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
- **hypr**: Hyprland compositor, hyprpaper, hyprlock, wallpapers, cliphist setup
- **nvim**: Neovim config with lazy.nvim, LSP, treesitter (C++ focused)
- **git**: Extensive git aliases and settings (uses meld for diff/merge)
- **clang**: clang-format (LLVM style) and clang-tidy config
- **foot/waybar/rofi/mako/starship**: Terminal and UI components (Nord themed)

### Install Script
`install.sh` handles: pacman packages, AUR packages (via yay), config backup, stow all packages, starship/ssh-agent shell integration, pipewire audio services.
