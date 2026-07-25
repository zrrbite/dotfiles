#!/bin/bash

# The `airport` CLI was gutted in macOS 14.4 (prints only a deprecation
# warning, no data), so SSID comes from networksetup instead.
WIFI_DEV=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

SSID=""
if [ -n "$WIFI_DEV" ]; then
    SSID=$(networksetup -getairportnetwork "$WIFI_DEV" 2>/dev/null | sed -n 's/^Current Wi-Fi Network: //p')
fi

if [ -n "$SSID" ]; then
    sketchybar --set "$NAME" icon="󰖩" label="$SSID"
else
    # Fall back to a wired interface (skipping the Wi-Fi device itself)
    IP=""
    for dev in en0 en1 en2; do
        [ "$dev" = "$WIFI_DEV" ] && continue
        IP=$(ipconfig getifaddr "$dev" 2>/dev/null)
        [ -n "$IP" ] && break
    done

    if [ -n "$IP" ]; then
        sketchybar --set "$NAME" icon="󰈀" label="$IP"
    else
        sketchybar --set "$NAME" icon="󰖪" label="Disconnected"
    fi
fi
