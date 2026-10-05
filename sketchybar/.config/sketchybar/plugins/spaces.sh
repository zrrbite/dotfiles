#!/bin/bash

# Refreshes every workspace item in one pass: the focused highlight, the app
# icons, and whether the item is shown at all. One script for all nine items
# rather than one per item, so a workspace switch costs two `aerospace` calls
# instead of eighteen.

# Nord
NORD8=0xff88c0d0
NORD10=0xff5e81ac
CLEAR=0x005e81ac   # NORD10 at zero alpha, so the fade only animates opacity

# Vendored from sketchybar-app-font, and must match the installed font's
# release: the map emits ligature names like ":slack:", and a name the font
# does not know renders as literal text. Defines __icon_map, sets $icon_result.
# lint.sh runs shellcheck without -x, so it cannot follow this; icon_result
# below is assigned in there.
# shellcheck source=/dev/null
source "$CONFIG_DIR/plugins/icon_map.sh"

# $FOCUSED_WORKSPACE is only set when aerospace_workspace_change fires, so on a
# reload, a fresh login or any other event it is empty. Ask AeroSpace directly.
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
WINDOWS=$(aerospace list-windows --all --format '%{workspace}|%{app-name}')

# Some apps (WhatsApp) prefix their name with an invisible U+200E
# left-to-right mark, which would make them miss the icon map.
LRM=$'\xe2\x80\x8e'

args=()
for sid in $(aerospace list-workspaces --all); do
    icons=""
    while IFS= read -r app; do
        [ -z "$app" ] && continue
        __icon_map "${app#"$LRM"}"
        # shellcheck disable=SC2154
        icons="$icons $icon_result"
    done <<< "$(printf '%s\n' "$WINDOWS" | awk -F'|' -v s="$sid" '$1 == s { print $2 }' | sort -u)"
    icons="${icons# }"

    # Empty workspaces are hidden, except the one you are on.
    if [ -n "$icons" ] || [ "$sid" = "$FOCUSED" ]; then drawing=on; else drawing=off; fi
    if [ -n "$icons" ]; then label_drawing=on; else label_drawing=off; fi

    # Active workspace mirrors waybar's `button.active`: indigo fill. Waybar
    # underlines it with `box-shadow: inset 0 -3px`; sketchybar has no
    # bottom-only border, so a 1px cyan border around the pill stands in.
    if [ "$sid" = "$FOCUSED" ]; then
        color=$NORD10; border=1
    else
        color=$CLEAR; border=0
    fi

    args+=(--set "space.$sid"
        "drawing=$drawing"
        label="$icons"
        "label.drawing=$label_drawing"
        "background.color=$color"
        "background.border_color=$NORD8"
        "background.border_width=$border")
done

# The highlight fades between workspaces rather than jumping. `drawing` is not
# animatable, so items still appear and disappear instantly.
sketchybar --animate tanh 12 "${args[@]}"
