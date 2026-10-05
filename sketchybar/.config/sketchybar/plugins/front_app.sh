#!/bin/bash

# $INFO is only set when front_app_switched fires, so on a reload or a fresh
# login it is empty. Ask AeroSpace for the focused window instead.
APP="${INFO:-$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null)}"

# Same icon map as the workspace pills (see spaces.sh). Some apps (WhatsApp)
# prefix their name with an invisible U+200E left-to-right mark.
# lint.sh runs shellcheck without -x; icon_result is assigned in icon_map.sh.
# shellcheck source=/dev/null
source "$CONFIG_DIR/plugins/icon_map.sh"
LRM=$'\xe2\x80\x8e'
APP="${APP#"$LRM"}"
__icon_map "$APP"

# shellcheck disable=SC2154
sketchybar --set "$NAME" icon="$icon_result" label="$APP"
