#!/usr/bin/env zsh

[ -f "$HOME/.config/envrc" ] && source "$HOME/.config/envrc"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Enable colors and change prompt:
autoload -U colors && colors
[ -f "$HOME/.config/aliasrc" ] && source "$HOME/.config/aliasrc"

setopt PROMPT_SUBST
PS1=$'zsh %{\e[?25h\e[0;92m%}%n' # PS1='\[\e[?25h\e[0;92m\]\u'
PS1+=$'%{%(?..\e[91m)%(130?.\e[93m.)%}' # PS1+='\[$(t=$? ;[ $t == 130 ] && echo -e "\e[93m" || ( [ $t != 0 ] && echo -e "\e[91m" ))\]'
PS1+=$'@%{\e[92m%}%m%{\e[0m%}:%{\e[94m%}%~%{\e[0m%}$ ' # PS1+='@\[\e[92m\]\h\[\e[0m\]:\[\e[94m\]\w\[\e[0m\]\$ '
# [ "$(tput cols)" -le 50 ] && PS1='\[\e[?25h\e[0m\]\$'


# History in cache directory:
HISTFILE=~/.config/zsh_history
HISTSIZE=10000000
SAVEHIST=10000000
# setopt BANG_HIST               # Treat the '!' character specially during expansion.
# setopt EXTENDED_HISTORY        # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'
zmodload zsh/complist
compinit -C
_comp_options+=(globdots)		# Include hidden files.
unsetopt BEEP

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^H" backward-kill-word

# Load zsh-syntax-highlighting; should be last.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
