#!/bin/bash

set -ex

function urldecode { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

function warning {
  printf '%s\0icon\x1fdialog-warning\x1fnonselectable\x1ftrue\x1c' "$1"
}

function base64_smart {
  if base64 --decode <<<"$1" >/dev/null; then
    res="$(base64 --decode <<<"$1")"
    if iconv -f UTF-8 <<<"$res" >/dev/null; then
      echo "$res"
    else
      warning "Base64 is not text..."
    fi
  else
    warning "Not base64..."
  fi
}

function process_text {
  clipboard="$(xclip -selection clipboard -out)"

  ru2en.c --rev <<<"$clipboard"
  printf '\x1c'
  urldecode "$clipboard"
  printf '\x1c'
  base64_smart "$clipboard"
  printf '\x1c'
  recode html..utf8 <<<"$clipboard" # todo: this will fail for chars above 0xffff
  printf '\x1c'
  xxd -r -p <<<"$clipboard"
  printf '\x1c'
}

function process_image {
  xclip -selection clipboard -t image/png ~/.cache/screenshot.png >/dev/null

  identify -precision 4 -format '%m %G %g %b\n' ~/.cache/screenshot.png
  printf '\x1c'
  zbarimg -q -1 ~/.cache/screenshot.png || warning "No qr-code found..."
  printf '\x1c'

  # todo: tesseract?
}

if [ "$ROFI_RETV" = 0 ]; then
  # Initial call of script.
  printf '\0delim\x1f\x1c\n'
  printf '\0markup-rows\x1ffalse\x1c'

  targets="$(xclip -selection clipboard -target TARGETS -out)"

  if grep -q UTF8_STRING <<<"$targets"; then
    process_text
  elif grep -q image/png <<<"$targets"; then
    process_image
  else
    warning "Unknown targets..."
    echo "$targets"
  fi
elif [ -n "$1" ]; then
  data="$(sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' <<<"$1")"
  printf '%s' "$data" | xclip -selection clipboard -in >/dev/null
else
  warning "Nothing to copy..."
fi
