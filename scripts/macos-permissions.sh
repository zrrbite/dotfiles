#!/usr/bin/env bash
#
# What a Mac needs from you after the installer: the permissions macOS lets
# only a person grant, and the apps that want a first start. One step at a
# time, it says what each one is for, opens the right System Settings page or
# app, waits for you, and checks what a script can check. Steps already done
# are passed over, so it's safe to run again.
#
# Usage: scripts/macos-permissions.sh [--check | --list]
#   (none)   walk through the steps not done yet; needs a terminal
#   --check  open and ask nothing: one line per step, "ok", "missing" (with
#            what's wrong) or "by hand" (a script can't see it; with how to
#            tell). Exits 1 if a step it can check is missing.
#   --list   the steps, and what each is for
#
# install_darwin.sh runs it at the end when it runs in a terminal;
# scripts/verify.sh reports --check. Passwords aren't here: the installer asks
# for them as it goes (Homebrew, the .pkg casks, Touch ID for sudo).
# Tests: scripts/test-macos-permissions.sh.

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# For the tests; everyone else gets the real ones. PERMISSIONS_TTY=1 lets
# the tests type into the walk through a pipe.
APPS="${PERMISSIONS_APPS:-/Applications}"
DOCKER_LINK="${PERMISSIONS_DOCKER_LINK:-/usr/local/bin/docker}"

SETTINGS="x-apple.systempreferences:com.apple"
PANE_ACCESSIBILITY="$SETTINGS.preference.security?Privacy_Accessibility"
PANE_INPUT="$SETTINGS.preference.security?Privacy_ListenEvent"
PANE_AUTOMATION="$SETTINGS.preference.security?Privacy_Automation"
PANE_EXTENSIONS="$SETTINGS.LoginItems-Settings.extension"
PANE_TOUCHID="$SETTINGS.Touch-ID-Settings.extension"

# In the order they're needed: AeroSpace first, since the Ghostty step uses it.
STEPS=(aerospace karabiner_driver karabiner_input touchid orbstack raycast ghostty)

# Each step is five functions: title_, why_, how_ (what to do), open_ (opens
# the page or app) and check_, which returns 0 done, 1 missing or 2 "only you
# can tell", and prints why or how to tell. A by-hand step may add after_,
# a check that only works right after open_.

installed() { [ -d "$APPS/$1.app" ]; }

title_aerospace() { echo "AeroSpace: Accessibility"; }
why_aerospace()   { echo "tiling, the ⌃⌥ keys and focus-follows-mouse"; }
how_aerospace()   { echo "Starting AeroSpace makes macOS ask. Or turn AeroSpace on in System Settings > Privacy & Security > Accessibility."; }
open_aerospace()  { open -a AeroSpace; open "$PANE_ACCESSIBILITY"; }
check_aerospace() {
    installed AeroSpace || { echo "AeroSpace isn't installed: brew install --cask nikitabobko/tap/aerospace"; return 1; }
    aerospace list-workspaces --focused >/dev/null 2>&1 || { echo "AeroSpace isn't running: open -a AeroSpace"; return 1; }
    # It can only see windows through Accessibility, and this script runs in
    # a terminal window.
    local n
    n="$(aerospace list-windows --all --count 2>/dev/null)"
    [ "${n:-0}" -gt 0 ] 2>/dev/null || { echo "AeroSpace sees no windows: it has no Accessibility (or no window is open)"; return 1; }
}

title_karabiner_driver() { echo "Karabiner-Elements: its driver"; }
why_karabiner_driver()   { echo "Caps Lock: Escape when tapped, Control when held"; }
how_karabiner_driver()   {
    echo "Karabiner-Elements' own setup asks for what it needs; pick ISO if it asks for the keyboard type."
    echo "The driver is a separate switch: System Settings > General > Login Items & Extensions, Driver Extensions, turn Karabiner on."
}
open_karabiner_driver()  { open -a Karabiner-Elements; open "$PANE_EXTENSIONS"; }
check_karabiner_driver() {
    installed Karabiner-Elements || { echo "Karabiner-Elements isn't installed: brew install --cask karabiner-elements"; return 1; }
    pgrep -x Karabiner-Core-Service >/dev/null 2>&1 || { echo "Karabiner-Elements isn't running: open it once"; return 1; }
    systemextensionsctl list 2>/dev/null | grep 'org.pqrs.Karabiner-DriverKit-VirtualHIDDevice' | grep -q 'activated enabled' ||
        { echo "its driver isn't approved, so Caps Lock isn't remapped"; return 1; }
}

