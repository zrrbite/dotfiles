# Claude on a remote machine over SSH — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let Claude on this Mac find, read, edit, build and test files that live on another Mac over SSH, with only safe operations allowed without prompts.

**Architecture:** A bash command `remote <host> <subcommand>` (stow package `remote`) holds every safe operation and is the permission boundary; the remote home is mounted at `~/remote/<host>` with FUSE-T sshfs for Claude's Read and Edit tools; a model-invoked skill teaches the rules. A localhost-only stand-in work Mac (`scripts/remote-test-host.sh`) and `scripts/test-remote.sh` test it end to end.

**Tech Stack:** bash (3.2-compatible), OpenSSH, FUSE-T + sshfs 2.9, CMake/CTest, jq, GNU Stow, Claude Code skills and permission rules.

**Spec:** `doc/specs/2026-10-08-remote-machine-design.md`

## Global Constraints

- Scripts run under macOS's `/bin/bash` 3.2 as well as Homebrew's bash 5: no `mapfile`, `${x,,}`, `[[ -v ]]`, `declare -A`; an empty array under `set -u` is expanded as `${a[@]+"${a[@]}"}`.
- `scripts/lint.sh` (shellcheck at style severity, `-x`) stays clean; it picks up any tracked file with a shell shebang.
- `remote` exit codes: the remote command's own; **2** for a refused or malformed request (nothing was run, and no SSH connection was made); **255** when the host can't be reached.
- Mount point: `~/remote/<host>` (override `REMOTE_MOUNT_ROOT`); the mount is always the remote home.
- Every SSH call: `-n -o BatchMode=yes -o ConnectTimeout=5`.
- dotfiles: commit straight to `master` and push; a `CHANGELOG.md` entry for every machine-affecting change, in the same pass; `doc/tools.md` updated in the same commit as an installer package change; never write the do-not-commit marker.
- The test host is reached as the ssh alias `workmac-test` (user `workmac-sim`, key `~/.ssh/remote_test`).

## Plan decisions (refinements of the spec, made while planning)

1. **`mount` when already mounted says so and exits 0** (the spec said "refuses"). Idempotent, so the skill's "if not mounted, mount" step can't fail on a re-run.
2. **Remote commands are POSIX `sh` text run by the remote user's login shell** (zsh on a Mac), after the PATH prelude; the spec said `/bin/zsh -c`. Same effect on a Mac, one quoting layer fewer.
3. **`build` configures when needed:** with presets, `cmake --preset P` first if a configure preset named `P` exists; without, `cmake -S . -B D` when `D/CMakeCache.txt` is missing. The spec was silent; a fresh checkout needs it.
4. **Localhost-only logins via `AllowUsers workmac-sim@127.0.0.1 workmac-sim@::1`**, not `ListenAddress`: on macOS `launchd` owns port 22 (`ssh.plist` Sockets), so `ListenAddress` has no effect. The port answers on the network but refuses every login not from this Mac. Task 1 verifies it.
5. **The test project is a small inline CMake project** (`src/hello`), not `practice-folder.sh`'s, whose `main.cpp` has a planted compile error.
6. **`remote-test-host.sh up` refuses if Remote Login is already on**, so it never restricts a Remote Login Martin relies on; `down` turns it off. It also adds `workmac-sim` to `com.apple.access_ssh`, which exists on this Mac and limits Remote Login to its members.
7. **The permission rules are added by `scripts/claude-remote-permissions.sh`**, called by the installer, so it can be tested on its own.

## Review Focus

1. A remote path containing spaces (`src/hello/with space.txt`) works for `ls`, `cat`, `grep` and through the mount. Test: Task 2, `t_read`.
2. A search pattern starting with `-` (`-Wall`) is searchable after `--`: `remote <h> grep -- -Wall src`. Test: Task 2, `t_read`.
3. `~/remote/<host>` exists, is not empty and isn't mounted: `mount` refuses with a clear message instead of an sshfs error. Test: Task 3, `t_mount`.
4. A leftover empty mount folder (sshfs crashed): `status` says "not mounted", `unmount` tidies it away. Test: Task 3, `t_mount`.
5. `cat` of a file that doesn't exist exits non-zero with the remote's error and no privacy hint. Test: Task 2, `t_read`.

---

## File map

| File | Responsibility |
|---|---|
| `scripts/remote-test-host.sh` (create) | Create/remove the stand-in work Mac: user, sshd drop-in, Remote Login, key, ssh alias, sample project |
| `remote/.local/bin/remote` (create) | The command: argument checking, quoting, SSH runner, mount handling, subcommands |
| `scripts/test-remote.sh` (create) | End-to-end tests against `workmac-test`, in groups |
| `scripts/claude-remote-permissions.sh` (create) | Add the two permission rules to a Claude settings file, idempotently |
| `claude/.claude/skills/remote-machine/SKILL.md` (create) | The model-invoked skill |
| `install_darwin.sh`, `scripts/packages.sh`, `scripts/verify.sh` (modify) | Install FUSE-T/sshfs, stow `remote`, add the rules; verify them |
| `doc/remote-machine.md` (create); `doc/tools.md`, `README.md`, `CLAUDE.md`, `CHANGELOG.md` (modify) | Docs |

---

### Task 1: The test host

**Files:**
- Create: `scripts/remote-test-host.sh`

**Interfaces:**
- Produces: ssh alias `workmac-test` (in `~/.ssh/config`, between the markers `# >>> remote-test-host` and `# <<< remote-test-host`); key `~/.ssh/remote_test`; remote user `workmac-sim` whose home holds `src/hello/` (a git repo: `CMakeLists.txt`, `CMakePresets.json` with configure/build/test preset `debug`, `hello.cpp` printing `hello from workmac-sim`, `README.md` with one uncommitted line, `flags.txt` containing `-Wall`, `with space.txt` containing `spaced out`) and `Documents/secret.txt`.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
#
# A stand-in for the offline work Mac, on this Mac: a separate local user,
# reached over SSH as the alias `workmac-test`. For scripts/test-remote.sh and
# for practising with `remote` (doc/remote-machine.md). Needs the admin
# password.
#
#   scripts/remote-test-host.sh up   [--dry-run]   create it, turn Remote Login on
#   scripts/remote-test-host.sh down [--dry-run]   remove it all, turn Remote Login off
#
# `up` refuses if Remote Login is already on: the test host restricts it to one
# user logging in from this Mac, which would lock out anything that relies on it.
#
# What `up` does, and `down` undoes:
#   - user `workmac-sim`, hidden from the login window, with no shell config:
#     commands over SSH get a bare PATH, as on the real work Mac
#   - /etc/ssh/sshd_config.d/050-remote-test.conf: only workmac-sim, only from
#     this Mac (127.0.0.1 / ::1), keys only. (launchd owns port 22 on macOS, so
#     the port answers on the network, but every other login is refused.)
#   - workmac-sim in com.apple.access_ssh, the group Remote Login admits
#   - Remote Login on
#   - key ~/.ssh/remote_test and a `Host workmac-test` block in ~/.ssh/config
#   - ~workmac-sim/src/hello (a CMake project with presets and a test, in git,
#     with one uncommitted change) and ~workmac-sim/Documents/secret.txt
set -euo pipefail

USER_SIM=workmac-sim
HOME_SIM=/Users/$USER_SIM
CONF=/etc/ssh/sshd_config.d/050-remote-test.conf
KEY="$HOME/.ssh/remote_test"
SSH_CONFIG="$HOME/.ssh/config"
BEGIN_MARK="# >>> remote-test-host (dotfiles scripts/remote-test-host.sh)"
END_MARK="# <<< remote-test-host"

ACTION="${1:-}"
DRY_RUN=false
[ "${2:-}" = "--dry-run" ] && DRY_RUN=true

run() {
    if [ "$DRY_RUN" = true ]; then echo "[dry] $*"; else "$@"; fi
}
remote_login_on() { launchctl print system/com.openssh.sshd >/dev/null 2>&1; }

