# zsh on Linux Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Arch, the Pi and WSL run zsh from the same `zsh/.zshrc` as the Mac, so a shell idea is written once; the three Linux bash configs are retired.

**Architecture:** One shared `zsh/.zshrc` loads a small per-OS file (`zsh/.config/zsh/darwin.zsh` or `linux.zsh`) through its own real path, then an untracked `~/.zshrc.local`. A new Linux-only stow package `zsh-linux` holds `.zprofile` (ssh-agent, Hyprland on TTY1). A shared `scripts/setup-zsh-linux.sh` does the Linux installers' zsh steps; `scripts/verify.sh` checks the result. Two test scripts make it checkable from the Mac: `scripts/test-zsh.sh` (what an interactive zsh gets, on any machine) and `scripts/test-in-docker.sh` (a Linux installer end to end in a container).

**Tech Stack:** zsh 5.9, oh-my-zsh, GNU Stow, bash installers, Docker (ubuntu:24.04, debian:12, archlinux).

**Spec:** `doc/specs/2026-10-06-zsh-on-linux-design.md`

## Global Constraints

- zsh replaces bash on Arch and Debian (the Pi, WSL). Windows is untouched.
- Retire exactly: `bash/.bashrc-arch`, `.bashrc-wsl`, `.bashrc-raspbian`, `.bash_profile-arch`, `.bash_profile-wsl`, `.bash_profile-raspbian`. Keep `.bashrc-darwin`, `.bash_profile-darwin`, `.bashrc-windows`, `.minttyrc`, `bash/.bashrc`.
- `ls` is never eza. `ll`, `lt`, `la` are eza, without the old `-I "CLAUDE.md|.claude*"`. `fcpp`, `ftodo`, `fmd`, `ffunc` exist everywhere.
- oh-my-zsh stays, `plugins=(git)`.
- Plugins load last: zsh-autosuggestions, then zsh-syntax-highlighting; `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#616E88'`.
- `zsh-linux` is stowed on Arch and Debian only. Never touch the Mac's `~/.zprofile`.
- Login shell change: `sudo chsh -s "$(command -v zsh)" "$(id -un)"`. A failure is a `FAILURES` entry, never a stop.
- Repo rules (`CLAUDE.md`):
  - `scripts/lint.sh` passes. It shellchecks at `--severity=style` and only sees tracked files, so `git add` new scripts before linting.
  - New scripts are executable.
  - `doc/tools.md` changes in the same commit as any installer package change.
  - A `CHANGELOG.md` entry with "On other machines" ships with the change.
- Git:
  - Commit to `master` and **push only in Task 7**. `master` is what other machines sync from, so it must never be pushed half-switched.
  - Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  - Never `--no-verify`.
- Script style, as in `scripts/seed-btop-config.sh`:
  - a `#!/usr/bin/env bash` shebang;
  - a header comment giving purpose and usage;
  - `info` and `warn` helpers with the repo's colours.

## Review Focus

1. **The Mac after the split.** It's the daily machine. PATH entries, functions, plugins and prompt must be identical to the baseline; only the listed alias changes may differ. Task 2 checks this with a baseline diff.
2. **A machine that pulls before re-stowing.** `~/.zshrc` is a link, so it changes on pull while `~/.config/zsh/` isn't linked yet. The OS file must still load. Task 1 tests this with an `HOME` that has no `~/.config/zsh`.
3. **An existing Linux machine upgrading.** The pull leaves `~/.bashrc` and `~/.bash_profile` dangling. The installer must retire them, restore `/etc/skel`, and set zsh. Task 5 tests this with `--upgrade-from origin/master`.
4. **A console login on TTY1 without Hyprland** (the Pi, WSL). `.zprofile` must not exec a missing binary, which would end the login and lock the console. Task 3 tests this with a `PATH` that has no Hyprland.
5. **Old fzf without `--zsh`** (Debian 12 has 0.38, Ubuntu 24.04 has 0.44). There must be no startup error, and `Ctrl+R` must still be fzf's. Task 5 tests this with the debian:12 and ubuntu:24.04 runs, with `/usr/share/doc` kept in the image.

---

### Task 1: Mac baseline and the interactive-zsh checks

**Files:**
- Create: `scripts/test-zsh.sh`

**Interfaces:**
- Produces: `scripts/test-zsh.sh`, no arguments, exit 0 when every check passes. It checks the function names `t`, `tp`, `y`, the aliases `ll lt la fcpp ftodo fmd ffunc`, `roast` (macOS), WSL's `d`/`cdrive`, and Debian's `bat`/`fd`. Task 3 appends a `.zprofile` section; Task 4's container driver runs it.

- [ ] **Step 1: Record the Mac baseline before touching `.zshrc`**

```bash
B=/private/tmp/zsh-baseline; mkdir -p $B
SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true zsh -i -c 'print -l $path' > $B/path.before
SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true zsh -i -c 'alias' | sort > $B/alias.before
SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true zsh -i -c 'print -l ${(k)functions}' | sort > $B/func.before
zsh -c 'zmodload zsh/datetime; for i in 1 2 3 4 5; do s=$EPOCHREALTIME; SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true zsh -i -c exit >/dev/null 2>&1; printf "%.3f\n" $((EPOCHREALTIME - s)); done' > $B/time.before
wc -l $B/*.before; cat $B/time.before
```

Expected: four non-empty files, and five startup times.

- [ ] **Step 2: Write `scripts/test-zsh.sh`**

```bash
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

echo
if [ "$FAILS" -gt 0 ]; then
    echo -e "${RED}$FAILS check(s) failed${NC}"
    exit 1
fi
echo -e "${GREEN}All zsh checks passed${NC}"
```

- [ ] **Step 3: Make it executable, lint it, run it on the Mac against the current `.zshrc`**

```bash
chmod +x scripts/test-zsh.sh && git add scripts/test-zsh.sh
scripts/lint.sh 2>&1 | grep -E 'shellcheck|All checks|FAIL'
scripts/test-zsh.sh
```

Expected:
- lint is clean.
- `test-zsh.sh` exits 1. The FAILs are exactly:
  - `alias fcpp`, `alias ftodo`, `alias fmd`, `alias ffunc` (they don't exist yet);
  - `alias ll uses eza` and `alias la uses eza` (oh-my-zsh's `ls -lh` / `ls -lAh`);
  - `alias lt uses eza`.
- Everything else is `ok`, including "OS file found without ~/.config/zsh": today's `.zshrc` defines `roast` itself.

- [ ] **Step 4: Commit**

```bash
git commit -q -m "scripts/test-zsh.sh: check what an interactive zsh gets on this machine

Real zsh -i shells: functions, aliases, fzf/starship/zoxide/direnv, both
plugins, and the per-OS file. Fails on the Mac until .zshrc is split (the new
shared aliases).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Split `.zshrc` into a shared file and per-OS files

**Files:**
- Modify: `zsh/.zshrc` (whole file)
- Create: `zsh/.config/zsh/darwin.zsh`
- Create: `zsh/.config/zsh/linux.zsh`

**Interfaces:**
- Consumes: `scripts/test-zsh.sh` (Task 1).
- Produces:
  - `path_prepend DIR`, defined in `.zshrc` before the OS file loads and unset after PATH is built. OS files may call it.
  - `zsh_os_aliases`, an optional function an OS file defines. `.zshrc` calls it once, after oh-my-zsh, then unfunctions it.
  - `~/.zshrc.local`, sourced if present.

- [ ] **Step 1: Replace `zsh/.zshrc` with this**

```zsh
# zsh configuration for every Unix machine here: macOS, Arch, and Debian (the
# Pi, WSL). zsh is the login shell on all of them.
#
# What differs per OS lives in one small file, loaded first:
# .config/zsh/darwin.zsh or .config/zsh/linux.zsh, next to this file in the
# repo. Lines for one machine only go in ~/.zshrc.local, which is not tracked.
# Linux login setup (ssh-agent, Hyprland on TTY1) is zsh-linux/.zprofile.
#
# oh-my-zsh stays. No standard command is overridden: ls, cat, find and ps are
# left alone, and eza's listings are ll, lt and la.
#
# Every tool integration is guarded, because a fresh machine has none of them
# until its installer runs.

# -------------------------------------------------------------------- PATH --
# Keep $path (and therefore $PATH) free of duplicates. Without this, anything
# that re-sources this file -- a nested shell, `exec zsh` -- appends another
# copy of every entry. Set before the OS file, which adds entries too.
typeset -U path PATH

# Prepend a directory if it exists; most-specific last, so it ends up first.
# The OS file uses it too. Unset once PATH is built.
path_prepend() { [ -d "$1" ] && PATH="$1:$PATH"; }

# ----------------------------------------------------------------- OS file --
# First, because on macOS it sets up Homebrew, which supplies most of what the
# `command -v` checks below look for, and puts Homebrew's completions on fpath
# before oh-my-zsh runs compinit.
#
# Found through this file's real location (~/.zshrc is a link into the repo),
# not ~/.config/zsh, so a machine that pulled a new .zshrc but hasn't
# re-stowed still loads it.
#
# An OS file may define zsh_os_aliases. It is called after oh-my-zsh, whose own
# aliases (`d` among them) would otherwise replace the OS file's.
case "$OSTYPE" in
    darwin*) _zsh_os_file="${${(%):-%x}:A:h}/.config/zsh/darwin.zsh" ;;
    linux*)  _zsh_os_file="${${(%):-%x}:A:h}/.config/zsh/linux.zsh" ;;
    *)       _zsh_os_file="" ;;
