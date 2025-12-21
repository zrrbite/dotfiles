# Dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Requirements

- Arch Linux
- GNU Stow (`sudo pacman -S stow`)

## Installation

```bash
git clone git@github.com:YOUR_USER/dotfiles.git ~/dotfiles
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
| `foot`  | Foot terminal emulator - Nord theme, transparency, padding |

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