write_project() { # $1: an empty folder to fill
    local d="$1/src/hello"
    mkdir -p "$d" "$1/Documents"
    cat > "$d/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.20)
project(hello LANGUAGES CXX)
add_executable(hello hello.cpp)
enable_testing()
add_test(NAME greets COMMAND hello)
set_tests_properties(greets PROPERTIES PASS_REGULAR_EXPRESSION "hello from workmac-sim")
EOF
    cat > "$d/CMakePresets.json" <<'EOF'
{
  "version": 3,
  "configurePresets": [
    { "name": "debug", "binaryDir": "${sourceDir}/build/debug",
      "cacheVariables": { "CMAKE_BUILD_TYPE": "Debug" } }
  ],
  "buildPresets": [ { "name": "debug", "configurePreset": "debug" } ],
  "testPresets": [
    { "name": "debug", "configurePreset": "debug",
      "output": { "outputOnFailure": true } }
  ]
}
EOF
    cat > "$d/hello.cpp" <<'EOF'
#include <iostream>

int main()
{
	std::cout << "hello from workmac-sim\n";
	return 0;
}
EOF
    printf 'build/\n' > "$d/.gitignore"
    printf '# hello\n\nThe test host'"'"'s sample project.\n' > "$d/README.md"
    printf 'Build flags: -Wall -Wextra\n' > "$d/flags.txt"
    printf 'spaced out\n' > "$d/with space.txt"
    git -C "$d" init -q -b main
    git -C "$d" add -A
    git -C "$d" -c user.name=workmac-sim -c user.email=workmac-sim@localhost \
        -c core.hooksPath=/dev/null commit -q -m "hello: first commit"
    printf '\nAn uncommitted line, for `remote git status`.\n' >> "$d/README.md"
    printf 'private\n' > "$1/Documents/secret.txt"
}

up() {
    if remote_login_on; then
        echo "Remote Login is already on. The test host would restrict it to one user" >&2
        echo "logging in from this Mac; turn it off first (System Settings > General >" >&2
        echo "Sharing > Remote Login) if nothing relies on it." >&2
        exit 1
    fi
    echo "Creating the stand-in work Mac (asks for your password)..."

    if ! id "$USER_SIM" >/dev/null 2>&1; then
        run sudo sysadminctl -addUser "$USER_SIM" -fullName "workmac-sim (remote test host)" \
            -password "$(openssl rand -base64 24)" -home "$HOME_SIM" -shell /bin/zsh
        run sudo createhomedir -c -u "$USER_SIM" >/dev/null
        run sudo dscl . create "/Users/$USER_SIM" IsHidden 1
    fi
    if dscl . -read /Groups/com.apple.access_ssh >/dev/null 2>&1; then
        run sudo dseditgroup -o edit -a "$USER_SIM" -t user com.apple.access_ssh
    fi

    local conf
    conf="$(printf '%s\n' \
        "# scripts/remote-test-host.sh (dotfiles). Removed by its 'down'." \
        "AllowUsers $USER_SIM@127.0.0.1 $USER_SIM@::1" \
        "PasswordAuthentication no" \
        "KbdInteractiveAuthentication no")"
    if [ "$DRY_RUN" = true ]; then echo "[dry] write $CONF:"; echo "$conf"
    else echo "$conf" | sudo tee "$CONF" >/dev/null; fi

    [ -f "$KEY" ] || run ssh-keygen -q -t ed25519 -N '' -C remote-test-host -f "$KEY"
    run sudo install -d -o "$USER_SIM" -g staff -m 700 "$HOME_SIM/.ssh"
    run sudo install -o "$USER_SIM" -g staff -m 600 "$KEY.pub" "$HOME_SIM/.ssh/authorized_keys"

    local tmp
    tmp="$(mktemp -d)"
    if [ "$DRY_RUN" = true ]; then echo "[dry] write the sample project into $HOME_SIM"
    else
        write_project "$tmp"
        sudo ditto "$tmp" "$HOME_SIM"
        sudo chown -R "$USER_SIM:staff" "$HOME_SIM/src" "$HOME_SIM/Documents"
    fi
    rm -rf "$tmp"

    if ! grep -qF "$BEGIN_MARK" "$SSH_CONFIG" 2>/dev/null; then
        local block
        block="$(printf '%s\n' "" "$BEGIN_MARK" \
            "Host workmac-test" \
            "    HostName localhost" \
            "    User $USER_SIM" \
            "    IdentityFile ~/.ssh/remote_test" \
            "    IdentitiesOnly yes" \
            "    UserKnownHostsFile ~/.ssh/known_hosts_remote_test" \
            "    StrictHostKeyChecking accept-new" \
            "    ConnectTimeout 5" \
            "$END_MARK")"
        if [ "$DRY_RUN" = true ]; then echo "[dry] append to $SSH_CONFIG:"; echo "$block"
        else echo "$block" >> "$SSH_CONFIG"; fi
    fi

    run sudo launchctl enable system/com.openssh.sshd
    run sudo launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist
    echo "Done. Try: ssh workmac-test whoami"
}

down() {
    echo "Removing the stand-in work Mac (asks for your password)..."
    if command -v remote >/dev/null 2>&1; then run remote workmac-test unmount >/dev/null 2>&1 || true; fi
    if remote_login_on; then
        run sudo launchctl bootout system/com.openssh.sshd || true
    fi
    run sudo launchctl disable system/com.openssh.sshd
    run sudo rm -f "$CONF"
    if dscl . -read /Groups/com.apple.access_ssh >/dev/null 2>&1; then
        run sudo dseditgroup -o edit -d "$USER_SIM" -t user com.apple.access_ssh 2>/dev/null || true
    fi
    if id "$USER_SIM" >/dev/null 2>&1; then
        run sudo sysadminctl -deleteUser "$USER_SIM"
    fi
    if grep -qF "$BEGIN_MARK" "$SSH_CONFIG" 2>/dev/null; then
        if [ "$DRY_RUN" = true ]; then echo "[dry] remove the workmac-test block from $SSH_CONFIG"
        else
            local tmp
            tmp="$(mktemp)"
            awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
                $0 == b { skip = 1; next }
                $0 == e { skip = 0; next }
                !skip' "$SSH_CONFIG" > "$tmp"
            cat "$tmp" > "$SSH_CONFIG"   # keeps the file's owner and mode
            rm -f "$tmp"
        fi
    fi
    run rm -f "$KEY" "$KEY.pub" "$HOME/.ssh/known_hosts_remote_test"
    echo "Done. Remote Login is off."
}

