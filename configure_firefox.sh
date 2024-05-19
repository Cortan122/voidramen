#!/bin/bash

set -e
cd -- "$(dirname -- "$0")"

profile="$HOME/.mozilla/firefox/$(awk -F= '/Default/ {print $2;exit}' ~/.mozilla/firefox/profiles.ini)/"
cp -vu .config/firefox-chrome/*.{css,png,jpeg} "$profile/chrome"
cp -vu ".config/firefox-chrome/user.js" "$profile/user.js"
