#!/bin/sh

set -e

if [ "$1" = "optional" ]; then
  config_path="/etc/systemd/logind.conf"
  status="$(awk '/HandleLidSwitch=/' "$config_path" | cut -d'=' -f2)"

  if [ "$status" != "lock" ]; then
    sleep 10
    exit
  fi
fi

# todo: force it to redraw itself
dunstctl set-paused true
i3lock -i ~/.config/wall.png --show-keyboard-layout --nofork
dunstctl set-paused false

pkill --signal SIGRTMIN+12 i3blocks
