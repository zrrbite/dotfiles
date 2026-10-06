# Changelog

What changed in this repo and **what to do on each machine to catch up**,
newest first. Git history has the detail; this file says what matters when
syncing.

## How to sync a machine (for agents, and people)

1. **Find where this machine is.** `scripts/verify.sh` prints the commit the
   machine was last verified at (stored in `~/.local/state/dotfiles/applied`),
   and how far behind `master` that is. No record means it was set up before
   2026-10-05: treat every entry below as new.
2. **Read every entry newer than that.** Do its **On other machines** steps in
   order. "Do first" steps must happen *before* `git pull`.
3. **Finish with `scripts/verify.sh`.** When it passes, it records the current
   commit, so the next sync starts from here.

The full procedure, including Windows, is "Updating a machine that already has
it" in `doc/applying-the-setup.md`.

Each entry also lists what the repo **can't** do for you: per-machine state,
app settings outside stow, and manual installs.

---

## 2026-10-05: the big one

A day of work across the whole setup. It includes changes written between
July and September that reached `master` today (the lint/CI branch, PR #2).

### On other machines

**Do first, before `git pull`:**

1. **Save git identity to `~/.gitconfig.local`.** The shared
   `git/.gitconfig` no longer carries a name, email or credential helper; if
   `~/.gitconfig` is a symlink into this repo, pulling removes them. The
   snippet is under "Updating a machine" in `doc/applying-the-setup.md`.
2. **Repair what older installers wrote into the repo.** A macOS installer
   from before today stowed `fastfetch` *before* creating
   `~/.config/fastfetch`. So that directory became a symlink into the repo,
   and its `ln -sf` replaced the tracked `fastfetch/.config/fastfetch/config.jsonc`
   with a symlink. `~/.claude` can be folded the same way. Check
   `git -C ~/dotfiles status` and `ls -ld ~/.config/fastfetch ~/.claude`, and
   repair with the snippet in "Updating a machine", step 1b. A pull over a
   modified tracked file can fail.

Then:

1. **`git pull --ff-only`, then re-run the installer** for the OS
   (`./install_darwin.sh`, `./install_arch.sh` or `./install_debian.sh`). It's
   re-run safe and installs only what's missing. New today:
   - **macOS:** `ghostty`, `font-sketchybar-app-font`, `yazi`, `chafa`,
     `ffmpeg`, `poppler`, `sevenzip`, `tmux`; oh-my-zsh (a git clone).
   - **All OSes:** tmux-resurrect, cloned into `~/.tmux/plugins/`.
   - **New stow packages:** `ghostty`, `yazi` and `tmux` on macOS (tmux's
     config existed but wasn't on the macOS list); `yazi` on Arch.
   - The installer also creates `~/.config`, `~/.config/fastfetch` and
     `~/.claude` before stowing (see the Installers section below).
2. **`scripts/verify.sh`.** Fix any FAIL. When everything passes, it records
   this commit as the machine's sync point.
3. **Reload what's running:**
   - open a new shell (on Arch, WSL and Raspbian that's also what brings in
     the bash `t` command, since `~/.bashrc` links into the repo);
   - Ghostty: `⌘⇧,`;
   - `aerospace reload-config` and `sketchybar --reload`;
   - tmux: `Ctrl+a` `r`, then detach and reattach (needed for the colour and
     image settings).

**Optional, macOS, not done by the installer:**
- **Finder settings:** `scripts/finder-defaults.sh`. Also part of
  `install_darwin.sh --with-desktop`. `--undo` reverts.
- **Raycast**, on trial and not in the installer:
  1. `brew install --cask raycast`.
  2. In Raycast: Settings → Extensions → + → Add Script Directory →
     `scripts/raycast/`.
  3. Raycast's settings live in its own database, not in this repo.
- **Launcher and window-manager conflicts.** If the Mac has **Alfred**, it
  clashes with Raycast on ⌥ Space. If it has **Rectangle** or **Rectangle
  Pro**, it fights AeroSpace. On Martin's main Mac, Alfred was paused (quit,
  out of login items) and Rectangle Pro uninstalled. Those were machine
  changes, not repo changes, so repeat them by hand where relevant.

**Windows:**
- Save identity first, then `git pull`.
- `.\stow_windows.ps1 -DryRun <packages>`, then the real run. It now checks
  symlink rights first and restores a file if its link fails.
- A Windows clone made before `.gitattributes` existed may have CRLF files.
  Run `git rm --cached -r . && git reset --hard` once in the repo to
  re-check them out as LF. This rewrites the working tree, so commit or stash
  local changes first.

### What changed

**Git**
- Identity and credentials moved to `~/.gitconfig.local`, which the shared
  config includes last. `scripts/seed-gitconfig-local.sh` creates it from an
  existing `~/.gitconfig`; every installer runs it. (`7397a84`)
- `spawn`, `nuke` and `bdone` follow each repo's default branch (main or
  master), via a new `git default-branch` alias. (`2ba368c`)
