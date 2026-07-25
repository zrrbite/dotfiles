#!/bin/bash

# Nord
NORD0=0xff2e3440
NORD9=0xff81a1c1
NORD11=0xffbf616a

# The `airport` CLI was gutted in macOS 14.4 (prints only a deprecation
# warning, no data), so SSID comes from networksetup instead.
WIFI_DEV=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

SSID=""
if [ -n "$WIFI_DEV" ]; then
    SSID=$(networksetup -getairportnetwork "$WIFI_DEV" 2>/dev/null | sed -n 's/^Current Wi-Fi Network: //p')
fi

if [ -n "$SSID" ]; then
    ICON="󰖩"
    LABEL="$SSID"
    COLOR=$NORD9
else
    # Fall back to a wired interface (skipping the Wi-Fi device itself)
    IP=""
    for dev in en0 en1 en2; do
        [ "$dev" = "$WIFI_DEV" ] && continue
        IP=$(ipconfig getifaddr "$dev" 2>/dev/null)
        [ -n "$IP" ] && break
    done

    if [ -n "$IP" ]; then
        ICON="󰈀"
        LABEL="$IP"
        COLOR=$NORD9
    else
        # Matches waybar's `#network.disconnected`
        ICON="󰖪"
        LABEL="Disconnected"
        COLOR=$NORD11
    fi
fi

sketchybar --set "$NAME" \
    icon="$ICON" \
    label="$LABEL" \
    icon.color=$NORD0 \
    label.color=$NORD0 \
    background.color="$COLOR"
