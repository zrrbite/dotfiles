# Hyprland on Linux

The tiling setup on Arch, and where it differs from the other two. Config lives
in `hypr/.config/hypr/hyprland.conf`.

Read [aerospace-macos.md](aerospace-macos.md) and [glazewm.md](glazewm.md) for
the macOS and Windows setups. As of 2026-07-26 the `hjkl` focus and move
bindings match all three. **The modifier still does not** — this one is `SUPER`
where the others are `alt`, for a reason that is not going away; see
[Why the modifier diverges](#why-the-modifier-diverges).

## The modifier is SUPER

`$mainMod = SUPER` — the Windows key. Not `alt`, which is what AeroSpace and
GlazeWM use.

## What actually runs

Started by `exec-once`, all in one line except the clipboard watchers:

| Process | What it does |
|---|---|
| waybar | Status bar |
| hyprpaper | Wallpaper |
| mako | Notifications |
| hypridle | Idle timeout → lock |
| `wl-paste --watch cliphist` | Clipboard history (one for text, one for images) |
| polkit-gnome agent | Authentication prompts |

Workspaces are pre-populated at startup: a terminal on 1, Firefox on 2, Discord
plus `btop` on 3. Window rules then keep Firefox on 2 and Discord on 3 for the
rest of the session.

See [status-bar-theming.md](status-bar-theming.md) for waybar itself.

## Keybindings

### Focus and move

| Key | Action |
|---|---|
| `SUPER` + `h/j/k/l` | Focus left / down / up / right |
| `SUPER` + `←/↓/↑/→` | Same thing, arrows |
| `SUPER-SHIFT` + `h/j/k/l` | Move the focused window in that direction |
| `SUPER-SHIFT` + `←/↓/↑/→` | Same thing, arrows |
| `SUPER` + LMB drag | Move the window |
| `SUPER` + RMB drag | Resize the window |

The `hjkl` half matches AeroSpace and GlazeWM exactly, so that muscle memory
carries across all three machines. Adding it displaced two bindings:
`togglesplit` moved from `SUPER-J` to **`SUPER-T`**, and the lock screen from
`SUPER-L` to **`SUPER-CTRL-L`**.

### Workspaces

| Key | Action |
|---|---|
| `SUPER` + `1`–`0` | Switch to workspace 1–10 |
| `SUPER-SHIFT` + `1`–`0` | Move window to workspace 1–10 (does **not** follow) |
| `SUPER` + scroll | Next / previous workspace |
| 3-finger horizontal swipe | Next / previous workspace |
| `SUPER-S` | Toggle the `magic` scratchpad |
| `SUPER-SHIFT-W` | Move window to the `magic` scratchpad |

Note the asymmetry with the other two WMs: here `SUPER-SHIFT` + a **number**
moves the window and leaves you where you are, while AeroSpace and GlazeWM both
follow it. (`SUPER-SHIFT` + a **letter** is now directional window movement, so
mind the difference.)

### Layout

The layout is `dwindle` — every new window splits the focused one, alternating
direction. `preserve_split = true`, so the split ratio survives closing a
sibling.

| Key | Action |
|---|---|
| `SUPER-T` | Toggle the split direction of the focused window |
| `SUPER-B` | Pre-select: next window opens **below** |
| `SUPER-N` | Pre-select: next window opens **right** |
| `SUPER-P` | Toggle pseudotile |
| `SUPER-V` | Toggle floating |
| `SUPER` + `=` | Resize to exactly 1080×1080 (square, for screenshots/recording) |

`SUPER-B` / `SUPER-N` apply to the *next* window you open, not the current one.
Press one, then launch something.

### Launchers and session

| Key | Action |
|---|---|
| `SUPER-Q` | Terminal (`foot`) |
| `SUPER-R` | App launcher (`rofi -show drun`) |
| `SUPER-E` | File manager (`thunar`) |
| `SUPER-SHIFT-E` | Midnight Commander in a terminal |
| `SUPER-SHIFT-V` | Clipboard history via rofi |
| `SUPER-C` | Close the focused window |
| `SUPER-CTRL-L` | Lock (`hyprlock`) |
| `SUPER-Escape` | Logout menu (`wlogout`) |
| `SUPER-M` | **Exit Hyprland immediately** — no confirmation |

`SUPER-M` sits one key from `SUPER-N`. It quits the session without asking.

### Screenshots and recording

| Key | Action |
|---|---|
| `Print` | Whole screen → `~/Pictures/Screenshots` |
| `SUPER-SHIFT-S` | Region → `~/Pictures/Screenshots` |
| `SUPER-SHIFT-C` | Region → clipboard |
| `SUPER-SHIFT-A` | Region → `satty` to annotate, then save |
| `SUPER-SHIFT-R` | Start / stop screen recording |
| `SUPER-CTRL-R` | Start / stop recording a region |

Needs `grim`, `slurp`, `satty` and `wf-recorder`.

### Built-in help

| Key | Action |
|---|---|
| `SUPER-F1` | Every binding, live from `hyprctl binds`, in rofi |
| `SUPER-F2` | Useful shell commands and aliases (`commands-menu.sh`) |
| `SUPER-F3` | Neovim keybindings (`nvim-keys.sh`) |
| `SUPER-SHIFT-F3` | Restart hyprlock if it crashed |

`SUPER-F1` reads the running config, so it is never stale — prefer it over this
document when the two disagree.

### Media keys

`XF86Audio{RaiseVolume,LowerVolume,Mute,MicMute}` go through `wpctl`,
`XF86MonBrightness{Up,Down}` through `brightnessctl`, and
`XF86Audio{Next,Prev,Play,Pause}` through `playerctl`. Volume is capped at 100%
(`-l 1`) so you cannot overdrive the sink by holding the key.

## Why the modifier diverges

`alt` is not available as a modifier here. The input section sets:

```
kb_layout = dk, us
kb_options = grp:alt_shift_toggle
```

Two keyboard layouts, Danish and US, cycled with **Alt+Shift**. That is exactly
the chord AeroSpace and GlazeWM use for moving windows
(`alt-shift-h/j/k/l`), so adopting their modifier would fight the layout
switcher on every window move. Changing it means giving up the layout toggle or
relocating it first — so `SUPER` stays.

The `hjkl` bindings had no such excuse. Until 2026-07-26 focus was on the arrow
keys only and there were no directional move bindings at all, which was a
leftover from the stock config this file grew out of (the header still says
`AUTOGENERATED`) rather than a decision. `SUPER-h/j/k/l` and
`SUPER-SHIFT-h/j/k/l` were free, so they are now bound to match the other two.

## Gaps and appearance

`gaps_in = 5`, `gaps_out = 20`, `border_size = 2`, `rounding = 10`. The active
border is a 45° cyan-to-green gradient — this is the one part of the setup that
is *not* Nord, unlike waybar, foot and alacritty. Blur and shadows are on.

"Smart gaps" (no gaps when only one window) is present but commented out near
the `workspace = w[tv1]` rules.

## Gotchas

**Focus does not follow the mouse across windows the way you might expect.**
`follow_mouse = 1` means focus follows the cursor, but `focus_on_activate =
false` means apps cannot steal focus by asking for it. A dialog opening
somewhere else will not pull you away.

**Maximize requests are suppressed** for every window class
(`suppressevent maximize, class:.*`). Apps that try to maximize themselves on
launch will just tile normally.

**JetBrains IDEs need the XWayland workarounds** already in the env block
(`_JAVA_AWT_WM_NONREPARENTING=1`, GL disabled, `force_zero_scaling`). Removing
them gives blank or mis-scaled IDE windows.
