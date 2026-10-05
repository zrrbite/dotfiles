# Applying this setup to another machine

Written for an AI agent asked to set up a machine from this repo, especially a
**work machine** that already has its own git identity, credentials, policies
and repositories. People can follow it too, but it is written as instructions.

The repo's own `CLAUDE.md` describes how the repo is laid out and how to work
*on* it. This file covers putting it *onto* a machine safely. Read both.

## Rules before touching anything

1. **Do not run the full installers on a work machine.** `install_darwin.sh`
   and `install_windows.ps1` were written for Martin's own machines. They
   replace `~/.gitconfig` and `~/.zshrc` wholesale, deleting the originals after
   copying them to a backup directory. `install_windows.ps1` also changes the
   desktop wallpaper whether you asked or not. Apply packages one at a time
   instead, using the steps below.
2. **Never overwrite git identity or credentials.** `git/.gitconfig` hardcodes
   Martin's personal name and email and sets `credential.helper = store`, which
   keeps credentials in plaintext. On a work machine, a stowed `.gitconfig`
   would sign every commit with a personal email. See [Git](#git).
3. **Do not stow `claude/.claude/CLAUDE.md` at work.** It tells the agent to
   write tasks into Martin's private `zrrbite/todo` repo and push them. At work
   that would leak work details into a personal GitHub repo. The skills are
   fine to link on their own; see [Claude Code](#claude-code).
4. **Preview, then ask.** Run every stow as a dry run (`-n`) first, and show the
   human what it would link or replace before running it for real. Anything
   that needs admin rights, a system permission or a policy exception is the
   human's call. List it for them rather than trying to work around it.
5. **Back up by copying, not moving**, and report where the copies are.

## 1. Discover first (read-only)

Find out the following and report it before changing anything:

| Question | macOS | Windows |
|---|---|---|
| Is the user an admin? | `id -Gn \| grep -qw admin` | `whoami /groups` and look for Administrators |
| Is the machine managed (MDM)? | `profiles status -type enrollment` | Settings → Accounts → Access work or school |
| Package manager present? | `command -v brew` | `scoop --version`, `winget --version` |
| Existing git identity | `git config --global --show-origin --get-regexp '^user\.'` | same |
| Existing credential helper | `git config --global --show-origin --get-all credential.helper` | same |
| Existing global hooks | `git config --global --get core.hooksPath` | same |
| Do work repos use hook managers? | look for `.husky/`, `lefthook.yml`, `.pre-commit-config.yaml` | same |
| Configs that would be replaced | `ls -la ~/.zshrc ~/.gitconfig ~/.config/{nvim,starship.toml,alacritty,aerospace,sketchybar}` | `~\.gitconfig`, `%LOCALAPPDATA%\nvim`, `~\.glzr` |
| Proxy or blocked downloads? | `env \| grep -i proxy`; does `curl -I https://github.com` work? | same, in PowerShell |

If the machine is managed, expect that installing casks into `/Applications`,
granting Accessibility, or running Scoop's installer may be blocked. Say so up
front rather than finding out halfway.

## 2. Choose the packages

Each top-level directory is a package. How safe each one is on a work machine:

| Package | Platforms | Work-safe? | Notes |
|---|---|---|---|
| `nvim` | all | ✅ | Full IDE config. TypeScript needs `npm i -g typescript-language-server typescript`. |
| `starship` | all | ✅ | Prompt only. |
| `tmux` | mac, Linux | ✅ | `Ctrl+a` prefix. |
| `clang` | all | ✅ with care | `~/.clang-format`/`~/.clang-tidy` are only fallbacks. A repo's own config wins, but a work repo *without* one would pick up Allman/Unreal Engine style. |
| `alacritty` | mac (Linux optional) | ✅ | Terminal, Nord theme. |
| `zsh` | mac | ⚠️ ask | Replaces `~/.zshrc`. Merge any work-specific lines (proxy, SDK paths, corporate tooling) into it, or source a local file. |
| `fastfetch` | all | ✅ | On macOS, stow with `--ignore='config\.jsonc'` and link `config-darwin.jsonc` in its place (see `CLAUDE.md`). |
| `aerospace`, `sketchybar`, `autoraise` | mac | ✅ needs permissions | The desktop stack. See [macOS desktop](#macos-desktop). |
| `glazewm`, `zebar` | Windows | ✅ | The Windows desktop stack. Linked by `install_windows.ps1` only, not by `stow_windows.ps1`. |
| `git` | all | ❌ not as-is | Personal identity, plaintext credentials, global hooks. See [Git](#git). |
| `claude` | all | ⚠️ skills only | See [Claude Code](#claude-code). |
| `bash` | per-OS variants | ⚠️ ask | Linked by the installers to `~/.bashrc`; check for existing content first. |
| `hypr`, `foot`, `waybar`, `rofi`, `mako`, `wlogout`, `cava`, `gtk`, `mimeapps`, `discord` | Arch | n/a | Linux desktop only. |

`doc/`, `img/`, `scripts/`, `templates/`, `screenshots/` and `windowsterminal/`
are not packages. They carry a `.stow-local-ignore`, and must never be stowed
into `$HOME`.

## 3. Apply on macOS

```bash
git clone https://github.com/zrrbite/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles

# Preview what the installer would do, without doing it:
./install_darwin.sh --dry-run
```

Use the dry run as a **list of packages to install**, not as something to run.
Install the Homebrew formulae and casks the human agrees to by hand. The lists
are `BREW_PACKAGES` and `BREW_CASKS` in `install_darwin.sh`.

Then stow one package at a time, previewing each:

```bash
stow -n -v -t ~ nvim        # shows LINK lines, and any conflicts
stow -v -t ~ nvim           # only after the preview is clean and approved
```

A conflict means a real file is in the way. Copy it to a backup directory,
show the human what differs, and move it aside only once they agree. Never use
`--adopt`: it pulls the machine's file *into the repo* and overwrites the
tracked version.

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
- `--with-desktop` in the installer hides the menu bar and Dock and changes the
  wallpaper. Do not do that on a work machine unless asked.

Layout fact that breaks silently if changed: the bar is 32pt tall, and
`gaps.outer.top = 44` in `aerospace.toml` is that height plus a 12pt gap.
Keybindings deliberately mirror GlazeWM on Windows; see `doc/aerospace-macos.md`
and `doc/tiling-window-managers.md`.

## 4. Apply on Windows

Requires Windows 11, or Windows 10 with Developer Mode, for symlinks.

- `install_windows.ps1` installs Scoop (`irm get.scoop.sh | iex` with
  `RemoteSigned` for the current user), many Scoop packages and Windows
  Terminal. It then links **everything**, including `git`, and sets the
  wallpaper. Do **not** run it whole at work. Read its package list and install
  the agreed packages with `scoop install` by hand.
- `stow_windows.ps1 <pkg>` links one package. It knows only `git`, `clang`,
  `nvim`, `starship` and `bash`. Run `.\stow_windows.ps1 -List` to see the
  targets. It moves any existing file to `<target>.bak`, and it has no dry
  run, so check each target first.
- GlazeWM and Zebar are linked by hand, as the installer does it:
  `glazewm\.glzr\glazewm\config.yaml` → `~\.glzr\glazewm\config.yaml`, and
  `zebar\.glzr\zebar\settings.json` → `~\.glzr\zebar\settings.json`.
  Starting GlazeWM at login is not automated.
- Do not link `git` with `stow_windows.ps1` at work. See [Git](#git).

## Git

**Do not stow or link `git/.gitconfig` on a work machine.** It hardcodes the
personal identity, has no hook for a local override, and changes behaviour
work repos may depend on:

| Setting | Effect at work |
|---|---|
| `user.name`, `user.email` | Martin's **personal** address on work commits. |
| `credential.helper = store` | Credentials in plaintext in `~/.git-credentials`. |
| `core.hooksPath = ~/.git-hooks` | Global hooks run in **every** repo, and the repo's own `.git/hooks` stop running. Hook managers that set a repo-local `core.hooksPath` (husky, lefthook) still win. |
| `core.excludesFile` → `.gitignore-global` | Ignores `*.pdf` and `*.zip` in every repo, so such files silently never get added. |
| `diff.noprefix = true` | Diffs without `a/` and `b/` prefixes, which some patch tooling rejects. |
| `pull.rebase`, `rebase.autoStash`, `push.default = current` | Different defaults from stock git. Harmless, but surprising. |

To get the aliases and the delta pager without those risks, leave the work
`~/.gitconfig` in charge and include the repo file at the **top**, so the work
values below it win:

```ini
[include]
    path = ~/Development/dotfiles/git/.gitconfig

# Everything below overrides the include. Keep the work identity here.
[user]
    name = <work name>
    email = <work email>

# An empty helper clears the inherited `store`; Windows uses `manager`.
[credential]
    helper =
    helper = osxkeychain

# Point at a work ignore file, or drop this section to inherit *.pdf/*.zip.
[core]
    excludesFile = ~/.gitignore-work
```

Check the result with `git config --show-origin --get-regexp
'user\.|credential\.|core\.hooksPath|core\.excludesFile'`. Every identity and
credential line must come from the work file.

**Global hooks.** The include still sets `core.hooksPath = ~/.git-hooks`, and
the hooks enforce Martin's own rules everywhere:

- `pre-commit` blocks any staged file containing the do-not-commit marker. For
  C++ files, it blocks unless they are clang-formatted, and it errors if no
  clang-format is installed.
- `pre-commit-ts` runs `npm run format:check` when that script exists.
- `pre-push` runs clang-tidy on changed C++ files when `compile_commands.json`
  exists.
- `pre-push-ts` runs `npm run type-check` and `npm run lint` in any repo with
  `package.json` and `tsconfig.json`, **without checking those scripts exist**.
  It runs `npm run test:run` only when that script exists, and it fails when
  `node_modules` is missing. **This will
  block pushes in work TypeScript repos.**

Ask the human whether they want the hooks at work. If not, add `[core]
hooksPath = ~/.git-hooks-none` after the include and leave that directory
absent. Note that this also stops each repo's own `.git/hooks` from running. If
work repos rely on those, the human has to decide between the two.

## Claude Code

The `claude` package holds `CLAUDE.md` (personal working rules), `hooks/` and
13 skills under `skills/`. At work:

```bash
stow -n -v -t ~ --ignore='CLAUDE\.md' claude   # preview: skills + hooks only
```

On Windows, `install_windows.ps1` links only `skills`, which is the right shape.

`hooks/pre-model-switch-compact.py` does nothing until it is registered in
`~/.claude/settings.json`. That is a per-machine choice; the package does not
ship a `settings.json`.

## Verify

- `scripts/lint.sh` runs shellcheck over the repo's scripts and a stow dry run.
  It reports any package that would drop bare files into `$HOME`.
- `stow -n -v -t ~ <pkg>` previews a single package.
- macOS desktop: `sketchybar --reload`, `aerospace reload-config`. Then check
  that the bar shows workspace pills with app icons and that windows sit 12pt
  below it.
- Git: the `--show-origin` command above.
- Open `nvim` and run `:checkhealth`.

## Undo

- Stow: `stow -D -t ~ <pkg>` removes that package's symlinks. Then restore the
  backed-up file.
- Windows: `.\stow_windows.ps1 -Delete <pkg>`, then rename `<target>.bak` back.
- Installer backups (if a full installer was run anyway):
  `~/.config-backup-YYYYMMDD-HHMMSS/` on macOS and Linux, and
  `%USERPROFILE%\.config-backup-<timestamp>\` on Windows. The Windows backup is
  flattened by file name, so the Zebar and Windows Terminal `settings.json`
  files overwrite each other there.
