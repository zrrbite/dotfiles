# Status Bar Theming (Nord)

How the status bars in this repo are themed, and what to know before changing
them. The goal is that Arch and macOS look like the same desktop: waybar and
sketchybar share one colour contract, so a module means the same colour on both.

| Platform | Bar | Themed here? |
|---|---|---|
| Arch (Hyprland) | waybar | ✓ `waybar/.config/waybar/style.css` |
| macOS (AeroSpace) | sketchybar | ✓ `sketchybar/.config/sketchybar/` |
| Windows (GlazeWM) | zebar | ✗ stock `glzr-io.starter` pack |

Windows is the odd one out: `zebar/.glzr/zebar/settings.json` only records
*which* widget to launch. Its styling lives inside the Zebar pack, not in this
repo, so it is not Nord-themed. Theming it would mean vendoring a widget pack.

## The colour contract

Every module on the right side of the bar is a **solid Nord accent pill with
dark `#2e3440` text**. The accent identifies the module at a glance:

| Module | Accent | Hex | State override |
|---|---|---|---|
| cpu | nord14 green | `#a3be8c` | — |
| memory | nord15 purple | `#b48ead` | — |
| network | nord9 blue | `#81a1c1` | disconnected → nord11 red `#bf616a` |
| volume | nord13 yellow | `#ebcb8b` | muted → nord3 grey `#4c566a`, light text |
| battery | nord14 green | `#a3be8c` | charging → nord13 yellow; <20% → nord11 red |
| clock | nord10 indigo | `#5e81ac` | — |

Left side is unfilled: the focused workspace gets a nord10 indigo pill, and the
front-app name is a bare bold `#eceff4` label with no background.

The bar itself is `#2e3440` at 90% opacity (`0xe62e3440` in sketchybar's ARGB
notation) so the blur behind it reads, with a nord3 `#4c566a` border.

### Sizing

JetBrainsMono Nerd Font Bold at 13pt for labels and 15pt for icons, in 26pt
pills. Waybar sets `font-size: 13px`, so labels match; icons run two points
larger because Nerd Font glyphs read small next to digits at the same size.

Everything is Bold. Regular labels look noticeably thin here — dark text on a
saturated fill optically thins its strokes, the reverse of the light-on-dark
case waybar mostly deals with.

Only `Regular` and `Bold` are styles of the base family. JetBrains ships the
other weights as *separate families*, so Medium is
`JetBrainsMono Nerd Font Medium:Regular:13.0`, not
`JetBrainsMono Nerd Font:Medium:13.0` — the latter resolves to a fallback face
silently, with no error and no obvious visual tell.

The bar stays 32pt tall. `aerospace.toml` sets `gaps.outer.top = 44`, which is
the 32pt bar plus the same 12pt margin used on the other three sides — so
changing the bar height means changing that gap too, or windows will sit wrong.

### Deviation: dark text everywhere

Waybar is internally inconsistent. `#cpu`, `#pulseaudio` and `#temperature` set
`color: #2e3440`, but `#memory` and `#network` omit it and inherit light
`#d8dee9`. Light-on-green is roughly 1.4:1 contrast — legible only because you
already know what it says.

Sketchybar normalises to dark text on every saturated fill, about 8:1. If you
ever want them byte-identical, change waybar rather than sketchybar.

## Where colours live in sketchybar

Split by whether the colour is fixed or depends on state:

- **`sketchybarrc`** — the Nord palette, bar appearance, per-item padding, and
  each module's *default* fill. Static styling only.
- **`plugins/*.sh`** — colours that change with state. A plugin re-sends
  `background.color`, `icon.color` and `label.color` on every tick, so it owns
  its module's appearance whenever more than one state exists.

This is why `volume.sh`, `network.sh` and `battery.sh` each redeclare the Nord
values they need at the top. The `--set` in `sketchybarrc` only supplies the
colour used before the first tick.

Adding a module with no states? Set the fill in `sketchybarrc` and leave the
plugin to set `icon`/`label` only, as `cpu.sh` and `memory.sh` do.

## Sketchybar constraints worth knowing

Things waybar does with CSS that sketchybar cannot:

- **No bottom-only borders.** Waybar underlines the active workspace with
  `box-shadow: inset 0 -3px #88c0d0`. Sketchybar's `background.border_width`
  draws all four sides, so the active workspace uses a 1px cyan border around
  the whole pill instead. Faking a true underline needs a second thin item per
  workspace.
- **The bar border is not per-edge either.** `border_width` on `--bar` outlines
  the whole bar. Flush against the top of the screen, the bottom edge is
  effectively all you see, which is close enough to waybar's `border-bottom`.
- **Padding is per-component, not a box.** Waybar's `padding: 0 10px` becomes
  `icon.padding_left=8`, `icon.padding_right=4`, `label.padding_right=8` in
  sketchybar's `--default`. Item-level `padding_left/right` is the *gap between*
  modules, not interior space, so 2 either side yields waybar's `spacing: 4`.
- **No temperature module.** Waybar reads `/sys/class/hwmon`. Apple Silicon
  exposes no unprivileged temperature sensor — it needs `sudo powermetrics` or a
  third-party binary, which is not worth a sudoers rule for a bar that polls
  every 10 seconds.

## Gotchas

**Event-driven items need a fallback for their initial state.** `front_app` and
the workspace pills update from the `front_app_switched` and
`aerospace_workspace_change` events, and the variables those events carry —
`$INFO` and `$FOCUSED_WORKSPACE` — exist *only* while the event is being
handled. On `sketchybar --reload` or a fresh login no event has fired yet, so
both were empty: no workspace highlighted, no app name, until you happened to
switch something.

Both plugins now fall back to querying AeroSpace directly:

```bash
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
APP="${INFO:-$(aerospace list-windows --focused --format '%{app-name}')}"
```

Apply the same pattern to any new event-driven item. The event wiring itself is
in `aerospace.toml` under `exec-on-workspace-change`, which triggers the
sketchybar event — if a workspace pill stops updating on switch, check there
before suspecting the plugin.

**`airport` is dead.** macOS 14.4 gutted
`/System/Library/PrivateFrameworks/Apple80211.framework/.../airport`; it now
prints a deprecation warning and no data. `network.sh` reads the SSID from
`networksetup -getairportnetwork` instead, resolving the Wi-Fi device from
`networksetup -listallhardwareports` rather than assuming `en0`. Against the old
`airport` call the SSID came back empty, so the widget silently fell through to
its wired branch and displayed the Wi-Fi IP behind an ethernet icon.

## Working on the theme

```bash
sketchybar --reload           # apply changes to sketchybarrc
sketchybar --query cpu        # inspect one item's rendered state
sketchybar --query bar        # inspect bar colour, border, height
```

`--query` is the reliable way to check your changes landed. Colours come back as
ARGB (`0xffa3be8c`), and an item's background sits under `.geometry.background`,
not at the top level:

```bash
sketchybar --query cpu | python3 -c \
  "import json,sys; print(json.load(sys.stdin)['geometry']['background']['color'])"
```

Note that `screencapture` is not a shortcut here. Without Screen Recording
permission it silently returns the desktop wallpaper with no windows drawn, so a
screenshot can look like the bar vanished when it is rendering fine.

Because `~/.config/sketchybar` is a stow symlink into this repo, editing files
here changes the live config directly. Plugins take effect on their next tick;
`sketchybarrc` changes need a reload.
