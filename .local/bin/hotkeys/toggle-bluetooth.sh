#!/bin/sh

set -e

if systemctl is-active bluetooth.service --quiet; then
  sudo systemctl stop bluetooth.service
  notify-send "🟦 Bluetooth" "Disabling bluetooth..."
else
  rfkill unblock 0
  rfkill unblock 4
  sudo systemctl start bluetooth.service
  notify-send "🟦 Bluetooth" "Enabling bluetooth..."
  sleep 2
  notify-send "🔵 Bluetooth Speaker" "$(bluetoothctl connect F4:4E:FC:1C:45:96)"
fi
