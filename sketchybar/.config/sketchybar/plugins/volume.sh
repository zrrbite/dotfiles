#!/bin/bash

# Nord
NORD0=0xff2e3440
NORD3=0xff4c566a
NORD4=0xffd8dee9
NORD13=0xffebcb8b

VOLUME=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')

# Muted matches waybar's `#pulseaudio.muted`: grey fill, light text
if [ "$MUTED" = "true" ]; then
    ICON="󰝟"
    COLOR=$NORD3
    TEXT=$NORD4
else
    COLOR=$NORD13
    TEXT=$NORD0

    if [ "$VOLUME" -gt 66 ]; then
        ICON="󰕾"
    elif [ "$VOLUME" -gt 33 ]; then
        ICON="󰖀"
    else
        ICON="󰕿"
    fi
fi

sketchybar --set "$NAME" \
    icon="$ICON" \
    label="${VOLUME}%" \
    icon.color="$TEXT" \
    label.color="$TEXT" \
    background.color="$COLOR"
