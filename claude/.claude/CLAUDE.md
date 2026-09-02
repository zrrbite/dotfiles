# CLAUDE.md

Personal guidance for Claude Code, applied across all my projects.

## Cross-project task list

I keep a task list at `~/Development/todo` (private repo `zrrbite/todo`);
`TODO.md` is the list, `log/YYYY-MM.md` is the per-session history, and its
`README.md` documents the conventions.

**When a session produces something I need to act on later, write it there** —
don't only report it in chat, where it dies with the session. Worth logging:

- a decision only I can make, or an approach that needs my approval
- work needing hardware, physical presence, or credentials you don't have
- a loose end a change deliberately left open, or a workaround that wants a
  proper fix
- a risk noticed in passing: unpushed work, a shadowed config, a stale doc, a
  claim in a doc that the code contradicts

Don't log what the repo already tracks — an open PR, a failing test, a `TODO`
comment in the code. Pointers to those are fine; copies are not.

### Conventions

- **Order by what blocks what**, not by size. Section order carries the
  priority; don't number sections (renumbering on every insert is churn).
- **Date-stamp every task** with the date it was added, as `` `YYYY-MM-DD` `` at
  the start of the item, so staleness is visible at a glance.
- **Name the repo and the file** holding the detail. This list holds pointers
  and judgement, never a second copy of another repo's docs — copies drift.
- `- [ ]` open, `- [x]` done. Ticked items stay until the section goes stale, so
  there's a record of what got finished.
- **Append a dated entry to `log/YYYY-MM.md`** for the current month, newest
  first within the file, saying what changed and what was left open. A task
  should always be traceable to the session that created it. Create the month's
  file if it doesn't exist yet; the history lives outside `TODO.md` so the list
  stays short.
- **In the same pass, add the row to the dated index in `README.md`** — one row
  per topic touched, one or two sentences, linking to that log entry's anchor.
  The index is the front door; a log entry without its row is invisible.
- Commit and push after updating. Keep the commit message specific about what
  moved, not "update todo".
- Never write the literal do-not-commit marker into these files — the global
  pre-commit hook greps staged files for it and will block the commit.

## Git

My global hooks live in `~/Development/dotfiles/git/.git-hooks`
(`core.hooksPath` points there). The pre-commit hook enforces clang-format on
staged C++ and blocks a do-not-commit marker. If a commit is blocked by that
marker, a staged file genuinely contains it — tell me rather than bypassing with
`--no-verify`.