case "$ACTION" in
up) up ;;
down) down ;;
*) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
```

- [ ] **Step 2: Lint and dry-run**

Run: `chmod +x scripts/remote-test-host.sh && shellcheck -x -S style scripts/remote-test-host.sh && scripts/remote-test-host.sh up --dry-run`
Expected: shellcheck silent; the dry run lists the `sysadminctl`, `dseditgroup`, `050-remote-test.conf` content (three settings), `ssh-keygen`, `install`, the `Host workmac-test` block, and the two `launchctl` lines. Nothing is created (`id workmac-sim` still fails).

- [ ] **Step 3: Martin runs `up`** — stop and ask him to run, in his own terminal:

```
cd ~/Development/dotfiles && scripts/remote-test-host.sh up
```

- [ ] **Step 4: Verify the test host**

Run each; compare:
```
ssh workmac-test whoami                                   # workmac-sim
ssh workmac-test 'command -v cmake || echo NO-CMAKE'      # NO-CMAKE  (the bare PATH)
ssh workmac-test 'cat src/hello/flags.txt'                # Build flags: -Wall -Wextra
ssh workmac-test 'git -C src/hello status --short'        # " M README.md"
ssh workmac-test 'cat Documents/secret.txt'               # fails: Operation not permitted
ssh -o BatchMode=yes -o PasswordAuthentication=yes -o PubkeyAuthentication=no workmac-sim@localhost true   # fails: Permission denied
LAN=$(ipconfig getifaddr en0); ssh -o BatchMode=yes -i ~/.ssh/remote_test workmac-sim@"$LAN" true          # fails: Permission denied
```
Expected as commented. If the privacy check *succeeds*, Remote Login's "full disk access for remote users" is on: note it (test 8 will skip). If the LAN login succeeds, decision 4 is wrong: stop and report.

- [ ] **Step 5: `down` and `up` once more**, to prove `down` is complete (Martin runs both). After `down`: `id workmac-sim` fails, `ls /etc/ssh/sshd_config.d/` shows only `100-macos.conf`, `grep -c workmac-test ~/.ssh/config` is 0, `launchctl print system/com.openssh.sshd` fails. After the second `up`, Step 4's first line works again.

- [ ] **Step 6: Commit**

```bash
git add scripts/remote-test-host.sh
git commit -m "remote-test-host.sh: a stand-in work Mac on this Mac (user workmac-sim, localhost-only SSH)"
```

---

### Task 2: `remote` — runner, status and the read subcommands

**Files:**
- Create: `remote/.local/bin/remote`
- Create: `scripts/test-remote.sh`

**Interfaces:**
- Consumes: alias `workmac-test` and the sample files from Task 1.
- Produces: `remote <host> status|ls|cat|grep|find|git`; env `REMOTE_SSH_CONFIG`, `REMOTE_MOUNT_ROOT`, `REMOTE_TIMEOUT`; in `remote`: functions `refuse`, `check_path`, `q`, `run_remote`, `is_mounted`, `with_timeout`, variable `MP`. In the test: helpers `ok`, `bad`, `expect_rc`, `expect_has`, `expect_lacks`, `R` (runs the repo's `remote`), `RD` (runs it against the dead alias), groups `t_status`, `t_read`, `t_refuse`, `t_git`, `t_hint`, selectable by name.

- [ ] **Step 1: Write the test script** (`scripts/test-remote.sh`)

```bash
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
    [ "$rc" -ne 0 ] && ok "status: unreachable host fails" || bad "status: unreachable host exit 0"
    [ $(( $(date +%s) - start )) -le 7 ] && ok "status: ...within 7 s" || bad "status: took $(( $(date +%s) - start )) s"
    expect_has "status: says NOT reachable" "$out" "NOT reachable"
    out="$(R $H status 2>&1)"
    expect_has "status: test host reachable" "$out" "is reachable"
}

t_read() {
    local out
    out="$(R $H ls src/hello 2>&1)";            expect_has "ls" "$out" "hello.cpp"
    out="$(R $H cat src/hello/hello.cpp 2>&1)"; expect_has "cat" "$out" "hello from workmac-sim"
    out="$(R $H cat src/hello/hello.cpp 1:1 2>&1)"
    [ "$out" = "#include <iostream>" ] && ok "cat range 1:1" || bad "cat range 1:1 gave [$out]"
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
    [ -z "$out" ] && ok "injection: nothing ran" || bad "injection: created $out"
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
```

- [ ] **Step 2: Run it to see it fail**

Run: `chmod +x scripts/test-remote.sh && scripts/test-remote.sh status read refuse git hint`
Expected: FAIL lines throughout (the `remote` file doesn't exist yet: "No such file or directory").

- [ ] **Step 3: Write `remote/.local/bin/remote`** (runner, status, read subcommands; mount/build come in Tasks 3–4)

```bash
#!/usr/bin/env bash
#
# remote -- the safe ways to work on another machine over SSH. Every
# subcommand is read-only or a build/test, which is why Claude may run
# `remote` without asking (doc/remote-machine.md). Anything else on the remote
# is plain `ssh <host> '...'`, which asks.
#
#   remote <host> status                  reachable? mounted? mount healthy?
#   remote <host> mount                   mount the remote home at ~/remote/<host>
#   remote <host> unmount                 unmount, forcing it if the remote is gone
#   remote <host> ls   <path>
#   remote <host> cat  <file> [first:last]
#   remote <host> grep [-i] [-w] [-l] [--include <glob>] [--] <pattern> <path>
#   remote <host> find <path> [-name <glob>] [-type f|d]
#   remote <host> git  <path> status|diff|log|show|branch [args]
#   remote <host> build <dir> [--preset P | --build-dir D]
#   remote <host> test  <dir> [--preset P | --build-dir D]
#
# <host> is an ~/.ssh/config alias. Relative paths are from the remote home,
# which is what ~/remote/<host> shows. A path may not start with '-' (write
# ./-name). Exit codes: the remote command's own; 2 for a refused or malformed
# request (nothing was run); 255 when the host can't be reached.
#
# Environment: REMOTE_SSH_CONFIG (an ssh config file instead of
# ~/.ssh/config), REMOTE_MOUNT_ROOT (default ~/remote), REMOTE_TIMEOUT (seconds
# a mount check or an unmount may take; default 5).
set -uo pipefail

MOUNT_ROOT="${REMOTE_MOUNT_ROOT:-$HOME/remote}"
TIMEOUT="${REMOTE_TIMEOUT:-5}"
SSH=(ssh -n -o BatchMode=yes -o ConnectTimeout=5)
SSHFS_CFG=()
if [ -n "${REMOTE_SSH_CONFIG:-}" ]; then
    SSH+=(-F "$REMOTE_SSH_CONFIG")
    SSHFS_CFG=(-F "$REMOTE_SSH_CONFIG")
fi

usage() { sed -n '8,17p' "$0" | sed 's/^# \{0,1\}//'; }
refuse() { echo "remote: $*" >&2; exit 2; }
q() { printf '%q' "$1"; }

# A time limit for things that can hang on a dead mount. perl ships with macOS
# and Linux; its alarm survives exec. A timeout exits 142.
with_timeout() { perl -e 'alarm shift; exec @ARGV' "$TIMEOUT" "$@"; }

# Refuse a path that could be read as an option. Runs in this shell (not in a
# $(...)), so the refusal really exits.
check_path() {
    case "$1" in
        "") refuse "empty path" ;;
        -*) refuse "a path may not start with '-': $1 (write ./$1)" ;;
    esac
}

# Commands over SSH don't load the login shell's setup, so Homebrew's tools
# (cmake above all) would be missing from PATH. Add its folders where they
# exist, instead of depending on the remote's shell config.
# shellcheck disable=SC2016  # expanded on the remote
PRELUDE='for d in /usr/local/bin /opt/homebrew/bin; do [ -d "$d" ] && PATH="$d:$PATH"; done; export PATH;'

# Run a command on the host. Output (stdout and stderr together) shows as it
# arrives and is kept, so a failure can be explained afterwards.
run_remote() {
    local out rc
    out="$(mktemp)"
    "${SSH[@]}" "$HOST" "$PRELUDE $1" 2>&1 | tee "$out"
    rc=${PIPESTATUS[0]}
    if [ "$rc" -eq 255 ]; then
        echo "remote: could not reach $HOST over ssh (is it on and connected?)" >&2
    elif grep -q 'Operation not permitted' "$out"; then
        echo "remote: \"Operation not permitted\" on a Mac remote is usually its privacy protection of ~/Documents, ~/Desktop and ~/Downloads over SSH. On the remote: System Settings > General > Sharing > Remote Login (i) > Allow full disk access for remote users." >&2
    fi
    rm -f "$out"
    return "$rc"
}

is_mounted() {
    mount | awk -v mp="$MP" '{ for (i = 1; i < NF; i++) if ($i == "on" && $(i + 1) == mp) found = 1 }
                             END { exit !found }'
}

cmd_status() {
    local rc=0
    if "${SSH[@]}" "$HOST" true 2>/dev/null; then
        echo "host: $HOST is reachable"
    else
        echo "host: $HOST is NOT reachable over ssh"; rc=1
    fi
    if is_mounted; then
        if with_timeout ls "$MP" >/dev/null 2>&1; then
            echo "mount: $MP (healthy)"
        else
            echo "mount: $MP is mounted but NOT responding -- run: remote $HOST unmount"; rc=1
        fi
    else
        echo "mount: not mounted (remote $HOST mount)"
    fi
    return "$rc"
}

