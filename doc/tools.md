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
| Ghostty | Terminal (`ctrl-alt-enter`) | ✓ | – | – | – |
| Alacritty | Terminal; dropped from macOS 2026-10-12 | – | config only | – | – |
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
| OrbStack | Docker on macOS (`docker`, `docker compose`) for devbox and `scripts/test-in-docker.sh`; replaced Docker Desktop 2026-10-12 | ✓ | – | – | – |
| lazygit | Terminal UI for git: looking around a repo, staging lines, tidying commits; `Ctrl+a g` in tmux, `Space gg` in nvim (`doc/lazygit.md`) | ✓ | – | – | – |
| remote + FUSE-T sshfs | Work on another machine over SSH: mount, read, search, build, test (`doc/remote-machine.md`) | ✓ | – | – | – |
| cmake + ninja + ccache | C++ builds with presets (`cmake --preset debug`) and a compiler cache (`scripts/bootstrap-cpp-project.sh`) | ✓ | – | – | cmake |
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

## Versions and upgrading

Nothing here pins a version except where the table says so: an installer
gets whatever Homebrew, pacman or apt has that day. The table says which
version each config was last checked against (Martin's MacBook, 2026-10-12)
and what to look at when an upgrade jumps past it. Update a row when you
re-check it.

| Tool | Checked against | After a big upgrade |
|---|---|---|
| AeroSpace | 0.21.3, `config-version = 2` | **Restart it** (`killall AeroSpace && open -a AeroSpace`): until then the old version keeps running and every `aerospace` command fails with "client and server versions are incompatible". Restarting drops all windows on one workspace; capture the layout first (`doc/aerospace-macos.md`). `verify.sh` checks the bindings are `ctrl-alt` |
| AutoRaise | 5.7 | `brew services restart autoraise`. If focus stops following the mouse, macOS took its Accessibility away: remove it in System Settings → Privacy & Security → Accessibility and add `/opt/homebrew/opt/autoraise/bin/AutoRaise` again |
| sketchybar, sketchybar-app-font | 2.24.0, font 3.0.5 | The font must be at least the release `plugins/icon_map.sh` was vendored from, or app names show as text in the workspace pills. `sketchybar --reload` |
| yazi | 26.9.1 | `keymap.toml`'s keys were written against this preset, and yazi renames keys between releases: compare with the new preset. `ya pkg upgrade` for the plugins |
| lazygit | 0.66.0 | The keys in `doc/lazygit.md`: `lazygit --config` prints the new defaults |
| Ghostty | 1.3.1 | `ghostty +validate-config` |
| Neovim | 0.12.5 | `:Lazy sync`, then `:checkhealth`. `Space gg` needs 0.11+ (`jobstart` with `term = true`) |
| tmux, its plugins | 3.7c; tmux-resurrect v4.0.0, tmux-continuum v3.1.0 | The plugins are **pinned** by tag in the installers; they move only when the tag does |
| clang-format (LLVM) | 23.1.2 | A new major version can reformat code you didn't touch, and the pre-commit hook then refuses those files. That's why `install_darwin.sh` doesn't upgrade by default |
| TypeScript, for nvim's `ts_ls` | typescript 6.0.3, typescript-language-server 6.0.1 | **Pinned to 6**: TypeScript 7 has no `tsserver`, which `ts_ls` needs |
| Karabiner-Elements | 16.3.0 | It rewrites `karabiner.json` when its settings change: read the `git diff`. `verify.sh` checks its driver is approved |
| OrbStack, docker | 2.2.4, docker 29.8.2 | `docker exec` runs with umask 0000 here (`scripts/test-in-docker.sh` sets 022). `scripts/test-in-docker.sh debian:12` is the end-to-end check |
| CMake, Ninja, ccache | 4.4.4, 1.13.2, 4.14.1 | The presets are format version 3 (CMake 3.21+) |
| FUSE-T, its sshfs | casks 1.2.9, 1.0.2 | `scripts/test-remote.sh` against the test host (`doc/remote-machine.md`) |
| Hyprland (Arch) | 0.56 | **0.57 stops reading `hyprland.conf`**: the Lua port waits on branch `hypr-lua` |

### Upgrading a Mac

```bash
mkdir -p ~/.local/state/dotfiles
brew list --versions > ~/.local/state/dotfiles/brew-before-$(date +%F).txt
aerospace list-windows --all --format '%{window-id} %{workspace}' > /tmp/layout
brew upgrade             # formulae and casks; .pkg casks ask for the password
```

Then:

1. Restart AeroSpace and put the windows back (the loop in
   `doc/aerospace-macos.md`, "Restarting loses your window placement").
2. `brew services restart autoraise`, and check focus follows the mouse.
3. `sketchybar --reload`; in nvim `:Lazy sync`; `ya pkg upgrade`.
4. `scripts/verify.sh`. It also finds the zsh completions a removed cask
   leaves dangling (a new terminal then prints `compinit: ... no such file
   or directory`).
5. Compare against the "before" list and the table above for anything that
   moved a major version.

Casks that update themselves (Ghostty, OrbStack, Raycast, Karabiner) are
skipped by `brew upgrade` unless you add `--greedy`.

## Not installed by the repo

Installed by hand, or decided per machine. Each has a `CHANGELOG.md` note.

- **Raycast's settings** (macOS): the installer installs Raycast, but its
  settings live in its own database. Add `scripts/raycast/` once, in Settings →
  Extensions → + → Add Script Directory.
- **Alfred and Rectangle Pro** (macOS) are uninstalled on Martin's main Mac:
  Alfred clashed with Raycast, Rectangle Pro with AeroSpace. Alfred went on
  2026-10-12; its settings folder stays, with the Powerpack licence.
- **Per-project `.envrc` files:** they live in each project, not here.
