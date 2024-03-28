#!/bin/sh

window_id="$(xdotool getactivewindow)"
[ "$(xdotool getwindowclassname "$window_id")" = "firefox" ] && sleep 0.1

# xdotool windowfocus --sync "$window_id" type --clearmodifiers --delay=1ms "$1"
# exit

xclip -selection clipboard -o > ~/.cache/xclip-backup
echo -n "$1" | xclip -selection clipboard -i
xdotool windowfocus --sync "$window_id" key --clearmodifiers Shift+Insert sleep 0.05
xclip -selection clipboard -i ~/.cache/xclip-backup
