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

# Check if running on Ubuntu/Debian (WSL)
if ! command -v apt &> /dev/null; then
    error "apt not found. This script is for Ubuntu/Debian-based WSL."
fi

info "Starting WSL dotfiles installation..."

# Update package lists
info "Updating package lists..."
sudo apt update

# Install apt packages
APT_PACKAGES=(
    bash-completion
    stow
    btop
    fzf
    bat  # Called batcat on Ubuntu
    ripgrep
    fd-find  # Called fdfind on Ubuntu
    git
    build-essential  # For compiling tools
    clang
    clang-format
    clangd
    gdb
    tldr
    curl
    unzip
)

info "Installing apt packages..."
sudo apt install -y "${APT_PACKAGES[@]}"

# Install Neovim (latest from GitHub releases)
if ! command -v nvim &> /dev/null; then
    info "Installing Neovim..."
    NVIM_VERSION="v0.10.2"
    curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz"
    sudo tar -C /opt -xzf nvim-linux64.tar.gz
    sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux64.tar.gz
else
    info "Neovim already installed"
fi

# Install starship prompt
if ! command -v starship &> /dev/null; then
    info "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    info "Starship already installed"
fi

# Install zoxide
if ! command -v zoxide &> /dev/null; then
    info "Installing zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
else
    info "Zoxide already installed"
fi

# Install eza (modern ls)
if ! command -v eza &> /dev/null; then
    info "Installing eza..."
    # Install from GitHub releases
    EZA_VERSION="v0.20.14"
    curl -Lo eza.zip "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
    sudo tar -xzf eza.zip -C /usr/local/bin
    rm eza.zip
else
    info "eza already installed"
fi

# Install duf (disk usage)
if ! command -v duf &> /dev/null; then
    info "Installing duf..."
    DUF_VERSION="0.8.1"
    curl -Lo duf.deb "https://github.com/muesli/duf/releases/download/v${DUF_VERSION}/duf_${DUF_VERSION}_linux_amd64.deb"
    sudo dpkg -i duf.deb
    rm duf.deb
else
    info "duf already installed"
fi

# Install git-delta
if ! command -v delta &> /dev/null; then
    info "Installing git-delta..."
    DELTA_VERSION="0.18.2"
    curl -Lo delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
    sudo dpkg -i delta.deb
    rm delta.deb
else
    info "git-delta already installed"
fi

# Install procs
if ! command -v procs &> /dev/null; then
    info "Installing procs..."
    PROCS_VERSION="0.14.8"
    curl -Lo procs.zip "https://github.com/dalance/procs/releases/download/v${PROCS_VERSION}/procs-v${PROCS_VERSION}-x86_64-linux.zip"
    unzip -o procs.zip
    sudo mv procs /usr/local/bin/
    rm procs.zip
else
    info "procs already installed"
fi

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
    ~/.gitconfig
    ~/.clang-format
    ~/.clang-tidy
    ~/.gdbinit
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
info "Creating WSL-specific bash config symlinks..."
cd "$DOTFILES_DIR/bash"
ln -sf .bashrc-wsl .bashrc
ln -sf .bash_profile-wsl .bash_profile
cd "$DOTFILES_DIR"

# Stow universal packages (no GUI/Wayland stuff)
info "Stowing packages..."
STOW_PACKAGES=(bash git clang gdb nvim starship)
for pkg in "${STOW_PACKAGES[@]}"; do
    info "  Stowing $pkg..."
    stow -R "$pkg" 2>/dev/null || warn "  Failed to stow $pkg"
done

echo ""
info "WSL installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc"
echo "  2. Install JetBrains Mono Nerd Font on Windows for proper icons"
echo ""
echo "Installed tools:"
echo "  - fzf, bat, ripgrep, fd, eza, zoxide"
echo "  - duf, git-delta, procs"
echo "  - neovim, git, clang, gdb"
echo "  - starship prompt"
echo ""
