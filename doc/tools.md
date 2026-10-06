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
| Ghostty | Terminal, default (`alt-enter`) | ✓ | – | – | – |
| Alacritty | Terminal, second (`alt-shift-enter`) | ✓ | config only | – | – |
| foot | Terminal (Wayland) | – | ✓ | – | – |
| Windows Terminal | Terminal | – | – | – | ✓ |
| tmux + resurrect + continuum | Sessions per project, surviving reboots; `t`, `tp`, `Ctrl+a` `f` | ✓ | ✓ | ✓ | – |
| direnv | Per-folder environments (`.envrc`, `use venv`) | ✓ | ✓ | ✓ | – |
| fastfetch | System info at shell start | ✓ | ✓ | – | ✓ |

## Files and navigation

| Tool | For | macOS | Arch | Debian | Windows |
|---|---|:-:|:-:|:-:|:-:|
| yazi | Terminal file manager, `y`; git status, Markdown preview | ✓ | ✓ | – | – |
| chafa | Images in the terminal; `fimg` | ✓ | ✓ | – | – |
| glow | Markdown in the terminal (and yazi previews) | ✓ | ✓ | – | – |
| zoxide | Frecent `cd` (`cd` is zoxide on macOS) | ✓ | ✓ | ✓ | ✓ |
| fzf | Fuzzy finder (`Ctrl+R`, `tp`, `fimg`) | ✓ | ✓ | ✓ | ✓ |
| eza | `ls` with icons and git status | ✓ | ✓ | ✓ | ✓ |
| fd, ripgrep | Find files / search contents | ✓ | ✓ | ✓ | ✓ |
| bat | `cat` with syntax highlighting, Nord theme (`batcat` on Debian; default theme on Windows) | ✓ | ✓ | ✓ | ✓ |
| duf, procs, btop | Disks, processes, system monitor (btop in Nord, via `scripts/seed-btop-config.sh`) | ✓ | ✓ | ✓ | duf, procs |
| tldr | Short man pages | ✓ | ✓ | ✓ | – |
| ffmpeg, poppler, 7-Zip | yazi preview helpers (video, PDF, archives) | ✓ | – | – | – |

## Git and code

| Tool | For | macOS | Arch | Debian | Windows |
|---|---|:-:|:-:|:-:|:-:|
| git + delta | Shared config; identity in `~/.gitconfig.local`; delta for diffs | ✓ | ✓ | ✓ | ✓ |
| Global git hooks | clang-format on commit, clang-tidy / TS checks on push | ✓ | ✓ | ✓ | ✓ |
| neovim | Editor: LSP, treesitter, DAP, yazi.nvim | ✓ | ✓ | ✓ | ✓ |
| clang-format, clang-tidy, clangd | C++ formatting, linting, LSP | ✓ | ✓ | ✓ | ✓ |
| gdb (+ dashboard) / lldb | Debuggers (lldb on macOS, via llvm) | lldb | gdb | gdb | – |
| node | TypeScript language server for nvim | ✓ | – | – | – |
| meld / nvimdiff | Diff and merge tool (nvimdiff on macOS) | nvimdiff | meld | – | meld |
| VS Code (`code`) | Second editor | – | ✓ | – | – |
| TeX Live | LaTeX | – | ✓ | – | – |

## Desktop

| Tool | For | macOS | Arch | Debian | Windows |
|---|---|:-:|:-:|:-:|:-:|
| AeroSpace / Hyprland / GlazeWM | Tiling window manager, same `hjkl` keys | AeroSpace | Hyprland | – | GlazeWM |
| sketchybar / waybar / zebar | Status bar (Nord) | sketchybar | waybar | – | zebar |
| JankyBorders | Window borders | ✓ | – | – | – |
| AutoRaise | Focus follows mouse | ✓ | (Hyprland) | – | – |
| rofi + cliphist | Launcher, clipboard history | – | ✓ | – | – |
| mako, hyprlock, hypridle, wlogout | Notifications, lock screen, idle, logout menu | – | ✓ | – | – |
| grim, slurp, satty, wf-recorder | Screenshots and recording | – | ✓ | – | – |
| JetBrains Mono Nerd Font | Font everywhere; sketchybar-app-font for bar icons (macOS) | ✓ | ✓ | – | ✓ |
| Finder settings | Hidden files, path bar, list view (`scripts/finder-defaults.sh`) | ✓ | – | – | – |

## Not installed by the repo

Installed by hand, or decided per machine. Each has a `CHANGELOG.md` note.

- **Raycast** (macOS): launcher, on trial. `brew install --cask raycast`,
  then add `scripts/raycast/` in its settings. Not in the installer until the
  trial ends.
- **Alfred, Rectangle Pro** (macOS): they conflict with Raycast and
  AeroSpace. On Martin's main Mac, Alfred is paused and Rectangle Pro is
  uninstalled.
- **Per-project `.envrc` files:** they live in each project, not here.
