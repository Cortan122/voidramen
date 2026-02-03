#!/bin/bash

[ -f "$HOME/.config/envrc" ] && source "$HOME/.config/envrc"

# If not running interactively, don't do anything
[ -z "$BASH_VERSION" ] && return
[[ $- != *i* ]] && return

[ -f "$HOME/.config/completion.bash" ] && source "$HOME/.config/completion.bash"
[ -f "$HOME/.config/aliasrc" ] && source "$HOME/.config/aliasrc"

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

set +H # disable ! style history substitution
shopt -s checkwinsize
shopt -s autocd
shopt -s histappend
shopt -s globstar
HISTSIZE= HISTFILESIZE=
HISTCONTROL=ignoreboth:erasedups
[ -f "$HOME/.config/bash_history" ] || {
  mkdir -p "$HOME/.config"
  [ -f ~/.bash_history ] && cp ~/.bash_history "$HOME/.config/bash_history"
}
HISTFILE="$HOME/.config/bash_history"
stty -ixon # Disable ctrl-s and ctrl-q.

cd "$(pathfinder.c)"

if [ "$(uname -o)" == "Android" ]; then
  mkdir -p /storage/emulated/0/Code
  PROMPT_COMMAND='history -a'
else
  umask 0022
  if command -v code.cmd >/dev/null; then
    Code () {
      [ ! -e "$1" ] && touch "$1"
      cmd.exe /C "code.cmd" "$(wslpath -ma "$1")"
    }
  fi
  if [[ "$(< /proc/version)" == *@(microsoft|WSL2)* ]]; then
    export DISPLAY="$(ip route list default | awk '{print $3}'):0"
  fi
  # todo: command -v apt is very slow
  if command -v apt >/dev/null; then
    pm () {
      if [[ $1 == "" ]]; then
        sudo apt "$@"
      elif [[ "install" == $1* ]]; then
        sudo apt-get install "${@:2}"
      elif [[ "up" == $1 && $# == 1 ]]; then (
        export DEBIAN_FRONTEND=noninteractive
        sudo apt-get update --yes
        sudo apt-get dist-upgrade --yes
        sudo apt-get autoremove --yes
        sudo apt-get autoclean --yes
      ) elif [[ "upgrade" == $1* ]]; then
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

PROMPT_DIRTRIM=5
PS1='\[\e[?25h\e[0;92m\]\u'
PS1+='\[\e[5 q\]' # change cursor shape to "line"
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

# todo: remove this, its fucking silly
rmdir ~/Thunderbird/ 2>/dev/null || true
