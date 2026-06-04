#!/bin/sh

# todo: force it to redraw itself
dunstctl set-paused true
i3lock -i ~/.config/wall.png --show-keyboard-layout --nofork "$@"
dunstctl set-paused false

pkill --signal SIGRTMIN+12 i3blocks
