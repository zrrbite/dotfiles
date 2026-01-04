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

- **Desktop**: Hyprland, waybar, rofi, mako notifications, wlogout (logout menu)
- **Terminal**: foot with Nord theme, starship prompt
- **Audio**: pipewire + wireplumber, pavucontrol, cava (audio visualizer)
- **Media**: mpv (video), imv (images), zathura (PDF)
- **Files**: thunar, mc (Midnight Commander), yazi (modern file manager)
- **Communication**: Discord, Delta Chat
- **Dev**: neovim, lazygit (git TUI), gdb + gdb-dashboard, clang-format, clang-tidy, TeX Live (beamer)
- **Fonts**: JetBrains Mono Nerd, CJK (Chinese/Japanese/Korean), emoji
- **Utils**: screenshots, screen recording (wf-recorder), clipboard history, screen lock, chafa (terminal images), fzf (fuzzy finder), zoxide (smart cd), bat (cat with syntax highlighting), eza (modern ls), tldr (simplified man pages)
- **Idle**: Lock at 5min, display off at 10min, suspend at 30min (hypridle)

## Default Applications

The `mimeapps` package sets default applications:

| Type | Application |
|------|-------------|
| Browser | Google Chrome |
| Images | imv |
| Video | mpv |
| PDF | zathura |

## Key Bindings

| Binding | Action |
|---------|--------|
| `Super + Q` | Terminal (foot) |
| `Super + E` | File manager (thunar) |
| `Super + Shift + E` | Midnight Commander |
| `Super + R` | App launcher (rofi) |
| `Super + C` | Close window |
| `Super + L` | Lock screen |
| `Super + Escape` | Logout menu (wlogout) |
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
| `cava`  | Audio visualizer with Nord gradient theme |
| `clang` | clang-format (LLVM style) and clang-tidy (modern C++ checks) |
| `gdb`   | GDB debugger config - gdb-dashboard, pretty printing, custom commands |
| `discord` | Desktop entry override for native Wayland support |
| `foot`  | Foot terminal emulator - Nord theme, transparency, padding |
| `git`   | Git config with extensive aliases for status, logging, branching, stashing |
| `hypr`  | Hyprland compositor + hyprpaper + hyprlock + hypridle + cliphist |
| `mako`  | Notification daemon (Nord theme) |
| `mimeapps` | Default applications (Chrome, imv, mpv, zathura) |
| `nvim`  | Neovim IDE setup - LSP, treesitter, telescope (C++ focused) |
| `rofi`  | App launcher with Nord theme |
| `starship` | Minimal shell prompt with Nerd Font icons |
| `waybar`| Status bar with workspaces, clock, system info (Nord theme) |
| `wlogout` | Logout menu with Nord theme (lock, logout, shutdown, reboot, suspend) |

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

The `clang` package provides `.clang-format` and `.clang-tidy` configs in your home directory. Tools automatically find these when run from any subdirectory.

**clang-format style:**
- C++20, 120 column limit, 4-space indent
- Allman brace style (braces on new line)
- Left-aligned pointers (`int* ptr`)
- Sorted includes with grouping

**clang-tidy checks:** modernize, bugprone, performance, readability, cppcoreguidelines

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

## Productivity Tools

### fzf - Fuzzy Finder

Interactive fuzzy search for command history, files, and more:

- `Ctrl+R` - Search command history
- `Ctrl+T` - Search files in current directory
- `Alt+C` - cd into a directory

### zoxide - Smart Directory Jumper

Tracks your most-used directories and jumps to them with partial matches:

```bash
z dot        # jumps to ~/dotfiles
z dev osm    # jumps to ~/dev/osm-raylib
zi           # interactive selection with fzf
```

Learns your habits over time - the more you `cd` somewhere, the higher it ranks.

### bat - Better cat

Syntax highlighting, line numbers, and git integration:

```bash
bat file.cpp           # view with syntax highlighting
bat -p file.cpp        # plain output (no line numbers)
bat file.cpp file.h    # view multiple files
```

### eza - Modern ls

Enhanced `ls` with colors, icons, and git status:

```bash
ll              # detailed list with icons and git status
la              # list all files with icons
lt              # tree view (respects .gitignore)
eza -T -L 2     # tree view, 2 levels deep
```

### tldr - Simplified Man Pages

Quick examples instead of full documentation:

```bash
tldr tar        # shows common tar examples
tldr git-log    # git log usage examples
tldr -u         # update cache (run once after install)
```

### lazygit - Git TUI

Beautiful terminal interface for git operations:

```bash
lazygit         # launch in any git repo
```

**Key bindings:**
- `1-5` - Switch panels (Status, Files, Branches, Commits, Stash)
- `space` - Stage/unstage files
- `c` - Commit
- `P` - Push
- `p` - Pull
- `?` - Help

### yazi - Modern File Manager

Fast file manager with image previews and vim-like navigation:

```bash
yazi            # launch in current directory
```

**Key bindings:**
- `hjkl` - Navigate (vim-style)
- `space` - Select files
- `y` - Copy
- `d` - Cut
- `p` - Paste
- `q` - Quit

### wlogout - Logout Menu

Graphical logout menu. Bind it in Hyprland:

```bash
wlogout         # show logout menu
```

Provides options for lock, logout, shutdown, reboot, and suspend.

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
