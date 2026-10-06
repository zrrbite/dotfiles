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

DRY_RUN=false
WITH_DESKTOP=false
UPGRADE=false

usage() {
    cat <<'USAGE'
Usage: ./install_darwin.sh [options]

Provisions a Mac from this dotfiles repo. Safe to re-run: by default it
installs only what is missing and does not touch your desktop settings.

Options:
  -n, --dry-run     Print every action without performing it.
      --with-desktop  Also apply desktop settings: auto-hide the Dock and menu
                    bar, hide desktop icons, set the wallpaper, and restart
                    Dock and Finder. Intended for a fresh machine -- this
                    overwrites your current wallpaper.
      --upgrade     Pass every package to `brew install` even when already
                    present, which upgrades outdated ones. Off by default so a
                    re-run cannot silently bump e.g. clang-format across major
                    versions and change how the pre-commit hook formats code.
  -h, --help        Show this message.

Typical use:
  ./install_darwin.sh --dry-run              # see what would happen
  ./install_darwin.sh                        # safe re-run
  ./install_darwin.sh --with-desktop         # fresh machine
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=true ;;
        --with-desktop) WITH_DESKTOP=true ;;
        --upgrade) UPGRADE=true ;;
        -h|--help) usage; exit 0 ;;
        *) usage; error "Unknown option: $1" ;;
    esac
    shift
done

# Every mutating command goes through run() so --dry-run is honoured in one
# place rather than sprinkled through the script.
run() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY]${NC} $*"
    else
        "$@"
    fi
}

# Same, for commands whose failure is expected and ignored.
run_ok() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY]${NC} $* ${YELLOW}(failure ignored)${NC}"
    else
        "$@" 2>/dev/null || true
    fi
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "This script is for macOS only."
fi

info "Starting macOS dotfiles installation..."

# Command Line Tools provide git and the compilers Homebrew needs. Installing
# them pops up a GUI dialog that a script (or an agent) cannot click through,
# so stop and say so rather than failing halfway.
if ! xcode-select -p >/dev/null 2>&1; then
    error "Command Line Tools are missing. Run: xcode-select --install -- then re-run this script."
fi

# Steps that fail without stopping the script are collected here and reported
# at the end, so "installation complete" is never printed over a failure.
FAILURES=()
[ "$DRY_RUN" = true ] && warn "DRY RUN -- nothing will be changed"
[ "$WITH_DESKTOP" = true ] && warn "--with-desktop: wallpaper and Dock/Finder settings WILL be overwritten"

# Homebrew may be installed but not on this shell's PATH -- e.g. the human ran
# its installer and the agent's shell predates the shellenv line it adds to
# ~/.zprofile. Load it from the standard locations before deciding it's
# missing, rather than running the Homebrew installer a second time.
if ! command -v brew &> /dev/null; then
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [ -x "$b" ] && eval "$("$b" shellenv)" && break
    done
fi

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    info "Installing Homebrew..."
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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
run brew tap nikitabobko/tap
run brew tap FelixKratz/formulae
run brew tap dimentium/autoraise

# Homebrew 6 refuses to load formulae from an untrusted tap, so tapping alone is
# not enough -- `brew install sketchybar` fails with "Refusing to load formula
# ... from untrusted tap". Trusting is a separate, explicit step. Older Homebrew
# has no `brew trust` command, hence the guard.
if brew trust --help >/dev/null 2>&1; then
    info "Trusting third-party taps..."
    for tap in nikitabobko/tap FelixKratz/formulae dimentium/autoraise; do
        run brew trust "$tap" || warn "  Failed to trust $tap"
    done
fi

