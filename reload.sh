#!/bin/bash
#
# Pull the latest dotfiles, re-stow this OS's packages, and reload the
# desktop pieces that need telling. Safe to re-run. Works wherever the repo
# is cloned: it stows from its own directory into $HOME.

set -uo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR" || exit 1
# shellcheck source=scripts/packages.sh
source "$DOTFILES_DIR/scripts/packages.sh"

case "$(uname -s)" in
    Darwin) OS=darwin; PACKAGES=("${PACKAGES_DARWIN[@]}") ;;
    Linux)
        if [ -f /etc/arch-release ]; then OS=arch; PACKAGES=("${PACKAGES_ARCH[@]}")
        else OS=debian; PACKAGES=("${PACKAGES_DEBIAN[@]}"); fi ;;
    *) echo "Unsupported OS"; exit 1 ;;
esac

echo -e "${BLUE}Reloading dotfiles ($OS)...${NC}"

echo -e "${GREEN}[1/3]${NC} Pulling latest changes..."
# --ff-only: never create a merge commit or start a rebase behind your back.
git pull --ff-only || echo -e "${YELLOW}  pull failed -- continuing with the local checkout${NC}"

echo -e "${GREEN}[2/3]${NC} Re-stowing packages (picks up newly added files)..."
for pkg in "${PACKAGES[@]}"; do
    stow -d "$DOTFILES_DIR" -t "$HOME" -R "$pkg" || echo -e "${YELLOW}  failed: $pkg${NC}"
done

echo -e "${GREEN}[3/3]${NC} Reloading the desktop..."
case "$OS" in
    darwin)
        command -v aerospace >/dev/null && aerospace reload-config
        command -v sketchybar >/dev/null && sketchybar --reload
        ;;
    arch)
        command -v hyprctl >/dev/null && hyprctl reload
        if command -v waybar >/dev/null; then pkill waybar; (waybar >/dev/null 2>&1 &); fi
        ;;
    debian) echo "  (no desktop on this platform)" ;;
esac

echo -e "${BLUE}Done.${NC} Open a new shell to pick up shell config changes."
echo "Check the result: $DOTFILES_DIR/scripts/verify.sh"
