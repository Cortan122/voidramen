#!/usr/bin/env jitcc

#define _GNU_SOURCE
#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>

#pragma comment(lib, "crypto")
#include <openssl/sha.h>
#include <openssl/evp.h>

typedef enum ParserState {
  PS_NORMAL,
  PS_NEWLINE,
  PS_BACKSLASH = 1<<3,
  PS_SHORT_COMMENT = 1<<4,
  PS_LONG_COMMENT = 1<<5,
  PS_STRING = 1<<6,
  PS_SHORT_STRING = 1<<7,
  PS_STR = PS_STRING|PS_LONG_COMMENT|PS_SHORT_COMMENT|PS_SHORT_STRING,
} ParserState;

typedef enum FileType {
  FT_EXE = 1,
  FT_OBJ = 2,
  FT_HEADER = 4,
} FileType;

typedef enum OutputMode {
  OM_NORMAL = 0b00,
  OM_IFTRUE,
  OM_IFFALSE,
  OM_IFUNKNOWN,
} OutputMode;

typedef struct StringList {
  int cap;
  int len;
  char** ptr;
} StringList;

typedef struct SourceFile {
  FILE* f;
  char* name;
  char* dir;
  FileType type;
  char* output;
  int depcount;

  int lineNumber;
  uint64_t outputMode;
  struct SourceFile* parent;
  struct StringList opt;
} SourceFile;

char* cachedir = NULL;
StringList cflags = {0};
SHA_CTX sha1context = {0};

const char* predefined_macros[] = {"amd64", "linux", "STDC", "unix", "x86_64", NULL};
const char* undefined_macros[] = {"i386", "WIN32", "WIN64", NULL};

bool endsWith(char* str, char* suffix){
  size_t lenstr = strlen(str);
  size_t lensuffix = strlen(suffix);
  if(lensuffix > lenstr)return false;
  return strncmp(str + lenstr - lensuffix, suffix, lensuffix) == 0;
}

int isOlderThen(const char* file1, const char* file2){
  struct stat b1, b2;
  if(stat(file1, &b1) || stat(file2, &b2))return 1; // ture, since at least one stat failed
  return b1.st_mtime < b2.st_mtime;
}

char* aprintf(char* fmt, ...){
  char* res = NULL;
  va_list args;
  va_start(args, fmt);
  vasprintf(&res, fmt, args);
  va_end(args);
  return res;
}

char* findStringInDirective(char* line){
  char* first = strchr(line, '"');
  char* last = strrchr(line, '"');
  if(first == NULL || last == NULL)return NULL;
  *last = '\0';
  return first+1;
}

char* expandTilde(char* path){
  if(path[0] == '~'){
    char* home = getenv("HOME");
    return aprintf("%s/%s", home, path+1);
  }
  return realpath(path, NULL);
}

char* genName(char* path, char* ext){
  uint8_t hash[SHA_DIGEST_LENGTH];
  char base64[4*((SHA_DIGEST_LENGTH+2)/3)+1];

  SHA_CTX contextcopy = sha1context;
  SHA1_Update(&contextcopy, (uint8_t*)path, strlen(path));
  SHA1_Final(hash, &contextcopy);
  EVP_EncodeBlock((uint8_t*)base64, hash, SHA_DIGEST_LENGTH);

  for(size_t i = 0; i < sizeof(base64); i++){
    if(base64[i] == '/')base64[i] = '_';
    if(base64[i] == '+')base64[i] = '-';
    if(base64[i] == '=')base64[i] = '\0';
  }

  char* slashindex = strrchr(path, '/');
  char* dotindex = strchr(slashindex, '.');
  if(dotindex)*dotindex = '\0';
  char* res = aprintf("%s/%.20s%s%s", cachedir, slashindex, base64, ext);
  if(dotindex)*dotindex = '.';
  return res;
}

void execFileSync(char* name, char** arr){
  pid_t pid = fork();
  arr[0] = name;

  if(pid == -1){
    perror("fork");
    exit(1);
  }else if(pid > 0){
    int status;
    waitpid(pid, &status, 0);
    if(status){
      fprintf(stderr, "%s exited with code %d\n", name, status);
      exit(1);
    }
  }else{
    execvp(name, arr);
    perror("execvp");
    fprintf(stderr, "can't run %s\n", name);
    exit(1);
  }
}

