#!/usr/bin/env bash
#
# Make Finder bearable. yazi is the file manager here, but Finder can't be
# avoided entirely: every Open and Save dialog is Finder. These settings make
# it show what's actually there.
#
# Usage: scripts/finder-defaults.sh [--dry-run | --undo]
#   --undo  deletes every key set here, returning each to macOS's default
#
# Safe to re-run. Restarts Finder at the end, which closes its open windows.
# install_darwin.sh runs this as part of --with-desktop.

set -euo pipefail

MODE=apply
case "${1:-}" in
    --dry-run) MODE=dry ;;
    --undo)    MODE=undo ;;
    "")        ;;
    *) echo "Usage: $0 [--dry-run | --undo]" >&2; exit 2 ;;
esac

# domain | key | type | value | why
SETTINGS=(
    "com.apple.finder|AppleShowAllFiles|-bool|true|show hidden files (dotfiles, ~/Library)"
    "NSGlobalDomain|AppleShowAllExtensions|-bool|true|always show file extensions"
    "com.apple.finder|ShowPathbar|-bool|true|path bar at the bottom: where am I, clickable"
    "com.apple.finder|ShowStatusBar|-bool|true|status bar: item count and free space"
    "com.apple.finder|_FXShowPosixPathInTitle|-bool|true|full POSIX path in the window title"
    "com.apple.finder|_FXSortFoldersFirst|-bool|true|folders before files, as in yazi"
    "com.apple.finder|FXPreferredViewStyle|-string|Nlsv|list view by default"
    "com.apple.finder|FXDefaultSearchScope|-string|SCcf|search the current folder, not the whole Mac"
    "com.apple.finder|FXEnableExtensionChangeWarning|-bool|false|no warning when changing an extension"
    "com.apple.finder|NewWindowTarget|-string|PfHm|new windows open in the home folder"
    "com.apple.desktopservices|DSDontWriteNetworkStores|-bool|true|no .DS_Store files on network shares"
    "com.apple.desktopservices|DSDontWriteUSBStores|-bool|true|no .DS_Store files on USB drives"
)

for entry in "${SETTINGS[@]}"; do
    IFS='|' read -r domain key type value why <<< "$entry"
    case "$MODE" in
        apply) defaults write "$domain" "$key" "$type" "$value"; echo "  set   $key = $value  ($why)" ;;
        dry)   echo "  would set $domain $key $type $value  ($why)" ;;
        undo)  defaults delete "$domain" "$key" 2>/dev/null && echo "  reset $key" || echo "  (already default) $key" ;;
    esac
done

if [ "$MODE" != dry ]; then
    # Finder only reads these at launch. The list view default applies to
    # folders without a saved view of their own; folders you've already
    # arranged keep theirs.
    killall Finder 2>/dev/null || true
    echo "Finder restarted."
fi
