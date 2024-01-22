#!/bin/bash

set -e
cd -- "$(dirname -- "$0")"
username="$1"
password="$2"

sudo="sudo"
[ "$(whoami)" == root ] && sudo=""
pm() {
  $sudo pacman --needed --noconfirm -S "$@"
}

pkg=(
  git sudo gcc make man-db man-pages openssh # build essentials
  vim nano bash-completion # text editors
  python3 python-pip python-numpy python-matplotlib # python
  ffmpeg imagemagick yt-dlp feh sxiv # media
  speedtest-cli tcc jq qrencode htop # extra stuff
)

# check if this is a graphical system (fixme)
if [ -e /dev/fb0 ]; then
  pkg+=(
    xorg-server xorg-xinput xorg-xrdb xf86-video-intel mesa # xorg
    i3-wm i3blocks dmenu xclip xcompmgr xwallpaper libnotify # window manager
    pulseaudio # audio (todo)
  )
fi
pm "${pkg[@]}"

# create user
if id "$username" >/dev/null 2>&1; then
  useradd -m -g wheel -s /bin/bash "$username"
  echo "$username:$password" | chpasswd
fi

# auto sudo
if $sudo [ ! -f "/etc/sudoers.d/000-$username" ]; then
  echo "$username ALL=(ALL) NOPASSWD: ALL" | $sudo tee "/etc/sudoers.d/000-$username"
  $sudo chmod 440 "/etc/sudoers.d/000-$username"
  $sudo chown root:root "/etc/sudoers.d/000-$username"
fi

sudo -i -u "$username" <<EOF
if [ -d .git/ ] && git remote get-url origin | grep -q Cortan122/voidrice.git; then
  echo "Alredy in repo..."
else
  mkdir ~/Programs
  cd ~/Programs
  git clone https://github.com/cortan122/voidrice.git
  cd ~/Programs/voidrice
fi
cp -r .config/ .local/ .bashrc .profile ~
cd ~
rm ~/.bash_logout ~/.bash_profile

sudo ln -fs ~/.config/nano/nanorc /root/.nanorc

if ! { command -v jitcc >/dev/null; } || [ ~/.local/bin/jitcc -ot ~/.local/bin/jitcc.c ]; then
  gcc -lcrypto ~/.local/bin/jitcc.c -o ~/.local/bin/jitcc
fi

if ! { command -v st >/dev/null; }; then
  cd ~/Programs/
  git clone https://github.com/cortan122/st.git
  cd st
  make
  sudo make install
fi

if ! { command -v yay >/dev/null; }; then
  cd ~/Programs
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
fi
EOF
