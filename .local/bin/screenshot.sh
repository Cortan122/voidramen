#!/bin/sh

set -e

location="$HOME/.cache/screenshot.png"
mode="screen"
copy="true"
delay="0"
report_errors="true"

while true; do
  case "$1" in
    '-f'|'--ffmpeg')
      mode="ffmpeg"
      shift
    ;;
    '-i'|'--interactive')
      mode="interactive"
      delay="0.2"
      shift
    ;;
    '-s'|'--full-screen')
      mode="screen"
      shift
    ;;
    '-n'|'--no-copy')
      copy="false"
      shift
    ;;
    '-q'|'--no-errors')
      report_errors="false"
      shift
    ;;
    '-d'|'--delay')
      delay="$2"
      shift 2
    ;;
    '-h'|'--help')
      echo 'Usage: screenshot.sh [OPTION]... [FILE]

Takes a screenshot and then copies it to the clipboard

  -f, --ffmpeg          Use ffmpeg to take the screenshot
                        this way the cursor also gets captured
  -i, --interactive     Prompt the user to select a region
                        will fail if the mouse is captured by another window
  -s, --full-screen     Capture the entire screen (default)

  -n, --no-copy         Do not copy the image into the clipboard
  -q, --no-errors       Do not send a notification in case of an error
  -d, --delay  %f       Delay, in seconds, before taking the screenshot
'
      exit
    ;;
    '--')
      shift
      break
    ;;
    *)
      break
    ;;
  esac
done

do_copy () {
  [ "$copy" = false ] && return

  xclip -selection clipboard -t image/png -i "$location"
}

do_screenshot () {
  case "$mode" in
    ffmpeg) ffmpeg -y -loglevel error -f x11grab -i :0 -vframes 1 -update 1 "$location" ;;
    screen) import -window root "$location" ;;
    interactive) import "$location" ;;
  esac

  # todo: warn if import is taking longer than expected
  # https://stackoverflow.com/a/11056286
}

do_error () {
  [ "$report_errors" = true ] && notify-send "$error"
  exit 1
}

[ -n "$1" ] && location="$1"
[ "$delay" != 0 ] && sleep "$delay"

error="$(do_screenshot 2>&1)" || do_error
do_copy