esac
[ -n "$_zsh_os_file" ] && [ -f "$_zsh_os_file" ] && source "$_zsh_os_file"
unset _zsh_os_file

path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.local/bin"

unset -f path_prepend
export PATH

# ------------------------------------------------------------------ oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

# starship replaces the oh-my-zsh theme when present; leaving a theme set would
# have both drawing a prompt. Fall back to the previous theme if it is missing.
if command -v starship >/dev/null 2>&1; then
    ZSH_THEME=""
else
    ZSH_THEME="robbyrussell"
fi

plugins=(git)

[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# ------------------------------------------------------------------- prompt --
# Same prompt everywhere, from starship/.config/starship.toml
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# -------------------------------------------------------------------- tools --
# zoxide takes over `cd`
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"

if command -v fzf >/dev/null 2>&1; then
    # fzf 0.48+ ships its zsh integration behind --zsh. Older ones (Debian 12
    # has 0.38, Ubuntu 24.04 0.44) don't; Debian packages the same scripts as
    # examples instead.
    if _fzf_zsh="$(fzf --zsh 2>/dev/null)"; then
        eval "$_fzf_zsh"
    else
        for _f in /usr/share/doc/fzf/examples/key-bindings.zsh \
                  /usr/share/doc/fzf/examples/completion.zsh; do
            [ -f "$_f" ] && source "$_f"
        done
        unset _f
    fi
    unset _fzf_zsh

    # Nord palette
    export FZF_DEFAULT_OPTS="--color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#A3BE8C \
--color=fg:#D8DEE9,header:#A3BE8C,info:#EBCB8B,pointer:#88C0D0 \
--color=marker:#88C0D0,fg+:#ECEFF4,prompt:#88C0D0,hl+:#A3BE8C \
--color=border:#4C566A"
fi

# ------------------------------------------------------------- line editing --
# macOS-style editing keys, matching the terminal configs. Ghostty and
# Alacritty send these sequences for the shortcuts in the right-hand column;
# on a terminal that doesn't send them, they never trigger. Bound after
# oh-my-zsh and fzf, which set their own bindings and would otherwise win.
#
# Home/End arrive in several forms: \e[H / \e[F straight from the terminal,
# \eOH / \eOF in application-cursor mode, and \e[1~ / \e[4~ inside tmux,
# which re-encodes keys for its own TERM (screen-256color). Bind them all.
# Cmd-Left/Right send Home/End rather than Ctrl-A/E so they still work inside
# tmux, whose prefix is Ctrl-A.
bindkey '^[[H'  beginning-of-line    # Cmd-Left
bindkey '^[OH'  beginning-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[F'  end-of-line          # Cmd-Right
bindkey '^[OF'  end-of-line
bindkey '^[[4~' end-of-line
bindkey '^[b'   backward-word        # Option-Left
bindkey '^[f'   forward-word         # Option-Right
bindkey '^[^?'  backward-kill-word   # Option-Backspace
bindkey '^U'    backward-kill-line   # Cmd-Backspace: to line start, as in macOS
                                     # (zsh's default ^U clears the whole line)

# direnv: loads a folder's .envrc on cd and unloads it on leaving (env vars, a
# Python venv via `use venv`, see direnv/.config/direnv/direnvrc). An .envrc
# runs only after `direnv allow`, and again after each edit.
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# ---------------------------------------------------------------- ssh-agent --
# On Linux, zsh-linux/.zprofile has usually started one already, at login.
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null
fi
[ -f "$HOME/.ssh/id_ed25519" ] && ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null

# ------------------------------------------------------------------ aliases --
# Only additive ones: ls, cat, find and ps are deliberately left alone.
alias grep='grep --color=auto'

# eza listings. These replace oh-my-zsh's ll and la (plain ls -lh, ls -lAh).
if command -v eza >/dev/null 2>&1; then
    alias ll='eza -la --icons --git'
    alias lt='eza -T --icons --git-ignore'
    alias la='eza -a --icons'
fi

# fzf shortcuts: pick a file, then view or edit it.
alias fcpp='fd -e cpp -e hpp | fzf | xargs bat'                # C++ files, in bat
alias ftodo='rg -l "TODO" | fzf | xargs -o nvim'               # files with a TODO, in nvim
alias fmd='fd -e md | fzf'                                     # Markdown files
alias ffunc='rg "^function" | fzf | cut -d: -f1 | xargs bat'   # function definitions, in bat

# The OS file's aliases, now that oh-my-zsh's are in place.
if (( $+functions[zsh_os_aliases] )); then
    zsh_os_aliases
    unfunction zsh_os_aliases
fi

# ------------------------------------------------------------- files, images --
# y -- yazi, the terminal file manager (yazi/.config/yazi). Unlike plain
# `yazi`, quitting with q leaves this shell in the directory you browsed to.
# The wrapper from yazi's docs; `builtin cd` because zoxide wraps cd.
y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# chafa -- images in the terminal. In Ghostty it draws the real image (kitty
# graphics protocol), in foot as Sixel; elsewhere it falls back to coloured
# blocks.
alias chafa-ascii='chafa --format symbols --symbols ascii --colors none -s 60x20'
alias chafa-block='chafa --format symbols --symbols block -s 60x20'
# fimg -- fuzzy-find images below here, previewing each as you move
alias fimg='fd -e png -e jpg -e jpeg -e gif -e webp -e bmp -e heic | fzf --preview "chafa -s \${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES} {}"'

# ---------------------------------------------------------------------- tmux --
# t        -- tmux session named after the current directory, started in it
# t name   -- attach to session "name", creating it if it doesn't exist
# One terminal window with a session per project, instead of a terminal window
# per project spread across workspaces. Sessions outlive the window: close it,
# open a new one, `t` again.
#
# Inside tmux it switches the current client rather than nesting tmux in
# tmux. tmux forbids "." and ":" in session names, so they become "_"
# (dotfiles.git -> dotfiles_git).
t() {
    command -v tmux >/dev/null 2>&1 || { echo "t: tmux is not installed" >&2; return 1; }
    local name="${1:-${PWD:t}}"
    name="${name//[.:]/_}"
    if [ -n "$TMUX" ]; then
        tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$PWD"
        tmux switch-client -t "=$name"
    else
        tmux new-session -A -s "$name" -c "$PWD"
    fi
}
# Tab-complete existing session names.
_t() { compadd -- ${(f)"$(tmux list-sessions -F '#S' 2>/dev/null)"} }
(( $+functions[compdef] )) && compdef _t t

# tp -- project picker: fuzzy-find a folder under ~/Development (or the
# space-separated dirs in $TP_ROOTS) and open its tmux session via `t`, so
# the session gets the same name `t` would give it there. Also bound to
# prefix f in tmux, which runs this in a popup (tmux/.tmux.conf).
tp() {
    command -v fzf >/dev/null 2>&1 || { echo "tp: fzf is not installed" >&2; return 1; }
    local root dir
    dir="$(
        for root in ${=TP_ROOTS:-$HOME/Development}; do
            find "$root" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null
        done | sed "s|^$HOME/|~/|" | sort |
        fzf --reverse --prompt='project> ' --height=100% \
            --preview 'eza -1 --group-directories-first --icons=always "${HOME}/$(echo {} | cut -c3-)" 2>/dev/null || ls "${HOME}/$(echo {} | cut -c3-)"'
    )" || return 0
    ( builtin cd -- "${dir/#\~/$HOME}" && t )
}

# ------------------------------------------------------------- this machine --
# Untracked lines for one machine only: a work proxy, an SDK path. Before the
# plugins, so syntax highlighting sees anything defined here.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# ------------------------------------------------------------ zsh plugins --
# Loaded only if installed. Homebrew, pacman and apt each put them somewhere
# else: $HOMEBREW_PREFIX/share, /usr/share/zsh/plugins, /usr/share.
#   autosuggestions: the rest of a matching past command appears in grey;
#                    Right arrow or Cmd-Right (End) accepts it.
#   syntax-highlighting: commands turn green if they exist, red if not.
# syntax-highlighting must be sourced LAST, after every widget and bindkey,
# or it misses them -- keep this block at the end of the file.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#616E88'   # Nord's comment grey
for _p in zsh-autosuggestions zsh-syntax-highlighting; do
    for _d in ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share} /usr/share/zsh/plugins /usr/share; do
        if [ -f "$_d/$_p/$_p.zsh" ]; then
            source "$_d/$_p/$_p.zsh"
            break
        fi
    done
