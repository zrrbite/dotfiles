#!/bin/bash

# `top` prints: CPU usage: 11.5% user, 15.66% sys, 73.27% idle
# Field 3 alone is only the user share, which undercuts the real figure by
# whatever sys is doing -- routinely 15-20% here. Sum user and sys instead.
#
# Two samples a second apart, taking the second: top's first sample is a
# degenerate reading (it will happily report identical user and sys values).
# `-n 0` skips the process list, so this costs ~1.7s of mostly-idle waiting
# rather than a full process enumeration.
CPU=$(top -l 2 -n 0 -s 1 | awk '/CPU usage/ { usage = int($3 + $5) } END { print usage }')

sketchybar --set "$NAME" label="${CPU}%"