cmd_ls() {
    [ $# -eq 1 ] || refuse "usage: remote $HOST ls <path>"
    check_path "$1"
    run_remote "ls -la $(q "$1")"
}

cmd_cat() {
    { [ $# -ge 1 ] && [ $# -le 2 ]; } || refuse "usage: remote $HOST cat <file> [first:last]"
    check_path "$1"
    if [ $# -eq 2 ]; then
        case "$2" in
            *[!0-9:]* | :* | *: | *:*:*) refuse "a range is first:last, e.g. 10:40" ;;
            *:*) ;;
            *) refuse "a range is first:last, e.g. 10:40" ;;
        esac
        run_remote "sed -n $(q "${2%%:*},${2##*:}p") $(q "$1")"
    else
        run_remote "cat $(q "$1")"
    fi
}

cmd_grep() {
    local opts="" pattern="" path="" npos=0 only_pos=0
    while [ $# -gt 0 ]; do
        if [ "$only_pos" -eq 0 ]; then
            case "$1" in
                --) only_pos=1; shift; continue ;;
                -i | -w | -l) opts="$opts $1"; shift; continue ;;
                --include) [ $# -ge 2 ] || refuse "--include needs a glob"
                    opts="$opts --include=$(q "$2")"; shift 2; continue ;;
                --include=*) opts="$opts --include=$(q "${1#--include=}")"; shift; continue ;;
                -*) refuse "grep option not allowed: $1 (allowed: -i -w -l --include; use -- before a pattern starting with -)" ;;
            esac
        fi
        case "$npos" in
            0) pattern="$1" ;;
            1) check_path "$1"; path="$1" ;;
            *) refuse "too many arguments: $1" ;;
        esac
        npos=$((npos + 1)); shift
    done
    [ "$npos" -eq 2 ] || refuse "usage: remote $HOST grep [-i] [-w] [-l] [--include <glob>] [--] <pattern> <path>"
    run_remote "grep -rnI$opts -e $(q "$pattern") $(q "$path")"
}

cmd_find() {
    [ $# -ge 1 ] || refuse "usage: remote $HOST find <path> [-name <glob>] [-type f|d]"
    check_path "$1"
    local path="$1" expr=""
    shift
    while [ $# -gt 0 ]; do
        case "$1" in
            -name) [ $# -ge 2 ] || refuse "-name needs a glob"; expr="$expr -name $(q "$2")"; shift 2 ;;
            -type) case "${2:-}" in f | d) expr="$expr -type $2" ;; *) refuse "-type is f or d" ;; esac; shift 2 ;;
            *) refuse "find option not allowed: $1 (allowed: -name <glob>, -type f|d)" ;;
        esac
    done
    run_remote "find $(q "$path")$expr"
}

cmd_git() {
    [ $# -ge 2 ] || refuse "usage: remote $HOST git <path> status|diff|log|show|branch [args]"
    check_path "$1"
    local path="$1" sub="$2" args="" a safe
    shift 2
    case "$sub" in
        status | diff | log | show)
            for a in "$@"; do
                case "$a" in
                    --ext-diff | --textconv | --output | --output=* | -c | -c* | --exec* | --upload-pack* | --open-files-in-pager* | -O*)
                        refuse "git option not allowed: $a" ;;
                esac
                args="$args $(q "$a")"
            done ;;
        branch)
            for a in "$@"; do
                case "$a" in
                    -a | -r | -v | -vv | --all | --remotes | --list | --show-current | --verbose) args="$args $a" ;;
                    *) refuse "git branch: only listing is allowed (-a -r -v -vv --list --show-current), not: $a" ;;
                esac
            done ;;
        *) refuse "git: only status, diff, log, show and branch are allowed, not: $sub" ;;
    esac
    safe=" --no-ext-diff --no-textconv"
    case "$sub" in status | branch) safe="" ;; esac
    run_remote "git -c core.fsmonitor=false -C $(q "$path") --no-pager $sub$safe$args"
}

