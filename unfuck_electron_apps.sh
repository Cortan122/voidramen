#!/bin/bash

set -e

patch_app() {
  app="$1"
  patch="$2"

  temp_dir="$(mktemp -d)"
  asar e "$app" "$temp_dir"

  f="$temp_dir/stylesheets/tailwind.css"
  if [ -f "$f" ]; then
    echo "$patch" >> "$f"
  else
    set -- "$temp_dir"/dist/renderer.*.css
    echo "$patch" >> "$1"
  fi

  sudo asar p "$temp_dir" "$app"
  rm -rf "$temp_dir"
}

patch_app "/usr/lib/signal-desktop/resources/app.asar" '
div[role="group"] > button[role="radio"]:last-child [aria-label*="Unread Message"] {
  display: none;
}

.NavTabs__ItemUnreadBadge {
  display: none !important;
}
'

patch_app "/opt/FreeTube/resources/app.asar" "
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