# Install packages via Homebrew
BREW_PACKAGES=(
    # Core shell
    bash
    bash-completion@2
    stow
    tmux
    # Terminal file manager (Finder replacement) and terminal image viewer.
    # yazi's previews use ffmpeg (video), poppler (PDF), 7zz (archives),
    # fd/rg/fzf/zoxide (search and jump) -- all installed here as well.
    yazi
    chafa
    glow       # Markdown rendering, for yazi's preview pane
    # zsh: grey suggestions from history, green/red command highlighting
    zsh-autosuggestions
    zsh-syntax-highlighting
    ffmpeg
    poppler
    sevenzip

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
    # nvim's ts_ls setup shells out to typescript-language-server, which is an
    # npm package -- so node is a hard dependency of the TypeScript IDE support,
    # not an optional extra. Installed globally below.
    node

    # Status bar + window borders (pairs with AeroSpace)
    sketchybar
    borders

    # Focus follows mouse -- AeroSpace has no setting for it
    autoraise
)

BREW_CASKS=(
    font-jetbrains-mono-nerd-font
    # App icons in the sketchybar workspace pills. Its version must match the
    # vendored sketchybar/.config/sketchybar/plugins/icon_map.sh -- a newer
    # font with an older map still works, the reverse renders names as text.
    font-sketchybar-app-font
    nikitabobko/tap/aerospace
    alacritty
    # Default terminal (alt-enter), on trial against Alacritty; see CLAUDE.md
    ghostty
)

# `brew install <already-installed-but-outdated>` upgrades it. That makes a
# plain re-run capable of jumping clang-format several major versions, which
# changes formatting output and therefore what the pre-commit hook rejects. So
# install only what is missing unless --upgrade was asked for.
if [ "$UPGRADE" = true ]; then
    info "Installing Homebrew packages (--upgrade: existing packages may be upgraded)..."
    run brew install "${BREW_PACKAGES[@]}" \
        || FAILURES+=("brew install failed for one or more of: ${BREW_PACKAGES[*]}")
    info "Installing Homebrew casks..."
    run brew install --cask "${BREW_CASKS[@]}" \
        || FAILURES+=("brew install failed for one or more of: ${BREW_CASKS[*]}")
