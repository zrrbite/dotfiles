#!/usr/bin/env bash
#
# Undo a folder that stow linked into this repo as a whole ("folded" it), so
# the apps writing there write into $HOME again. For each folder that is a
# symlink into the repo: remove the link, make a real folder, and move back
# everything in the repo's copy that git doesn't track, ignored files
# included. That is what apps wrote through the link: Claude Code's history,
# settings and synced skills, an app's config. The repo's own files stay;
# re-stow afterwards (the installers do) and stow links them one by one.
#
# Usage: scripts/unfold.sh [--dry-run] DIR...
#   (DRY_RUN=true in the environment works too, for the installers)
#
# A real folder, a missing one, or a link that leads outside the repo is left
# alone, so it's safe on every run. The installers run it; verify.sh names
# the folders that need it. A folder in .claude is refused while Claude Code
# runs: it writes there all the time, and a file it writes between the link
# going and the move would land in the way. Tests: scripts/test-unfold.sh.

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_REAL="$(realpath "$DOTFILES_DIR")"

DRY="${DRY_RUN:-false}"
if [ "${1:-}" = --dry-run ]; then
    DRY=true
    shift
fi
run() {
    if [ "$DRY" = true ]; then
        echo "[DRY] $*"
    else
        "$@"
    fi
}

# Claude Code: a `claude` process, its native build under ~/.local/share/claude,
# or the npm one. UNFOLD_CLAUDE_RUNNING=yes|no is for the tests.
claude_running() {
    case "${UNFOLD_CLAUDE_RUNNING:-}" in
        yes) return 0 ;;
        no)  return 1 ;;
    esac
    pgrep -x claude >/dev/null 2>&1 || pgrep -f '/share/claude/|claude-code/cli' >/dev/null 2>&1
}

status=0
for dir in "$@"; do
    dir="${dir%/}"
    [ -L "$dir" ] || continue
    src="$(realpath "$dir" 2>/dev/null)" || continue
    case "$src" in
        "$REPO_REAL"/*) ;;
        *) echo "$dir links outside the repo ($src): left alone"; continue ;;
    esac
    rel="${src#"$REPO_REAL"/}"
    case "$dir" in
        */.claude|*/.claude/*)
            if claude_running; then
                echo "$dir is linked into the repo ($rel), but Claude Code is running and writes there."
                echo "  Quit Claude Code (every window), then run: scripts/unfold.sh $dir"
                status=1
                continue
            fi ;;
    esac
    echo "$dir is linked into the repo ($rel): making it a real folder"
    # Listed before the link goes. --others without --exclude-standard
    # includes ignored files; --directory lists a new folder once.
    strays="$(git -C "$REPO_REAL" ls-files --others --directory -- "$rel/")"
    run rm "$dir" || { status=1; continue; }
    run mkdir -p "$dir"
    while IFS= read -r path; do
        [ -n "$path" ] || continue
        path="${path%/}"
        sub="${path#"$rel"/}"
        echo "  moving back: $sub"
        run mkdir -p "$(dirname "$dir/$sub")"
        run mv "$REPO_REAL/$path" "$dir/$sub" || status=1
    done <<< "$strays"
done
exit "$status"
