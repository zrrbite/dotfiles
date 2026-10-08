# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Cross-platform personal dotfiles supporting:
- **Arch Linux**: Full Hyprland desktop environment
- **WSL (Ubuntu/Debian)**: CLI development tools only
- **Raspberry Pi (Raspbian)**: CLI development tools only (ARM64)
- **macOS (M1/M2/Intel)**: CLI tools + Alacritty terminal
- **Windows 10/11**: CLI tools + Windows Terminal (via Scoop, no Stow needed)

Linux/macOS managed with [GNU Stow](https://www.gnu.org/software/stow/), Windows uses native PowerShell symlinks.

`AGENTS.md` points non-Claude agents at this file and
`doc/applying-the-setup.md`; keep its three repeated rules in sync with them.

**Setting up another machine (especially a work one)?** Read
`doc/applying-the-setup.md` first. The installers assume Martin's personal
machines: they replace `~/.gitconfig` (global hooks, a global ignore) and
`~/.zshrc`.

**`doc/tools.md` is the per-OS overview of every tool** (what it's for, and
which OS has it). Update its table in the same commit that adds or removes a
package from an installer. The exact package names stay in the installers,
not copied there.

**Every change that affects a machine gets a `CHANGELOG.md` entry**, under
today's date (newest first), in the same pass as the commit. Say what changed,
with commit refs, and **On other machines**: the exact steps to catch up (re-run
the installer, reload something, a manual step), flagging anything that must
happen before `git pull`. Also say what the repo *can't* do: app settings
outside stow, manual installs, changes made only on one machine. Other agents
sync machines from this file, so a missing entry means a machine silently
missing a change. `scripts/verify.sh` records each machine's last synced
commit in `~/.local/state/dotfiles/applied`, which is how they find where to
start reading.

**Git identity is per-machine.** `git/.gitconfig` has no `[user]` and no
credential helper; it includes `~/.gitconfig.local` last, which holds both.
`scripts/seed-gitconfig-local.sh` creates that file from an existing
`~/.gitconfig`, and every installer runs it before replacing `~/.gitconfig`.
Never put identity or credentials back into the tracked file.

## Commands

### Installation
```bash
./install_arch.sh     # Arch Linux (full Hyprland + all tools)
./install_wsl.sh      # WSL (CLI only, no GUI)
./install_raspbian.sh # Raspberry Pi / Raspbian (CLI only, ARM64)
./install_darwin.sh   # macOS (Homebrew + Alacritty)
                      #   --dry-run       show actions without doing them
                      #   --with-desktop  also set wallpaper/Dock/menu bar (fresh machine)
                      #   --upgrade       allow brew to upgrade existing packages
                      # Default is re-run safe: missing packages only, no desktop changes.
```

```powershell
# Windows (PowerShell as Administrator or with Developer Mode)
.\install_windows.ps1
```

### Managing Configs with Stow (Linux/macOS)
Run from the repo root, always with `-t ~`. The repo may not be cloned at
`~/dotfiles`, and without `-t` stow links into the repo's parent directory.
```bash
stow -n -v -t ~ <package>   # Preview: what would be linked, any conflicts
stow -t ~ <package>         # Enable a package (creates symlinks)
stow -D -t ~ <package>      # Remove a package's symlinks
stow -R -t ~ <package>      # Re-stow (useful after adding files)
./reload.sh                 # git pull + re-stow this OS's packages + reload the desktop
scripts/verify.sh           # Read-only: is everything applied? Exit 0 = yes
scripts/finder-defaults.sh  # macOS: Finder settings (--dry-run, --undo); part of --with-desktop
```
Which packages each OS gets is defined once, in `scripts/packages.sh`. The
installers, `verify.sh` and `reload.sh` all read it, so add a package there.
Create `~/.config` and `~/.claude` before stowing on a fresh machine;
otherwise stow links those whole directories into the repo, and apps write
into the working tree. The installers do this, and `verify.sh` checks it.

### Managing Configs on Windows
```powershell
.\stow_windows.ps1 git              # Link one package
.\stow_windows.ps1 git nvim clang   # Link multiple packages
.\stow_windows.ps1 -All             # Link all supported packages
.\stow_windows.ps1 -Delete git      # Remove a package's symlinks
.\stow_windows.ps1 -Delete -All     # Remove all symlinks
.\stow_windows.ps1 -List            # Show available packages and their mappings
```
Requires Developer Mode (Windows 10) or Windows 11. Handles Windows-specific paths (e.g., nvim -> `%LOCALAPPDATA%\nvim`).

### Adding New Configs
1. Create directory mirroring home structure: `mkdir -p ~/dotfiles/foo/.config/foo`
2. Move config files into it
3. Run `stow foo` from dotfiles root

### Non-Package Directories

`stow */` treats **every** top-level directory as a package, so directories
holding repo content rather than dotfiles (`doc/`, `img/`, `screenshots/`,
`scripts/`, `templates/`, `windowsterminal/`) each carry a `.stow-local-ignore`
containing `.*`, which makes stow skip them. Without it, `stow */` symlinks
their contents straight into `$HOME` — `~/Makefile`, `~/settings.json`,
`~/terminal.png` and friends.

Add one to any new directory that is not meant to be stowed. A package can also
ignore individual files: `typescript/.stow-local-ignore` excludes
`tsconfig.json` (bootstrap scripts read it from the repo) while still stowing
the dotfiles beside it.

Verify with a dry run before committing — this only simulates:
```bash
stow -n -v -t ~ */ 2>&1 | grep '^LINK:' | grep -v 'LINK: \.'
```
Any output means something would land as a bare `~/file`.

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
- **starship**: Shell prompt (fully portable). Nord palette defined in the file.
  The directory is plain bold text; the git pill is built from module
  `format` strings, with git_branch opening it and git_status closing it
- **claude**: Claude Code global skills (`/review`, `/fix-issue`, `/bootstrap`)
- **tmux**: Terminal multiplexer, `Ctrl+a` prefix and Nord status line. Stowed
  and installed on Arch, Debian/WSL/Raspbian and macOS; not on Windows.
  `Ctrl+a v` and `Ctrl+a Enter` are Option-free alternatives to `|` and `[`
  (both Option keys on the Danish layout).
- **bat**: one line, `--theme="Nord"`, matching delta. Stowed on Arch,
  Debian/WSL/Raspbian (where the binary is `batcat`) and macOS; not on Windows,
  whose bat config lives under `%APPDATA%`.

**Shell (macOS and Linux):**
- **zsh**: `zsh/.zshrc` → `~/.zshrc`, the login shell on macOS, Arch and
  Debian/WSL/Raspbian. One shared file. OS specifics live in
  `zsh/.config/zsh/darwin.zsh` and `linux.zsh`, which `.zshrc` loads first
  through its own real path, so a pull works before a re-stow. OS aliases go in
  their `zsh_os_aliases`, called after oh-my-zsh. An untracked
  `~/.zshrc.local` holds one machine's lines. Keeps oh-my-zsh, swaps its theme
  for starship, and initialises zoxide, fzf and direnv; every integration is
  guarded by `command -v`. Overrides no standard command: `ls`, `cat`, `find`
  and `ps` are left alone, and eza is `ll`/`lt`/`la`.
- **zsh-linux**: `.zprofile` for Linux login shells: one ssh-agent per login,
  and Hyprland on TTY1 (only if installed). Not stowed on macOS, which keeps
  its own `~/.zprofile`. `scripts/setup-zsh-linux.sh`, run by both Linux
  installers, clones oh-my-zsh, retires old links to the removed Linux bash
  files, links Debian's `batcat`/`fdfind` as `bat`/`fd`, and makes zsh the
  login shell. Test from the Mac with `scripts/test-zsh.sh` and
  `scripts/test-in-docker.sh <image>`.

**bash configs (macOS and Windows only; Linux runs zsh since 2026-10-06):**
- **bash/.bashrc-darwin** - macOS with Homebrew paths, read only if you start bash
- **bash/.bashrc-windows** - Windows Git Bash with Scoop tools
- Install scripts create symlinks to the appropriate variant

**Cross-platform with per-OS configs:**
- **fastfetch**: System info. Stowed on both Arch and macOS. The package ships
  `config.jsonc` (Arch logo), `config-darwin.jsonc` (Apple logo) and
  `config-windows.jsonc`; `install_darwin.sh` links the darwin one over
  `~/.config/fastfetch/config.jsonc` and stows the package with
  `--ignore='config\.jsonc'` so stow does not fight that symlink.

**Linux-only (Arch + optionally WSL):**
- **gdb**: Debugger config (macOS uses lldb instead)

btop is installed as a binary by every installer but has no stow package here:
it rewrites its own `btop.conf` on exit, so a linked file would be rewritten
inside the repo. Instead the installers run `scripts/seed-btop-config.sh`, which
sets `color_theme = "nord"` once (only over btop's `Default` or a missing file)
and leaves the file to btop. There is no `btop/` directory; don't add it to a
stow list.

**Arch-only (native hardware with GPU):**
- **hypr**: Hyprland compositor, hyprpaper, hyprlock, wallpapers
- **foot**: Wayland terminal
- **waybar**: Status bar
- **rofi**: App launcher
- **mako**: Notifications
- **wlogout**: Logout menu
- **cava**: Audio visualizer
- **gtk/mimeapps/discord**: Desktop environment configs (uses discord_arch_electron)

**macOS:**
- **aerospace**: i3-style tiling WM (same keys as GlazeWM/Hyprland under a ctrl-alt (⌃⌥) modifier, because
  on the Danish layout Option alone types `[ ] { } | \`; `~/.config/aerospace/aerospace.toml`).
  **Rule: every new AeroSpace binding uses `ctrl-alt-`, never plain `alt-`**, which can take a character
  the Danish layout types with Option, in every app. `scripts/verify.sh` fails while a Mac still runs
  `alt-` bindings; the fix is `aerospace reload-config`.
- **sketchybar**: Nord-themed status bar, pinned to the top; workspace pills show app icons
  (sketchybar-app-font, map vendored as `plugins/icon_map.sh`) and hide when empty
  (auto-launched by AeroSpace).
  Shares waybar's colour contract — see `doc/status-bar-theming.md`
- **autoraise**: focus-follows-mouse. AeroSpace has no setting for this, so AutoRaise
  (`brew tap dimentium/autoraise`) supplies it, configured in
  `~/.config/AutoRaise/config` and run as a launchd service
  (`brew services start dimentium/autoraise/autoraise`) so it survives an
  AeroSpace restart. Do not also start it from `after-startup-command` — that
  would leave two instances running.
  Note that `on-focus-changed = ['move-mouse window-lazy-center']` in
  `aerospace.toml` is the *opposite* direction (mouse follows focus) and must stay:
  it keeps the cursor on the keyboard-focused window so AutoRaise does not
  immediately steal focus back. Needs Accessibility permission.
- **alacritty**: Cross-platform terminal with Nord theme (`ctrl-alt-shift-enter`)
- **yazi**: Terminal file manager (Finder replacement), macOS and Arch. `y` in
  zsh launches it and leaves the shell where you quit. No theme file: the
  default theme uses ANSI colours, which the terminals map to Nord. Config keys
  are written against yazi 26.9's preset; they were renamed between releases.
  `keymap.toml` holds additions only (`g` bookmarks, Far-style `Tab` between
  tabs, spot on `i`), and `init.lua` shares yanks between instances; `g s`
  sends the current folder to the other instances (a `sync-cd` message)
- **ghostty**: On trial alongside Alacritty since 2026-10-05; the default terminal
  (`ctrl-alt-enter`) since the same day.
  `~/.config/ghostty/config.ghostty` mirrors the Alacritty config (font, padding,
  opacity, Nord palette, keybindings) and adds ligatures, the Kitty image
  protocol and a native window. Alacritty stays until the trial is decided;
  don't remove either one without asking
- **remote**: `~/.local/bin/remote`, the safe operations on a remote machine
  over SSH (mount with FUSE-T sshfs, read, search, read-only git, build,
  test). Claude may run it without asking (`Bash(remote:*)` in
  `~/.claude/settings.json`, added by `scripts/claude-remote-permissions.sh`).
  Its skill, `remote-machine`, is the one dotfiles skill that is
  model-invoked. Tests: `scripts/test-remote.sh` against the stand-in from
  `scripts/remote-test-host.sh up`. See `doc/remote-machine.md`

**Windows 10/11:**
- **Git, Neovim, Clang, Starship**: All work identically to Linux/macOS
- **bash/.bashrc-windows**: Git Bash configuration (Scoop tools)
- **Windows Terminal**: Recommended terminal emulator (replaces Alacritty/Foot)
- **glazewm**: i3-inspired tiling WM (symlinks to `~/.glzr/glazewm/config.yaml`)
- **zebar**: Status bar companion to GlazeWM (auto-started via GlazeWM startup command, symlinks `~/.glzr/zebar/settings.json`)
- **No Hyprland/Wayland**: Windows doesn't support Linux desktop environment configs

### Key Packages

- **bash**: macOS (`.bashrc-darwin`, only if you start bash) and Windows Git
  Bash (`.bashrc-windows`, Scoop tools, bash-completion from Git for Windows).
  Linux uses zsh; see Shell above.

- **nvim**: Neovim config with lazy.nvim, LSP, treesitter, DAP debugging, gitsigns
  - **C++ (clangd)**: Full IDE features, clang-tidy integration, header/source switching
  - **TypeScript (ts_ls)**: Autocomplete, go-to-definition, refactoring, inlay hints
  - **Lua (lua_ls)**: For Neovim config development
  - Git integration: blame, hunks, staging
  - Telescope fuzzy finder for symbols, files, macros
  - Debugging: codelldb (C++), node2 (TypeScript/JavaScript)
  - Batch fixes: `Space+cf` (C++)

- **git**: Extensive git aliases (`git cf` for formatting), global hooks for code quality
  - Linear history: `pull.rebase = true` and `merge.ff = only`, so a merge that
    can't fast-forward is refused. The rules for agents are in
    `claude/.claude/CLAUDE.md` ("History: linear, no merge commits")
  - Uses meld for diff/merge. meld isn't installed on macOS, so set
    `diff.tool`/`merge.tool = nvimdiff` in `~/.gitconfig.local` there
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
  - Second terminal on macOS (`ctrl-alt-shift-enter`); Ghostty is the default
  - Optional on Arch/WSL (foot is default on Arch)

- **ghostty**: Native-UI GPU terminal, on trial on macOS alongside Alacritty
  - Config is `config.ghostty`; check edits with `ghostty +validate-config`
  - Keeps a block cursor (`shell-integration-features = no-cursor`) and leaves
    Option alone, because the Danish layout types `{ } [ ] | @ $` with it

- **claude**: Claude Code global skills (stowed to `~/.claude/skills/`)
  - `/review` - Code review current diff for bugs, security issues, style violations
  - `/fix-issue <number>` - Read a GitHub issue and implement a fix
  - `/bootstrap [name]` - Interactive project scaffolding (C++, TypeScript variants)
  - All skills except `remote-machine` use `disable-model-invocation: true` (user-triggered only)

### Install Scripts

- **install_arch.sh**: Pacman + AUR packages, full Hyprland setup, systemd services
- **install_debian.sh**: Unified Debian/Ubuntu installer with architecture detection (x86_64/aarch64)
  - **install_wsl.sh**: Symlink to install_debian.sh (auto-detects WSL)
  - **install_raspbian.sh**: Symlink to install_debian.sh (auto-detects Raspberry Pi)
  - apt packages + manual installs (starship, zoxide, eza, duf, git-delta, procs, btop)
  - procs skipped on ARM64 (no prebuilt binary available)
- **install_darwin.sh**: Homebrew packages, Alacritty setup, M2 ARM support
- **install_windows.ps1**: Full setup - Scoop packages, Windows Terminal, and all symlinks
  - Requires: Windows 10 (Developer Mode) or Windows 11
  - Installs: Git, Neovim, LLVM, modern CLI tools via Scoop
  - Symlinks: Git hooks, clang configs, nvim (to %LOCALAPPDATA%), starship, bashrc
- **stow_windows.ps1**: Symlinks only (no package installation) - the Windows equivalent of `stow`
  - Use this to manage individual packages after initial setup
  - Supports: stow, unstow (-Delete), list (-List), all packages (-All)

**Windows Stow script** (`stow_windows.ps1`): Lightweight GNU Stow equivalent for Windows.
- Auto-detects dotfiles directory (no hardcoded paths)
- Per-package control, same workflow as `stow` on Linux
- Backs up existing non-symlink files before overwriting
- Skips already-correct symlinks
- Packages: git (plus .gitignore-global), clang, nvim, starship, bash (plus
  .minttyrc), fastfetch, glazewm, zebar, claude (skills only). `-DryRun` previews;
  it probes symlink rights first and restores a file if its link fails

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
- **⚠️ REQUIRES**: `npm install -g typescript-language-server typescript@6`; `install_darwin.sh` does it. TypeScript 7 is a Go port without tsserver, so it doesn't work with ts_ls

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
- **Prefixes**: `In` for template parameters
- **Always-braces** policy for if statements (UE standard)
- **Type prefixes documented**: U/A/S/F/E/I/C/T/b (manually enforced)
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
