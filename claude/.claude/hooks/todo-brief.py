#!/usr/bin/env python3
"""Show the cross-project todo list's open items at the start of a Claude Code session.

Why this exists
---------------
`~/Development/todo/TODO.md` is where sessions write what Martin must act on
later (see `CLAUDE.md`, "Cross-project task list"). Nothing read it back: a
session only saw it when asked to, so Martin had to remember to say "check the
todo". This SessionStart hook prints a short brief into the session's context
instead:

  - in full, the sections that mention the repo the session starts in (its open
    items only, done ones left out);
  - one line counting what is open everywhere else.

Outside a git repo it prints only the counts.

It fails open: a missing file, bad input or any error prints nothing and exits 0.
A brief is a convenience; it must never stop a session from starting.

Registration (per machine, like the other hooks in this package)
----------------------------------------------------------------
In `~/.claude/settings.json`:

    "hooks": {
      "SessionStart": [
        { "hooks": [ { "type": "command", "command": "$HOME/.claude/hooks/todo-brief.py" } ] }
      ]
    }

Configuration (environment):
  TODO_FILE              the list (default ~/Development/todo/TODO.md)
  TODO_BRIEF_MAX_LINES   cap on the repo's part of the brief (default 80)
"""

from __future__ import annotations

import json
import os
import re
import sys

SKIP_SECTIONS = ("Repo map", "Log")
OPEN = re.compile(r"^\s*- \[ \]")
DONE = re.compile(r"^\s*- \[[xX]\]")


def repo_name(cwd: str) -> str | None:
    """The basename of the git work tree containing cwd, found without running git."""
    path = os.path.abspath(cwd)
    while True:
        if os.path.exists(os.path.join(path, ".git")):
            return os.path.basename(path)
        parent = os.path.dirname(path)
        if parent == path:
            return None
        path = parent


def sections(text: str) -> list[tuple[str, list[str]]]:
    """Level-2 sections as (heading, body lines), the list's preamble and its Repo map and Log left out."""
    out: list[tuple[str, list[str]]] = []
    heading, body = None, []
    for line in text.splitlines():
        if line.startswith("## "):
            if heading is not None:
                out.append((heading, body))
            heading, body = line[3:].strip(), []
        elif heading is not None:
            body.append(line)
    if heading is not None:
        out.append((heading, body))
    return [(h, b) for h, b in out if not h.startswith(SKIP_SECTIONS)]


def open_items(body: list[str]) -> list[str]:
    """The open items with their continuation lines, and any ### heading that has one under it."""
    out: list[str] = []
    pending_sub = None
    keeping = False
    for line in body:
        if line.startswith("### "):
            pending_sub, keeping = line, False
        elif OPEN.match(line):
            if pending_sub:
                out.append(pending_sub)
                pending_sub = None
            out.append(line)
            keeping = True
        elif DONE.match(line) or not line.strip():
            keeping = False
        elif keeping and line.startswith((" ", "\t")):
            out.append(line)
        else:
            keeping = False
    return out


def count_open(body: list[str]) -> int:
    return sum(1 for line in body if OPEN.match(line))


def short(heading: str) -> str:
    return re.split(r" — | - ", heading, maxsplit=1)[0].strip()


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except Exception:
        event = {}
    cwd = event.get("cwd") or os.getcwd()

    path = os.path.expanduser(os.environ.get("TODO_FILE", "~/Development/todo/TODO.md"))
    if not os.path.isfile(path):
        return
    with open(path, encoding="utf-8") as f:
        secs = sections(f.read())

    repo = repo_name(cwd)
    mine = []
    if repo:
        needle = repo.lower()
        mine = [(h, b) for h, b in secs
                if needle in (h + "\n" + "\n".join(b)).lower() and count_open(b) > 0]
    others = [(h, b) for h, b in secs if (h, b) not in mine and count_open(b) > 0]

    lines: list[str] = []
    if mine:
        cap = int(os.environ.get("TODO_BRIEF_MAX_LINES", "80"))
        body: list[str] = []
        for h, b in mine:
            body.append(f"## {h}")
            body.extend(open_items(b))
            body.append("")
        if len(body) > cap:
            hidden = len(body) - cap
            body = body[:cap] + [f"... ({hidden} more lines in TODO.md)"]
        lines.append(f"Open items for `{repo}` in {path} (the cross-project todo list; "
                     "CLAUDE.md says how to update it):")
        lines.append("")
        lines.extend(body)

    if others:
        total = sum(count_open(b) for _, b in others)
        listed = "; ".join(f"{short(h)} ({count_open(b)})" for h, b in others)
        where = "Elsewhere in the list" if mine else f"Open in {path}"
        lines.append(f"{where}: {total} items in {len(others)} sections: {listed}.")

    if lines:
        print("\n".join(lines).rstrip())


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
