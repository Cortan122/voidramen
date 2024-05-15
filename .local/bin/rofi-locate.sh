#!/bin/bash

history="$HOME/.config/locate_history"

[ -f "$history" ] || touch "$history"

if [ "$ROFI_RETV" = 0 ]; then
  # Initial call of script.
  awk '!x[$0]++' "$history"
  grep -Pi '^locate [^-][^ ]*$' ~/.config/bash_history | cut -d' ' -f2 | sort | uniq
elif [ -e "$1" ]; then
  basename -- "$1" >> "$history"
  coproc ( xdg-open "$1" >/dev/null 2>&1 )
else
  locate --ignore-case --limit 100 -- "$1" || echo "Nothing found..."
fi
