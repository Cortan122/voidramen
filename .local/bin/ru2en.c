#!/usr/bin/env jitcc

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

static const char* ru2en_rom[] = {
  ['"'] = "@",
  [','] = "?",
  ['.'] = "/",
  [':'] = "^",
  ['?'] = "&",
  [';'] = "$",
  [0x0401] = "~",
  [0x0410] = "F",
  [0x0411] = "<",
  [0x0412] = "D",
  [0x0413] = "U",
  [0x0414] = "L",
  [0x0415] = "T",
  [0x0416] = ":",
  [0x0417] = "P",
  [0x0418] = "B",
  [0x0419] = "Q",
  [0x041a] = "R",
  [0x041b] = "K",
  [0x041c] = "V",
  [0x041d] = "Y",
  [0x041e] = "J",
  [0x041f] = "G",
  [0x0420] = "H",
  [0x0421] = "C",
  [0x0422] = "N",
  [0x0423] = "E",
  [0x0424] = "A",
  [0x0425] = "{",
  [0x0426] = "W",
  [0x0427] = "X",
  [0x0428] = "I",
  [0x0429] = "O",
  [0x042a] = "}",
  [0x042b] = "S",
  [0x042c] = "M",
  [0x042d] = "\"",
  [0x042e] = ">",
  [0x042f] = "Z",
  [0x0430] = "f",
  [0x0431] = ",",
  [0x0432] = "d",
  [0x0433] = "u",
  [0x0434] = "l",
  [0x0435] = "t",
  [0x0436] = ";",
  [0x0437] = "p",
  [0x0438] = "b",
  [0x0439] = "q",
  [0x043a] = "r",
  [0x043b] = "k",
  [0x043c] = "v",
  [0x043d] = "y",
  [0x043e] = "j",
  [0x043f] = "g",
  [0x0440] = "h",
  [0x0441] = "c",
  [0x0442] = "n",
  [0x0443] = "e",
  [0x0444] = "a",
  [0x0445] = "[",
  [0x0446] = "w",
  [0x0447] = "x",
  [0x0448] = "i",
  [0x0449] = "o",
  [0x044a] = "]",
  [0x044b] = "s",
  [0x044c] = "m",
  [0x044d] = "'",
  [0x044e] = ".",
  [0x044f] = "z",
  [0x0451] = "`",
  [0x2116] = "#"
};

static const char* en2ru_rom[] = {
  ['"'] = "Э",
  ['#'] = "№",
  [','] = "б",
  ['.'] = "ю",
  [':'] = "Ж",
  [';'] = "ж",
  ['<'] = "Б",
  ['>'] = "Ю",
  ['A'] = "Ф",
  ['B'] = "И",
  ['C'] = "С",
  ['D'] = "В",
  ['E'] = "У",
  ['F'] = "А",
  ['G'] = "П",
  ['H'] = "Р",
  ['I'] = "Ш",
  ['J'] = "О",
  ['K'] = "Л",
  ['L'] = "Д",
  ['M'] = "Ь",
  ['N'] = "Т",
  ['O'] = "Щ",
  ['P'] = "З",
  ['Q'] = "Й",
  ['R'] = "К",
  ['S'] = "Ы",
  ['T'] = "Е",
  ['U'] = "Г",
  ['V'] = "М",
  ['W'] = "Ц",
  ['X'] = "Ч",
  ['Y'] = "Н",
  ['Z'] = "Я",
  ['['] = "х",
  ['\''] = "э",
  [']'] = "ъ",
  ['`'] = "ё",
  ['a'] = "ф",
  ['b'] = "и",
  ['c'] = "с",
  ['d'] = "в",
  ['e'] = "у",
  ['f'] = "а",
  ['g'] = "п",
  ['h'] = "р",
  ['i'] = "ш",
  ['j'] = "о",
  ['k'] = "л",
  ['l'] = "д",
  ['m'] = "ь",
  ['n'] = "т",
  ['o'] = "щ",
  ['p'] = "з",
  ['q'] = "й",
  ['r'] = "к",
  ['s'] = "ы",
  ['t'] = "е",
  ['u'] = "г",
  ['v'] = "м",
  ['w'] = "ц",
  ['x'] = "ч",
  ['y'] = "н",
  ['z'] = "я",
  ['{'] = "Х",
  ['}'] = "Ъ",
  ['~'] = "Ё",
};

