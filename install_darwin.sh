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

# Add third-party taps
info "Adding Homebrew taps..."
brew tap nikitabobko/tap
brew tap FelixKratz/formulae
brew tap dimentium/autoraise

# Homebrew 6 refuses to load formulae from an untrusted tap, so tapping alone is
# not enough -- `brew install sketchybar` fails with "Refusing to load formula
# ... from untrusted tap". Trusting is a separate, explicit step, and a
# non-interactive run has no way to answer the prompt. Older Homebrew has no
# `brew trust` command, hence the guard.
if brew trust --help >/dev/null 2>&1; then
    info "Trusting third-party taps..."
    for tap in nikitabobko/tap FelixKratz/formulae dimentium/autoraise; do
        brew trust "$tap" || warn "  Failed to trust $tap"
    done
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
    fastfetch

    # Development
    neovim
    git
    clang-format
    # lldb ships inside the llvm formula; there is no `lldb` formula, and naming
    # one makes the whole `brew install` below fail under `set -e`.
    llvm

    # Status bar + window borders (pairs with AeroSpace)
    sketchybar
    borders

    # Focus follows mouse -- AeroSpace has no setting for it
    autoraise
)

info "Installing Homebrew packages..."
brew install "${BREW_PACKAGES[@]}"

# Install Homebrew casks (GUI apps)
BREW_CASKS=(
    font-jetbrains-mono-nerd-font
    nikitabobko/tap/aerospace
    alacritty
)

info "Installing Homebrew casks..."
brew install --cask "${BREW_CASKS[@]}"

# Remove Gatekeeper quarantine from Alacritty (unsigned cask)
xattr -cr /Applications/Alacritty.app 2>/dev/null || true

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
    ~/.config/aerospace/aerospace.toml
    ~/.config/sketchybar
)

# `[ ! -L ]` only tests the final path component, so a path that reaches a real
# file *through* a stow symlink looks like an ordinary file and would be backed
# up and deleted -- destroying the tracked original in the repo. That is exactly
# what ~/.config/aerospace/aerospace.toml is once ~/.config/aerospace has been
# folded into a symlink. Resolve the path and skip anything living in the repo.
is_in_repo() {
    local resolved
    resolved="$(realpath "$1" 2>/dev/null)" || return 1
    case "$resolved" in
        "$(realpath "$DOTFILES_DIR")"/*) return 0 ;;
        *) return 1 ;;
    esac
}

needs_backup() {
    [ -e "$1" ] && [ ! -L "$1" ] && ! is_in_repo "$1"
}

backup_needed=false
for config in "${CONFIGS_TO_BACKUP[@]}"; do
    if needs_backup "$config"; then
        backup_needed=true
        break
    fi
done

if [ "$backup_needed" = true ]; then
    info "Backing up existing configs to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    for config in "${CONFIGS_TO_BACKUP[@]}"; do
        if needs_backup "$config"; then
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

# Create platform-specific bash symlinks directly (not via stow)
info "Creating macOS-specific bash config symlinks..."
ln -sf "$DOTFILES_DIR/bash/.bashrc-darwin" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/bash/.bash_profile-darwin" "$HOME/.bash_profile"

# Stow packages (use -t ~ in case dotfiles dir isn't ~/dotfiles)
info "Stowing packages..."
STOW_PACKAGES=(git clang nvim starship alacritty aerospace sketchybar autoraise claude)
for pkg in "${STOW_PACKAGES[@]}"; do
    info "  Stowing $pkg..."
    stow -t "$HOME" -R "$pkg" 2>/dev/null || warn "  Failed to stow $pkg"
done

# fastfetch is stowed separately, ignoring config.jsonc, because the macOS
# config is linked over that name below. Stowing it normally makes stow claim
# ~/.config/fastfetch/config.jsonc, and every later run then aborts the whole
# package with "existing target is not owned by stow" -- leaving the other
# fastfetch configs unstowed.
# Note: stow anchors --ignore patterns at both ends itself, so writing
# '^config\.jsonc$' here silently matches nothing and the conflict returns.
info "  Stowing fastfetch (config.jsonc handled separately)..."
stow -t "$HOME" -R --ignore='config\.jsonc' fastfetch 2>/dev/null || warn "  Failed to stow fastfetch"

# Symlink macOS-specific fastfetch config (Apple logo instead of Arch)
mkdir -p "$HOME/.config/fastfetch"
ln -sf "$DOTFILES_DIR/fastfetch/.config/fastfetch/config-darwin.jsonc" "$HOME/.config/fastfetch/config.jsonc"

# Focus follows mouse. Started as a launchd service rather than from AeroSpace's
# after-startup-command so it survives restarting AeroSpace. This has to run
# after stowing, or AutoRaise starts before ~/.config/AutoRaise/config exists
# and comes up with defaults instead.
info "Starting AutoRaise service (focus follows mouse)..."
brew services start dimentium/autoraise/autoraise 2>/dev/null || warn "  Failed to start AutoRaise"

# Clean up macOS desktop to match tiling WM aesthetic
info "Configuring macOS desktop..."

# Auto-hide Dock (sketchybar replaces it)
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
killall Dock 2>/dev/null || true

# Auto-hide menu bar (sketchybar replaces it)
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Hide desktop icons
defaults write com.apple.finder CreateDesktop -bool false
killall Finder 2>/dev/null || true

# Set wallpaper (skull, matching Windows)
WALLPAPER="$DOTFILES_DIR/hypr/.local/share/wallpapers/pexels-ahmedadly-1270184.jpg"
if [ -f "$WALLPAPER" ]; then
    osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$WALLPAPER\""
    info "  ✓ Wallpaper set"
fi

echo ""
info "macOS installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc"
echo "  2. Open Alacritty (Command+Space, type 'Alacritty')"
echo ""
echo "Installed tools:"
echo "  - fzf, bat, ripgrep, fd, eza, zoxide, fastfetch"
echo "  - duf, git-delta, procs"
echo "  - neovim, git, clang-format, llvm (provides lldb)"
echo "  - starship prompt, alacritty terminal"
echo "  - AeroSpace tiling WM (alt+hjkl focus, alt+1-9 workspaces)"
echo "  - sketchybar status bar (Nord theme, workspace indicators)"
echo "  - JankyBorders (active window glow, Nord blue)"
echo "  - AutoRaise (focus follows mouse, like Hyprland)"
echo ""
echo "NOTE: AutoRaise needs Accessibility permission before it will work:"
echo "  System Settings > Privacy & Security > Accessibility > enable AutoRaise"
echo ""
echo "Desktop:"
echo "  - Dock auto-hidden (sketchybar replaces it)"
echo "  - Menu bar auto-hidden"
echo "  - Desktop icons hidden"
echo "  - Wallpaper set (skull)"
echo ""
echo "AeroSpace tiling WM:"
echo "  - Starts at login automatically"
echo "  - Keybinds match GlazeWM (Windows) and Hyprland (Linux):"
echo "    alt+hjkl focus, alt+shift+hjkl move, alt+1-9 workspaces"
echo "    alt+enter Alacritty, alt+shift+q close, alt+f fullscreen"
echo "    alt+v toggle split direction, alt+r resize mode"
echo "    alt+shift+r reload config"
echo "  - Grant Accessibility permission when prompted"
echo ""
echo "Note: You may need to grant terminal permissions in System Preferences"
echo ""
