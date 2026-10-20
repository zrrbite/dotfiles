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

On macOS and Linux, **`scripts/verify.sh` exits 0**. Its only write is a
record of the commit it passed at (`~/.local/state/dotfiles/applied`; the
installers pass `--no-record`, since steps remain after them). It fails when
a package isn't linked (stow has something left to do), an app-state
directory is a symlink into the repo, or git identity is missing, empty or
from the tracked file. It warns, without failing, about a dirty repo, desktop
services that aren't running on macOS, permissions, and leftovers of removed
tools. It ends by listing what only a person can confirm. On Path B, pass the packages
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
  are a human, hardware-specific job. Follow the Arch guide in the archinstall repo
  (https://github.com/zrrbite/archinstall/blob/main/doc/arch-hyprland-guide.md)
  ("Bare Metal Differences") *before* the installer. Its NVIDIA settings
  for Hyprland would go into the shared, tracked config under
  `hypr/.config/hypr/`, which changes every machine. Don't commit them;
  tell the human.
- **Hyprland 0.57 drops `hyprland.conf`.** These dotfiles' Hyprland config
  is still in that format; Arch ships 0.56 as of 2026-10-05. Until it's
  migrated to `hyprland.lua` (see Martin's TODO), a 0.57 upgrade leaves
  Hyprland unconfigured. Check `pacman -Q hyprland` and tell the human.
- **Arch:** Hyprland starts on login on TTY1 (`zsh-linux/.zprofile`).
  There is no display manager, so after the installer: reboot, log in on TTY1.

### Run

```bash
git clone https://github.com/zrrbite/dotfiles.git ~/dotfiles
cd ~/dotfiles

# macOS
./install_darwin.sh --dry-run     # preview; show the human
./install_darwin.sh               # missing packages only; re-run safe

# Linux: Arch, or Debian/Ubuntu (install_wsl.sh and install_raspbian.sh are
# symlinks to install_debian.sh). No dry run; they use sudo, so the human
# types the password.
./install_arch.sh                 # or ./install_debian.sh
```

macOS flags:
- `--with-desktop` hides the Dock and menu bar and sets the wallpaper. Use it
  for a fresh machine only, when asked.
- `--upgrade` lets brew upgrade existing packages.

**A fresh Arch box, from a blank disk:** the archinstall guide's
[fast path](https://github.com/zrrbite/archinstall/blob/main/doc/arch-hyprland-guide.md#fast-path-arch-with-the-dotfiles-step-by-step)
is this, step by step, including what comes before the installer (git, an
NVIDIA driver, the Hyprland version) and what to check after.

What the macOS installer does, in order:
1. Packages. A failed brew install is recorded, not fatal.
2. Carries git identity into `~/.gitconfig.local`.
3. Makes folders an older run linked into the repo real again
   (`scripts/unfold.sh`), then backs up the configs it will replace to
   `~/.config-backup-<timestamp>/` (the `CONFIGS_TO_BACKUP` list), deleting
   an original only once its copy succeeded.
4. Creates `~/.config`, `~/.config/fastfetch`, `~/.claude`,
   `~/.claude/skills` and `~/.local/bin` as real directories.
5. Stows the packages in `scripts/packages.sh`.
6. Extras: yazi's plugins, btop's theme, Claude's permission for `remote`,
   Touch ID for sudo, the tmux plugins, oh-my-zsh; the desktop settings only
   with `--with-desktop`.
7. With someone at the terminal, `scripts/macos-permissions.sh`.
8. `scripts/verify.sh --no-record`, and a problem summary.

### Human-only, after the installer (macOS)

During the run, the `.pkg` casks (FUSE-T and its sshfs, Karabiner-Elements)
and `scripts/touch-id-sudo.sh` ask for the password; the human types it.

Afterwards, **`scripts/macos-permissions.sh`** walks the human through what
macOS lets only a person grant, one step at a time: it says what each is for,
opens the right System Settings page or app, waits, and checks what a script
can. The installer runs it at the end when someone is at the terminal. An
agent can't do these steps: ask the human to run it in a terminal, and use
`scripts/macos-permissions.sh --check` to see what's left (`--list` prints the
steps). They are Accessibility for AeroSpace (which also starts it, and it
starts sketchybar and borders); Karabiner-Elements' driver and Input
Monitoring; a Touch ID fingerprint; OrbStack's and Raycast's first starts;
and letting AeroSpace control Ghostty.

Also the human's calls:

- **Docker Desktop:** migrating to OrbStack is optional; see `CHANGELOG.md`
  2026-10-12 before removing Docker Desktop, whose uninstall takes
  OrbStack's `docker` link with it.
- **Desktop settings** (`--with-desktop` on a fresh Mac; on an existing one
  `scripts/macos-defaults.sh` and `scripts/finder-defaults.sh`) change the
  Dock, menu bar, Finder and text input. Ask before running them on a Mac
  that's already set up the way its owner likes.
- First-launch prompts: Ghostty asks about notifications, and oh-my-zsh may
  offer an update.

Then run `scripts/verify.sh` again; done is exit 0. It reports the
permissions too, and its "confirm by hand" list at the end covers what a
script can't see.

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
| Configs that would be replaced | `ls -la ~/.zshrc ~/.gitconfig ~/.config/{nvim,starship.toml,alacritty,ghostty,aerospace,sketchybar}` | `ls -la ~/.zshrc ~/.zprofile ~/.gitconfig ~/.tmux.conf ~/.gdbinit ~/.config/{nvim,starship.toml}` | `~\.gitconfig`, `%LOCALAPPDATA%\nvim`, `~\.glzr` |
| Proxy or blocked downloads? | `env \| grep -i proxy`; does `curl -I https://github.com` work? | same | same, in PowerShell |

If the machine is managed, installing casks into `/Applications`, granting
Accessibility, or running Scoop's installer may be blocked. Say so up front.

### 2. Choose the packages

Each top-level directory is a package. How safe each one is on a work machine:

| Package | Platforms | Work-safe? | Notes |
|---|---|---|---|
| `nvim` | all | ✅ | Full IDE config. Installs plugins from GitHub on first launch and needs a C compiler and `make` for treesitter. TypeScript needs `npm i -g typescript-language-server typescript@6` (`install_darwin.sh` does it); TypeScript 7 has no tsserver. |
| `starship` | all | ✅ | Prompt only. |
| `tmux` | mac, Linux | ✅ | `Ctrl+a` prefix. |
| `gdb` | Linux | ✅ | `~/.gdbinit`. It has hardcoded `/home/zrrbite` paths, so on another user account those lines do nothing. |
| `clang` | all | ✅ with care | `~/.clang-format`/`~/.clang-tidy` are only fallbacks. A repo's own config wins, but a work repo *without* one would pick up Allman/Unreal Engine style. |
| `ghostty` | mac | ✅ | Default terminal (`ctrl-alt-enter`), Nord. `ghostty` cask. |
| `yazi` | mac, Arch | ✅ | Terminal file manager; `y` in zsh launches it. Needs `yazi` plus, for previews, `ffmpeg`, `poppler` and `sevenzip`. Image previews need Ghostty, and `allow-passthrough on` inside tmux (set in `tmux/.tmux.conf`). |
| `alacritty` | Linux (optional) | ✅ | Nord config for Alacritty; foot is the Arch terminal. Not on macOS since 2026-10-12, where Ghostty is the terminal. |
| `zsh` | mac, Linux | ⚠️ ask | Replaces `~/.zshrc`. Put work-specific lines (proxy, SDK paths, corporate tooling) in `~/.zshrc.local`, which it loads. On Linux the installer also makes zsh the login shell. |
| `zsh-linux` | Linux | ⚠️ ask | Replaces `~/.zprofile`: one ssh-agent per login, Hyprland on TTY1 if installed. |
| `fastfetch` | all | ✅ | On macOS, create `~/.config/fastfetch` first, stow with `--ignore='config\.jsonc'`, and link `config-darwin.jsonc` in its place (see `install_darwin.sh`). |
| `aerospace`, `sketchybar` | mac | ✅ needs permissions | The desktop stack. See [macOS desktop](#macos-desktop). |
| `git` | all | ⚠️ after `~/.gitconfig.local` | Identity and credentials come from `~/.gitconfig.local`; create it first. Global hooks and a global ignore still apply. See [Git](#git). |
| `claude` | all | ⚠️ skills only | See [Claude Code](#claude-code). |
| `bash` | mac, Windows | ⚠️ ask | `bash/.bashrc-darwin` / `.bashrc-windows` are linked to `~/.bashrc` by the installers; check for existing content first. Linux uses zsh. |
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

AeroSpace (tiling, and focus-follows-mouse), sketchybar (bar) and
JankyBorders (`borders`) work together:

- AeroSpace starts at login (`start-at-login = true`) and launches sketchybar
  and borders from `after-startup-command` in `aerospace.toml`.
- The sketchybar workspace icons need the `font-sketchybar-app-font` cask, and
  the vendored `sketchybar/.config/sketchybar/plugins/icon_map.sh` must come
  from the same release. See `doc/status-bar-theming.md`.
- **Human-only:** grant Accessibility to AeroSpace in System
  Settings → Privacy & Security (`scripts/macos-permissions.sh` walks
  through it and the others). On a managed Mac this may need IT.

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

**0. Find out what's new for this machine.** Run `scripts/verify.sh`. Its
first line says which commit the machine was last synced at, and how many
commits behind it is. No record (or no `verify.sh` yet, in a clone from
before 2026-10-05) means it predates 2026-10-05. Then read `CHANGELOG.md`
from that date. Each entry lists what changed and its **On other machines**
steps, including manual ones the installer can't do (e.g. Raycast's script
folder). The steps below are the common core. In a clone older than these
files, read them with `git fetch` and `git show origin/master:<path>`
before pulling.

**1. Save git identity first, before pulling.** If `~/.gitconfig` is a
symlink into the repo, an older version carried the identity inside the
tracked file. Newer versions moved it to `~/.gitconfig.local`, so pulling
would leave the machine with no identity. Copy the current values out while
they still exist:

```bash
if [ ! -e ~/.gitconfig.local ]; then
    n="$(git config --global user.name)"; e="$(git config --global user.email)"
    if [ -n "$n" ] && [ -n "$e" ]; then
        git config -f ~/.gitconfig.local user.name  "$n"
        git config -f ~/.gitconfig.local user.email "$e"
        h="$(git config --global credential.helper)"
        [ -n "$h" ] && git config -f ~/.gitconfig.local credential.helper "$h"   # an empty value would reset helpers
        if [ "$(uname -s)" = Darwin ]; then   # no meld on macOS
            git config -f ~/.gitconfig.local diff.tool nvimdiff
            git config -f ~/.gitconfig.local merge.tool nvimdiff
        fi
    else
        echo "No identity to save; leave ~/.gitconfig.local to the installer"
    fi
fi
```

If `~/.gitconfig` is a plain file instead, skip this. The installers' seed
step handles it. Already pulled? Don't create the file by hand: the seed
step finds the identity in the repo's history, and `verify.sh` fails on an
empty one.

**1b. Repair anything an older installer wrote into the repo.** Before
2026-10-05, the macOS installer could make `~/.config/fastfetch` (and
`~/.claude`) a symlink into the repo, and then replaced the tracked
`fastfetch/.config/fastfetch/config.jsonc` with a link to the macOS config.
The pull goes through regardless, but the link keeps writing into the repo,
so undo it first:

```bash
cd <dotfiles> && git status --short      # anything you didn't change yourself?
ls -ld ~/.config/fastfetch ~/.claude     # an `l` in the first column = symlink
if [ -L ~/.config/fastfetch ]; then
    git checkout -- fastfetch/.config/fastfetch/config.jsonc   # restore the tracked file
    rm ~/.config/fastfetch                                     # removes only the link
fi
```

Other changed files: nvim's `lazy-lock.json` is a lockfile, discard it
(`git checkout -- nvim/.config/nvim/lazy-lock.json`); `karabiner.json` was
rewritten by Karabiner on that machine, discard it too unless the human
changed a setting on purpose. Anything else: ask. For a `~/.claude` symlink,
see step 3; the installer also repairs both now (`scripts/unfold.sh`).

**2. Pull and re-run the installer** (macOS / Linux). It's re-run safe,
installs only what's missing (new tools, fonts, casks), and re-links. One run
at the newest commit covers every older entry that says to re-run it or to
re-stow. It asks for the password (the `.pkg` casks, Touch ID for sudo), so
the human runs it, in a terminal; an agent's shell can't pass a password on.

```bash
cd <dotfiles> && git pull --ff-only
./install_darwin.sh        # or ./install_arch.sh, ./install_debian.sh
```

For config-only changes, with no new tools, `./reload.sh` is enough: pull,
re-stow and reload the desktop.

**macOS set up before 2026-10-12: AeroSpace must be 0.21 before it loads the
pulled config.** The config uses keys AeroSpace only knows from 0.21
(`config-version = 2`, `focus-follows-mouse`); an older one rejects the whole
file at its next reload or restart, and every key binding with it. Upgrade
it *before* pulling and restart it right after, so neither version reads the
other's config: steps 3 and 4 of "Handing a Mac to an agent" below.
`verify.sh` fails until it's done.

**3. Check, and fix anything folded into the repo.** Run
`scripts/verify.sh`. Older installers could leave `~/.claude`,
`~/.claude/skills` or `~/.config/fastfetch` as a symlink into the repo, so
apps wrote into the working tree; `verify.sh` reports that as FAIL. To fix
one, name it (quit Claude Code first for `~/.claude`: it writes there):

```bash
scripts/unfold.sh ~/.claude      # real folder again; moves what apps wrote back out
stow -R -t ~ claude              # or re-run the installer
```

**4. Pick up the changes in running apps.**
- Open a new shell.
- In Ghostty, reload with `⌘⇧,`.
- `aerospace reload-config` and `sketchybar --reload`, or let `reload.sh` do it.

### Handing a Mac to an agent

To bring another of Martin's Macs up to date with an AI agent (Claude Code
on that Mac, started in its dotfiles folder), paste:

```
This is my second Mac. Sync it with my dotfiles (github.com/zrrbite/dotfiles)
so it matches my main MacBook. The clone here may be older than the docs
below: run `git fetch`, read them with `git show origin/master:<path>`, and
don't pull until they say so. Read AGENTS.md and doc/handover-2026-10.md
(the overview), then "Handing a Mac to an agent" and "Updating a machine
that already has it" in doc/applying-the-setup.md, and follow them. If
there's no clone yet, follow Path A instead. Ask me before anything the doc
says to ask about.
```

For the agent. This order overrides the order inside the CHANGELOG entries.

1. **Find the starting point:** `scripts/verify.sh`, if the clone has it,
   says when this Mac was last synced. No `verify.sh` or no record: every
   `CHANGELOG.md` entry since 2026-10-05 ("the big one") is new.
2. **Read all of those entries before doing any of them.** Later entries
   undo earlier ones: don't install or set up what a later entry removes
   (AutoRaise, Alacritty on macOS, Docker Desktop), but do do the removal
   steps. Every "re-run the installer" and "re-stow" is covered by the one
   installer run in step 5.
3. **Before `git pull`, in this order:**
   - "Updating" steps 1 and 1b: save the git identity, repair what an old
     installer wrote into the repo.
   - **Ask Martin about Alfred and Docker Desktop now** (the MacBook has
     neither; Raycast and OrbStack replaced them): step 5's walk starts
     Raycast and OrbStack, and OrbStack takes over `docker`.
     `brew list --cask | grep -i docker` gives Docker Desktop's cask name,
     `docker-desktop` or the older `docker`; none means it was installed by
     hand.
   - AutoRaise running? `brew services stop dimentium/autoraise/autoraise`.
   - AeroSpace older than 0.21 (`aerospace --version`)? Save the window
     layout with `aerospace list-windows --all --format '%{window-id}
     %{workspace}' > ~/aerospace-layout.txt`. Then `brew update`, and
     `brew trust nikitabobko/tap` if `brew trust --help` works (Homebrew 7
     won't upgrade a cask from an untrusted tap), then `brew upgrade --cask
     aerospace` **without restarting it**: the old one keeps running on the
     old config until step 4.
4. **Pull, then restart AeroSpace:** `git pull --ff-only`, then
   `killall borders; killall AeroSpace && open -a AeroSpace`. That loads the
   new config with the new version, and AeroSpace starts borders again with
   the new settings (a running one would be kept). Check
   `aerospace list-windows --all --count` is above 0; at 0 AeroSpace can't
   see windows, so Martin turns it on in System Settings → Privacy &
   Security → Accessibility, and you restart it again. Then put the windows
   back and tidy:
   ```bash
   while read -r id ws; do aerospace move-node-to-workspace --window-id "$id" "$ws"; done < ~/aerospace-layout.txt
   aerospace flatten-workspace-tree
   ```
5. **The installer, by Martin.** First `ls -ld ~/.claude`: if it's a
   symlink into the repo, Claude Code must be closed while it's fixed, so
   hand over: Martin quits Claude Code (every window), runs the installer,
   and starts you again with `claude --continue` in the dotfiles folder.
   Either way: run `./install_darwin.sh --dry-run`, show Martin what it
   would do, then ask him to run `./install_darwin.sh` in a terminal. It
   asks for his password, and ends with `scripts/macos-permissions.sh`, which
   walks him through the permissions and first starts.
   `scripts/macos-permissions.sh --check` shows you what's left.
6. **Versions, so they match the MacBook** (recommended; it upgrades
   everything, so ask): Martin runs `scripts/update.sh --follow-lockfiles` in
   a terminal. It brings Homebrew current and puts nvim's and yazi's plugins
   at the repo's lockfiles; never commit lockfile changes from this Mac. The
   MacBook is only as current as its last `update.sh`; the 2026-10-07 entry
   explains a Mac that's far behind.
7. **The remaining "On other machines" steps**, oldest first: the removals
   (`verify.sh` warns on AutoRaise's and Alacritty's leftovers; leave
   Alacritty's own to step 9), reloads, manual steps.
8. **Ask Martin before:** desktop settings (`scripts/macos-defaults.sh`,
   `scripts/finder-defaults.sh`, `--with-desktop`), and anything else that
   deletes data.
9. **At the end, by Martin: what would cut off your own session.** You run
   in a terminal, maybe in tmux. Hand him this list and stop:
   - tmux: `Ctrl+a r` (loads the new config with resurrect), `Ctrl+a
     Ctrl+s` (saves), then `tmux kill-server` and `t` for the new version;
   - on a Mac set up in September, Alacritty is the terminal you run in:
     once he works in Ghostty, `stow -D -t ~ alacritty` and
     `brew uninstall --cask alacritty`;
   - a restart or log-out, if an entry asked for one.
10. **What the repo doesn't carry** (below): ask Martin which he wants.
11. **Outside this repo:** clone `github.com/zrrbite/todo` to
    `~/Development/todo` and register its todo-brief hook ("Claude Code"
    below). Ask which other repos under `~/Development` he wants pulled.
12. **Done** is `scripts/verify.sh` exiting 0, run last: that run records
    the sync point (the installer's doesn't). Plus Martin confirming: tapping
    Caps Lock is Escape; `sudo -k; sudo true` in a tmux pane asks for a
    fingerprint; focus follows the mouse; `⌃⌥⇧V` opens clipboard history.
    Log the sync in the todo repo.

**What the MacBook has that the repo doesn't carry** (2026-10-20; a
snapshot, so ask):

- **Claude Code plugins**, all from `claude-plugins-official` (install with
  `/plugin` in Claude Code): superpowers, context7, and the language servers
  clangd-lsp, typescript-lsp, pyright-lsp, rust-analyzer-lsp, swift-lsp.
- **Claude Code's status line:** `~/.claude/statusline.sh`, outside the repo,
  set as `statusLine` in `~/.claude/settings.json`. Copy it over if wanted.
- **Homebrew installed by hand for projects** (`brew leaves` on the
  MacBook): among others actionlint, ast-grep, bazel, dotnet, doxygen,
  flyctl, gcc, graphviz, lua, mono, probe-rs-tools, protobuf, pyright,
  rbenv, yt-dlp; casks gcc-arm-embedded, ilspy, logitech-g-hub.
- Claude's memory notes (`~/.claude/projects/<project>/memory/`, per
  machine; the rules that matter are in CLAUDE.md), and per-machine choices
  such as the `remote` test host.

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

`hooks/todo-brief.py` (2026-10-08) shows the open items of `~/Development/todo/TODO.md`
at the start of every session: the sections that mention the repo you start in,
and a count of the rest. Register it the same way:

```json
"hooks": {
  "SessionStart": [
    { "hooks": [ { "type": "command", "command": "$HOME/.claude/hooks/todo-brief.py" } ] }
  ]
}
```

It needs `python3` and the todo repo cloned at `~/Development/todo` (or `TODO_FILE`
pointing at the list); without them it prints nothing.

## Undo

- Stow: `stow -D -t ~ <pkg>` removes that package's symlinks. Then restore the
  backed-up file.
- Windows: `.\stow_windows.ps1 -Delete <pkg>`, then rename
  `<target>.bak-<timestamp>` back.
- Installer backups: `~/.config-backup-YYYYMMDD-HHMMSS/` on macOS and Linux,
  `%USERPROFILE%\.config-backup-<timestamp>\` on Windows. The Windows backup is
  flattened by file name, so the Zebar and Windows Terminal `settings.json`
  files overwrite each other there.
