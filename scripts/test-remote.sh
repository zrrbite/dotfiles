#!/usr/bin/env bash
#
# End-to-end tests for `remote` (remote/.local/bin/remote), against the
# stand-in work Mac from scripts/remote-test-host.sh. Exit 0 = all passed.
#
# Usage: scripts/test-remote.sh [group ...]
#   groups: status read refuse git hint mount build perms   (default: all)
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE="$DOTFILES_DIR/remote/.local/bin/remote"
H=workmac-test
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
FAILS=0
ok()   { echo -e "${GREEN}ok${NC}   $1"; }
bad()  { echo -e "${RED}FAIL${NC} $1"; FAILS=$((FAILS + 1)); }
skip() { echo -e "${YELLOW}skip${NC} $1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# An ssh config with two extra aliases, keeping everything in ~/.ssh/config:
# one that can't be reached, and one that goes through a relay the mount test
# can kill. Include comes first so it stays outside the Host blocks.
CFG="$TMP/ssh_config"
RELAY_PORT=$(( 20000 + $$ % 10000 ))
cat > "$CFG" <<EOF
Include ~/.ssh/config
Host remote-test-dead
    HostName 192.0.2.1
    User nobody
Host remote-test-relay
    HostName 127.0.0.1
    Port $RELAY_PORT
    User workmac-sim
    IdentityFile ~/.ssh/remote_test
    IdentitiesOnly yes
    UserKnownHostsFile ~/.ssh/known_hosts_remote_test
    HostKeyAlias localhost
    StrictHostKeyChecking accept-new
EOF

# R: run the repo's remote. RD: the same, against the unreachable alias, which
# proves a refusal ran nothing: a request that reached ssh would take 5 s and
# exit 255, a refusal exits 2 at once.
R()  { "$REMOTE" "$@"; }
RD() { REMOTE_SSH_CONFIG="$CFG" "$REMOTE" remote-test-dead "$@"; }

# expect_rc NAME WANTED CMD... ; expect_has NAME OUTPUT TEXT ; expect_lacks NAME OUTPUT TEXT
expect_rc() { local n="$1" w="$2" rc; shift 2; "$@" >"$TMP/out" 2>&1; rc=$?
    if [ "$rc" = "$w" ]; then ok "$n"; else bad "$n: exit $rc, wanted $w: $(head -c 300 "$TMP/out")"; fi; }
expect_has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1: [$(printf %s "$2" | head -c 300)] lacks [$3]" ;; esac; }
expect_lacks() { case "$2" in *"$3"*) bad "$1: has [$3]" ;; *) ok "$1" ;; esac; }

t_status() {
    local start out
    start=$(date +%s)
    out="$(REMOTE_SSH_CONFIG="$CFG" "$REMOTE" remote-test-dead status 2>&1)"; local rc=$?
    if [ "$rc" -ne 0 ]; then ok "status: unreachable host fails"; else bad "status: unreachable host exit 0"; fi
    if [ $(( $(date +%s) - start )) -le 7 ]; then ok "status: ...within 7 s"; else bad "status: took $(( $(date +%s) - start )) s"; fi
    expect_has "status: says NOT reachable" "$out" "NOT reachable"
    out="$(R $H status 2>&1)"
    expect_has "status: test host reachable" "$out" "is reachable"
}

