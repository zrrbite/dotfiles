#!/usr/bin/env bash
#
# Read-only check of whether this repo is applied to the current machine.
# Changes nothing. Prints PASS / WARN / FAIL lines and exits non-zero if any
# check FAILs, so an agent (or a person) has an unambiguous "done" signal.
#
# Usage: scripts/verify.sh [package ...]
#   With no arguments, checks the packages the installer for this OS stows.
#   Pass a list to check only those -- e.g. on a work machine that applied a
#   subset:  scripts/verify.sh nvim starship tmux ghostty
#   `claude-skills` checks the claude package without CLAUDE.md, for machines
#   where it is deliberately left out (see doc/applying-the-setup.md).
#
# What "applied" means for a package: `stow -n` against $HOME has nothing left
# to link and no conflicts. That is stow's own view, so it accounts for
# folding and ignore lists exactly as the real stow did.

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_REAL="$(realpath "$DOTFILES_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
FAILS=0
WARNS=0
pass() { echo -e "${GREEN}PASS${NC} $1"; }
warn() { echo -e "${YELLOW}WARN${NC} $1"; WARNS=$((WARNS + 1)); }
fail() { echo -e "${RED}FAIL${NC} $1"; FAILS=$((FAILS + 1)); }

case "$(uname -s)" in
    Darwin) OS=darwin ;;
    Linux)
        if [ -f /etc/arch-release ]; then OS=arch; else OS=debian; fi ;;
    *) echo "Unsupported OS: $(uname -s). On Windows, see doc/applying-the-setup.md."; exit 2 ;;
esac

# The same lists the installers stow. On macOS, fastfetch is checked
# separately below, because it is stowed with an ignore pattern.
# shellcheck source=scripts/packages.sh
source "$DOTFILES_DIR/scripts/packages.sh"
case "$OS" in
    darwin) DEFAULT=("${PACKAGES_DARWIN[@]}") ;;
    arch)   DEFAULT=("${PACKAGES_ARCH[@]}") ;;
    debian) DEFAULT=("${PACKAGES_DEBIAN[@]}") ;;
esac
if [ $# -gt 0 ]; then PACKAGES=("$@"); else PACKAGES=("${DEFAULT[@]}"); fi

echo "Checking $OS against $DOTFILES_DIR"
echo

# -- Prerequisites ------------------------------------------------------------
command -v stow >/dev/null 2>&1 || { fail "stow is not installed -- nothing else can be checked"; exit 1; }

# -- Packages -----------------------------------------------------------------
for pkg in "${PACKAGES[@]}"; do
    stow_args=()
    if [ "$pkg" = claude-skills ]; then
        pkg=claude
        stow_args=(--ignore='CLAUDE\.md')
    fi
    if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
        fail "$pkg: no such package in the repo"
        continue
    fi
    out="$(stow -n -v "${stow_args[@]}" -d "$DOTFILES_DIR" -t "$HOME" "$pkg" 2>&1)"
    if echo "$out" | grep -q -E 'CONFLICT|cannot stow|existing target'; then
        fail "$pkg: conflicts with files already in \$HOME (see: stow -n -v -t ~ $pkg)"
    elif echo "$out" | grep -q '^LINK:'; then
        fail "$pkg: not linked yet ($(echo "$out" | grep -c '^LINK:') links missing)"
    else
        pass "$pkg: linked"
    fi
done

if [ $# -eq 0 ] && [ "$OS" = darwin ]; then
    ff="$HOME/.config/fastfetch/config.jsonc"
    if [ "$(realpath "$ff" 2>/dev/null)" = "$REPO_REAL/fastfetch/.config/fastfetch/config-darwin.jsonc" ]; then
        pass "fastfetch: macOS config linked"
    else
        fail "fastfetch: ~/.config/fastfetch/config.jsonc should link to config-darwin.jsonc"
    fi
fi

# -- Directories that must never be a symlink into the repo --------------------
# If stow "folds" one of these into a single symlink, anything that later writes
# there -- apps writing config, Claude Code writing its history, the installer
# linking fastfetch's macOS config -- writes inside the repo instead.
for d in "$HOME/.config" "$HOME/.config/fastfetch" "$HOME/.claude"; do
    if [ -L "$d" ]; then
        case "$(realpath "$d")" in
            "$REPO_REAL"/*) fail "$d is a symlink into the repo; apps will write into the working tree" ;;
            *) pass "$d is not linked into the repo" ;;
        esac
    elif [ -d "$d" ]; then
        pass "$d is a real directory"
    fi
done

# -- Repo state ---------------------------------------------------------------
dirty="$(git -C "$DOTFILES_DIR" status --porcelain 2>/dev/null)"
if [ -n "$dirty" ]; then
    warn "repo has uncommitted changes -- if you didn't make them, something wrote into it:"
    while IFS= read -r line; do echo "       $line"; done <<< "$dirty"
else
    pass "repo working tree is clean"
fi

# -- Git ----------------------------------------------------------------------
# `--includes` is required: --global alone does not follow ~/.gitconfig.local.
for key in user.name user.email; do
    line="$(git config --global --includes --show-origin --get "$key" 2>/dev/null)"
    if [ -z "$line" ]; then
        fail "git $key is not set -- create ~/.gitconfig.local (scripts/seed-gitconfig-local.sh)"
        continue
    fi
    origin="${line%%	*}"
    origin="${origin#file:}"
    case "$(realpath "${origin/#\~/$HOME}" 2>/dev/null)" in
        "$REPO_REAL"/*) fail "git $key comes from the tracked repo file -- it belongs in ~/.gitconfig.local" ;;
        *) pass "git $key = ${line#*	} (from $origin)" ;;
    esac
done

# The shared gitconfig calls these; a missing one breaks diff/log/commit.
if [ "$(realpath "$HOME/.gitconfig" 2>/dev/null)" = "$REPO_REAL/git/.gitconfig" ]; then
    for tool in delta nvim; do
        if command -v "$tool" >/dev/null 2>&1; then
            pass "$tool installed (used by git/.gitconfig)"
        else
            fail "$tool missing, but git/.gitconfig uses it -- git diff/log or commit will break"
        fi
    done
fi

# -- Running services (macOS desktop) -----------------------------------------
if [ "$OS" = darwin ] && [ $# -eq 0 ]; then
    for proc in AeroSpace sketchybar borders; do
        if pgrep -x "$proc" >/dev/null 2>&1; then
            pass "$proc is running"
        else
            warn "$proc is not running (AeroSpace starts it at login; launch AeroSpace once)"
        fi
    done
    if brew services list 2>/dev/null | grep -q -E '^autoraise[[:space:]]+started'; then
        pass "AutoRaise service is started"
    else
        # FAIL, not WARN: the installer starts this itself, so not running is
        # a real failure. The three processes above need AeroSpace launched
        # once by a person, so they only warn.
        fail "AutoRaise service not started: brew services start dimentium/autoraise/autoraise"
    fi
    echo
    echo "Cannot be checked from a script -- confirm by hand:"
    echo "  - Accessibility is granted to AeroSpace and AutoRaise"
    echo "    (System Settings > Privacy & Security > Accessibility)"
    echo "  - a new terminal shows the Nord starship prompt"
fi

echo
if [ "$FAILS" -gt 0 ]; then
    echo -e "${RED}$FAILS check(s) failed${NC}, $WARNS warning(s)."
    exit 1
fi
echo -e "${GREEN}All checks passed${NC}, $WARNS warning(s)."
