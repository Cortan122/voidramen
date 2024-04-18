#!/bin/sh

xdotool search --onlyvisible --class Firefox |
  while read id; do
    window_id="$id"
    xdotool getwindowgeometry "$id" | grep -Fq "Geometry: 1x1" || break
  done

if [ -z "$window_id" ]; then
  firefox &
  exit
fi

xdotool windowactivate "$window_id" key ctrl+shift+p
