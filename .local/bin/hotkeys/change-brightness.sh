#!/bin/sh

set -e

result="$(brightnessctl set "$1" | grep -Po "Current brightness: .*")"

if [ "$result" = "Current brightness: 0 (0%)" ]; then
  result="$(brightnessctl set 1 | grep -Po "Current brightness: .*")"
fi

notify-send -t 500 "$result"
