#!/bin/bash

cd -- "$(dirname -- "$0")"
find . -type d -name '.git' -prune -o -type f -exec chmod 644 {} \;
find . -type d -name '.git' -prune -o -type d -exec chmod 755 {} \;
chmod +x install.sh
cp -r .[!.]* * ~

cd ~
rm -f ~/.bash_logout ~/.bash_profile ~/install.sh
rm -rf ~/.git
chmod +x ~/.local/bin/*

cd ~/Programs/st
chmod +x *.sh st st-copyout
cd ~

[ -z "$PREFIX" ] || echo "include $PREFIX/share/nano/*" > ~/.nanorc
[ "$(uname -o)" == "Android" ] && rm -f ~/.profile #fixme

command -v sudo >/dev/null || exit 0

if [[ "$(< /proc/version)" == *@(Microsoft|WSL)* ]]; then
  ln -Ts /mnt/b/apache/www ~/www
  ln -Ts /mnt/b/костя/видухи ~/Videos
  ln -Ts "$(wslpath "$(cmd.exe /c echo %USERPROFILE%\\Downloads)" | tr '\r' '/')" ~/Downloads
fi

sudo ln -s ~/.nanorc /root

if command -v pacman >/dev/null && ! { command -v yay >/dev/null; }; then
  sudo pacman -Syyuu --noconfirm
  echo -e 'n\n\n' | sudo pacman -S git base-devel --needed
  cd ~/Programs
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ~

  yay --noeditmenu --nodiffmenu --save
fi

if command -v pacman >/dev/null && ! { locale -a | grep ru_RU >/dev/null; }; then
  # Uncomment the Color line in /etc/pacman.conf.
  sudo sed -i 's/^#Color$/Color/' /etc/pacman.conf
  # раскомментируйте ru_RU.UTF-8 UTF-8 в файле /etc/locale.gen
  sudo sed -i 's/^#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
  # После сохранения файла сгенерируйте выбранные локали командой:
  sudo locale-gen
fi

packageList="npm nodejs python2 python3 bash-completion ffmpeg youtube-dl imagemagick lolcat php openssh python-pip feh qrencode sxiv"
if command -v pacman >/dev/null; then
  sudo pacman --needed --noconfirm -S $packageList
elif command -v apt >/dev/null; then
  sudo apt install -y $packageList
fi

sudo pip install numpy sympy matplotlib gTTS speedtest-cli

[ "$1" == "--delete" ] && rm -rf -- "$(dirname -- $0)"
