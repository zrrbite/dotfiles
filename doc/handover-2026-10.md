# Handover: the October 2026 improvements

What changed in this setup between 2026-10-05 and 2026-10-13, grouped by
topic, and where each piece lives. Written 2026-10-15, covering up to commit
`29dc0b3`. It's a snapshot and won't be kept up to date: `CHANGELOG.md` has
everything after it.

**Who it's for.** Martin, to remember what's there. Also an AI agent bringing
another Mac up to date, so it sees the whole picture before it starts. The
steps aren't repeated here:
- `CHANGELOG.md` has each change's "On other machines" steps;
- `doc/applying-the-setup.md`, "Handing a Mac to an agent", has the order,
  the traps, when to ask Martin, and the prompt to paste.

Most of this is macOS, built and tried on Martin's MacBook. Linux got the
zsh switch and some fixes, tested in containers but not yet on real hardware
(see "Still open").

## The short version

- **AeroSpace moved to ⌃⌥ (Control+Option).** Option alone types
  `[ ] { } | \` on the Danish layout, and the old bindings took those keys
  away from every app.
- **Caps Lock** is Escape when tapped and Control when held. **Touch ID**
  works for `sudo`, inside tmux too.
- **Ghostty** is the terminal. Alacritty is gone from macOS.
- **tmux** saves and restores its sessions.
- **yazi** is the file manager in the terminal.
- **lazygit** is for looking around a repo.
- **Focus follows the mouse**, done by AeroSpace itself; AutoRaise is gone.
  Chrome and the chat apps open on fixed workspaces.
- **OrbStack** replaced Docker Desktop and uses the same `docker` commands.
- **C++ projects** get CMake presets and ccache.
- **Claude Code:**
  - it sees the todo list at session start;
  - it follows the linear-history rules;
  - it can work on the work Mac over SSH (`remote`).
- **Keeping machines in step:**
  - `scripts/verify.sh` says whether a machine is fully applied;
  - `CHANGELOG.md` says how to catch up;
  - `scripts/update.sh` upgrades a Mac.

## Keys worth knowing

**AeroSpace:** ⌃⌥ plus a key; full list in `doc/aerospace-macos.md`.

| Key | Does |
|---|---|
| ⌃⌥ 1–9 | Go to workspace 1–9 |
| ⌃⌥⇧ 1–9 | Move the window there, and follow it |
| ⌃⌥ h j k l | Focus left, down, up, right; with ⇧, move the window |
| ⌃⌥ Enter | New Ghostty window |
| ⌃⌥ d | Back to the previous workspace |
| ⌃⌥ r | Resize mode: a yellow RESIZE pill shows in sketchybar; Esc leaves |
| ⌃⌥ b | Even out window sizes |
| ⌃⌥ f | Fullscreen |
| ⌃⌥⇧ Space | Float or tile the window |
| ⌃⌥⇧ V | Clipboard history (Raycast) |
| ⌃⌥⇧ R | Reload AeroSpace's config |

**Shell and tmux:** `doc/tmux.md` has every tmux key and a one-week plan for
learning them.

| Key or command | Does |
|---|---|
| Caps Lock | Escape when tapped, Control when held |
| `t [name]` | Go to a tmux session, created if needed (default name: this folder) |
| `tp`, or `Ctrl+a` `f` in tmux | Fuzzy-pick a project under `~/Development` and go to its session |
| `y` | yazi; the shell stays where you quit it |
| `ll` `lt` `la` | eza listings: long, tree, all |
| `fcpp` `fmd` `ftodo` `fimg` | Fuzzy-pick a C++ file, Markdown file, a file with a TODO, an image |
| `Ctrl+a` `g` | lazygit in a popup, for this pane's folder |
| `Ctrl+a` `v` / `-` | Split side by side / top and bottom |
| `Ctrl+a` `Enter` | Copy mode (same as `Ctrl+a` `[`, which needs Option on a Danish keyboard) |
| `Ctrl+a` `Tab` | Last session; `Ctrl+a` ⌘← / ⌘→ cycles through them |
| `Ctrl+a` `Ctrl+s` | Save sessions now; continuum also saves every 15 minutes |
| ⌘← ⌘→, ⌥← ⌥→, ⌥⌫, ⌘⌫ | macOS text editing at the prompt, inside tmux too |

**nvim and yazi:** `doc/nvim-tutorial.md` (Level 8 covers finding your way
around a codebase), `doc/yazi.md`, `doc/lazygit.md`.

| Key | Does |
|---|---|
| nvim `Space` `g` `g` | lazygit in a floating window, for this file's repo |
| nvim `Space` `f` `c` / `f` `r` / `f` `o` | Grep the word under the cursor / repeat the last search / recent files |
| nvim `Space` `/` | Fuzzy search in this file |
| nvim `Space` `-` / `_` | yazi at this file / at the project root |
| yazi `g` `D` / `g` `.` / `g` `T` | Go to `~/Development` / the dotfiles / the todo repo |
| yazi `Tab` | Next tab (Far Manager's panel switch); `i` shows a file's details |
| yazi `g` `s` | Send this folder to your other yazi windows |
| yazi `y` here, `p` there | Copy a file between two yazi windows |

## What changed, by topic

Dates are when each change landed; the matching `CHANGELOG.md` entries have
the commits.

### Windows, keyboard and desktop (macOS)

- **AeroSpace on ⌃⌥** (10-07). Rule for every new binding: `ctrl-alt-`,
  never `alt-`. `verify.sh` fails while a running AeroSpace still has
  `alt-` keys.
- **AeroSpace 0.21** (10-12). The config uses `config-version = 2` with
  workspaces 1–9 listed, so an older AeroSpace rejects the whole file and
  every key binding with it. `verify.sh` fails on anything older than 0.21.
- **Focus follows the mouse:** AeroSpace's own `focus-follows-mouse` since
  10-12; AutoRaise is uninstalled. The `on-focus-changed` mouse warp stays,
  so the keyboard-focused window keeps focus. `doc/aerospace-macos.md`.
- **Where apps open** (10-08): Chrome on 2. Discord, Slack, WhatsApp,
  Telegram, DeltaChat and Messages on 3. Settings, Calculator, PrivadoVPN,
  Steam and Battle.net float. By habit, not by rule: Ghostty and tmux on 1,
  yazi on 4.
- **sketchybar:**
  - app icons on each workspace pill;
  - empty workspaces hidden;
  - a RESIZE pill in resize mode;
  - the front app's icon;
  - Wi-Fi state, battery and clock.

  Window borders are 5 pt and rounded. `doc/status-bar-theming.md`.
- **Caps Lock** via Karabiner-Elements (10-08). The `karabiner` package
  links the whole `~/.config/karabiner` folder, because Karabiner replaces
  its file when it saves.
- **Touch ID for sudo** (10-08), also in tmux: `scripts/touch-id-sudo.sh`
  writes `/etc/pam.d/sudo_local`, which survives macOS updates. It needs an
  enrolled fingerprint.
- **Raycast is the launcher** (in the installer since 10-07). It also does
  clipboard history (⌃⌥⇧V) and runs the `tmux session` script command
  (`scripts/raycast/`).
- **macOS settings as scripts:** each has `--check` and `--undo`.
  - `scripts/macos-defaults.sh`: the Dock, the menu bar, Mission Control
    grouped by app, ⌃⌘-drag to move any window, no smart quotes or
    autocorrect, and held keys repeat.
  - `scripts/finder-defaults.sh`: Finder.
- **Wallpaper:** the Arch logo, on the lock screen too (10-06).

### Terminal and shell

- **Ghostty** won its trial against Alacritty (10-05 to 10-12). It has
  ligatures, images in the terminal and the Nord palette. It leaves Option
  alone for the Danish layout.
- **zsh:**
  - one `.zshrc` for macOS and Linux, with OS specifics in
    `zsh/.config/zsh/`;
  - one machine's own lines go in `~/.zshrc.local`;
  - a starship prompt in Nord;
  - grey suggestions from history (→ accepts);
  - commands turn green or red as you type;
  - direnv: a `use venv` line in a project's `.envrc` activates its
    virtualenv on `cd`.
- **bat and btop** use Nord, like delta (10-06).
- **tmux:**
  - a status bar: the session pill turns yellow while the prefix is
    pending, COPY shows in copy mode, and all sessions are listed;
  - tmux-resurrect and continuum restore sessions after a restart;
  - Danish-friendly keys, `Ctrl+a` `f` and `Ctrl+a` `g`;
  - `verify.sh` warns when a second tmux server runs, because continuum
    silently stops saving then.
- **yazi** (`y`):
  - shows hidden files;
  - a git sign per file;
  - Markdown rendered in the preview;
  - bookmarks;
  - `Tab` between tabs;
  - copy and folder sync between windows.

  Config keys are written against yazi 26.9.

### Git, editor and code

- **git:**
  - **History stays linear.** `pull.rebase`, and `merge.ff = only` refuses
    a merge that can't fast-forward. The rules for agents are in
    `claude/.claude/CLAUDE.md`.
  - A new branch's first push sets its upstream.
  - The commit editor shows the diff.
  - Tags sort by version.
  - Identity and credentials live in `~/.gitconfig.local`, never in the
    repo.
  - The hooks were fixed: a repo's first commit is checked, and branch
    deletions skip the pre-push hook.
- **lazygit:** kept after its trial, mostly for looking around a repo.
  Practice steps are in `doc/lazygit.md`. macOS only for now.
- **nvim:**
  - the finder keys above;
  - the tutorial's Level 8;
  - lazygit on `Space` `g` `g`;
  - yazi inside nvim;
  - TypeScript works: its language server was never installed on the
    MacBook, and `ts_ls` needs TypeScript 6, because 7 has no `tsserver`.
- **C++** (10-12):
  - `templates/cpp-project/` has `CMakePresets.json` with `debug`,
    `release` and `asan`;
  - ccache is used when installed;
  - configuring a preset links `compile_commands.json` for clangd;
  - `scripts/bootstrap-cpp-project.sh` works on macOS again (it failed at
    its first `sed`).

  Tried first in bullet-ble, where a full rebuild went from 17 s to 3 s.
- **Docker:** OrbStack replaced Docker Desktop (10-12), with the same
  `docker` and `docker compose`. devbox didn't need any change. It's free
  for personal use only, so a work Mac needs a licence or Docker Desktop.
- **New in the Mac installer:** gh, cmake, ninja, tree, wget, jq, ccache,
  lazygit, OrbStack, Karabiner, pam-reattach, Raycast.
- **PATH cleanups:**
  - Homebrew's dotnet comes first, ahead of an old 2022 install;
  - the `node@18` pin is gone.

### Claude Code

- `claude/.claude/CLAUDE.md` is the global working config, linked into
  `~/.claude`. It holds the todo-list conventions and the linear-history
  rules.
- **The todo brief** (10-08): a SessionStart hook shows the open items of
  `~/Development/todo` for the repo a session starts in. Each machine
  registers it in its own `settings.json`.
- **`remote`** (10-08) lets Claude work on the offline work Mac over an SSH
  cable:
  - it mounts the remote with FUSE-T sshfs, then reads, searches, runs
    read-only git, builds and tests;
  - Claude may run it without asking;
  - the `remote-machine` skill says when to use it;
  - unmounting removes the `._` files macOS leaves on the remote;
  - 97 tests run against a stand-in host on this Mac (`doc/remote-machine.md`).
- **`AGENTS.md`** points other agents at the same rules.

### Keeping machines in step

- **`scripts/verify.sh`** checks, read-only, that this machine is fully
  applied. Exit 0 means done. It records the commit it passed at, which is
  where the next sync starts reading `CHANGELOG.md`.
- **`CHANGELOG.md`:** every change that affects a machine gets an entry with
  "On other machines" steps.
- **`scripts/packages.sh`** is the one list of stow packages per OS.
- **The installers** are re-run safe, back up before replacing anything, and
  exit 1 on any problem.
- **`scripts/update.sh`** (10-12) upgrades a Mac:
  - it saves the AeroSpace layout and runs `brew upgrade`;
  - it restarts AeroSpace if that was upgraded, and puts the windows back;
  - it updates nvim's and yazi's plugins;
  - it lists what moved, then runs `verify.sh`.

  `doc/tools.md`, "Versions and upgrading", says what to re-check after a
  big upgrade.
- **`doc/tools.md`:** every tool, what it's for, and which OS has it.
- **Tests and CI:**
  - `scripts/lint.sh` (shellcheck, stow, executable bits) runs in CI;
  - `scripts/test-zsh.sh` and `scripts/test-in-docker.sh <image>` test
    the shell and the Linux installers.

### Linux (Arch, Debian, WSL, Pi)

- **zsh is the login shell** (10-06). The Linux bash files are gone, and a
  `zsh-linux` package holds `.zprofile`: one ssh-agent per login, and
  Hyprland started on TTY1.
- **Linux also got** direnv, `tp`, `y`, and Nord for bat and btop.
- **Hyprland 0.56 fixes** (10-05): window rules in the new syntax, and
  hyprpaper's new config, which brings the wallpaper back. The `hyprland.lua`
  port that 0.57 needs waits on branch `hypr-lua`.
- All of it is tested in Docker (Ubuntu 24.04, Debian 12, Arch), not yet on
  hardware.

## Removed, or tried and not kept

| What | Why | When |
|---|---|---|
| AutoRaise | AeroSpace does focus-follows-mouse itself since 0.21 | 10-12 |
| Alacritty (macOS) | Ghostty won the trial; the config stays for Arch | 10-12 |
| Docker Desktop | OrbStack does the same job with the same commands | 10-12 |
| Alfred | Raycast replaced it. The app is in the Trash; the settings and Powerpack licence stay in `~/Library/Application Support/Alfred` | 10-12 |
| Rectangle Pro | Fought AeroSpace | 10-05 |
| `node@18` pin | End of life; it hid Homebrew's current node | 10-06 |

Considered and left out:
- Ghostty's quick terminal: skipped for now.
- watchexec: the git hooks already run the tests at the right moment.
- A Lua language server: Martin doesn't write Lua.
- atuin: only worth it for synced history.
- Time Machine: no drive.

## What the repo can't carry

Each Mac needs these by hand or keeps them itself:
- **Permissions:**
  - Accessibility for AeroSpace;
  - Karabiner's driver and Input Monitoring;
  - a Touch ID fingerprint;
  - OrbStack's helper.
- **App settings in the apps' own stores:** Raycast's hotkey and clipboard
  settings.
- **Per-machine files:**
  - `~/.gitconfig.local` and `~/.zshrc.local`;
  - `~/.zprofile`, where OrbStack adds a line;
  - `~/.claude/settings.json`, which needs the todo-brief hook registered;
  - each project's `.envrc`.
- **Claude's memory notes**, which are per machine. The rules that matter
  are in CLAUDE.md.
- **The wallpaper**, set once per machine.

The "Human-only" list in `doc/applying-the-setup.md` has the exact clicks.

## Still open (2026-10-15)

From the todo list, the items that touch this setup:
- **Run `scripts/update.sh`.** Run `--dry-run` first, and save tmux with
  `Ctrl+a` `Ctrl+s` before. tmux 3.8, neovim, llvm, sketchybar and the app
  font are waiting.
- **Sync the other machines:** the Mac at home (the prompt in "Handing a Mac
  to an agent"), the Arch box, the Pi, WSL and Windows.
- **The NUC:** a from-scratch Arch test.
- **Merge `hypr-lua` before Hyprland 0.57** reaches Arch. Until then, hold
  the upgrade.
- **The work Mac's one-time setup for `remote`:** Remote Login, the key, the
  cable.
- **After a restart:** check the FileVault unlock screen shows the new
  wallpaper.
- **Linux equivalents:** Caps Lock (keyd) and lazygit.
- **Practice:** lazygit's seven steps and the tmux week plan.
