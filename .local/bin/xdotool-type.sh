#!/bin/sh

sleep 0.1
xdotool type --clearmodifiers --delay=1ms "$1"
exit

window_id="$(xdotool getactivewindow)"
notify-send "$(xdotool getwindowname "$window_id")"

sleep 0.1
xclip -selection clipboard -o > ~/.cache/xclip-backup
echo -n "$1" | xclip -selection clipboard -i
xdotool key --window "$window_id" --clearmodifiers shift+Insert
xclip -selection clipboard -i ~/.cache/xclip-backup
