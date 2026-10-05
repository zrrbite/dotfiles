# Applying this setup to a machine

Written for an AI agent asked to "apply this repo" to a machine. People can
follow it too, but it is written as instructions. `CLAUDE.md` describes how
the repo is laid out and how to work *on* it; this file covers putting it
*onto* a machine. `AGENTS.md` points here.

## Pick a path

Ask the human two things before doing anything, unless they already said:

1. **Whose machine is it?** Martin's own personal machine, or anyone else's,
   including Martin's work laptop.
2. **Which OS?**

| Machine | macOS | Arch | Debian / Ubuntu / WSL / Raspberry Pi | Windows |
|---|---|---|---|---|
| Martin's own | [Path A](#path-a-martins-own-machine) | [Path A](#path-a-martins-own-machine) | [Path A](#path-a-martins-own-machine) | [Path C](#path-c-windows) |
| Work, or anyone else's | [Path B](#path-b-work-or-someone-elses-machine) | [Path B](#path-b-work-or-someone-elses-machine) | [Path B](#path-b-work-or-someone-elses-machine) | [Path C](#path-c-windows) |

Already set up from an older version of this repo? See
[Updating a machine](#updating-a-machine-that-already-has-it) instead. Its
first step has to happen before `git pull`.

The repo can be cloned anywhere. Every script works from its own location,
and every stow command here passes `-t ~`. The examples use `~/dotfiles`.

## What "done" means

On macOS and Linux, **`scripts/verify.sh` exits 0**. It is read-only. It
checks that each package is linked (stow has nothing left to do), that no
app-state directory is a symlink into the repo, that the repo is clean, that
git identity is set and doesn't come from the tracked file, and, on macOS,
that the desktop services are running. It ends by listing what only a person
can confirm, such as Accessibility permissions. On Path B, pass the packages
you applied: `scripts/verify.sh nvim starship tmux`. If you linked
`claude` without `CLAUDE.md`, name it `claude-skills` there.

On Windows there is no verify script yet; [Path C](#path-c-windows) lists the
checks.

Report the verify output to the human as the result. Don't summarise a FAIL
away.

## Rules for every path

1. **Never overwrite git identity or credentials.** `git/.gitconfig` carries
   neither. They belong in `~/.gitconfig.local`, which it includes last.
   **Create that file before linking `git`.** Otherwise the machine's existing
   identity disappears with the old `~/.gitconfig`. The installers and
   `stow_windows.ps1 git` do this themselves; see [Git](#git).
2. **Don't link `claude/.claude/CLAUDE.md` on anyone else's machine.** It tells
   an agent to push tasks to Martin's private `zrrbite/todo` repo. At work that
   would leak work details into a personal GitHub repo. The skills are fine on
   their own; see [Claude Code](#claude-code).
3. **Preview, then ask.** Dry-run first (`--dry-run`, `stow -n`, `-DryRun`)
   and show the human what would be linked or replaced. Anything that needs
   admin rights, a password, a system permission or a policy exception is the
   human's to do. List it for them; don't work around it.
4. **Never `stow --adopt`.** It pulls the machine's file *into the repo*,
   overwriting the tracked version.
5. **A non-zero exit is a failure.** The installers and `stow_windows.ps1` exit
   1 when anything went wrong and print what. Stop and report it.

## Path A: Martin's own machine

Run the installer. On Martin's machines it's the intended path, and it's
re-run safe: by default it only installs what's missing.

### Prerequisites (macOS)

- **Command Line Tools.** Human-only, because it opens a GUI dialog:
  `xcode-select --install`. The installer stops with this instruction if
  they're missing.
- **Homebrew.** The installer installs it if missing, but Homebrew asks for
  the user's password. Run the installer in a terminal where the human can
  type it, or have them install Homebrew first. If they did, the installer
  finds it in `/opt/homebrew` or `/usr/local` even when it isn't on the
  agent's PATH yet.
- **Git identity on a fresh machine.** With no old `~/.gitconfig` there's
  nothing to carry over. **Create it before running the installer**:
  otherwise its closing `verify.sh` fails on identity and the installer exits 1.
  ```bash
  git config -f ~/.gitconfig.local user.name  "Martin Kjeldsen"
  git config -f ~/.gitconfig.local user.email "<ask the human>"
  git config -f ~/.gitconfig.local credential.helper osxkeychain
  git config -f ~/.gitconfig.local diff.tool nvimdiff    # meld isn't installed on macOS
  git config -f ~/.gitconfig.local merge.tool nvimdiff
  ```

### Prerequisites (Linux)

- **sudo.** Both installers call `sudo`; the human types the password.
- **Git identity on a fresh machine**, before the installer, as on macOS but
  with a Linux credential helper:
  ```bash
  git config -f ~/.gitconfig.local user.name  "Martin Kjeldsen"
  git config -f ~/.gitconfig.local user.email "<ask the human>"
  git config -f ~/.gitconfig.local credential.helper "cache --timeout=86400"   # or `store` (plaintext)
  ```
- **Arch with an NVIDIA GPU:** the driver, kernel parameters and mkinitcpio
  are a human, hardware-specific job. Follow `doc/arch-hyprland-guide.md`
  ("Bare Metal Differences") *before* the installer. The guide's
  `env =` lines for Hyprland would go into the shared, tracked
  `hypr/.config/hypr/hyprland.conf`, which changes every machine. Don't
  commit them; tell the human.
- **Arch:** Hyprland starts on login on TTY1 (`bash/.bash_profile-arch`).
  There is no display manager, so after the installer: reboot, log in on TTY1.

### Run

```bash
git clone https://github.com/zrrbite/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install_darwin.sh --dry-run     # preview; show the human
./install_darwin.sh               # missing packages only; re-run safe
```

Flags:
- `--with-desktop` hides the Dock and menu bar and sets the wallpaper. Use it
  for a fresh machine only, when asked.
- `--upgrade` lets brew upgrade existing packages.

On Linux, `./install_arch.sh` or `./install_debian.sh` (WSL and Raspberry Pi
are symlinks to the Debian one). They use `sudo`, so the human types the
password.

What the installer does, in order:
1. Packages. A failed brew install is recorded, not fatal.
2. Carries git identity into `~/.gitconfig.local`.
3. Backs up the configs it will replace to `~/.config-backup-<timestamp>/`
   (the `CONFIGS_TO_BACKUP` list in the script), deleting an original only
   once its copy succeeded.
4. Creates `~/.config`, `~/.config/fastfetch` and `~/.claude` as real
   directories.
5. Stows the packages in `scripts/packages.sh`.
6. Starts services.
7. Runs `scripts/verify.sh` and ends with a problem summary.

### Human-only, after the installer (macOS)

- Grant **Accessibility** to **AeroSpace** and **AutoRaise**: System Settings
  → Privacy & Security → Accessibility. AutoRaise runs as a brew service, so
  if it isn't offered there, add its binary with **+**:
  `$(brew --prefix autoraise)/bin/AutoRaise`.
- Launch AeroSpace once (it starts at login after that). It starts sketchybar
  and borders.
- First-launch prompts: Ghostty asks about notifications, and oh-my-zsh may
  offer an update. These are the human's calls.

Then run `scripts/verify.sh` again; done is exit 0.

## Path B: work, or someone else's machine

Don't run the installers here. They replace `~/.zshrc` wholesale and assume
Martin's choices. Apply packages one at a time.

### 1. Discover first (read-only)

Find out the following and report it before changing anything:

| Question | macOS | Linux | Windows |
|---|---|---|---|
| Is the user an admin? | `id -Gn \| grep -qw admin` | `sudo -n true` or `id -nG \| grep -qwE 'sudo\|wheel'` | `whoami /groups` and look for Administrators |
| Is the machine managed? | `profiles status -type enrollment` | ask; look for config management (e.g. `/etc/puppetlabs`, `/etc/chef`, a `realm` join) | Settings → Accounts → Access work or school |
| Package manager present? | `command -v brew` | `apt` / `pacman`; `command -v stow` | `scoop --version`, `winget --version` |
| Existing git config, with origins | `git config --list --show-origin --show-scope` | same | same |
| Existing global hooks | `git config --global --get core.hooksPath` | same | same |
| Do work repos use hook managers? | look for `.husky/`, `lefthook.yml`, `.pre-commit-config.yaml` | same | same |
| Configs that would be replaced | `ls -la ~/.zshrc ~/.gitconfig ~/.config/{nvim,starship.toml,alacritty,ghostty,aerospace,sketchybar}` | `ls -la ~/.bashrc ~/.gitconfig ~/.tmux.conf ~/.gdbinit ~/.config/{nvim,starship.toml}` | `~\.gitconfig`, `%LOCALAPPDATA%\nvim`, `~\.glzr` |
| Proxy or blocked downloads? | `env \| grep -i proxy`; does `curl -I https://github.com` work? | same | same, in PowerShell |

If the machine is managed, installing casks into `/Applications`, granting
Accessibility, or running Scoop's installer may be blocked. Say so up front.

### 2. Choose the packages

Each top-level directory is a package. How safe each one is on a work machine:

| Package | Platforms | Work-safe? | Notes |
|---|---|---|---|
| `nvim` | all | ✅ | Full IDE config. Installs plugins from GitHub on first launch and needs a C compiler and `make` for treesitter. TypeScript needs `npm i -g typescript-language-server typescript`. |
| `starship` | all | ✅ | Prompt only. |
| `tmux` | mac, Linux | ✅ | `Ctrl+a` prefix. |
| `gdb` | Linux | ✅ | `~/.gdbinit`. It has hardcoded `/home/zrrbite` paths, so on another user account those lines do nothing. |
| `clang` | all | ✅ with care | `~/.clang-format`/`~/.clang-tidy` are only fallbacks. A repo's own config wins, but a work repo *without* one would pick up Allman/Unreal Engine style. |
| `ghostty` | mac | ✅ | Default terminal (`alt-enter`), Nord. `ghostty` cask. |
| `alacritty` | mac (Linux optional) | ✅ | Second terminal (`alt-shift-enter`), same Nord config. Only one of the two is needed. |
| `zsh` | mac | ⚠️ ask | Replaces `~/.zshrc`. Merge any work-specific lines (proxy, SDK paths, corporate tooling) in first. |
| `fastfetch` | all | ✅ | On macOS, create `~/.config/fastfetch` first, stow with `--ignore='config\.jsonc'`, and link `config-darwin.jsonc` in its place (see `install_darwin.sh`). |
| `aerospace`, `sketchybar`, `autoraise` | mac | ✅ needs permissions | The desktop stack. See [macOS desktop](#macos-desktop). |
| `git` | all | ⚠️ after `~/.gitconfig.local` | Identity and credentials come from `~/.gitconfig.local`; create it first. Global hooks and a global ignore still apply. See [Git](#git). |
| `claude` | all | ⚠️ skills only | See [Claude Code](#claude-code). |
| `bash` | per-OS variants | ⚠️ ask | `bash/.bashrc-<os>` is linked to `~/.bashrc` by hand (the installers do it); check for existing content first. |
| `hypr`, `foot`, `waybar`, `rofi`, `mako`, `wlogout`, `cava`, `gtk`, `mimeapps`, `discord` | Arch | n/a | Linux desktop only. |

Per-OS package lists are in `scripts/packages.sh`. `doc/`, `img/`, `scripts/`,
`templates/`, `screenshots/` and `windowsterminal/` are not packages; they
carry a `.stow-local-ignore`.

### 3. Apply (macOS / Linux)

Install the tools the human agrees to by hand. The lists are `BREW_PACKAGES`
and `BREW_CASKS` in `install_darwin.sh` (or the package lists in the Linux
installers).

**Create the app-state directories first.** If a target directory is missing,
stow links the whole directory into the repo. Claude Code would then write its
history into the working tree, for example.

```bash
mkdir -p ~/.config ~/.claude
```

Then stow one package at a time, previewing each:

```bash
stow -n -v -t ~ nvim        # shows LINK lines, and any conflicts
stow -v -t ~ nvim           # only after the preview is clean and approved
```

A conflict means a real file is in the way. Copy it to a backup directory,
show the human what differs, and move it aside only once they agree.

Finish with `scripts/verify.sh <the packages you applied>`.

### macOS desktop

AeroSpace (tiling), sketchybar (bar), JankyBorders (`borders`) and AutoRaise
(focus-follows-mouse) work together:

- AeroSpace starts at login (`start-at-login = true`) and launches sketchybar
  and borders from `after-startup-command` in `aerospace.toml`.
- AutoRaise runs as a launchd service: `brew services start
  dimentium/autoraise/autoraise`. Do not also launch it from `aerospace.toml`,
  or two instances will run.
- The sketchybar workspace icons need the `font-sketchybar-app-font` cask, and
  the vendored `sketchybar/.config/sketchybar/plugins/icon_map.sh` must come
  from the same release. See `doc/status-bar-theming.md`.
- **Human-only:** grant Accessibility to AeroSpace and AutoRaise in System
  Settings → Privacy & Security. On a managed Mac this may need IT.

Layout fact that breaks silently if changed: the bar is 32pt tall, and
`gaps.outer.top = 44` in `aerospace.toml` is that height plus a 12pt gap.
Keybindings deliberately mirror GlazeWM on Windows; see `doc/aerospace-macos.md`
and `doc/tiling-window-managers.md`.

## Path C: Windows

### Prerequisites

- **The right to create symlinks.** Every config is a symlink, which needs
  **Developer Mode on Windows 10 and 11 alike** (Settings → System → For
  developers), or an elevated shell. A non-admin user on Windows 11 without
  Developer Mode cannot create them. Both scripts test this first and change
  nothing if it fails. On a managed machine, enabling it may need IT.
- **Execution policy.** If scripts are blocked, run them for this process
  only, which needs no admin:
  `powershell -ExecutionPolicy Bypass -File .\stow_windows.ps1 -List`
- **Tools.** `git` must exist before linking `git`. The shared config also
  calls `nvim` (editor) and `delta` (pager), so install those first, or git
  diff/log and commit break. With Scoop: `scoop install git neovim delta
  starship`. Installing Scoop itself (`irm get.scoop.sh | iex`) is the human's
  call on a managed machine.

### Martin's own Windows machine

`install_windows.ps1` installs Scoop, a package set and Windows Terminal,
links everything and sets the wallpaper. It's fine on his own machine; read
its package list with him first.

### Work, or someone else's Windows machine

Don't run `install_windows.ps1`. Use `stow_windows.ps1`, one package at a
time:

```powershell
.\stow_windows.ps1 -List                 # packages and their targets
.\stow_windows.ps1 -DryRun starship nvim # preview, changes nothing
.\stow_windows.ps1 starship nvim
.\stow_windows.ps1 -DryRun git           # shows what it carries into ~\.gitconfig.local
.\stow_windows.ps1 git
```

It knows `git`, `clang`, `nvim`, `starship`, `bash` (with `.minttyrc`),
`fastfetch`, `glazewm`, `zebar` and `claude` (skills only; `CLAUDE.md` is
never linked). The symlink check also runs in `-DryRun`, so a preview warns if
the real run would stop. An existing
real file is moved to `<target>.bak-<timestamp>` only as the link is created,
and moved back if the link fails.

Notes:
- `bash` replaces `~\.bashrc`, which aliases `cat`, `find` and `ps` and
  initialises starship, fzf and zoxide. Ask first, and install those tools
  before linking it.
- `starship` only changes Git Bash, through `.bashrc-windows`. No PowerShell
  profile is shipped. For PowerShell, add `Invoke-Expression (&starship init
  powershell)` to `$PROFILE` if the human wants it.
- `nvim` needs a C compiler and `make` (treesitter parsers, fzf-native) plus
  network access to GitHub on first launch: `scoop install gcc make`, or
  expect `:checkhealth` errors. The same applies on macOS/Linux, where the
  installers provide them.
- Line endings: `.gitattributes` forces LF on checkout, so the hooks and
  `.bashrc-windows` work even with Git for Windows' `core.autocrlf=true`.
- The GlazeWM cheatsheet keybind (`glazewm/.glzr/glazewm/config.yaml`) calls
  `C:/dev/dotfiles.git/scripts/glazewm-cheatsheet.ps1`. Clone there, or edit
  that path.
- Starting GlazeWM at login isn't automated.

### Done on Windows

- `.\stow_windows.ps1 <packages>` again reports "Already linked" for every
  item and exits 0.
- `git config --global --includes --show-origin --get-regexp '^(user\.|credential\.)'`
  shows identity from `~\.gitconfig.local`.
- A test commit in a scratch repo shows the expected author.
- `nvim` then `:checkhealth`, if `nvim` was linked.

## Updating a machine that already has it

For a machine set up from an older version of this repo.

**1. Save git identity first, before pulling.** If `~/.gitconfig` is a
symlink into the repo, an older version carried the identity inside the
tracked file. Newer versions moved it to `~/.gitconfig.local`, so pulling
would leave the machine with no identity. Copy the current values out while
they still exist:

```bash
if [ ! -e ~/.gitconfig.local ]; then
    git config -f ~/.gitconfig.local user.name  "$(git config --global user.name)"
    git config -f ~/.gitconfig.local user.email "$(git config --global user.email)"
    h="$(git config --global credential.helper)"
    [ -n "$h" ] && git config -f ~/.gitconfig.local credential.helper "$h"   # an empty value would reset helpers
fi
```

If `~/.gitconfig` is a plain file instead, skip this. The installers'
seed step handles it.

**2. Pull and re-run the installer** (macOS / Linux). It's re-run safe,
installs only what's missing (new tools, fonts, casks), and re-links:

```bash
cd ~/dotfiles && git pull --ff-only
./install_darwin.sh        # or ./install_arch.sh, ./install_debian.sh
```

For config-only changes, with no new tools, `./reload.sh` is enough: pull,
re-stow and reload the desktop.

**3. Check, and fix anything folded into the repo.** Run
`scripts/verify.sh`. Older installers could leave `~/.claude` or
`~/.config/fastfetch` as a symlink into the repo; `verify.sh` reports that as
FAIL. To fix one:

```bash
stow -D -t ~ claude && rm ~/.claude && mkdir ~/.claude && stow -t ~ claude
```

This works because `rm` on a symlink removes only the link. Check with
`ls -ld ~/.claude` first that it really is a symlink (`l` in the first
column).

**4. Pick up the changes in running apps.**
- Open a new shell.
- In Ghostty, reload with `⌘⇧,` (Alacritty reloads by itself).
- `aerospace reload-config` and `sketchybar --reload`, or let `reload.sh` do it.

**Windows:** do step 1 the same way in Git Bash or PowerShell, then
`git pull`, then `.\stow_windows.ps1 -DryRun <packages>` and
`.\stow_windows.ps1 <packages>`. Then the [Done on Windows](#done-on-windows)
checks.

## Git

`git/.gitconfig` is shared by every machine and holds **no identity and no
credential helper**. Its last line includes `~/.gitconfig.local`, so anything
set there overrides the repo file, including `core.hooksPath` and
`core.excludesFile`. Git silently ignores the include if the file is missing,
and the machine then has no identity at all.

**Before linking `git`, create `~/.gitconfig.local`:**

```bash
scripts/seed-gitconfig-local.sh --dry-run    # preview
scripts/seed-gitconfig-local.sh
```

It carries over, from the existing `~/.gitconfig`:
- identity (`user.*`) and credentials (`credential.*`);
- signing (`gpg.*`, `commit.gpgsign`, `tag.gpgsign`);
- what a work machine typically adds: proxy and certificates (`http.*`,
  `https.*`), `includeIf` (often where a work email lives), `url.*.insteadOf`,
  `core.autocrlf` and `core.sshCommand`.

Settings that aren't on that list stay only in the backup, so check the old
file for anything else per-machine. The script never overwrites an existing
`~/.gitconfig.local`. The installers and `stow_windows.ps1 git` run the same
step.

If nothing was carried over (fresh machine, or `~/.gitconfig` already points
into this repo), write it by hand:

```bash
git config -f ~/.gitconfig.local user.name  "<name>"
git config -f ~/.gitconfig.local user.email "<email>"
git config -f ~/.gitconfig.local credential.helper osxkeychain   # Windows: manager
```

Then link `git` and check where each value comes from. `--includes` is
required, because `--global` alone does not follow includes:

```bash
git config --global --includes --show-origin --get-regexp \
  '^(user\.|credential\.|core\.hookspath|core\.excludesfile)'
```

Identity and credential lines must come from `~/.gitconfig.local`.

What the shared file still changes, and how to undo each item in
`~/.gitconfig.local` if work needs it:

| Setting | Effect | Override in `~/.gitconfig.local` |
|---|---|---|
| `core.hooksPath = ~/.git-hooks` | Global hooks run in **every** repo, and each repo's own `.git/hooks` stop running. Hook managers that set a repo-local `core.hooksPath` (husky, lefthook) still win. | See below. |
| `core.excludesFile` → `.gitignore-global` | Ignores `*.pdf` and `*.zip` in every repo, so such files silently never get added. | `[core] excludesFile = ~/.gitignore-work` |
| `diff.noprefix = true` | Diffs without `a/` and `b/` prefixes, which some patch tooling rejects. | `[diff] noprefix = false` |
| `diff.tool`, `merge.tool` = `meld` | Installed by `install_arch.sh` and `install_windows.ps1`, not by `install_debian.sh` or on macOS. | `nvimdiff`, or install meld |
| `interactive.diffFilter = delta` | `git add -p` breaks without delta. | install delta |
| `core.editor = nvim`, `core.pager = delta` | Commit and diff break if these tools are missing. | install them, or override |
| `pull.rebase`, `rebase.autoStash`, `push.default = current` | Different defaults from stock git. Harmless, but surprising. | as needed |

**Global hooks.** The include still sets `core.hooksPath = ~/.git-hooks`, and
the hooks enforce Martin's own rules everywhere:

- `pre-commit` blocks any staged file containing the do-not-commit marker. For
  C++ files, it blocks unless they are clang-formatted, and it errors if no
  clang-format is installed.
- `pre-commit-ts` runs `npm run format:check` when that script exists.
- `pre-push` runs clang-tidy on changed C++ files when `compile_commands.json`
  exists.
- `pre-push-ts`, in any repo with `package.json` and `tsconfig.json`, runs
  each of `npm run type-check`, `lint` and `test:run` **that the repo defines**,
  and skips the rest. A repo that defines none of them pushes untouched.
  Otherwise, a failing check or a missing `node_modules` blocks the push.

Ask the human whether they want the hooks at work. If not, put `[core]
hooksPath = ~/.git-hooks-none` in `~/.gitconfig.local` and leave that
directory absent. This also stops each repo's own `.git/hooks` from running;
if work repos rely on those, the human has to decide between the two.

## Claude Code

The `claude` package holds `CLAUDE.md` (personal working rules), `hooks/` and
13 skills under `skills/`. On anyone else's machine:

```bash
mkdir -p ~/.claude
stow -n -v -t ~ --ignore='CLAUDE\.md' claude   # preview: skills + hooks only
scripts/verify.sh claude-skills                 # after linking: checks it without CLAUDE.md
```

On Windows, `stow_windows.ps1 claude` and `install_windows.ps1` link only
`skills`.

`hooks/pre-model-switch-compact.py` does nothing until it is registered in
`~/.claude/settings.json`. That is a per-machine choice; the package does not
ship a `settings.json`.

## Undo

- Stow: `stow -D -t ~ <pkg>` removes that package's symlinks. Then restore the
  backed-up file.
- Windows: `.\stow_windows.ps1 -Delete <pkg>`, then rename
  `<target>.bak-<timestamp>` back.
- Installer backups: `~/.config-backup-YYYYMMDD-HHMMSS/` on macOS and Linux,
  `%USERPROFILE%\.config-backup-<timestamp>\` on Windows. The Windows backup is
  flattened by file name, so the Zebar and Windows Terminal `settings.json`
  files overwrite each other there.
