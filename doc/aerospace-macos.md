# AeroSpace on macOS

How the tiling setup works on macOS, and the things that will confuse you at
least once. Keybinds deliberately mirror GlazeWM (Windows) and Hyprland (Linux)
from this repo, so the same muscle memory works on all three.

Config lives in `aerospace/.config/aerospace/aerospace.toml`.

## Alt means Option

Every binding below uses `alt`, which on a Mac is the **Option (⌥)** key —
between `control` and `command`, usually labelled `alt` on keyboards sold in
Europe. On an external PC keyboard the physical `Alt` maps to Option by default
(remappable under System Settings → Keyboard → Keyboard Shortcuts → Modifier
Keys).

## What actually runs

Four processes, started three different ways:

| Process | What it does | How it starts |
|---|---|---|
| AeroSpace | Tiles windows, owns the keybinds | `start-at-login = true` |
| sketchybar | Status bar | AeroSpace `after-startup-command` |
| borders | Glow around the active window | AeroSpace `after-startup-command` |
| AutoRaise | Focus follows mouse | launchd service (`brew services`) |

AutoRaise is deliberately *not* in `after-startup-command`. As a launchd service
it starts at login on its own and survives restarting AeroSpace; listing it in
both places would leave two instances polling the cursor. See
[status-bar-theming.md](status-bar-theming.md) for the bar itself.

## Keybindings

### Focus and move

| Key | Action |
|---|---|
| `alt` + `h/j/k/l` | Focus left / down / up / right |
| `alt-shift` + `h/j/k/l` | Move the focused window in that direction |
| `alt-tab` | Cycle to the next window in the workspace |
| `alt-shift-tab` | Cycle to the previous window |

Two ways to change focus. The `hjkl` bindings are **directional** — with two
windows side by side, `alt-l` and `alt-h` move between them. `alt-tab` instead
walks every window in the workspace in tree order (`focus dfs-next`), which is
easier when you have several windows and do not want to think about where they
sit.

Neither wraps into other workspaces; use `alt-1`–`alt-9` or `alt-s`/`alt-a` for
that.

### Workspaces

| Key | Action |
|---|---|
| `alt` + `1`–`9` | Switch to workspace N |
| `alt-shift` + `1`–`9` | Move window to workspace N **and follow it** |
| `alt-s` / `alt-a` | Next / previous workspace |
| `alt-d` | Back and forth between the last two |
| `alt-shift-a` / `alt-shift-f` | Move the whole workspace to the previous / next monitor |

### Layout

| Key | Action |
|---|---|
| `alt-v` | Toggle tiling direction: tiles horizontal ↔ vertical |
| `alt-f` | Toggle fullscreen |
| `alt-shift-space` | Toggle floating / tiling |

### Windows and session

| Key | Action |
|---|---|
| `alt-enter` | New Alacritty window (`open -na`, so it really is a new one) |
| `alt-shift-q` | Close the focused window |
| `alt-shift-r` | Reload the config |

### Resizing

Either nudge directly, or enter a mode and stay there:

| Key | Action |
|---|---|
| `alt-u` / `alt-p` | Width −50 / +50 |
| `alt-i` / `alt-o` | Height −50 / +50 |
| `alt-r` | Enter resize mode |

In resize mode, `h`/`l` change width, `j`/`k` change height, and `esc` or
`enter` returns to main mode. Nothing else is bound there, so if the keyboard
seems dead, you are probably still in resize mode — press escape.

## Layouts, and the trap in them

AeroSpace has two layout algorithms, each with a horizontal and a vertical
orientation. The config defaults to `tiles` with `auto` orientation, which
picks horizontal on a display wider than it is tall.

- **tiles** — i3 style. Windows split the space and never overlap.
- **accordion** — windows stack, with only the focused one expanded.

**Accordion is the one that will confuse you.** It looks exactly like a broken
tiling layout: another window sits "beneath" the focused one and you can still
focus it, and resizing appears to make the focused window fill the screen. It is
easy to land in without meaning to — collapsing many windows into one workspace
can leave a nested container in accordion.