title_karabiner_input() { echo "Karabiner-Elements: Input Monitoring"; }
why_karabiner_input()   { why_karabiner_driver; }
how_karabiner_input()   { echo "System Settings > Privacy & Security > Input Monitoring: turn the Karabiner entries on."; }
open_karabiner_input()  { open "$PANE_INPUT"; }
check_karabiner_input() {
    installed Karabiner-Elements || { echo "Karabiner-Elements isn't installed: brew install --cask karabiner-elements"; return 1; }
    echo "tap Caps Lock in a text field: nothing turns to capitals (Karabiner-EventViewer shows escape)"
    return 2
}

title_touchid() { echo "Touch ID: a fingerprint"; }
why_touchid()   { echo "sudo takes your finger, also inside tmux"; }
how_touchid()   { echo "System Settings > Touch ID & Password > Add Fingerprint. Skip this if the Mac has no Touch ID."; }
open_touchid()  { open "$PANE_TOUCHID"; }
check_touchid() {
    local fingers
    fingers="$(bioutil -c 2>/dev/null | sed -n 's/^User [0-9]*:[[:space:]]*\([0-9]*\) biometric.*/\1/p')"
    [ "${fingers:-0}" -gt 0 ] 2>/dev/null || { echo "no fingerprint enrolled, so sudo asks for the password"; return 1; }
}

title_orbstack() { echo "OrbStack: first start"; }
why_orbstack()   { echo "docker and docker compose"; }
how_orbstack()   { echo "Choose Docker, and allow its helper (it asks for the password). Migrating from Docker Desktop is optional."; }
open_orbstack()  { open -a OrbStack; }
check_orbstack() {
    installed OrbStack || { echo "OrbStack isn't installed: brew install --cask orbstack"; return 1; }
    case "$(readlink "$DOCKER_LINK" 2>/dev/null)" in
        *OrbStack.app*) ;;
        *) echo "docker isn't OrbStack's yet: its first start links it"; return 1 ;;
    esac
}

title_raycast() { echo "Raycast: first start, clipboard history, scripts"; }
why_raycast()   { echo "the launcher; ⌃⌥⇧V opens its clipboard history"; }
how_raycast()   {
    echo "Go through Raycast's welcome. Press ⌃⌥⇧V and allow the link (tick Always)."
    echo "Then Raycast Settings > Extensions > + > Add Script Directory: $DOTFILES_DIR/scripts/raycast"
}
open_raycast()  { open -a Raycast; }
check_raycast() {
    installed Raycast || { echo "Raycast isn't installed: brew install --cask raycast"; return 1; }
    echo "⌃⌥⇧V opens clipboard history without asking first"
    return 2
}

title_ghostty() { echo "Ghostty: let AeroSpace control it"; }
why_ghostty()   { echo "⌃⌥Enter opens windows in the Ghostty that's running, not a new copy each time"; }
how_ghostty()   {
    echo "This presses ⌃⌥Enter for you. When macOS asks whether AeroSpace may control Ghostty, click OK."
    echo "Close the new window with ⌃⌥⇧Q."
}
GHOSTTY_TRIES=0
GHOSTTY_BEFORE=0
GHOSTTY_PRESSED=false
open_ghostty() {
    GHOSTTY_PRESSED=false
    if ! aerospace list-workspaces --focused >/dev/null 2>&1; then
        echo "  AeroSpace isn't running; start it first (step 1)."
        return
    fi
    # Synced from an older config, AeroSpace has no ctrl-alt-enter until it
    # reloads, and pressing it would do nothing.
    if ! aerospace config --get mode.main.binding --keys 2>/dev/null | grep -qx ctrl-alt-enter; then
        echo "  AeroSpace hasn't loaded this repo's config yet: run aerospace reload-config, then Enter."
        return
    fi
    if [ "$GHOSTTY_TRIES" -gt 0 ]; then
        # macOS asks once; after a refusal only Settings can change it.
        echo "  On this page, under AeroSpace, turn Ghostty on. Then press Enter."
        open "$PANE_AUTOMATION"
        read -r _ || true
    fi
    if ! pgrep -x ghostty >/dev/null 2>&1; then
        open -a Ghostty
        sleep 2
    fi
    GHOSTTY_BEFORE="$(pgrep -x ghostty | wc -l | tr -d ' ')"
    GHOSTTY_TRIES=$((GHOSTTY_TRIES + 1))
    aerospace trigger-binding --mode main ctrl-alt-enter
    GHOSTTY_PRESSED=true
}
after_ghostty() {
    local now
    if [ "$GHOSTTY_PRESSED" != true ]; then
        echo "⌃⌥Enter wasn't pressed yet"
        return 1
    fi
    now="$(pgrep -x ghostty | wc -l | tr -d ' ')"
    if [ "$now" -gt "$GHOSTTY_BEFORE" ]; then
        echo "a second copy of Ghostty started, so AeroSpace may not control Ghostty yet"
        return 1
    fi
}
check_ghostty() {
    installed Ghostty || { echo "Ghostty isn't installed: brew install --cask ghostty"; return 1; }
    echo "⌃⌥Enter opens a window with no second Ghostty in the Dock"
    return 2
}