SourceFile* treeFind(SourceFile* file, FileType type){
  while(file){
    if(file->type & type)return file;
    file = file->parent;
  }
  return NULL;
}

void addString(StringList* list, char* str){
  if(list->cap == 0){
    list->cap = 16;
    list->len = 0;
    list->ptr = calloc(list->cap, sizeof(char*));
  }

  list->ptr[list->len++] = str;

  if(list->len >= list->cap){
    list->cap *= 2;
    list->ptr = realloc(list->ptr, list->cap * sizeof(char*));
  }

  list->ptr[list->len] = NULL;
}

void addOption(SourceFile* file, char* opt, FileType type){
  file = treeFind(file, type);
  if(file == NULL)return;

  if(endsWith(opt, ".o")){
    for(int i = 0; i < file->opt.len; i++){
      if(strcmp(file->opt.ptr[i], opt) == 0)return;
    }
  }

  addString(&file->opt, opt);
}

void buildFile(SourceFile* file){
  char** args = calloc(file->opt.len+cflags.len+5, sizeof(char*));
  int argsi = 0;

  memcpy(args, cflags.ptr, cflags.len*sizeof(char*));
  argsi += cflags.len;
  if(file->opt.len){
    memcpy(args+argsi, file->opt.ptr, file->opt.len*sizeof(char*));
    argsi += file->opt.len;
  }
  memcpy(args+argsi, (char*[]){"-o", file->output, file->name}, 3*sizeof(char*));
  argsi += 3;
  if(file->type == FT_OBJ){
    memcpy(args+argsi++, (char*[]){"-c"}, sizeof(char*));
  }
  memcpy(args+argsi, (char*[]){NULL}, sizeof(char*));

  for(int i = 0; args[i]; i++){
    fprintf(stderr, "%s ", args[i]);
  }
  fprintf(stderr, "\n");
  fflush(stderr);
  execFileSync(args[0], args);
  free(args);
}

void parseFile(SourceFile* file);

int readFile(const char* name, FileType type, char** output, SourceFile* parent){
  FILE* f = fopen(name, "r");
  if(f == NULL){
    perror(name);
    return 0;
  }
  char* fullname = realpath(name, NULL);
  char* slashindex = strrchr(fullname, '/');
  *slashindex = '\0';
  char* dir = strdup(fullname);
  *slashindex = '/';

  SourceFile dto = {f, fullname, dir, type, NULL, 0, 1, OM_NORMAL, parent, {0}};
  if(type != FT_HEADER){
    dto.output = genName(fullname, type==FT_OBJ ? ".o" : "");
    dto.depcount += isOlderThen(dto.output, fullname);
  }
  parseFile(&dto);

  if(dto.output && dto.depcount){
    buildFile(&dto);
  }

  fclose(dto.f);
  for(int i = 0; i < dto.opt.len; i++){
    free(dto.opt.ptr[i]);
  }
  free(dto.opt.ptr);
  free(dto.name);
  free(dto.dir);
  if(output){
    *output = dto.output;
  }else{
    free(dto.output);
  }
  return dto.depcount;
}

void include(SourceFile* file, char* name){
  if(strcmp(file->name, name) == 0)return;

  char* output = NULL;
  FileType type = endsWith(name, ".c") ? FT_OBJ : FT_HEADER;
  file->depcount += readFile(name, type, &output, file);

  if(file->output && isOlderThen(file->output, name)){
    file->depcount++;
  }else if(file->output == NULL){
    char* realOutput = treeFind(file, FT_EXE|FT_OBJ)->output;
    if(isOlderThen(realOutput, name))file->depcount++;
  }

  if(output){
    addOption(file, output, FT_EXE);
  }
}

