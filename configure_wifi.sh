#!/bin/sh

set -e

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

# does not work
print_bit_802() {
  cat <<EOF
network={
  ssid="802.1X"
  key_mgmt=WPA-EAP
  eap=TTLS
  phase2="autheap=PAP"
  anonymous_identity="anonymous@wlan.informatik.uni-bonn.de"
  ca_cert="/etc/ssl/certs/ISRG_Root_X1.pem"
  altsubject_match="DNS:radius.informatik.uni-bonn.de"
  identity="$(pass 802.1X-wifi-login)"
  password="$(pass 802.1X-wifi)"
}
EOF
}

print_wpa_eap() {
  ssid="$1"
  login="$2"
  pass="$3"
  cat <<EOF
network={
  ssid="$ssid"
  key_mgmt=WPA-EAP
  eap=PEAP
  phase2="autheap=MSCHAPV2"
  identity="$login"
  password="$pass"
}
EOF
}

print_eduroam() {
  ssid="$1"
  login="$2"; [ -z "$login" ] && login="bonn-eduroam-login"
  pass="$3"; [ -z "$pass" ] && pass="bonn-eduroam-pass"
  word_login="$(pass "$login")"
  word_pass="$(pass "$pass")"
  cat <<EOF
network={
  ssid="$ssid"
  key_mgmt=WPA-EAP
  eap=PEAP
  phase2="autheap=MSCHAPV2"
  identity="$word_login"
  password="$word_pass"
  ca_cert="/etc/ssl/certs/uni-bonn-eduroam.pem"
}
EOF
}

parse_qrcode_str() {
  text="$1"
  if echo "$text" | grep -qvF "WIFI:"; then
    return
  fi

  trimmed_text="$(echo "$text" | grep -oP '(?<=WIFI:).*(?=;)')"
  uuid="$(echo "$trimmed_text" | grep -oP '(?<=S:).*?[^\\](?=;)' | sed 's/\\;/;/g' | sed 's/\\\\/\\/g')"
  pass="$(echo "$trimmed_text" | grep -oP '(?<=P:).*?[^\\](?=;)' | sed 's/\\;/;/g' | sed 's/\\\\/\\/g')"
  wpa_passphrase "$uuid" "$pass"
}

parse_qrcode() {
  # todo: if the clipboard is literally empty, this crashes
  targets="$(xclip -selection clipboard -target TARGETS -out)"

  if echo "$targets" | grep -q UTF8_STRING; then
    parse_qrcode_str "$(xclip -selection clipboard -out)"
  fi
  if echo "$targets" | grep -q image/png; then
    xclip -selection clipboard -t image/png ~/.cache/screenshot.png >/dev/null
    parse_qrcode_str "$(zbarimg -q -1 ~/.cache/screenshot.png)"
  fi
}

print_wifi() {
  wpa_passphrase "$(pass "$1"-wifi-name)" "$(pass "$1"-wifi-pass)"
}

print_39c3() {
  cat <<EOF
network={
  ssid="39C3"
  key_mgmt=WPA-EAP
  eap=TTLS
  identity="allowany"
  password="allowany"
  ca_cert="/etc/ssl/certs/ISRG_Root_X1.pem"
  altsubject_match="DNS:radius.c3noc.net"
  phase2="auth=PAP"
}
EOF
}

# todo: set `scan_freq=2462` for `nika-roof`

(
  if [ -n "$1" ]; then
    if [ -n "$2" ]; then
      wpa_passphrase "$1" "$2"
    else
        cat <<EOF
network={
  ssid="$1"
  key_mgmt=NONE
}
EOF
    fi
  fi
cat <<EOF
ctrl_interface=/run/wpa_supplicant
update_config=1

EOF
  parse_qrcode
  print_wifi "redmi-T9"
  print_wifi "fritzbox"
  # print_bit_802
  print_eduroam eduroam
  print_eduroam eduroam-cs
  print_eduroam eduroam-stw
  print_wpa_eap CCCAC cccac 23cccac42
) | $sudo tee /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf
$sudo chown root:root /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf
$sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf

$sudo systemctl restart systemd-networkd.service
$sudo systemctl restart wpa_supplicant@wlp3s0.service
$sudo systemctl enable wpa_supplicant@wlp3s0.service
