#!/bin/sh

sudo="sudo"
[ "$(whoami)" == root ] && sudo=""
pm() {
  $sudo pacman --needed --noconfirm -S "$@"
}

pm pass wpa_supplicant

$sudo tee /etc/systemd/network/25-wireless.network <<EOF
[Match]
Name=wlp3s0

[Network]
DHCP=yes
IgnoreCarrierLoss=3s
EOF

wpa_passphrase "$(pass bonn-tplink-wifi-name)" "$(pass bonn-tplink-wifi)" | $sudo tee /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf

$sudo systemctl restart systemd-networkd.service
$sudo systemctl start wpa_supplicant@wlp3s0.service
$sudo systemctl enable wpa_supplicant@wlp3s0.service
