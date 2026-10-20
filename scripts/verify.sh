#!/usr/bin/env bash
#
# Check whether this repo is applied to the current machine. Prints PASS /
# WARN / FAIL lines and exits non-zero if any check FAILs, so an agent (or a
# person) has an unambiguous "done" signal.
#
# Changes nothing, with one exception: when every check passes, it records the
# repo's current commit in ~/.local/state/dotfiles/applied. The next run then
# says how far behind master this machine is, and CHANGELOG.md says what to
# do about it. The record is outside the repo, per machine.
#
# Usage: scripts/verify.sh [--no-record] [package ...]
#   --no-record  check, but don't record the commit as this machine's sync
#   point. The installers pass it: the steps after them (permissions, a
#   CHANGELOG entry's manual steps) aren't done yet when they finish.
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
RECORD=true
if [ "${1:-}" = --no-record ]; then
    RECORD=false
    shift
fi
if [ $# -gt 0 ]; then PACKAGES=("$@"); else PACKAGES=("${DEFAULT[@]}"); fi

echo "Checking $OS against $DOTFILES_DIR"

# -- Where this machine was last synced ------------------------------------------
STATE="$HOME/.local/state/dotfiles/applied"
HEAD_SHA="$(git -C "$DOTFILES_DIR" rev-parse HEAD 2>/dev/null)"
if [ -f "$STATE" ]; then
    last_sha="$(sed -n 's/^commit //p' "$STATE")"
    last_date="$(sed -n 's/^date //p' "$STATE")"
    if behind="$(git -C "$DOTFILES_DIR" rev-list --count "$last_sha..HEAD" 2>/dev/null)"; then
        if [ "$behind" -gt 0 ]; then
            warn "last verified at ${last_sha:0:7} ($last_date), $behind commit(s) ago -- read the CHANGELOG.md entries since $last_date"
        else
            pass "last verified at ${last_sha:0:7} ($last_date), the current commit"
        fi
    else
        warn "last verified at ${last_sha:0:7} ($last_date), a commit this checkout doesn't have -- pull first"
    fi
else
    warn "no record of a previous sync on this machine -- treat every CHANGELOG.md entry as new"
fi
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

# -- Shell (Linux) --------------------------------------------------------------
# zsh replaced bash on Linux on 2026-10-06 (doc/specs/2026-10-06-zsh-on-linux-design.md).
checks_zsh=false
for p in "${PACKAGES[@]}"; do [ "$p" = zsh ] && checks_zsh=true; done
if [ "$OS" != darwin ] && [ "$checks_zsh" = true ]; then
    me="$(id -un)"
    shell="$(getent passwd "$me" | cut -d: -f7)"
    if [ "${shell##*/}" = zsh ] && ! grep -qx "$shell" /etc/shells 2>/dev/null; then
        fail "login shell $shell is not listed in /etc/shells; login managers and chsh reject it -- run: sudo chsh -s /usr/bin/zsh $me"
    elif [ "${shell##*/}" = zsh ]; then
        pass "login shell is zsh ($shell)"
    else
        fail "login shell is ${shell:-unknown}, not zsh -- run: sudo chsh -s /usr/bin/zsh $me (or scripts/setup-zsh-linux.sh), then log in again"
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
    # A tmux server keeps the shell it started with, so one started before the
    # switch goes on opening bash panes until it is restarted.
    if tmux_shell="$(tmux show -gv default-shell 2>/dev/null)" && [ "${tmux_shell##*/}" != zsh ]; then
        warn "a running tmux server still opens $tmux_shell -- save (prefix Ctrl-s), then: tmux kill-server"
    fi
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

# -- Directories that must never be a symlink into the repo --------------------
# If stow "folds" one of these into a single symlink, anything that later writes
# there -- apps writing config, Claude Code writing its history or its synced
# skills, the installer linking fastfetch's macOS config -- writes inside the
# repo instead. The installers undo a folded ~/.claude/skills on their next run.
for d in "$HOME/.config" "$HOME/.config/fastfetch" "$HOME/.claude" "$HOME/.claude/skills" "$HOME/.local/bin"; do
    if [ -L "$d" ]; then
        case "$(realpath "$d")" in
            "$REPO_REAL"/*) fail "$d is a symlink into the repo; apps write into the working tree -- fix: scripts/unfold.sh $d (quit Claude Code first if it's ~/.claude), then re-run the installer" ;;
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
    # Set but empty: what saving the identity after the pull wrote, on a Mac
    # whose old tracked ~/.gitconfig had carried it. Commits then fail.
    if [ -z "${line#*	}" ]; then
        fail "git $key is empty (in $origin) -- set it: git config -f ~/.gitconfig.local $key \"...\""
        continue
    fi
    case "$(realpath "${origin/#\~/$HOME}" 2>/dev/null)" in
        "$REPO_REAL"/*) fail "git $key comes from the tracked repo file -- it belongs in ~/.gitconfig.local" ;;
        *) pass "git $key = ${line#*	} (from $origin)" ;;
    esac
done

# meld is the shared config's diff and merge tool, and macOS has no meld;
# ~/.gitconfig.local names nvimdiff there (scripts/seed-gitconfig-local.sh).
if [ "$OS" = darwin ] && [ "$(git config --global --includes diff.tool 2>/dev/null)" = meld ] &&
    ! command -v meld >/dev/null 2>&1; then
    warn "git difftool and mergetool use meld, which isn't installed: git config -f ~/.gitconfig.local diff.tool nvimdiff && git config -f ~/.gitconfig.local merge.tool nvimdiff"
fi

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

# -- yazi plugins ----------------------------------------------------------------
YAZI_PKG="$DOTFILES_DIR/yazi/.config/yazi/package.toml"
if [ -f "$YAZI_PKG" ] && [ "$(realpath "$HOME/.config/yazi" 2>/dev/null)" = "$REPO_REAL/yazi/.config/yazi" ]; then
    missing=""
    while read -r dep; do
        name="${dep##*:}"
        [ -d "$HOME/.config/yazi/plugins/$name.yazi" ] || missing="$missing $name"
    done < <(sed -n 's/^use = "\(.*\)"$/\1/p' "$YAZI_PKG")
    if [ -n "$missing" ]; then
        warn "yazi plugins not installed:$missing -- run: ya pkg install"
    else
        pass "yazi plugins installed"
    fi
fi

# -- tmux plugin ----------------------------------------------------------------
if command -v tmux >/dev/null 2>&1; then
    if [ -f "$HOME/.tmux/plugins/tmux-resurrect/resurrect.tmux" ]; then
        pass "tmux-resurrect installed"
    else
        warn "tmux-resurrect missing: sessions won't survive a reboot (the installers clone it)"
    fi
    if [ -f "$HOME/.tmux/plugins/tmux-continuum/continuum.tmux" ]; then
        pass "tmux-continuum installed (auto-save and restore)"
    else
        warn "tmux-continuum missing: saving is manual, prefix Ctrl-s (the installers clone it)"
    fi
    # tmux-continuum only auto-saves while one tmux server runs; a second one
    # (often a test server left behind, as on 2026-10-07) stops it silently.
    # Count the sockets a server answers on; dead ones left by old servers
    # don't matter.
    servers=""
    for sock in "${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)"/*; do
        [ -S "$sock" ] && tmux -S "$sock" list-sessions >/dev/null 2>&1 &&
            servers="$servers ${sock##*/}"
    done
    count=$(echo "$servers" | wc -w | tr -d ' ')
    if [ "$count" -gt 1 ]; then
        warn "$count tmux servers run (${servers# }), so tmux-continuum has stopped auto-saving; stop the extra ones: tmux -L <name> kill-server"
    elif [ "$count" -eq 1 ]; then
        pass "one tmux server (${servers# }): auto-save works"
    fi
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
    # aerospace.toml uses config-version 2 and focus-follows-mouse, which
    # AeroSpace before 0.21 doesn't know: it would refuse the whole file at the
    # next reload or restart, and every binding with it. The installer doesn't
    # upgrade what's installed, so a Mac set up earlier must do it by hand.
    # (AEROSPACE_APP is for the tests.)
    aero_app="${AEROSPACE_APP:-/Applications/AeroSpace.app}"
    if aero_ver="$(defaults read "$aero_app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)"; then
        if [ "$(printf '0.21\n%s\n' "${aero_ver%%-*}" | sort -V | head -1)" = 0.21 ]; then
            pass "AeroSpace $aero_ver (the config needs 0.21+)"
        else
            fail "AeroSpace $aero_ver is older than the config needs (0.21): brew upgrade --cask aerospace, then killall AeroSpace && open -a AeroSpace"
        fi
    fi
    # AeroSpace keeps the bindings it loaded until reload-config. Since
    # 2026-10-07 they are ctrl-alt: plain alt took [ ] { } | \ from the Danish
    # layout, in every app. `aerospace config` asks the running instance.
    if keys="$(aerospace config --get mode.main.binding --keys 2>/dev/null)"; then
        if echo "$keys" | grep -q '^alt-'; then
            fail "AeroSpace is running old alt- keybindings, which take [ ] { } | \\ from the Danish layout -- run: aerospace reload-config"
        else
            pass "AeroSpace keybindings are ctrl-alt"
        fi
    fi
    # AeroSpace's own focus-follows-mouse replaced AutoRaise on 2026-10-12. A
    # Mac set up before then may still run AutoRaise, and two of them fight
    # over which window has focus.
    if pgrep -f 'autoraise/bin/AutoRaise' >/dev/null 2>&1; then
        warn "AutoRaise still runs next to AeroSpace's own focus-follows-mouse: brew services stop dimentium/autoraise/autoraise && brew uninstall autoraise"
    else
        pass "no AutoRaise (AeroSpace does focus-follows-mouse itself)"
    fi
    # What the 2026-10-12 removals leave on a Mac synced from before them.
    # Re-stowing doesn't remove a link for a package that's off the list.
    leftovers=0
    if [ -L "$HOME/.config/alacritty" ]; then
        warn "Alacritty's config is still linked (Ghostty replaced it on macOS): stow -D -t ~ alacritty"
        leftovers=$((leftovers + 1))
    fi
    if [ -d /Applications/Alacritty.app ]; then
        warn "Alacritty is still installed: brew uninstall --cask alacritty, once you work in Ghostty"
        leftovers=$((leftovers + 1))
    fi
    if [ -L "$HOME/.config/AutoRaise" ]; then
        warn "AutoRaise's config link is left over: rm ~/.config/AutoRaise (removes only the link)"
        leftovers=$((leftovers + 1))
    fi
    if [ -d "$(brew --prefix 2>/dev/null)/Cellar/autoraise" ]; then
        warn "AutoRaise is still installed: brew uninstall autoraise && brew untap dimentium/autoraise"
        leftovers=$((leftovers + 1))
    fi
    [ "$leftovers" = 0 ] && pass "no leftovers of AutoRaise or Alacritty"
    # WARN, not FAIL: the installer applies these only with --with-desktop.
    if differ="$("$DOTFILES_DIR/scripts/macos-defaults.sh" --check)"; then
        pass "macOS settings match scripts/macos-defaults.sh"
    else
        warn "macOS settings differ from scripts/macos-defaults.sh (run it to apply):"
        echo "$differ"
    fi
    # What only a person can grant (Accessibility, Karabiner's driver, a
    # fingerprint, ...): scripts/macos-permissions.sh holds the list, checks
    # what a script can, and walks a person through the rest. WARN, not FAIL:
    # nothing here can grant them.
    by_hand=()
    while IFS= read -r line; do
        case "$line" in
            "ok: "*)      pass "${line#ok: }" ;;
            "missing: "*) warn "${line#missing: } -- scripts/macos-permissions.sh walks you through it" ;;
            "by hand: "*) by_hand+=("${line#by hand: }") ;;
        esac
    done < <("$DOTFILES_DIR/scripts/macos-permissions.sh" --check)
    # A cask that's removed (Docker Desktop, 2026-10-12) can leave its zsh
    # completion linked into Homebrew's folder; every new shell then prints
    # "compinit: no such file or directory". WARN, and name the links.
    site="$(brew --prefix 2>/dev/null)/share/zsh/site-functions"
    dangling="$(find "$site" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null)"
    if [ -z "$dangling" ]; then
        pass "no dangling zsh completions in $site"
    else
        warn "dangling zsh completions (new shells print a compinit error); remove them:"
        while IFS= read -r link; do echo "       rm $link"; done <<< "$dangling"
    fi
    # WARN: setting it up needs the password, which a check can't ask for.
    if "$DOTFILES_DIR/scripts/touch-id-sudo.sh" --check >/dev/null; then
        pass "Touch ID for sudo is configured, also for tmux (/etc/pam.d/sudo_local)"
    else
        warn "Touch ID for sudo is not set up: scripts/touch-id-sudo.sh"
    fi
    if command -v sshfs >/dev/null 2>&1; then
        pass "sshfs is installed (remote <host> mount)"
    else
        fail "sshfs is missing: brew install --cask macos-fuse-t/cask/fuse-t-sshfs"
    fi
    if jq -e '.permissions.allow | index(["Bash(remote:*)"]) and index(["Read(~/remote/**)"])' \
        "$HOME/.claude/settings.json" >/dev/null 2>&1; then
        pass "Claude may run remote and read ~/remote without asking"
    else
        fail "Claude's remote permissions are missing: scripts/claude-remote-permissions.sh"
    fi
    echo
    echo "Cannot be checked from a script -- confirm by hand:"
    echo "  - a new terminal shows the Nord starship prompt"
    # The +form: bash 3.2 (a fresh Mac's) calls an empty array unbound.
    for item in ${by_hand[@]+"${by_hand[@]}"}; do
        echo "  - $item"
    done
    echo "  (scripts/macos-permissions.sh walks you through each)"
fi

echo
if [ "$FAILS" -gt 0 ]; then
    echo -e "${RED}$FAILS check(s) failed${NC}, $WARNS warning(s)."
    exit 1
fi

# Everything passed: record this commit as the one this machine is synced to.
if [ "$RECORD" = false ]; then
    echo -e "${GREEN}All checks passed${NC}, $WARNS warning(s). Not recorded as this machine's sync point (--no-record): run scripts/verify.sh once the remaining steps are done."
    exit 0
fi
if [ -n "$HEAD_SHA" ]; then
    mkdir -p "$(dirname "$STATE")"
    {
        echo "commit $HEAD_SHA"
        echo "date $(git -C "$DOTFILES_DIR" log -1 --format=%cd --date=short HEAD)"
        echo "verified $(date '+%Y-%m-%d %H:%M')"
        echo "packages ${PACKAGES[*]}"
    } > "$STATE"
fi
echo -e "${GREEN}All checks passed${NC}, $WARNS warning(s). Recorded ${HEAD_SHA:0:7} as this machine's sync point."
