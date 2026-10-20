#!/usr/bin/env bash
#
# Tests for scripts/macos-permissions.sh. Fake commands go in front of PATH
# (aerospace, systemextensionsctl, bioutil, pgrep, open, sleep) and a fake
# /Applications stands in for the real one, so this runs the same on any Mac,
# opens nothing and grants nothing. The interactive walk insists on a
# terminal; PERMISSIONS_TTY=1 lets these tests type into it through a pipe.
#
# Usage: scripts/test-macos-permissions.sh
#
# shellcheck disable=SC2015  # ok and bad always succeed, so A && ok || bad is an if-else here

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$DOTFILES_DIR/scripts/macos-permissions.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
FAILS=0
ok()  { echo -e "${GREEN}ok${NC}   $1"; }
bad() { echo -e "${RED}FAIL${NC} $1"; FAILS=$((FAILS + 1)); }

# -- Fakes -----------------------------------------------------------------
# Each reads its state from FAKE_* variables or files under $TMP.
mkdir -p "$TMP/bin"
cat > "$TMP/bin/aerospace" <<'EOF'
#!/usr/bin/env bash
[ "${FAKE_AERO:-running}" = running ] || { echo "Can't connect to AeroSpace server" >&2; exit 1; }
case "$1" in
    list-workspaces) echo 1 ;;
    list-windows) echo "${FAKE_WINDOWS:-5}" ;;
    trigger-binding)
        # A refused Automation prompt makes the binding start a new copy.
        if [ "${FAKE_REFUSED:-0}" = 1 ]; then
            echo $(( $(cat "$FAKE_STATE/ghostty") + 1 )) > "$FAKE_STATE/ghostty"
        fi ;;
esac
EOF
cat > "$TMP/bin/systemextensionsctl" <<'EOF'
#!/usr/bin/env bash
if [ "${FAKE_DRIVER:-on}" = on ]; then state="activated enabled"; else state="activated waiting for user"; fi
printf '*\t*\tG43BCU2T37\torg.pqrs.Karabiner-DriverKit-VirtualHIDDevice (1.8.0/1.8.0)\tKarabiner-DriverKit-VirtualHIDDevice\t[%s]\n' "$state"
EOF
cat > "$TMP/bin/bioutil" <<'EOF'
#!/usr/bin/env bash
printf 'User 501:\t%s biometric template(s)\nOperation performed successfully.\n' "${FAKE_FINGERS:-2}"
EOF
cat > "$TMP/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
name="${*: -1}"
case "$name" in
    Karabiner-Core-Service) [ "${FAKE_CORE:-running}" = running ] && echo 4242 ;;
    ghostty)
        n="$(cat "$FAKE_STATE/ghostty")"
        [ "$n" -gt 0 ] || exit 1
        seq 1 "$n" ;;
    *) exit 1 ;;
esac
EOF
cat > "$TMP/bin/open" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$FAKE_STATE/opened"
EOF
printf '#!/usr/bin/env bash\n' > "$TMP/bin/sleep"
chmod +x "$TMP/bin/"*

for app in AeroSpace Karabiner-Elements OrbStack Raycast Ghostty; do
    mkdir -p "$TMP/Applications/$app.app"
done
ln -s "$TMP/Applications/OrbStack.app/Contents/MacOS/xbin/docker" "$TMP/docker-orbstack"
ln -s "/Applications/Docker.app/Contents/Resources/bin/docker" "$TMP/docker-desktop"

export PATH="$TMP/bin:$PATH"
export PERMISSIONS_APPS="$TMP/Applications"
export FAKE_STATE="$TMP/state"

# A finished Mac: every check passes. Each test starts from here.
reset() {
    rm -rf "$FAKE_STATE" && mkdir -p "$FAKE_STATE"
    echo 1 > "$FAKE_STATE/ghostty"
    : > "$FAKE_STATE/opened"
    export PERMISSIONS_DOCKER_LINK="$TMP/docker-orbstack"
    unset FAKE_AERO FAKE_WINDOWS FAKE_DRIVER FAKE_CORE FAKE_FINGERS FAKE_REFUSED
}

# The interactive walk, fed $1 as keyboard input.
walk() {
    printf '%b' "$1" | PERMISSIONS_TTY=1 "$SCRIPT" > "$FAKE_STATE/out" 2>&1
    echo $? > "$FAKE_STATE/rc"
}

has()    { grep -q -- "$2" "$1"; }
opened() { grep -q -- "$1" "$FAKE_STATE/opened"; }

# -- --list ------------------------------------------------------------------
reset
out="$("$SCRIPT" --list)"
if [ "$(printf '%s\n' "$out" | grep -c '^[0-9]\. ')" = 7 ]; then ok "--list: seven steps"; else bad "--list: seven steps, got: $out"; fi

# -- --check -----------------------------------------------------------------
reset
out="$("$SCRIPT" --check)"; rc=$?
[ "$rc" = 0 ] && ok "--check, all done: exit 0" || bad "--check, all done: exit $rc"
[ "$(printf '%s\n' "$out" | grep -c '^ok: ')" = 4 ] && ok "--check, all done: four ok" || bad "--check, all done: four ok, got: $out"
[ "$(printf '%s\n' "$out" | grep -c '^by hand: ')" = 3 ] && ok "--check, all done: three by hand" || bad "--check, all done: three by hand, got: $out"
[ -s "$FAKE_STATE/opened" ] && bad "--check opened something" || ok "--check opens nothing"

