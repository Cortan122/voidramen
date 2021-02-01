#!/bin/bash

[ "$1" == "--help" ] && cat -- "$0" && exit
# Usage:
# ./youtube-dl-range.sh URL [[STRAT_TIME] STRAT_TIME_2] DURATION

temp="$(mktemp)"
youtube-dl --get-url --get-filename "$1" > "$temp" # THIS IS STUPID
readarray -t urls < "$temp"
rm "$temp"
# urls[2] = filename

if [ -z "$3" ]; then
  ffmpeg -i "${urls[0]}" -i "${urls[1]}" -t "$2" -map 0:v -map 1:a -c copy "${urls[2]%.*}".mkv
elif ! [ -z "$4" ]; then
  ffmpeg -ss "$2" -i "${urls[0]}" -ss "$2" -i "${urls[1]}" -ss "$3" -t "$4" -map 0:v -map 1:a -c copy "${urls[2]%.*}".mkv
else
  ffmpeg -ss "$2" -i "${urls[0]}" -ss "$2" -i "${urls[1]}" -t "$3" -map 0:v -map 1:a -c copy "${urls[2]%.*}".mkv
fi

