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

## 2026-10-08: git merges only fast-forward; Claude's global rules ask for linear history

### On other machines
- **Every machine:** pull. `~/.gitconfig` links into the repo, so it takes
  effect at once. From then on, `git merge <branch>` refuses a branch that
  has diverged ("Not possible to fast-forward, aborting"). Rebase the branch
  first, or use `git merge --no-ff` when you do want a merge commit.
  `git pull` already rebased; that's unchanged.
- **Claude Code** (where the `claude` package is stowed; Windows links only
  the skills): the global `~/.claude/CLAUDE.md` has a new "History: linear,
  no merge commits" section, read by every new session after the pull.

### What changed
`e29a70a`:
- `git/.gitconfig`: `merge.ff = only`, next to the existing
  `pull.rebase = true`. Tested in scratch repos: a diverged merge is refused,
  fast-forwards and `--no-ff` still work, and `git pull` on a diverged branch
  still rebases.
- `claude/.claude/CLAUDE.md`: how to integrate without merge commits, which
  commits to fold together and which to keep, and a non-interactive rebase
  recipe (`--autosquash`, `GIT_SEQUENCE_EDITOR`, `--exec`), each step tested.

### What the repo can't do
- A repo's own `.git/config` can set `merge.ff` back.
- GitHub's merge button is per repo: turn off "Allow merge commits", or add
  a `required_linear_history` rule to a ruleset.

---

## 2026-10-07: macOS uses Homebrew's dotnet, not the old /usr/local/share/dotnet

### On other machines
- **macOS:** pull, then open a new terminal. `dotnet --version` should print Homebrew's version (10.x) if
  `brew list dotnet` has it. Without Homebrew's dotnet nothing changes: the old install is still on the PATH
  through `/etc/paths.d/dotnet`, just no longer in front.
- **Arch, Debian, Windows:** nothing.

### What changed
- `zsh/.config/zsh/darwin.zsh` (`f2333f6`): dropped `path_prepend "/usr/local/share/dotnet"`. That folder holds a
  2022 Microsoft install (SDK 6.0 and 7.0, both out of support), and putting it first hid Homebrew's dotnet 10
  after `brew upgrade` brought it in. The old SDKs cannot build .NET 10 projects (valheim-smith moved to
  `net10.0` today).

### What the repo can't do
The old Microsoft install is still on disk. Removing it is manual and needs sudo:
`sudo rm -rf /usr/local/share/dotnet /etc/paths.d/dotnet`. Only do that if nothing still needs the .NET 6 or 7
runtime. `~/Development/unity/pantheon` targets `net6.0`; it builds with SDK 10, with an out-of-support warning.

## 2026-10-07: macOS installer adds gh, cmake, ninja, tree, wget and Raycast; Homebrew catch-up

### On other machines
- **macOS:** pull, then `./install_darwin.sh`. It installs only what's
  missing: gh, cmake, ninja, tree, wget and Raycast. It also trusts the three
  third-party taps. That step matters on Homebrew 7, which refuses casks from
  an untrusted tap: AeroSpace won't install or upgrade, and
  `brew list --cask --versions` errors out. Then add `scripts/raycast/` in
  Raycast (Settings → Extensions → + → Add Script Directory).
- **macOS, if `brew outdated | wc -l` is large** (this Mac had 150, git from
  March 2023): `brew upgrade`, after saving `brew list --versions` somewhere.
  Watch for:
  - **AutoRaise and AeroSpace:** macOS ties their Accessibility permission to
    the binary, so upgrade them only when you can re-grant it straight after
    (System Settings → Privacy & Security → Accessibility).
  - **llvm** carries the clang-format and clang-tidy the git hooks use. Here
    it went 21 → 23; `clang-tidy --verify-config --config-file=clang/.clang-tidy`
    still passes.
  - **sketchybar and borders** keep running the old binary until restarted:
    `brew services restart sketchybar`, and restart borders with the
    arguments from `aerospace.toml`'s `after-startup-command`.
  - Casks that ask for your password (Docker Desktop, Logitech G HUB): run
    those upgrades yourself.
  - `brew untap homebrew/core homebrew/cask` frees about 1 GB of package
    lists Homebrew no longer reads (it uses its online API).