void pushOutputMode(SourceFile* file, OutputMode new){
  OutputMode prev = file->outputMode & 0b11;
  if(prev == OM_IFFALSE)new = OM_IFFALSE;
  if(prev == OM_IFUNKNOWN)new = OM_IFUNKNOWN;
  file->outputMode = (file->outputMode << 2) | new;
}

OutputMode popOutputMode(SourceFile* file, const char* errstr){
  OutputMode prev = file->outputMode & 0b11;
  if(file->outputMode == OM_NORMAL){
    fprintf(
      stderr, "\x1b[35mWARNING\x1b[0m: \x1b[93msfmake.c\x1b[0m: unexpected \x1b[33m%s\x1b[0m "
      "in file `\x1b[1m%s\x1b[0m` on line \x1b[36m%d\x1b[0m\n",
      errstr, strrchr(file->name, '/')+1, file->lineNumber
    );
  }
  file->outputMode >>= 2;
  return prev;
}

OutputMode getMacroType(char* str){
  while(str[0] <= ' ' || str[0] == '_')str++;
  int len = strlen(str);
  while(len && (str[len-1] <= ' ' || str[len-1] == '_'))len--;

  for(const char** ptr = predefined_macros; *ptr; ptr++){
    if(strlen(*ptr) == len && strncmp(*ptr, str, len) == 0){
      return OM_IFTRUE;
    }
  }
  for(const char** ptr = undefined_macros; *ptr; ptr++){
    if(strlen(*ptr) == len && strncmp(*ptr, str, len) == 0){
      return OM_IFFALSE;
    }
  }

  return OM_IFUNKNOWN;
}

OutputMode invertOutputMode(OutputMode prev){
  if(prev == OM_IFFALSE)return OM_IFTRUE;
  if(prev == OM_IFTRUE)return OM_IFFALSE;
  return prev;
}

bool checkDirective(SourceFile* file, char* line){
  OutputMode type = file->outputMode & 0b11;
  if(type == OM_IFTRUE || type == OM_NORMAL)return true;
  if(type == OM_IFFALSE)return false;
  fprintf(
    stderr, "\x1b[35mWARNING\x1b[0m: \x1b[93msfmake.c\x1b[0m: directive \x1b[33m`%s`\x1b[0m "
    "is located inside an ambiguous #if block "
    "in file `\x1b[1m%s\x1b[0m` on line \x1b[36m%d\x1b[0m\n",
    line, strrchr(file->name, '/')+1, file->lineNumber
  );
  return false;
}

void directiveCallback(SourceFile* file, char* line){
  while(line[0] <= ' ')line++;
  int len = strlen(line);
  while(len && line[len-1] <= ' ')len--;

  if(strncmp(line, "endif", 5) == 0){
    popOutputMode(file, "#endif");
  }else if(strncmp(line, "ifndef", 6) == 0 && len > 7){
    pushOutputMode(file, invertOutputMode(getMacroType(line+6)));
  }else if(strncmp(line, "ifdef", 5) == 0 && len > 6){
    pushOutputMode(file, getMacroType(line+5));
  }else if(strncmp(line, "if", 2) == 0 && len > 3){
    pushOutputMode(file, OM_IFUNKNOWN);
  }else if(strncmp(line, "elif", 4) == 0){
    popOutputMode(file, "#elif");
    pushOutputMode(file, OM_IFUNKNOWN);
  }else if(strncmp(line, "elseif", 6) == 0){
    popOutputMode(file, "#elseif");
    pushOutputMode(file, OM_IFUNKNOWN);
  }else if(strncmp(line, "else", 4) == 0){
    pushOutputMode(file, invertOutputMode(popOutputMode(file, "#else")));
  }else if(strncmp(line, "include", 7) == 0 && len > 8){
    char* name = findStringInDirective(line);
    if(!name)return;
    if(!endsWith(name, ".h"))return;
    if(!checkDirective(file, line))return;

    char* newname = aprintf("%s/%s", file->dir, name);
    include(file, newname);
    newname[strlen(newname)-1] = 'c';
    include(file, newname);
    free(newname);
  }else if(strncmp(line, "pragma comment(dir", 18) == 0 && len > 20){
    char* dir = findStringInDirective(line);
    if(!dir)return;
    if(!checkDirective(file, line))return;
    free(file->dir);
    file->dir = expandTilde(dir);
    addString(&cflags, aprintf("-I%s", file->dir));
  }else if(strncmp(line, "pragma comment(option", 21) == 0 && len > 23){
    char* opt = findStringInDirective(line);
    if(!opt)return;
    if(!checkDirective(file, line))return;
    addString(&cflags, opt);
  }else if(strncmp(line, "pragma comment(lib", 18) == 0 && len > 20){
    char* lib = findStringInDirective(line);
    if(!lib)return;
    if(!checkDirective(file, line))return;
    if(strcmp(lib, "pthread") == 0){
      addOption(file, aprintf("-%s", lib), FT_EXE);
    }else{
      addOption(file, aprintf("-l%s", lib), FT_EXE);
    }
  }
}

