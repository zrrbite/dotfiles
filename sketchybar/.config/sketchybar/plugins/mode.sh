#!/bin/bash

# Shows the AeroSpace mode while it isn't `main`, so resize mode can't be
# left on by accident: in it, h j k l resize windows instead of typing.
# Triggered by aerospace.toml's on-mode-changed; asks AeroSpace for the mode
# rather than taking it from the event, so a reload shows the right state.

MODE="$(aerospace list-modes --current 2>/dev/null)"

if [ -z "$MODE" ] || [ "$MODE" = main ]; then
    sketchybar --set "$NAME" drawing=off
else
    sketchybar --set "$NAME" drawing=on label="$(echo "$MODE" | tr '[:lower:]' '[:upper:]')"
fi
