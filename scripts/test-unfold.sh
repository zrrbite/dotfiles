#!/usr/bin/env bash
#
# Tests for scripts/unfold.sh, against a throwaway clone of this repo (with
# the working tree's unfold.sh copied in) and a throwaway $HOME, shaped like a
# Mac whose ~/.claude an old installer let stow link into the repo.
#
# Usage: scripts/test-unfold.sh
#
# shellcheck disable=SC2015  # ok and bad always succeed, so A && ok || bad is an if-else here

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
FAILS=0
ok()  { echo -e "${GREEN}ok${NC}   $1"; }
bad() { echo -e "${RED}FAIL${NC} $1"; FAILS=$((FAILS + 1)); }

git clone -q "$DOTFILES_DIR" "$TMP/repo"
cp "$DOTFILES_DIR/scripts/unfold.sh" "$TMP/repo/scripts/unfold.sh"
REPO="$TMP/repo"
H="$TMP/home"
# Claude Code runs right now (this may be it): unfold.sh would refuse ~/.claude.
export UNFOLD_CLAUDE_RUNNING=no

# ~/.claude linked into the repo, and what Claude Code wrote through the link.
setup() {
    rm -rf "$H" && mkdir -p "$H"
    git -C "$REPO" clean -qfdx -- claude/
    ln -s "$REPO/claude/.claude" "$H/.claude"
    mkdir -p "$REPO/claude/.claude/projects/p1" "$REPO/claude/.claude/skills/synced/s1"
    echo '{"a":1}' > "$REPO/claude/.claude/projects/p1/session.jsonl"
    echo '{}' > "$REPO/claude/.claude/settings.json"
    echo '{}' > "$REPO/claude/.claude/settings.local.json"   # ignored by the repo
    echo 'skill' > "$REPO/claude/.claude/skills/synced/s1/SKILL.md"
}

# -- Dry run changes nothing ---------------------------------------------------
setup
out="$("$REPO/scripts/unfold.sh" --dry-run "$H/.claude" 2>&1)"
[ -L "$H/.claude" ] && [ -f "$REPO/claude/.claude/settings.json" ] && ok "dry run changes nothing" || bad "dry run changed something"
printf '%s\n' "$out" | grep -q 'settings.json' && ok "dry run names what it would move" || bad "dry run: $out"

# -- The real thing ------------------------------------------------------------
setup
out="$("$REPO/scripts/unfold.sh" "$H/.claude" 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "exit 0" || bad "exit $rc: $out"
[ -d "$H/.claude" ] && [ ! -L "$H/.claude" ] && ok "the home .claude is a real folder" || bad "home .claude: $(ls -ld "$H/.claude")"
[ ! -L "$H/.claude" ] && [ -f "$H/.claude/projects/p1/session.jsonl" ] && ok "Claude's history moved back" || bad "history not moved: $out"
[ ! -L "$H/.claude" ] && [ -f "$H/.claude/settings.json" ] && [ -f "$H/.claude/settings.local.json" ] && ok "settings moved back, ignored ones too" || bad "settings not moved: $out"
[ ! -L "$H/.claude" ] && [ -f "$H/.claude/skills/synced/s1/SKILL.md" ] && ok "synced skills moved back" || bad "synced skills not moved: $out"
left="$(git -C "$REPO" status --porcelain --ignored -- claude/)"
[ -z "$left" ] && ok "nothing of Claude's left in the repo" || bad "left in the repo: $left"
[ -f "$REPO/claude/.claude/CLAUDE.md" ] && ok "the repo's own files stay" || bad "a tracked file went missing"
stow -d "$REPO" -t "$H" claude 2>"$TMP/stow.err" && [ -L "$H/.claude/CLAUDE.md" ] && [ -L "$H/.claude/skills/review" ] &&
    ok "stow then links the files one by one" || bad "stow afterwards: $(cat "$TMP/stow.err")"

# -- Claude Code running: ~/.claude is left alone, and it says why -------------
setup
out="$(UNFOLD_CLAUDE_RUNNING=yes "$REPO/scripts/unfold.sh" "$H/.claude" 2>&1)"; rc=$?
if [ "$rc" = 1 ] && [ -L "$H/.claude" ] && printf '%s\n' "$out" | grep -q 'Quit Claude Code'; then
    ok "Claude Code running: refuses ~/.claude, exit 1"
else
    bad "Claude Code running (exit $rc): $out"
fi
out="$(UNFOLD_CLAUDE_RUNNING=yes "$REPO/scripts/unfold.sh" --dry-run "$H/.claude" 2>&1)"
printf '%s\n' "$out" | grep -q 'Quit Claude Code' && ok "Claude Code running: a dry run says so" || bad "dry run, Claude running: $out"

# -- Left alone ----------------------------------------------------------------
mkdir -p "$TMP/elsewhere" && rm -rf "$H" && mkdir -p "$H" && ln -s "$TMP/elsewhere" "$H/.claude"
"$REPO/scripts/unfold.sh" "$H/.claude" >/dev/null 2>&1
[ -L "$H/.claude" ] && ok "a link outside the repo is left alone" || bad "a link outside the repo was removed"
rm -rf "$H" && mkdir -p "$H/.claude"
out="$("$REPO/scripts/unfold.sh" "$H/.claude" "$H/missing" 2>&1)"; rc=$?
[ "$rc" = 0 ] && [ -z "$out" ] && ok "real and missing folders: silent no-op" || bad "real/missing (exit $rc): $out"

echo
if [ "$FAILS" -gt 0 ]; then
    echo -e "${RED}$FAILS test(s) failed${NC}"
    exit 1
fi
echo -e "${GREEN}All tests passed${NC}"