done
unset _p _d
```

- [ ] **Step 2: Create `zsh/.config/zsh/darwin.zsh`**

```zsh
# macOS part of zsh/.zshrc, which loads it before everything else.
# path_prepend comes from .zshrc.

# Homebrew. Must come before anything that checks `command -v`, since Homebrew
# supplies most of those binaries. Also sets HOMEBREW_PREFIX, where .zshrc
# finds the zsh plugins.
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

path_prepend "/usr/local/share/dotnet"
path_prepend "$HOME/.dotnet/tools"
path_prepend "/Library/Frameworks/Mono.framework/Versions/Current/Commands"
path_prepend "/opt/homebrew/opt/llvm/bin"

# Called by .zshrc after oh-my-zsh.
zsh_os_aliases() {
    # The roast console. --usb is baked in because that is the only mode worth
    # a shortcut; --demo and --replay are typed deliberately.
    #
    # DO NOT wrap this in caffeinate. The console forks its own
    # `caffeinate -dimsu -w <its pid>` on --usb, so the Mac stays awake for
    # exactly as long as the roast runs and the assertion dies with it -- even
    # on a crash or a kill -9, because -w is watching the pid. An outer
    # caffeinate would outlive a console that exited early and leave the
    # machine awake for nothing.
    #
    # Two things caffeinate cannot do, worth knowing before a twelve-minute
    # roast: -s (prevent system sleep) is valid only on AC power, and NOTHING
    # here stops a MacBook sleeping when the lid is closed. Plugged in, lid
    # open.
    alias roast='"$HOME/Development/bullet-ble.git/build/bullet-console" --usb'
}
```

- [ ] **Step 3: Create `zsh/.config/zsh/linux.zsh`**

```zsh
# Linux part of zsh/.zshrc (Arch, Debian, the Pi, WSL), which loads it before
# everything else. Login-time setup is in zsh-linux/.zprofile.

# System info when a terminal opens (fastfetch: Arch installs it, Debian
# doesn't). Not inside tmux, where it would flash in the prefix-f project
# popup, and not when output isn't a terminal.
if [ -z "$TMUX" ] && [ -t 1 ] && command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# Called by .zshrc after oh-my-zsh: its `d` (dirs -v) would replace ours.
zsh_os_aliases() {
    # WSL: shortcuts to the Windows drives. WSL sets WSL_DISTRO_NAME; the
    # kernel string is the fallback check.
    if [ -n "$WSL_DISTRO_NAME" ] || grep -qi microsoft /proc/version 2>/dev/null; then
        alias c='cd /mnt/c'
        alias d='cd /mnt/d'
        alias cdrive='cd /mnt/c'
        alias ddrive='cd /mnt/d'
        alias dev='cd /mnt/d/dev'
        alias downloads='cd /mnt/c/Users/$USER/Downloads'
        alias docs='cd /mnt/c/Users/$USER/Documents'
    fi
}
```

- [ ] **Step 4: Run the checks**

Run: `scripts/test-zsh.sh`
Expected: `All zsh checks passed`, exit 0.

If a new terminal could break, `git checkout zsh/.zshrc` restores the old file at once: `~/.zshrc` is a link to it.

- [ ] **Step 5: Compare with the baseline**

```bash
B=/private/tmp/zsh-baseline
SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true zsh -i -c 'print -l $path' > $B/path.after
SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true zsh -i -c 'alias' | sort > $B/alias.after
SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true zsh -i -c 'print -l ${(k)functions}' | sort > $B/func.after
zsh -c 'zmodload zsh/datetime; for i in 1 2 3 4 5; do s=$EPOCHREALTIME; SSH_AUTH_SOCK=/dev/null DISABLE_AUTO_UPDATE=true zsh -i -c exit >/dev/null 2>&1; printf "%.3f\n" $((EPOCHREALTIME - s)); done' > $B/time.after
diff $B/path.before $B/path.after && echo "PATH identical"
diff $B/func.before $B/func.after && echo "functions identical"
diff $B/alias.before $B/alias.after
paste $B/time.before $B/time.after
```

Expected:
- `PATH identical` and `functions identical`.
- The alias diff shows only:
  - changed: `la` and `ll` (from `ls -lAh`/`ls -lh` to eza);
  - added: `lt`, `fcpp`, `ftodo`, `fmd`, `ffunc`.
- The after times are no slower than before; they may be faster, since `brew --prefix` no longer runs at startup.

Anything else in a diff is a regression: fix it before continuing.

- [ ] **Step 6: Re-stow on the Mac and verify**

```bash
stow -R -t ~ zsh && ls -l ~/.config/zsh && scripts/verify.sh 2>&1 | grep -E 'zsh|FAIL|All checks'
```

Expected:
- `~/.config/zsh` links to `…/dotfiles/zsh/.config/zsh`;
- verify shows `PASS zsh: linked` and `All checks passed`. Its "repo has uncommitted changes" warning is expected until the commit.

- [ ] **Step 7: Commit**

```bash
git add zsh/.zshrc zsh/.config/zsh/darwin.zsh zsh/.config/zsh/linux.zsh
git commit -q -m "zsh: one shared .zshrc with a small file per OS

.zshrc loads .config/zsh/darwin.zsh or linux.zsh first, through its own real
path, so a pull works before a re-stow. OS aliases are set in zsh_os_aliases,
called after oh-my-zsh (whose d would win otherwise). Shared now: ll/lt/la
(eza) and fcpp/ftodo/fmd/ffunc; ls stays ls. fzf falls back to Debian's key
bindings when it predates --zsh. Plugins are found in Homebrew's, Arch's or
Debian's location. ~/.zshrc.local for one machine's lines. On the Mac, PATH
and functions are unchanged against a recorded baseline.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: `zsh-linux/.zprofile` (ssh-agent, Hyprland on TTY1)

**Files:**
- Create: `zsh-linux/.zprofile`
- Modify: `scripts/test-zsh.sh` (append a `.zprofile` section before the final summary)

**Interfaces:**
- Consumes: `scripts/test-zsh.sh` helpers `expect`, `ok`, `bad`, `ZSH_BIN`, `DOTFILES_DIR` (Task 1).
- Produces: the `zsh-linux` stow package. Task 5 adds it to `PACKAGES_ARCH` and `PACKAGES_DEBIAN`.

- [ ] **Step 1: Add the `.zprofile` checks to `scripts/test-zsh.sh`, just above the final `echo` / summary block**