[ $# -ge 2 ] || { usage; exit 2; }
HOST="$1"; SUB="$2"; shift 2
case "$HOST" in "" | -* | */*) refuse "not a host alias: $HOST" ;; esac
MP="$MOUNT_ROOT/$HOST"

case "$SUB" in
    status) [ $# -eq 0 ] || refuse "usage: remote $HOST status"; cmd_status ;;
    ls) cmd_ls "$@" ;;
    cat) cmd_cat "$@" ;;
    grep) cmd_grep "$@" ;;
    find) cmd_find "$@" ;;
    git) cmd_git "$@" ;;
    *) refuse "unknown subcommand: $SUB (see: remote with no arguments)" ;;
esac
```

- [ ] **Step 4: Run the tests**

Run: `chmod +x remote/.local/bin/remote && scripts/test-remote.sh status read refuse git hint`
Expected: every line `ok` (or `skip` for the hint if Task 1 noted full disk access); last line `All remote checks passed`.

- [ ] **Step 5: Lint**

Run: `scripts/lint.sh shellcheck`
Expected: `shellcheck: clean` (the new files are tracked after `git add`; run `git add -N remote scripts/test-remote.sh` first so lint sees them).

- [ ] **Step 6: Commit**

```bash
git add remote/.local/bin/remote scripts/test-remote.sh
git commit -m "remote: status and the read-only subcommands (ls, cat, grep, find, git), with refusals; test-remote.sh"
```

---

### Task 3: `remote` — mount and unmount

**Files:**
- Modify: `remote/.local/bin/remote` (add `cmd_mount`, `cmd_unmount`, dispatch)
- Modify: `scripts/test-remote.sh` (add `t_mount`)

**Interfaces:**
- Consumes: `is_mounted`, `with_timeout`, `MP`, `SSHFS_CFG`, `SSH`, `refuse` (Task 2).
- Produces: `remote <host> mount|unmount`; mounted tree at `$MP`.

- [ ] **Step 1: Add the test group** to `scripts/test-remote.sh`, before the `ALL=` line:

```bash
t_mount() {
    local mp="$HOME/remote/$H" out start pid
    R $H unmount >/dev/null 2>&1
    expect_rc "mount" 0 R $H mount
    mount | grep -qF " on $mp " && ok "mount: in the mount table" || bad "mount: not in the mount table"
    out="$(R $H status 2>&1)"; expect_has "status: healthy" "$out" "(healthy)"
    out="$(R $H mount 2>&1)"; expect_has "mount again: says so" "$out" "already mounted"
    out="$(cat "$mp/src/hello/hello.cpp" 2>&1)"; expect_has "read through the mount" "$out" "hello from workmac-sim"
    out="$(cat "$mp/src/hello/with space.txt" 2>&1)"; expect_has "mount: path with a space" "$out" "spaced out"
    printf 'edited through the mount %s\n' "$$" > "$mp/src/hello/notes.txt"
    out="$(R $H cat src/hello/notes.txt 2>&1)"; expect_has "edit through the mount lands remotely" "$out" "edited through the mount $$"
    rm -f "$mp/src/hello/notes.txt"
    expect_rc "unmount" 0 R $H unmount
    mount | grep -qF " on $mp " && bad "unmount: still mounted" || ok "unmount: gone from the mount table"
    [ -e "$mp" ] && bad "unmount: $mp left behind" || ok "unmount: folder removed"

    # Review focus 4: a leftover empty folder
    mkdir -p "$mp"
    out="$(R $H status 2>&1)"; expect_has "leftover folder: status says not mounted" "$out" "not mounted"
    expect_rc "leftover folder: unmount tidies" 0 R $H unmount
    [ -e "$mp" ] && bad "leftover folder: still there" || ok "leftover folder: removed"
    # Review focus 3: a folder that isn't empty
    mkdir -p "$mp"; touch "$mp/mine.txt"
    expect_rc "non-empty folder: mount refuses" 2 R $H mount
    [ -f "$mp/mine.txt" ] && ok "non-empty folder: left alone" || bad "non-empty folder: file gone"
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
    [ "$rc" -ne 0 ] && ok "dead mount: status fails" || bad "dead mount: status exit 0"
    expect_has "dead mount: status says so" "$out" "NOT"
    [ $(( $(date +%s) - start )) -le 15 ] && ok "dead mount: status within 15 s" || bad "dead mount: status took $(( $(date +%s) - start )) s"
    start=$(date +%s)
    expect_rc "dead mount: unmount" 0 env "$RR" "$REMOTE" remote-test-relay unmount
    [ $(( $(date +%s) - start )) -le 20 ] && ok "dead mount: unmount within 20 s" || bad "dead mount: unmount took $(( $(date +%s) - start )) s"
    mount | grep -qF " on $HOME/remote/remote-test-relay " && bad "dead mount: still mounted" || ok "dead mount: gone"
}
```

- [ ] **Step 2: Run it to see it fail**

Run: `scripts/test-remote.sh mount`
Expected: FAIL on "mount" with `remote: unknown subcommand: mount`.

- [ ] **Step 3: Add mount and unmount to `remote`**, after `cmd_status`:

```bash
cmd_mount() {
    command -v sshfs >/dev/null 2>&1 ||
        refuse "sshfs is not installed (macOS: brew install --cask macos-fuse-t/cask/fuse-t-sshfs)"
    if is_mounted; then echo "already mounted at $MP"; return 0; fi
    if [ -d "$MP" ] && [ -n "$(ls -A "$MP" 2>/dev/null)" ]; then
        refuse "$MP exists and isn't empty; move its contents away first"
    fi
    "${SSH[@]}" "$HOST" true 2>/dev/null ||
        { echo "remote: could not reach $HOST over ssh (is it on and connected?)" >&2; return 255; }
    mkdir -p "$MP"
    if sshfs ${SSHFS_CFG[@]+"${SSHFS_CFG[@]}"} "$HOST:" "$MP" \
        -o "volname=$HOST,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,BatchMode=yes,ConnectTimeout=5"; then
        echo "mounted $HOST's home at $MP"
    else
        rmdir "$MP" 2>/dev/null
        echo "remote: sshfs could not mount $HOST" >&2; return 1
    fi
}

cmd_unmount() {
    if ! is_mounted; then
        rmdir "$MP" 2>/dev/null
        echo "not mounted"; return 0
    fi
    if command -v fusermount >/dev/null 2>&1; then
        with_timeout fusermount -u "$MP" 2>/dev/null
    else
        with_timeout umount "$MP" 2>/dev/null ||
            with_timeout diskutil unmount force "$MP" >/dev/null 2>&1 ||
            with_timeout umount -f "$MP" 2>/dev/null
    fi
    if is_mounted; then
        echo "remote: could not unmount $MP; try: diskutil unmount force $MP" >&2; return 1
    fi
    rmdir "$MP" 2>/dev/null
    echo "unmounted $MP"
}
```

and in the dispatch `case`, after `status`:

```bash
    mount) [ $# -eq 0 ] || refuse "usage: remote $HOST mount"; cmd_mount ;;
    unmount) [ $# -eq 0 ] || refuse "usage: remote $HOST unmount"; cmd_unmount ;;
```

- [ ] **Step 4: Run the tests**

Run: `scripts/test-remote.sh mount && scripts/test-remote.sh status read refuse git hint`
Expected: all `ok`. If the dead-mount status takes longer than 15 s, `REMOTE_TIMEOUT` handling is wrong (it should give up after 5 s): debug, don't loosen the test.

- [ ] **Step 5: Lint and commit**

```bash
scripts/lint.sh shellcheck
git add remote/.local/bin/remote scripts/test-remote.sh
git commit -m "remote: mount and unmount (FUSE-T sshfs), with dead-mount handling"
```

---

### Task 4: `remote` — build and test

**Files:**
- Modify: `remote/.local/bin/remote` (add `parse_build_args`, `cmd_build`, `cmd_test`, dispatch)
- Modify: `scripts/test-remote.sh` (add `t_build`)

**Interfaces:**
- Consumes: `run_remote`, `check_path`, `q`, `refuse`, `cmd_mount`/`cmd_unmount` (via `R`).
- Produces: `remote <host> build|test <dir> [--preset P | --build-dir D]`.

- [ ] **Step 1: Add the test group** before `ALL=`:

```bash
t_build() {
    local out mp="$HOME/remote/$H"
    out="$(ssh -n $H 'command -v cmake || echo NO-CMAKE' 2>&1)"
    expect_has "bare PATH has no cmake (the problem the prelude fixes)" "$out" "NO-CMAKE"
    expect_rc "build with presets" 0 R $H build src/hello
    out="$(R $H ls src/hello/build/debug 2>&1)"; expect_has "build: binary in the preset's folder" "$out" "hello"
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
    [ "$rc" -ne 0 ] && ok "test fails after the edit (the build saw it)" || bad "test passed after the edit"
    # A broken build exits non-zero
    printf 'this is not C++;\n' >> "$mp/src/hello/hello.cpp"
    out="$(R $H build src/hello 2>&1)"; rc=$?
    [ "$rc" -ne 0 ] && ok "broken build exits non-zero" || bad "broken build exit 0"
    ssh -n $H 'git -C src/hello checkout -- hello.cpp'
    expect_rc "restored: build passes again" 0 R $H build src/hello
    expect_rc "restored: test passes again" 0 R $H test src/hello
    R $H unmount >/dev/null
}
```

- [ ] **Step 2: Run it to see it fail**

Run: `scripts/test-remote.sh build`
Expected: "bare PATH" ok; the rest FAIL with `remote: unknown subcommand: build`.

- [ ] **Step 3: Add build and test to `remote`**, after `cmd_git`:

```bash
# Set DIR, PRESET and BDIR from: <dir> [--preset P | --build-dir D]
parse_build_args() {
    [ $# -ge 1 ] || refuse "usage: remote $HOST $SUB <dir> [--preset P | --build-dir D]"
    check_path "$1"
    DIR="$1"; PRESET=""; BDIR=""
    shift
    while [ $# -gt 0 ]; do
        case "$1" in
            --preset) [ $# -ge 2 ] || refuse "--preset needs a name"; PRESET="$2"; shift 2 ;;
            --build-dir) [ $# -ge 2 ] || refuse "--build-dir needs a folder"; check_path "$2"; BDIR="$2"; shift 2 ;;
            *) refuse "$SUB option not allowed: $1 (allowed: --preset P, --build-dir D)" ;;
        esac
    done
    if [ -n "$PRESET" ] && [ -n "$BDIR" ]; then refuse "use --preset or --build-dir, not both"; fi
}

# Both run on the remote as `sh -c '<script>' remote "$DIR" "$PRESET" "$BDIR"`.
# With a CMakePresets.json (and no --build-dir) they use presets, defaulting to
# the first one CMake lists; otherwise a build folder (default: build).
# shellcheck disable=SC2016  # expanded on the remote
BUILD_SH='cd "$1" || exit 1
if [ -z "$3" ] && [ -f CMakePresets.json ]; then
    p="$2"
    [ -n "$p" ] || p="$(cmake --list-presets=build 2>/dev/null | sed -n "s/^  \"\([^\"]*\)\".*/\1/p" | head -n 1)"
    [ -n "$p" ] || { echo "remote: CMakePresets.json has no build preset" >&2; exit 2; }
    if cmake --list-presets=configure 2>/dev/null | grep -q "^  \"$p\""; then
        cmake --preset "$p" || exit $?
    fi
    cmake --build --preset "$p"
else
    b="${3:-build}"
    [ -f "$b/CMakeCache.txt" ] || cmake -S . -B "$b" || exit $?
    cmake --build "$b"
fi'
# shellcheck disable=SC2016  # expanded on the remote
TEST_SH='cd "$1" || exit 1
if [ -z "$3" ] && [ -f CMakePresets.json ]; then
    p="$2"
    [ -n "$p" ] || p="$(ctest --list-presets 2>/dev/null | sed -n "s/^  \"\([^\"]*\)\".*/\1/p" | head -n 1)"
    [ -n "$p" ] || { echo "remote: CMakePresets.json has no test preset" >&2; exit 2; }
    ctest --preset "$p" --output-on-failure
