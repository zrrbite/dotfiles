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
    printf '\nAn uncommitted line, for remote git status.\n' >> "$d/README.md"
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
