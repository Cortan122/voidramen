#!/bin/sh

case $1 in
  mute) BLOCK_BUTTON=2 ;;
  up) BLOCK_BUTTON=4 ;;
  down) BLOCK_BUTTON=5 ;;
esac

export BLOCK_BUTTON
volume="$(~/.local/bin/statusbar/volume)"
notify-send -t 500 "Current volume: $volume"
pkill --signal SIGRTMIN+10 i3blocks
