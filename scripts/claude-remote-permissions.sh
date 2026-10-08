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
