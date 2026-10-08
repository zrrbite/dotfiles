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

### History: linear, no merge commits

History is a straight line of commits that each make sense on their own.

**git enforces part of this.** `git/.gitconfig` sets `pull.rebase = true` (a
pull rebases) and `merge.ff = only` (a merge that can't fast-forward is
refused). A refusal means "rebase first". Don't get around it with `--no-ff`,
`--no-rebase` or `-c merge.ff=...` unless I ask for a merge commit. On a
machine or in a repo without these settings, follow the same rules by hand.

**Integrating**
- Never create a merge commit. Bring a branch up to date with
  `git pull --rebase` or `git rebase origin/<base>`. Land it with
  `git merge --ff-only` or a plain push. If that is refused, rebase and try
  again. Never fall back to a merge, and never "fix" a refused push with
  `--force` on a shared branch.
- On GitHub: "Rebase and merge", or "Squash and merge" for a one-commit
  change. Never "Create a merge commit".
- Merge commits already on the main branch stay. Don't rewrite published
  history to remove them.

**Cleaning up a branch before it lands**
Rewrite only commits that exist nowhere else, or a branch only I push to.
For anything already on a shared branch, stop and ask first.

Every commit that survives is one logical change, builds and passes tests on
its own, and has a message that says why. So:
- Fold into the commit they fix: fixups, "wip", typo and lint fixes, review
  fixes to lines this branch added, and reverts of this branch's own work.
- Keep separate: a refactor and the behaviour change built on it, unrelated
  fixes found along the way, and anything someone might want to revert or
  bisect to on its own.
- Don't squash a whole branch into one commit just because it looks tidier.

`rebase -i` needs an editor you don't have, so:
1. Back up first: `git branch backup/<branch>-<YYYYMMDD>`.
2. While working, make fixes with `git commit --fixup=<sha>`. To clean up, run
   `git rebase --autosquash <base>` (no `-i` needed since git 2.44).
3. To reorder, drop or reword, write the todo list to a file and run
   `GIT_SEQUENCE_EDITOR="cp <todo-file>" git rebase -i <base>`. Reword with an
   `exec git commit --amend -m "..."` line after the `pick`.
4. If a conflict's intent isn't clear: `git rebase --abort` and ask. Never
   resolve one by taking a whole side.
5. Verify before pushing:
   - `git diff backup/<branch> HEAD` prints nothing, since a cleanup must not
     change the end result (unless changing content was the point);
   - `git log --merges <base>..HEAD` prints nothing;
   - `git rebase --exec "<test command>" <base>` passes, proving each commit
     builds.
6. Push with `--force-with-lease`, never `--force`. Keep the backup branch and
   tell me it exists.

Report `git log --oneline <base>..HEAD` before and after, and what was folded
into what.
