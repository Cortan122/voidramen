#!/bin/sh

set -e

send_key () {
  xdotool key --clearmodifiers Super+Shift+T
}

start_term () {
  exec i3-sensible-terminal
}

if ! name="$(xdotool getactivewindow getwindowclassname)"; then
  [ "$1" = "press" ] && start_term
  exit
fi

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
