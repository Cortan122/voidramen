#!/bin/sh

set -e

# is this more or less of a bodge compared to:
# sudo rm /usr/share/icons/AdwaitaLegacy/*/legacy/dialog-information.png

css_patch="
.shaka-bottom-controls {
  padding: 0 !important;
}

.shaka-play-button {
  display: none !important;
}

.shaka-range-container {
  margin: 0 !important;
}

.shaka-scrim-container {
  background: linear-gradient(0deg, #000 0, transparent 40px) !important;
  transition: none !important;
}

.shaka-bottom-controls * {
  transition: none !important;
}

.playerFullscreenTitleOverlay {
  transition: none !important;
}"

temp_dir="$(mktemp -d)"
asar e /opt/FreeTube/resources/app.asar "$temp_dir"

set -- "$temp_dir"/dist/renderer.*.css
echo "$css_patch" >> "$1"

sudo asar p "$temp_dir" /opt/FreeTube/resources/app.asar

trap "exit 1"              HUP INT PIPE QUIT TERM
trap 'rm -rf "$temp_dir"'  EXIT
