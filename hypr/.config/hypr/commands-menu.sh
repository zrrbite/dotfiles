#!/bin/bash

# Cool commands menu for rofi
# Shows useful CLI commands and aliases

COMMANDS=(
    "fimg • Find and preview images interactively"
    "z <dir> • Jump to frequently used directory"
    "zi • Jump to directory with fzf picker"
    "fd <pattern> • Find files (better than find)"
    "fd -H <pattern> • Find including hidden files"
    "rg <pattern> • Search file contents (better grep)"
    "rg -l <pattern> • List files containing pattern"
    "bat <file> • View file with syntax highlighting"
    "chafa-ascii <img> • View image as ASCII art"
    "chafa-block <img> • View image with block chars"
    "btop • Beautiful system monitor"
    "yazi • Modern file manager with previews"
    "eza / ls • Modern ls with icons and colors"
    "ll • Detailed file list with git status"
    "lt • Tree view of current directory"
    "tldr <cmd> • Quick examples for any command"
    "Ctrl+R • Search command history with fzf"
    "Ctrl+T • Fuzzy find files"
    "Alt+C • Fuzzy cd into directory"
    "fd -e cpp | fzf | xargs bat • Find, pick, view C++ file"
    "rg -l TODO | fzf | xargs nvim • Find TODOs and edit"
)

# Join array with newlines
MENU=$(printf '%s\n' "${COMMANDS[@]}")

# Show menu in rofi
SELECTED=$(echo "$MENU" | rofi -dmenu -i -p "Cool Commands" -theme-str 'window {width: 50%;}' -theme-str 'listview {lines: 15;}')

# If something was selected, copy the command part to clipboard
if [ -n "$SELECTED" ]; then
    # Extract just the command (before the •)
    COMMAND=$(echo "$SELECTED" | sed 's/ •.*//')
    echo -n "$COMMAND" | wl-copy
    notify-send "Command Copied" "$COMMAND" -t 2000
fi
