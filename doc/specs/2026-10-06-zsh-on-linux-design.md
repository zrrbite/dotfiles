# zsh on Linux — design

2026-10-06. Agreed with Martin in conversation, part by part. Status: design
approved; implementation plan next.

## Goal

One shell config for every Unix machine. Today the Mac runs zsh
(`zsh/.zshrc`) and Arch, the Pi and WSL run bash from three near-copies
(`bash/.bashrc-arch`, `-wsl`, `-raspbian`), so every shell idea has to be
written twice and the copies drift. After this change, Linux runs zsh from the
same `.zshrc` as the Mac, and a shell idea lands once.

**Done means:**

- A new terminal on Arch, the Pi and WSL opens zsh with what the Mac has:
  starship, `t`, `tp`, `y`, direnv, fzf, zoxide, grey history suggestions and
  command highlighting.
- Hyprland still starts on TTY1. tmux's `Ctrl+a` `f` still opens `tp`.
- `scripts/verify.sh` checks the new pieces.
- The Mac behaves as before, except for the new shared aliases below.

**Not in scope:** Windows (Git Bash keeps `.bashrc-windows`); the Mac's bash
files (`.bashrc-darwin`, `.bash_profile-darwin`); dropping oh-my-zsh; ble.sh.

## Decisions

| Question | Decision | Why |
|---|---|---|
| zsh on Linux, or ble.sh in bash? | zsh | Shell ideas written once. |
| The Linux bash files | Retired | A second config drifts; `~/.bashrc` reverts to the distro default, used only if `bash` is typed. |
| eza and fzf shortcuts | `ll`, `lt`, `la`, `fcpp`, `ftodo`, `fmd`, `ffunc` everywhere; `ls` stays `ls` | One behaviour on every machine; no standard command overridden (the Mac's rule). Hiding `CLAUDE.md` and `.claude*` from listings is dropped. |
| Layout | Shared `.zshrc` plus one small file per OS (approach A) | The shared file stays readable; OS specifics are small and visible; per-machine lines stay out of git. Rejected: one file with inline OS blocks (conditionals throughout, no per-machine place); one full file per OS (rebuilds the drift). |
| oh-my-zsh | Kept, on Linux too | Least change, same behaviour everywhere. Its `git` plugin is unused (0 of 1,729 history lines), so dropping it can be a later, separate step. |

## Files

### `zsh` package (stowed on macOS, Arch, Debian)

**`.zshrc`**, shared. Order matters:

1. Load the OS file: `~/.config/zsh/darwin.zsh` when `$OSTYPE` is `darwin*`,
   `~/.config/zsh/linux.zsh` when `linux*`. First, because it sets up the PATH
   that every `command -v` below depends on.
2. Shared PATH: `typeset -U path PATH`, then `~/.cargo/bin` and `~/.local/bin`
   prepended if they exist.
3. oh-my-zsh (`plugins=(git)`, empty theme when starship exists), starship,
   zoxide (`--cmd cd`), fzf with the Nord `FZF_DEFAULT_OPTS`, direnv, ssh-agent.
   **fzf fallback:** `fzf --zsh` needs fzf 0.48+. Debian 12 (the Pi) and Ubuntu
   22.04 ship older ones, so when `fzf --zsh` fails, source
   `/usr/share/doc/fzf/examples/key-bindings.zsh` and `completion.zsh` if
   present.
4. Line-editing keys as today (Home/End in their several encodings, word
   jumps, `^U`). Harmless on terminals that don't send them.
5. Aliases: `grep --color=auto`; `ll`, `lt`, `la` with eza (as the Linux bash
   files define them, minus the `-I "CLAUDE.md|.claude*"`); `fcpp`, `ftodo`,
   `fmd`, `ffunc` from `.bashrc-arch`. These override oh-my-zsh's `ll`/`la`
   (`ls -lh`, `ls -lAh`), which is a visible change on the Mac.
6. `y`, the chafa aliases, `fimg`, `t` (with completion), `tp`: unchanged.
7. `~/.zshrc.local` if it exists: untracked lines for one machine.
8. zsh-autosuggestions then zsh-syntax-highlighting, last (highlighting must
   follow every widget and binding). Looked up in, first match wins:
   `$(brew --prefix)/share` (macOS), `/usr/share/zsh/plugins` (Arch),
   `/usr/share` (Debian).

**`.config/zsh/darwin.zsh`**: Homebrew `shellenv` (both prefixes); PATH entries
for dotnet, `~/.dotnet/tools`, Mono and Homebrew's llvm; the `roast` alias with
its caffeinate comment.

**`.config/zsh/linux.zsh`**:

- WSL (`$WSL_DISTRO_NAME` set, or `/proc/version` mentions Microsoft): the
  drive shortcuts from `.bashrc-wsl` (`c`, `d`, `cdrive`, `ddrive`, `dev`,
  `downloads`, `docs`).
- The fastfetch greeting, when fastfetch exists and not inside tmux. Arch
  greets today; inside tmux it would flash in the `Ctrl+a` `f` popup. Debian
  doesn't install fastfetch, so there is no greeting there, as now.

### `zsh-linux` package (new; stowed on Arch and Debian only)

**`.zprofile`**, read by zsh login shells:

1. Start one ssh-agent if `SSH_AUTH_SOCK` is unset, so Hyprland and every
   terminal inherit it. `.bash_profile-arch` got this by sourcing `.bashrc`
   before starting Hyprland; zsh reads `.zprofile` *before* `.zshrc`, so
   without this each terminal would start its own agent. `ssh-add` stays in
   `.zshrc`: a key passphrase is now asked in the first terminal rather than
   on the TTY.
2. The TTY1 Hyprland start, moved verbatim from `.bash_profile-arch`
   (`start-hyprland`, falling back to `Hyprland`).

A separate package because the Mac keeps its own `~/.zprofile`: Homebrew's
installer tells every Mac to create one (this Mac's also has a JetBrains
Toolbox line), so a shared one would conflict on every Mac.

### Retired

`bash/.bashrc-arch`, `.bashrc-wsl`, `.bashrc-raspbian`, `.bash_profile-arch`,
`.bash_profile-wsl`, `.bash_profile-raspbian`. Kept: `.bashrc-darwin`,
`.bash_profile-darwin`, `.bashrc-windows`, `.minttyrc`, `bash/.bashrc`.

## Installers

### Arch (`install_arch.sh`) and Debian (`install_debian.sh`)

1. Install `zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting` (pacman /
   apt).
2. Clone oh-my-zsh into `~/.oh-my-zsh` if absent, as `install_darwin.sh` does
   (clone only; `~/.zshrc` stays the repo's). A failed clone is a FAILURES
   entry, not a stop.
3. Add `zsh` and `zsh-linux` to `PACKAGES_ARCH` and `PACKAGES_DEBIAN` in
   `scripts/packages.sh`. Add `~/.zshrc` and `~/.zprofile` to the backup lists.
4. Stop linking `~/.bashrc` and `~/.bash_profile`. If either is a symlink into
   the repo, remove it and copy the distro default from `/etc/skel` when there
   is one.
5. Debian only: if `batcat` exists and `bat` doesn't, link
   `~/.local/bin/bat` to it; same for `fd` → `fdfind`. Aliases don't survive
   `xargs`, which `fcpp` and `ffunc` use; links fix those, yazi and the fzf
   previews alike.
6. If the login shell isn't zsh: `sudo chsh -s "$(command -v zsh)" "$USER"`.
   The installer already holds sudo, so there is no second password prompt. On
   failure, a FAILURES entry with the command.
7. The closing message says to log out and back in, not `source ~/.bashrc`.

### macOS (`install_darwin.sh`)

Nothing new to install. Stowing `zsh` picks up `.config/zsh/darwin.zsh`.

## Moving existing machines

**Linux (Arch box, Pi, WSL)**, in the CHANGELOG entry: pull and run the
installer **straight away**, then log out and back in. The pull deletes the
bash files that `~/.bashrc` and `~/.bash_profile` link to; until the installer
runs, a new terminal is unconfigured bash, and on Arch a logout lands on the
TTY without Hyprland (the installer can be run from there).

**The Mac:** pull, `stow -R -t ~ zsh`, open a new terminal. `~/.zprofile` stays
as it is.

## verify.sh

Packages come from `packages.sh` as before. New on Linux:

- FAIL: login shell (`getent passwd "$USER"`) isn't zsh.
- FAIL: `~/.bashrc` or `~/.bash_profile` is a dangling link into the repo.
- WARN: `~/.oh-my-zsh` missing; either zsh plugin missing.

## Other touch points

- `tmux/.tmux.conf`: the `Ctrl+a` `f` comment (the command, `$SHELL -ic tp`,
  already works with zsh).
- Docs: `CLAUDE.md` (shell sections, package list, installer notes),
  `doc/tools.md` (zsh, bash, plugin rows), `doc/applying-the-setup.md`,
  `doc/tmux.md`, `README.md` (TTY1 start, WSL section), the comment in
  `scripts/packages.sh`.
- archinstall `doc/arch-hyprland-guide.md` line 187 names
  `bash/.bash_profile-arch`; it becomes `zsh-linux/.zprofile`. Its manual,
  non-dotfiles steps (editing `~/.bash_profile` by hand) stay: a fresh Arch
  install is bash.
- `CHANGELOG.md`: an entry with the steps under "Moving existing machines".
- todo: the NUC checklist's terminal checks become zsh checks; log entry and
  README row.

## Testing

**Mac, before and after:**

- `zsh -i -c exit` prints nothing to stderr.
- `t`, `tp`, `y`, the aliases and both plugins are defined.
- `$PATH` has the same entries.
- Startup time (`time zsh -i -c exit`, a few runs) is about the same.
- `verify.sh` passes.

**Linux in Docker**, running the real installer as a non-root user with sudo:

- Images: `archlinux`, `ubuntu:24.04`, and `debian:12` (the Pi's base, whose
  fzf exercises the fallback).
- In each:
  - `zsh -i -c exit` is clean;
  - the functions, aliases, fzf's `^R` binding and both plugins are present;
  - on Debian, `bat` and `fd` resolve;
  - `getent` shows zsh;
  - `verify.sh` passes (on Arch, apart from the known AUR step that can't
    build under emulation).

**`.zprofile` alone:**

- as a login shell it starts one ssh-agent;
- with `XDG_VTNR=1`, no `DISPLAY` and a fake `start-hyprland` on PATH, it
  execs it;
- otherwise it doesn't.

**WSL branch:** `WSL_DISTRO_NAME=Ubuntu` in the Debian container defines the
drive shortcuts.

**Not testable here:** a real Hyprland login (the NUC checklist), the Pi
(tmux week, day 5), real WSL (the Windows laptop).

## Risks

- **The pull-then-installer gap** on existing Linux machines (above). Mitigated
  by the CHANGELOG wording; the Arch box can recover from the TTY.
- **A key passphrase** is now asked in the first terminal, not at the TTY login.
- **Startup cost on the Pi:** oh-my-zsh plus two plugins is slower than bash.
  Measure on the Pi when it's updated; dropping oh-my-zsh is the lever if
  needed.