# -- Modes -------------------------------------------------------------------

list() {
    local n=0 id
    for id in "${STEPS[@]}"; do
        n=$((n + 1))
        echo "$n. $(title_"$id") -- $(why_"$id")"
    done
}

# One line per step. Exit 1 if a step a script can check is missing.
check() {
    local id detail rc missing=0
    for id in "${STEPS[@]}"; do
        detail="$(check_"$id")"; rc=$?
        case "$rc" in
            0) echo "ok: $(title_"$id")" ;;
            1) echo "missing: $(title_"$id") -- $detail"; missing=1 ;;
            *) echo "by hand: $(title_"$id") -- $detail" ;;
        esac
    done
    return "$missing"
}

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Reads one answer into KEY. End of input counts as quit.
ask() {
    echo -ne "  ${YELLOW}$1${NC} "
    read -r KEY || KEY=q
}

walk() {
    local total=${#STEPS[@]} n=0 id detail rc
    local done_checked=() done_yours=() skipped=() stopped=false
    echo "macOS permissions and first starts: $total steps. Done ones are passed over."
    for id in "${STEPS[@]}"; do
        n=$((n + 1))
        detail="$(check_"$id")"; rc=$?
        if [ "$rc" = 0 ]; then
            echo -e "${GREEN}[$n/$total] $(title_"$id"): done${NC}"
            done_checked+=("$(title_"$id")")
            continue
        fi
        echo
        echo -e "${BOLD}[$n/$total] $(title_"$id")${NC}"
        echo "  For: $(why_"$id")"
        if [ "$rc" = 1 ]; then
            echo "  Now: $detail"
        fi
        how_"$id" | sed 's/^/  /'

        if [ "$rc" = 2 ]; then
            echo "  Done already if: $detail"
            ask "Enter: open it   d: already done   s: skip   q: quit"
            case "$KEY" in
                d) done_yours+=("$(title_"$id")"); continue ;;
                s) skipped+=("$(title_"$id")"); continue ;;
                q) stopped=true; break ;;
            esac
        fi

        # Open, wait, check; again until it's done or skipped.
        while :; do
            open_"$id"
            ask "Enter when done   s: skip   q: quit"
            case "$KEY" in
                s) skipped+=("$(title_"$id")"); break ;;
                q) stopped=true; break ;;
            esac
            if [ "$rc" = 2 ]; then
                if declare -F "after_$id" >/dev/null && ! detail="$(after_"$id")"; then
                    echo "  Not yet: $detail"
                    ask "Enter: try again   s: skip   q: quit"
                    case "$KEY" in
                        s) skipped+=("$(title_"$id")"); break ;;
                        q) stopped=true; break ;;
                    esac
                    continue
                fi
                echo -e "  ${GREEN}done${NC}"
                done_yours+=("$(title_"$id")")
                break
            fi
            if detail="$(check_"$id")"; then
                echo -e "  ${GREEN}done${NC}"
                done_checked+=("$(title_"$id")")
                break
            fi
            echo "  Still missing: $detail"
            ask "Enter: open it again   s: skip   q: quit"
            case "$KEY" in
                s) skipped+=("$(title_"$id")"); break ;;
                q) stopped=true; break ;;
            esac
        done
        $stopped && break
    done

    echo
    $stopped && echo "Stopped. Run scripts/macos-permissions.sh again to carry on."
    echo "Done and checked: ${#done_checked[@]}. Done on your word: ${#done_yours[@]}."
    if [ "${#skipped[@]}" -gt 0 ]; then
        local IFS=';'
        echo "Skipped: ${skipped[*]}"
    fi
    if $stopped || [ "${#skipped[@]}" -gt 0 ]; then
        return 1
    fi
}

main() {
    case "${1:-}" in
        --check) check ;;
        --list)  list ;;
        "")
            if [ ! -t 0 ] && [ "${PERMISSIONS_TTY:-}" != 1 ]; then
                echo "scripts/macos-permissions.sh needs a terminal: it opens System Settings and waits for you."
                echo "Where things stand (--check):"
                check
                exit 2
            fi
            walk ;;
        *) echo "Usage: $0 [--check | --list]" >&2; exit 2 ;;
    esac
}

# Run only when executed, so a test can source the functions above.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
