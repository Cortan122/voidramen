#!/bin/bash

set -e
cd -- "$(dirname -- "$0")"

profile="$HOME/.mozilla/firefox/$(awk -F= '/Default/ {print $2;exit}' ~/.mozilla/firefox/profiles.ini)/"
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