- Hooks:
  - pre-push-ts runs only the npm scripts a repo defines (`acaf937`);
  - pre-push skips branch deletions (`042963d`);
  - pre-commit checks a repo's first commit and never passes on an error
    (`88e7c1f`);
  - pre-commit pins the clang-format binary (`4db22f0`).

**Installers and checks**
- **`scripts/verify.sh`:** an "is this machine applied?" check; exit 0
  means done. Its only write is the sync record in
  `~/.local/state/dotfiles/applied`. (`13253a8`, `535dece`)
- **`scripts/packages.sh`:** the single list of stow packages per OS.
- **Installers:**
  - never link app-state folders into the repo;
  - back up before deleting;
  - collect failures, run verify and exit 1 on any problem.
  (`13253a8`, `7883e94`)
- **Linux:** `install_debian.sh` was never executable (so WSL and the Pi
  couldn't install); Arch named three packages pacman doesn't have.
  (`35c6b39`, `8b0fed7`)
- **Windows:** `stow_windows.ps1` probes symlink rights, has `-DryRun`, and
  restores a file if its link fails; `.gitattributes` forces LF. (`442e79d`,
  `7883e94`)
- **Lint and CI:** `scripts/lint.sh` (shellcheck, stow, executable bits),
  run in CI. (`027c7a9`)
- **Installers:** tmux and node were added to the macOS and Arch package
  lists. node is there for nvim's TypeScript language server. (`f561c24`)

**Desktop (macOS)**
- **sketchybar:**
  - app icons per workspace;
  - empty workspaces hidden;
  - animated focus;
  - tinted pills on the right;
  - battery and clock icons restored;
  - Wi-Fi state taken from the IP, not the SSID;
  - front-app icon.
  (`cd4bc88`, `87e1626`, `3a19444`, `07d2414`)
- **AeroSpace:**
  - `alt-enter` opens Ghostty, `alt-shift-enter` Alacritty;
  - resize follows the container's orientation;
  - `alt-b` balances window sizes.
  (`fc93518`, `2c2da39`)
- **Borders:** 5pt and rounded. (`07d2414`)
- **Finder:** settings script. (`603fe7b`)

**Terminal**
- **Ghostty** added as the default terminal; Alacritty stays as the second.
  (`a6fb331`)
- **Alacritty:** no title bar. (`07d2414`)
- **Starship:** Nord prompt, a plain directory, a git pill. (`07d2414`,
  `f6256bc`)
- **macOS text-editing keys** in zsh, Ghostty and Alacritty, working inside
  tmux too: ⌘ ←/→ line start/end, ⌥ ←/→ words, ⌥⌫, ⌘⌫. (`0ec0241`)
- **tmux:**
  - `t` command, in zsh and, since `6497280`, in bash on Arch, WSL and
    Raspbian;
  - `Ctrl+a` `Tab` for the last session, `Ctrl+a` ⌘ ←/→ to cycle sessions;
  - 24-bit colour;
  - image passthrough;
  - tmux-resurrect.
  (`496c370`, `45514b4`, `f8ae3da`, `cc510f6`, `96708cd`, `6497280`)
  Reference and learning plan: `doc/tmux.md`.
- **yazi**, a terminal file manager (launch with `y`), and **chafa** for
  terminal images (`fimg`). (`a80e0da`)
- **Raycast script command:** `tmux session`, `t` from anywhere.
  (`88fbac8`)

**zsh and Claude Code**
- **zsh:** a `roast` alias for the coffee-roaster console. (`b0b0031`)
- **Claude Code:** `claude/.claude/CLAUDE.md` is now the working config, not
  the old persona file. The installer backs up a real `~/.claude/CLAUDE.md`
  and links the repo's. There is also a PreModelSwitch hook that blocks
  costly model switches; it does nothing until registered in
  `~/.claude/settings.json`. (`033da3d`, `6a2e19e`)

**Docs**
- `AGENTS.md` for non-Claude agents. (`705dc20`)
- `doc/applying-the-setup.md`: one path per machine (Martin's own, work,
  Windows), a definition of done, and how to update an existing machine.
  (`04568ff`, `157f901`)
- `doc/arch-hyprland-guide.md`, adopted from the old `main` branch. (`248f0c1`)
