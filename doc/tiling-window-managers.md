# Tiling Window Managers by OS

Quick reference of tiling window manager options across the platforms this
dotfiles repo supports. The row marked ✓ is what this repo ships configs for.

## Linux

| Manager | Protocol | Language | Notes |
|---|---|---|---|
| ✓ **Hyprland** | Wayland | C++ | Dynamic tiling with animations. Used here with waybar + rofi + mako. |
| Sway | Wayland | C | i3-compatible config, minimal, rock solid. |
| i3 | X11 | C | The reference manual tiler; huge ecosystem. |
| AwesomeWM | X11 | Lua | Fully scriptable in Lua, very flexible. |
| bspwm | X11 | C | Binary-space partitioning, external keybinds via sxhkd. |
| dwm | X11 | C | Suckless; configure by patching source. |
| Qtile | X11/Wayland | Python | Scripted in Python. |
| XMonad | X11 | Haskell | Scripted in Haskell, legendary stability. |
| Niri | Wayland | Rust | Scrollable columns (PaperWM-style), newer. |

**This repo uses Hyprland** — see `hypr/`, `waybar/`, `rofi/`, `mako/`,
`foot/`, `wlogout/`. Installed via `./install_arch.sh`.

## Windows

| Manager | Language | Config | Notes |
|---|---|---|---|
| ✓ **GlazeWM** | Rust | YAML | i3-inspired, paired with Zebar for status bar. Most popular (~12k stars). |
| Whim | C# | YAML/JSON + C# scripting | Plugin architecture, multiple layout engines (tree/slice). Pre-1.0. |
| komorebi | Rust | JSON | bspwm-style, uses AutoHotkey or whkd for bindings. Mature. |
| Jwno | Janet | Janet scripting | Lisp-family REPL-driven, UIAutomation integration. Niche. |
| FancyWM | C# | GUI | Microsoft Store app, tree tiling, beginner-friendly. |

**This repo uses GlazeWM + Zebar** — see `glazewm/`, `zebar/`. Installed via
`./install_windows.ps1`. Paired with PowerToys Run (`Ctrl+Space`) for a
Spotlight-style launcher and optionally WinLaunch for a Launchpad-style grid.

## macOS

| Manager | Language | Config | Notes |
|---|---|---|---|
| yabai | C | `yabairc` shell script | Most powerful. Requires partially disabling SIP for full features. Pairs with skhd for hotkeys. |
| ✓ **AeroSpace** | Swift | TOML | i3-style, no SIP changes needed. Config in dotfiles repo. |
| Amethyst | Swift | GUI preferences | Simple automatic tiling, no scripting, very low friction. |
| Rectangle | Swift | GUI | Window snapping only (not true tiling), but often "enough". Free. |
| Magnet | Swift | GUI | Paid snapping tool, Mac App Store. |
| Phoenix | JS | JavaScript config | Scriptable window manager, not strictly tiling. |

**This repo uses AeroSpace** — see `aerospace/`. Installed via `./install_darwin.sh`.
Keybinds match GlazeWM (Windows) and Hyprland (Linux) for cross-platform muscle memory.

## Cross-platform convergence

The Hyprland-style workflow this repo targets on Linux maps reasonably well
across platforms:

| Role | Linux (Arch) | Windows | macOS (recommended) |
|---|---|---|---|
| Window manager | Hyprland | GlazeWM | ✓ AeroSpace |
| Status bar | Waybar | Zebar | ✓ sketchybar |
| Launcher | Rofi | PowerToys Run (`Ctrl+Space`) | Raycast / Spotlight |
| Notifications | Mako | Windows native | macOS native |
| App grid | (n/a) | WinLaunch | Launchpad (built-in) |
| Terminal | Foot | Windows Terminal / Alacritty | Alacritty |

Hotkey conventions across platforms in this repo:
- `Alt+HJKL` — focus direction
- `Alt+Shift+HJKL` — move window
- `Alt+1..9` — switch workspace
- `Alt+Shift+1..9` — move window to workspace
- `Ctrl+Space` — launcher (Windows); `Alt+R` on Hyprland
