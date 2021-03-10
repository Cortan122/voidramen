#!/usr/bin/env jitcc

#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <stdbool.h>

char* gluePath(char* path1, char* path2){
  char* buf = malloc(strlen(path1) + strlen(path2) + 2); // 2 для '/' и '\0'
  strcpy(buf, path1);
  strcat(buf, "/"); // 🧶🐈
  strcat(buf, path2);
  return buf;
}

char* getShortPath(char* home, char* linkname, char* pwd){
  char* buf = gluePath(home, linkname);
  char* real = realpath(buf, NULL);
  if(!real){
    perror("realpath");
    exit(1);
  }

  char* path = NULL;
  if(strncmp(real, pwd, strlen(real)) == 0){
    if(pwd[strlen(real)] == '/' || pwd[strlen(real)] == '\0'){
      path = gluePath(buf, pwd+strlen(real));
    }
  }

  free(buf);
  free(real);
  return path;
}

int pathlen(char* path, char* home){
  if(strncmp(path, home, strlen(home)) == 0)return strlen(path)-strlen(home)+1;
  return strlen(path);
}

char* getMinPath(char* pwd, char* home){
  DIR* d = opendir(home);
  if(!d){
    perror("opendir($HOME)");
    exit(1);
  }

  char* minpath = strdup(pwd);

  struct dirent* dir;
  while(dir = readdir(d)){
    if(dir->d_type == DT_LNK){
      char* path = getShortPath(home, dir->d_name, pwd);
      if(!path)continue;
      if(pathlen(minpath, home) > pathlen(path, home)){
        free(minpath);
        minpath = path;
      }else{
        free(path);
      }
    }
  }
  closedir(d);

  return minpath;
}

bool checkEdgecases(char* pwd, char* home){
  if(strcmp(pwd, "/data/data/com.termux/files/home") == 0){
    printf("%s\n", "/storage/emulated/0/Code");
  }else if(strcasecmp(pwd, "/mnt/c/windows/system32") == 0){
    printf("%s\n", home);
  }else if(strcmp(pwd, "/") == 0){
    printf("%s\n", home);
  }else return false;

  return true;
}

int main(){
  char* pwd = realpath(".", NULL);
  if(!pwd){
    perror("realpath(.)");
    exit(1);
  }

  char* home = getenv("HOME");
  if(!home){
    fprintf(stderr, "getenv(HOME): Not found\n");
    exit(1);
  }

  if(!checkEdgecases(pwd, home)){
    char* minpath = getMinPath(pwd, home);
    printf("%s\n", minpath);
    free(minpath);
  }

  free(pwd);
  return 0;
}
