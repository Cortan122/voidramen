#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"
repo_path="$1"

clone() {
  mkdir -p ~/Programs
  cd ~/Programs
  git clone "$1"
  cd "$(basename "$1" .git)"
}

if [ -z "$repo_path" ]; then
  clone https://github.com/cortan122/voidrice.git
  repo_path="$PWD"
else
  cd "$repo_path"
fi

cp -drvu .config/ .local/ .bashrc .profile ~
cd ~
rm -f ~/.bash_logout ~/.bash_profile

sudo ln -fs ~/.config/nano/nanorc /root/.nanorc

if ! { command -v jitcc >/dev/null; } || [ ~/.local/bin/jitcc -ot ~/.local/bin/jitcc.c ]; then
  gcc -lcrypto ~/.local/bin/jitcc.c -o ~/.local/bin/jitcc
fi

if ! { command -v st >/dev/null; }; then
  clone https://github.com/cortan122/st.git
  make
  sudo make install
fi

if ! { command -v yay >/dev/null; }; then
  clone https://aur.archlinux.org/yay.git
  makepkg -si --noconfirm
fi

pm() {
  yay --answerdiff=None --needed --noconfirm -S "$@"
}

if ! { command -v boomer >/dev/null; }; then
  clone https://github.com/Cortan122/boomer
  pm nim
  nimble -y build
  sudo install -D boomer /usr/local/bin
fi

if ! { command -v raylid >/dev/null; }; then
  clone https://github.com/Cortan122/ImageEditor
  pm raylib glfw
  sudo make install
fi

cd "$repo_path"
[ -d "$HOME/.mozilla/firefox" ] && ./configure_firefox.sh

# fonts
pm alttab noto-fonts-emoji-blob snixembed talon-bin
# pm vscodium-bin prismlauncher freetube-bin sublime-text-4
