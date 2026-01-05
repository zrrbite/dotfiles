# Dotfiles

🎨 Nord-themed Hyprland dotfiles for Arch Linux • Developer-focused • Stow-managed • One-command setup

Personal Arch Linux dotfiles with a Nord-themed Hyprland setup, managed with GNU Stow for easy deployment and version control.

## About

**One-liner:**
> Personal Arch Linux dotfiles with a Nord-themed Hyprland setup, managed with GNU Stow for easy deployment and version control.

**Short (elevator pitch):**
> A comprehensive dotfiles repository for Arch Linux featuring a beautiful Nord-themed Hyprland desktop environment. Everything is managed with GNU Stow and includes an automated install script. It's optimized for C++ development with neovim, clang tools, and gdb-dashboard, plus tons of productivity tools like fzf, zoxide, bat, and yazi. The whole setup is designed to be reproducible - clone the repo, run one script, and you're up and running.

**Detailed:**
> My personal Arch Linux configuration managed as a dotfiles repository using GNU Stow. It features a Nord-themed Hyprland compositor setup with waybar, rofi, and mako notifications. The repository includes configs for development tools (neovim with LSP, gdb-dashboard, clang-format/tidy), productivity utilities (fzf, zoxide, bat, eza, yazi), and visual enhancements (cava audio visualizer, wlogout menu, fastfetch system info). Everything is automated with an install script that handles package installation, config deployment, and shell integration. It's designed to be completely reproducible - perfect for quickly setting up a new machine or sharing configurations across systems.

---

