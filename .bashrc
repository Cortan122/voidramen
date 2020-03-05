#!/bin/bash

[ -f "$HOME/.config/envrc" ] && source "$HOME/.config/envrc"

# If not running interactively, don't do anything
[ -z "$BASH_VERSION" ] && return
[[ $- != *i* ]] && return

[ -f "$PREFIX/etc/profile.d/bash_completion.sh" ] && source "$PREFIX/etc/profile.d/bash_completion.sh"
PKGFILE_PROMPT_INSTALL_MISSING=y
[ -f "/usr/share/doc/pkgfile/command-not-found.bash" ] && source /usr/share/doc/pkgfile/command-not-found.bash

# enable color support of ls
[ -x "$(command -v dircolors)" ] && eval $( [ -e ~/.config/dircolors ] && dircolors -b ~/.config/dircolors || dircolors -b )
alias cls='clear'
alias where='whereis'
alias ls='ls --color=auto --group-directories-first'
alias la='ls -lAuGh --file-type'
alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'
alias grep='grep --color=auto'
alias R='R --quiet --no-save'
alias ln='ln --symbolic --interactive --verbose'
alias cp='cp --interactive --verbose'
alias mv='mv --interactive --verbose'
alias rm='rm --verbose'
alias mkd='mkdir --parents --verbose'

# ~/.inputrc
bind '"\e[1;5C":shell-forward-word'
bind '"\e[1;5D":shell-backward-word'
bind '"\e[3;5~":shell-kill-word'
bind '"\C-h":shell-backward-kill-word'
bind '"\e[1;6C":forward-word'
bind '"\e[1;6D":backward-word'
bind '"\e[3;6~":kill-word'
bind '"\e[127;6u":backward-kill-word' # only works in st
bind '"\C-e":glob-expand-word'

shopt -s checkwinsize
shopt -s autocd
shopt -s histappend
HISTSIZE= HISTFILESIZE=
HISTCONTROL=ignoreboth:erasedups
stty -ixon # Disable ctrl-s and ctrl-q.

if [[ "$(< /proc/version)" == *@(Microsoft|WSL)* ]]; then
  [ "$(echo "$PWD" | awk '{print tolower($0)}')" == "/mnt/c/windows/system32" ] && cd ~
  [ "$PWD" == "/" ] && cd ~
  winpath () { wslpath -ma "$1" 2>/dev/null || echo "C:/Debian/rootfs"$(readlink -f "$1") ;}
  Code () {  cmd.exe /C "code.cmd" "$(winpath "$1")" ;}
  subl () { "/mnt/c/Program Files/Sublime Text 3/sublime_text.exe" "$(winpath "$1")" &}
fi

if [ "$(uname -o)" == "Android" ]; then
  [ "$PWD" == "/data/data/com.termux/files/home" ] && cd /storage/emulated/0/Code
  PROMPT_COMMAND='history -a'
else
  umask 0022
  if command -v apt >/dev/null; then
    pm () {
      if [[ $1 == "" ]]; then
        sudo apt "$@"
      elif [[ "install" == $1* ]]; then
        sudo apt-get install "${@:2}"
      elif [[ "up" == $1 && $# == 1 ]]; then
        sudo apt-get update
        sudo apt-get dist-upgrade
        sudo apt-get autoremove
      elif [[ "upgrade" == $1* ]]; then
        sudo apt-get upgrade "${@:2}"
      elif [[ "update" == $1* ]]; then
        sudo apt-get update "${@:2}"
      elif [[ "search" == $1* ]]; then
        sudo apt search "${@:2}"
      elif [[ "remove" == $1* || "uninstall" == $1* || "rm" == $1 ]]; then
        sudo apt-get remove "${@:2}"
      else
        sudo apt "$@"
      fi
    }
    if [ -f "/usr/share/bash-completion/completions/apt" ]; then
      source /usr/share/bash-completion/completions/apt
      complete -F _apt pm
    fi
  fi
fi

PS1='\[\e[?25h\e[0;92m\]\u'
PS1+='\[$(t=$? ;[ $t "==" 130 ] && echo -e "\e[93m" || ( [ $t != 0 ] && echo -e "\e[91m" ))\]'
PS1+='@\[\e[92m\]\h\[\e[0m\]:\[\e[94m\]\w\[\e[0m\]\$ '
[ "$(tput cols)" -le 50 ] && PS1='\[\e[?25h\e[0m\]\$'

# If this is an xterm set the title to '{command} user@host:dir'
if [[ "$TERM" != linux* ]]; then
  PS1_TITLE="\u@\h: \w"
  [ "$(tput cols)" -le 50 ] && PS1_TITLE="\w"
  PS1="\[\e]0;$PS1_TITLE\a\]$PS1"
  if [[ ${BASH_VERSINFO[0]} -ge 5 || ${BASH_VERSINFO[0]} == 4 && ${BASH_VERSINFO[1]} -ge 4 ]]; then
    trap 'printf "\033]0;{%s} %s\007" "${BASH_COMMAND//[^[:print:]]/}" "${PS1_TITLE@P}"' DEBUG
  fi
fi
