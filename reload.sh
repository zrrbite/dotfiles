#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Reloading dotfiles...${NC}"

# Git pull latest changes
echo -e "${GREEN}[1/5]${NC} Pulling latest changes from git..."
git pull

# Re-stow all packages (in case new files were added)
echo -e "${GREEN}[2/5]${NC} Re-stowing all packages..."
for dir in */; do
    if [ -d "$dir" ] && [ "$dir" != ".git/" ]; then
        pkg="${dir%/}"
        stow -R "$pkg" 2>/dev/null
    fi
done

# Reload Hyprland config
echo -e "${GREEN}[3/5]${NC} Reloading Hyprland..."
hyprctl reload

# Reload waybar
echo -e "${GREEN}[4/5]${NC} Reloading waybar..."
pkill waybar
waybar &

# Source bashrc (for current terminal)
echo -e "${GREEN}[5/5]${NC} Sourcing bashrc..."
source ~/.bashrc

echo -e "${BLUE}✅ Dotfiles reloaded!${NC}"
echo ""
echo "Note: Open a new terminal to see all bash changes"
