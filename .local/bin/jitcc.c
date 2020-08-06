#include <openssl/sha.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdint.h>
#include <limits.h> /* PATH_MAX */

#define ARGV(...) ((char* []){"",##__VA_ARGS__,NULL})

int mkdir_p(const char* pathname, mode_t mode){
  // invalid pathname
  if(!pathname || !pathname[0])return -1;

  // pathname already exists and is a directory
  struct stat st = {0};
  if(stat(pathname, &st) == 0 && S_ISDIR(st.st_mode))return 0;

  // doesn't need parent directories created
  if(mkdir(pathname, mode) == 0)return 0;

  // prepend initial / if needed
  char tmp[PATH_MAX+1] = {0};
  if(pathname[0] == '/')tmp[0] = '/';

  // make a copy of pathname and start tokenizing it
  char path[PATH_MAX+1] = {0};
  strncpy(path, pathname, PATH_MAX);
  char* tok = strtok(path, "/");

  // keep going until there are no tokens left
  while(tok){
    // append the next token to the path
    strcat(tmp, tok);

    // create the directory and keep going unless mkdir fails and
    // errno doesn't indicate that the path already exists
    errno = 0;
    if(mkdir(tmp, mode) != 0 && errno != EEXIST)return -1; // errno still set from mkdir() call

    // append a / to the path for the next token and get it
    strcat(tmp, "/");
    tok = strtok(NULL, "/");
  }

  // success
  return 0;
}

int isOlderThen(const char* file1, const char* file2){
  struct stat b1, b2;
  if(stat(file1, &b1) || stat(file2, &b2))return 1; // ture, since at least one stat failed
  return b1.st_mtime < b2.st_mtime;
}

const char* base64_rom = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
static int mod_table[] = {0, 2, 1};

char* base64_encode(const uint8_t* data, size_t input_length){
  size_t output_length = 4 * ((input_length + 2) / 3);

  char* encoded_data = malloc(output_length+1);
  if(encoded_data == NULL)return NULL;

  for(int i = 0, j = 0; i < input_length;){
    uint32_t octet_a = i < input_length ? (uint8_t)data[i++] : 0;
    uint32_t octet_b = i < input_length ? (uint8_t)data[i++] : 0;
    uint32_t octet_c = i < input_length ? (uint8_t)data[i++] : 0;

    uint32_t triple = (octet_a << 0x10) + (octet_b << 0x08) + octet_c;

    encoded_data[j++] = base64_rom[(triple >> 3 * 6) & 0x3F];
    encoded_data[j++] = base64_rom[(triple >> 2 * 6) & 0x3F];
    encoded_data[j++] = base64_rom[(triple >> 1 * 6) & 0x3F];
    encoded_data[j++] = base64_rom[(triple >> 0 * 6) & 0x3F];
  }

  for(int i = 0; i < mod_table[input_length % 3]; i++){
    encoded_data[output_length - 1 - i] = '\0';
  }

  encoded_data[output_length] = '\0';

  return encoded_data;
}

char* base64_sha1(const char* data){
  size_t length = strlen(data);

  uint8_t hash[SHA_DIGEST_LENGTH];
  SHA1(data, length, hash);
  // hash now contains the 20-byte SHA-1 hash

  char* b64hash = base64_encode(hash, SHA_DIGEST_LENGTH);

  return b64hash;
}

void execFileSync(char* name, char* arr[], int pipe[2]){
  pid_t pid = fork();
  arr[0] = name;

  if(pid == -1){
    // error, failed to fork()
    fprintf(stderr, "can't fork()\n");
    exit(1);
  }else if(pid > 0){
    int status;
    waitpid(pid, &status, 0);
    if(status){
      fprintf(stderr, "%s exited with code %d\n", name, status);
      exit(1);
    }
  }else{
    // we are the child
    if(pipe[1] != -1){
      dup2(pipe[1], STDOUT_FILENO);
      close(pipe[1]);
    }
    if(pipe[0] != -1){
      dup2(pipe[0], STDIN_FILENO);
      close(pipe[0]);
    }
    execvp(name, arr);
    fprintf(stderr, "can't run %s\n", name);
    exit(1);
  }
}

char* getFilename(char* name){
  // this function is only here for readability
  char cachepath[PATH_MAX];
  snprintf(cachepath, sizeof cachepath, "%s/.cache/jitcc", getenv("HOME"));
  mkdir_p(cachepath, 0755); // octal 0o755

  char realpathbuf[PATH_MAX]; /* PATH_MAX incudes the \0 so +1 is not required */
  char* res = realpath(name, realpathbuf);
  if(res == NULL){
    fprintf(stderr, "can't find %s\n", name);
    exit(1);
  }
  char* hash = base64_sha1(res);

  char filename[PATH_MAX];
  snprintf(filename, sizeof filename, "%s/%s", cachepath, hash);
  free(hash);

  return strdup(filename);
}

int main(int argc, char* argv[]){
  if(argv[1] == NULL)argv[1] = "utf8.c"; // todo

  char* filename = getFilename(argv[1]);

  if(isOlderThen(filename, argv[1])){
    int fd[2];
    if(pipe(fd)){
      fprintf(stderr, "can't open pipe\n");
      exit(1);
    }

    execFileSync("sed", ARGV("1s/^#!.*//", argv[1]), (int[]){-1, fd[1]});
    close(fd[1]);
    execFileSync("gcc", ARGV("-O3","-lcrypto","-lm","-x","c","-","-o", filename), (int[]){fd[0], -1});
    close(fd[0]);
  }

  // printf("%s %s\n", res, filename); // todo

  execFileSync(filename, argv+1, (int[]){-1, -1});
  free(filename);

  return 0;
}
