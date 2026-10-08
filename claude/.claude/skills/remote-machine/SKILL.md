---
name: remote-machine
description: Use when working with files, builds or tests on another machine over SSH (such as the offline work Mac), when the user names a remote host alias, or with paths under ~/remote/. Covers the `remote` command, the ~/remote/<host> mount, and what needs the user's approval. macOS and Linux only.
---

# Working on a remote machine

The files live on another machine, reached over SSH as an `~/.ssh/config`
alias (`<host>`). Use the `remote` command for everything it offers: it is
allowed without prompts because every subcommand is read-only or a
build/test. Full reference: `doc/remote-machine.md` in the dotfiles.

## Rules

1. **Start with `remote <host> status`.** If the host is not reachable, tell
   the user and stop: touching `~/remote/<host>` while the host is gone hangs.
   If it isn't mounted, run `remote <host> mount`.
2. **Find things on the remote:** `remote <host> grep`, `find`, `ls`. Never
   use the Grep or Glob tools on `~/remote/<host>`: searching through the
   mount is about 100 times slower than searching on the remote.
3. **Read with the Read tool** at `~/remote/<host>/<path>`, where `<path>` is
   what `remote` printed (paths are relative to the remote home, which is what
   the mount shows).
4. **Edit with Edit or Write on the mount.** Each edit asks the user. Never
   edit through `ssh <host> sed ...` or similar, which would skip that.
5. **Build and test with `remote <host> build <dir>` and `remote <host> test
   <dir>`.** The remote compiler is the truth. Ignore local C++ diagnostics on
   files under `~/remote/`: they use the wrong paths and the wrong headers.
6. **Anything else on the remote** (running a program, deleting, `git commit`)
   is `ssh <host> '...'`, which asks the user; say why before running it.
   Never install anything on the remote and never give it internet access.
7. **"Operation not permitted"** under `~/Documents`, `~/Desktop` or
   `~/Downloads` on a Mac remote is its privacy protection: tell the user the
   setting (Remote Login, "Allow full disk access for remote users"); don't
   look for a way around it.
8. **When done, `remote <host> unmount`**, and always before the remote is
   unplugged, sleeps or is shut down.

## The commands

| Command | Does |
|---|---|
| `remote <host> status` | reachable? mounted? mount healthy? |
| `remote <host> mount` / `unmount` | the remote home at `~/remote/<host>` |
| `remote <host> ls <path>` | list a folder |
| `remote <host> cat <file> [first:last]` | a file, or a range of its lines |
| `remote <host> grep [-i] [-w] [-l] [--include <glob>] [--] <pattern> <path>` | search (recursive, with line numbers) |
| `remote <host> find <path> [-name <glob>] [-type f\|d]` | find files |
| `remote <host> git <path> status\|diff\|log\|show\|branch` | read-only git |
| `remote <host> build <dir> [--preset P \| --build-dir D]` | CMake build (configures if needed) |
| `remote <host> test <dir> [--preset P \| --build-dir D]` | ctest |

Exit 2 means `remote` refused the request and ran nothing (the message says
why); 255 means the host could not be reached. A path may not start with `-`:
write `./-name`.
