# GlazeWM on Windows

The tiling setup on Windows. Config lives in `glazewm/.glzr/glazewm/config.yaml`.

Keybinds deliberately mirror [AeroSpace on macOS](aerospace-macos.md) — same
modifier, same `hjkl`, same chords for close/fullscreen/resize — so muscle
memory carries between the two. The Linux setup
([hyprland.md](hyprland.md)) does **not** match; it uses `SUPER` and arrow keys.

## What actually runs

| Process | What it does | How it starts |
|---|---|---|
| GlazeWM | Tiles windows, owns the keybinds | Manually / at login |
| zebar | Status bar | `startup_commands: shell-exec zebar` |

zebar is killed on shutdown with `taskkill /IM zebar.exe /F`. The 50px top outer
gap exists to make room for it.

## Keybindings

### Focus and move

| Key | Action |
|---|---|
| `alt` + `h/j/k/l` | Focus left / down / up / right |
| `alt` + `←/↓/↑/→` | Same thing, arrows |
| `alt-shift` + `h/j/k/l` | Move the focused window in that direction |
| `alt-shift` + `←/↓/↑/→` | Same thing, arrows |
| `alt-space` | Cycle focus within the current container |

Both `hjkl` and arrows are bound for focus and move — AeroSpace only binds
`hjkl`.

### Workspaces

| Key | Action |
|---|---|
| `alt` + `1`–`9` | Focus workspace N |
| `alt-shift` + `1`–`9` | Move window to workspace N **and follow it** |
| `alt-s` / `alt-a` | Next / previous active workspace |
| `alt-d` | Most recent workspace |
| `alt-shift-a` / `alt-shift-f` | Move the workspace to the monitor left / right |
| `alt-shift-d` / `alt-shift-s` | Move the workspace to the monitor up / down |

Nine workspaces are declared. Monitor movement has all four directions here;
AeroSpace only binds previous/next.

### Layout and window state

| Key | Action |
|---|---|
| `alt-v` | Toggle tiling direction for the next inserted window |
| `alt-f` | Toggle fullscreen |
| `alt-t` | Toggle tiling for the focused window |
| `alt-m` | Minimize |
| `alt-shift-space` | Toggle floating, centred |

New windows tile by default (`initial_state: tiling`), floating windows are
centred, and fullscreen is not maximized.

### Resizing

| Key | Action |
|---|---|
| `alt-u` / `alt-p` | Width −2% / +2% |
| `alt-i` / `alt-o` | Height −2% / +2% |

**`alt-r` resize mode is commented out.** The binding is reserved for the
PowerToys Run launcher, to match `SUPER-R` on Hyprland. The `resize` binding
mode is still defined in the config — with `h/j/k/l` or arrows to resize and
`escape`/`enter` to leave — so uncommenting the one line brings it back.

AeroSpace resizes by ±50 pixels; this resizes by ±2%.

### Session

| Key | Action |
|---|---|
| `alt-enter` | Windows Terminal (`wt`) |
| `alt-shift-q` | Close the focused window |
| `alt-shift-r` | Reload the config |
| `alt-shift-e` | Exit GlazeWM |
| `alt-shift-w` | Redraw (fixes windows left in a bad spot) |
| `alt-shift-p` | Pause the WM — stops all tiling |
| `alt-F12` | Keybinding cheatsheet popup |

`alt-shift-p` is easy to hit by accident when reaching for `alt-shift-q`. If
tiling suddenly stops working entirely, press it again before debugging
anything else.

Swap the `alt-enter` command to `shell-exec %ProgramFiles%/Git/git-bash.exe` for
Git Bash instead of Windows Terminal.

### Volume

`alt-F1` mutes, `alt-F2` / `alt-F3` change volume by ±30%. These shell out to
`nircmd`, which is **not installed by default** — get it via Scoop. Without it
the keys silently do nothing.

## Window rules

Several things are set to `ignore` so GlazeWM leaves them alone:

- **zebar** itself — the bar is not a tiled window.
- **Picture-in-picture** popups in Chrome and Firefox.
- **PowerToys** — PowerAccent, Command Palette, and Peek.
- **Office child windows** — Excel, Word and PowerPoint spawn helper windows
  that are not the main frame; the rules match on class *not* being `XLMAIN` /
  `OpusApp` / `PPTFrameClass` and ignore those.
- **Fellowship** (`fellowship-Win64-Shipping`) — fully ignored so GlazeWM does
  not fight the game's own fullscreen and resolution handling at launch.

Games generally need an entry here. Add the process name and reload with
`alt-shift-r`.

## Appearance

Nord-adjacent, matching the alacritty and foot themes in this repo: focused
border `#88c0d0`, everything else `#4c566a`. Rounded corners, no transparency,
title bars kept. Inner gap 12px, outer 12px on three sides and 50px at the top
for zebar. Gaps scale with DPI.

## Gotchas

**`hide_method: 'cloak'`** is the recommended setting and what this config uses.
The legacy `hide` method makes some apps think they are minimized and stop
rendering.

**`focus_follows_cursor: true`** combined with **`cursor_jump` on
`monitor_focus`** — the cursor teleports to a monitor when you focus it, but not
when you focus a window within the same monitor. This is deliberate; setting
`trigger: 'window_focus'` makes the cursor jump on every focus change, which
fights focus-follows-cursor.

**`toggle_workspace_on_refocus: false`** — pressing `alt-3` while already on
workspace 3 does nothing. Use `alt-d` for back-and-forth instead.

**Windows are not shown in the taskbar** (`show_all_in_taskbar: false`), so
Alt+Tab and the taskbar only see the current workspace.