else
    ctest --test-dir "${3:-build}" --output-on-failure
fi'

cmd_build() {
    parse_build_args "$@"
    run_remote "sh -c $(q "$BUILD_SH") remote $(q "$DIR") $(q "$PRESET") $(q "$BDIR")"
}

cmd_test() {
    parse_build_args "$@"
    run_remote "sh -c $(q "$TEST_SH") remote $(q "$DIR") $(q "$PRESET") $(q "$BDIR")"
}
```

and in the dispatch, after `git`:

```bash
    build) cmd_build "$@" ;;
    test) cmd_test "$@" ;;
```

- [ ] **Step 4: Run all groups so far**

Run: `scripts/test-remote.sh status read refuse git hint mount build`
Expected: all `ok` (hint may `skip`). The build lines show CMake output, since `run_remote` streams it.

- [ ] **Step 5: Lint and commit**

```bash
scripts/lint.sh shellcheck
git add remote/.local/bin/remote scripts/test-remote.sh
git commit -m "remote: build and test (CMake presets or a build folder), configuring when needed"
```

---

### Task 5: Installer, permissions and verify

**Files:**
- Create: `scripts/claude-remote-permissions.sh`
- Modify: `scripts/test-remote.sh` (add `t_perms`)
- Modify: `scripts/packages.sh` (`PACKAGES_DARWIN` += `remote`)
- Modify: `install_darwin.sh` (tap + trust `macos-fuse-t/cask`; casks `fuse-t`, `macos-fuse-t/cask/fuse-t-sshfs`; `mkdir -p "$HOME/.local/bin"` before stow; run the permissions script)
- Modify: `scripts/verify.sh` (`~/.local/bin` real directory; darwin: sshfs installed, both rules present)
- Modify: `doc/tools.md` (row, same commit as the installer change)

**Interfaces:**
- Produces: `scripts/claude-remote-permissions.sh [settings.json]` (default `~/.claude/settings.json`); exit 1 and file untouched on invalid JSON.

- [ ] **Step 1: Add the test group** before `ALL=`:

```bash
t_perms() {
    local S="$DOTFILES_DIR/scripts/claude-remote-permissions.sh" f="$TMP/settings.json" out
    rm -f "$f"
    expect_rc "perms: creates a missing file" 0 "$S" "$f"
    out="$(jq -c '.permissions.allow' "$f")"
    [ "$out" = '["Bash(remote:*)","Read(~/remote/**)"]' ] && ok "perms: both rules" || bad "perms: got $out"
    printf '{"model":"x","permissions":{"allow":["Bash(ls:*)"],"deny":["Read(./.env)"]}}' > "$f"
    expect_rc "perms: existing file" 0 "$S" "$f"
    expect_rc "perms: second run" 0 "$S" "$f"
    out="$(jq -c '[.model, .permissions.allow, .permissions.deny]' "$f")"
    [ "$out" = '["x",["Bash(ls:*)","Bash(remote:*)","Read(~/remote/**)"],["Read(./.env)"]]' ] &&
        ok "perms: keeps the rest, adds each rule once" || bad "perms: got $out"
    printf '{ not json' > "$f"
    expect_rc "perms: invalid JSON exits 1" 1 "$S" "$f"
    [ "$(cat "$f")" = '{ not json' ] && ok "perms: invalid file untouched" || bad "perms: invalid file changed"
}
```

- [ ] **Step 2: Run it to see it fail**

Run: `scripts/test-remote.sh perms`
Expected: FAIL ("No such file or directory" for the script).

- [ ] **Step 3: Write `scripts/claude-remote-permissions.sh`**

```bash
#!/usr/bin/env bash
#
# Add the two Claude Code permission rules `remote` relies on
# (doc/remote-machine.md) to a settings file: run any `remote` subcommand, and
# read files under ~/remote, without a prompt. Adds only what is missing and
# keeps everything else; a second run changes nothing. Edits on the mount and
# raw `ssh` keep asking.
#
# Usage: scripts/claude-remote-permissions.sh [settings.json]
#        (default: ~/.claude/settings.json)
set -euo pipefail

FILE="${1:-$HOME/.claude/settings.json}"
command -v jq >/dev/null 2>&1 || { echo "jq is required (brew install jq)" >&2; exit 1; }
mkdir -p "$(dirname "$FILE")"
[ -s "$FILE" ] || echo '{}' > "$FILE"
if ! jq -e 'type == "object"' "$FILE" >/dev/null 2>&1; then
    echo "$FILE is not a JSON object; leaving it alone" >&2
    exit 1
fi
tmp="$(mktemp "$FILE.XXXXXX")"
jq '(.permissions.allow // []) as $have
    | .permissions.allow = $have + (["Bash(remote:*)", "Read(~/remote/**)"]
        | map(select(. as $r | ($have | index([$r])) == null)))' "$FILE" > "$tmp"
cat "$tmp" > "$FILE"   # keeps the file's owner and mode
rm -f "$tmp"
```

- [ ] **Step 4: Run the perms tests**

Run: `chmod +x scripts/claude-remote-permissions.sh && scripts/test-remote.sh perms`
Expected: all `ok`.

- [ ] **Step 5: Wire it into the installer, packages, verify and tools.md**

`scripts/packages.sh`: append `remote` to `PACKAGES_DARWIN` (after `claude`).

`install_darwin.sh`:
- after `run brew tap dimentium/autoraise`: `run brew tap macos-fuse-t/homebrew-cask`
- in the trust loop: `for tap in nikitabobko/tap FelixKratz/formulae dimentium/autoraise macos-fuse-t/cask; do`
- `BREW_CASKS`, after `raycast`:
```bash
    # sshfs for `remote <host> mount` (doc/remote-machine.md): FUSE-T, which
    # needs no kernel extension. Both are .pkg installers and ask for the
    # password.
    fuse-t
    macos-fuse-t/cask/fuse-t-sshfs
```
- the pre-stow `mkdir` line becomes `run mkdir -p "$HOME/.config" "$HOME/.config/fastfetch" "$HOME/.claude" "$HOME/.local/bin"`, and its comment gains: "and ~/.local/bin, where the `remote` package links its command."
- after the btop seed block:
```bash
# Claude Code may run `remote` and read ~/remote without asking
# (doc/remote-machine.md). settings.json is per machine, so it isn't stowed.
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[DRY]${NC} scripts/claude-remote-permissions.sh"
else
    "$DOTFILES_DIR/scripts/claude-remote-permissions.sh" ||
        FAILURES+=("claude-remote-permissions.sh failed; Claude will ask before each remote command")
fi
```
(check the installer's dry-run colour variable name with `grep -n 'DRY' install_darwin.sh | head` and match it.)

`scripts/verify.sh`:
- find the real-directory check (`grep -n 'real directory' scripts/verify.sh`) and add `$HOME/.local/bin` to its list.
- in the darwin block (before `echo; echo "Cannot be checked from a script`):
```bash
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
```

`doc/tools.md`, in "Git and code", after the `gh` row:
```
| remote + FUSE-T sshfs | Work on another machine over SSH: mount, read, search, build, test (`doc/remote-machine.md`) | ✓ | – | – | – |
```

- [ ] **Step 6: Apply on this Mac and verify**

