# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for a Nord-themed Hyprland setup on Arch Linux, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Commands

### Installation
```bash
./install.sh          # Full install (packages + stow all configs)
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

Each top-level directory is a stow package that mirrors the home directory structure:
- Files in `<package>/.config/X` symlink to `~/.config/X`
- Files in `<package>/.local/share/X` symlink to `~/.local/share/X`
- Files in `<package>/.filename` symlink to `~/.filename`

### Key Packages
- **bash**: Shell configuration with bash-completion, aliases, fzf/zoxide integration
  - Requires `bash-completion` package for git branch/tag autocomplete
  - Loads completion from `/usr/share/bash-completion/bash_completion`
- **hypr**: Hyprland compositor, hyprpaper, hyprlock, wallpapers, cliphist setup
- **nvim**: Neovim config with lazy.nvim, LSP (clangd), treesitter, DAP debugging, gitsigns (C++ focused)
  - Full IDE features: completion, diagnostics, refactoring, debugging
  - Git integration: blame, hunks, staging
  - Telescope fuzzy finder for symbols, files, macros
  - Batch clang-tidy fixes (`Space+cf`)
- **git**: Extensive git aliases (`git cf` for formatting), global pre-commit hook for clang-format enforcement
  - Uses meld for diff/merge
  - Global hooks at `~/.git-hooks/` (applies to all repos)
- **clang**: clang-format (LLVM/Allman style) and clang-tidy config
  - Pre-commit hook validates formatting with fun ASCII art
- **foot/waybar/rofi/mako/starship**: Terminal and UI components (Nord themed)

### Install Script
`install.sh` handles: pacman packages, AUR packages (via yay), config backup, stow all packages, starship/ssh-agent shell integration, pipewire audio services.

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
