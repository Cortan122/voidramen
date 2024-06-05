#!/bin/sh

BLOCK_BUTTON=2 ~/.local/bin/statusbar/volume
pkill --signal SIGRTMIN+10 i3blocks
