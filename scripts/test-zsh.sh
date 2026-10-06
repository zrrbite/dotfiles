#!/usr/bin/env bash
#
# Check what a new terminal's zsh gets on this machine: zsh/.zshrc with its
# per-OS file, and the tools it wires up. Runs real `zsh -i` shells. Used on
# the Mac directly and inside the Linux test containers
# (scripts/test-in-docker.sh). Exit 0 = every check passed.
#
# Usage: scripts/test-zsh.sh
#
# shellcheck disable=SC2016  # $ in single quotes is expanded by zsh, not here

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
FAILS=0
ok()  { echo -e "${GREEN}ok${NC}   $1"; }
bad() { echo -e "${RED}FAIL${NC} $1"; FAILS=$((FAILS + 1)); }
# expect NAME ACTUAL WANTED
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1: got [$2], wanted [$3]"; fi; }
# expect_has NAME ACTUAL SUBSTRING
expect_has() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1: [$2] lacks [$3]" ;; esac; }

ZSH_BIN="$(command -v zsh)" || { bad "zsh is not installed"; exit 1; }

# An interactive zsh running one command. SSH_AUTH_SOCK is set so it starts no
# ssh-agent that outlives it; DISABLE_AUTO_UPDATE stops oh-my-zsh asking to
# update in the middle of a check.
zi() { SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true "$ZSH_BIN" -i -c "$1" 2>&1; }
# Is a command on zsh's PATH (which can differ from this script's)?
zhas() { [ -n "$(zi "whence -p $1")" ]; }

case "$(uname -s)" in Darwin) OS=darwin ;; *) OS=linux ;; esac
echo "zsh checks on $OS, $("$ZSH_BIN" --version)"

# -- Startup ---------------------------------------------------------------------
err="$(SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true "$ZSH_BIN" -i -c exit 2>&1 >/dev/null)"
expect "starts without printing errors" "$err" ""

# -- Functions and aliases from the shared .zshrc ----------------------------------
for f in t tp y; do
    expect "$f is a function" "$(zi "whence -w $f")" "$f: function"
done
for a in fcpp ftodo fmd ffunc; do
    expect_has "alias $a" "$(zi "alias $a")" "$a="
done
if zhas eza; then
    for a in ll lt la; do expect_has "alias $a uses eza" "$(zi "alias $a")" "eza"; done
fi
case "$(zi 'alias ls')" in
    *eza*) bad "ls is aliased to eza; it must stay ls" ;;
    *)     ok "ls is not eza" ;;
esac

# -- Tools ------------------------------------------------------------------------
expect "oh-my-zsh loaded" "$(zi 'print ${+functions[omz]}')" "1"
zhas fzf      && expect_has "Ctrl+R is fzf's history search" "$(zi "bindkey '^R'")" "fzf-history-widget"
zhas starship && expect "starship prompt" "$(zi 'print $STARSHIP_SHELL')" "zsh"
zhas zoxide   && expect "zoxide's cd" "$(zi 'whence -w __zoxide_z')" "__zoxide_z: function"
zhas direnv   && expect "direnv hook" "$(zi 'print ${+functions[_direnv_hook]}')" "1"
expect "autosuggestions loaded" "$(zi 'print ${+functions[_zsh_autosuggest_start]}')" "1"
expect "syntax highlighting loaded" "$(zi 'print ${+functions[_zsh_highlight]}')" "1"

# -- Per-OS file ------------------------------------------------------------------
if [ "$OS" = darwin ]; then
    expect_has "darwin.zsh: Homebrew set up" "$(zi 'print $HOMEBREW_PREFIX')" "/"
    expect_has "darwin.zsh: alias roast" "$(zi 'alias roast')" "bullet-console"
    # A Mac that pulled a new .zshrc but hasn't re-stowed has no ~/.config/zsh.
    # .zshrc must find darwin.zsh through its own real location anyway.
    tmp="$(mktemp -d)"
    ln -s "$DOTFILES_DIR/zsh/.zshrc" "$tmp/.zshrc"
    expect_has "OS file found without ~/.config/zsh" \
        "$(ZDOTDIR="$tmp" HOME="$tmp" SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true \
            "$ZSH_BIN" -i -c 'alias roast' 2>/dev/null)" "bullet-console"
    rm -rf "$tmp"