#define ARR_LEN(arr) (sizeof(arr)/sizeof(*(arr)))
#define ROM_GET(rom, i) (char*)(i >= ARR_LEN(rom) ? NULL : rom[i])


#define UTF8_ACCEPT 0
#define UTF8_REJECT 12

const uint8_t utf8d[] = {
  // The first part of the table maps bytes to character classes that
  // to reduce the size of the transition table and create bitmasks.
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
   7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
   8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  10,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3, 11,6,6,6,5,8,8,8,8,8,8,8,8,8,8,8,

  // The second part is a transition table that maps a combination
  // of a state of the automaton and a character class to a state.
   0,12,24,36,60,96,84,12,12,12,48,72, 12,12,12,12,12,12,12,12,12,12,12,12,
  12, 0,12,12,12,12,12, 0,12, 0,12,12, 12,24,12,12,12,12,12,24,12,24,12,12,
  12,12,12,12,12,12,12,24,12,12,12,12, 12,24,12,12,12,12,12,12,12,24,12,12,
  12,12,12,12,12,12,12,36,12,36,12,12, 12,36,12,12,12,12,12,36,12,36,12,12,
  12,36,12,12,12,12,12,12,12,12,12,12,
};

int decode(int* state, uint32_t* codep, uint8_t byte){
  int type = utf8d[byte];

  *codep = (*state != UTF8_ACCEPT) ?
    (byte & 0x3fu) | (*codep << 6) :
    (0xff >> type) & (byte);

  *state = utf8d[256 + *state + type];
  return *state;
}

int isShellHelper = 0;
int isRevMode = 0;

void revCallback(char* en2ru, char* ru2en, char* utf8buf){
  static int currentSelection = 1;
  if(!en2ru && !ru2en){
    printf("%s", utf8buf);
    return;
  }

  if(currentSelection){
    if(!en2ru)currentSelection = 0;
  }else{
    if(!ru2en)currentSelection = 1;
  }

  printf("%s", currentSelection ? en2ru : ru2en);
}

void convertChar(uint8_t ch){
  static uint32_t utf8codepoint;
  static uint8_t utf8buf[10];
  static int utf8bufind = 0;
  static int utf8state = 0;

  utf8buf[utf8bufind++] = ch;
  decode(&utf8state, &utf8codepoint, ch);

  if(utf8state == UTF8_REJECT){
    utf8bufind = utf8state = utf8codepoint = 0;
    // panic!!
    fprintf(stderr, "%s\n", "какойто у тебя неправильный utf8");
    exit(1);
  }else if(utf8state == UTF8_ACCEPT){
    if(isShellHelper == 1 && utf8codepoint < 0x80){
      printf("%s\n", "original_command_not_found_handle \"$@\"");
      exit(0);
    }
    isShellHelper = 0;

    utf8buf[utf8bufind++] = '\0';

    char* en2ru = ROM_GET(en2ru_rom, utf8codepoint);
    char* ru2en = ROM_GET(ru2en_rom, utf8codepoint);
    if(isRevMode){
      revCallback(en2ru, ru2en, (char*)utf8buf);
    }else{
      printf("%s", ru2en ? ru2en : (char*)utf8buf);
    }

    utf8bufind = utf8state = utf8codepoint = 0;
  }
}

int main(int argc, char *argv[]){
  if(argc == 1){
    int t;
    while((t = getc(stdin)) != EOF)convertChar((uint8_t)t);
  }else if(argc == 2 && strcmp(argv[1], "--rev") == 0){
    isRevMode = 1;
    int t;
    while((t = getc(stdin)) != EOF)convertChar((uint8_t)t);
  }else{
    isShellHelper = 1;
    for(int i = 1; i < argc; i++){
      if(i != 1)putc(' ', stdout);
      for(int j = 0; argv[i][j] != '\0'; j++){
        convertChar(argv[i][j]);
      }
    }
    putc('\n', stdout);
  }

  return 0;
}