check_missing() { # name, expected text in the missing line
    out="$("$SCRIPT" --check)"; rc=$?
    if [ "$rc" = 1 ] && printf '%s\n' "$out" | grep '^missing: ' | grep -q -- "$2"; then
        ok "--check: $1"
    else
        bad "--check: $1 (exit $rc): $out"
    fi
}
reset; export FAKE_AERO=stopped;  check_missing "AeroSpace not running" "AeroSpace isn't running"
reset; export FAKE_WINDOWS=0;     check_missing "AeroSpace sees no windows" "no Accessibility"
reset; export FAKE_DRIVER=off;    check_missing "Karabiner's driver off" "driver"
reset; export FAKE_CORE=stopped;  check_missing "Karabiner not running" "Karabiner-Elements isn't running"
reset; export FAKE_FINGERS=0;     check_missing "no fingerprint" "fingerprint"
reset; export PERMISSIONS_DOCKER_LINK="$TMP/docker-desktop"; check_missing "docker isn't OrbStack's" "OrbStack"
reset; rm -rf "$TMP/Applications/Raycast.app"; check_missing "Raycast not installed" "brew install --cask raycast"
mkdir -p "$TMP/Applications/Raycast.app"

# -- No terminal -------------------------------------------------------------
reset
out="$("$SCRIPT" < /dev/null 2>&1)"; rc=$?
if [ "$rc" = 2 ] && printf '%s\n' "$out" | grep -q 'needs a terminal' && printf '%s\n' "$out" | grep -q '^ok: '; then
    ok "no terminal: says so, shows --check, exit 2"
else
    bad "no terminal (exit $rc): $out"
fi

# -- The walk ----------------------------------------------------------------
# Order: aerospace, karabiner_driver, karabiner_input (by hand), touchid,
# orbstack, raycast (by hand), ghostty (by hand).

reset
walk 'd\nd\nd\n'
[ "$(cat "$FAKE_STATE/rc")" = 0 ] && ok "walk, all done: exit 0" || bad "walk, all done: exit $(cat "$FAKE_STATE/rc")"
[ -s "$FAKE_STATE/opened" ] && bad "walk, all done: opened $(cat "$FAKE_STATE/opened")" || ok "walk, all done: opens nothing"
has "$FAKE_STATE/out" "AeroSpace: Accessibility: done" && ok "walk: a done step says so" || bad "walk: done step: $(cat "$FAKE_STATE/out")"

# A missing fingerprint: the page opens; Enter while still missing says so; s skips.
reset; export FAKE_FINGERS=0
walk 'd\n\ns\nd\nd\n'
opened "Touch-ID-Settings" && ok "walk: opens the Touch ID page" || bad "walk: Touch ID page not opened: $(cat "$FAKE_STATE/opened")"
has "$FAKE_STATE/out" "Still missing" && ok "walk: re-checks after Enter" || bad "walk: no re-check: $(cat "$FAKE_STATE/out")"
[ "$(cat "$FAKE_STATE/rc")" = 1 ] && ok "walk, a step skipped: exit 1" || bad "walk, a step skipped: exit $(cat "$FAKE_STATE/rc")"
has "$FAKE_STATE/out" "Skipped: Touch ID" && ok "walk: the summary names what was skipped" || bad "walk: summary: $(cat "$FAKE_STATE/out")"

# Fixed while waiting: the check passes after Enter.
reset; export FAKE_DRIVER=off
walk '\nd\nd\nd\n'
opened "LoginItems-Settings" && ok "walk: opens Login Items & Extensions for the driver" || bad "walk: driver page: $(cat "$FAKE_STATE/opened")"
opened "-a Karabiner-Elements" && ok "walk: starts Karabiner-Elements" || bad "walk: Karabiner not started: $(cat "$FAKE_STATE/opened")"

# A by-hand step: Enter opens it, Enter again counts as done.
reset
walk '\n\nd\nd\n'
opened "Privacy_ListenEvent" && ok "walk: by hand, Enter opens Input Monitoring" || bad "walk: Input Monitoring: $(cat "$FAKE_STATE/opened")"
[ "$(cat "$FAKE_STATE/rc")" = 0 ] && ok "walk: by hand, done on your word" || bad "walk: by hand: exit $(cat "$FAKE_STATE/rc")"

# Ghostty: the script presses ⌃⌥Enter; a new copy means the prompt was refused.
reset; export FAKE_REFUSED=1
walk 'd\nd\n\n\ns\n'
has "$FAKE_STATE/out" "second copy of Ghostty" && ok "walk: Ghostty, a refused prompt is caught" || bad "walk: Ghostty refused: $(cat "$FAKE_STATE/out")"
reset
walk 'd\nd\n\n\n'
[ "$(cat "$FAKE_STATE/rc")" = 0 ] && ok "walk: Ghostty, allowed: done" || bad "walk: Ghostty allowed: exit $(cat "$FAKE_STATE/rc"): $(cat "$FAKE_STATE/out")"

# q stops the walk.
reset; export FAKE_FINGERS=0
walk 'd\nq\n'
if has "$FAKE_STATE/out" "Stopped" && ! has "$FAKE_STATE/out" "Raycast"; then ok "walk: q stops"; else bad "walk: q: $(cat "$FAKE_STATE/out")"; fi

echo
if [ "$FAILS" -gt 0 ]; then
    echo -e "${RED}$FAILS test(s) failed${NC}"
    exit 1
fi
echo -e "${GREEN}All tests passed${NC}"
