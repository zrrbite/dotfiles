#!/bin/bash

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" background.drawing=on label.color=0xff2e3440 background.color=0xff88c0d0
else
    sketchybar --set "$NAME" background.drawing=off label.color=0xffd8dee9
fi
