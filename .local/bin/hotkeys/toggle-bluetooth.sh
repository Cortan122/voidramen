#!/bin/sh

set -e

strip_codes () {
  sed 's|\x1B\[[?0-9;]*[a-zA-Z]||g'
}

speaker_id="F4:4E:FC:1C:45:96"

if ! systemctl is-active bluetooth.service --quiet; then
  sudo systemctl start bluetooth.service
  notify-send "🟦 Bluetooth" "Enabling bluetooth..."
fi

rfkill unblock all

list_of_speakers="$(LANG=C pactl list | grep -A2 'Source #' | grep 'Name: ' | cut -d" " -f2)"
if echo "$list_of_speakers" | grep -q "$speaker_id"; then
  notify-send "🟥 Bluetooth" "Disconnecting bluetooth..."
  notify-send "🔴 Bluetooth Speaker" "$(bluetoothctl disconnect "$speaker_id" | strip_codes)"
else
  notify-send "🟦 Bluetooth" "Connecting bluetooth..."
  notify-send "🔵 Bluetooth Speaker" "$(bluetoothctl connect "$speaker_id" | strip_codes)"
  sleep 2
  notify-send "🔋 Speaker Battery" "$(bluetoothctl info F4:4E:FC:1C:45:96 | grep "Battery Percentage" | grep -Po "\([0-9]*\)" | tr --del '()' || echo "NaN")%"
fi
