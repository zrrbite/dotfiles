#!/bin/bash

# Nord
NORD4=0xffd8dee9
NORD13=0xffebcb8b

# Tinted style: the item's accent at 20% alpha behind text in the full accent,
# instead of a solid accent fill with dark text. tint 0xffRRGGBB -> 0x33RRGGBB
tint() { echo "0x33${1:4}"; }

VOLUME=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')

# Muted matches waybar's `#pulseaudio.muted`: grey rather than yellow. A 20%
# tint of grey vanishes into the bar, so muted uses a heavier 0x66 wash.
if [ "$MUTED" = "true" ]; then
    ICON="󰝟"
    BG=0x664c566a
    TEXT=$NORD4
else
    BG=$(tint $NORD13)
    TEXT=$NORD13

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
    background.color="$BG"
