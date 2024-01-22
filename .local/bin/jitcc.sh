#!/bin/bash

## its faster if we dont check
ifinstalled openssl gcc realpath || exit 1
[ -z "$1" ] && exit 1

hash="$(echo -n "$(realpath -- "$1")" | openssl dgst -binary -sha1 | openssl base64 | tr '/+' '_-' | sed 's/=//g')"
cachepath="$HOME/.cache/jitcc"
filename="$cachepath/$hash"
mkdir -p "$cachepath"

if [ ! -f "$filename" ] || [ "$filename" -ot "$1" ]; then
  sed '1s/^#!.*//' "$1" | gcc -lm -x c - -o "$filename" || exit 1
fi

"$filename" "${@:2}"