```bash
# -- zsh-linux/.zprofile, from the repo (runs on any OS) ---------------------------
# A login zsh that reads only that file: ZDOTDIR points at the package, and
# GLOBAL_RCS off skips /etc/zprofile. PATH is a scratch dir, which decides
# whether a Hyprland "exists".
bin="$(mktemp -d)"
zl() {  # zl [VAR=value ...] -- prints what the login shell printed
    env -i HOME="$HOME" ZDOTDIR="$DOTFILES_DIR/zsh-linux" PATH="$bin" "$@" \
        "$ZSH_BIN" +o GLOBAL_RCS -l -c 'echo still-here' 2>&1
}
if [ -f "$DOTFILES_DIR/zsh-linux/.zprofile" ]; then
    printf '#!/bin/sh\necho start-hyprland-ran\n' > "$bin/start-hyprland"
    printf '#!/bin/sh\necho Hyprland-ran\n' > "$bin/Hyprland"
    chmod +x "$bin/start-hyprland" "$bin/Hyprland"
    expect ".zprofile: TTY1 starts Hyprland via start-hyprland" "$(zl SSH_AUTH_SOCK=x XDG_VTNR=1)" "start-hyprland-ran"
    expect ".zprofile: not on TTY2" "$(zl SSH_AUTH_SOCK=x XDG_VTNR=2)" "still-here"
    expect ".zprofile: not under a display" "$(zl SSH_AUTH_SOCK=x XDG_VTNR=1 DISPLAY=:0)" "still-here"
    rm "$bin/start-hyprland"
    expect ".zprofile: falls back to Hyprland" "$(zl SSH_AUTH_SOCK=x XDG_VTNR=1)" "Hyprland-ran"
    rm "$bin/Hyprland"
    # The Pi and WSL: no Hyprland. exec of a missing command would end the login.
    expect ".zprofile: TTY1 without Hyprland keeps the shell" "$(zl SSH_AUTH_SOCK=x XDG_VTNR=1)" "still-here"
    expect ".zprofile: keeps an existing agent" \
        "$(env -i HOME="$HOME" ZDOTDIR="$DOTFILES_DIR/zsh-linux" PATH="$bin" SSH_AUTH_SOCK=preset \
            "$ZSH_BIN" +o GLOBAL_RCS -l -c 'echo $SSH_AUTH_SOCK' 2>&1)" "preset"
    ln -s "$(command -v ssh-agent)" "$bin/ssh-agent"
    sock="$(env -i HOME="$HOME" ZDOTDIR="$DOTFILES_DIR/zsh-linux" PATH="$bin" \
        "$ZSH_BIN" +o GLOBAL_RCS -l -c 'echo $SSH_AUTH_SOCK; kill $SSH_AGENT_PID' 2>&1)"
    expect_has ".zprofile: starts an ssh-agent when there is none" "$sock" "/"
else
    bad "zsh-linux/.zprofile is missing"
fi
rm -rf "$bin"
```

- [ ] **Step 2: Run it to see it fail**

Run: `scripts/test-zsh.sh`
Expected: exit 1, with exactly one FAIL: `zsh-linux/.zprofile is missing`.

- [ ] **Step 3: Create `zsh-linux/.zprofile`**

```zsh
# zsh login shells on Linux: the zsh-linux package, stowed on Arch and Debian
# only. The Mac keeps its own ~/.zprofile, which Homebrew's installer asks for.
#
# zsh reads this before ~/.zshrc. On Arch it is what starts Hyprland.

# One ssh-agent for the whole login, started before Hyprland so Hyprland and
# every terminal it opens inherit it; otherwise each terminal's .zshrc would
# start its own. ssh-add stays in .zshrc, so a key's passphrase is asked in
# the first terminal.
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null
fi

# Start Hyprland on TTY1. start-hyprland (Hyprland 0.53+) is the supported
# launcher: it restarts Hyprland in safe mode after a crash. Falls back to
# Hyprland for older versions. A machine with neither (the Pi, WSL) just gets
# its shell: exec of a missing command would end the login instead.
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    if command -v start-hyprland >/dev/null 2>&1; then
        exec start-hyprland
    elif command -v Hyprland >/dev/null 2>&1; then
        exec Hyprland
    fi
fi
```

- [ ] **Step 4: Run the checks**

Run: `scripts/test-zsh.sh`
Expected: `All zsh checks passed`, including all seven `.zprofile:` lines.

- [ ] **Step 5: Lint and commit**

```bash
git add zsh-linux/.zprofile scripts/test-zsh.sh
scripts/lint.sh 2>&1 | grep -E 'shellcheck|litter|All checks|FAIL'
git commit -q -m "zsh-linux: .zprofile for Linux logins (ssh-agent, Hyprland on TTY1)

One ssh-agent per login, started before Hyprland so every terminal shares
it, then the TTY1 Hyprland start moved from .bash_profile-arch. Unlike that
file it no longer execs a Hyprland that isn't installed, which would end a
console login on the Pi. A separate package so the Mac keeps its own
~/.zprofile. test-zsh.sh checks it from the repo on any OS.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected: lint clean (`stow: no package would litter $HOME`).

---

### Task 4: The container driver, `scripts/test-in-docker.sh`

**Files:**
- Create: `scripts/test-in-docker.sh`

**Interfaces:**
- Consumes: `scripts/test-zsh.sh` (Tasks 1, 3), `scripts/verify.sh`, `install_arch.sh`, `install_debian.sh`.
- Produces: `scripts/test-in-docker.sh IMAGE [--upgrade-from REF]`, exit 0 when every check passes. `KEEP=1` keeps the container. Inside the container it creates user `tester` (passwordless sudo), and copies the repo to `/home/tester/dotfiles`. The full installer log is `~/install.log`. Task 6 appends verify.sh checks to it.

- [ ] **Step 1: Write `scripts/test-in-docker.sh`**

```bash
#!/usr/bin/env bash
#
# Run a Linux installer end to end in a throwaway Docker container, as a
# normal user with sudo, then check the result: scripts/test-zsh.sh and
# scripts/verify.sh as that user, plus what the zsh switch must leave behind.
# For trying Linux changes from the Mac. Needs Docker running.
#
# Usage: scripts/test-in-docker.sh IMAGE [--upgrade-from REF]
#   IMAGE  ubuntu:24.04, debian:12 (the Pi's base), or archlinux. archlinux
#          has no arm64 image, so it runs under emulation: slow, and its AUR
#          builds fail there (a known failure, unrelated to what is tested).
#   --upgrade-from REF
#          install at REF first, then return to the working tree and install
#          again -- what an existing machine does when it pulls.
#
# Copies the working tree, uncommitted changes included. Before installing it
# puts a real ~/.zshrc and ~/.zprofile in place, which the installer must back
# up. The container is removed at the end; KEEP=1 leaves it for a look.
#
# shellcheck disable=SC2016  # $ in single quotes is for the container's shell

set -uo pipefail

IMAGE="${1:-}"
[ -n "$IMAGE" ] || { echo "usage: scripts/test-in-docker.sh IMAGE [--upgrade-from REF]"; exit 2; }
UPGRADE_FROM=""
if [ "${2:-}" = --upgrade-from ]; then
    UPGRADE_FROM="${3:-}"
    [ -n "$UPGRADE_FROM" ] || { echo "--upgrade-from needs a git ref"; exit 2; }
fi
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
FAILS=0
ok()  { echo -e "${GREEN}ok${NC}   $1"; }
bad() { echo -e "${RED}FAIL${NC} $1"; FAILS=$((FAILS + 1)); }

docker info >/dev/null 2>&1 || { echo "Docker isn't running: open -a Docker, then retry"; exit 2; }

platform=()
case "$IMAGE" in
    archlinux*) platform=(--platform linux/amd64); INSTALLER=install_arch.sh ;;
    *)          INSTALLER=install_debian.sh ;;
esac

cid="$(docker run -d "${platform[@]}" "$IMAGE" sleep infinity)" || exit 2
cleanup() {
    if [ "${KEEP:-0}" = 1 ]; then echo "kept container $cid"; else docker rm -f "$cid" >/dev/null; fi
}
trap cleanup EXIT

as_root()   { docker exec "$cid" bash -c "$1"; }
as_tester() { docker exec -u tester -e USER=tester -e HOME=/home/tester -w /home/tester "$cid" bash -c "$1"; }

echo "== $IMAGE: a user with sudo"
if [ "$INSTALLER" = install_arch.sh ]; then
    as_root 'pacman -Syu --noconfirm --needed sudo git >/dev/null' || exit 2
else
    # Docker's Debian and Ubuntu images leave out /usr/share/doc, which is
    # where Debian's fzf keeps its zsh key bindings. Real machines have it.
    as_root 'rm -f /etc/dpkg/dpkg.cfg.d/excludes /etc/dpkg/dpkg.cfg.d/docker
             apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq sudo git ca-certificates curl >/dev/null' || exit 2
fi
as_root 'useradd -m -s /bin/bash tester && echo "tester ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tester' || exit 2
as_tester 'git config --global user.name "Test User" && git config --global user.email test@example.com
           echo "# pre-existing" > ~/.zshrc && echo "# pre-existing" > ~/.zprofile' || exit 2

echo "== copying the working tree"
docker cp "$DOTFILES_DIR/." "$cid:/home/tester/dotfiles" >/dev/null \
    && as_root 'chown -R tester:tester /home/tester/dotfiles' || exit 2

