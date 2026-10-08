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
    # A leading = (zsh expands =word) or ~ (bash 3.2 leaves it bare) must stay literal
    out="$(R $H grep '=x' src 2>&1)"; expect_lacks "grep: pattern starting with = reaches grep" "$out" "not found"
    out="$(R $H find src -name '=*' 2>&1)"; local rc=$?
    if [ "$rc" -eq 0 ]; then ok "find: -name starting with ="; else bad "find -name =*: exit $rc: $out"; fi
    out="$(/bin/bash "$REMOTE" $H ls '~root' 2>&1)"; expect_has "ls under bash 3.2: ~ stays literal" "$out" "No such file"
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
    R $H grep "$(printf 'x\ntouch /tmp/%s-6' "$tag")" src >/dev/null 2>&1
    R $H git src/hello log -1 "--format=%s;\$(touch /tmp/$tag-7)" >/dev/null 2>&1
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
    expect_rc "refuse: host alias with a comma (sshfs -o injection)" 2 R "work,ssh_command=touch" status
    expect_rc "refuse: host alias .." 2 R .. status
    expect_rc "refuse: host alias ." 2 R . status
    expect_rc "refuse: host alias with a space" 2 R "a b" status
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

t_mount() {
    local mp="$HOME/remote/$H" out start pid
    R $H unmount >/dev/null 2>&1
    expect_rc "mount" 0 R $H mount
    if mount | grep -qF " on $mp "; then ok "mount: in the mount table"; else bad "mount: not in the mount table"; fi
    out="$(R $H status 2>&1)"; expect_has "status: healthy" "$out" "(healthy)"
    out="$(R $H mount 2>&1)"; expect_has "mount again: says so" "$out" "already mounted"
    out="$(cat "$mp/src/hello/hello.cpp" 2>&1)"; expect_has "read through the mount" "$out" "hello from workmac-sim"
    out="$(cat "$mp/src/hello/with space.txt" 2>&1)"; expect_has "mount: path with a space" "$out" "spaced out"
    printf 'edited through the mount %s\n' "$$" > "$mp/src/hello/notes.txt"
    out="$(R $H cat src/hello/notes.txt 2>&1)"; expect_has "edit through the mount lands remotely" "$out" "edited through the mount $$"
    rm -f "$mp/src/hello/notes.txt"
    expect_rc "unmount" 0 R $H unmount
    if mount | grep -qF " on $mp "; then bad "unmount: still mounted"; else ok "unmount: gone from the mount table"; fi
    if [ -e "$mp" ]; then bad "unmount: $mp left behind"; else ok "unmount: folder removed"; fi

    # Review focus 4: a leftover empty folder
    mkdir -p "$mp"
    out="$(R $H status 2>&1)"; expect_has "leftover folder: status says not mounted" "$out" "not mounted"
    expect_rc "leftover folder: unmount tidies" 0 R $H unmount
    if [ -e "$mp" ]; then bad "leftover folder: still there"; else ok "leftover folder: removed"; fi
    # Review focus 3: a folder that isn't empty
    mkdir -p "$mp"; touch "$mp/mine.txt"
    expect_rc "non-empty folder: mount refuses" 2 R $H mount
    if [ -f "$mp/mine.txt" ]; then ok "non-empty folder: left alone"; else bad "non-empty folder: file gone"; fi
    rm -f "$mp/mine.txt"; rmdir "$mp"

    # The remote disappears while mounted (through a relay we can kill)
    python3 - "$RELAY_PORT" 22 > /dev/null 2>&1 <<'PY' &
import socket, sys, threading
lport, dport = int(sys.argv[1]), int(sys.argv[2])
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", lport)); s.listen(5)
def pipe(a, b):
    try:
        while True:
            d = a.recv(65536)
            if not d: break
            b.sendall(d)
    except OSError: pass
    finally:
        for x in (a, b):
            try: x.shutdown(socket.SHUT_RDWR)
            except OSError: pass
while True:
    c, _ = s.accept()
    u = socket.create_connection(("127.0.0.1", dport))
    threading.Thread(target=pipe, args=(c, u), daemon=True).start()
    threading.Thread(target=pipe, args=(u, c), daemon=True).start()
PY
    pid=$!
    sleep 1
    local RR="REMOTE_SSH_CONFIG=$CFG"
    expect_rc "relay: mount" 0 env "$RR" "$REMOTE" remote-test-relay mount
    kill "$pid"; wait "$pid" 2>/dev/null
    start=$(date +%s)
    out="$(env "$RR" "$REMOTE" remote-test-relay status 2>&1)"; local rc=$?
    if [ "$rc" -ne 0 ]; then ok "dead mount: status fails"; else bad "dead mount: status exit 0"; fi
    expect_has "dead mount: status says the mount is not responding" "$out" "NOT responding"
    if [ $(( $(date +%s) - start )) -le 15 ]; then ok "dead mount: status within 15 s"; else bad "dead mount: status took $(( $(date +%s) - start )) s"; fi
    start=$(date +%s)
    expect_rc "dead mount: unmount" 0 env "$RR" "$REMOTE" remote-test-relay unmount
    if [ $(( $(date +%s) - start )) -le 20 ]; then ok "dead mount: unmount within 20 s"; else bad "dead mount: unmount took $(( $(date +%s) - start )) s"; fi
    if mount | grep -qF " on $HOME/remote/remote-test-relay "; then bad "dead mount: still mounted"; else ok "dead mount: gone"; fi
}

