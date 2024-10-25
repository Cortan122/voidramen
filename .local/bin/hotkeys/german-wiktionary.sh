#!/bin/sh

selection="$(xclip -o -selection primary)"
xdg-open "https://en.wiktionary.org/wiki/$selection#German"
