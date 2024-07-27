#!/bin/sh

sudo="sudo"
[ "$(whoami)" = root ] && sudo=""
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
LLMNR=false
EOF

print_eduroam() {
  ssid="$1"
  login="$2"; [ -z "$login" ] && login="bonn-eduroam-login"
  pass="$3"; [ -z "$pass" ] && pass="bonn-eduroam-pass"
  cat <<EOF
network={
  ssid="$ssid"
  key_mgmt=WPA-EAP
  eap=PEAP
  phase2="autheap=MSCHAPV2"
  identity="$(pass "$login")"
  password="$(pass "$pass")"
}
EOF
}

(
  wpa_passphrase "$(pass bonn-tplink-wifi-name)" "$(pass bonn-tplink-wifi)"
  print_eduroam Studentenheim nika-wifi-login nika-wifi-pass
  print_eduroam eduroam
  print_eduroam eduroam-cs
  print_eduroam eduroam-stw
) | $sudo tee /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf
$sudo chown root:root /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf
$sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf

$sudo systemctl restart systemd-networkd.service
$sudo systemctl restart wpa_supplicant@wlp3s0.service
$sudo systemctl enable wpa_supplicant@wlp3s0.service
