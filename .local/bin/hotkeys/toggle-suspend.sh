#!/bin/sh

# look up this as well:
# https://help.ubuntu.com/community/LaptopLidAndDockScripts

# source:
# https://old.reddit.com/r/archlinux/comments/12fapkq/

# change HandleLidSwitch value
CONFIG_PATH="/etc/systemd/logind.conf"
STATUS="$(awk '/HandleLidSwitch=/' "${CONFIG_PATH}" | cut -d'=' -f2)"
if [ "${STATUS}" = "suspend-then-hibernate" ]; then
  sudo sed -i '/HandleLidSwitch=/c HandleLidSwitch=ignore' "${CONFIG_PATH}"
  echo "HandleLidSwitch=ignore"
  echo "Your laptop will not go to sleep mode upon closing the lid!"
elif [ "${STATUS}" = "ignore" ]; then
  sudo sed -i '/HandleLidSwitch=/c HandleLidSwitch=suspend-then-hibernate' "${CONFIG_PATH}"
  echo "HandleLidSwitch=suspend-then-hibernate"
  echo "Your laptop will go to sleep mode upon closing the lid!"
else
  echo "Error..."
fi

# To apply any changes, signal systemd-logind with HUP
sudo systemctl kill -s HUP systemd-logind
