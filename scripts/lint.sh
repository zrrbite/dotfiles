#!/usr/bin/env bash
#
# Repo checks, run both by CI and by hand. Two things are worth catching
# automatically here, because both have already broken this repo once:
#
#   1. Shell bugs in the installers. They are long, run rarely, and a typo in
#      one of them is only discovered on a fresh machine -- the worst possible
#      moment. shellcheck reads them all in a second.
#
#   2. Stow packages that would litter $HOME. `stow */` treats every top-level
#      directory as a package, so a new directory without a .stow-local-ignore
#      drops its contents straight into $HOME as ~/Makefile, ~/settings.json
#      and friends. CLAUDE.md documents the dry-run check; this runs it.
#
# Usage: ./scripts/lint.sh [shellcheck|stow]
# With no argument, runs everything.

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || { fail "cannot cd to repo root $REPO_ROOT"; exit 2; }

STATUS=0

# ---------------------------------------------------------------------------
# Check: shell scripts
#
# The banner says "Check:" rather than the bare tool name because a comment
# whose first word is `shellcheck` is read as a shellcheck directive, and an
# unparseable one is an error -- in this file, from this very check.
# ---------------------------------------------------------------------------
check_shellcheck() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        warn "shellcheck not installed -- skipping (brew install shellcheck)"
        return 0
    fi

    # Collect tracked shell scripts. Anything ending in .sh, plus any tracked
    # file with a shell shebang -- which is how the git hooks get picked up,
    # since they are extensionless by design.
    local files=()
    local f
    while IFS= read -r f; do
        case "$f" in
            *.sh) files+=("$f"); continue ;;
        esac
        # -s guards against tracked-but-absent files; the read is one line, so
        # a binary file costs nothing.
        if [ -s "$f" ] && head -n 1 "$f" 2>/dev/null | grep -qE '^#!.*[/ ](ba|da|k)?sh( |$)'; then
            files+=("$f")
        fi
    done < <(git ls-files)

    if [ ${#files[@]} -eq 0 ]; then
        fail "shellcheck: found no shell scripts to check -- the discovery above is broken"
        return 1
    fi

    info "shellcheck: checking ${#files[@]} scripts"
    # --severity=style is the strictest level; the repo is clean at it today, so
    # anything less would let new findings in unnoticed.
    if shellcheck --severity=style --format=gcc "${files[@]}"; then
        info "shellcheck: clean"
        return 0
    fi
    fail "shellcheck: findings above"
    return 1
}

# ---------------------------------------------------------------------------
# stow dry-run
# ---------------------------------------------------------------------------
check_stow() {
    if ! command -v stow >/dev/null 2>&1; then
        warn "stow not installed -- skipping"
        return 0
    fi

    local target
    target="$(mktemp -d)"
    # shellcheck disable=SC2064  # expand $target now, not at trap time
    trap "rm -rf '$target'" RETURN

    # Stow into a throwaway target so this cannot touch the real $HOME, and
    # report any link whose name does not start with a dot: those are the bare
    # ~/Makefile-style files a missing .stow-local-ignore produces.
    local offenders
    offenders="$(stow -n -v -t "$target" ./*/ 2>&1 | grep '^LINK:' | grep -v 'LINK: \.' || true)"

    if [ -n "$offenders" ]; then
        fail "stow: these would be created as bare files in \$HOME:"
        # shellcheck disable=SC2001  # indenting every line of a multi-line
        # string is what sed is for; ${var//} substitutes, it does not prefix lines.
        echo "$offenders" | sed 's/^/    /'
        echo ""
        echo "    Fix: add a .stow-local-ignore containing '.*' to the offending"
        echo "    directory, so \`stow */\` skips it. See CLAUDE.md."
        return 1
    fi

    info "stow: no package would litter \$HOME"
    return 0
}

case "${1:-all}" in
    shellcheck) check_shellcheck || STATUS=1 ;;
    stow)       check_stow || STATUS=1 ;;
    all)
        check_shellcheck || STATUS=1
        echo ""
        check_stow || STATUS=1
        ;;
    *)
        fail "Unknown check: $1 (expected shellcheck, stow, or nothing)"
        exit 2
        ;;
esac

echo ""
if [ "$STATUS" -eq 0 ]; then
    info "All checks passed"
else
    fail "Some checks failed"
fi
exit "$STATUS"
