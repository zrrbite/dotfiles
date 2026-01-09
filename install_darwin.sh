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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "This script is for macOS only."
fi

info "Starting macOS dotfiles installation..."

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Setup Homebrew in PATH (M2 ARM Mac)
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    info "Homebrew already installed"
fi

# Install packages via Homebrew
BREW_PACKAGES=(
    # Core shell
    bash
    bash-completion@2
    stow

    # CLI utilities
    btop
    fzf
    zoxide
    bat
    eza
    ripgrep
    fd
    tldr
    duf
    git-delta
    procs
    starship

    # Development
    neovim
    git
    clang-format
    lldb

    # Terminal
    alacritty
)

info "Installing Homebrew packages..."
brew install "${BREW_PACKAGES[@]}"

# Install Homebrew casks (GUI apps if needed)
BREW_CASKS=(
    font-jetbrains-mono-nerd-font
)

info "Installing Homebrew casks..."
brew install --cask "${BREW_CASKS[@]}"

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
    ~/.config/nvim
    ~/.config/starship.toml
    ~/.config/alacritty
    ~/.gitconfig
    ~/.clang-format
    ~/.bashrc
    ~/.bash_profile
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

# Create platform-specific bash symlinks
info "Creating macOS-specific bash config symlinks..."
cd "$DOTFILES_DIR/bash"
ln -sf .bashrc-darwin .bashrc
ln -sf .bash_profile-darwin .bash_profile
cd "$DOTFILES_DIR"

# Stow universal packages
info "Stowing packages..."
STOW_PACKAGES=(bash git clang nvim starship alacritty)
for pkg in "${STOW_PACKAGES[@]}"; do
    info "  Stowing $pkg..."
    stow -R "$pkg" 2>/dev/null || warn "  Failed to stow $pkg"
done

echo ""
info "macOS installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc"
echo "  2. Open Alacritty (Command+Space, type 'Alacritty')"
echo ""
echo "Installed tools:"
echo "  - fzf, bat, ripgrep, fd, eza, zoxide"
echo "  - duf, git-delta, procs"
echo "  - neovim, git, clang-format, lldb"
echo "  - starship prompt, alacritty terminal"
echo ""
echo "Note: You may need to grant terminal permissions in System Preferences"
echo ""
