# Claude on a remote machine over SSH — design

2026-10-08. Agreed with Martin in conversation, part by part. Status: design
approved; spec awaiting review, then an implementation plan.

## Goal

Claude runs on this Mac (online). The files it should work with live on
another MacBook: the offline work machine, reachable only over SSH. Claude
should be able to find, read and reason about those files, edit them, and run
the CMake builds and tests there, the same way it works on a local project.

**Done means:**

- `remote <host> …` gives Claude the safe operations on the remote: status,
  mount, unmount, `ls`, `cat`, `grep`, `find`, read-only `git`, `build`,
  `test`.
- The remote's files are mounted at `~/remote/<host>`, so Claude's own Read and
  Edit tools work on them.
- A skill teaches Claude when to use what, and is picked up without being
  asked for.
- Reading, read-only commands, builds and tests run without prompts; edits on
  the remote and every other remote command ask first.
- All of it is tested against a stand-in work Mac on this Mac, and documented
  for setting up the real one.

**Not in scope:** an online Linux or Windows machine (the script avoids
Mac-only tricks where that costs nothing, but only macOS is tested); git write
operations through `remote`; VS Code integration; installing anything on the
remote.

## Decisions

| Question | Decision | Why |
|---|---|---|
| Where does Claude run? | On this Mac, directly | devbox (Claude in a container) is a different scenario. |
| Where do the files live? | On the remote | They exist only on the work Mac. |
| What is the remote? | Another MacBook | SFTP is built in once Remote Login is on, so mounting works. |
| Where does this live? | The dotfiles | The skill is stowed like the others; the installer and `verify.sh` cover it. |
| Access to the remote's files | Mount it (sshfs) for reading and editing; run searches, builds and tests over SSH | The probe below: the mount makes Claude's tools work, but searching through it is about 100× slower. |
| How Claude's actions are limited | A `remote` command holding only safe operations, allowed without prompts; everything else is plain `ssh`, which prompts | Martin: "read and build freely; ask before edits". Allowing `ssh <host>` would allow any command; patterns over quoted command strings are fragile. |
| Alternatives rejected | Skill plus raw `ssh` (can't express the trust rule); an MCP server (a server to maintain, for what a script does) | |
| Test target | This Mac via `ssh localhost`, as a separate user | Exercises the Mac-specific parts (zsh over SSH, Homebrew PATH, privacy-protected folders). Not offline, but the tools only need SSH. |
| Mount implementation on macOS | FUSE-T and its sshfs (`macos-fuse-t/cask/fuse-t-sshfs`) | No kernel extension. macFUSE (`sshfs-mac`) needs one; Homebrew's `sshfs` formula needs Linux's libfuse. |

## What the probe established (2026-10-08)

Against a Docker stand-in (`fake-pi`, Debian arm64, no internet) mounted with
FUSE-T sshfs 2.9:

- Mounting takes under a second. Read and Edit work on the mounted files;
  edits land on the remote, and the next remote build picks them up.
- Searching through the mount is fine for a small tree (40 files: 0.5 s) and
  far too slow for a real one: 2,252 files took 35 s, cold or warm, with or
  without sshfs's caching options. The same search on the remote over SSH:
  0.26 s.
- Local C++ diagnostics on mounted files are wrong: they reported ten errors
  in a file that built cleanly on the remote, because the remote's
  `compile_commands.json` names its own paths and the Mac's headers stand in
  for the remote's.
- When the remote disappears, anything touching the mount hangs. When it
  returns, the mount recovers by itself within a second (`reconnect`).

## Part 1: the `remote` command

`remote/.local/bin/remote`, a new stow package, so it lands in
`~/.local/bin` (already on PATH).

```
remote <host> status                    reachable? mounted? mount healthy?
remote <host> mount                     mount the remote home at ~/remote/<host>
remote <host> unmount                   unmount, forcing it if the remote has gone away
remote <host> ls   <path>
remote <host> cat  <file> [first:last]  optionally only a range of lines
remote <host> grep <pattern> <path> [-i] [-w] [-l] [--include <glob>]
remote <host> find <path> [-name <glob>] [-type f|d]
remote <host> git  <path> status|diff|log|show|branch [args]
remote <host> build <dir> [--preset P | --build-dir D]
remote <host> test  <dir> [--preset P | --build-dir D]
```

- `<host>` is an `~/.ssh/config` alias: address, user, key and connection
  details live there, not in the script.
- Relative paths are from the remote home, and the mount is always the
  remote home, so `src/proj/main.cpp` from a search is
  `~/remote/<host>/src/proj/main.cpp` for Read and Edit. Absolute paths work
  for the read subcommands too, but only the home is mounted.
- Every SSH call uses `BatchMode=yes` and `ConnectTimeout=5`, so an absent
  host fails within seconds instead of hanging or prompting.
- Remote commands run under `/bin/zsh -c`, after a prelude that adds
  Homebrew's directories (`/opt/homebrew/bin`, `/usr/local/bin`) to PATH where
  they exist. Commands over SSH don't load the login shell's setup, so `cmake`
  would otherwise be missing; this avoids depending on the remote's shell
  config.
- Arguments are quoted for the remote shell, so a pattern or path can never be
  run as a command.
- `build` and `test`: with a `CMakePresets.json` in `<dir>`, use
  `cmake --build --preset P` and `ctest --preset P` (`P` defaults to the
  first entry of `cmake --list-presets=build` for `build`, and of
  `ctest --list-presets` for `test`);
  otherwise `cmake --build <dir>/<D>` and `ctest --test-dir <dir>/<D>`, `D`
  defaulting to `build`. Output is shown; the exit code is passed through.
- `status` checks the mount with a time limit, so a dead mount is reported
  ("mounted, not responding: `remote <host> unmount`") rather than hanging.
- `mount` uses `reconnect`, `ServerAliveInterval=15` and a volume name of
  `<host>`; it refuses if already mounted. `unmount` tries `umount`, then
  `diskutil unmount force`, each under a time limit.
- When the remote says "Operation not permitted", the error gets a hint: on a
  Mac remote that is the privacy protection of `~/Documents`, `~/Desktop` and
  `~/Downloads`, lifted by Remote Login's "Allow full disk access for remote
  users".

**Why it's safe to allow without prompts.** Every subcommand is read-only or a
build/test, which Martin chose to allow. Options that would run something are
not accepted:

- `grep` runs `grep -rnI` with only `-i`, `-w`, `-l` and `--include`
  passed through (no ripgrep, whose `--pre` runs a program).
- `find` accepts only `-name` and `-type`: no `-exec`, `-execdir`, `-delete`,
  `-ok`.
- `git` accepts only `status`, `diff`, `log`, `show` and `branch` (listing
  only: no `-d`, `-D`, `-m`, `-c`), and passes `--no-pager`. Options that
  could run an external program (`--ext-diff`, `--output`, `-c`) are
  refused.
- Anything not on these lists is refused with exit 2 and nothing is run on
  the remote.

There is no `run` and no free-form command. Running a built program, or
anything else, is plain `ssh <host> '…'`, which prompts.

## Part 2: the skill and the permissions

**`claude/.claude/skills/remote-machine/SKILL.md`**, stowed to
`~/.claude/skills`. Unlike the dotfiles' other skills (user-triggered,
`disable-model-invocation: true`), this one is model-invoked: its description
triggers on work involving another machine over SSH, `remote <host>`, or paths
under `~/remote/`. It says it is for macOS and Linux; on Windows (which links
the dotfiles' skills too) the `remote` command does not exist.

The rules, in the order they come up:

1. Start with `remote <host> status`. If the host doesn't answer, say so and
   stop: touching `~/remote/<host>` would hang. If it isn't mounted,
   `remote <host> mount`.
2. Find things on the remote: `remote grep`, `find`, `ls`. Never search
   through the mount with Claude's own search tools.
3. Read with the Read tool at `~/remote/<host>/…`.
4. Edit with Edit or Write on the mount, which prompts; never through
   `ssh … sed` or similar, which would sidestep that.
5. Build and test with `remote build` and `remote test`. The remote compiler
   is the truth: ignore local C++ diagnostics on mounted files.
6. Anything else on the remote (running a program, deleting, `git commit`) is
   plain `ssh <host> '…'`, with the reason given. Never install anything on
   the remote, and never give it internet access.
7. "Operation not permitted" under `~/Documents`, `~/Desktop` or `~/Downloads`
   on a Mac remote is privacy protection: name the Remote Login setting.
8. When done, `remote <host> unmount`, and always before the remote is
   unplugged or sleeps.

**Permissions**, in `~/.claude/settings.json` (applies in every project):

| Rule | Effect |
|---|---|
| allow `Bash(remote:*)` | every `remote` subcommand runs without a prompt |
| allow `Read(~/remote/**)` | reading the mounted files without a prompt (this also covers Claude's search tools, which the skill steers away from) |
| (none) | edits on the mount and raw `ssh` commands ask |

`settings.json` is per machine and not stowed. `install_darwin.sh` adds the
two rules with `jq`, only when missing, keeping everything else in the file.
`verify.sh` checks they are there.

## Part 3: setup, test host, tests, docs

### This Mac (and any other online Mac)

`install_darwin.sh`:
- trusts the `macos-fuse-t/cask` tap and installs the `fuse-t` and
  `macos-fuse-t/cask/fuse-t-sshfs` casks (both `.pkg`: they ask for the
  password);
- stows the new `remote` package (added to `PACKAGES_DARWIN` in
  `scripts/packages.sh`), after making sure `~/.local/bin` exists, so stow
  links the file rather than the folder;
- adds the two permission rules.

### The work Mac, once, by hand (a checklist in the doc)

1. System Settings → General → Sharing → Remote Login: on, "Allow access for"
   your user only. Tick "Allow full disk access for remote users" only if the
   source lives under `~/Documents`, `~/Desktop` or `~/Downloads`.
2. Put this Mac's public key in its `~/.ssh/authorized_keys`. It is offline,
   so carry the key over on a USB stick or by AirDrop.
3. Connect the two: a Thunderbolt cable makes a network by itself
   (`name.local`); a USB-C Ethernet adapter or a LAN without internet works
   too.
4. Add `Host workmac` to this Mac's `~/.ssh/config` (HostName, User,
   IdentityFile, `IdentitiesOnly yes`, `ConnectTimeout 5`).

### The test host on this Mac

`scripts/remote-test-host.sh up | down [--dry-run]`, run by Martin (it needs
the admin password).

`up`:
- creates a standard user `workmac-sim` with no shell config of its own, so
  the Homebrew PATH prelude is tested for real;
- installs `/etc/ssh/sshd_config.d/050-remote-test.conf`: `ListenAddress
  127.0.0.1` and `::1`, `AllowUsers workmac-sim`, `PasswordAuthentication no`,
  `KbdInteractiveAuthentication no`. Drop-ins load in name order with the
  first value winning, so it takes precedence over macOS's `100-macos.conf`;
- turns Remote Login on;
- creates a key pair for the test, installs the public half for
  `workmac-sim`, and adds `Host workmac-test` to `~/.ssh/config`;
- copies a small CMake project (from `scripts/practice-folder.sh`, with a
  `CMakePresets.json` added) into `workmac-sim`'s home, plus a file under its
  `~/Documents` for the privacy check.

`down` removes all of it and turns Remote Login off.

### Tests: `scripts/test-remote.sh` against `workmac-test`

1. `status` against an unreachable host (an alias to the non-routable
   `192.0.2.1`) fails within 6 s; against `workmac-test` it succeeds.
2. `mount`; `status` reports mounted and healthy; `unmount`.
3. Each read subcommand gives the expected output. A search pattern such as
   `x; touch /tmp/remote-pwned` creates nothing on the remote.
4. Refused: `grep --pre`, `find -exec`, `find -delete`, `git push`,
   `git commit`, `git reset`, `git branch -D`, `git diff --ext-diff`; each
   exits 2 and runs nothing.
5. `build` and `test` with presets and with a build folder: `cmake` is found
   despite the bare PATH; a failing build or test exits non-zero.
6. An edit through the mount shows in `remote cat`, and the next build sees
   it.
7. The remote disappears while mounted, simulated without sudo: mount
   through an alias that reaches `workmac-test` via a small local TCP relay
   started by the test, then stop the relay. `status` reports the dead mount
   within its time limit, and `unmount` cleans up.
8. A file under `~/Documents` gives the privacy hint, not only "Operation not
   permitted".
9. The installer's permission step adds both rules once; a second run adds
   nothing.

The skill: one scripted `claude -p` check that a fresh session asked about the
test host uses `remote` and the mount, plus a look by hand.

### Docs and bookkeeping

- `doc/remote-machine.md`: what it is, setting up both Macs, the command
  reference, troubleshooting (hangs, privacy protection, PATH), the test host.
- `doc/tools.md` row; README pointer; CLAUDE.md package list, including that
  this skill is model-invoked.
- `CHANGELOG.md` entry; `verify.sh` checks (FUSE-T sshfs installed, `remote`
  on PATH, the two rules present).

### Cleanup

- libbullet: remove the exercise files (`docs/OFFLINE-TARGET.md`,
  `scripts/remote.sh`, `scripts/fake-pi.sh`, `CLAUDE.md`). Keep the
  `.gitignore` line for `.claude/settings.local.json`. The `log.hpp` fix is
  already pushed (`3f2ae66`).
- The fake Pi: `fake-pi.sh down`, its two images, the `Host fake-pi` block in
  `~/.ssh/config` and the `~/.ssh/fake_pi` key.

## Risks

- **Hangs.** A mount whose remote vanished hangs whatever touches it,
  including Claude's tools. Mitigated by `status` first (skill rule 1), the
  time limits in `status` and `unmount`, and unmounting when done.
- **Remote Login on this Mac** opens SSH to the network unless restricted. The
  test host restricts it to localhost, one user and keys only, and `down`
  turns it off.
- **The permission boundary is the script.** A subcommand added later without
  the same care would be allowed without prompts. The refusal tests (4) pin
  the current behaviour.
