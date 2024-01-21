#!/bin/bash

[ -f "$PREFIX/etc/profile.d/bash_completion.sh" ] && source "$PREFIX/etc/profile.d/bash_completion.sh"
PKGFILE_PROMPT_INSTALL_MISSING=y
[ -f "/usr/share/doc/pkgfile/command-not-found.bash" ] && source /usr/share/doc/pkgfile/command-not-found.bash

if command -v ru2en.c >/dev/null; then
  declare -f original_command_not_found_handle >/dev/null || {
    declare -f command_not_found_handle >/dev/null || command_not_found_handle () {
      printf "bash: %s: command not found\n" "$1";
    }
    eval "original_$(declare -f command_not_found_handle)"

    command_not_found_handle () {
      eval "$(ru2en.c "$@")"
    }
    св () {
      eval "$(ru2en.c св "$@")"
    }
  }

  _пшеCompletion() {
    local res="$(ru2en.c "${COMP_WORDS[0]}")"
    [[ "$res" == original_command_not_found_handle* ]] && res="${COMP_WORDS[0]}"
    readarray -t COMPREPLY < <(compgen -c "$res")
  }
  complete -F _пшеCompletion -I
fi

complete -F _minimal g++
complete -F _minimal gcc