t_read() {
    local out
    out="$(R $H ls src/hello 2>&1)";            expect_has "ls" "$out" "hello.cpp"
    out="$(R $H cat src/hello/hello.cpp 2>&1)"; expect_has "cat" "$out" "hello from workmac-sim"
    out="$(R $H cat src/hello/hello.cpp 1:1 2>&1)"
    if [ "$out" = "#include <iostream>" ]; then ok "cat range 1:1"; else bad "cat range 1:1 gave [$out]"; fi
    out="$(R $H grep 'hello from' src 2>&1)";   expect_has "grep" "$out" "src/hello/hello.cpp:"
    out="$(R $H grep -l -i 'HELLO FROM' src 2>&1)"; expect_has "grep -l -i" "$out" "src/hello/hello.cpp"
    out="$(R $H grep --include '*.txt' spaced src 2>&1)"; expect_has "grep --include" "$out" "with space.txt"
    out="$(R $H grep --include '*.txt' 'hello from' src 2>&1)"; expect_lacks "grep --include filters" "$out" "hello.cpp"
    out="$(R $H find src -name '*.cpp' -type f 2>&1)"; expect_has "find" "$out" "src/hello/hello.cpp"
    # Review focus 1: spaces in paths
    out="$(R $H cat 'src/hello/with space.txt' 2>&1)"; expect_has "cat: path with a space" "$out" "spaced out"
    out="$(R $H grep spaced 'src/hello/with space.txt' 2>&1)"; expect_has "grep: path with a space" "$out" "spaced out"
    # Review focus 2: a pattern that starts with -
    out="$(R $H grep -- -Wall src 2>&1)"; expect_has "grep -- -Wall" "$out" "flags.txt"
    # Review focus 5: a missing file fails with the remote's error, no hint
    expect_rc "cat: missing file exits 1" 1 R $H cat src/hello/nope.txt
    out="$(R $H cat src/hello/nope.txt 2>&1)"; expect_lacks "cat: missing file, no privacy hint" "$out" "full disk access"
    # Injection: none of these may run anything on the remote
    local tag="pwned-$$"
    R $H grep "x; touch /tmp/$tag-1" src >/dev/null 2>&1
    R $H grep "\$(touch /tmp/$tag-2)" src >/dev/null 2>&1
    R $H ls "src; touch /tmp/$tag-3" >/dev/null 2>&1
    R $H cat "src/hello/\`touch /tmp/$tag-4\`" >/dev/null 2>&1
    R $H find src -name "*; touch /tmp/$tag-5" >/dev/null 2>&1
    out="$(ls /tmp/"$tag"-* 2>/dev/null)"
    if [ -z "$out" ]; then ok "injection: nothing ran"; else bad "injection: created $out"; fi
}

t_refuse() {
    expect_rc "refuse: grep --pre" 2 RD grep --pre=sh x src
    expect_rc "refuse: grep -r (not allowed)" 2 RD grep -r x src
    expect_rc "refuse: find -exec" 2 RD find src -exec rm {} ';'
    expect_rc "refuse: find -delete" 2 RD find src -delete
    expect_rc "refuse: find -type x" 2 RD find src -type l
    expect_rc "refuse: path starting with -" 2 RD ls -la
    expect_rc "refuse: unknown subcommand" 2 RD rm src
    expect_rc "refuse: bad cat range" 2 RD cat src/x 5
    expect_rc "refuse: host alias with a slash" 2 R ../etc status
}

t_git() {
    local out
    out="$(R $H git src/hello status 2>&1)";        expect_has "git status" "$out" "README.md"
    out="$(R $H git src/hello log --oneline 2>&1)";  expect_has "git log" "$out" "hello: first commit"
    out="$(R $H git src/hello diff 2>&1)";           expect_has "git diff" "$out" "An uncommitted line"
    out="$(R $H git src/hello show --stat 2>&1)";    expect_has "git show" "$out" "hello.cpp"
    out="$(R $H git src/hello branch 2>&1)";         expect_has "git branch" "$out" "main"
    expect_rc "refuse: git push" 2 RD git src/hello push
    expect_rc "refuse: git commit" 2 RD git src/hello commit -m x
    expect_rc "refuse: git reset" 2 RD git src/hello reset --hard
    expect_rc "refuse: git branch -D" 2 RD git src/hello branch -D main
    expect_rc "refuse: git diff --ext-diff" 2 RD git src/hello diff --ext-diff
    expect_rc "refuse: git log --output" 2 RD git src/hello log --output=/tmp/x
    expect_rc "refuse: git -c" 2 RD git src/hello log -c
}

t_hint() {
    local out rc
    out="$(R $H cat Documents/secret.txt 2>&1)"; rc=$?
    if [ "$rc" -eq 0 ]; then
        skip "privacy hint: Remote Login has full disk access for remote users here"
        return
    fi
    expect_has "privacy hint" "$out" "Allow full disk access for remote users"
}

ALL="status read refuse git hint mount build perms"
# (Not GROUPS: that is a bash built-in, and assigning to it does nothing.)
RUN_GROUPS="${*:-$ALL}"
if [ "$RUN_GROUPS" != perms ] && ! ssh -n -o BatchMode=yes -o ConnectTimeout=5 "$H" true 2>/dev/null; then
    echo "$H is not reachable: run scripts/remote-test-host.sh up" >&2
    exit 2
fi
for g in $RUN_GROUPS; do
    if declare -f "t_$g" >/dev/null; then "t_$g"; else bad "no test group: $g"; fi
done
echo
if [ "$FAILS" -eq 0 ]; then echo -e "${GREEN}All remote checks passed${NC}"; else echo -e "${RED}$FAILS check(s) failed${NC}"; fi
[ "$FAILS" -eq 0 ]
