#!/bin/sh

cd -- "$(dirname -- "$0")"

profile="$HOME/.mozilla/firefox/$(awk -F= '/Default/ {print $2;exit}' ~/.mozilla/firefox/profiles.ini)/"
cp -rvu .config/firefox-chrome -T "$profile/chrome"
mv -vu "$profile/chrome/user.js" "$profile"
