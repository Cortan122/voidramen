#!/bin/bash

set -e
cd -- "$(dirname -- "$0")"
username="$1"
password="$2"

[ -z "$username" ] && [ "$(whoami)" != "root" ] && username="$(whoami)"

sudo="sudo"
[ "$(whoami)" == root ] && sudo=""
pm() {
  $sudo pacman --needed --noconfirm -S "$@"
}

pkg=(
  git base-devel man-db man-pages openssh # build essentials
  vim nano bash-completion pkgfile # text editors
  python3 python-pip python-numpy python-matplotlib # python
  ffmpeg imagemagick yt-dlp feh sxiv # media
  speedtest-cli tcc jq qrencode htop # extra stuff
  dust bat tree # rusted coreutils
)

# check if this is a graphical system (fixme)
if [ -e /dev/fb0 ]; then
  pkg+=(
    xorg-server xorg-xinput xorg-xrdb xf86-video-intel mesa # xorg
    i3-wm i3blocks dmenu xclip xcompmgr libnotify # window manager
    pulseaudio alsa-utils # audio
    dunst sysstat calcurse bc lm_sensors # statusbar stuff
  )
fi
pm "${pkg[@]}"
$sudo pkgfile --update

# create user
if ! { id "$username" >/dev/null 2>&1; } ; then
  useradd -m -g wheel -s /bin/bash "$username"
  echo "$username:$password" | chpasswd
fi

# auto sudo
if $sudo [ ! -f "/etc/sudoers.d/000-$username" ]; then
  echo "$username ALL=(ALL) NOPASSWD: ALL" | $sudo tee "/etc/sudoers.d/000-$username"
  $sudo chmod 440 "/etc/sudoers.d/000-$username"
  $sudo chown root:root "/etc/sudoers.d/000-$username"
fi

if [ -d .git/ ] && git remote get-url origin | grep -iq Cortan122/voidrice; then
  repo_path="$(pwd)"
else
  repo_path=""
fi

sudo -i -u "$username" "$(pwd -P)/install_as_user.sh" "$repo_path"
