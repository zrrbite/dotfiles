#!/bin/bash

# Nord
NORD0=0xff2e3440
NORD9=0xff81a1c1
NORD11=0xffbf616a

# The `airport` CLI was gutted in macOS 14.4 (prints only a deprecation
# warning, no data), so SSID comes from networksetup instead.
WIFI_DEV=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

# Connectivity is decided by whether the interface HAS AN ADDRESS, never by
# whether its name is readable. macOS 15+ gates the SSID behind Location
# Services, and a CLI binary like sketchybar cannot hold that grant, so every
# source lies while Wi-Fi is perfectly up:
#   networksetup -getairportnetwork  -> "You are not associated with an AirPort network."
#   system_profiler SPAirPortDataType -> "<redacted>"
#   ipconfig getsummary en0           -> "SSID : <redacted>"
# Keying off the SSID meant an empty name fell through to the wired branch,
# which skips the Wi-Fi device by design -- so a connected laptop reported
# "Disconnected". The SSID is now only a label for a link already known good.
WIFI_IP=""
SSID=""
if [ -n "$WIFI_DEV" ]; then
    WIFI_IP=$(ipconfig getifaddr "$WIFI_DEV" 2>/dev/null)
    if [ -n "$WIFI_IP" ]; then
        SSID=$(networksetup -getairportnetwork "$WIFI_DEV" 2>/dev/null | sed -n 's/^Current Wi-Fi Network: //p')
        [ "$SSID" = "<redacted>" ] && SSID=""
    fi
fi

if [ -n "$WIFI_IP" ]; then
    ICON="󰖩"
    # Falls back to the IP when macOS withholds the network name.
    LABEL="${SSID:-$WIFI_IP}"
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
