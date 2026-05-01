#!/bin/bash

set -e
cd -- "$(dirname -- "$0")"

firefox="$HOME/.config/mozilla/firefox"
profile="$firefox/$(awk -F= '/Default/ {print $2;exit}' "$firefox/profiles.ini")/"
mkdir -pv "$profile/chrome"
cp -vu .config/firefox-chrome/*.{css,png,jpeg} "$profile/chrome"
cp -vu .config/firefox-chrome/user.js "$profile/user.js"

# this script is also responsible for handling the personal dictionaries
presdict=.config/firefox-chrome/persdict.dat
if [ "$profile/persdict.dat" -ot "$presdict" ]; then
  perl -ne 'print unless $seen{$_}++' "$presdict" | sponge "$presdict"
  cp -u "$presdict" ~/"$presdict"
fi

cp -vu "$presdict" "$profile/persdict.dat"
cp -vu "$presdict" ~/.local/share/TelegramDesktop/tdata/dictionaries/custom

# converting the dict for sublime text
presdict_subl=~/.config/sublime-text/Packages/Persdict/Preferences.sublime-settings
if [ "$presdict_subl" -ot "$presdict" ]; then
  jq -Rs '{added_words: [.|split("\n")|.[]|select(length > 0)]}' "$presdict" \
    | install -Dv /dev/stdin "$presdict_subl"
fi

# theme url:
# https://color.firefox.com/?theme=XQAAAAIaAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPr79BBHBoBDHBn11sKixxJ8nCuRy8nck1kUU--KOrTBHK3glVCXfb60aH3vNwXpOTQzbhGZLbT_s75p6W3HPI3lf2pI-5TO1joyuib8YSPmwqfOpKqyFLihUYUzEU9wXo6wYK3ZWzZHcxV4UVKdrlxvSCC4VRWwSg7APa9qnlQ8jaWBmTP2TIjPmqX_8B02lKrJIwCg1DrL8QMALc0lOf_pI6uA
