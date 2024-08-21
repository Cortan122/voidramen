#!/bin/sh

set -e
window_id="$(xdotool getactivewindow)"
name="$(xdotool getwindowclassname "$window_id")"

send_key () {
  xdotool windowfocus --sync "$window_id" key --clearmodifiers Super+Shift+T
}

case "$1" in
  press)
    case "$name" in
      Thunar|VSCodium|VSCode) ;;
      *) exec i3-sensible-terminal ;;
    esac ;;
  release)
    case "$name" in
      Thunar|VSCodium|VSCode) send_key ;;
      *) ;;
    esac ;;
  *) exec i3-sensible-terminal ;;
esac


