#!/bin/bash

set -e

selection="$(xclip -o -selection primary)"

# remove whitespace characters
# https://stackoverflow.com/a/3352015
selection="${selection#"${selection%%[![:space:]]*}"}"
selection="${selection%"${selection##*[![:space:]]}"}"

if [[ $selection =~ [[:space:]]+ ]]; then
  notify-send "📕 Persdict" "String '<span color=\"#f00\">$selection</span>' has spaces"
elif [[ "${#selection}" -gt 30 ]]; then
  notify-send "📕 Persdict" "String '<span color=\"#f00\">$selection</span>' is too long"
elif [[ "${#selection}" -lt 3 ]]; then
  notify-send "📕 Persdict" "String '<span color=\"#f00\">$selection</span>' is too short"
elif ! [[ $selection =~ ^[[:alnum:]-]*$ ]]; then
  notify-send "📕 Persdict" "String '<span color=\"#f00\">$selection</span>' is not alphanumeric"
else
  notify-send "📗 Persdict" "Adding '<span color=\"#0f0\">$selection</span>' to persdict"

  echo "$selection" >> ~/Programs/voidramen/.config/firefox-chrome/persdict.dat
  cd ~/Programs/voidramen/
  ./install.sh
fi

