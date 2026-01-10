# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Cross-platform personal dotfiles supporting:
- **Arch Linux**: Full Hyprland desktop environment
- **WSL (Ubuntu/Debian)**: CLI development tools only
- **macOS (M1/M2/Intel)**: CLI tools + Alacritty terminal

All managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Commands

### Installation
```bash
./install_arch.sh     # Arch Linux (full Hyprland + all tools)
./install_wsl.sh      # WSL (CLI only, no GUI)
./install_darwin.sh   # macOS (Homebrew + Alacritty)
```

### Managing Configs with Stow
```bash
stow <package>        # Enable a package (creates symlinks)
stow -D <package>     # Remove a package's symlinks
stow -R <package>     # Re-stow (useful after adding files)
stow */               # Stow all packages
```

### Adding New Configs
1. Create directory mirroring home structure: `mkdir -p ~/dotfiles/foo/.config/foo`
2. Move config files into it
3. Run `stow foo` from dotfiles root

## Architecture

### Platform Structure

Each top-level directory is a stow package that mirrors the home directory structure:
- Files in `<package>/.config/X` symlink to `~/.config/X`
- Files in `<package>/.local/share/X` symlink to `~/.local/share/X`
- Files in `<package>/.filename` symlink to `~/.filename`

### Package Classification

**Universal (all platforms):**
- **git**: Git config and hooks (fully portable)
- **clang**: clang-format/clang-tidy configs (fully portable)
- **nvim**: Neovim full IDE setup (fully portable)
- **starship**: Shell prompt (fully portable)

**Platform-specific bash configs:**
- **bash/.bashrc-arch** - Arch Linux with all tools
- **bash/.bashrc-wsl** - WSL with CLI tools only
- **bash/.bashrc-darwin** - macOS with Homebrew paths
- Install scripts create symlinks to the appropriate variant

**Linux-only (Arch + optionally WSL):**
- **btop**: System monitor
- **gdb**: Debugger config (macOS uses lldb instead)

**Arch-only (native hardware with GPU):**
- **hypr**: Hyprland compositor, hyprpaper, hyprlock, wallpapers
- **foot**: Wayland terminal
- **waybar**: Status bar
- **rofi**: App launcher
- **mako**: Notifications
- **wlogout**: Logout menu
- **cava**: Audio visualizer
- **fastfetch**: System info
- **gtk/mimeapps/discord**: Desktop environment configs

**macOS/Optional:**
- **alacritty**: Cross-platform terminal with Nord theme

### Key Packages

- **bash**: Platform-specific shell configuration
  - Arch: Full setup with Hyprland auto-start, all aliases, bash-completion from `/usr/share`
  - WSL: CLI tools only, bash-completion from `/etc` or `/usr/share`, aliases for batcat/fdfind
  - macOS: Homebrew paths (`/opt/homebrew`), bash-completion from Homebrew location

- **nvim**: Neovim config with lazy.nvim, LSP (clangd), treesitter, DAP debugging, gitsigns (C++ focused)
  - Full IDE features: completion, diagnostics, refactoring, debugging
  - Git integration: blame, hunks, staging
  - Telescope fuzzy finder for symbols, files, macros
  - Batch clang-tidy fixes (`Space+cf`)

- **git**: Extensive git aliases (`git cf` for formatting), global pre-commit hook for clang-format enforcement
  - Uses meld for diff/merge (Arch/WSL) or built-in tools (macOS)
  - Global hooks at `~/.git-hooks/` (applies to all repos)

- **clang**: clang-format (LLVM/Allman style) and clang-tidy config
  - Pre-commit hook validates formatting with fun ASCII art

- **alacritty**: GPU-accelerated terminal with Nord theme
  - macOS primary terminal
  - Optional on Arch/WSL (foot is default on Arch)

### Install Scripts

- **install_arch.sh**: Pacman + AUR packages, full Hyprland setup, systemd services
- **install_wsl.sh**: apt packages + manual installs (starship, zoxide, eza, duf, git-delta, procs), CLI only
- **install_darwin.sh**: Homebrew packages, Alacritty setup, M2 ARM support

## Starting New C++ Projects

Use the bootstrap script to create new projects with optimal Claude Code workflow:

```bash
~/dotfiles/scripts/bootstrap-cpp-project.sh my-project-name
# Or specify custom location:
~/dotfiles/scripts/bootstrap-cpp-project.sh my-project ~/custom/path
```

**What it creates:**
- **CLAUDE.md** - Project context for Claude Code (architecture, build commands, common tasks)
- **.clangd** - LSP configuration for IDE features
- **CMakeLists.txt** - With `CMAKE_EXPORT_COMPILE_COMMANDS=ON` for LSP
- **.nvim.lua** - Project-specific debug configurations (DAP)
- **Directory structure** - src/, include/, tests/, doc/, build/
- **Git repository** - Initialized with first commit
- **README.md** - Basic project documentation
- **.gitignore** - Standard C++ ignores

**After creating a project:**
1. `cd ~/dev/my-project`
2. Edit `CLAUDE.md` with your project specifics
3. `cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`
4. `cmake --build build`
5. `ln -s build/compile_commands.json .` (for LSP)
6. `nvim .` (opens with debug configs ready)

**Templates are located at:** `~/dotfiles/templates/cpp-project/`
- Customize templates to match your preferred project structure
- Templates use `PROJECT_NAME` placeholder (auto-replaced by script)

## Recent Features & Important Notes

### Neovim C++ IDE Setup
- **LSP**: clangd with full C++ support (requires `compile_commands.json` for best results)
- **Debugging**: nvim-dap with codelldb adapter
  - F5: Start/Continue, F10: Step over, F11: Step into, F12: Step out
  - `Space+b`: Toggle breakpoint, `Space+du`: Toggle debug UI
- **Git**: gitsigns with inline blame, hunk staging/preview/reset
  - `Space+gb`: Toggle blame, `Space+hp`: Preview hunk, `Space+hs`: Stage hunk
- **Formatting**: `Space+F` for clang-format, `Space+cf` for batch clang-tidy fixes
- **Macros**: `Space+fm` to find #define macros (not visible in LSP symbols)
- **Generate impl**: `Space+ca` on function declaration to generate implementation

### Git Pre-commit Hook
- Global hook at `~/.git-hooks/pre-commit` enforces clang-format on all C++ commits
- Shows fun ASCII art `(╯°□°)╯︵ ┻━┻` when formatting violations detected
- Fix with `git cf` (formats staged files) or `git clang-format --staged`
- Bypass with `git commit --no-verify` (not recommended)

### Clang-tidy Configuration
- Disabled checks: const-correctness warnings (can be noisy)
- Edit `~/.clang-tidy` to disable specific warnings: add `-check-name,` to Checks list
- Restart nvim after changing `.clang-tidy`

### Unreal Engine Development
Neovim works well for UE C++ coding (7/10 feasibility):
- ✅ LSP, debugging, formatting all work with UE projects
- ⚠️ Generate `compile_commands.json` from UE project for best LSP results
- ❌ Use Unreal Editor for Blueprints, levels, assets (hybrid workflow recommended)
