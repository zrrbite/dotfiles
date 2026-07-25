#!/bin/bash

# $INFO is only set when front_app_switched fires, so on a reload or a fresh
# login it is empty. Ask AeroSpace for the focused window instead.
APP="${INFO:-$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null)}"

sketchybar --set "$NAME" label="$APP"
