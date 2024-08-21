#!/bin/sh

set -e
name="$(xdotool getactivewindow getwindowclassname)"

send_key () {
  xdotool key --clearmodifiers Super+Shift+T
}

start_term () {
  exec i3-sensible-terminal
}

case "$1" in
  press)
    case "$name" in
      Thunar|VSCodium|VSCode) ;;
      *) start_term ;;
    esac ;;
  release)
    case "$name" in
      Thunar|VSCodium|VSCode) send_key ;;
      *) ;;
    esac ;;
  *) start_term ;;
esac


