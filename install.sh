#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running on Arch Linux
if [ ! -f /etc/arch-release ]; then
    error "This script is designed for Arch Linux"
fi

info "Starting dotfiles installation..."

# Core packages
PACKAGES=(
    # Window manager & display
    hyprland
    hyprpaper
    hyprlock
    hypridle
    brightnessctl
    asciiquarium
    waybar
    xorg-xwayland
    xdg-desktop-portal-hyprland
    polkit-gnome

    # Terminal & shell
    foot
    starship

    # Audio
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol

    # Media
    mpv
    imv

    # File manager
    thunar

    # Bluetooth
    blueman

    # Communication
    discord

    # Utilities
    stow
    rofi-wayland
    wl-clipboard
    cliphist
    mako
    libnotify
    grim
    slurp
    wf-recorder
    btop

    # Development
    neovim
    git
    openssh
    ripgrep
    fd
    clang
    code
    meld

    # LaTeX (beamer for presentations)
    texlive-basic
    texlive-bin
    texlive-latexrecommended
    texlive-latexextra
    texlive-fontsrecommended
    texlive-pictures

    # Fonts
    ttf-jetbrains-mono-nerd
    ttf-nerd-fonts-symbols
    noto-fonts-cjk
    noto-fonts-emoji
)

info "Installing packages..."
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# AUR packages (requires yay)
AUR_PACKAGES=(
    google-chrome
    slack-desktop
    p4
    p4v
)

# Install yay if not present
if ! command -v yay &> /dev/null; then
    info "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    rm -rf /tmp/yay
fi

info "Installing AUR packages..."
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

# Determine dotfiles location
DOTFILES_DIR="${HOME}/dotfiles"

# If we're running from inside the dotfiles repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/.git/config" ]; then
    DOTFILES_DIR="$SCRIPT_DIR"
    info "Running from dotfiles directory: $DOTFILES_DIR"
else
    # Clone if not exists
    if [ ! -d "$DOTFILES_DIR" ]; then
        info "Cloning dotfiles repository..."
        git clone https://github.com/zrrbite/dotfiles.git "$DOTFILES_DIR"
    else
        info "Dotfiles directory exists, pulling latest..."
        cd "$DOTFILES_DIR" && git pull
    fi
fi

cd "$DOTFILES_DIR"

# Backup existing configs
BACKUP_DIR="${HOME}/.config-backup-$(date +%Y%m%d-%H%M%S)"
CONFIGS_TO_BACKUP=(
    ~/.config/foot
    ~/.config/hypr
    ~/.config/waybar
    ~/.config/rofi
    ~/.config/mako
    ~/.config/btop
    ~/.config/nvim
    ~/.config/starship.toml
    ~/.gitconfig
    ~/.clang-format
    ~/.clang-tidy
    ~/.bash_profile
    ~/.local/share/wallpapers
)

backup_needed=false
for config in "${CONFIGS_TO_BACKUP[@]}"; do
    if [ -e "$config" ] && [ ! -L "$config" ]; then
        backup_needed=true
        break
    fi
done

if [ "$backup_needed" = true ]; then
    info "Backing up existing configs to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    for config in "${CONFIGS_TO_BACKUP[@]}"; do
        if [ -e "$config" ] && [ ! -L "$config" ]; then
            cp -r "$config" "$BACKUP_DIR/" 2>/dev/null || true
            rm -rf "$config"
        fi
    done
fi

# Remove any existing symlinks that might conflict
for config in "${CONFIGS_TO_BACKUP[@]}"; do
    if [ -L "$config" ]; then
        rm "$config"
    fi
done

# Stow all packages
info "Stowing all packages..."
for dir in */; do
    if [ -d "$dir" ] && [ "$dir" != ".git/" ]; then
        pkg="${dir%/}"
        info "  Stowing $pkg..."
        stow -R "$pkg" 2>/dev/null || warn "  Failed to stow $pkg"
    fi
done

# Setup starship for bash and zsh
if [ -f ~/.bashrc ]; then
    if ! grep -q 'starship init bash' ~/.bashrc; then
        info "Adding starship to ~/.bashrc"
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
    fi
fi

if [ -f ~/.zshrc ]; then
    if ! grep -q 'starship init zsh' ~/.zshrc; then
        info "Adding starship to ~/.zshrc"
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    fi
fi

# Setup ssh-agent for bash and zsh
SSH_AGENT_SETUP='
# SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi
if [ -f ~/.ssh/id_ed25519 ]; then
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi'

if [ -f ~/.bashrc ]; then
    if ! grep -q 'SSH_AUTH_SOCK' ~/.bashrc; then
        info "Adding ssh-agent to ~/.bashrc"
        echo "$SSH_AGENT_SETUP" >> ~/.bashrc
    fi
fi

if [ -f ~/.zshrc ]; then
    if ! grep -q 'SSH_AUTH_SOCK' ~/.zshrc; then
        info "Adding ssh-agent to ~/.zshrc"
        echo "$SSH_AGENT_SETUP" >> ~/.zshrc
    fi
fi

# Enable pipewire audio
info "Enabling audio services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

echo ""
info "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Reboot (or log out and back in)"
echo "  2. Hyprland will auto-start on TTY1"
echo ""
echo "Key bindings:"
echo "  Super + Q      - Open terminal (foot)"
echo "  Super + R      - App launcher (rofi)"
echo "  Super + C      - Close window"
echo "  Super + L      - Lock screen"
echo "  Super + Shift+V - Clipboard history"
echo "  Super + Shift+S - Screenshot region"
echo "  Super + F1     - Show all keybinds"
echo ""
