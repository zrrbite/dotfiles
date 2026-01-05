#!/bin/bash

# Neovim keybindings menu for rofi
# Shows useful nvim keybindings and commands

KEYBINDS=(
    "Space + e • Toggle file tree sidebar (neo-tree)"
    "Space + ff • Find files (Telescope)"
    "Space + fg • Find by grep (Telescope)"
    "Space + fb • Find buffers (Telescope)"
    "Space + fh • Find help (Telescope)"
    "Space + fd • Find diagnostics (Telescope)"
    "Space + fs • Find symbols in file (Telescope)"
    "Space + fw • Find symbols in workspace (Telescope)"
    "Space + fm • Find macros (#define)"
    "Space + mp • Markdown preview (toggle)"
    "Space + q • Show all diagnostics (full text)"
    "Space + d • Show diagnostic at cursor"
    "---"
    "Ctrl + h/j/k/l • Navigate between windows"
    "Ctrl + w + v • Split window vertically"
    "Ctrl + w + s • Split window horizontally"
    "Ctrl + w + q • Close current window"
    "---"
    "gd • Go to definition (LSP)"
    "gD • Go to declaration (LSP)"
    "gr • Go to references (LSP)"
    "gI • Go to implementation (LSP)"
    "K • Show hover documentation (LSP)"
    "Space + h • Switch header/source (C++)"
    "Space + rn • Rename symbol (LSP)"
    "Space + ca • Code actions (LSP + Generate definition)"
    "Space + cf • Batch fix with clang-tidy (C++)"
    "Space + F • Format code (clang-format)"
    "Space + D • Type definition (LSP)"
    "---"
    "TIPS: Space+q then Enter to jump to diagnostic"
    "TIPS: Space+ca on function declaration = generate impl"
    "TIPS: ]d / [d to jump next/previous diagnostic"
    "---"
    ":w • Save file"
    ":q • Quit"
    ":wq • Save and quit"
    ":q! • Quit without saving"
    "---"
    "i • Enter insert mode"
    "v • Enter visual mode"
    "Esc • Return to normal mode"
    "u • Undo"
    "Ctrl + r • Redo"
    "---"
    "dd • Delete line"
    "yy • Yank (copy) line"
    "p • Paste"
    "/ • Search"
    "n • Next search result"
    "N • Previous search result"
    ":%s/old/new/g • Replace all"
    "---"
    "gg • Go to top of file"
    "G • Go to bottom of file"
    "0 • Go to start of line"
    "$ • Go to end of line"
    "w • Next word"
    "b • Previous word"
)

# Join array with newlines
MENU=$(printf '%s\n' "${KEYBINDS[@]}")

# Show menu in rofi
SELECTED=$(echo "$MENU" | rofi -dmenu -i -p "Neovim Keybindings" -theme-str 'window {width: 55%;}' -theme-str 'listview {lines: 20;}')

# If something was selected, copy the keybind part to clipboard
if [ -n "$SELECTED" ]; then
    # Skip separator lines
    if [ "$SELECTED" != "---" ]; then
        # Extract just the keybind (before the •)
        KEYBIND=$(echo "$SELECTED" | sed 's/ •.*//')
        echo -n "$KEYBIND" | wl-copy
        notify-send "Keybind Copied" "$KEYBIND" -t 2000
    fi
fi
