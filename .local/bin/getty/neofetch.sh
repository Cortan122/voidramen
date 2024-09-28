#!/bin/sh

clear
export TERM="st"
sudo -u green hyfetch

~green/.local/bin/getty/fb_png ~green/.config/wall.png --gradient-start 500 --gradient-end 856
exit 0
