#!/bin/bash

set -e

date +"[%d.%m.%Y %H:%M]" | tr -d '\n'  | xclip -in -selection clipboard

xdotool key --clearmodifiers ctrl+v
