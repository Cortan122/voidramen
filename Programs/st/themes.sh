#!/bin/bash

ifinstalled jq dmenu sponge wal column || exit 1

cd -P -- "$(dirname -- "$0")"

name="$(jq 'keys[]' themes.json --raw-output | grep -v ^_ | dmenu)"
[ -z "$name" ] && exit

jq ".$name|to_entries|map([.[]|tostring]|join(\":\t\"))[]" themes.json --raw-output \
| (
  TEMP="$(mktemp /tmp/themes.sh_file.XXXXXXXX)"
  tee "$TEMP" | grep -v ^font
  font="$(awk -F $':\t' '/^font/ {print $2}' "$TEMP")"
  rm "$TEMP"

  sys="WSL"
  [ -z "$(grep -i microsoft /proc/version)" ] && sys="Linux"
  dfont="$(jq "._fonts.$sys|keys[]" themes.json --raw-output | grep -v ^_ | dmenu -i)"
  [ -z "$dfont" ] && dfont="$font"
  rfont="$(jq "._fonts.$sys[\"$dfont\"]" themes.json --raw-output)"
  [ "$rfont" == "null" ] && rfont="$font"
  echo -e "font:\t$rfont"

  alpha="$(jq "._fonts.$sys._alpha" themes.json --raw-output)"
  echo -e "alpha:\t$alpha"
) | awk '{print "/*st*/ *.St."$0}' | column -t -s $'\t' \
| cat <(grep -v '^\/\*st\*\/ \*\.St\.' ~/.Xdefaults) - | sponge ~/.Xdefaults
xrdb ~/.Xdefaults

jq "{\
  \"colors\": (.$name | to_entries | map(select(.key | startswith(\"color\"))) | from_entries),\
  \"special\": (.$name | to_entries | map(select(.key == \"background\" or .key == \"foreground\" or .key == \"cursorColor\")) | from_entries)\
}" themes.json | sed 's/cursorColor/cursor/' > "/tmp/$name.json"
wal -a "$alpha" --theme "/tmp/$name.json"
rm "/tmp/$name.json"
