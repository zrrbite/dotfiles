#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  OMARCHY INSTALLATION GUIDE                    ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Check if already running Omarchy
if grep -q "omarchy" /etc/os-release 2>/dev/null; then
    info "Omarchy is already installed!"
    echo ""
    echo "You can now layer your custom dotfiles on top."
    echo "See the 'Custom Dotfiles' section at the end of this script."
    exit 0
fi

echo -e "${YELLOW}IMPORTANT:${NC} Omarchy is a complete Linux distribution installed via ISO."
echo "It cannot be installed on top of an existing system."
echo ""
echo "This script provides two installation paths:"
echo ""
echo "  ${GREEN}1. ISO Installation (Recommended)${NC}"
echo "     - Download ISO from https://omarchy.org"
echo "     - Flash to USB with balenaEtcher"
echo "     - Boot and follow installer prompts"
echo ""
echo "  ${GREEN}2. Manual Arch Installation (Advanced)${NC}"
echo "     - For those familiar with Arch Linux"
echo "     - Use vanilla Arch ISO + archinstall"
echo "     - Manually configure Omarchy-like setup"
echo ""

# Ask user which path they want
echo -n "Which installation method? [iso/manual/cancel]: "
read -r choice

case $choice in
    iso)
        echo ""
        info "ISO Installation Method"
        echo ""
        echo "Steps:"
        echo "  1. Download Omarchy ISO from https://omarchy.org"
        echo "  2. Disable Secure Boot and TPM in BIOS"
        echo "  3. Flash ISO to USB stick:"
        echo "     - Mac/Windows: Use balenaEtcher"
        echo "     - Linux: Use caligula or dd"
        echo "  4. Boot from USB stick"
        echo "  5. Follow the installer prompts"
        echo "  6. After installation, run this script again to layer custom dotfiles"
        echo ""
        warn "Installation will WIPE the selected drive completely!"
        echo ""
        ;;

    manual)
        echo ""
        info "Manual Arch Installation Method"
        echo ""
        echo "This is an advanced method for those familiar with Arch Linux."
        echo ""
        echo "Steps:"
        echo "  1. Download Arch Linux ISO from https://archlinux.org/download/"
        echo "  2. Disable Secure Boot in BIOS"
        echo "  3. Flash ISO to USB and boot from it"
        echo "  4. Connect to WiFi (if needed):"
        echo "     iwctl"
        echo "     station wlan0 scan"
        echo "     station wlan0 connect <SSID>"
        echo "  5. Run archinstall and configure:"
        echo "     - Mirrors: Select your country/region"
        echo "     - Disk: Choose 'Default partitioning layout'"
        echo "     - Desktop: Select Hyprland"
        echo "     - [Configure remaining options as needed]"
        echo "  6. Complete installation and reboot"
        echo "  7. After first boot, install Omarchy packages (see below)"
        echo ""
        warn "Refer to Omarchy manual for complete configuration:"
        echo "     https://learn.omacom.io/2/the-omarchy-manual"
        echo ""
        ;;

    cancel|*)
        info "Installation cancelled"
        exit 0
        ;;
esac

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                     CUSTOM DOTFILES                            ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "After Omarchy is installed, you can layer custom dotfiles on top:"
echo ""
echo "  # Clone this dotfiles repo"
echo "  git clone https://github.com/zrrbite/dotfiles.git ~/dotfiles"
echo "  cd ~/dotfiles"
echo ""
echo "  # Install additional packages from install.sh"
echo "  # (TODO: Add specific packages to install on top of Omarchy)"
echo ""
echo "  # Stow custom configs"
echo "  stow bash     # Custom bash aliases (chafa, eza)"
echo "  stow git      # Git config with aliases"
echo "  stow clang    # clang-format and clang-tidy configs"
echo "  stow gdb      # gdb-dashboard setup"
echo "  # ... add more packages as needed"
echo ""
echo "  # Note: Be careful not to override Omarchy's core configs"
echo "  # (hypr, waybar, rofi, etc.) unless you want to replace them"
echo ""
