#!/bin/sh

selection="$(xclip -o -selection primary)"
xdg-open "https://en.wikipedia.org/wiki/$selection?useskin=vector"
