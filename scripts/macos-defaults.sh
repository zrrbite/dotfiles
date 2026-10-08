#!/usr/bin/env bash
#
# macOS settings for this setup: a Dock and menu bar that sketchybar replaces,
# what AeroSpace's guide recommends, and text input that doesn't rewrite what
# you type. Finder has its own script, finder-defaults.sh.
#
# Usage: scripts/macos-defaults.sh [--dry-run | --check | --undo]
#   --check  changes nothing; lists each setting that differs, exits 1 if any
#            does (scripts/verify.sh runs this)
#   --undo   deletes every key set here, returning each to macOS's default
#
# Safe to re-run. Restarts the Dock at the end. Apps read the text settings
# when they start, so already-open apps change after you quit and reopen them
# (or log out and in). install_darwin.sh runs this as part of --with-desktop.

set -euo pipefail

MODE=apply
case "${1:-}" in
    --dry-run) MODE=dry ;;
    --check)   MODE=check ;;
    --undo)    MODE=undo ;;
    "")        ;;
    *) echo "Usage: $0 [--dry-run | --check | --undo]" >&2; exit 2 ;;
esac

# domain | key | type | value | why
SETTINGS=(
    # sketchybar replaces the Dock and the menu bar
    "com.apple.dock|autohide|-bool|true|hide the Dock"
    "com.apple.dock|autohide-delay|-float|0|no delay before the Dock shows"
    "com.apple.dock|autohide-time-modifier|-float|0.3|show and hide the Dock quickly"
    "NSGlobalDomain|_HIHideMenuBar|-bool|true|hide the menu bar"

    # AeroSpace (https://nikitabobko.github.io/AeroSpace/guide)
    "com.apple.dock|expose-group-apps|-bool|true|Mission Control groups windows by app; AeroSpace parks hidden windows in a corner, which otherwise shows as slivers"
    "com.apple.WindowManager|EnableStandardClickToShowDesktop|-bool|false|clicking the wallpaper (a gap between tiles) doesn't slide every window away"
    "NSGlobalDomain|NSWindowShouldDragOnGesture|-bool|true|ctrl+cmd-drag moves a window from anywhere on it, handy for floating ones"

    # Text input: what you type stays what you typed
    "NSGlobalDomain|NSAutomaticQuoteSubstitutionEnabled|-bool|false|no curly quotes, which break commands pasted into a terminal"
    "NSGlobalDomain|NSAutomaticDashSubstitutionEnabled|-bool|false|-- stays two hyphens"
    "NSGlobalDomain|NSAutomaticSpellingCorrectionEnabled|-bool|false|no autocorrect"
    "NSGlobalDomain|ApplePressAndHoldEnabled|-bool|false|holding a key repeats it (j in VS Code's vim mode) instead of offering accents"
)

# `defaults read` prints booleans as 1/0 and floats without a trailing .0.
expected() {
    case "$1:$2" in
        -bool:true) echo 1 ;;
        -bool:false) echo 0 ;;
        *) echo "$2" ;;
    esac
}

differ=0
for entry in "${SETTINGS[@]}"; do
    IFS='|' read -r domain key type value why <<< "$entry"
    case "$MODE" in
        apply) defaults write "$domain" "$key" "$type" "$value"; echo "  set   $key = $value  ($why)" ;;
        dry)   echo "  would set $domain $key $type $value  ($why)" ;;
        check)
            current="$(defaults read "$domain" "$key" 2>/dev/null || echo unset)"
            if [ "$current" != "$(expected "$type" "$value")" ]; then
                echo "  $domain $key is $current, wants $value ($why)"
                differ=$((differ + 1))
            fi
            ;;
        undo)  defaults delete "$domain" "$key" 2>/dev/null && echo "  reset $key" || echo "  (already default) $key" ;;
    esac
done

case "$MODE" in
    check) [ "$differ" -eq 0 ] ;;
    dry) ;;
    *)
        killall Dock 2>/dev/null || true
        echo "Dock restarted. Quit and reopen apps (or log out and in) for the text settings."
        ;;
esac
