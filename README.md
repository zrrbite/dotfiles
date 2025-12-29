# Dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).

Nord-themed Hyprland setup for Arch Linux.

## Quick Install

On a fresh Arch Linux system:

```bash
git clone https://github.com/zrrbite/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

The install script will:
- Install all required packages via pacman
- Backup any existing configs to `~/.config-backup-TIMESTAMP/`
- Stow all packages
- Setup starship prompt
- Enable audio (pipewire)

Then log out and select Hyprland as your session.

## What's Included

- **Desktop**: Hyprland, waybar, rofi, mako notifications
- **Terminal**: foot with Nord theme, starship prompt
- **Audio**: pipewire + wireplumber, pavucontrol
- **Media**: mpv (video), imv (images)
- **Files**: thunar file manager
- **Dev**: neovim, gdb + gdb-dashboard, clang-format, clang-tidy, TeX Live (beamer)
- **Fonts**: JetBrains Mono Nerd, CJK (Chinese/Japanese/Korean), emoji
- **Utils**: screenshots, screen recording (wf-recorder), clipboard history, screen lock
- **Idle**: Lock at 5min, display off at 10min, suspend at 30min (hypridle)

## Key Bindings

| Binding | Action |
|---------|--------|
| `Super + Q` | Terminal (foot) |
| `Super + E` | File manager (thunar) |
| `Super + R` | App launcher (rofi) |
| `Super + C` | Close window |
| `Super + L` | Lock screen |
| `Super + Shift + V` | Clipboard history |
| `Super + Shift + S` | Screenshot region |
| `Super + Shift + R` | Toggle screen recording |
| `Super + Ctrl + R` | Toggle region recording |
| `Super + B` | Next window below (vertical) |
| `Super + N` | Next window right (horizontal) |
| `Super + J` | Toggle split direction |
| `Super + F1` | Show all keybinds |

## Manual Installation

If you prefer to install selectively:

```bash
git clone https://github.com/zrrbite/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow foot      # just terminal
stow hypr      # just hyprland
stow */        # everything
```

## Packages

| Package | Description |
|---------|-------------|
| `btop`  | System monitor (Nord theme) |
| `clang` | clang-format (LLVM style) and clang-tidy (modern C++ checks) |
| `gdb`   | GDB debugger config - gdb-dashboard, pretty printing, custom commands |
| `discord` | Desktop entry override for native Wayland support |
| `foot`  | Foot terminal emulator - Nord theme, transparency, padding |
| `git`   | Git config with extensive aliases for status, logging, branching, stashing |
| `hypr`  | Hyprland compositor + hyprpaper + hyprlock + hypridle + cliphist |
| `mako`  | Notification daemon (Nord theme) |
| `nvim`  | Neovim IDE setup - LSP, treesitter, telescope (C++ focused) |
| `rofi`  | App launcher with Nord theme |
| `starship` | Minimal shell prompt with Nerd Font icons |
| `waybar`| Status bar with workspaces, clock, system info (Nord theme) |

## GDB Debugging

The gdb config includes [gdb-dashboard](https://github.com/cyrus-and/gdb-dashboard) for a visual debugging interface showing source, assembly, variables, stack, and registers.

### Dashboard Commands

```bash
dashboard                          # Show current layout
dashboard -enabled off             # Disable (vanilla gdb)
dashboard -layout source stack     # Customize panels
dashboard source -style height 30  # Resize a panel
```

### Custom GDB Commands

| Command | Description |
|---------|-------------|
| `pa <arr> <len>` | Print raw array |
| `pv <vector>` | Print std::vector contents |
| `pm <map>` | Print std::map contents |
| `pl <head>` | Print linked list |
| `btall` | Backtrace all threads |
| `bpl` / `bpc` | List / clear breakpoints |
| `ctx` | Show source context at PC |

Project-local `.gdbinit` files are auto-loaded from `~/dev/`.

## Clang Tools

The `clang` package provides `.clang-format` (LLVM-based, C++20) and `.clang-tidy` (modernize, bugprone, performance checks) configs in your home directory. Tools automatically find these when run from any subdirectory.

### Command Line

```bash
# Format a single file (in-place)
clang-format -i src/main.cpp

# Format all C++ files in a directory
find src -name '*.cpp' -o -name '*.hpp' | xargs clang-format -i

# Check formatting without modifying (CI/pre-commit)
clang-format --dry-run --Werror src/*.cpp

# Run clang-tidy on a file (needs compile_commands.json)
clang-tidy src/main.cpp

# Run clang-tidy and apply fixes
clang-tidy -fix src/main.cpp

# Run on entire project
find src -name '*.cpp' | xargs clang-tidy
```

### Generate compile_commands.json

clang-tidy needs a compilation database:

```bash
# CMake (recommended)
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -s build/compile_commands.json .

# Bear (wrap any build system)
bear -- make
```

### VS Code with clangd

Install the [clangd extension](https://marketplace.visualstudio.com/items?itemName=llvm-vs-code-extensions.vscode-clangd) (disable Microsoft C/C++ IntelliSense).

clangd automatically uses your `.clang-format` and `.clang-tidy` configs. Add to `.vscode/settings.json`:

```json
{
    "clangd.arguments": [
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu"
    ],
    "editor.formatOnSave": true,
    "[cpp]": {
        "editor.defaultFormatter": "llvm-vs-code-extensions.vscode-clangd"
    }
}
```

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
