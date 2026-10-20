# Changelog

What changed in this repo and **what to do on each machine to catch up**,
newest first. Git history has the detail; this file says what matters when
syncing.

## How to sync a machine (for agents, and people)

1. **Find where this machine is.** `scripts/verify.sh` prints the commit the
   machine was last verified at (stored in `~/.local/state/dotfiles/applied`),
   and how far behind `master` that is. No record means it was set up before
   2026-10-05: treat every entry below as new.
2. **Read every entry newer than that.** Do their **On other machines** steps
   oldest first (the file is newest first). "Do first" steps must happen
   *before* `git pull`. For a Mac, "Handing a Mac to an agent" in
   `doc/applying-the-setup.md` gives the whole order.
3. **Finish with `scripts/verify.sh`.** When it passes, it records the current
   commit, so the next sync starts from here.

The full procedure, including Windows, is "Updating a machine that already has
it" in `doc/applying-the-setup.md`.

Each entry also lists what the repo **can't** do for you: per-machine state,
app settings outside stow, and manual installs.

---

## 2026-10-20: the second Mac's sync, rehearsed again

### On other machines
- **The second Mac:** the prompt is the same as in the entry below; the
  steps in "Handing a Mac to an agent" changed. Follow them as they are now.
- **Any machine:** nothing to run. The installers no longer record the sync
  point; the `scripts/verify.sh` run at the end of a sync does.

### What changed
- A second fresh agent rehearsed the sync against the fixed docs: about 70%,
  up from 45%. Fixed from its findings:
  - **`unfold.sh` leaves `~/.claude` alone while Claude Code runs**
    (`260bbde`): the agent doing the sync is Claude Code, and the installer
    unfolds `~/.claude`. If it's linked, the agent now hands over: Martin
    quits Claude Code, runs the installer, and resumes with
    `claude --continue`.
  - **The installers check without recording** (`2bae8c6`,
    `verify.sh --no-record`): an interrupted sync looked finished.
  - **Versions** (`141f411`): nothing brought a second Mac in line with the
    MacBook. `scripts/update.sh --follow-lockfiles` upgrades Homebrew and
    puts nvim's and yazi's plugins at the repo's lockfiles instead of moving
    them on; the handing steps recommend it.
  - **Order:** ask about Alfred and Docker Desktop before the installer,
    whose permissions walk starts Raycast and OrbStack; trust AeroSpace's
    tap before upgrading it (Homebrew 7); after the restart, check
    AeroSpace sees windows (Accessibility) before putting them back, with
    the loop reading the file step 3 wrote; restart borders too; reload
    tmux's config before saving it; Alacritty's unlink moves to Martin's
    end-of-session list.
  - **Wording:** the CHANGELOG's preamble said to do the steps "in order"
    in a newest-first file (now: oldest first); two Alfred lines still said
    "paused"; nvimdiff was set only by a fresh seed (the snippet sets it
    too now); "What done means" and the installer's step list overstated
    what verify checks and listed services it doesn't start.

---

## 2026-10-20: the second Mac's sync, rehearsed and fixed

### On other machines
- **The second Mac:** paste the prompt in "Handing a Mac to an agent"
  (`doc/applying-the-setup.md`) again; it changed. It now copes with a clone
  older than the docs, and the section has one order for the whole sync.
- **Alfred** (no entry said this before): Raycast replaced it on the
  MacBook on 2026-10-12, where it's uninstalled. On a Mac that has it, ask
  Martin, then quit it, take it out of the login items and move it to the
  Trash; keep `~/Library/Application Support/Alfred` (the Powerpack
  licence).
- **Any machine:** nothing to run; `scripts/verify.sh` reports the new
  checks below.

