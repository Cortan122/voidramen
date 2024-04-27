#!/bin/bash

if [ "$ROFI_RETV" = 0 ]; then
  # Initial call of script.
  grep -Pi '^locate [^-][^ ]*$' ~/.config/bash_history | cut -d' ' -f2 | sort | uniq
elif [ -e "$1" ]; then
  coproc ( xdg-open "$1" >/dev/null 2>&1 )
else
  locate --limit 100 -- "$1"
fi
