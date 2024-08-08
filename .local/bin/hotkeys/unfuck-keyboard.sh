#!/bin/sh

if [ -f ~/.config/x11/keymap.xkb ]; then
  xkbcomp -w2 ~/.config/x11/keymap.xkb "$DISPLAY"
else
  setxkbmap us,ru -option grp:toggle,grp:caps_toggle,grp:alt_shift_toggle,grp_led:caps
fi
xinput set-prop "Synaptics TM3276-022" "libinput Click Method Enabled" 0 0
xinput set-prop "Synaptics TM3276-022" "libinput Natural Scrolling Enabled" 1
xset r rate 500 34