Run:
```
stow -t ~ remote && command -v remote
scripts/claude-remote-permissions.sh && jq -c .permissions.allow ~/.claude/settings.json
./install_darwin.sh --dry-run 2>&1 | grep -iE 'fuse|remote-permissions|local/bin'
scripts/verify.sh 2>&1 | tail -3
scripts/lint.sh
```
Expected: `~/.local/bin/remote`; the allow list contains both rules; the dry run shows the tap, the casks being installed or already installed, the `.local/bin` mkdir and the permissions line; verify ends `All checks passed`; lint clean.

- [ ] **Step 7: Commit**

```bash
git add scripts/claude-remote-permissions.sh scripts/test-remote.sh scripts/packages.sh install_darwin.sh scripts/verify.sh doc/tools.md
git commit -m "remote: installed on macOS (FUSE-T sshfs, stow package), Claude permission rules, verify checks"
```

---

### Task 6: The skill

**Files:**
- Create: `claude/.claude/skills/remote-machine/SKILL.md`

**Interfaces:**
- Consumes: the `remote` command and the permission rules.

- [ ] **Step 1: Write the skill**

```markdown
---
name: remote-machine
description: Use when working with files, builds or tests on another machine over SSH (such as the offline work Mac), when the user names a remote host alias, or with paths under ~/remote/. Covers the `remote` command, the ~/remote/<host> mount, and what needs the user's approval. macOS and Linux only.
---

# Working on a remote machine

The files live on another machine, reached over SSH as an `~/.ssh/config`
alias (`<host>`). Use the `remote` command for everything it offers: it is
allowed without prompts because every subcommand is read-only or a
build/test. Full reference: `doc/remote-machine.md` in the dotfiles.

## Rules

1. **Start with `remote <host> status`.** If the host is not reachable, tell
   the user and stop: touching `~/remote/<host>` while the host is gone hangs.
   If it isn't mounted, run `remote <host> mount`.
2. **Find things on the remote:** `remote <host> grep`, `find`, `ls`. Never
   use the Grep or Glob tools on `~/remote/<host>`: searching through the
   mount is about 100 times slower than searching on the remote.
3. **Read with the Read tool** at `~/remote/<host>/<path>`, where `<path>` is
   what `remote` printed (paths are relative to the remote home, which is what
   the mount shows).
4. **Edit with Edit or Write on the mount.** Each edit asks the user. Never
   edit through `ssh <host> sed ...` or similar, which would skip that.
5. **Build and test with `remote <host> build <dir>` and `remote <host> test
   <dir>`.** The remote compiler is the truth. Ignore local C++ diagnostics on
   files under `~/remote/`: they use the wrong paths and the wrong headers.
6. **Anything else on the remote** (running a program, deleting, `git commit`)
   is `ssh <host> '...'`, which asks the user; say why before running it.
   Never install anything on the remote and never give it internet access.
7. **"Operation not permitted"** under `~/Documents`, `~/Desktop` or
   `~/Downloads` on a Mac remote is its privacy protection: tell the user the
   setting (Remote Login, "Allow full disk access for remote users"); don't
   look for a way around it.
8. **When done, `remote <host> unmount`**, and always before the remote is
   unplugged, sleeps or is shut down.

## The commands

| Command | Does |
|---|---|
| `remote <host> status` | reachable? mounted? mount healthy? |
| `remote <host> mount` / `unmount` | the remote home at `~/remote/<host>` |
| `remote <host> ls <path>` | list a folder |
| `remote <host> cat <file> [first:last]` | a file, or a range of its lines |
| `remote <host> grep [-i] [-w] [-l] [--include <glob>] [--] <pattern> <path>` | search (recursive, with line numbers) |
| `remote <host> find <path> [-name <glob>] [-type f\|d]` | find files |
| `remote <host> git <path> status\|diff\|log\|show\|branch` | read-only git |
| `remote <host> build <dir> [--preset P \| --build-dir D]` | CMake build (configures if needed) |
| `remote <host> test <dir> [--preset P \| --build-dir D]` | ctest |

Exit 2 means `remote` refused the request and ran nothing (the message says
why); 255 means the host could not be reached. A path may not start with `-`:
write `./-name`.
```

- [ ] **Step 2: Stow and check it loads**

Run: `stow -t ~ -R claude && ls ~/.claude/skills/remote-machine/SKILL.md`
Expected: the file is listed (through the stowed link).

- [ ] **Step 3: A fresh Claude uses it**

Run (from a scratch folder, so no project instructions interfere):
```
cd "$(mktemp -d)" && claude -p "On the remote machine workmac-test, what does src/hello/hello.cpp print? One line." \
    --output-format stream-json --verbose > /tmp/remote-skill-check.jsonl 2>&1; \
grep -o '"command":"[^"]*' /tmp/remote-skill-check.jsonl | head; tail -c 400 /tmp/remote-skill-check.jsonl
```
Expected: at least one `"command":"remote workmac-test ...` (status, cat or mount), no `"command":"ssh workmac-test ...`, and the result mentions `hello from workmac-sim`. If the skill wasn't picked up, sharpen its `description` (it decides triggering) and repeat; record what changed.

- [ ] **Step 4: Commit**

```bash
git add claude/.claude/skills/remote-machine/SKILL.md
git commit -m "Skill remote-machine: how Claude works on a remote machine with \`remote\` (model-invoked)"
```

---

### Task 7: Docs and CHANGELOG

**Files:**
- Create: `doc/remote-machine.md`
- Modify: `README.md` (one pointer near the other `doc/` pointers: `grep -n 'doc/aerospace-macos.md' README.md`)
- Modify: `CLAUDE.md` (packages: `remote`; the skill exception)
- Modify: `CHANGELOG.md` (entry at the top)

- [ ] **Step 1: Write `doc/remote-machine.md`**

