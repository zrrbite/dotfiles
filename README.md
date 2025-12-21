# Dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Requirements

- Arch Linux
- GNU Stow
- JetBrainsMono Nerd Font
- Symbols Nerd Font (icon fallback)

```bash
sudo pacman -S stow ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols starship rofi-wayland wl-clipboard cliphist mako libnotify hyprlock btop grim slurp
```

## Fresh Install

On a new Arch Linux system with Hyprland:

```bash
# 1. Install dependencies
sudo pacman -S stow ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols starship rofi-wayland wl-clipboard cliphist mako libnotify hyprlock btop grim slurp hyprland hyprpaper waybar foot

# 2. Clone dotfiles
git clone https://github.com/zrrbite/dotfiles.git ~/dotfiles

# 3. Remove any existing configs that would conflict
rm -rf ~/.config/foot ~/.config/hypr ~/.config/waybar ~/.config/rofi ~/.config/mako ~/.config/starship.toml ~/.gitconfig ~/.clang-format ~/.clang-tidy

# 4. Stow all packages
cd ~/dotfiles
stow */

# 5. Add starship to your shell (add to ~/.bashrc or ~/.zshrc)
echo 'eval "$(starship init bash)"' >> ~/.bashrc

# 6. Log out and back in to start Hyprland
```

## Installation

If you already have configs and want to selectively install:

```bash
git clone https://github.com/zrrbite/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow */  # stow all packages
```

Or stow individual packages:

```bash
stow foot
```

## Packages

| Package | Description |
|---------|-------------|
| `btop`  | System monitor (Nord theme) |
| `clang` | clang-format (LLVM style) and clang-tidy (modern C++ checks) |
| `foot`  | Foot terminal emulator - Nord theme, transparency, padding |
| `git`   | Git config with extensive aliases for status, logging, branching, stashing |
| `hypr`  | Hyprland compositor + hyprpaper + hyprlock + cliphist |
| `mako`  | Notification daemon (Nord theme) |
| `rofi`  | App launcher with Nord theme |
| `starship` | Minimal shell prompt with Nerd Font icons |
| `waybar`| Status bar with workspaces, clock, system info (Nord theme) |

## Usage

```bash
cd ~/dotfiles

# Enable a package
stow <package>

# Remove a package's symlinks
stow -D <package>

# Re-stow (useful after adding files)
stow -R <package>

# Stow all packages
stow */
```

## Adding New Configs

1. Create the package directory mirroring the home structure:
   ```bash
   mkdir -p ~/dotfiles/nvim/.config/nvim
   ```

2. Move your config files:
   ```bash
   mv ~/.config/nvim/init.lua ~/dotfiles/nvim/.config/nvim/
   ```

3. Stow the package:
   ```bash
   cd ~/dotfiles && stow nvim
   ```

4. Commit:
   ```bash
   git add -A && git commit -m "Add nvim config"
   ```
