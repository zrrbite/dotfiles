#!/usr/bin/env bash
#
# Create ~/.gitconfig.local from the machine's existing ~/.gitconfig, so the
# identity and credential settings survive the installer replacing ~/.gitconfig
# with the repo's portable version. The repo file includes ~/.gitconfig.local
# last, so whatever lands here overrides it.
#
# Copies only what is per-machine: user.*, credential.*, gpg.*, and the
# commit/tag signing switches. Never overwrites an existing ~/.gitconfig.local.
#
# Usage: scripts/seed-gitconfig-local.sh [--dry-run]
#        (DRY_RUN=true in the environment works too, for the installers)

set -euo pipefail

[ "${1:-}" = "--dry-run" ] && DRY_RUN=true
DRY_RUN="${DRY_RUN:-false}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

LOCAL="$HOME/.gitconfig.local"
SOURCE="$HOME/.gitconfig"
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -e "$LOCAL" ]; then
    info "$LOCAL already exists -- leaving it alone"
    exit 0
fi

# A ~/.gitconfig that already resolves into this repo has nothing per-machine
# to offer: the repo file carries no identity any more.
keys=""
if [ -f "$SOURCE" ]; then
    case "$(realpath "$SOURCE")" in
        "$DOTFILES_DIR"/*) ;;
        *)
            keys="$(git config -f "$SOURCE" --get-regexp \
                '^(user\.|credential\.|gpg\.|commit\.gpgsign$|tag\.gpgsign$)' || true)"
            ;;
    esac
fi

if [ -z "$keys" ]; then
    warn "No existing git identity found to carry over. Create ~/.gitconfig.local:"
    warn "  git config -f ~/.gitconfig.local user.name  \"Your Name\""
    warn "  git config -f ~/.gitconfig.local user.email \"you@example.com\""
    warn "  git config -f ~/.gitconfig.local credential.helper osxkeychain   # Windows: manager"
    exit 0
fi

info "Seeding ~/.gitconfig.local from the existing ~/.gitconfig:"
while IFS= read -r line; do
    key="${line%% *}"
    value="${line#* }"
    [ "$key" = "$line" ] && value=""   # a key with no value
    # Never echo credential values or signing keys; names of keys are enough.
    case "$key" in
        user.name|user.email) echo "    $key = $value" ;;
        *) echo "    $key" ;;
    esac
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY]${NC} git config -f ~/.gitconfig.local --add $key <value>"
    else
        git config -f "$LOCAL" --add "$key" "$value"
    fi
done <<< "$keys"
