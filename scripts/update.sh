#!/usr/bin/env bash
#
# Upgrade this Mac: the checklist in doc/tools.md, "Versions and upgrading",
# as one command. Run it yourself, in a terminal: .pkg casks ask for the
# password (Touch ID works).
#
# Usage: scripts/update.sh [--dry-run]
#   --dry-run  fetch Homebrew's package lists and show what would be
#              upgraded; change nothing else
#
# What it does:
#   1. records `brew list --versions` (formulae and casks) in
#      ~/.local/state/dotfiles/, so you can see later what moved
#   2. saves AeroSpace's window layout
#   3. brew upgrade (formulae, and casks that don't update themselves)
#   4. restarts AeroSpace if it was upgraded (until then its old version keeps
#      running and every `aerospace` command fails), and puts the windows back
#   5. reloads sketchybar; updates nvim's plugins (:Lazy sync) and yazi's
#      (ya pkg upgrade)
#   6. lists every version that moved, flagging the tools whose config was
#      checked against a version (doc/tools.md), and ends with verify.sh
#
# Not upgraded on purpose: global npm packages (TypeScript stays on 6 for
# nvim's ts_ls), the tmux plugins (pinned by tag in the installers).
#
# The plugin lockfiles (nvim's lazy-lock.json, yazi's package.toml) live in
# this repo; once nvim and yazi still work, commit them.

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$HOME/.local/state/dotfiles"
STAMP="$(date +%Y-%m-%d-%H%M)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info() { echo -e "${GREEN}==>${NC} $1"; }
note() { echo -e "${YELLOW}==>${NC} $1"; }

# The tools in doc/tools.md's versions table, by their Homebrew name.
WATCHED=(aerospace yazi lazygit ghostty neovim tmux llvm clang-format sketchybar
    font-sketchybar-app-font karabiner-elements orbstack cmake ninja ccache fuse-t
    fuse-t-sshfs)

# Window id and workspace of every window, one per line.
capture_layout() {
    aerospace list-windows --all --format '%{window-id} %{workspace}' 2>/dev/null
}

# Move each window in a saved layout back to its workspace. Windows that are
# gone are skipped.
restore_layout() {
    local file="$1" id ws now cur moved=0
    now="$(capture_layout)"
    while read -r id ws; do
        [ -n "$id" ] || continue
        cur="$(printf '%s\n' "$now" | awk -v i="$id" '$1 == i { print $2 }')"
        if [ -n "$cur" ] && [ "$cur" != "$ws" ]; then
            aerospace move-node-to-workspace --window-id "$id" "$ws" && moved=$((moved + 1))
        fi
    done < "$file"
    echo "$moved"
}

# Wait until AeroSpace's server answers (it starts in a second or two).
wait_for_aerospace() {
    local tries=40
    while [ "$tries" -gt 0 ]; do
        aerospace list-workspaces --focused >/dev/null 2>&1 && return 0
        sleep 0.5
        tries=$((tries - 1))
    done
    return 1
}

# "name version" lines in, "name: old -> new" out, for what changed.
diff_versions() {
    awk 'NR == FNR { old[$1] = $2; next }
         ($1 in old) && old[$1] != $2 { print $1 ": " old[$1] " -> " $2 }' "$1" "$2"
}

main() {
    local dry=false
    case "${1:-}" in
        --dry-run) dry=true ;;
        "") ;;
        *) echo "Usage: $0 [--dry-run]" >&2; exit 2 ;;
    esac
    if [ "$(uname -s)" != Darwin ]; then
        echo "update.sh is for macOS. On Arch: sudo pacman -Syu; on Debian: sudo apt update && sudo apt upgrade" >&2
        exit 2
    fi

    info "Fetching Homebrew's package lists..."
    brew update --quiet || { echo "brew update failed" >&2; exit 1; }
    local outdated
    outdated="$(brew outdated --verbose)"
    if [ -z "$outdated" ]; then
        info "Homebrew: everything is up to date"
    else
        info "To upgrade:"
        printf '%s\n' "$outdated" | sed 's/^/    /'
    fi
    if $dry; then
        echo "(dry run: nothing changed)"
        exit 0
    fi

    mkdir -p "$STATE"
    local before="$STATE/brew-before-$STAMP.txt" after layout aero_before aero_after
    { brew list --versions; brew list --cask --versions; } > "$before"
    info "Versions before: $before"

    aero_before=""
    layout=""
    if pgrep -x AeroSpace >/dev/null 2>&1; then
        aero_before="$(brew list --cask --versions aerospace 2>/dev/null)"
        layout="$STATE/aerospace-layout-$STAMP.txt"
        capture_layout > "$layout"
        info "Window layout saved: $layout"
    fi

    if [ -n "$outdated" ]; then
        info "Upgrading (casks with a .pkg ask for the password)..."
        brew upgrade || note "brew upgrade reported a problem (see above); carrying on"
    fi

    if [ -n "$aero_before" ]; then
        aero_after="$(brew list --cask --versions aerospace 2>/dev/null)"
        if [ "$aero_after" != "$aero_before" ]; then
            info "AeroSpace was upgraded ($aero_before -> ${aero_after##* }); restarting it..."
            killall AeroSpace 2>/dev/null
            sleep 1
            open -a AeroSpace
            if wait_for_aerospace; then
                info "Windows moved back: $(restore_layout "$layout")"
            else
                note "AeroSpace didn't answer; restore later with: while read -r id ws; do aerospace move-node-to-workspace --window-id \"\$id\" \"\$ws\"; done < $layout"
            fi
        fi
    fi

    if pgrep -x sketchybar >/dev/null 2>&1; then
        sketchybar --reload && info "sketchybar reloaded"
    fi
    if command -v nvim >/dev/null 2>&1; then
        info "Updating nvim's plugins (:Lazy sync)..."
        nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || note "nvim's plugin update failed; run :Lazy sync inside nvim"
    fi
    if command -v ya >/dev/null 2>&1; then
        info "Updating yazi's plugins..."
        ya pkg upgrade >/dev/null 2>&1 || note "ya pkg upgrade failed; run it by hand"
    fi

    after="$STATE/brew-after-$STAMP.txt"
    { brew list --versions; brew list --cask --versions; } > "$after"
    local changed
    changed="$(diff_versions "$before" "$after")"
    echo
    if [ -z "$changed" ]; then
        info "No Homebrew versions changed"
    else
        info "Changed:"
        printf '%s\n' "$changed" | while IFS= read -r line; do
            name="${line%%:*}"
            if printf '%s\n' "${WATCHED[@]}" | grep -qx -- "$name"; then
                echo -e "    $line  ${YELLOW}<- re-check its row in doc/tools.md${NC}"
            else
                echo "    $line"
            fi
        done
    fi

    local locks
    locks="$(git -C "$DOTFILES_DIR" status --short -- nvim/.config/nvim/lazy-lock.json yazi/.config/yazi/package.toml)"
    if [ -n "$locks" ]; then
        echo
        note "Plugin lockfiles changed in the repo; commit them once nvim and yazi still work:"
        printf '%s\n' "$locks" | sed 's/^/    /'
    fi

    echo
    "$DOTFILES_DIR/scripts/verify.sh"
}

# Run only when executed, so a test can source the functions above.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