- **Arch, Debian, Windows:** nothing.

### What changed
- `install_darwin.sh` (and `doc/tools.md`): gh, cmake, ninja, tree and wget
  were on the main Mac but not in the installer, so a fresh Mac lacked them;
  `scripts/bootstrap-cpp-project.sh` needs cmake. Raycast stays after its
  trial and is now a cask in the installer.
- The installer's tap-trust comment now covers Homebrew 7's casks.

### What the repo can't do
- Raycast's settings and hotkey live in its own database. Alfred is still
  installed on the main Mac (paused), not removed by the repo.
- Package versions aren't pinned: each Mac is as current as its last
  `brew upgrade`.

---

## 2026-10-07: AeroSpace moves from ⌥ to ⌃⌥ (Control+Option)

### On other machines
- **macOS:** pull, then `aerospace reload-config` (the running AeroSpace keeps
  the old keys until then). Every shortcut is now **⌃⌥** plus the same key:
  `ctrl-alt-1`–`9` for workspaces, `ctrl-alt-h/j/k/l` to focus,
  `ctrl-alt-enter` for Ghostty, and so on. `scripts/verify.sh` fails until
  the running AeroSpace has the new keys.
- **Arch, Windows:** nothing. Hyprland (SUPER) and GlazeWM (alt) keep theirs.