else
    if [ -z "${WSL_DISTRO_NAME:-}" ] && ! grep -qi microsoft /proc/version 2>/dev/null; then
        expect "no WSL drive shortcuts outside WSL" "$(zi 'alias cdrive')" ""
    fi
    # `d` also tests the order: oh-my-zsh defines its own `d` (dirs -v).
    expect "WSL drive shortcut d" "$(WSL_DISTRO_NAME=Test zi 'alias d')" "d='cd /mnt/d'"
    # Debian names them batcat and fdfind; the installer links the usual names.
    for pair in bat:batcat fd:fdfind; do
        name="${pair%%:*}"
        real="${pair##*:}"
        if zhas "$name" || zhas "$real"; then
            expect_has "$name resolves" "$(zi "whence -p $name")" "/"
        fi
    done
fi

# -- zsh-linux/.zprofile, from the repo (runs on any OS) ---------------------------
# A login zsh that reads only that file: ZDOTDIR points at the package, and
# GLOBAL_RCS off skips /etc/zprofile. PATH is a scratch dir holding fake
# Hyprlands, then the system's, which /etc/profile.d scripts need.
bin="$(mktemp -d)"
SYS_PATH=/usr/bin:/bin
zl() {  # zl [VAR=value ...] -- prints what the login shell printed
    env -i HOME="$HOME" ZDOTDIR="$DOTFILES_DIR/zsh-linux" PATH="$bin:$SYS_PATH" "$@" \
        "$ZSH_BIN" +o GLOBAL_RCS -l -c 'echo still-here' 2>&1
}
# A real Hyprland on the system PATH (Arch) would answer before our fakes run
# out, so the fallback and no-Hyprland checks only run where there is none.
sys_hypr=false
for d in /usr/bin /bin; do
    { [ -x "$d/Hyprland" ] || [ -x "$d/start-hyprland" ]; } && sys_hypr=true
done
if [ -f "$DOTFILES_DIR/zsh-linux/.zprofile" ]; then
    printf '#!/bin/sh\necho start-hyprland-ran\n' > "$bin/start-hyprland"
    printf '#!/bin/sh\necho Hyprland-ran\n' > "$bin/Hyprland"
    chmod +x "$bin/start-hyprland" "$bin/Hyprland"
    expect ".zprofile: TTY1 starts Hyprland via start-hyprland" "$(zl SSH_AUTH_SOCK=x XDG_VTNR=1)" "start-hyprland-ran"
    expect ".zprofile: not on TTY2" "$(zl SSH_AUTH_SOCK=x XDG_VTNR=2)" "still-here"
    expect ".zprofile: not under a display" "$(zl SSH_AUTH_SOCK=x XDG_VTNR=1 DISPLAY=:0)" "still-here"
    rm "$bin/start-hyprland"
    if [ "$sys_hypr" = false ]; then
        expect ".zprofile: falls back to Hyprland" "$(zl SSH_AUTH_SOCK=x XDG_VTNR=1)" "Hyprland-ran"
        rm "$bin/Hyprland"
        # The Pi and WSL: no Hyprland. exec of a missing command would end the login.
        expect ".zprofile: TTY1 without Hyprland keeps the shell" "$(zl SSH_AUTH_SOCK=x XDG_VTNR=1)" "still-here"
    else
        echo "skip .zprofile: fallback and no-Hyprland checks (a real Hyprland is installed here)"
        rm "$bin/Hyprland"
    fi
    expect ".zprofile: keeps an existing agent" \
        "$(env -i HOME="$HOME" ZDOTDIR="$DOTFILES_DIR/zsh-linux" PATH="$bin:$SYS_PATH" SSH_AUTH_SOCK=preset \
            "$ZSH_BIN" +o GLOBAL_RCS -l -c 'echo $SSH_AUTH_SOCK' 2>&1)" "preset"
    sock="$(env -i HOME="$HOME" ZDOTDIR="$DOTFILES_DIR/zsh-linux" PATH="$bin:$SYS_PATH" \
        "$ZSH_BIN" +o GLOBAL_RCS -l -c 'echo $SSH_AUTH_SOCK; kill $SSH_AGENT_PID' 2>&1)"
    expect_has ".zprofile: starts an ssh-agent when there is none" "$sock" "/"
else
    bad "zsh-linux/.zprofile is missing"
fi
rm -rf "$bin"

echo
if [ "$FAILS" -gt 0 ]; then
    echo -e "${RED}$FAILS check(s) failed${NC}"
    exit 1
fi
echo -e "${GREEN}All zsh checks passed${NC}"