if [ -n "$UPGRADE_FROM" ]; then
    echo "== installing at $UPGRADE_FROM first, like a machine set up before"
    as_tester "cd ~/dotfiles
        stashed=false
        if [ -n \"\$(git status --porcelain)\" ]; then git stash push -u -q && stashed=true; fi
        git checkout -q --detach '$UPGRADE_FROM' || exit 1
        ./$INSTALLER > ~/install-old.log 2>&1 || echo \"     (that installer exited \$?; ~/install-old.log)\"
        git checkout -q -
        if \$stashed; then git stash pop -q; fi" || { bad "could not install at $UPGRADE_FROM"; exit 1; }
fi

echo "== $INSTALLER (full log: ~/install.log in the container)"
if as_tester "cd ~/dotfiles && ./$INSTALLER > ~/install.log 2>&1"; then
    ok "installer exited 0"
else
    as_tester 'sed -n "/Finished with/,/^\$/p" ~/install.log | sed "s/^/     /"'
    if [ "$INSTALLER" = install_arch.sh ]; then
        echo "     (on archlinux the AUR step fails under emulation; judged by the checks below)"
    else
        bad "installer exited non-zero (its problems are listed above)"
    fi
fi

echo "== checks"
if as_tester 'cd ~/dotfiles && scripts/test-zsh.sh'; then ok "scripts/test-zsh.sh"; else bad "scripts/test-zsh.sh (above)"; fi
if as_tester 'cd ~/dotfiles && scripts/verify.sh'; then ok "scripts/verify.sh"; else bad "scripts/verify.sh (above)"; fi

login="$(as_tester 'getent passwd tester | cut -d: -f7')"
if [ "${login##*/}" = zsh ]; then ok "login shell is $login"; else bad "login shell is $login, not zsh"; fi

if as_tester 'ls ~/.config-backup-*/.zshrc ~/.config-backup-*/.zprofile >/dev/null 2>&1'; then
    ok "the pre-existing ~/.zshrc and ~/.zprofile were backed up"
else
    bad "the pre-existing ~/.zshrc and ~/.zprofile were not backed up"
fi
if as_tester '[ "$(readlink -f ~/.zshrc)" = ~/dotfiles/zsh/.zshrc ] && [ "$(readlink -f ~/.zprofile)" = ~/dotfiles/zsh-linux/.zprofile ]'; then
    ok "~/.zshrc and ~/.zprofile link into the repo"
else
    bad "~/.zshrc or ~/.zprofile doesn't link into the repo: $(as_tester 'ls -l ~/.zshrc ~/.zprofile 2>&1')"
fi
for f in .bashrc .bash_profile; do
    if as_tester "[ -L ~/$f ] && readlink ~/$f | grep -q /bash/"; then
        bad "~/$f still links to the repo's bash files"
    else
        ok "~/$f doesn't link into the repo"
    fi
done
if [ -n "$UPGRADE_FROM" ]; then
    if as_tester 'cmp -s ~/.bashrc /etc/skel/.bashrc'; then
        ok "~/.bashrc is the distro default again"
    else
        bad "~/.bashrc is not /etc/skel/.bashrc: $(as_tester 'ls -l ~/.bashrc 2>&1')"
    fi
fi

echo "== zsh startup time, three runs (seconds)"
as_tester 'command -v zsh >/dev/null && zsh -c "zmodload zsh/datetime; for i in 1 2 3; do s=\$EPOCHREALTIME; SSH_AUTH_SOCK=/dev/null zsh -i -c exit >/dev/null 2>&1; printf \"     %.2f\n\" \$((EPOCHREALTIME - s)); done"'

echo
if [ "$FAILS" -gt 0 ]; then
    echo -e "${RED}$FAILS check(s) failed${NC} on $IMAGE${UPGRADE_FROM:+ (upgrade from $UPGRADE_FROM)}"
    exit 1
fi
echo -e "${GREEN}All checks passed${NC} on $IMAGE${UPGRADE_FROM:+ (upgrade from $UPGRADE_FROM)}"
```

- [ ] **Step 2: Make it executable and lint**

```bash
chmod +x scripts/test-in-docker.sh && git add scripts/test-in-docker.sh
scripts/lint.sh 2>&1 | grep -E 'shellcheck|exec bits|All checks|FAIL'
```

Expected: clean.

- [ ] **Step 3: Run it against today's installer to see it fail**

```bash
open -a Docker; until docker info >/dev/null 2>&1; do sleep 2; done
scripts/test-in-docker.sh ubuntu:24.04
```

Expected: exit 1. FAILs include:
- `scripts/test-zsh.sh` ("zsh is not installed");
- `login shell is /bin/bash`;
- "were not backed up";
- "doesn't link into the repo";
- `~/.bashrc still links to the repo's bash files`.

The installer itself exits 0.

- [ ] **Step 4: Commit**

```bash
git commit -q -m "scripts/test-in-docker.sh: a Linux installer end to end in a container

As a sudo user: optionally install at an older ref first (--upgrade-from),
then the working tree's installer, then test-zsh.sh, verify.sh, the login
shell, backups of a pre-existing ~/.zshrc/~/.zprofile, and no links left to
the bash files. Keeps /usr/share/doc in Debian images, where fzf's zsh
bindings live. Fails against today's installers, which still set up bash.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Switch the Linux installers to zsh; retire the bash files

**Files:**
- Create: `scripts/setup-zsh-linux.sh`
- Modify: `scripts/packages.sh:7,16-17`
- Modify: `install_debian.sh` (APT list, zoxide comment, backup list, bash link block, after the stow loop, next steps)
- Modify: `install_arch.sh` (package list, backup list, bash link block, stow comment, after the stow loop, next steps)
- Delete: `bash/.bashrc-arch`, `bash/.bashrc-wsl`, `bash/.bashrc-raspbian`, `bash/.bash_profile-arch`, `bash/.bash_profile-wsl`, `bash/.bash_profile-raspbian`
- Modify: `tmux/.tmux.conf:88-93` (comment), `doc/tools.md:20-22` (same-commit rule)

**Interfaces:**
- Consumes:
  - the `zsh` and `zsh-linux` packages (Tasks 2, 3);
  - `scripts/test-in-docker.sh` (Task 4).
- Produces: `scripts/setup-zsh-linux.sh`, no arguments, exit 1 if any step failed (after trying all). Its retired-bash-file patterns are duplicated in `verify.sh` (Task 6): `*/bash/.bashrc-{arch,wsl,raspbian}`, `*/bash/.bash_profile-{arch,wsl,raspbian}`.

- [ ] **Step 1: Write `scripts/setup-zsh-linux.sh`**

```bash
#!/usr/bin/env bash
#
# The zsh steps of the Linux installers (install_arch.sh, install_debian.sh),
# shared so both do them the same way. Run after zsh and zsh-linux are stowed:
#
#   1. Clone oh-my-zsh, which zsh/.zshrc loads (clone only, as on macOS).
#   2. Retire ~/.bashrc and ~/.bash_profile if they still link to the Linux
#      bash files this repo used to have, putting back the distro's defaults
#      from /etc/skel. scripts/verify.sh checks for the same links.
#   3. Debian: link ~/.local/bin/bat and fd to batcat and fdfind, Debian's
#      names. Aliases would not reach `xargs bat` or yazi's previews.
#   4. Make zsh the login shell. Through sudo, which the installer already
#      holds, so there is no second password prompt.
#
# Every step is skipped when already done. Exits 1 if a step failed, after
# trying the rest.
#
# Usage: scripts/setup-zsh-linux.sh

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

status=0
me="$(id -un)"

# 1. oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing oh-my-zsh (clone only; ~/.zshrc stays the repo's)..."
    if ! git clone -q --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"; then
        warn "oh-my-zsh clone failed; zsh works without it"
        status=1
    fi
fi

# 2. Links to the retired bash files. Same patterns as scripts/verify.sh.
for f in "$HOME/.bashrc" "$HOME/.bash_profile"; do
    [ -L "$f" ] || continue
    case "$(readlink "$f")" in
        */bash/.bashrc-arch | */bash/.bashrc-wsl | */bash/.bashrc-raspbian | \
        */bash/.bash_profile-arch | */bash/.bash_profile-wsl | */bash/.bash_profile-raspbian)
            rm "$f"
            skel="/etc/skel/${f##*/}"
            if [ -f "$skel" ]; then
                cp "$skel" "$f"
                info "Retired $f (it linked to a removed bash file); restored $skel"
            else
                info "Retired $f (it linked to a removed bash file)"
            fi
            ;;
    esac
