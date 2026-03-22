#!/bin/sh

set -e

strip_codes () {
  sed 's|\x1B\[[?0-9;]*[a-zA-Z]||g'
}

speaker_id="F4:4E:FC:1C:45:96"
speaker_id2="dev_F4_4E_FC_1C_45_96"

if ! systemctl is-active bluetooth.service --quiet; then
  sudo systemctl start bluetooth.service
  notify-send "🟦 Bluetooth" "Enabling bluetooth..."
fi

rfkill unblock all

connect () {
  sudo dbus-send --print-reply --system --dest=org.bluez \
    "/org/bluez/hci0/$speaker_id2" \
    org.bluez.Device1.ConnectProfile \
    string:0000110b-0000-1000-8000-00805f9b34fb
}

list_of_speakers="$(LANG=C pactl list | grep -A2 'Source #' | grep 'Name: ' | cut -d" " -f2)"
if echo "$list_of_speakers" | grep -q "$speaker_id"; then
  notify-send "🟥 Bluetooth" "Disconnecting bluetooth..."
  notify-send "🔴 Bluetooth Speaker" "$(bluetoothctl disconnect "$speaker_id" | strip_codes)"
else
  notify-send "🟦 Bluetooth" "Connecting bluetooth..."
  notify-send "🔵 Bluetooth Speaker" "$(connect 2>&1 | strip_codes)"
  sleep 2
  notify-send "🔋 Speaker Battery" "$(bluetoothctl info "$speaker_id" | grep "Battery Percentage" | grep -Po "\([0-9]*\)" | tr --del '()' || echo "NaN")%"
fi

