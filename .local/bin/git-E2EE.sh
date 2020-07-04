#!/bin/bash

function reset {
	[ -d ~/.cache/git-E2EE ] && rm -r ~/.cache/git-E2EE
	mkdir ~/.cache/git-E2EE
	chmod 700 ~/.cache/git-E2EE
	read -s -p "Password:" password
	echo
	password="$(echo "$password" | openssl enc -base64)" # это чтобы в паролях могли быть пробелы и всякие там русские буквы
	salt="f804cd7653bfd670" # нам тут надо чтобы всё было deterministic и поэтому нам надо захардкодить какуюто соль
	echo "openssl enc -S $salt -aes-256-cbc -pbkdf2 -pass pass:$password" > ~/.cache/git-E2EE/clean.sh
	echo "openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:$password 2>/dev/null || cat" > ~/.cache/git-E2EE/smudge.sh
	echo "openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:$password -in \"\$1\" 2>/dev/null || cat \"\$1\"" > ~/.cache/git-E2EE/diff.sh
	chmod 600 ~/.cache/git-E2EE/*
	chmod +x ~/.cache/git-E2EE/*
}

[ -d ~/.cache/git-E2EE ] || reset

gitattributes="$(cat <<EOF
* filter=openssl diff=openssl
[merge]
	renormalize=true
EOF
)"

filter="$(cat <<EOF
[filter "openssl"]
	clean = ~/.cache/git-E2EE/clean.sh
	smudge = ~/.cache/git-E2EE/smudge.sh
	required

[diff "openssl"]
	textconv = ~/.cache/git-E2EE/diff.sh

[filter "lfs"]
	smudge = ~/.cache/git-E2EE/smudge.sh | git-lfs smudge
	process = git-lfs filter-process
	required = true
	clean = ~/.cache/git-E2EE/clean.sh | git-lfs clean
EOF
)"

if [ "$1" == "init" ]; then
	git init
	echo "$gitattributes" > .git/info/attributes
	echo "$filter" >> .git/config
elif [ "$1" == "change-password" ]; then
	reset
elif [ "$1" == "lfs" ]; then
	[ -f .gitattributes ] || mv .git/info/attributes .gitattributes
	git "$@"
elif [ "$1" == "clone" ]; then
	git clone --no-checkout "$2" "$3"
	cd "$3"
	echo "$gitattributes" > .git/info/attributes
	echo "$filter" >> .git/config
	git reset --hard HEAD
elif [ "$1" == "help" -o "$1" == "--help" ]; then
	echo "Usage: $0 init"
	echo "       $0 change-password"
	echo "       $0 clone URL DIR"
	echo "       $0 help"
fi

# git ls-tree -rl --full-name HEAD | awk '$4 > 100000000 {$1=$2=$3=$4=""; print $0}' | sed 's/^ *//'
# find . -type f -size +100M
