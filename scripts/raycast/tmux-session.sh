#!/bin/bash
#
# Raycast script command: `t` from anywhere. Switch to, or create, a tmux
# session in Ghostty.
#
#   (empty)       bring the tmux window forward, or reattach to the most
#                 recent session if none is open
#   name          go to session "name" if it exists. Otherwise ask zoxide
#                 for a folder: "dotf" -> ~/Development/dotfiles, and the
#                 session is named after the folder ("dotfiles"), exactly as
#                 `t` would name it there -- so the two never make duplicates.
#                 No zoxide match: a session called "name" in $HOME.
#
# If a tmux client is already attached somewhere, that window is switched to
# the session and Ghostty is brought forward -- one terminal, many sessions,
# instead of a new window each time. A new Ghostty window opens only when
# nothing is attached.
#
# To use it: Raycast Settings -> Extensions -> + -> Add Script Directory ->
# choose this repo's scripts/raycast/.
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title tmux session
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName dotfiles
# @raycast.icon 🖥️
# @raycast.argument1 { "type": "text", "placeholder": "session or folder", "optional": true }
# @raycast.description Switch to or create a tmux session in Ghostty (zoxide picks the folder)

set -uo pipefail

# Raycast runs scripts with a minimal PATH; Homebrew's tools live here.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# TMUX_SOCKET_NAME selects a private tmux server (tmux -L) -- used to test
# this script without touching the real one. Normally unset.
T=(tmux)
[ -n "${TMUX_SOCKET_NAME:-}" ] && T=(tmux -L "$TMUX_SOCKET_NAME")
GHOSTTY_OPEN=(open -na Ghostty --args -e)

command -v tmux >/dev/null || { echo "tmux is not installed"; exit 1; }

arg="${1:-}"
# The most recently active attached client, if any.
client="$("${T[@]}" list-clients -F '#{client_activity} #{client_name}' 2>/dev/null \
          | sort -rn | head -1 | cut -d' ' -f2-)"

if [ -z "$arg" ]; then
    if [ -n "$client" ]; then
        open -a Ghostty
        echo "tmux: $("${T[@]}" display -p -c "$client" '#{client_session}')"
    elif "${T[@]}" has-session 2>/dev/null; then
        "${GHOSTTY_OPEN[@]}" "${T[@]}" attach
        echo "tmux: reattached"
    else
        "${GHOSTTY_OPEN[@]}" "${T[@]}" new-session -A -s main -c "$HOME"
        echo "tmux: main"
    fi
    exit 0
fi

# tmux forbids "." and ":" in session names (same rule as `t` in .zshrc).
sanitize() { local n="$1"; echo "${n//[.:]/_}"; }

name="$(sanitize "$arg")"
if ! "${T[@]}" has-session -t "=$name" 2>/dev/null; then
    dir="$(command -v zoxide >/dev/null && zoxide query -- "$arg" 2>/dev/null)"
    if [ -d "$dir" ]; then
        name="$(sanitize "$(basename "$dir")")"
    else
        dir="$HOME"
    fi
    if ! "${T[@]}" has-session -t "=$name" 2>/dev/null; then
        "${T[@]}" new-session -d -s "$name" -c "$dir"
        created=" (new, in ${dir/#$HOME/~})"
    fi
fi

if [ -n "$client" ]; then
    "${T[@]}" switch-client -c "$client" -t "=$name"
    open -a Ghostty
else
    "${GHOSTTY_OPEN[@]}" "${T[@]}" attach -t "=$name"
fi
echo "tmux: $name${created:-}"
