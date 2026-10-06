#!/usr/bin/env bash
#
# Give btop the Nord theme without linking its config into the repo. btop
# rewrites btop.conf whenever it exits, so a stowed file would be rewritten
# inside the working tree. This sets the one line and leaves the file to btop:
#
#   no btop.conf             create it with color_theme = "nord"
#   color_theme = "Default"  switch it to nord (btop's own default)
#   no color_theme line      add one
#   any other theme          leave it; it was picked on purpose
#
# Usage: scripts/seed-btop-config.sh [--dry-run]
#        (DRY_RUN=true in the environment works too, for the installers)

set -euo pipefail

[ "${1:-}" = "--dry-run" ] && DRY_RUN=true
DRY_RUN="${DRY_RUN:-false}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
dry() { echo -e "${BLUE}[DRY]${NC} $1"; }

THEME='color_theme = "nord"'
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/btop/btop.conf"

if [ ! -e "$CONF" ]; then
    if [ "$DRY_RUN" = true ]; then
        dry "create $CONF with $THEME"
    else
        mkdir -p "$(dirname "$CONF")"
        echo "$THEME" > "$CONF"
        info "btop: created $CONF with the Nord theme"
    fi
    exit 0
fi

current="$(awk '/^color_theme[[:space:]]*=/ { sub(/^[^=]*=[[:space:]]*/, ""); print; exit }' "$CONF")"
case "$current" in
    '"nord"')
        info "btop: already on the Nord theme"
        ;;
    '"Default"' | '')
        if [ "$DRY_RUN" = true ]; then
            dry "set $THEME in $CONF"
            exit 0
        fi
        tmp="$(mktemp)"
        if [ -n "$current" ]; then
            sed "s/^color_theme[[:space:]]*=.*/$THEME/" "$CONF" > "$tmp"
        else
            cat "$CONF" > "$tmp"
            echo "$THEME" >> "$tmp"
        fi
        # Rewrite in place rather than mv, so the file keeps its permissions.
        cat "$tmp" > "$CONF"
        rm -f "$tmp"
        info "btop: switched to the Nord theme"
        ;;
    *)
        info "btop: keeping its theme, $current"
        ;;
esac
