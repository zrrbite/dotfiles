#!/bin/bash

# Nord
NORD0=0xff2e3440
NORD11=0xffbf616a
NORD13=0xffebcb8b
NORD14=0xffa3be8c

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ -n "$CHARGING" ]; then
    ICON=""
    COLOR=$NORD13
elif [ "$PERCENTAGE" -gt 80 ]; then
    ICON=""
    COLOR=$NORD14
elif [ "$PERCENTAGE" -gt 60 ]; then
    ICON=""
    COLOR=$NORD14
elif [ "$PERCENTAGE" -gt 40 ]; then
    ICON=""
    COLOR=$NORD14
elif [ "$PERCENTAGE" -gt 20 ]; then
    ICON=""
    COLOR=$NORD14
else
    ICON=""
    COLOR=$NORD11
fi

sketchybar --set "$NAME" \
    icon="$ICON" \
    label="${PERCENTAGE}%" \
    icon.color=$NORD0 \
    label.color=$NORD0 \
    background.color="$COLOR"
