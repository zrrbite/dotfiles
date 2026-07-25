#!/bin/bash

# Nord
NORD4=0xffd8dee9
NORD8=0xff88c0d0
NORD10=0xff5e81ac

# $FOCUSED_WORKSPACE is only set when aerospace_workspace_change fires, so on a
# reload or a fresh login it is empty and nothing would be highlighted. Ask
# AeroSpace directly in that case.
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

# Active workspace mirrors waybar's `button.active`: indigo fill, light label.
# Waybar underlines it with `box-shadow: inset 0 -3px`; sketchybar has no
# bottom-only border, so a 1px cyan border around the pill stands in.
if [ "$1" = "$FOCUSED" ]; then
    sketchybar --set "$NAME" \
        background.drawing=on \
        background.color=$NORD10 \
        background.border_color=$NORD8 \
        background.border_width=1 \
        label.color=$NORD4
else
    sketchybar --set "$NAME" \
        background.drawing=off \
        background.border_width=0 \
        label.color=$NORD4
fi