**Note:** If you prefer a pre-configured Hyprland distro over building your own, check out [Omarchy](https://omarchy.org/) - an opinionated Linux distribution by DHH (Rails creator) that's also built on Hyprland. This dotfiles approach gives you more control and customization, while Omarchy provides an out-of-the-box experience.

Want to try Omarchy? See `./install_omarchy.sh` for installation guidance and instructions on layering these dotfiles on top.

---

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

## Updating Your Config

Pull the latest changes and reload everything:

```bash
cd ~/dotfiles && ./reload.sh
```

This will:
- Pull latest changes from git
- Re-stow all packages (picks up new files)
- Reload Hyprland config
- Reload waybar
- Source bashrc for current terminal

## What's Included

- **Desktop**: Hyprland, waybar, rofi, mako notifications, wlogout (logout menu), Nordic GTK theme, Papirus-Dark icons, Nordzy cursors
- **Terminal**: foot with Nord theme, starship prompt, fastfetch (system info)
- **Audio**: pipewire + wireplumber, pavucontrol, cava (audio visualizer)
- **Media**: mpv (video), imv (images), zathura (PDF)
- **Files**: thunar, mc (Midnight Commander), yazi (modern file manager)
- **Communication**: Discord, Delta Chat
- **Dev**: neovim, gdb + gdb-dashboard, clang-format, clang-tidy, TeX Live (beamer)
- **Fonts**: JetBrains Mono Nerd, CJK (Chinese/Japanese/Korean), emoji
- **Utils**: screenshots (grim + slurp + satty), screen recording (wf-recorder), clipboard history, screen lock, chafa (terminal images), fzf (fuzzy finder), zoxide (smart cd), bat (cat with syntax highlighting), eza (modern ls), tldr (simplified man pages)
- **Idle**: Lock at 5min, display off at 10min, suspend at 30min (hypridle)

## Screenshots

### Terminal with Fastfetch
![Terminal](screenshots/terminal.png)

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
| `Super + Shift + A` | Screenshot with annotation (satty) |
| `Super + Shift + C` | Screenshot to clipboard |
| `Super + Shift + R` | Toggle screen recording |
| `Super + Ctrl + R` | Toggle region recording |
| `Super + B` | Next window below (vertical) |
| `Super + N` | Next window right (horizontal) |
| `Super + J` | Toggle split direction |
| `Super + =` | Resize window to 1:1 aspect ratio (square) |
| `Super + F1` | Show all keybinds |
| `Super + F2` | Useful commands menu |
| `Super + F3` | Neovim keybindings |

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
| `fastfetch` | System info display with Nord colors (Arch logo, system stats) |
| `foot`  | Foot terminal emulator - Nord theme, transparency, padding |
| `git`   | Git config with extensive aliases for status, logging, branching, stashing |
| `gtk`   | GTK theme config - Nordic theme with Papirus-Dark icons for all GUI apps |
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

### Neovim with clangd

The `nvim` package includes a full C++ IDE setup with clangd LSP, Telescope, and Treesitter.

**Symbol Navigation:**
```bash
Space + fs              # Find symbols in current file
Space + fw              # Find symbols in entire workspace
Space + fg              # Search text across all files (grep)
gd                      # Go to definition
gD                      # Go to declaration
gr                      # Go to references (find all usages)
gI                      # Go to implementation
K                       # Show documentation/hover info
Space + h               # Switch between header/source (.h <-> .cpp)
```

**Code Intelligence:**
```bash
Space + rn              # Rename symbol across project
Space + ca              # Code actions (suggestions/fixes)
Space + D               # Go to type definition
Space + sh              # Signature help
Space + fd              # Show diagnostics (errors/warnings)
```

**File Navigation:**
```bash
Space + e               # Toggle file tree (neo-tree)
Space + ff              # Find files (Telescope)
Space + fb              # Find open buffers
Ctrl + h/j/k/l          # Navigate between splits
```

**Setup for C++ projects:**
1. Open project: `nvim .`
2. Generate `compile_commands.json` for best results (see above)
3. LSP activates automatically when you open `.cpp` or `.hpp` files
4. Use `Space + fw` to fuzzy search any symbol in your project!

**Diagnostics & Auto-fix Workflow:**

Clangd shows errors and warnings in the sign column (left side) with E/W markers.

```bash
# View diagnostics:
Space + q               # List all diagnostics with full text
Space + d               # Show diagnostic at cursor in popup
K                       # Hover on line - shows diagnostic

# Navigate diagnostics:
]d                      # Jump to next diagnostic
[d                      # Jump to previous diagnostic

# Auto-fix issues:
Space + ca              # Code actions - shows available fixes
                        # Select fix and press Enter to apply
```

**Common auto-fixes:**
- Remove unused variables
- Add missing includes
- Apply clang-tidy suggestions
- Modernize C++ code (use auto, range-for, etc.)

**Workflow for fixing multiple issues:**
1. `Space + q` - See all diagnostics
2. Navigate to one with "Fix available"
3. Press `Enter` to jump to line
4. `Space + ca` - View and apply fix
5. Repeat for other issues

Press `Super + F3` for a quick reference of all Neovim keybindings.

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

Replaces `ls` with a modern alternative featuring colors, icons, and git status:

```bash
ls              # eza with icons (replaces standard ls)
ll              # detailed list with icons and git status
la              # list all files with icons
lt              # tree view (respects .gitignore)
eza -T -L 2     # tree view, 2 levels deep

# Use original ls if needed:
/bin/ls         # standard ls command
```

### tldr - Simplified Man Pages

Quick examples instead of full documentation:

```bash
tldr tar        # shows common tar examples
tldr git-log    # git log usage examples
tldr -u         # update cache (run once after install)
```

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

### fd - Better Find

Modern, user-friendly alternative to `find` with intuitive syntax:

```bash
fd pattern              # Find files/dirs matching pattern
fd -H bashrc            # Include hidden files
fd -e cpp               # Find by extension
fd -t f pattern         # Only files (-t d for dirs)
fd '^install'           # Files starting with "install" (regex)
```

Fast, respects `.gitignore` by default, and has colored output.

### ripgrep (rg) - Better Grep

Blazing fast search tool for file contents:

```bash
rg "pattern"            # Search recursively from current dir
rg -i "PATTERN"         # Case insensitive
rg -l "term"            # Just list filenames with matches
rg -C 3 "pattern"       # Show 3 lines of context
rg -t sh "function"     # Only search .sh files
rg --hidden "config"    # Include hidden files
```

Much faster than grep, respects `.gitignore`, and has smart case sensitivity.

### chafa - Terminal Image Viewer

View images directly in the terminal:

```bash
chafa-ascii image.jpg   # ASCII art mode (alias)
chafa-block image.jpg   # Block characters (alias)
chafa image.png         # Full color mode
fimg                    # Find and preview images with fzf (alias)
```

Perfect for quickly previewing images without leaving the terminal. The `fimg` alias combines fd, fzf, and chafa for an interactive image browser.

### btop - System Monitor

Beautiful system monitor with Nord theme:

```bash
btop                    # Launch interactive monitor
```

Shows CPU, memory, disk, network, and processes with a gorgeous TUI.

### fastfetch - System Info

Fast system information display (runs on terminal startup):

```bash
fastfetch               # Show system info with Arch logo
```

Displays OS, kernel, packages, shell, DE/WM, and more.

### wlogout - Logout Menu

Graphical logout menu. Bind it in Hyprland:

```bash
wlogout         # show logout menu
```

Provides options for lock, logout, shutdown, reboot, and suspend.

### CLI Tools Quick Reference

**Pro Tip Aliases - Power user shortcuts:**
```bash
fcpp                    # Find and view C++ files (fd + fzf + bat)
ftodo                   # Find and edit TODOs (rg + fzf + nvim)
fmd                     # Find markdown files (fd + fzf)
ffunc                   # Find function definitions (rg + fzf + bat)
fimg                    # Find and preview images (fd + fzf + chafa)
```

**Search & Navigation:**
```bash
z dot                   # Jump to frequently used directory
zi                      # Jump with fzf picker
fd <pattern>            # Find files (better than find)
fd -H <pattern>         # Include hidden files
rg <pattern>            # Search file contents (better grep)
rg -l <pattern>         # List files containing pattern
```

**Keyboard Shortcuts:**
```bash
Ctrl+R                  # Search command history with fzf
Ctrl+T                  # Fuzzy find files
Alt+C                   # Fuzzy cd into directory
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
