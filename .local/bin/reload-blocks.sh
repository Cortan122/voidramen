#!/bin/sh

for i in $(seq 1 10); do
  grep -q up /sys/class/net/[we]*/operstate && break
  echo "Waiting for network..."
  sleep "$i"
done

pkill --signal SIGRTMIN+5 i3blocks
pkill --signal SIGRTMIN+7 i3blocks
pkill --signal SIGRTMIN+10 i3blocks
