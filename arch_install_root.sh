#!/bin/bash

set -e
cd -- "$(dirname -- "$0")"
username="$1"
password="$2"

[ -z "$username" ] && [ "$(whoami)" != "root" ] && username="$(whoami)"

sudo="sudo"
[ "$(whoami)" == root ] && sudo=""
pm() {
  $sudo pacman --color always --needed --noconfirm -S "$@" 2>&1 | grep -vP 'warning: .* is up to date -- skipping'
}

pkg=(
  git base-devel man-db man-pages openssh # build essentials
  vim nano bash-completion pkgfile # text editors
  python3 python-pip python-numpy python-matplotlib # python
  ffmpeg imagemagick yt-dlp feh sxiv # media
  speedtest-cli tcc jq qrencode htop # extra stuff
  dust bat tree # rusted coreutils
  hyfetch neofetch # gay logos
)

# check if this is a graphical system (fixme)
if [ -e /dev/fb0 ]; then
  pkg+=(
    xorg-server xorg-xinput xorg-xrdb xf86-video-intel mesa # xorg
    i3-wm i3blocks xclip xcompmgr libnotify # window manager
    rofi rofimoji xdotool # rofi (dmenu replacement)
    pipewire-pulse alsa-utils pulsemixer # audio
    dunst sysstat lm_sensors brightnessctl # statusbar stuff
    firefox telegram-desktop mpv # gui apps
    qemu-img nbd # mounting wsl
    cpupower tlp thermald # cpu throttling stuff
  )
fi
pm "${pkg[@]}"
[ -f /var/cache/pkgfile/core.files ] || $sudo pkgfile --update

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

if [ -d .git/ ] && git remote get-url origin | grep -iq Cortan122/voidrice; then
  repo_path="$(pwd)"
else
  repo_path=""
fi

sudo -i -u "$username" "$(pwd -P)/arch_install_user.sh" "$repo_path"
