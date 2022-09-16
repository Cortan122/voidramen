#!/bin/bash

# git pull --recurse-submodules

cd -- "$(dirname -- "$0")"
find . -type d -name '.git' -prune -o -type f -exec chmod 644 {} \;
find . -type d -name '.git' -prune -o -type d -exec chmod 755 {} \;
chmod +x install.sh
cp -r .[!.]* * ~

cd ~
rm -f ~/.bash_logout ~/.bash_profile ~/install.sh
rm -rf ~/.git
chmod +x ~/.local/bin/*  ~/.local/bin/statusbar/*

if [ "$(uname -o)" == "Android" ] && ! { command -v make >/dev/null; }; then
  pkg install clang make ncurses-utils pkg-config
  cat > "$PREFIX/etc/motd"
  termux-setup-storage || echo Run: termux-setup-storage
fi

if ! { command -v jitcc >/dev/null; } || [ ~/.local/bin/jitcc -ot ~/.local/bin/jitcc.c ]; then
  gcc -lcrypto ~/.local/bin/jitcc.c -o ~/.local/bin/jitcc
fi

cd ~/Programs/st
chmod +x *.sh st-copyout
[ -f st ] && chmod +x st
cd ~

[ -z "$PREFIX" ] || echo "include $PREFIX/share/nano/*" > ~/.nanorc
[ "$(uname -o)" == "Android" ] && rm -f ~/.profile #fixme

command -v sudo >/dev/null || exit 0

if [[ "$(< /proc/version)" == *@(microsoft|Microsoft|WSL)* ]]; then
  pushd /mnt/c > /dev/null
  ln -Tfs /mnt/b/apache/www ~/www
  ln -Tfs /mnt/b/костя/видухи ~/Videos
  ln -Tfs "$(wslpath "$(cmd.exe /c echo %USERPROFILE%\\Downloads)" | tr -d '\r')" ~/Downloads
  ln -Tfs "$(wslpath "$(cmd.exe /c echo %USERPROFILE%\\Desktop)" | tr -d '\r')" ~/Desktop
  ln -Tfs "$(wslpath "$(cmd.exe /c echo %USERPROFILE%\\OneDrive\\microrice)" | tr -d '\r')" ~/Programs/microrice
  ln -Tfs "$(wslpath "$(cmd.exe /c echo %USERPROFILE%\\OneDrive\\dz2019)" | tr -d '\r')" ~/dz2019
  ln -Tfs "$(wslpath "$(cmd.exe /c echo %USERPROFILE%\\OneDrive\\dz2020)" | tr -d '\r')" ~/dz2020
  ln -Tfs "$(wslpath "$(cmd.exe /c echo %USERPROFILE%\\OneDrive\\dz2021)" | tr -d '\r')" ~/dz2021
  ln -Tfs "$(wslpath "$(cmd.exe /c echo %USERPROFILE%\\OneDrive\\dz2022)" | tr -d '\r')" ~/dz2022
  popd > /dev/null
fi

sudo ln -fs ~/.nanorc /root

if command -v pacman >/dev/null && ! { command -v yay >/dev/null; }; then
  sudo pacman -Syyuu --noconfirm

  if pacman -Si yay >/dev/null 2>&1; then
    # yay can be installed from the repos on manjaro
    sudo pacman -S yay --noconfirm --needed
  else
    # installing yay from the aur
    echo -e 'n\n\n' | sudo pacman -S git base-devel --needed
    cd ~/Programs
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
  fi

  yay --noeditmenu --nodiffmenu --save
fi

if command -v pacman >/dev/null && ! { locale -a | grep ru_RU >/dev/null; }; then
  # Uncomment the Color line in /etc/pacman.conf.
  sudo sed -i 's/^#Color$/Color/' /etc/pacman.conf
  # раскомментируйте ru_RU.UTF-8 UTF-8 в файле /etc/locale.gen
  sudo sed -i 's/^# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
  # После сохранения файла сгенерируйте выбранные локали командой:
  sudo locale-gen
fi

if sudo [ ! -f "/etc/sudoers.d/000-cortan122" ]; then
  echo "cortan122 ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/000-cortan122"
  sudo chmod 440 "/etc/sudoers.d/000-cortan122"
  sudo chown root:root "/etc/sudoers.d/000-cortan122"
fi

if ! { command -v st >/dev/null; }; then
  cd ~/Programs/st
  make
  sudo make install
  cd ~
fi

# todo: this is slow, put it in some kind of if
packageList="npm nodejs python3 bash-completion ffmpeg youtube-dl imagemagick php openssh python-pip feh qrencode sxiv python-numpy python-scipy python-matplotlib speedtest-cli tcc jq"
if command -v pacman >/dev/null; then
  sudo pacman --needed --noconfirm -S $packageList
elif command -v apt >/dev/null; then
  sudo apt install -y $packageList
fi

# sudo pip install gTTS

[ "$1" == "--delete" ] && rm -rf -- "$(dirname -- $0)"
