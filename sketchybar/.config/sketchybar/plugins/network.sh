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
    # Fall back to a wired interface. Enumerate them rather than assuming
    # en0-en2: on a laptop with a dock, en1/en2 are Thunderbolt and the real
    # Ethernet adapters come up as en3/en4, so a hardcoded range reports
    # "Disconnected" while the machine is online over the dock.
    IP=""
    while read -r dev; do
        [ "$dev" = "$WIFI_DEV" ] && continue
        IP=$(ipconfig getifaddr "$dev" 2>/dev/null)
        [ -n "$IP" ] && break
    done < <(networksetup -listallhardwareports | awk '/^Device: /{print $2}')

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
