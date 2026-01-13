#!/bin/bash
# Restart hyprlock if it's crashed or stuck

# Kill any existing hyprlock processes
pkill -9 hyprlock 2>/dev/null

# Wait a moment for cleanup
sleep 0.2

# Start hyprlock fresh
hyprlock &

# Send notification
notify-send "Hyprlock Restarted" "Lock screen has been reloaded" -t 2000
