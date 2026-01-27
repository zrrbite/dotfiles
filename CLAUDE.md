# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Cross-platform personal dotfiles supporting:
- **Arch Linux**: Full Hyprland desktop environment
- **WSL (Ubuntu/Debian)**: CLI development tools only
- **macOS (M1/M2/Intel)**: CLI tools + Alacritty terminal
- **Windows 10/11**: CLI tools + Windows Terminal (via Scoop, no Stow needed)

Linux/macOS managed with [GNU Stow](https://www.gnu.org/software/stow/), Windows uses native PowerShell symlinks.

## Commands

### Installation
```bash
./install_arch.sh     # Arch Linux (full Hyprland + all tools)
./install_wsl.sh      # WSL (CLI only, no GUI)
./install_darwin.sh   # macOS (Homebrew + Alacritty)
```

```powershell
# Windows (PowerShell as Administrator or with Developer Mode)
.\install_windows.ps1
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
- **bash/.bashrc-windows** - Windows Git Bash with Scoop tools
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
- **gtk/mimeapps/discord**: Desktop environment configs (uses discord_arch_electron)

**macOS/Optional:**
- **alacritty**: Cross-platform terminal with Nord theme

**Windows 10/11:**
- **Git, Neovim, Clang, Starship**: All work identically to Linux/macOS
- **bash/.bashrc-windows**: Git Bash configuration (Scoop tools)
- **Windows Terminal**: Recommended terminal emulator (replaces Alacritty/Foot)
- **No Hyprland/Wayland**: Windows doesn't support Linux desktop environment configs

### Key Packages

- **bash**: Platform-specific shell configuration
  - Arch: Full setup with Hyprland auto-start, all aliases, bash-completion from `/usr/share`
  - WSL: CLI tools only, bash-completion from `/etc` or `/usr/share`, aliases for batcat/fdfind
  - macOS: Homebrew paths (`/opt/homebrew`), bash-completion from Homebrew location
  - Windows: Git Bash with Scoop tools, bash-completion from Git for Windows

- **nvim**: Neovim config with lazy.nvim, LSP, treesitter, DAP debugging, gitsigns
  - **C++ (clangd)**: Full IDE features, clang-tidy integration, header/source switching
  - **TypeScript (ts_ls)**: Autocomplete, go-to-definition, refactoring, inlay hints
  - **Lua (lua_ls)**: For Neovim config development
  - Git integration: blame, hunks, staging
  - Telescope fuzzy finder for symbols, files, macros
  - Debugging: codelldb (C++), node2 (TypeScript/JavaScript)
  - Batch fixes: `Space+cf` (C++)

- **git**: Extensive git aliases (`git cf` for formatting), global hooks for code quality
  - Uses meld for diff/merge (Arch/WSL) or built-in tools (macOS)
  - Global hooks at `~/.git-hooks/` (automatically symlinked via stow, applies to all repos)
  - **Pre-commit hook**: Enforces clang-format on C++ files
  - **Pre-push hook**: Runs clang-tidy on changed files before push

- **clang**: clang-format (LLVM/Allman style) and clang-tidy config (Unreal Engine standards)
  - Two configs: `.clang-tidy` (default UE style), `.clang-tidy-unreal` (reference copy)
  - Hooks validate code quality with fun ASCII art on violations

- **typescript**: TypeScript/JavaScript configuration
  - **tsconfig.json**: Strict mode, modern ES2022 target, no implicit any
  - **ESLint**: TypeScript-specific rules, no-explicit-any enforcement
  - **Prettier**: Consistent formatting (single quotes, 100 char width)
  - **Vitest**: Fast unit testing with React Testing Library support
  - Four quality gates: Prettier (pre-commit) → TypeScript + ESLint + Vitest (pre-push)

- **alacritty**: GPU-accelerated terminal with Nord theme
  - macOS primary terminal
  - Optional on Arch/WSL (foot is default on Arch)

### Install Scripts

- **install_arch.sh**: Pacman + AUR packages, full Hyprland setup, systemd services
- **install_wsl.sh**: apt packages + manual installs (starship, zoxide, eza, duf, git-delta, procs), CLI only
- **install_darwin.sh**: Homebrew packages, Alacritty setup, M2 ARM support
- **install_windows.ps1**: Scoop packages, Windows Terminal, native PowerShell symlinks (no Stow)
  - Requires: Windows 10 (Developer Mode) or Windows 11
  - Installs: Git, Neovim, LLVM, modern CLI tools via Scoop
  - Symlinks: Git hooks, clang configs, nvim (to %LOCALAPPDATA%), starship, bashrc

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

## Starting New TypeScript Projects

Use the bootstrap script to create TypeScript projects with multiple framework options:

```bash
~/dotfiles/scripts/bootstrap-ts-project.sh my-app --framework=node     # Node.js CLI app
~/dotfiles/scripts/bootstrap-ts-project.sh my-api --framework=express  # Express API
~/dotfiles/scripts/bootstrap-ts-project.sh my-web --framework=react    # React app (Vite)
~/dotfiles/scripts/bootstrap-ts-project.sh my-site --framework=next    # Next.js app
```

**What it creates:**
- **CLAUDE.md** - Project context for Claude Code
- **tsconfig.json** - Strict TypeScript config (from dotfiles/typescript/)
- **.eslintrc.json** - TypeScript-aware ESLint rules
- **.prettierrc** - Consistent code formatting
- **vitest.config.ts** - Vitest testing configuration
- **package.json** - Framework-specific scripts and dependencies
- **.nvim.lua** - DAP debug configuration for Node.js
- **Git hooks** - Pre-commit (Prettier) and pre-push (type-check + lint + tests)
- **Test files** - Auto-generated sample tests for each framework
- **Directory structure** - src/, src/test/ or test/, appropriate framework files

**After creating a project:**
1. `cd ~/dev/my-app`
2. `npm install` - Install dependencies
3. `npm run dev` - Start development server
4. Edit code in `src/`, write tests in `src/test/`
5. `npm run test` - Run tests in watch mode (optional during development)
6. Git enforces four quality gates: Prettier (commit) → TypeScript + ESLint + Vitest (push)
7. `nvim .` - Opens with LSP and DAP ready (F5 to debug)

**Framework-specific features:**
- **node/express**: Simple Node.js apps with tsx for hot reload
- **react**: Vite + React + TypeScript with fast HMR
- **next**: Next.js 14+ with App Router and TypeScript

## Recent Features & Important Notes

### Neovim IDE Setup

**C++ (clangd):**
- **LSP**: Full C++ support (requires `compile_commands.json` for best results)
- **Debugging**: nvim-dap with codelldb adapter
- **Formatting**: `Space+F` for clang-format, `Space+cf` for batch clang-tidy fixes
- **Macros**: `Space+fm` to find #define macros (not visible in LSP symbols)
- **Generate impl**: `Space+ca` on function declaration to generate implementation
- **Header switching**: `Space+h` to toggle between .h/.cpp

**TypeScript (ts_ls):**
- **LSP**: Autocomplete, go-to-definition, refactoring, inlay hints
- **Debugging**: nvim-dap with node2 adapter (F5 to start)
- **Formatting**: `Space+F` uses Prettier (respects .prettierrc)
- **Type checking**: Automatic via LSP, `npm run type-check` for full project
- **Linting**: ESLint integration, errors shown inline
- **⚠️ REQUIRES**: `npm install -g typescript-language-server typescript` (not in install scripts yet)

**Common features (all languages):**
- F5: Start/Continue, F10: Step over, F11: Step into, F12: Step out
- `Space+b`: Toggle breakpoint, `Space+du`: Toggle debug UI
- `Space+gb`: Toggle git blame, `Space+hp`: Preview hunk, `Space+hs`: Stage hunk
- `Space+ff`: Find files, `Space+fg`: Live grep, `Space+fs`: Find symbols

### Git Hooks (Automatic Code Quality)

**C++ projects:**
- **Pre-commit**: Enforces clang-format on all C++ files
- **Pre-push**: Runs clang-tidy on changed files
- Fix with `git cf` or bypass with `git commit --no-verify`

**TypeScript projects (Four Quality Gates):**
- **Pre-commit** (Gate 1): Runs Prettier on staged .ts/.tsx/.js/.jsx files
- **Pre-push** (Gates 2-4): Type checks with `tsc --noEmit`, lints with ESLint, tests with Vitest
- Fix formatting with `npm run format`, tests must pass before push
- Bypass with `git push --no-verify` (not recommended)

### Git Hooks (C++ - Legacy Documentation)

Global hooks automatically installed via stow to `~/.git-hooks/` (applies to all repos).

**Pre-commit Hook** (`git/.git-hooks/pre-commit`):
- Enforces clang-format on all C++ files being committed
- Shows fun ASCII art `(╯°□°)╯︵ ┻━┻` when formatting violations detected
- **Fix with**: `git cf` (formats staged files) or `git clang-format --staged`
- **Bypass**: `git commit --no-verify` (not recommended)
- **Fast**: Only checks staged files, runs on every commit

**Pre-push Hook** (`git/.git-hooks/pre-push`):
- Runs clang-tidy static analysis on changed C++ files before push
- Shows ASCII art `ლ(ಠ益ಠლ)` when errors detected
- **Errors block push**, warnings are non-blocking
- **Fix with**: `clang-tidy <file> --fix` or `nvim <file>` then `Space+cf`
- **Bypass**: `git push --no-verify` (not recommended)
- **Smart**: Only checks files changed in commits being pushed
- Warns if `compile_commands.json` missing (needed for best results)

### Clang-tidy Configuration (Unreal Engine Standards)

**Default config** (`clang/.clang-tidy`):
- Configured for **Unreal Engine coding standards** by default
- **PascalCase** for all types, functions, variables (not snake_case)
- **No private member suffix** (UE doesn't use trailing `_`)
- **Prefixes**: `k` for constants, `T` for template parameters
- **Always-braces** policy for if statements (UE standard)
- **Type prefixes documented**: U/A/F/E/I/T/b (manually enforced)
- Less aggressive modernization (matches UE idioms)

**Reference copy** (`clang/.clang-tidy-unreal`):
- Identical to default, for project-specific use
- Copy to UE projects that need local `.clang-tidy`

**Tuning**:
- Edit `~/.clang-tidy` to disable specific checks: add `-check-name,` to Checks list
- Restart nvim after changing `.clang-tidy` (clangd reads on startup)
- Pre-push hook uses whatever `.clang-tidy` exists (project-local or global)

### Unreal Engine Development

Neovim works well for UE C++ coding (7/10 feasibility):
- ✅ **LSP**: clangd with full C++ support (completion, go-to-definition, refactoring)
- ✅ **Debugging**: nvim-dap with codelldb (breakpoints, stepping, variable inspection)
- ✅ **Formatting**: clang-format with Allman braces (matches UE style)
- ✅ **Static analysis**: clang-tidy configured for UE coding standards (PascalCase, prefixes)
- ✅ **Git hooks**: Pre-commit (format) + pre-push (tidy) enforce quality automatically
- ⚠️ **Compilation database**: Generate `compile_commands.json` from UE project for best LSP results
  - Run: `UnrealBuildTool -mode=GenerateClangDatabase` or use UE's CMake export
- ❌ **Blueprints/Assets**: Use Unreal Editor (hybrid workflow recommended)

**UE-specific workflow**:
1. Generate `compile_commands.json` for your UE project
2. Open project in nvim: LSP shows UE types, macros, includes
3. Write C++ with full IDE support (UPROPERTY, UFUNCTION completions via macros)
4. Pre-commit hook formats on commit (Allman braces, tabs)
5. Pre-push hook validates naming (catches PascalCase violations)
6. Use UE Editor for Blueprints, levels, materials