void parseFile(SourceFile* file){
  ParserState ps = PS_NEWLINE;
  char prev = '\0';
  int t;
  while((t = getc(file->f)) >= 0){
    if(t == '\n')file->lineNumber++;
    if(prev == '/' && t == '/' && (ps&PS_STR) == 0){
      ps |= PS_SHORT_COMMENT;
    }
    if(prev == '/' && t == '*' && (ps&PS_STR) == 0){
      ps |= PS_LONG_COMMENT;
    }
    if(t == '\'' && (ps&PS_STR) == 0){
      ps |= PS_SHORT_STRING;
    }
    if(t == '"' && (ps&PS_STR) == 0){
      ps |= PS_STRING;
    }
    if(ps&PS_BACKSLASH){
      ps &= ~PS_BACKSLASH;
      continue;
    }
    if(t == '\\'){
      ps |= PS_BACKSLASH;
    }
    if(ps == PS_NEWLINE && t > ' '){
      ps = PS_NORMAL;
      if(t == '#'){
        char* str = NULL;
        fscanf(file->f, "%m[^\n]", &str);
        directiveCallback(file, str);
        free(str);
      }
    }
    if(t == '\n' && (ps == PS_NORMAL || (ps&PS_SHORT_COMMENT))){
      ps = PS_NEWLINE;
    }
    if(t == '\'' && (ps&PS_SHORT_STRING)){
      ps &= ~PS_SHORT_STRING;
    }
    if(t == '"' && (ps&PS_STRING)){
      ps &= ~PS_STRING;
    }
    if(prev == '*' && t == '/' && (ps&PS_LONG_COMMENT)){
      ps &= ~PS_LONG_COMMENT;
    }
    prev = t;
  }
}

int main(int argc, char** argv){
  if(argc < 2){
    fprintf(stderr, "\x1b[31mERROR\x1b[0m: \x1b[93msfmake.c\x1b[0m expects at least one argument\n");
    return 1;
  }

  cachedir = expandTilde("~/.cache/sfmake");
  if(mkdir(cachedir, 0755)){
    if(errno != EEXIST){
      perror(cachedir);
      exit(1);
    }
  }

  SHA1_Init(&sha1context);

  char* arr[] = {
    getenv("CC") ?: "gcc", "-g",
    "-fdollars-in-identifiers", "-funsigned-char",
    "-Wall", "-Wextra", "-Wno-parentheses", "-Wno-unknown-pragmas", "-Werror=vla",
    NULL
  };
  for(int i = 0; arr[i]; i++){
    addString(&cflags, arr[i]);
    SHA1_Update(&sha1context, (uint8_t*)arr[i], strlen(arr[i]));
  }

  int optargc = 1;
  for(; optargc < argc; optargc++){
    if(argv[optargc][0] == '-'){
      addString(&cflags, argv[optargc]);
      SHA1_Update(&sha1context, (uint8_t*)argv[optargc], strlen(argv[optargc]));
    }else break;
  }

  char* output = NULL;
  readFile(argv[optargc], FT_EXE, &output, NULL);
  free(cachedir);

  execvp(output, argv+optargc);
  perror("execvp");
  fprintf(stderr, "can't run %s\n", output);
  return 1;
}

// TODO: include stb libs
// TODO: ignore shebang