```markdown
# Claude on a remote machine

Claude runs on this Mac; the files it should work with live on another Mac
(the offline work machine) that it reaches only over SSH. Claude finds, reads
and edits them, and runs the builds and tests there.

How it fits together:
- **`remote <host> ...`** (`remote/.local/bin/remote`): every safe operation
  on the remote. Claude may run it without asking, because each subcommand is
  read-only or a build/test.
- **The mount**: `remote <host> mount` shows the remote home at
  `~/remote/<host>` (FUSE-T sshfs), so Claude reads and edits with its own
  tools. Edits ask first.
- **The skill** (`claude/.claude/skills/remote-machine/SKILL.md`): when to use
  which. Claude picks it up by itself.
- **Everything else** on the remote is plain `ssh <host> '...'`, which asks.

Searching happens on the remote, never through the mount: measured on 2,252
files, 0.26 s over SSH against 35 s through the mount. The design and its
measurements: `doc/specs/2026-10-08-remote-machine-design.md`.

## Setting up

### This Mac

`./install_darwin.sh` does it: FUSE-T and its sshfs (two `.pkg` installers,
which ask for your password), the `remote` command (stow package `remote`),
and two rules in `~/.claude/settings.json`: `Bash(remote:*)` and
`Read(~/remote/**)`. `scripts/verify.sh` checks all three.

### The work Mac, once

1. **Remote Login:** System Settings > General > Sharing > Remote Login: on.
   Under (i), "Allow access for": only your user. Tick "Allow full disk access
   for remote users" only if the source lives under `~/Documents`, `~/Desktop`
   or `~/Downloads` (macOS blocks those over SSH otherwise).
2. **Your key:** on this Mac, `ssh-keygen -t ed25519 -f ~/.ssh/workmac`. Copy
   `~/.ssh/workmac.pub` to the work Mac (USB stick or AirDrop; it's offline)
   and append it to `~/.ssh/authorized_keys` there.
3. **A connection:** a Thunderbolt cable between the Macs makes a network by
   itself; the work Mac is then `<its-name>.local` (System Settings > General
   > Sharing shows the name). A USB-C Ethernet adapter, or a LAN without
   internet, works too.
4. **The alias**, in this Mac's `~/.ssh/config`:
   ```
   Host workmac
       HostName <its-name>.local
       User <your user there>
       IdentityFile ~/.ssh/workmac
       IdentitiesOnly yes
       ConnectTimeout 5
   ```
   Check: `remote workmac status`.

Nothing is installed on the work Mac. Builds use its own Xcode command line
tools and Homebrew `cmake`; `remote` adds Homebrew's folders to PATH itself,
because commands over SSH don't load the shell's setup.

## Commands

| Command | Does |
|---|---|
| `remote <host> status` | reachable? mounted? mount healthy? |
| `remote <host> mount` / `unmount` | the remote home at `~/remote/<host>`; `unmount` forces it if the remote is gone |
| `remote <host> ls <path>` | `ls -la` |
| `remote <host> cat <file> [first:last]` | a file, or a range of lines |
| `remote <host> grep [-i] [-w] [-l] [--include <glob>] [--] <pattern> <path>` | recursive search with line numbers |
| `remote <host> find <path> [-name <glob>] [-type f\|d]` | find files |
| `remote <host> git <path> status\|diff\|log\|show\|branch [args]` | read-only git |
| `remote <host> build <dir> [--preset P \| --build-dir D]` | CMake build; configures first if needed |
| `remote <host> test <dir> [--preset P \| --build-dir D]` | ctest, with output on failure |

Paths are relative to the remote home. Exit 2: refused, nothing ran (the
message says why). Exit 255: the host can't be reached. Options that could run
a program or write (`grep --pre`, `find -exec`/`-delete`, `git push`/`commit`,
`--ext-diff`, `--output`) are refused.

## Troubleshooting

- **Anything under `~/remote/<host>` hangs:** the remote went away while
  mounted. `remote <host> status` reports it; `remote <host> unmount` clears it
  (forcing it if needed). Unmount before unplugging or sleeping the remote.
- **"Operation not permitted":** macOS privacy protection on the remote; see
  step 1 above.
- **`cmake: command not found`:** the remote's cmake is somewhere other than
  `/opt/homebrew/bin` or `/usr/local/bin`. Use `ssh <host> 'command -v cmake'`
  from an interactive login to find it, and add that folder to `PRELUDE` in
  `remote`.
- **Red C++ errors in files under `~/remote/`:** expected and wrong; the
  remote build is the truth.

## Practising on this Mac

`scripts/remote-test-host.sh up` (asks for your password) creates a stand-in
work Mac: user `workmac-sim`, reached as `remote workmac-test`, with a small
CMake project in `src/hello`. SSH accepts only that user, only from this Mac,
only with its key. `scripts/test-remote.sh` runs the full test suite against
it. `scripts/remote-test-host.sh down` removes it all and turns Remote Login
off. `up` refuses if Remote Login is already on.
```

- [ ] **Step 2: README, CLAUDE.md, CHANGELOG**

README, after the AeroSpace doc pointer line:
```
- **Claude on a remote machine**: work on another Mac over SSH with `remote <host>` and a mount — see [doc/remote-machine.md](doc/remote-machine.md)
```

CLAUDE.md, in "Cross-platform with per-OS configs" or after the `claude` package bullet:
```
- **remote**: `~/.local/bin/remote`, the safe operations on a remote machine
  over SSH (mount with FUSE-T sshfs, read, search, read-only git, build,
  test). Claude may run it without asking (`Bash(remote:*)` in
  `~/.claude/settings.json`, added by `scripts/claude-remote-permissions.sh`).
  Its skill, `remote-machine`, is the one dotfiles skill that is
  model-invoked. Tests: `scripts/test-remote.sh` against the stand-in from
  `scripts/remote-test-host.sh up`. See `doc/remote-machine.md`.
```
and change "All skills use `disable-model-invocation: true` (user-triggered only)" to "All skills except `remote-machine` use `disable-model-invocation: true` (user-triggered only)".

CHANGELOG, a new top entry:
```
## 2026-10-08: Claude works on a remote machine over SSH (`remote`, a mount, a skill)

### On other machines
- **macOS:** pull, then `./install_darwin.sh`. It installs FUSE-T and its
  sshfs (two `.pkg` installers: they ask for your password), stows the new
  `remote` package (`~/.local/bin/remote`), and adds two rules to
  `~/.claude/settings.json`. `scripts/verify.sh` checks all three.
- **To use it with the work Mac:** the one-time setup in
  `doc/remote-machine.md` (Remote Login, your key, a cable, an ssh alias).
- **Arch, Debian, Windows:** nothing. (Windows links the new skill too; it
  says it is for macOS and Linux.)

### What changed
- `remote` command, `remote-machine` skill, `scripts/claude-remote-permissions.sh`,
  `scripts/remote-test-host.sh`, `scripts/test-remote.sh`, `doc/remote-machine.md`.
  Spec `doc/specs/2026-10-08-remote-machine-design.md`; plan
  `doc/plans/2026-10-08-remote-machine.md`.

### What the repo can't do
- The work Mac's side (Remote Login, its authorized key, the cable) is set up
  by hand, once.
```

- [ ] **Step 3: Check and commit**

Run: `scripts/lint.sh && git diff --stat`
Expected: lint clean; four files changed.

```bash
git add doc/remote-machine.md README.md CLAUDE.md CHANGELOG.md
git commit -m "Docs: doc/remote-machine.md, README and CLAUDE.md pointers, CHANGELOG for remote"
git push
```

---

### Task 8: Cleanup

**Files:** outside this repo: `~/Development/libbullet.git`, Docker, `~/.ssh`.

- [ ] **Step 1: Take the fake Pi down while its script still exists**

Run:
```
cd ~/Development/libbullet.git && ./scripts/fake-pi.sh down
docker rmi libbullet-fake-pi libbullet-fake-pi-port
docker ps -a --filter name=fake-pi --format '{{.Names}}'; docker network ls | grep -c pi-lan
```
Expected: "fake Pi is down"; both images removed; no containers listed; `0`.

- [ ] **Step 2: Remove the exercise files from libbullet and commit the .gitignore line**

Run:
```
cd ~/Development/libbullet.git
rm -f docs/OFFLINE-TARGET.md scripts/remote.sh scripts/fake-pi.sh CLAUDE.md
rm -rf .cache/fake-pi
git status --short
git add .gitignore && git commit -m "gitignore .claude/settings.local.json: per-machine Claude permissions" && git push
```
Expected before the commit: only ` M .gitignore` (plus nothing untracked). Read `git status` first: if anything else shows up, stop and ask.

- [ ] **Step 3: Remove the fake Pi's SSH pieces**

Run:
```
python3 - <<'PY'
import os
p = os.path.expanduser("~/.ssh/config")
lines = open(p).read().split("\n")
start = next(i for i, l in enumerate(lines) if l.startswith("# Stand-in for libbullet's offline Pi"))
end = next(i for i in range(start, len(lines)) if lines[i].strip().startswith("ConnectTimeout"))
# drop the blank line before the block too
if start > 0 and lines[start - 1] == "":
    start -= 1
del lines[start:end + 1]
open(p, "w").write("\n".join(lines))
PY
grep -c fake-pi ~/.ssh/config
rm -f ~/.ssh/fake_pi ~/.ssh/fake_pi.pub ~/.ssh/known_hosts_fake_pi
```
Expected: `0`. Show Martin the remaining `~/.ssh/config` diff against `~/.ssh/config.bak-2026-10-08` (`diff ~/.ssh/config.bak-2026-10-08 ~/.ssh/config`) — expect only the `workmac-test` block (if the test host is up).

- [ ] **Step 4: Full suite, verify, and the todo log**

Run: `scripts/test-remote.sh && scripts/verify.sh 2>&1 | tail -1`
Expected: `All remote checks passed`; `All checks passed`.

Then log the session in `~/Development/todo` (TODO.md item for the one-time work-Mac setup with a pointer to `dotfiles/doc/remote-machine.md`; log entry; README row), commit and push. Ask Martin whether to keep the test host up for practice or run `scripts/remote-test-host.sh down`.