### What changed
On the Danish layout Option types `[ ] { } | \` (⌥ 8, ⌥ 9, ⌥⇧ 8/9, ⌥ i,
⌥⇧ 7), and AeroSpace's bindings are global, so with plain alt those keys
switched workspaces or resized instead of typing, in every app. Measured from
the layout itself: those six were the only code symbols it took. ⌃⌥ plus a
key types nothing on a Mac. The letters are unchanged; docs, the Ghostty
comment and the installer's summary name the new keys.

---

## 2026-10-07: tmux `Ctrl+a v` and `Ctrl+a Enter` for Danish keyboards; window names in narrow windows

### On other machines
In tmux: `Ctrl+a` `r` to reload. Nothing else.

### What changed
- `Ctrl+a v` splits a pane side by side, like vim's `:vsplit`, next to the
  existing `Ctrl+a |`. On a Danish Mac layout `|` is Option+i, and AeroSpace
  takes alt-i for resizing, so `Ctrl+a |` did nothing there.
- The status bar lists every session only when the window is 120+ columns
  wide. In a narrower one the list crowded out the window names.
- `Ctrl+a Enter` enters copy mode, next to `Ctrl+a [`: on the Danish layout
  `[` is Option+8, which AeroSpace takes for workspace 8.

---

## 2026-10-06: zsh on Linux; the Linux bash files are gone

### On other machines
**Arch box, Pi, WSL. Do first, before `git pull`:**
1. **Rescue local lines from the old bash files.** On Linux `~/.bashrc` linked
   into the repo, so anything a tool appended to it (nvm, rustup, conda, uv)
   landed in `bash/.bashrc-arch`, `-wsl` or `-raspbian`, and the pull refuses
   to delete a changed file. Run `git -C ~/dotfiles status --short bash/`. For
   each modified file, copy the added lines (`git -C ~/dotfiles diff bash/`)
   into `~/.zshrc.local` in their zsh form, then
   `git -C ~/dotfiles checkout -- bash/`.
2. **If tmux is running, save and stop it:** prefix `Ctrl-s`, then
   `tmux kill-server`. A tmux server keeps the shell it started with, so one
   left running goes on opening bash panes. continuum restores the sessions on
   the next `t`, in zsh.

**Then run the installer straight after pulling.** The pull deletes the Linux
`bash/.bashrc-*` and `.bash_profile-*` files that `~/.bashrc` and
`~/.bash_profile` link to. Until the installer runs, a new terminal is bash
with no config, and on Arch logging out lands on the text console without
Hyprland (run the installer from there).
1. `git pull --ff-only`, then at once `./install_arch.sh` or
   `./install_debian.sh` (not `./reload.sh`, which doesn't install zsh). It
   installs zsh, its two plugins and oh-my-zsh, links `zsh` and `zsh-linux`,
   puts back the distro's own `~/.bashrc`, and makes zsh the login shell
   (`sudo chsh`).
2. Log out and back in. On Arch, Hyprland now starts from `~/.zprofile`.
3. `scripts/verify.sh`. It also warns if a tmux server still opens bash.

A key's passphrase is now asked in a terminal, not at the TTY login. Shell
history doesn't move over: zsh starts with an empty `~/.zsh_history`, so the
grey suggestions build up from scratch.

**macOS:** `stow -R -t ~ zsh`, then open a new terminal. A pull alone already
works; the re-stow adds the `~/.config/zsh` link. `ll`, `lt` and `la` are now
eza (they were oh-my-zsh's `ls -lh` / `ls -lAh`), and `fcpp`, `ftodo`, `fmd`
and `ffunc` are new. `~/.zprofile` is untouched.

**Windows:** nothing.

### What changed
- `zsh/.zshrc` is shared by macOS and Linux. OS specifics are in
  `zsh/.config/zsh/darwin.zsh` / `linux.zsh`; `~/.zshrc.local` holds one
  machine's lines.
- New Linux-only package `zsh-linux`: `.zprofile` with one ssh-agent per
  login and the TTY1 Hyprland start. Unlike `.bash_profile-arch` it doesn't
  exec a Hyprland that isn't installed. On Debian and Ubuntu, whose zsh skips
  `/etc/profile`, it runs `/etc/profile.d/*.sh` as bash logins do.
- `scripts/setup-zsh-linux.sh`, run by both Linux installers: oh-my-zsh,
  retiring the old bash links, Debian's `bat`/`fd` names, and `chsh` to a zsh
  path `/etc/shells` lists. (On Arch `command -v zsh` can answer
  `/usr/sbin/zsh`, which isn't listed.)
- `scripts/verify.sh` on Linux: FAIL if the login shell isn't zsh, isn't
  listed in `/etc/shells`, or a link to a removed bash file remains; WARN for
  a missing oh-my-zsh or plugin, or a tmux server still opening bash.
- `ls` is no longer eza on Linux, and listings no longer hide `CLAUDE.md`.
- Tested: the Mac against a before/after baseline (same PATH and functions,
  faster startup); `scripts/test-in-docker.sh` on ubuntu:24.04, debian:12 (an
  upgrade from the bash setup) and archlinux. Not yet on real Linux hardware:
  see the NUC checklist; the Pi and WSL on their next sync.
- New test scripts: `scripts/test-zsh.sh` (what a new zsh gets, any machine)
  and `scripts/test-in-docker.sh <image>` (a Linux installer end to end).
- Design and plan: `doc/specs/2026-10-06-zsh-on-linux-design.md`,
  `doc/plans/2026-10-06-zsh-on-linux.md`.

---

## 2026-10-06: Nord theme for bat and btop

### On other machines
- **macOS, Arch, Debian/WSL/Pi:** pull, then either re-run the installer,
  or do its two steps by hand:
  ```bash
  stow -t ~ bat
  scripts/seed-btop-config.sh
  ```
  `scripts/verify.sh` then checks `bat` like any other package.
- If stowing `bat` reports a conflict, that machine already has its own
  `~/.config/bat/config`: merge it into `bat/.config/bat/config` or move it
  aside.
- btop: the script only replaces btop's `Default` theme. A theme picked in
  btop's menu is kept, and the script says so.
- **Windows:** nothing; bat keeps its default theme there.

### What changed
- **bat:** a new `bat` package with `--theme="Nord"` (a theme bat ships
  with), matching delta. Stowed on macOS, Arch and Debian
  (`scripts/packages.sh`).
- **btop:** not stowed, because btop rewrites `btop.conf` on exit and would
  write into the repo through a link. The new
  `scripts/seed-btop-config.sh` sets `color_theme = "nord"` once and leaves
  the file to btop. All three installers run it, Arch after its config
  backup. Tested on all four starting states (none, `Default`, a picked
  theme, no theme line), plus a real btop run: it draws in Nord and keeps
  the setting when it rewrites its config.
- **On Martin's main Mac:** both applied.

---

## 2026-10-06: node 18 pin gone; nvim's TypeScript needs TypeScript 6

### On other machines
- **macOS:** open a new shell. If `node --version` still says 18, that Mac
  has a hand-installed `node@18` too: `brew uninstall node@18`.
- **macOS, TypeScript in nvim:** check
  `ls "$(npm root -g)/typescript/lib/tsserver.js"`. If it's missing, the
  global TypeScript is 7 and nvim's `ts_ls` fails with "Could not find a
  valid TypeScript installation". Fix with
  `npm install -g typescript-language-server typescript@6`, or re-run
  `./install_darwin.sh`, which now checks for it.
- **Linux, Windows:** nothing. node and `ts_ls` are macOS-only here.

### What changed
- `zsh/.zshrc` no longer puts `node@18` (end of life since April 2025)
  ahead of Homebrew's `node`. Only Martin's main Mac had that keg, so
  `node` was 18 there and 25 everywhere else. It's uninstalled there.
- TypeScript 7 became npm's `latest`. It's a Go port with no `tsserver`,
  and `typescript-language-server` (nvim's `ts_ls`) drives `tsserver`, so
  the installer's unpinned `typescript` gave a broken setup.
  `install_darwin.sh` now installs `typescript@6`, and reinstalls when the
  global TypeScript lacks `tsserver`. A project's own TypeScript still
  takes precedence. Moving nvim to TypeScript 7's built-in server
  (`tsc --lsp --stdio`) is left for when projects are on 7.
- Docs giving the install command now say `typescript@6`.
- **On Martin's main Mac:** the language server had never been installed,
  so TypeScript in nvim did nothing. It's installed now, and nvim attaches
  `ts_ls` and reports type errors.

---

## 2026-10-06: macOS wallpaper is the Arch logo, on the lock screen too

### On other machines
- **macOS:** the installer only sets the wallpaper with `--with-desktop`,
  which also overwrites the Dock and Finder settings. To change just the
  wallpaper:
  ```bash
  osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$HOME/Development/dotfiles/hypr/.local/share/wallpapers/arch-blue-lowlight.png\""
  ```
  (adjust the path if the repo lives elsewhere). The lock screen follows at
  once. With FileVault on, the screen after a restart is a separate copy:
  run `sudo diskutil apfs updatePreboot /`, or log out and back in.
- **Arch, Windows:** nothing. Arch already uses this image (hyprpaper);
  Windows keeps the skull.

### What changed
`install_darwin.sh --with-desktop` sets `arch-blue-lowlight.png` instead of
the skull, matching the Arch box's desktop. macOS has no separate lock-screen
or login-window picture, so the wallpaper is what they show.

**Not in the repo:** the wallpaper is a per-machine setting, so pulling
changes nothing until it's set. The lock-screen clock's font and weight
(System Settings → Wallpaper → Clock Appearance, new in Tahoe) are
settings-app only. Martin's main Mac: set 2026-10-06 (it was
`~/Downloads/melinoe_wallpaper.jpeg`).

---

## 2026-10-05 (night): yazi shows hidden files by default

### On other machines
Nothing to run: it applies the next time yazi starts (the config is linked).

### What changed
`show_hidden = true` in `yazi/.config/yazi/yazi.toml`, matching Finder
(`scripts/finder-defaults.sh`). `.` still toggles, for the current session
only.

---

## 2026-10-05 (night): Hyprland config fixes that apply now (0.56)

### On other machines
- **Arch:** pull, then `hyprctl reload` and restart hyprpaper
  (`pkill hyprpaper; hyprpaper &`), or just log out and back in on TTY1.
- Expect the wallpaper back, and no window-rule errors.

### What changed
- **Window rules:** converted to the `match:` syntax of 0.53+. The old
  `windowrulev2` / `windowrule = effect, class:` lines have been errors
  since 0.53, so the firefox→2, discord→3, suppress-maximize and XWayland
  no-focus rules weren't applying. Names checked against the hyprland-wiki
  page at `7a711bbee`, the last version before the Lua rewrite.
- **hyprpaper.conf:** uses the 0.8 `wallpaper { }` block syntax. The old
  `preload` / `wallpaper = ,path` lines make hyprpaper 0.8.1+ refuse to
  start, so there was no wallpaper. The path is now `~/`, not
  `/home/zrrbite`.
- **`.bash_profile-arch`:** starts Hyprland via `start-hyprland` (0.53+),
  the supported launcher with crash recovery, falling back to `Hyprland`.
- **Still to do:** the `hyprland.lua` migration (needed before 0.57) is
  being prepared on branch `hypr-lua`, for testing on the NUC.

---

## 2026-10-05 (night): doc/tools.md — what's installed, per OS

### On other machines
Nothing to run.

### What changed
`doc/tools.md` lists every tool by purpose, with a column per OS (macOS,
Arch, Debian/WSL/Pi, Windows), plus what the repo *doesn't* install
(Raycast, per-project `.envrc`). It was built from the installers' actual
package lists, which remain the source for exact names. `AGENTS.md` links it
first; `CLAUDE.md` requires updating it whenever an installer gains or loses
a package.

---

## 2026-10-05 (night): Arch guide lives in archinstall; Hyprland 0.57 warning

### On other machines
- Nothing to run.
- **Arch: watch for Hyprland 0.57.** It stops reading `hyprland.conf`,
  which is what `hypr/` still uses (Arch is on 0.56.2 as of today). Until
  the config is migrated to `hyprland.lua`, hold the upgrade or expect an
  unconfigured desktop.

### What changed
- `doc/arch-hyprland-guide.md` is now a pointer to the maintained guide in
  [archinstall](https://github.com/zrrbite/archinstall/blob/main/doc/arch-hyprland-guide.md).
  The copy here was the December version, adopted this morning, and had
  fallen ~360 lines behind. It's kept in git history (`248f0c1`).
- `doc/README.md` and `doc/applying-the-setup.md` point there, and the
  setup doc warns about 0.57.

---

## 2026-10-05 (night): Linux catches up — tp, y, direnv in bash; prefix f fixed

### On other machines
- **Arch / Debian / WSL / Pi:** pull, re-run the installer (adds `direnv`
  and stows the `direnv` package), and open a new shell.
- **tmux, everywhere:** `Ctrl+a` `r` to reload the fixed `f` binding.

### What changed
- **Fixed:** `Ctrl+a` `f` ran `zsh -ic tp`, which failed on Linux, where
  zsh isn't installed. It now runs `"$SHELL" -ic tp`, using your login
  shell.
- **bash** (`.bashrc-arch`, `-wsl`, `-raspbian`) gains `tp` (project
  picker), `y` (yazi that changes directory on quit) and the direnv hook,
  matching zsh. The hook is last, after starship, as direnv requires. `t`
  was ported earlier (`6497280`).
- **direnv** is installed by `install_arch.sh` and `install_debian.sh` and
  stowed on both (`scripts/packages.sh`).
- **Not ported:** zsh-autosuggestions and syntax highlighting. bash's
  equivalent (ble.sh) is heavier, so it's left out unless wanted.

---

## 2026-10-05 (night): direnv — per-project environments

### On other machines
- **macOS:** re-run the installer (installs `direnv`, stows the `direnv`
  package), then open a new shell.
- **Per project, not in this repo:** an `.envrc` lives in each project. On
  Martin's main Mac, `tilt-hydrometer-analysis`, `chess` and `llm-price-watch`
  each have one containing `use venv`, approved with `direnv allow`, and
  listed in that repo's `.git/info/exclude`, so it isn't committed. Repeat
  that on another machine if wanted: one line per project, then
  `direnv allow`.
- **Linux:** not wired up yet. zsh is only the macOS shell here; the bash
  configs would need `eval "$(direnv hook bash)"`.

### What changed
- **direnv:** `cd` into a folder with an approved `.envrc` loads it; leaving
  unloads it. The hook is in `zsh/.zshrc`.
- **`use venv [dir]`** (in `direnv/.config/direnv/direnvrc`) activates
  `./.venv`, or a given virtualenv. starship shows it in the prompt.
- **Quieter output:** `direnv.toml` hides the per-variable diff on each `cd`.
- `.direnv/` is added to the global gitignore.

---

## 2026-10-05 (night): yazi extras — git status, Markdown preview, yazi inside nvim

### On other machines
- **Re-run the installer.** macOS gets `glow`. Both macOS and Arch run
  `ya pkg install`, which fetches the yazi plugins pinned in
  `yazi/.config/yazi/package.toml`. They are gitignored, not committed.
- **nvim:** open it once. lazy.nvim installs yazi.nvim, pinned in
  `lazy-lock.json`. `:checkhealth yazi` should be all OK.
- `scripts/verify.sh` warns if the yazi plugins are missing.

### What changed
- **git.yazi:** a git status sign per file, set up in the new
  `yazi/.config/yazi/init.lua` plus fetchers in `yazi.toml`.
- **piper.yazi + glow:** Markdown is rendered in the preview pane.
- **yazi.nvim:** `Space` `-` (current file) and `Space` `_` (project root),
  alongside neo-tree. Its relative-path keymap is disabled: it needs GNU
  `grealpath`, which macOS lacks.

---

## 2026-10-05 (late): tmux status bar and auto-save

### On other machines
- **Re-run the installer.** It clones tmux-continuum (v3.1.0) into
  `~/.tmux/plugins/`.
- **In tmux:** `Ctrl+a` `r`. A running server loads auto-save but doesn't
  restore anything; restore happens on the next fresh start.

### What changed
- **Status bar:**
  - the session pill turns yellow while the prefix is pending;
  - COPY shows in copy mode;
  - the right side lists every session and the host name;
  - the date and time are gone (sketchybar has them).
- **tmux-continuum:** auto-saves every 15 minutes and restores on the next
  tmux start. It loads after resurrect, and after status-right is set,
  because it hooks its timer into status-right. It pauses itself while more
  than one tmux server runs.

---

## 2026-10-05 (evening): project picker, zsh suggestions and highlighting

### On other machines
- **macOS:** re-run `./install_darwin.sh`. It installs `zsh-autosuggestions`
  and `zsh-syntax-highlighting`. Then open a new shell.
- **tmux:** `Ctrl+a` `r` to load the new `f` binding.
- **Linux:** nothing. zsh is the macOS shell here; the plugins are loaded only
  where installed.

### What changed
- **`tp` / `Ctrl+a` `f`:** fuzzy-find a project folder under
  `~/Development` (or `$TP_ROOTS`) and go to its tmux session, created if
  needed. `tp` hands off to `t`, so session names match. In tmux it opens
  as a popup and replaces tmux's default find-window key (`Ctrl+a` `w` still
  finds windows).
- **zsh-autosuggestions:** a grey completion from history as you type; →
  or ⌘ → accepts it.
- **zsh-syntax-highlighting:** commands turn green when they exist, red when
  they don't. It's sourced last in `.zshrc`, after every key binding.

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
