#!/bin/sh

sudo="sudo"
[ "$(whoami)" == root ] && sudo=""
pm() {
  $sudo pacman --color always --needed --noconfirm -S "$@" 2>&1 | grep -vP 'warning: .* is up to date -- skipping'
}

pm pass wpa_supplicant

$sudo tee /etc/systemd/network/25-wireless.network <<EOF
[Match]
Name=wlp3s0

[Network]
DHCP=yes
IgnoreCarrierLoss=3s
EOF

print_eduroam() {
  ssid="$1"
  cat <<EOF
network={
  ssid="$ssid"
  key_mgmt=WPA-EAP
  eap=PEAP
  phase2="autheap=MSCHAPV2"
  identity="$(pass bonn-eduroam-login)"
  password="$(pass bonn-eduroam-pass)"
}
EOF
}

(
  wpa_passphrase "$(pass bonn-tplink-wifi-name)" "$(pass bonn-tplink-wifi)"
  print_eduroam eduroam
  print_eduroam eduroam-cs
  print_eduroam eduroam-stw
) | $sudo tee /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf
$sudo chown root:root /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf
$sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf

$sudo systemctl restart systemd-networkd.service
$sudo systemctl start wpa_supplicant@wlp3s0.service
$sudo systemctl enable wpa_supplicant@wlp3s0.service
