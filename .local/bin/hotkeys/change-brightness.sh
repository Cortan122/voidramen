#!/bin/sh

notify-send -t 500 "$(brightnessctl set "$1" | grep -Po "Current brightness: .*")"
