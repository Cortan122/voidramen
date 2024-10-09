#!/bin/bash

set -e
cd -- "$(dirname -- "$0")"

list="$(pacman -Q)"
to_build=()

function version-lte {
  printf '%s\n' "$1" "$2" | sort -C -V
}

function check-pkgname {
  name="$(grep -Po '(?<=pkgname=).*' "$1"/PKGBUILD)"
  if ! grep -q "$name" <<<"$list"; then
    to_build+=("$1")
  else
    commit="$(git log -n 1 --pretty=format:%H -- "$1"/PKGBUILD)"
    new_version="r$(git rev-list --count "$commit").$(git rev-parse --short=7 "$commit")"
    old_version="$(grep -Po "(?<=$name )"'r[0-9]+\.[a-f0-9]{7}' <<<"$list")"

    if ! version-lte "$new_version" "$old_version"; then
      echo "$name: $old_version is less than $new_version. reinstalling..."
      to_build+=("$1")
    fi
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

  if [ "$stash_not_needed" = "false" ]; then
    git stash pop
  fi
fi
