#!/bin/sh

window_id="$(xdotool search --onlyvisible --class Firefox | head -n 1)"

if [ -z "$window_id" ]; then
  firefox &
  exit
fi

xdotool windowactivate "$window_id" && xdotool key ctrl+shift+p
