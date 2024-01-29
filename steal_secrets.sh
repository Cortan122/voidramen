#!/bin/sh

set -e

VHDX_IMG="/mnt/c/Arch/ext4.vhdx"
sudo mount -t ntfs3 --mkdir /dev/nvme0n1p3 /mnt/c

sudo modprobe nbd max_part=16

sudo qemu-nbd -c /dev/nbd0 "$VHDX_IMG"
sudo mount --mkdir -o rw,nouser /dev/nbd0 /mnt/wsl

wsl_home="$(echo /mnt/wsl/home/*)"
sudo cp --preserve=mode -vru "$wsl_home/.ssh" -t ~
sudo cp --preserve=mode -vru "$wsl_home/.gnupg" -t ~
sudo cp --preserve=mode -vru "$wsl_home/.config/password-store/" -t ~/.config/
sudo chown -R "$USER:$USER" ~/.ssh ~/.gnupg ~/.config/password-store/

sudo umount /mnt/wsl && sudo qemu-nbd -d /dev/nbd0 && sudo rmmod nbd
sudo umount /mnt/c