The fix is `alt-v`, or from a shell:

```bash
aerospace layout tiles horizontal
```

Note that `aerospace layout horizontal` alone is **not** enough: accordion has
horizontal and vertical variants too, so setting only the orientation leaves you
in accordion. Change the layout, not just the direction.

`layout` exits **1 when the change is a no-op** — that is, when you are already
in the requested layout — and 0 when it actually changed something. An exit of 1
with no error message means there was nothing to do, not that the command
failed. The same applies to `fullscreen`. Read `$?` directly; piping the command
into anything gives you the pipeline's exit code instead.

`alt-f` fullscreen produces a similar "the other window vanished" impression.
`aerospace fullscreen off --fail-if-noop` tells you which it was: exit 0 means
the window really was fullscreen and has been un-fullscreened, exit 1 means it
was not. Check `$?` directly rather than through a pipe, or you will read the
exit code of the last command in the pipeline instead.

If the tree itself is tangled, flatten it:

```bash
aerospace flatten-workspace-tree     # applies to the focused workspace
```

## Restarting loses your window placement

AeroSpace has **no session persistence**. Restarting it re-detects every window
and drops them all onto the focused workspace; your arrangement across
workspaces is gone. There is also no `restart` subcommand — only
`reload-config`, which re-reads the config but does not re-run
`after-startup-command`.

So capture the layout before restarting:

```bash
aerospace list-windows --all --format '%{window-id} %{workspace}' > /tmp/layout
```

and put it back afterwards:

```bash
while read -r id ws; do
    aerospace move-node-to-workspace --window-id "$id" "$ws"
done < /tmp/layout
```

A full restart, when you need one:

```bash
killall AeroSpace && open -a AeroSpace
```

sketchybar and borders detect a running instance and will not duplicate when
`after-startup-command` fires again. AutoRaise is untouched by this entirely,
since launchd owns it.

Expect to run `flatten-workspace-tree` afterwards — unwinding the collapse tends
to leave nested containers behind.

## Focus follows mouse

This comes from AutoRaise, not AeroSpace. AeroSpace has no focus-follows-mouse
setting at all; version 0.20.3-Beta contains no such option.

Confusingly, `aerospace.toml` does contain:

```toml
on-focus-changed = ['move-mouse window-lazy-center']
```

That is the **opposite** direction — mouse follows focus — and it must stay.
It warps the cursor onto whatever window you focus by keyboard. Without it the
cursor would still be sitting over the *previous* window, and AutoRaise would
immediately take focus straight back.

Hold `control` to suspend focus-follows-mouse temporarily. Configuration and
options are in the [README](../README.md#macos-m1m2intel).

## Gaps

```toml
inner.horizontal = 20    inner.vertical = 20
outer.left = 12          outer.right = 12        outer.bottom = 12
outer.top = 44
```

`outer.top` is not arbitrary: it is the 32pt sketchybar height plus the same
12pt margin used on the other three sides. Change the bar height and this has to
change with it, or windows will sit under the bar or float below it.

## Useful commands

```bash
aerospace list-windows --all          # every window, with workspace
aerospace list-windows --focused      # just the focused one
aerospace list-workspaces --focused   # which workspace am I on
aerospace list-workspaces --monitor all --empty no   # workspaces in use
aerospace reload-config               # after editing the toml
aerospace move-node-to-workspace --window-id <id> <ws>
```

One caveat on introspection: `aerospace config --get` only resolves `mode.*`
keys in 0.20.3. Every root-level key — `gaps`, `after-startup-command`,
`on-focus-changed`, even `start-at-login` — returns "No value at key token" even
though the setting is live. To check what the config actually says, parse the
file:

```bash
python3 -c "import tomllib; print(tomllib.load(open('$HOME/.config/aerospace/aerospace.toml','rb')))"
```