done

# 3. Debian's names for bat and fd
for pair in bat:batcat fd:fdfind; do
    name="${pair%%:*}"
    real="${pair##*:}"
    if ! command -v "$name" >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/$name" ] \
        && real_path="$(command -v "$real")"; then
        mkdir -p "$HOME/.local/bin"
        ln -s "$real_path" "$HOME/.local/bin/$name"
        info "Linked ~/.local/bin/$name -> $real_path"
    fi
done

# 4. The login shell
zsh_path="$(command -v zsh || true)"
current="$(getent passwd "$me" | cut -d: -f7)"
if [ -z "$zsh_path" ]; then
    warn "zsh is not installed; the login shell stays $current"
    status=1
elif [ "${current##*/}" != zsh ]; then
    if sudo chsh -s "$zsh_path" "$me"; then
        info "Login shell is now zsh (was $current); log out and back in to use it"
    else
        warn "Could not change the login shell. Run: sudo chsh -s $zsh_path $me"
        status=1
    fi
fi

exit $status
```

Then: `chmod +x scripts/setup-zsh-linux.sh && git add scripts/setup-zsh-linux.sh`

- [ ] **Step 2: `scripts/packages.sh`.** Change the comment line and the two Linux lists to exactly:

```bash
#   bash      -- macOS only: install_darwin.sh links .bashrc-darwin -> ~/.bashrc (Linux runs zsh)
```
```bash
PACKAGES_ARCH=(hypr foot waybar rofi mako wlogout cava gtk mimeapps discord slack fastfetch alacritty nvim starship bat git clang gdb tmux yazi direnv zsh zsh-linux typescript claude)
PACKAGES_DEBIAN=(git clang gdb nvim starship bat tmux direnv zsh zsh-linux claude)
```

- [ ] **Step 3: `install_debian.sh`.** Five edits.

(a) In `APT_PACKAGES`, after `    direnv`, add:
```bash
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
```
(b) In the zoxide comment, replace `which only the stowed\n# .bashrc adds to PATH` with `which only the stowed\n# .zshrc adds to PATH`.

(c) In `CONFIGS_TO_BACKUP`, replace the two lines `    ~/.bashrc` and `    ~/.bash_profile` with `    ~/.zshrc` and `    ~/.zprofile`.

(d) Delete the whole block from `# Create platform-specific bash symlinks directly (not via stow)` through `ln -sf "$DOTFILES_DIR/bash/.bash_profile-${BASH_PROFILE_VARIANT}" "$HOME/.bash_profile"`: the `case $PLATFORM` block, the `info` line and both `ln -sf` lines, plus one blank line after them.

(e) Between the stow loop's closing `done` and `# btop's Nord theme.`, insert:
```bash
# zsh as the login shell, oh-my-zsh, and retiring the old bash links. Shared
# with install_arch.sh.
"$DOTFILES_DIR/scripts/setup-zsh-linux.sh" \
    || FAILURES+=("setup-zsh-linux.sh: a zsh step failed (see its warnings above)")

```
In "Next steps", replace `echo "  1. Restart your terminal or run: source ~/.bashrc"` with `echo "  1. Log out and back in: zsh is now your login shell"`.

- [ ] **Step 4: `install_arch.sh`.** Five edits.

(a) In the `# Terminal & shell` group, after `    bash-completion`, add:
```bash
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
```
(b) In `CONFIGS_TO_BACKUP`, replace `    ~/.bashrc` and `    ~/.bash_profile` with `    ~/.zshrc` and `    ~/.zprofile`.

(c) Delete these four lines and the blank line after them:
```bash
# Create platform-specific bash symlinks directly (not via stow)
info "Creating Arch-specific bash config symlinks..."
ln -sf "$DOTFILES_DIR/bash/.bashrc-arch" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/bash/.bash_profile-arch" "$HOME/.bash_profile"
```
(d) Replace the stow comment's last two lines
```bash
# packages (aerospace, sketchybar, autoraise, ghostty, zsh) and Windows ones
# (glazewm, zebar) that have no business in an Arch $HOME. bash is linked above.
```
with
```bash
# packages (aerospace, sketchybar, autoraise, ghostty) and Windows ones
# (glazewm, zebar) that have no business in an Arch $HOME.
```
(e) Between the stow loop's closing `done` and `# yazi plugins (git status column, Markdown preview) are declared in`, insert the same block as in Step 3(e). In "Next steps", replace `echo "  2. Hyprland will auto-start on TTY1"` with `echo "  2. Log in on TTY1: zsh is your login shell, and it starts Hyprland"`.

- [ ] **Step 5: Delete the Linux bash files, and update the tmux comment and `doc/tools.md`**

```bash
git rm -q bash/.bashrc-arch bash/.bashrc-wsl bash/.bashrc-raspbian \
          bash/.bash_profile-arch bash/.bash_profile-wsl bash/.bash_profile-raspbian
```

In `tmux/.tmux.conf`, replace the comment above `bind f display-popup` (the six lines starting `# prefix f: project picker`) with:
```
# prefix f: project picker in a popup -- fuzzy-find a folder in ~/Development
# and switch to its session (created if needed). Runs `tp` in your login
# shell ($SHELL): zsh on macOS and Linux, from zsh/.zshrc. Replaces tmux's
# default find-window on f; prefix w still finds windows.
```

In `doc/tools.md`, replace the three shell rows with:
```
| zsh + oh-my-zsh | Login shell; one shared `.zshrc` | ✓ | ✓ | ✓ | – |
| bash | Login shell (Git Bash) | – | – | – | ✓ |
| zsh-autosuggestions, zsh-syntax-highlighting | Grey history suggestions, green/red commands | ✓ | ✓ | ✓ | – |
```

- [ ] **Step 6: Lint, and check that nothing still names the deleted files**

```bash
scripts/lint.sh 2>&1 | grep -E 'shellcheck|exec bits|All checks|FAIL'
bash -n install_arch.sh && bash -n install_debian.sh && echo parsed
git grep -n -E 'bashrc-(arch|wsl|raspbian)|bash_profile-(arch|wsl|raspbian)' -- ':!CHANGELOG.md' ':!doc/specs' ':!doc/plans'
```

Expected: lint clean and `parsed`. The grep lists only lines Task 7 updates: `CLAUDE.md`, `README.md`, `doc/tmux.md`, `doc/applying-the-setup.md`, plus the patterns in `scripts/setup-zsh-linux.sh`. Anything else must be fixed here.

- [ ] **Step 7: Run the containers**

```bash
scripts/test-in-docker.sh ubuntu:24.04
scripts/test-in-docker.sh debian:12
scripts/test-in-docker.sh ubuntu:24.04 --upgrade-from origin/master
```

Expected: each ends with `All checks passed`.
- In every run, `test-zsh.sh` shows the `Ctrl+R is fzf's history search`, `WSL drive shortcut d` and `bat resolves` / `fd resolves` lines as ok.
- The upgrade run also shows `~/.bashrc is the distro default again`.

`debian:12` may hit installer failures unrelated to zsh, such as a package missing from bookworm. Don't fix those here: write each into the session log for the todo list. The run must still pass every zsh check.

- [ ] **Step 8: Commit**

```bash
git add -A scripts/packages.sh install_debian.sh install_arch.sh tmux/.tmux.conf doc/tools.md
git commit -q -m "Linux runs zsh: installers switch, Linux bash files retired

Both Linux installers install zsh and its two plugins, stow zsh and
zsh-linux, back up a real ~/.zshrc/~/.zprofile, and run the new
scripts/setup-zsh-linux.sh: oh-my-zsh, retiring ~/.bashrc and
~/.bash_profile links to the removed files (restoring /etc/skel), Debian's
bat/fd names, and sudo chsh to zsh. .bashrc-arch/-wsl/-raspbian and their
.bash_profiles are deleted. Passes test-in-docker.sh on ubuntu:24.04,
debian:12, and an upgrade from origin/master.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: `verify.sh` checks the shell on Linux

**Files:**
- Modify: `scripts/verify.sh` (a new section after the macOS fastfetch check, before `# -- Directories that must never be a symlink into the repo`)
- Modify: `scripts/test-in-docker.sh` (a negative-check block before the startup-time block)

