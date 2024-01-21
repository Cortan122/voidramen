#!/bin/sh

set -xe

root_passwd="$1"
extra_pkg="intel-ucode"

root_partition=nvme0n1p4
efi_partition=nvme0n1p1
lsblk | grep "/dev/$root_partition" | grep "32.1G" || exit 1
lsblk | grep "/dev/$efi_partition" | grep "260M" || exit 1

mount --mkdir "$root_partition" /mnt
mount --mkdir "$efi_partition" /mnt/boot

pacstrap -K /mnt base linux linux-firmware $extra_pkg
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt <<EOT
set -xe

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

echo -e "\nen_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8" >> /etc/locale.gen
echo -e "LANG=en_US.UTF-8\nLC_TIME=ru_RU.UTF-8" > /etc/locale.conf
locale-gen

systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd

echo ThinkPad-T480 > /etc/hostname
echo "root:$root_passwd" | chpasswd
bootctl install
EOT

tee /mnt/boot/loader/loader.conf <<EOF
default  arch.conf
timeout  4
editor   no
EOF

tee /mnt/boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=1a1cec0e-5202-4e1a-a036-0ccdb4941854 rw
EOF

tee /mnt/boot/loader/entries/arch-fallback.conf <<EOF
title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux-fallback.img
options root=UUID=1a1cec0e-5202-4e1a-a036-0ccdb4941854 rw
EOF

tee /mnt/etc/systemd/network/20-wired.network <<EOF
[Match]
Name=enp0s20f0u4u2u1

[Network]
DHCP=yes
EOF

# shutdown -h now
