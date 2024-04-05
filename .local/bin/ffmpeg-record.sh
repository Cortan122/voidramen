#!/bin/sh

if tmux ls | grep record; then
  notify-send "stopping recording..."
  tmux send-keys -t record q
else
  rm -vf ~/.cache/ffmpeg-recording.mp4
  tmux new -d -s record \
    ffmpeg -framerate 30 -video_size 1920x1080 -f x11grab -i :0 -preset ultrafast ~/.cache/ffmpeg-recording.mp4
  notify-send "recording started..."
fi