**Interfaces:**
- Consumes: the retired-file patterns from `scripts/setup-zsh-linux.sh` (Task 5).
- Produces: these verify.sh messages, which the driver greps for:
  - `still links to a retired bash file`
  - `login shell is <path>, not zsh`

- [ ] **Step 1: Add the negative checks to `scripts/test-in-docker.sh`, just above `echo "== zsh startup time`**

```bash
echo "== verify.sh catches a half-done switch"
as_tester 'cp ~/.bashrc ~/.bashrc.keep && ln -sfn ~/dotfiles/bash/.bashrc-wsl ~/.bashrc'
out="$(as_tester 'cd ~/dotfiles && scripts/verify.sh' 2>&1)"; rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q 'still links to a retired bash file'; then
    ok "verify.sh fails on a ~/.bashrc left linked to a removed bash file"
else
    bad "verify.sh missed a ~/.bashrc linked to a removed bash file (exit $rc)"
fi
as_tester 'rm ~/.bashrc && mv ~/.bashrc.keep ~/.bashrc'
as_root 'chsh -s /bin/bash tester'
out="$(as_tester 'cd ~/dotfiles && scripts/verify.sh' 2>&1)"; rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q 'login shell is /bin/bash, not zsh'; then
    ok "verify.sh fails when the login shell isn't zsh"
else
    bad "verify.sh missed a bash login shell (exit $rc)"
fi
as_root 'chsh -s "$(command -v zsh)" tester'
```

- [ ] **Step 2: Run it to see the two new checks fail**

Run: `scripts/test-in-docker.sh ubuntu:24.04`
Expected: exit 1 with exactly two FAILs: `verify.sh missed a ~/.bashrc linked to a removed bash file` and `verify.sh missed a bash login shell`.

- [ ] **Step 3: Add the section to `scripts/verify.sh`, after the macOS fastfetch `fi`**

```bash
# -- Shell (Linux) --------------------------------------------------------------
# zsh replaced bash on Linux on 2026-10-06 (doc/specs/2026-10-06-zsh-on-linux-design.md).
checks_zsh=false
for p in "${PACKAGES[@]}"; do [ "$p" = zsh ] && checks_zsh=true; done
if [ "$OS" != darwin ] && [ "$checks_zsh" = true ]; then
    me="$(id -un)"
    shell="$(getent passwd "$me" | cut -d: -f7)"
    if [ "${shell##*/}" = zsh ]; then
        pass "login shell is zsh ($shell)"
    else
        fail "login shell is ${shell:-unknown}, not zsh -- run: sudo chsh -s \"\$(command -v zsh)\" $me, then log in again"
    fi
    # Same patterns as scripts/setup-zsh-linux.sh, which removes these links.
    for f in "$HOME/.bashrc" "$HOME/.bash_profile"; do
        [ -L "$f" ] || continue
        case "$(readlink "$f")" in
            */bash/.bashrc-arch | */bash/.bashrc-wsl | */bash/.bashrc-raspbian | \
            */bash/.bash_profile-arch | */bash/.bash_profile-wsl | */bash/.bash_profile-raspbian)
                fail "$f still links to a retired bash file -- re-run the installer (or scripts/setup-zsh-linux.sh)" ;;
        esac
    done
    if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        pass "oh-my-zsh installed"
    else
        warn "oh-my-zsh missing: zsh works, minus its completion setup (the installers clone it)"
    fi
    for p in zsh-autosuggestions zsh-syntax-highlighting; do
        if [ -f "/usr/share/zsh/plugins/$p/$p.zsh" ] || [ -f "/usr/share/$p/$p.zsh" ]; then
            pass "$p installed"
        else
            warn "$p missing (the installers install it)"
        fi
    done
fi
```

- [ ] **Step 4: Lint, then run the full matrix**

```bash
scripts/lint.sh 2>&1 | grep -E 'shellcheck|All checks|FAIL'
scripts/verify.sh 2>&1 | tail -3      # the Mac: section skipped, still passes
scripts/test-in-docker.sh ubuntu:24.04
scripts/test-in-docker.sh debian:12 --upgrade-from origin/master
scripts/test-in-docker.sh archlinux   # emulated: expect a long run
```

Expected:
- lint clean, and the Mac's verify passes.
- All three container runs end with `All checks passed`, including both `verify.sh fails …` lines.
- On archlinux the installer reports its known AUR failure, and every check still passes.

- [ ] **Step 5: Commit**

```bash
git add scripts/verify.sh scripts/test-in-docker.sh
git commit -q -m "verify.sh: on Linux, the login shell is zsh and no link to a retired bash file remains

FAIL for either; WARN for a missing oh-my-zsh or zsh plugin. test-in-docker.sh
now checks that verify.sh catches both. Passes on ubuntu:24.04, an upgrade
from origin/master on debian:12, and archlinux.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Docs, CHANGELOG, push; archinstall and the todo list

**Files:**
- Modify: `CLAUDE.md` (the `**macOS shell:**` block, `**Platform-specific bash configs:**` list, Key Packages `bash` bullet, the two `install_wsl.sh`/`install_raspbian.sh` lines)
- Modify: `README.md:45-46`, `README.md:265`
- Modify: `doc/applying-the-setup.md:176,196,201`
- Modify: `doc/tmux.md:4-6`
- Modify: `doc/tools.md` (the eza row)
- Modify: `CHANGELOG.md` (new top entry)
- Modify: `~/Development/archinstall/doc/arch-hyprland-guide.md:187`
- Modify: `~/Development/todo/TODO.md`, `log/2026-10.md`, `README.md`

**Interfaces:**
- Consumes: everything above.
- Produces: nothing used later.

- [ ] **Step 1: `CLAUDE.md`**

Replace the block from `**macOS shell:**` through `  aliases, which override standard commands.` with:
```markdown
**Shell (macOS and Linux):**
- **zsh**: `zsh/.zshrc` → `~/.zshrc`, the login shell on macOS, Arch and
  Debian/WSL/Raspbian. One shared file. OS specifics live in
  `zsh/.config/zsh/darwin.zsh` and `linux.zsh`, which `.zshrc` loads first
  through its own real path, so a pull works before a re-stow. OS aliases go in
  their `zsh_os_aliases`, called after oh-my-zsh. An untracked
  `~/.zshrc.local` holds one machine's lines. Keeps oh-my-zsh, swaps its theme
  for starship, and initialises zoxide, fzf and direnv; every integration is
  guarded by `command -v`. Overrides no standard command: `ls`, `cat`, `find`
  and `ps` are left alone, and eza is `ll`/`lt`/`la`.
- **zsh-linux**: `.zprofile` for Linux login shells: one ssh-agent per login,
  and Hyprland on TTY1 (only if installed). Not stowed on macOS, which keeps
  its own `~/.zprofile`. `scripts/setup-zsh-linux.sh`, run by both Linux
  installers, clones oh-my-zsh, retires old links to the removed Linux bash
  files, links Debian's `batcat`/`fdfind` as `bat`/`fd`, and makes zsh the
  login shell. Test from the Mac with `scripts/test-zsh.sh` and
  `scripts/test-in-docker.sh <image>`.
```

Replace the `**Platform-specific bash configs:**` list with:
```markdown
**bash configs (macOS and Windows only; Linux runs zsh since 2026-10-06):**
- **bash/.bashrc-darwin** - macOS with Homebrew paths, read only if you start bash
- **bash/.bashrc-windows** - Windows Git Bash with Scoop tools
- Install scripts create symlinks to the appropriate variant
```

Replace the Key Packages bullet `- **bash**: Platform-specific shell configuration` and its five sub-bullets with:
```markdown
- **bash**: macOS (`.bashrc-darwin`, only if you start bash) and Windows Git
  Bash (`.bashrc-windows`, Scoop tools, bash-completion from Git for Windows).
  Linux uses zsh; see Shell above.