t_build() {
    local out mp="$HOME/remote/$H"
    out="$(ssh -n $H 'command -v cmake || echo NO-CMAKE' 2>&1)"
    expect_has "bare PATH has no cmake (the problem the prelude fixes)" "$out" "NO-CMAKE"
    expect_rc "build with presets" 0 R $H build src/hello
    out="$(R $H find src/hello/build/debug -name hello -type f 2>&1)"; expect_has "build: binary in the preset's folder" "$out" "build/debug/hello"
    expect_rc "test with presets" 0 R $H test src/hello
    expect_rc "build --preset debug" 0 R $H build src/hello --preset debug
    expect_rc "build --build-dir" 0 R $H build src/hello --build-dir build/plain
    expect_rc "test --build-dir" 0 R $H test src/hello --build-dir build/plain
    expect_rc "refuse: --preset and --build-dir" 2 RD build src/hello --preset debug --build-dir b
    expect_rc "refuse: unknown build option" 2 RD build src/hello --target all
    # An edit through the mount reaches the build; a failing test exits non-zero
    R $H mount >/dev/null
    sed -i '' 's/hello from workmac-sim/goodbye/' "$mp/src/hello/hello.cpp"
    expect_rc "build after an edit through the mount" 0 R $H build src/hello
    out="$(R $H test src/hello 2>&1)"; local rc=$?
    if [ "$rc" -ne 0 ]; then ok "test fails after the edit (the build saw it)"; else bad "test passed after the edit"; fi
    # A broken build exits non-zero. The pause matters: macOS's make (GNU Make
    # 3.81) compares file times in whole seconds, so an edit in the same second
    # as the last build's object file looks up to date (Ninja doesn't care).
    sleep 1
    printf 'this is not C++;\n' >> "$mp/src/hello/hello.cpp"
    out="$(R $H build src/hello 2>&1)"; rc=$?
    if [ "$rc" -ne 0 ]; then ok "broken build exits non-zero"; else bad "broken build exit 0"; fi
    ssh -n $H 'git -C src/hello checkout -- hello.cpp'
    expect_rc "restored: build passes again" 0 R $H build src/hello
    expect_rc "restored: test passes again" 0 R $H test src/hello
    R $H unmount >/dev/null
}

t_perms() {
    local S="$DOTFILES_DIR/scripts/claude-remote-permissions.sh" f="$TMP/settings.json" out
    rm -f "$f"
    expect_rc "perms: creates a missing file" 0 "$S" "$f"
    out="$(jq -c '.permissions.allow' "$f")"
    if [ "$out" = '["Bash(remote:*)","Read(~/remote/**)"]' ]; then ok "perms: both rules"; else bad "perms: got $out"; fi
    printf '{"model":"x","permissions":{"allow":["Bash(ls:*)"],"deny":["Read(./.env)"]}}' > "$f"
    expect_rc "perms: existing file" 0 "$S" "$f"
    expect_rc "perms: second run" 0 "$S" "$f"
    out="$(jq -c '[.model, .permissions.allow, .permissions.deny]' "$f")"
    if [ "$out" = '["x",["Bash(ls:*)","Bash(remote:*)","Read(~/remote/**)"],["Read(./.env)"]]' ]; then ok "perms: keeps the rest, adds each rule once"; else bad "perms: got $out"; fi
    printf '{ not json' > "$f"
    expect_rc "perms: invalid JSON exits 1" 1 "$S" "$f"
    if [ "$(cat "$f")" = '{ not json' ]; then ok "perms: invalid file untouched"; else bad "perms: invalid file changed"; fi
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