### What changed
- A fresh agent rehearsed the sync read-only, as the second Mac's agent
  would, and put its chance of success at about 45%. Fixed:
  - **The prompt sent it to files a September clone doesn't have**, which
    invited a pull before the pre-pull steps. The prompt and `AGENTS.md` now
    say to read them with `git show origin/master:<path>` first.
  - **An early pull lost the git identity for good** (`1597b7d`): the
    snippet then wrote empty values and `verify.sh` passed them. The
    snippet refuses empty values, `seed-gitconfig-local.sh` recovers the
    identity from the repo's history, and `verify.sh` fails on an empty
    one. On macOS the seed (when it creates the file) and the snippet set
    nvimdiff as the diff and merge tool.
  - **A folded `~/.claude` couldn't be fixed as documented** (`afbf623`):
    the recipe's `rm` failed after `stow -D`, and Claude's files stayed in
    the repo. `scripts/unfold.sh` makes such a folder real again and moves
    what apps wrote back out; the installers run it, and the macOS one
    restores the fastfetch config the September installer replaced with a
    link (it also re-damaged it before).
  - **Contradictions:** before or after the pull for AeroSpace (now: upgrade
    before, restart right after); "skip the steps for what was removed",
    read as skipping the removals; Alfred "paused" here, "uninstalled"
    elsewhere; tmux "not on the macOS list" (it was).
  - **Gaps** (`ee15c81`): nobody said the human runs the installer (an
    agent can't answer its password prompts; it now warns without a
    terminal); `verify.sh` didn't notice AutoRaise's and Alacritty's
    leftovers; nothing warned the agent off killing its own terminal or
    tmux; nothing listed what the MacBook has outside the repo (Claude
    Code's plugins and status line, project Homebrew packages); shellcheck,
    which `lint.sh` needs, wasn't installed.
- Tested: `scripts/test-unfold.sh` (12), `scripts/test-macos-permissions.sh`
  (28), identity recovery in scratch homes, `install_darwin.sh --dry-run`
  against a September-shaped clone and home, and `scripts/test-in-docker.sh
  debian:12 --upgrade-from 71bd12e`, where the installer log shows the old
  folded `~/.claude/skills` made real again.

---

## 2026-10-20: scripts/macos-permissions.sh walks you through the permissions

### On other machines
- **macOS:** after pulling, run `scripts/macos-permissions.sh` in a terminal,
  yourself (an agent can't click System Settings). Steps already done are
  passed over; on a Mac that's set up, expect Ghostty's (new on 2026-10-16)
  and the three only you can confirm. `scripts/verify.sh` now lists any
  that are missing.

### What changed
- What macOS lets only a person grant was spread over a doc section and
  `verify.sh`; the installer's closing message named two of the seven. Now
  one script holds the list: Accessibility for AeroSpace, Karabiner's driver
  and Input Monitoring, a Touch ID fingerprint, OrbStack's and Raycast's
  first starts, and AeroSpace controlling Ghostty. For each it says what
  it's for, opens the System Settings page or app, waits and re-checks.
- A script can check four: AeroSpace lists windows (it can only with
  Accessibility), Karabiner's driver is enabled, a fingerprint is enrolled,
  `docker` is OrbStack's. For Ghostty, the walk presses `⌃⌥Enter` itself and
  catches a refusal by a second Ghostty starting. The other three are your
  word, each with how to tell.
- `install_darwin.sh` runs it at the end when someone is at the terminal;
  `verify.sh` reports `--check` (its Karabiner and fingerprint checks moved
  there) and builds its "confirm by hand" list from it.
- Tests: `scripts/test-macos-permissions.sh` (27, fake commands, opens
  nothing; also under macOS's bash 3.2). Not yet walked for real.

---

## 2026-10-20: the installers no longer move `~/.claude/skills` or link it into the repo

### On other machines
- **Run `scripts/verify.sh` after pulling.** If it fails with
  "`~/.claude/skills` is a symlink into the repo" (likely on a Linux box
  installed before Claude Code was), Claude has been writing its synced
  skills into the dotfiles folder. Re-run the installer, or
  `scripts/unfold.sh ~/.claude/skills && stow -R -t ~ claude`: it makes the
  folder real again and moves Claude's files back out (entry above).
- **Before this, don't run `install_darwin.sh` or `install_arch.sh` on a
  machine with Claude Code:** they moved `~/.claude/skills` (synced skills,
  links from other repos) into the backup folder.

### What changed
- `install_darwin.sh` and `install_arch.sh` backed up and deleted
  `~/.claude/skills` whenever it was a real folder. After that, and in
  `install_debian.sh` whenever the folder didn't exist yet, stow linked the
  whole folder into the repo, where Claude Code then writes its synced
  skills. Found in a dry run on 2026-10-20; the real path had never run.
- All three now create `~/.claude/skills` before stowing (stow then links
  the skills one by one), undo an earlier link into the repo, and back up
  only a skill named like one of the repo's. `verify.sh` fails when the
  folder links into the repo.
- Tested: `install_darwin.sh --dry-run` in scratch home folders shaped like
  the MacBook's (10 checks) and against the real one; `scripts/test-in-docker.sh
  debian:12`, fresh and `--upgrade-from 71bd12e`. `install_arch.sh` has the
  same lines, not run.

---

## 2026-10-16: update.sh says how to restart tmux when it upgraded tmux

### On other machines
- **Nothing to do.** After `scripts/update.sh` upgrades tmux, follow its
  note when nothing in tmux needs to keep running.

### What changed
- A running tmux server keeps the version it started with, so after an
  upgrade the new tmux isn't in use until the server restarts. Restarting it
  ends what runs in the panes, so `update.sh` doesn't do it; when tmux moved
  and a server runs, it ends with the steps: `Ctrl+a Ctrl+s`,
  `tmux kill-server`, `t` (continuum restores the save). `doc/tools.md`'s
  versions table says the same.

---

## 2026-10-16: ⌃⌥Enter opens the window in the Ghostty that's running

### On other machines
- **macOS:** `./reload.sh` (or `git pull`, then `aerospace reload-config`).
  The first `⌃⌥Enter` while Ghostty runs asks to let AeroSpace control
  Ghostty: allow it. Refused, or a Ghostty older than 1.3 (no AppleScript),
  and the key starts a separate copy, as before.
- Copies of Ghostty already running stay until you quit them or restart.

### What changed
- `ctrl-alt-enter` ran `open -na Ghostty`, which starts a new copy of the app
  for every window (three were running on 2026-10-16). It now asks a running
  Ghostty for a new window over AppleScript, starting in `~` as a new copy
  did: one Dock icon, less memory, and the quick terminal stays possible
  (every copy would register its global key). Not running: `open -na`
  starts it. `doc/aerospace-macos.md` and the human-only steps in
  `doc/applying-the-setup.md` say so.
- Tested on the MacBook through `aerospace trigger-binding`: the window
  opened in the running Ghostty, no new process, in `~`.

---

## 2026-10-15: doc/handover-2026-10.md, an overview of the October improvements

### On other machines
- **Nothing to run.**

### What changed
- `doc/handover-2026-10.md` covers everything improved between 2026-10-05
  and 2026-10-13, by topic:
  - the keys worth knowing;
  - what each change gives and where it's documented;
  - what was removed or tried and dropped;
  - what each Mac needs by hand;
  - what's still open.

  It points at the entries below for the steps instead of repeating them. It's
  a snapshot and won't be kept up to date.
- The prompt in "Handing a Mac to an agent" (`doc/applying-the-setup.md`)
  has the agent read it first; `doc/README.md` lists it.

---

## 2026-10-13: Handing a Mac to an agent; verify.sh fails on an AeroSpace older than 0.21

### On other machines
- **macOS:** if `verify.sh` now fails on AeroSpace's version:
  `brew upgrade --cask aerospace`, then `killall AeroSpace && open -a
  AeroSpace`. The config uses keys only 0.21 knows, and an older AeroSpace
  drops every binding when it rejects the file. On a Mac that hasn't pulled
  yet, upgrade before pulling and restart right after ("Handing a Mac to an
  agent", steps 3 and 4, has the order).
- **Arch, Debian, Windows:** nothing.

### What changed
- `doc/applying-the-setup.md`, "Handing a Mac to an agent": the prompt to
  paste into Claude Code on another Mac, and for the agent the order, the
  steps to skip because a later entry undid them (AutoRaise, Alacritty,
  Docker Desktop), when to ask Martin, what's outside the repo and what
  "done" means. The update procedure warns about AeroSpace at its pull step;
  `AGENTS.md` points at the section.
- `verify.sh` FAILs when AeroSpace is older than 0.21 (tested with a fake
  0.19 app bundle, the real 0.21.3, and exactly 0.21.0).

---

## 2026-10-12: `remote`: the review's seven leftovers

### On other machines
- **macOS:** `git pull`. `./install_darwin.sh` adds `jq` (macOS 14 and
  older have none).
- **Arch, Debian, Windows:** nothing.

### What changed
- `remote`'s privacy hint fired whenever output contained "Operation not
  permitted", including a file that merely said so. It now reads only the
  remote's error stream (stdout and stderr still show as they arrive).
- `scripts/claude-remote-permissions.sh` left a temp file next to
  `settings.json` when `jq` failed; it's removed on any exit now.
- `scripts/remote-test-host.sh down` left the blank line `up` had written, one
  more per cycle; it removes it now (an up/down cycle restores the file
  exactly). Its functions can be sourced for tests.
- `scripts/test-remote.sh`'s build group left `hello.cpp` edited and the
  mount up when interrupted; it starts from the committed file and cleans up
  on Ctrl+C or a kill.
- `jq` is in the macOS installer; the skill says "macOS only" (it said Linux
  too); `REMOTE_SSH_CONFIG` is explained where it's used.
- `scripts/test-remote.sh`: 97 checks, all pass.

---

## 2026-10-12: scripts/update.sh, the upgrade checklist as one command

### On other machines
- **Nothing to do.** On a Mac, `scripts/update.sh --dry-run` shows what's
  outdated, `scripts/update.sh` upgrades. Run it in a terminal yourself:
  `.pkg` casks ask for the password.

### What changed
- `scripts/update.sh` (macOS) follows `doc/tools.md`'s checklist: records
  versions before and after in `~/.local/state/dotfiles/`, saves the
  AeroSpace layout, `brew upgrade`, restarts AeroSpace if it was upgraded and
  restores the windows, reloads sketchybar, updates nvim's and yazi's plugins,
  lists what moved (flagging the tools in the versions table), reports the
  plugin lockfiles to commit, and runs `verify.sh`. It leaves npm's globals
  (TypeScript stays on 6) and the pinned tmux plugins alone.
- Tested: `--dry-run`, the version diff and the layout restore. A full run
  wasn't made: it's Martin's to start.

---

## 2026-10-12: verify.sh warns when more than one tmux server runs

### On other machines
- **Nothing to do.** If `scripts/verify.sh` warns, stop the extra server it
  names: `tmux -L <name> kill-server`.

### What changed
- tmux-continuum stops auto-saving while a second tmux server runs (a test
  server left behind did it on 2026-10-07), and nothing said so.
  `verify.sh` now counts the servers that answer on their sockets (old dead
  sockets don't count) and warns, naming them. `doc/tmux.md` points at it.

---

## 2026-10-12: `remote <host> unmount` removes the `._` files the mount left

### On other machines
- **macOS:** `git pull`; nothing else (`remote` is linked from the repo).

### What changed
- Every file written through the sshfs mount got a `._` partner on the
  remote (AppleDouble: the remote end can't store the extended attributes
  macOS puts on new files). On the work Mac they'd have littered every repo
  Claude edited. FUSE-T's sshfs can't prevent it: `noappledouble` is
  accepted and ignored, and it rejects FUSE-T's `backend=` option.
- So `mount` leaves a marker on the remote, and `unmount` removes the `._`
  files newer than it whose partner file exists; other `._` files stay.
  `scripts/test-remote.sh` checks both (95 checks, all pass).
- `doc/remote-machine.md` and the `remote-machine` skill say so.

---

## 2026-10-12: AeroSpace's own focus-follows-mouse replaces AutoRaise

### On other machines
- **macOS. Do first, before `git pull`:** upgrade AeroSpace to 0.21 (the
  setting is new there; see the config-version entry below, and "Handing a
  Mac to an agent" for the order). Then:
  1. `brew services stop dimentium/autoraise/autoraise`
  2. `git pull`, then `rm ~/.config/AutoRaise` (the `autoraise` package is
     gone, so that link now points nowhere; `rm` removes only the link).
  3. `brew uninstall autoraise && brew untap dimentium/autoraise`
  4. `aerospace reload-config`, and check focus follows the mouse.
  5. Optional: remove AutoRaise from System Settings → Privacy & Security →
     Accessibility ("−").
  `scripts/verify.sh` warns while AutoRaise still runs: two
  focus-follows-mouse implementations fight over focus.
- **Arch, Debian, Windows:** nothing.

### What changed
- `aerospace.toml`: `focus-follows-mouse.enabled = true`. Tried on Martin's
  MacBook with AutoRaise stopped: focus follows, keyboard focus stays put
  (the `on-focus-changed` warp is kept), floating windows and popups behave.
  Lost: holding Control no longer pauses it; there's no delay to tune.
- AutoRaise is gone: the `autoraise` stow package, its formula and tap in
  `install_darwin.sh`, the service start, and the installer's Accessibility
  step for it. One app, one service and one Accessibility re-grant per
  upgrade fewer.
- `verify.sh`: the "AutoRaise service is started" FAIL became a WARN when
  AutoRaise still runs.
- README, CLAUDE.md, `doc/aerospace-macos.md`, `doc/applying-the-setup.md`
  and `doc/tools.md` (incl. its versions table and upgrade checklist) updated.

---

## 2026-10-12: AeroSpace config-version 2 (AeroSpace 0.21)

### On other machines
- **macOS, after upgrading AeroSpace to 0.21:** pull and
  `aerospace reload-config`. The config is written for 0.21 and wasn't
  tried on 0.20, so upgrade first (`brew upgrade --cask aerospace`), and
  restart it once the new config is pulled ("Handing a Mac to an agent",
  steps 3 and 4).
- **Arch, Debian, Windows:** nothing.

### What changed
- `aerospace.toml` declares `config-version = 2` and lists workspaces 1-9
  in `persistent-workspaces`. 0.21 warned on every reload that version 1 is
  outdated; version 2 no longer infers persistent workspaces from the key
  bindings, so they're listed to keep all nine (and sketchybar's pills).
- AeroSpace 0.21 has its own `focus-follows-mouse.enabled`. The docs said it
  had none; they now say "before 0.21". AutoRaise stays until the built-in
  one is tried.

---

## 2026-10-12: Alacritty dropped from macOS (Ghostty won the trial); lazygit kept

### On other machines
- **macOS:** pull, then `stow -D -t ~ alacritty` (removes the
  `~/.config/alacritty` link), `brew uninstall --cask alacritty`, and
  `aerospace reload-config` (`ctrl-alt-shift-enter` is gone).
- **Arch:** nothing. The `alacritty` package stays there, config only; foot
  is the terminal.
- **Debian, Windows:** nothing.

### What changed
- Alacritty is out of `install_darwin.sh` (cask, quarantine step, backup
  list), `PACKAGES_DARWIN` and AeroSpace's `ctrl-alt-shift-enter`. Ghostty
  is the macOS terminal. The `alacritty/` package stays for Arch.
- lazygit stays, no longer "on trial": Martin uses it mostly to look around
  a repo. Still macOS-only.
- CLAUDE.md, README, `doc/tools.md`, `doc/aerospace-macos.md`,
  `doc/applying-the-setup.md`, `doc/tmux.md` and `doc/lazygit.md` say so.

---

## 2026-10-12: Versions and upgrading (doc/tools.md); verify.sh finds dangling zsh completions

### On other machines
- **Nothing to do.** `scripts/verify.sh` now warns when Homebrew's zsh
  completion folder holds links to something removed; if it does, run the
  `rm` lines it prints. (Removing Docker Desktop left
  `/opt/homebrew/share/zsh/site-functions/_docker_compose`, and every new
  shell printed a `compinit` error.)

### What changed
- `doc/tools.md`, "Versions and upgrading": the version each config was last
  checked against, what to re-check after a big upgrade (AeroSpace needs a
  restart, AutoRaise may lose Accessibility, yazi renames keys, clang-format
  reformats, TypeScript stays on 6, Hyprland 0.57), and an upgrade checklist
  for a Mac.
- `scripts/verify.sh`: the dangling-completion check (macOS).

---

## 2026-10-12: C++ projects get CMake presets and ccache; the bootstrap script works on macOS again

### On other machines
- **macOS:** `brew install ccache`, or re-run `./install_darwin.sh`. Nothing
  else: existing projects are untouched, new ones get the presets.
- **Arch, Debian, Windows:** nothing. Their installers have no cmake or ninja
  either, so ccache alone would do nothing there.

### What changed
- `templates/cpp-project/`: a `CMakePresets.json` (`debug` into `build/`,
  `release`, `asan` with AddressSanitizer and UBSan); its `CMakeLists.txt`
  uses ccache when installed, and a preset's configure links
  `./compile_commands.json` to its build (the manual `ln -s` step is gone).
  The project `CLAUDE.md` template shows the preset commands.
- `scripts/bootstrap-cpp-project.sh` **failed on macOS** at its first `sed -i`
  (GNU syntax), and its header guard needed bash 4 and broke on a hyphenated
  name. It now writes names directly, makes `my-demo` → `MY_DEMO_H`,
  clang-formats the generated files so the first commit passes the hook, and
  prints the preset commands.
- `ccache` in `install_darwin.sh`. The same setup went into bullet-ble first
  (its `50a8b27`): a from-scratch rebuild went from 17 s to 3 s.

---

## 2026-10-12: OrbStack replaces Docker Desktop (same docker commands)

### On other machines
- **macOS:** `./install_darwin.sh` (or `brew install --cask orbstack`), then
  open OrbStack once: allow its helper (password; it links
  `/usr/local/bin/docker`), and it adds a line to `~/.zprofile`, a real file,
  not the repo. Migrating from Docker Desktop is optional: images can be
  pulled or rebuilt (devbox: its own build). Check: `docker context show`
  says `orbstack`, `scripts/test-in-docker.sh debian:12` passes.
- **Then, when you're sure:** quit Docker Desktop and remove it (done on
  Martin's MacBook 2026-10-12):
  1. `brew uninstall --cask docker-desktop`. **It also deletes
     `/usr/local/bin/docker` and `docker-credential-osxkeychain`, which
     OrbStack had taken over.** Quit and reopen OrbStack; it puts them back.
     Don't add `--zap`: it trashes `~/.docker`, where OrbStack's context is.
  2. `sudo find /usr/local/bin -lname '/Applications/Docker.app/*' -print
     -delete` removes links left pointing into the deleted app.
  3. `rm -rf ~/Library/Containers/com.docker.docker` (its data, 14 GB here;
     macOS keeps an empty folder with one protected file, which is harmless).
     Not before you're sure: it holds everything Docker Desktop had.
  4. `scripts/verify.sh` names a zsh completion the uninstall left dangling
     (`_docker_compose`, which makes new shells print a compinit error);
     `rm` it.
- **Arch, Debian, Windows:** nothing.

### What changed
- `orbstack` cask in `install_darwin.sh`; row in `doc/tools.md`.
- `scripts/test-in-docker.sh`: OrbStack's `docker exec` runs with umask 0000
  (Docker Desktop's had 022), which made the test's sudoers file world
  writable; it sets 022 now. devbox is unaffected (`docker compose run`).

### What the repo can't do
- OrbStack is free for personal use only; a work Mac needs a licence, or
  keep Docker Desktop there.

---

## 2026-10-12: git: upstream on first push, the diff in the commit editor, version-sorted tags

### On other machines
- **Every machine with the stowed `~/.gitconfig`:** `git pull`; nothing else.
  The settings apply at once.

### What changed
`git/.gitconfig`: `push.autoSetupRemote` (a new branch's first push sets its
upstream), `commit.verbose` (the editor shows the diff), `tag.sort =
version:refname`. Two settings are written down as deliberately left out:
`rebase.updateRefs` (it would move the `backup/<branch>` the history rules
make before a rebase) and `core.fsmonitor`/`core.untrackedCache` (only worth
it in big repos, and they warn on every git command inside the `~/remote`
sshfs mounts).

---

## 2026-10-08: Clipboard history on ⌃⌥⇧V, lazygit on trial (`Ctrl+a g` in tmux, `Space gg` in nvim, `doc/lazygit.md`)

### On other machines
- **macOS:** pull, then `aerospace reload-config` for the key. The first
  press asks Raycast to allow the link; tick "always". `brew install
  lazygit`, or re-run `./install_darwin.sh`, which installs it.
- **Every machine with tmux:** `Ctrl+a` `r` in a running tmux picks up
  `Ctrl+a` `g`. Without lazygit (Arch and Debian for now) it says so.
- **Windows:** nothing. (Arch has had `Super+Shift+V`.)

### What changed
- `ctrl-alt-shift-v` in `aerospace.toml` opens Raycast's Clipboard History
  through its deeplink, so the key is in the repo, not in Raycast's
  settings (`doc/aerospace-macos.md`).
- lazygit in `install_darwin.sh`, on trial; no config, its defaults use the
  terminal's Nord colours. `Ctrl+a` `g` opens it in a tmux popup for the
  current pane's folder (`doc/tmux.md`), `Space gg` in nvim for the current
  file's repo (a floating terminal, no plugin; Esc goes to lazygit). Guide
  and practice steps: `doc/lazygit.md`.

### What the repo can't do
- Raycast's clipboard settings (how long it keeps history, which apps it
  ignores) live in Raycast.

---

## 2026-10-08: Caps Lock as Escape/Control, Touch ID for sudo, app placement, a RESIZE pill, macOS settings

### On other machines
- **macOS:** pull, then `./install_darwin.sh`. It installs Karabiner-Elements
  (a `.pkg`: asks for the password) and pam-reattach, stows the new
  `karabiner` package (an existing `~/.config/karabiner` is moved to the
  backup folder first), and runs `scripts/touch-id-sudo.sh` (asks for the
  password once; refuses if `/etc/pam.d/sudo_local` exists and it didn't
  write it, so merge that by hand).
- **Then, by hand:**
  - Open Karabiner-Elements once and allow what it asks for: its driver
    (System Settings → General → Login Items & Extensions → Driver
    Extensions) and Input Monitoring. Pick ISO if it asks for the keyboard
    type. If it rewrote `karabiner/.config/karabiner/karabiner.json`, commit
    that or `git checkout` it.
  - `aerospace reload-config` and `sketchybar --reload`: the placement rules
    and the RESIZE pill.
  - `scripts/macos-defaults.sh` (the installer runs it only with
    `--with-desktop`; `verify.sh` warns until it's applied). Quit and reopen
    apps, or log out and in, for the text settings.
  - If Caps Lock switched between input sources, use the 🌐 key now.
- **Arch, Debian, Windows:** nothing.

### What changed
`8324281`..this entry's commit:
- `karabiner` package: Caps Lock is Escape when tapped, Control when held.
  The whole `~/.config/karabiner` folder links to the repo (Karabiner
  replaces the file when it saves); `automatic_backups/` is ignored.
- `scripts/touch-id-sudo.sh`: Touch ID for sudo, also inside tmux, in
  `/etc/pam.d/sudo_local` (survives macOS updates). `--check`, `--undo`;
  run `--undo` before uninstalling pam-reattach.
- AeroSpace: Chrome opens on workspace 2, chat apps on 3, fixed-size
  windows float (`doc/aerospace-macos.md`, "Where apps open"); a yellow
  RESIZE pill in sketchybar while resize mode is on.
- `scripts/macos-defaults.sh`: the installer's Dock and menu bar settings
  moved here, plus Mission Control grouped by app and no click-to-reveal
  desktop (AeroSpace's guide), ctrl+cmd-drag for any window, no smart
  quotes, dashes or autocorrect, and held keys repeat. `--check`, `--undo`.
- `verify.sh` checks all of it; the installer's closing summary shows the
  ctrl-alt keys (it still said alt).

### What the repo can't do
- Karabiner's driver and Input Monitoring permissions, and the password for
  Touch ID's file, are yours to give.
- Karabiner's settings window writes into the repo's `karabiner.json`;
  review those changes like any other.
- On Martin's MacBook the Dock's hide speed was 0.5, by hand; the script
  sets the repo's 0.3.

---

## 2026-10-08: Claude works on a remote machine over SSH (`remote`, a mount, a skill)

### On other machines
- **macOS:** pull, then `./install_darwin.sh`. It installs FUSE-T and its
  sshfs (two `.pkg` installers: they ask for your password), stows the new
  `remote` package (`~/.local/bin/remote`), and adds two rules to
  `~/.claude/settings.json` (`Bash(remote:*)`, `Read(~/remote/**)`).
  `scripts/verify.sh` checks all three. A new skill, `remote-machine`, arrives
  with the `claude` package.
- **To use it with the work Mac:** the one-time setup in
  `doc/remote-machine.md` (Remote Login, your key, a cable, an ssh alias).
- **Arch, Debian, Windows:** nothing. (Windows links the new skill too; it
  says it is for macOS and Linux.)

### What changed
`33c4863`..this entry's commit:
- `remote` command (`remote/.local/bin/remote`): status, mount, unmount, ls,
  cat, grep, find, read-only git, build, test. Every subcommand is read-only
  or a build/test, and options that could run a program or write are refused,
  which is why Claude may run it without asking.
- `remote-machine` skill (model-invoked): when to use the mount, when to
  search on the remote, what asks first.
- `scripts/claude-remote-permissions.sh`, `scripts/remote-test-host.sh` (a
  stand-in work Mac on this Mac: user `workmac-sim`, SSH only from this Mac),
  `scripts/test-remote.sh` (end-to-end tests against it).
- Spec `doc/specs/2026-10-08-remote-machine-design.md`; plan
  `doc/plans/2026-10-08-remote-machine.md`; guide `doc/remote-machine.md`.

### What the repo can't do
- The work Mac's side (Remote Login, its authorized key, the cable) is set up
  by hand, once.
- This Mac's test host (`scripts/remote-test-host.sh up`) is optional and per
  machine; `down` removes it and turns Remote Login off.

---

## 2026-10-08: Claude Code sees the todo list at session start

### On other machines
- **Every machine where Claude Code runs (macOS, Arch, Debian):** pull. `~/.claude/hooks` is this repo's, so
  the new hook is already there. Then register it in that machine's `~/.claude/settings.json`; the snippet is
  in `doc/applying-the-setup.md` ("todo-brief"). It needs `python3` and `~/Development/todo` cloned; without
  them it prints nothing. **Done on this Mac.**

### What changed
- `claude/.claude/hooks/todo-brief.py`: a SessionStart hook. It prints the `TODO.md` sections that mention the
  repo the session starts in (open items only) and one line counting the rest; outside a repo, only the count.
  It fails open. Martin: "I need to remember to tell you to call up this todo once in a while". Now he doesn't.
- `claude/.claude/CLAUDE.md`: says the brief is there, and to raise what it shows when it matters.
- `doc/applying-the-setup.md`: how to register it.

### What the repo can't do
Register the hook: `settings.json` is per machine, as for the PreModelSwitch hook.

---

## 2026-10-08: nvim finder keys, and the tutorial's Level 8 (finding your way around a codebase)

### On other machines
- **Every machine with this nvim config (macOS, Arch, Debian, Windows):** pull, then restart nvim. The keys load
  at startup; nothing to install (they use telescope and ripgrep, already in the installers).

### What changed
- `nvim/.config/nvim/lua/plugins/init.lua` (`30931da`): `Space f c` greps the word under the cursor, `Space f r`
  reopens the last search, `Space f o` lists recently opened files, `Space /` fuzzy-searches this file.
- `doc/nvim-tutorial.md`: Level 8, finding your way around a codebase. It covers files, project grep, symbols,
  definitions and references through the quickfix list (`]q`/`[q`), the picker's own keys, changing something
  everywhere (`Space r n`, `:cdo`), and diagnostics. Checked against this config and Neovim 0.12.5.
  `doc/practice.md`'s cheat sheet and drill N1 point to it.

### What the repo can't do
Nothing new.

---

## 2026-10-08: yazi bookmarks, Far-style Tab between tabs, copy and sync between yazi windows

### On other machines
- **macOS, Arch:** pull, then quit and restart every running yazi. The yazi
  config folder links into the repo, so the new `keymap.toml` needs no
  re-stow. New keys: `g D` (~/Development), `g .` (the dotfiles, wherever
  they're cloned), `g T` (~/Development/todo; missing on most machines, and
  then it does nothing), `Tab` flips between tabs, and `i` shows a file's
  details (it was `Tab`). A `y` in one yazi and a `p` in another now works,
  and `g s` sends the folder you're in to your other yazi windows.
- **Debian, Windows:** nothing (no yazi there).

### What changed
- `yazi/.config/yazi/keymap.toml` (new): additions to the 26.9 preset only.
  `g .` finds the repo from where `~/.zshrc` links, since it's cloned to
  `~/Development/dotfiles` on the Mac but `~/dotfiles` elsewhere.
- `init.lua`: the built-in session plugin with `sync_yanked = true`, and a
  listener for `g s`, which broadcasts the folder (`ya pub-to 0 sync-cd`).
- Tested by driving two yazi instances in a throwaway tmux server: every
  bookmark, `Tab` and `i`, a file yanked in one and pasted in the other, and
  `g s` both ways, including a folder name with a space.
- `doc/yazi.md`, README and CLAUDE.md list the new keys.

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
- Raycast's settings and hotkey live in its own database. Alfred was still
  installed on the main Mac then (paused); it was uninstalled on 2026-10-12
  (see 2026-10-20, "the second Mac's sync").
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
  osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$PWD/hypr/.local/share/wallpapers/arch-blue-lowlight.png\""
  ```
  (run it from the dotfiles folder). The lock screen follows at
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
   - **New stow packages:** `ghostty` and `yazi` on macOS (`tmux` was
     already stowed there); `yazi` on Arch.
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
  out of login items; uninstalled later, on 2026-10-12) and Rectangle Pro
  uninstalled. Those were machine changes, not repo changes, so repeat them
  by hand where relevant.

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
