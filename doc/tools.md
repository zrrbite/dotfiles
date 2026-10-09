# Tools at a glance

What each OS gets from this repo, grouped by what it's **for**. Read this
first to know what's available on a machine. The **exact package names** live
in the installers and aren't repeated here:

| OS | Package lists |
|---|---|
| macOS | `BREW_PACKAGES`, `BREW_CASKS` in `install_darwin.sh` |
| Arch | `PACKAGES`, `AUR_PACKAGES` in `install_arch.sh` |
| Debian / WSL / Pi | `APT_PACKAGES` and the manual installs in `install_debian.sh` |
| Windows | the Scoop list in `install_windows.ps1` |
| Stowed configs, every OS | `scripts/packages.sh` |

✓ installed and configured · – not on that OS. "Debian" covers Ubuntu, WSL
and Raspberry Pi.

## Shell and terminal

| Tool | For | macOS | Arch | Debian | Windows |
|---|---|:-:|:-:|:-:|:-:|
| zsh + oh-my-zsh | Login shell; one shared `.zshrc` | ✓ | ✓ | ✓ | – |
| bash | Login shell (Git Bash) | – | – | – | ✓ |
| zsh-autosuggestions, zsh-syntax-highlighting | Grey history suggestions, green/red commands | ✓ | ✓ | ✓ | – |
| starship | Prompt (Nord) | ✓ | ✓ | ✓ | ✓ |
| Ghostty | Terminal, default (`ctrl-alt-enter`) | ✓ | – | – | – |
| Alacritty | Terminal, second (`ctrl-alt-shift-enter`) | ✓ | config only | – | – |
| foot | Terminal (Wayland) | – | ✓ | – | – |
| Windows Terminal | Terminal | – | – | – | ✓ |
| tmux + resurrect + continuum | Sessions per project, surviving reboots; `t`, `tp`, `Ctrl+a` `f` | ✓ | ✓ | ✓ | – |
| direnv | Per-folder environments (`.envrc`, `use venv`) | ✓ | ✓ | ✓ | – |
| fastfetch | System info at shell start | ✓ | ✓ | – | ✓ |

## Files and navigation

| Tool | For | macOS | Arch | Debian | Windows |
|---|---|:-:|:-:|:-:|:-:|
| yazi | Terminal file manager, `y`; git status, Markdown preview; keys in `doc/yazi.md` | ✓ | ✓ | – | – |
| chafa | Images in the terminal; `fimg` | ✓ | ✓ | – | – |
| glow | Markdown in the terminal (and yazi previews) | ✓ | ✓ | – | – |
| zoxide | Frecent `cd` (`cd` is zoxide on macOS) | ✓ | ✓ | ✓ | ✓ |
| fzf | Fuzzy finder (`Ctrl+R`, `tp`, `fimg`) | ✓ | ✓ | ✓ | ✓ |
| eza | Listings with icons and git status (`ll`, `lt`, `la`; `ls` stays `ls`) | ✓ | ✓ | ✓ | ✓ |
| fd, ripgrep | Find files / search contents | ✓ | ✓ | ✓ | ✓ |
| bat | `cat` with syntax highlighting, Nord theme (`batcat` on Debian; default theme on Windows) | ✓ | ✓ | ✓ | ✓ |
| duf, procs, btop | Disks, processes, system monitor (btop in Nord, via `scripts/seed-btop-config.sh`) | ✓ | ✓ | ✓ | duf, procs |
| tldr | Short man pages | ✓ | ✓ | ✓ | – |
| tree, wget | Directory trees, downloads | ✓ | – | – | – |
| ffmpeg, poppler, 7-Zip | yazi preview helpers (video, PDF, archives) | ✓ | – | – | – |

## Git and code

| Tool | For | macOS | Arch | Debian | Windows |
|---|---|:-:|:-:|:-:|:-:|
| git + delta | Shared config; identity in `~/.gitconfig.local`; delta for diffs | ✓ | ✓ | ✓ | ✓ |
| Global git hooks | clang-format on commit, clang-tidy / TS checks on push | ✓ | ✓ | ✓ | ✓ |
| neovim | Editor: LSP, treesitter, DAP, yazi.nvim | ✓ | ✓ | ✓ | ✓ |
| gh | GitHub from the terminal: PRs, issues, Actions runs | ✓ | – | – | – |
| lazygit | Terminal UI for git: stage hunks, fixup, reorder, reword (on trial since 2026-10-08) | ✓ | – | – | – |
| remote + FUSE-T sshfs | Work on another machine over SSH: mount, read, search, build, test (`doc/remote-machine.md`) | ✓ | – | – | – |
| cmake + ninja | C++ builds (`scripts/bootstrap-cpp-project.sh`) | ✓ | – | – | cmake |
| clang-format, clang-tidy, clangd | C++ formatting, linting, LSP | ✓ | ✓ | ✓ | ✓ |
| gdb (+ dashboard) / lldb | Debuggers (lldb on macOS, via llvm) | lldb | gdb | gdb | – |
| node | TypeScript language server for nvim | ✓ | – | – | – |
| meld / nvimdiff | Diff and merge tool (nvimdiff on macOS) | nvimdiff | meld | – | meld |
| VS Code (`code`) | Second editor | – | ✓ | – | – |
| TeX Live | LaTeX | – | ✓ | – | – |

## Desktop

| Tool | For | macOS | Arch | Debian | Windows |
|---|---|:-:|:-:|:-:|:-:|
| AeroSpace / Hyprland / GlazeWM | Tiling window manager, same `hjkl` keys (⌃⌥ / Super / Alt) | AeroSpace | Hyprland | – | GlazeWM |
| sketchybar / waybar / zebar | Status bar (Nord) | sketchybar | waybar | – | zebar |
| JankyBorders | Window borders | ✓ | – | – | – |
| AutoRaise | Focus follows mouse | ✓ | (Hyprland) | – | – |
| Raycast / rofi + cliphist | Launcher, clipboard history (`⌃⌥⇧V` / `Super+Shift+V`); Raycast runs `scripts/raycast/` | Raycast | rofi | – | – |
| mako, hyprlock, hypridle, wlogout | Notifications, lock screen, idle, logout menu | – | ✓ | – | – |
| grim, slurp, satty, wf-recorder | Screenshots and recording | – | ✓ | – | – |
| JetBrains Mono Nerd Font | Font everywhere; sketchybar-app-font for bar icons (macOS) | ✓ | ✓ | – | ✓ |
| Finder settings | Hidden files, path bar, list view (`scripts/finder-defaults.sh`) | ✓ | – | – | – |
| macOS settings | Hidden Dock and menu bar, AeroSpace's Mission Control settings, no smart quotes (`scripts/macos-defaults.sh`) | ✓ | – | – | – |
| Karabiner-Elements | Caps Lock: Escape when tapped, Control when held | ✓ | – | – | – |
| pam-reattach | Touch ID for `sudo`, also inside tmux (`scripts/touch-id-sudo.sh`) | ✓ | – | – | – |

## Not installed by the repo

Installed by hand, or decided per machine. Each has a `CHANGELOG.md` note.

- **Raycast's settings** (macOS): the installer installs Raycast, but its
  settings live in its own database. Add `scripts/raycast/` once, in Settings →
  Extensions → + → Add Script Directory.
- **Alfred, Rectangle Pro** (macOS): they conflict with Raycast and
  AeroSpace. On Martin's main Mac, Alfred is paused and Rectangle Pro is
  uninstalled.
- **Per-project `.envrc` files:** they live in each project, not here.
