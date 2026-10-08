#!/usr/bin/env bash
#
# Touch ID for sudo, also inside tmux. Writes /etc/pam.d/sudo_local, the file
# macOS keeps across updates for exactly this (sudo includes it first):
#   pam_reattach  lets a process inside tmux reach the GUI session Touch ID
#                 needs; without it, sudo in tmux asks for the password
#   pam_tid       Touch ID; when it fails or there's no finger (lid closed,
#                 over SSH), sudo falls back to the password
#
# Usage: scripts/touch-id-sudo.sh [--dry-run | --check | --undo]
#   --check  changes nothing; exits 1 unless the file is in place
#   --undo   removes the file; sudo asks for the password again
#
# Asks for your password once (writing under /etc needs root). Refuses to
# replace a sudo_local this script didn't write.
#
# Needs the pam-reattach formula, which the installer installs. Run --undo
# before uninstalling it: sudo can't load a missing module. The module sits
# in Homebrew's folder, which you own, as pam_reattach's README has it; so
# something running as you could swap it and run as root at your next sudo.
# That adds little to what it can already do (wrap sudo in your shell config
# and read the password), but it's the trade-off. If sudo ever
# breaks, this removes the file without sudo (it asks for the password in a
# dialog instead):
#   osascript -e 'do shell script "rm /etc/pam.d/sudo_local" with administrator privileges'

set -euo pipefail

MODE=apply
case "${1:-}" in
    --dry-run) MODE=dry ;;
    --check)   MODE=check ;;
    --undo)    MODE=undo ;;
    "")        ;;
    *) echo "Usage: $0 [--dry-run | --check | --undo]" >&2; exit 2 ;;
esac

# SUDO_LOCAL is for the tests; everyone else gets the real file.
TARGET="${SUDO_LOCAL:-/etc/pam.d/sudo_local}"
MARKER="# Written by dotfiles scripts/touch-id-sudo.sh"

# Root is only needed where we can't write ourselves, i.e. the real /etc.
as_root() { if [ -w "$(dirname "$TARGET")" ]; then "$@"; else sudo "$@"; fi; }

ours() { [ -f "$TARGET" ] && grep -qF "$MARKER" "$TARGET"; }

case "$MODE" in
    check)
        if ours && grep -q '^auth.*pam_tid\.so' "$TARGET" && grep -q '^auth.*pam_reattach\.so' "$TARGET"; then
            echo "Touch ID for sudo is set up ($TARGET)"
            exit 0
        fi
        echo "Touch ID for sudo is not set up by this script ($TARGET)"
        exit 1
        ;;
    undo)
        if [ ! -e "$TARGET" ]; then echo "Nothing to undo: $TARGET doesn't exist"; exit 0; fi
        ours || { echo "Refusing: $TARGET wasn't written by this script. Look at it first." >&2; exit 1; }
        as_root rm -f "$TARGET"
        echo "Removed $TARGET; sudo asks for the password again."
        exit 0
        ;;
esac

PREFIX="$(brew --prefix 2>/dev/null || true)"
REATTACH="$PREFIX/lib/pam/pam_reattach.so"
if [ -z "$PREFIX" ] || [ ! -f "$REATTACH" ]; then
    echo "pam_reattach.so not found at $REATTACH: brew install pam-reattach" >&2
    exit 1
fi

# ignore_ssh: over SSH, don't pop a Touch ID prompt on this Mac's screen for
# someone typing elsewhere; pam_tid then fails and sudo asks for the password.
CONTENT="$MARKER
# Touch ID for sudo, also inside tmux. See the script for how to undo it.
auth       optional       $REATTACH ignore_ssh
auth       sufficient     pam_tid.so"

if [ -e "$TARGET" ] && ! ours; then
    echo "Refusing: $TARGET exists and wasn't written by this script:" >&2
    sed 's/^/  /' "$TARGET" >&2
    echo "Merge by hand, or move it aside and run this again." >&2
    exit 1
fi

if [ "$MODE" = dry ]; then
    echo "Would write $TARGET (root:wheel, 444):"
    while IFS= read -r line; do echo "  $line"; done <<< "$CONTENT"
    exit 0
fi

if ours && [ "$(cat "$TARGET")" = "$CONTENT" ]; then
    echo "Touch ID for sudo is already set up ($TARGET)"
    exit 0
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
echo "$CONTENT" > "$tmp"
if [ -w "$(dirname "$TARGET")" ]; then
    install -m 444 "$tmp" "$TARGET"
else
    sudo install -m 444 -o root -g wheel "$tmp" "$TARGET"
fi
echo "Wrote $TARGET. Try it in a new tmux pane: sudo -k; sudo true"