else
    INSTALLED_FORMULAE="$(brew list --formula -1 2>/dev/null || true)"
    MISSING_FORMULAE=()
    for pkg in "${BREW_PACKAGES[@]}"; do
        if ! printf '%s\n' "$INSTALLED_FORMULAE" | grep -qx -- "${pkg##*/}"; then
            MISSING_FORMULAE+=("$pkg")
        fi
    done

    if [ ${#MISSING_FORMULAE[@]} -gt 0 ]; then
        info "Installing missing packages: ${MISSING_FORMULAE[*]}"
        run brew install "${MISSING_FORMULAE[@]}" \
            || FAILURES+=("brew install failed for one or more of: ${MISSING_FORMULAE[*]}")
    else
        info "All Homebrew packages already installed (use --upgrade to update them)"
    fi

    INSTALLED_CASKS="$(brew list --cask -1 2>/dev/null || true)"
    MISSING_CASKS=()
    for cask in "${BREW_CASKS[@]}"; do
        if ! printf '%s\n' "$INSTALLED_CASKS" | grep -qx -- "${cask##*/}"; then
            MISSING_CASKS+=("$cask")
        fi
    done

    if [ ${#MISSING_CASKS[@]} -gt 0 ]; then
        info "Installing missing casks: ${MISSING_CASKS[*]}"
        run brew install --cask "${MISSING_CASKS[@]}" \
            || FAILURES+=("brew install failed for one or more of: ${MISSING_CASKS[*]}")
    else
        info "All Homebrew casks already installed"
    fi
fi

# Remove Gatekeeper quarantine from Alacritty (unsigned cask)
run_ok xattr -cr /Applications/Alacritty.app

# TypeScript language server. nvim names `typescript-language-server` as ts_ls's
# cmd, so without this the TypeScript half of the nvim setup silently does
# nothing. npm is only missing here if the node install above was skipped.
if command -v npm >/dev/null 2>&1; then
    if npm ls -g --depth=0 typescript-language-server >/dev/null 2>&1; then
        info "typescript-language-server already installed"
    else
        info "Installing typescript-language-server..."
        run npm install -g typescript-language-server typescript
    fi
else
    warn "npm not found -- skipping typescript-language-server (nvim's ts_ls will not start)"
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
        run git clone https://github.com/zrrbite/dotfiles.git "$DOTFILES_DIR"
    else
        info "Dotfiles directory exists, pulling latest..."
        cd "$DOTFILES_DIR" && run git pull
    fi
fi

cd "$DOTFILES_DIR"

# Backup existing configs
BACKUP_DIR="${HOME}/.config-backup-$(date +%Y%m%d-%H%M%S)"
CONFIGS_TO_BACKUP=(
    ~/.config/nvim
    ~/.config/starship.toml
    ~/.config/alacritty
    ~/.config/ghostty
    ~/.gitconfig
    ~/.clang-format
    ~/.bashrc
    ~/.bash_profile
    ~/.zshrc
    ~/.tmux.conf
    ~/.config/aerospace/aerospace.toml
    ~/.config/sketchybar
    ~/.config/AutoRaise
    ~/.clang-tidy
    ~/.git-hooks
    ~/.gitignore-global
    # Claude Code creates ~/.claude itself; an existing skills/ or CLAUDE.md
    # would otherwise make `stow claude` conflict.
    ~/.claude/CLAUDE.md
    ~/.claude/skills
    ~/.claude/hooks
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

# git/.gitconfig carries no identity or credential helper; those live in
# ~/.gitconfig.local, which it includes last. Carry the existing ones over
# before ~/.gitconfig is backed up and replaced, so a machine keeps its own
# identity (a work laptop keeps its work email).
DRY_RUN="$DRY_RUN" "$DOTFILES_DIR/scripts/seed-gitconfig-local.sh"

backup_needed=false
for config in "${CONFIGS_TO_BACKUP[@]}"; do
    if needs_backup "$config"; then
        backup_needed=true
        break
    fi
done

if [ "$backup_needed" = true ]; then
    info "Backing up existing configs to $BACKUP_DIR"
    run mkdir -p "$BACKUP_DIR"
    for config in "${CONFIGS_TO_BACKUP[@]}"; do
        if needs_backup "$config"; then
            info "  Backing up $config"
            # Only delete the original once the copy has succeeded. Otherwise
            # leave it in place: stow will then report a conflict for it,
            # which is recoverable, where a lost config is not.
            if run cp -R "$config" "$BACKUP_DIR/"; then
                run rm -rf "$config"
            else
                warn "  Backup of $config failed -- leaving it in place"
                FAILURES+=("backup of $config failed; it was left in place")
            fi
        fi
    done
else
    info "No configs need backing up"
fi

# Remove any existing symlinks that might conflict
for config in "${CONFIGS_TO_BACKUP[@]}"; do
    if [ -L "$config" ]; then
        run rm "$config"
    fi
done

# Create platform-specific bash symlinks directly (not via stow)
info "Creating macOS-specific bash config symlinks..."
run ln -sf "$DOTFILES_DIR/bash/.bashrc-darwin" "$HOME/.bashrc"
run ln -sf "$DOTFILES_DIR/bash/.bash_profile-darwin" "$HOME/.bash_profile"

# Stow packages (use -t ~ in case dotfiles dir isn't ~/dotfiles).
# stow's conflict reports go to stderr and are worth seeing, so they are not
# silenced -- a hidden failure here means a config silently missing from $HOME.
info "Stowing packages..."

# Directories that must exist *before* stow runs. When a target directory is
# missing, stow "folds" it: it links the whole directory into the repo instead
# of the files inside it. On a fresh Mac that turns ~/.config into a symlink
# into this repo, so every app writing its config would write into the working
# tree. The same goes for ~/.claude (Claude Code's history and settings), and
# for ~/.config/fastfetch, where the macOS config is linked in below.
# scripts/verify.sh checks that none of these ended up as a symlink.
run mkdir -p "$HOME/.config" "$HOME/.config/fastfetch" "$HOME/.claude"

# shellcheck source=scripts/packages.sh
source "$DOTFILES_DIR/scripts/packages.sh"
STOW_PACKAGES=("${PACKAGES_DARWIN[@]}")
for pkg in "${STOW_PACKAGES[@]}"; do
    info "  Stowing $pkg..."
    if ! run stow -t "$HOME" -R "$pkg"; then
        warn "  Failed to stow $pkg (see stow output above)"
        FAILURES+=("stow $pkg failed (conflict? see: stow -n -v -t ~ $pkg)")
    fi
done

# fastfetch is stowed separately, ignoring config.jsonc, because the macOS
# config is linked over that name below. Stowing it normally makes stow claim
# ~/.config/fastfetch/config.jsonc, and every later run then aborts the whole
# package with "existing target is not owned by stow" -- leaving the other
# fastfetch configs unstowed.
# Note: stow anchors --ignore patterns at both ends itself, so writing
# '^config\.jsonc$' here silently matches nothing and the conflict returns.
info "  Stowing fastfetch (config.jsonc handled separately)..."
run stow -t "$HOME" -R --ignore='config\.jsonc' fastfetch || FAILURES+=("stow fastfetch failed")

# Symlink macOS-specific fastfetch config (Apple logo instead of Arch).
# ~/.config/fastfetch was created as a real directory above, so this writes
# into $HOME -- not through a folded link over the repo's tracked config.jsonc.
run ln -sf "$DOTFILES_DIR/fastfetch/.config/fastfetch/config-darwin.jsonc" "$HOME/.config/fastfetch/config.jsonc"

# yazi plugins (git status column, Markdown preview) are declared in
# yazi/.config/yazi/package.toml but not committed; fetch them now that the
# config is linked.
if command -v ya >/dev/null 2>&1; then
    info "Installing yazi plugins..."
    run ya pkg install || FAILURES+=("ya pkg install failed; yazi works, minus its plugins")
fi

# tmux-resurrect: save/restore tmux sessions across reboots. Loaded by
# tmux/.tmux.conf if present; pinned to a release tag.
if [ ! -d "$HOME/.tmux/plugins/tmux-resurrect" ]; then
    info "Installing tmux-resurrect..."
    run git clone -q --depth 1 --branch v4.0.0 \
        https://github.com/tmux-plugins/tmux-resurrect "$HOME/.tmux/plugins/tmux-resurrect" \
        || FAILURES+=("tmux-resurrect clone failed; tmux works without it")
fi
# tmux-continuum: auto-saves every 15 minutes and restores on tmux start.
if [ ! -d "$HOME/.tmux/plugins/tmux-continuum" ]; then
    info "Installing tmux-continuum..."
    run git clone -q --depth 1 --branch v3.1.0 \
        https://github.com/tmux-plugins/tmux-continuum "$HOME/.tmux/plugins/tmux-continuum" \
        || FAILURES+=("tmux-continuum clone failed; saving stays manual (prefix Ctrl-s)")
fi

# oh-my-zsh, which zsh/.zshrc loads when present. Cloned rather than run
# through its install.sh, because that script rewrites ~/.zshrc -- which is
# the stowed file from this repo.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing oh-my-zsh (clone only; ~/.zshrc stays the repo's)..."
    run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" \
        || FAILURES+=("oh-my-zsh clone failed; zsh still works without it")
fi

# Focus follows mouse. Started as a launchd service rather than from AeroSpace's
# after-startup-command so it survives restarting AeroSpace. This has to run
# after stowing, or AutoRaise starts before ~/.config/AutoRaise/config exists
# and comes up with defaults instead.
info "Starting AutoRaise service (focus follows mouse)..."
run brew services start dimentium/autoraise/autoraise \
    || FAILURES+=("AutoRaise service did not start: brew services start dimentium/autoraise/autoraise")

# Desktop settings are opt-in. They overwrite the wallpaper and restart Dock and
# Finder, which is right on a fresh machine and unwelcome on a re-run.
if [ "$WITH_DESKTOP" = true ]; then
    info "Configuring macOS desktop..."

    # Auto-hide Dock (sketchybar replaces it)
    run defaults write com.apple.dock autohide -bool true
    run defaults write com.apple.dock autohide-delay -float 0
    run defaults write com.apple.dock autohide-time-modifier -float 0.3
    run_ok killall Dock

    # Auto-hide menu bar (sketchybar replaces it)
    run defaults write NSGlobalDomain _HIHideMenuBar -bool true

    # Hide desktop icons
    run defaults write com.apple.finder CreateDesktop -bool false
    # Hidden files, extensions, path and status bars, list view, no .DS_Store
    # on network or USB drives. Also runnable alone; --undo reverts it. It
    # restarts Finder itself.
    run "$DOTFILES_DIR/scripts/finder-defaults.sh"

    # Set wallpaper (skull, matching Windows)
    WALLPAPER="$DOTFILES_DIR/hypr/.local/share/wallpapers/pexels-ahmedadly-1270184.jpg"
    if [ -f "$WALLPAPER" ]; then
        run osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$WALLPAPER\""
        info "  Wallpaper set"
    fi
else
    info "Skipping desktop settings (pass --with-desktop to apply them)"
fi

# The same read-only check an agent or person would run afterwards. Its
# failures (an unlinked package, no git identity, a folder folded into the
# repo) count as installer failures.
if [ "$DRY_RUN" != true ]; then
    echo ""
    info "Verifying..."
    "$DOTFILES_DIR/scripts/verify.sh" || FAILURES+=("scripts/verify.sh reported failures (see above)")
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    info "Dry run complete -- nothing was changed."
elif [ "${#FAILURES[@]}" -gt 0 ]; then
    warn "macOS installation finished with ${#FAILURES[@]} problem(s):"
    for f in "${FAILURES[@]}"; do warn "  - $f"; done
else
    info "macOS installation complete!"
fi
echo ""
echo "Next steps:"
echo "  1. Open a new terminal (zsh is the login shell; ~/.zshrc is linked)"
echo "  2. alt+enter opens Ghostty once AeroSpace is running"
echo "  3. Grant Accessibility to AeroSpace AND AutoRaise:"
echo "     System Settings > Privacy & Security > Accessibility"
echo "  4. Check the result: $DOTFILES_DIR/scripts/verify.sh"
echo ""
echo "Installed tools:"
echo "  - fzf, bat, ripgrep, fd, eza, zoxide, fastfetch"
echo "  - duf, git-delta, procs"
echo "  - neovim, git, clang-format, llvm (provides lldb)"
echo "  - starship prompt, ghostty terminal (alt-enter), alacritty alongside (alt-shift-enter)"
echo "  - AeroSpace tiling WM (alt+hjkl focus, alt+1-9 workspaces)"
echo "  - sketchybar status bar (Nord theme, workspace indicators)"
echo "  - JankyBorders (active window glow, Nord blue)"
echo "  - AutoRaise (focus follows mouse, like Hyprland)"
echo ""
if [ "$WITH_DESKTOP" = true ]; then
    echo "Desktop:"
    echo "  - Dock auto-hidden (sketchybar replaces it)"
    echo "  - Menu bar auto-hidden"
    echo "  - Desktop icons hidden"
    echo "  - Wallpaper set (skull)"
    echo ""
fi
echo "AeroSpace tiling WM:"
echo "  - Starts at login automatically"
echo "  - Keybinds match GlazeWM (Windows) and Hyprland (Linux):"
echo "    alt+hjkl focus, alt+shift+hjkl move, alt+1-9 workspaces"
echo "    alt+enter Ghostty, alt+shift+enter Alacritty, alt+shift+q close, alt+f fullscreen"
echo "    alt+tab cycle windows, alt+v toggle split direction"
echo "    alt+r resize mode, alt+shift+r reload config"
echo "  - Grant Accessibility permission when prompted"
echo ""
echo "Note: You may need to grant terminal permissions in System Preferences"
echo ""

# Non-zero exit when something failed, so a caller (a person's shell history,
# or an agent) can't mistake a partial install for a finished one.
if [ "$DRY_RUN" != true ] && [ "${#FAILURES[@]}" -gt 0 ]; then
    exit 1
fi
