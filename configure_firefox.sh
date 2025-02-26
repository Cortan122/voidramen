#!/bin/bash

set -e
cd -- "$(dirname -- "$0")"

# perl -ne 'print unless $seen{$_}++' .config/firefox-chrome/persdict.dat | sponge .config/firefox-chrome/persdict.dat

profile="$HOME/.mozilla/firefox/$(awk -F= '/Default/ {print $2;exit}' ~/.mozilla/firefox/profiles.ini)/"
cp -vu .config/firefox-chrome/*.{css,png,jpeg} "$profile/chrome"
cp -vu .config/firefox-chrome/user.js "$profile/user.js"
cp -vu .config/firefox-chrome/persdict.dat "$profile/persdict.dat"
cp -vu .config/firefox-chrome/persdict.dat ~/.local/share/TelegramDesktop/tdata/dictionaries/custom
