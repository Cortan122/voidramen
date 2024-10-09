#!/bin/bash

set -e
cd -- "$(dirname -- "$0")"

list="$(pacman -Qq)"
to_build=()

function check-pkgname {
  name="$(grep -Po '(?<=pkgname=).*' "$1"/PKGBUILD)"
  if ! grep -q "$name" <<<"$list"; then
    to_build+=("$1")
  fi
}

if [ -n "$1" ]; then
  for arg in "$@"; do
    check-pkgname "$arg"
  done
else
  for i in */; do
    check-pkgname "$i"
  done
fi

function build {
  if ! { command -v yay >/dev/null; }; then
    makepkg -si --noconfirm
  else
    yay --answerdiff=None --noconfirm -Bi .
    git restore PKGBUILD
  fi
}

if (( "${#to_build[@]}" != 0 )); then
  stash_not_needed=false
  if git stash push | tee /dev/stderr | grep -q 'No local changes to save'; then
    stash_not_needed=true
  fi

  for f in "${to_build[@]}"; do
    (
      cd "$f"
      build
    )
  done

  [ "$stash_not_needed" = "false" ] && git stash pop
fi