```

Replace `(auto-detects WSL, uses \`.bashrc-wsl\`)` with `(auto-detects WSL)`, and `(auto-detects Raspberry Pi, uses \`.bashrc-raspbian\`)` with `(auto-detects Raspberry Pi)`.

- [ ] **Step 2: `README.md`, `doc/applying-the-setup.md`, `doc/tmux.md`, `doc/tools.md`**

- `README.md:46`: `(\`bash/.bash_profile-arch\`); there is no display manager.` → `(\`zsh-linux/.zprofile\`); there is no display manager.`
- `README.md:265`: replace the `zsh` row with these two rows:
  ```
  | `zsh`   | Login shell config, macOS and Linux - oh-my-zsh + starship, one shared .zshrc plus a small file per OS |
  | `zsh-linux` | Linux login file (.zprofile) - one ssh-agent per login, Hyprland on TTY1 |
  ```
- `doc/applying-the-setup.md:176`: in the Linux column, `ls -la ~/.bashrc ~/.gitconfig` → `ls -la ~/.zshrc ~/.zprofile ~/.gitconfig`.
- `doc/applying-the-setup.md:196`: replace the `zsh` row with these two rows:
  ```
  | `zsh` | mac, Linux | ⚠️ ask | Replaces `~/.zshrc`. Put work-specific lines (proxy, SDK paths, corporate tooling) in `~/.zshrc.local`, which it loads. On Linux the installer also makes zsh the login shell. |
  | `zsh-linux` | Linux | ⚠️ ask | Replaces `~/.zprofile`: one ssh-agent per login, Hyprland on TTY1 if installed. |
  ```
- `doc/applying-the-setup.md:201`: `| \`bash\` | per-OS variants | …` → `| \`bash\` | mac, Windows | ⚠️ ask | \`bash/.bashrc-darwin\` / \`.bashrc-windows\` are linked to \`~/.bashrc\` by the installers; check for existing content first. Linux uses zsh. |`
- `doc/tmux.md:4-6`: the sentence `The \`t\` command lives in … (\`bash/.bashrc-arch\`, \`-wsl\`, \`-raspbian\`).` → `The \`t\` command lives in \`zsh/.zshrc\`, the shell config on macOS and Linux alike.`
- `doc/tools.md`: the eza row's description `` `ls` with icons and git status `` → `` Listings with icons and git status (`ll`, `lt`, `la`; `ls` stays `ls`) ``.

- [ ] **Step 3: The CHANGELOG entry, at the top below the `---` that follows "How to sync a machine"**

````markdown
## 2026-10-06: zsh on Linux; the Linux bash files are gone

### On other machines
**Arch box, Pi, WSL: run the installer straight after pulling.** The pull
deletes the Linux `bash/.bashrc-*` and `.bash_profile-*` files that
`~/.bashrc` and `~/.bash_profile` link to. Until the installer runs, a new
terminal is bash with no config, and on Arch logging out lands on the text
console without Hyprland (run the installer from there).
1. `git pull --ff-only`, then at once `./install_arch.sh` or
   `./install_debian.sh`. It installs zsh, its two plugins and oh-my-zsh, links
   `zsh` and `zsh-linux`, puts back the distro's own `~/.bashrc`, and makes zsh
   the login shell (`sudo chsh`).
2. Log out and back in. On Arch, Hyprland now starts from `~/.zprofile`.
3. `scripts/verify.sh`.

A key passphrase is now asked in the first terminal, not at the TTY login.

**macOS:** `stow -R -t ~ zsh`, then open a new terminal. A pull alone already
works; the re-stow adds the `~/.config/zsh` link. `ll`, `lt` and `la` are now
eza (they were oh-my-zsh's `ls -lh` / `ls -lAh`), and `fcpp`, `ftodo`, `fmd`
and `ffunc` are new. `~/.zprofile` is untouched.

**Windows:** nothing.

### What changed
- `zsh/.zshrc` is shared by macOS and Linux. OS specifics are in
  `zsh/.config/zsh/darwin.zsh` / `linux.zsh`; `~/.zshrc.local` holds one
  machine's lines.
- New Linux-only package `zsh-linux`: `.zprofile` with one ssh-agent per
  login and the TTY1 Hyprland start. Unlike `.bash_profile-arch` it doesn't
  exec a Hyprland that isn't installed.
- `scripts/setup-zsh-linux.sh`, run by both Linux installers: oh-my-zsh,
  retiring the old bash links, Debian's `bat`/`fd` names, `chsh`.
- `scripts/verify.sh` on Linux: FAIL if the login shell isn't zsh or a link to
  a removed bash file remains; WARN for a missing oh-my-zsh or plugin.
- `ls` is no longer eza on Linux, and listings no longer hide `CLAUDE.md`.
- Tested: the Mac against a before/after baseline; `scripts/test-in-docker.sh`
  on ubuntu:24.04, debian:12 (an upgrade from the bash setup) and archlinux.
  Not yet on real Linux hardware: see the NUC checklist; the Pi and WSL on
  their next sync.
- Design and plan: `doc/specs/2026-10-06-zsh-on-linux-design.md`,
  `doc/plans/2026-10-06-zsh-on-linux.md`.

---
````

- [ ] **Step 4: Verify on the Mac, commit, push**

```bash
scripts/lint.sh 2>&1 | grep -E 'All checks|FAIL'
scripts/test-zsh.sh | tail -1
git add -A CLAUDE.md README.md doc/applying-the-setup.md doc/tmux.md doc/tools.md CHANGELOG.md
git commit -q -m "Docs and CHANGELOG for zsh on Linux

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push -q && git log --oneline origin/master -8
scripts/verify.sh 2>&1 | tail -2
```

Expected:
- lint clean; `All zsh checks passed`;
- the push lists Tasks 1–7's commits;
- `verify.sh` passes and records the new commit.

- [ ] **Step 5: archinstall's guide**

In `~/Development/archinstall/doc/arch-hyprland-guide.md` line 187, `(\`bash/.bash_profile-arch\`)` → `(\`zsh-linux/.zprofile\`; zsh is the login shell)`. Then:

```bash
cd ~/Development/archinstall && git add doc/arch-hyprland-guide.md && git commit -q -m "Arch guide: dotfiles start Hyprland from zsh-linux/.zprofile now

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" && git push -q
```

- [ ] **Step 6: The todo list** (`~/Development/todo`; `git pull --ff-only` first, since other sessions write there)

- `TODO.md`, NUC checklist step 3: replace the `Terminal: foot plus the Nord starship prompt; …` item's opening with `` `2026-10-05` Terminal: foot opens **zsh** (`echo $SHELL`), with the Nord starship prompt, grey suggestions and green/red highlighting; `` and keep the rest of that item.
- Add an item to the NUC checklist:
  `` - [ ] `2026-10-06` zsh switch (dotfiles, see CHANGELOG 2026-10-06): `scripts/verify.sh` passes the "login shell is zsh" check; Hyprland starts from `~/.zprofile` on TTY1; one ssh-agent shared by every terminal (`echo $SSH_AUTH_SOCK` matches in two). ``
- In the "Update the other machines" item, add one sentence: "**The zsh switch (2026-10-06):** run the installer straight after pulling (CHANGELOG)."
- In the "Setup ideas not yet done" item, tick the "Decide first: zsh on Linux" line as done, naming Task 5's commit (`git -C ~/Development/dotfiles log --oneline -1 --grep 'Linux runs zsh'`).
- Write a `log/2026-10.md` entry at the top: what changed, the test matrix results, and any unrelated debian:12 installer failures noted in Task 5.
- Add its `README.md` row under `### 2026-10-06`.
- Commit with a specific message, and push.

---

## Self-review notes

- **Spec coverage:**

  | Spec section | Task |
  |---|---|
  | Files: `.zshrc`, `darwin.zsh`, `linux.zsh` | 2 |
  | `zsh-linux/.zprofile` | 3 |
  | Installers 1–7 | 5 |
  | Moving existing machines | 5 (upgrade run), 7 (CHANGELOG) |
  | verify.sh | 6 |
  | Other touch points | 5 (tmux, tools.md), 7 (the rest, archinstall, todo) |
  | Testing: Mac | 1, 2 |
  | Testing: Docker matrix | 5, 6 |
  | Testing: `.zprofile` alone | 3 |
  | Testing: WSL branch | 1 (check), 5 (container) |
  | Risks | CHANGELOG wording, Task 7 |

- **Beyond the spec, found while planning:**
  - oh-my-zsh defines its own `d`, so OS aliases load after it, through `zsh_os_aliases`.
  - `.zprofile` must not exec a missing Hyprland.
  - `.zshrc` loads its OS file through its real path, for a pull before a re-stow.
  - oh-my-zsh already aliases `ls` to `ls -G`, so the check is "ls is not eza".
  - Docker's Debian images drop `/usr/share/doc`.
- **Names used across tasks:**
  - `zsh_os_aliases`, `path_prepend`, `scripts/test-zsh.sh`, `scripts/test-in-docker.sh`, `scripts/setup-zsh-linux.sh`;
  - the verify messages `still links to a retired bash file` and `login shell is <path>, not zsh`.
