# Voidramen
_(made with soba and spaghetti code)_

This is my dotfiles repository.
In its current iteration, it is designed to work on Arch Linux.

Changes are propagated into `~/` by calling `./install.sh`.
That should also work for installing on a new system, but i haven't tested that in 1 year, so good luck...

## Cool features

- Custom `st` [fork](https://github.com/Cortan122/st) with nice scrolling and history behavior. Might try to migrate that to `kitty` in the future.
- Nice image in the tty login screen, [made using framebuffers](.local/bin/getty/neofetch.sh).
- There is an intel driver fix, that required me to recompile the x server myself...

## Overlay

I'm not sure yet, how i can apply overlays, without conflicting with whatever pacman does.

```bash
sudo cp -rvu --no-target-directory overlay/ /
```

## X11 fuckery

Because the last release was 5-10 years ago, we need some unreleased bugfixes.
Specifically we need the new versions of the x server and `xclip`.
