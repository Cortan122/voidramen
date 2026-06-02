#!/bin/bash

# include .bashrc if it exists
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"

# ssh over gpg
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
gpgconf --launch gpg-agent
gpg-connect-agent updatestartuptty /bye >/dev/null
