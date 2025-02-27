#!/bin/bash

set -e
cd -- "$(dirname -- "$0")"
username="$1"
password="$2"

[ -z "$username" ] && [ "$(whoami)" != "root" ] && username="$(whoami)"

sudo="sudo"
[ "$(whoami)" = root ] && sudo=""

pkg=(base)
[ -e /dev/fb0 ] && pkg+=(graphical)
./packages/install_packages.sh "${pkg[@]}"

# create user
if ! { id "$username" >/dev/null 2>&1; } ; then
  $sudo useradd -m -s /bin/bash "$username"
  $sudo usermod -a -G wheel "$username"
  echo "$username:$password" | chpasswd
fi

# auto sudo
if $sudo [ ! -f "/etc/sudoers.d/000-$username" ]; then
  echo "$username ALL=(ALL) NOPASSWD: ALL" | $sudo tee "/etc/sudoers.d/000-$username"
  $sudo chmod 440 "/etc/sudoers.d/000-$username"
  $sudo chown root:root "/etc/sudoers.d/000-$username"
fi

if [ -d .git/ ] && git remote get-url origin | grep -iq Cortan122/voidramen; then
  repo_path="$(pwd)"
else
  repo_path=""
fi

sudo -i -u "$username" "$(pwd -P)/arch_install_user.sh" "$repo_path"
