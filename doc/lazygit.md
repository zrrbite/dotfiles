# lazygit

A cheat sheet for lazygit, a terminal UI for git, in the order you use it:
look, stage, commit, tidy up before pushing, push. Then a practice plan.
lazygit is on trial since 2026-10-08 (macOS installer only) and has no config
here: its defaults use the terminal's Nord colours, and `e` opens nvim
because git's `core.editor` says so. Every key was checked against lazygit
0.66's defaults (`lazygit --config` prints them); keys move between releases,
so check again after a big upgrade.

## The one idea: panels on the left, keys act on the one you're in

The left column is five panels: **1** status, **2** files, **3** branches,
**4** commits, **5** stash. The big area on the right shows whatever is
selected (a file's diff, a commit's changes). The same letter does different
things in different panels, so when unsure, press **`?`**: it lists the keys
for the panel you're in.

Everything lazygit does is an ordinary git command. The **Command log** at the
bottom left shows each one as it runs, which is a good way to learn what the
keys mean in git terms.

## Start and quit

| Do | Keys |
|---|---|
| Start, in the repo of the current folder | `lazygit` |
| In a tmux popup, for this pane's repo | `Ctrl+a` `g` |
| In nvim, for the current file's repo | `Space` `g` `g` |
| Every key for this panel | `?` |
| Back out of a view or a menu | `Esc` |
| Quit | `q` |

lazygit finds the repo root from any folder inside it. Outside a repo it
asks whether to create one; `Enter` says no.

## Get around

| Do | Keys |
|---|---|
| Jump to a panel | `1`–`5` |
| Previous / next panel | `h` / `l` (or `Tab`) |
| Up / down a list | `j` / `k` |
| Into the selected thing (a file's lines, a commit's files) | `Enter` |
| Search the list | `/` |
| Undo / redo the last git action | `z` / `Z` |

`z` works through git's reflog, so it undoes commits, amends and rebases. It
**can't** bring back changes you discarded from a file: those were never in
git.

## Stage and commit (panel 2, files)

| Do | Keys |
|---|---|
| Stage / unstage the file | `Space` |
| Stage / unstage everything | `a` |
| Stage single lines: go into the file | `Enter`, then `j` `k` and `Space` |
| ...a range of lines / the whole hunk | `v`, move, `Space` / `a` |
| ...previous / next hunk; back to the file list | `h` / `l`; `Esc` |
| Commit what's staged | `c`, type the message, `Enter` (`Tab` for a description) |
| Add what's staged to the last commit | `A` |
| Discard a file's changes (asks first) | `d` |
| Stash everything | `s` |

Staging by line is where lazygit beats the command line: one change becomes
two commits without `git add -p`.

## Tidy up before pushing (panel 4, commits)

Your git rules: history stays a straight line, and every commit makes sense
on its own. So before pushing, fold the fix-ups in. Rewrite **only commits
you haven't pushed**: the branches panel and the status line show `↑3` when
the top three commits exist only here.

| Do | Keys |
|---|---|
| Reword a commit's message | `r` |
| Fold a commit into the one below, keeping only that one's message (fixup) | `f` |
| Fold a commit into the one below, combining messages (squash) | `s` |
| Move a commit down / up | `Ctrl+j` / `Ctrl+k` |
| Drop a commit | `d` |
| Put staged changes into **this** older commit | `A` |
| Which commit do my staged lines belong to? (from panel 2) | `Ctrl+f` (it searches commits not yet on `main`/`master`'s remote) |
| Continue or abort a rebase that stopped | `m` |

The everyday fix-up: you find a typo in something you committed an hour ago.
Fix it, stage it (`Space` in panel 2), press `Ctrl+f` to jump to the commit
that last touched those lines, then `A`. lazygit rebases the fix into that
commit, and there's nothing to squash later.

If a rebase stops on a conflict, the conflicted files show in panel 2. When
the right resolution isn't obvious, `m` then **abort** puts everything back
as it was; don't settle a conflict by taking one side wholesale.

## Pull and push

| Do | Keys |
|---|---|
| Pull (it rebases: your git config has `pull.rebase = true`) | `p` |
| Push | `P` |
| New branch / switch branch / back to the previous one (panel 3) | `n` / `Space` / `-` |

If a push is refused because the remote moved on, lazygit offers to force
push. Say no: pull (`p`), which rebases your commits on top, then push
again. Force-pushing is only for a branch you alone push to, and then with
`--force-with-lease` from the command line.

## In nvim

`Space` `g` `g` opens lazygit in a floating window for the repo of the file
you're editing. `q` closes it, and any buffer lazygit changed on disk (a
discarded change, a checkout) reloads. Inside it, `Esc` goes to lazygit, not
to nvim's "leave terminal mode". `e` on a file opens a second nvim inside the
window; `:q` returns to lazygit.

## On the Danish Mac layout

- `[` / `]` switch tabs inside a panel (local branches, remotes, tags); they
  are ⌥ 8 / ⌥ 9, and work, since AeroSpace's keys are on ⌃⌥.
- Nothing in the tables above needs Option.

## Practice: seven steps

In the practice folder (`scripts/practice-folder.sh`, then `cd
/tmp/practice`): a git repo with one commit, a modified `main.cpp` and an
untracked `todo.txt`. Open lazygit there with `lazygit` or `Ctrl+a` `g`.

1. **Look around:** `1`–`5`, `j` `k` through the files, read the diff on
   the right, `?` in each panel. Find the Command log.
2. **Stage lines, on a branch:** in panel 3, `n` and call it `tidy`, so
   your commits aren't on `main` (`Ctrl+f` in step 4 only searches commits
   that aren't). Then `Enter` on `main.cpp`, stage only the `Scale` call with
   `Space`, commit it (`c`). Stage and commit the rest as a second commit,
   and `todo.txt` as a third.
3. **Reword:** in panel 4, `r` on the second commit; give it a better
   message.
4. **Fix an older commit:** change a line that the first commit added, stage
   it, `Ctrl+f`, `A`. Check with `Enter` on that commit that the change is
   inside it. (If `Ctrl+f` finds nothing, select the commit yourself; `A`
   works the same.)
5. **Reorder and fold:** `Ctrl+k` to move `todo.txt`'s commit down, then `f`
   to fold it into its neighbour.
6. **Undo:** `z` until you're back before step 5, then `Z` to redo.
7. **From the editor:** open `main.cpp` in nvim, `Space` `g` `g`, stage a
   line, commit, `q`; nvim is where you left it.

You've got it when tidying three messy commits into two clean ones takes a
`Ctrl+f`, an `A` and an `r`, without opening `?`.
