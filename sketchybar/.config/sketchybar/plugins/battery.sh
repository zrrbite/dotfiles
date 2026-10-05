#!/bin/bash

# Nord
NORD11=0xffbf616a
NORD13=0xffebcb8b
NORD14=0xffa3be8c

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

# Tinted style: the item's accent at 20% alpha behind text in the full accent,
# instead of a solid accent fill with dark text. tint 0xffRRGGBB -> 0x33RRGGBB
tint() { echo "0x33${1:4}"; }

# Desktop Macs have no battery: `pmset -g batt` prints only the AC Power line
# and PERCENTAGE comes back empty, which would otherwise render a permanent
# charging pill labelled just "%". Hide the item instead.
if [ -z "$PERCENTAGE" ]; then
    sketchybar --set "$NAME" drawing=off
    exit 0
fi

# Material Design battery glyphs (nf-md-battery_*): charging, 80/60/40/20, and
# an alert outline when low.
if [ -n "$CHARGING" ]; then
    ICON="󰂄"
    COLOR=$NORD13
elif [ "$PERCENTAGE" -gt 80 ]; then
    ICON="󰂁"
    COLOR=$NORD14
elif [ "$PERCENTAGE" -gt 60 ]; then
    ICON="󰁿"
    COLOR=$NORD14
elif [ "$PERCENTAGE" -gt 40 ]; then
    ICON="󰁽"
    COLOR=$NORD14
elif [ "$PERCENTAGE" -gt 20 ]; then
    ICON="󰁻"
    COLOR=$NORD14
else
    ICON="󰂃"
    COLOR=$NORD11
fi

sketchybar --set "$NAME" \
    icon="$ICON" \
    label="${PERCENTAGE}%" \
    icon.color="$COLOR" \
    label.color="$COLOR" \
    background.color="$(tint "$COLOR")"
