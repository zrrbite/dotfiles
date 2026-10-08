# Claude on a remote machine

Claude runs on this Mac; the files it should work with live on another Mac
(the offline work machine) that it reaches only over SSH. Claude finds, reads
and edits them, and runs the builds and tests there.

How it fits together:
- **`remote <host> ...`** (`remote/.local/bin/remote`): every safe operation
  on the remote. Claude may run it without asking, because each subcommand is
  read-only or a build/test.
- **The mount**: `remote <host> mount` shows the remote home at
  `~/remote/<host>` (FUSE-T sshfs), so Claude reads and edits with its own
  tools. Edits ask first.
- **The skill** (`claude/.claude/skills/remote-machine/SKILL.md`): when to use
  which. Claude picks it up by itself.
- **Everything else** on the remote is plain `ssh <host> '...'`, which asks.

Searching happens on the remote, never through the mount: measured on 2,252
files, 0.26 s over SSH against 35 s through the mount. The design and its
measurements: `doc/specs/2026-10-08-remote-machine-design.md`.

## Setting up

### This Mac

`./install_darwin.sh` does it: FUSE-T and its sshfs (two `.pkg` installers,
which ask for your password), the `remote` command (stow package `remote`),
and two rules in `~/.claude/settings.json`: `Bash(remote:*)` and
`Read(~/remote/**)`. `scripts/verify.sh` checks all three.

### The work Mac, once

1. **Remote Login:** System Settings > General > Sharing > Remote Login: on.
   Under (i), "Allow access for": only your user. Tick "Allow full disk access
   for remote users" only if the source lives under `~/Documents`, `~/Desktop`
   or `~/Downloads` (macOS blocks those over SSH otherwise).
2. **Your key:** on this Mac, `ssh-keygen -t ed25519 -f ~/.ssh/workmac`. Copy
   `~/.ssh/workmac.pub` to the work Mac (USB stick or AirDrop; it's offline)
   and append it to `~/.ssh/authorized_keys` there.
3. **A connection:** a Thunderbolt cable between the Macs makes a network by
   itself; the work Mac is then `<its-name>.local` (System Settings > General
   > Sharing shows the name). A USB-C Ethernet adapter, or a LAN without
   internet, works too.
4. **The alias**, in this Mac's `~/.ssh/config`:
   ```
   Host workmac
       HostName <its-name>.local
       User <your user there>
       IdentityFile ~/.ssh/workmac
       IdentitiesOnly yes
       ConnectTimeout 5
   ```
   Check: `remote workmac status`.

Nothing is installed on the work Mac. Builds use its own Xcode command line
tools and Homebrew `cmake`; `remote` adds Homebrew's folders to PATH itself,
because commands over SSH don't load the shell's setup.

## Commands

| Command | Does |
|---|---|
| `remote <host> status` | reachable? mounted? mount healthy? |
| `remote <host> mount` / `unmount` | the remote home at `~/remote/<host>`; `unmount` forces it if the remote is gone |
| `remote <host> ls <path>` | `ls -la` |
| `remote <host> cat <file> [first:last]` | a file, or a range of lines |
| `remote <host> grep [-i] [-w] [-l] [--include <glob>] [--] <pattern> <path>` | recursive search with line numbers |
| `remote <host> find <path> [-name <glob>] [-type f\|d]` | find files |
| `remote <host> git <path> status\|diff\|log\|show\|branch [args]` | read-only git |
| `remote <host> build <dir> [--preset P \| --build-dir D]` | CMake build; configures first if needed |
| `remote <host> test <dir> [--preset P \| --build-dir D]` | ctest, with output on failure |

Paths are relative to the remote home. Exit 2: refused, nothing ran (the
message says why). Exit 255: the host can't be reached. Options that could run
a program or write (`grep --pre`, `find -exec`/`-delete`, `git push`/`commit`,
`--ext-diff`, `--output`) are refused.

## Troubleshooting

- **Anything under `~/remote/<host>` hangs:** the remote went away while
  mounted. `remote <host> status` reports it; `remote <host> unmount` clears it
  (forcing it if needed). Unmount before unplugging or sleeping the remote.
- **"Operation not permitted":** macOS privacy protection on the remote; see
  step 1 above.
- **`cmake: command not found`:** the remote's cmake is somewhere other than
  `/opt/homebrew/bin` or `/usr/local/bin`. Use `ssh <host> 'command -v cmake'`
  from an interactive login to find it, and add that folder to `PRELUDE` in
  `remote`.
- **Red C++ errors in files under `~/remote/`:** expected and wrong; the
  remote build is the truth.
- **A build straight after an edit says nothing changed:** macOS's `make`
  (GNU Make 3.81) compares file times in whole seconds, so an edit in the same
  second as the last build's output looks up to date. Build again a moment
  later, or use a Ninja preset, which doesn't have this problem.

## Practising on this Mac

`scripts/remote-test-host.sh up` (asks for your password) creates a stand-in
work Mac: user `workmac-sim`, reached as `remote workmac-test`, with a small
CMake project in `src/hello`. SSH accepts only that user, only from this Mac,
only with its key. `scripts/test-remote.sh` runs the full test suite against
it. `scripts/remote-test-host.sh down` removes it all and turns Remote Login
off. `up` refuses if Remote Login is already on.
