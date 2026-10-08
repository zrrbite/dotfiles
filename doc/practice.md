# Practice: tmux, yazi and nvim

Cheat sheets and drills for the three tools that do the day-to-day work in
this setup, written from the 2026-10 practice sessions: what was configured,
and what tripped things up. Every key here was checked against this repo's
config (`tmux/.tmux.conf`, `yazi/.config/yazi/`, `nvim/.config/nvim/`) and
yazi 26.9's own keymap.

The full references stay where they are: [`tmux.md`](tmux.md) (and its
one-week plan), [`yazi.md`](yazi.md), and
[`nvim-tutorial.md`](nvim-tutorial.md) for vim motions. This page is the
short version plus practice.

**Start here:** build a throwaway folder to practise in. It has notes, a
Markdown guide, two images, a hidden file, and a small C++ project in git
with one modified file (containing an error clangd will flag) and one
untracked file:

```bash
scripts/practice-folder.sh              # builds /tmp/practice
scripts/practice-folder.sh --fresh      # wipe it and build it again
```

## How the pieces fit

| Job | Where it happens |
|---|---|
| One project's terminals | a tmux **session** per project: `t` in its folder, or `tp` / `Ctrl+a f` to pick one |
| Editing | nvim, in that session's first window |
| Opening and moving files | yazi: on its own in a Ghostty window (outside tmux), or inside nvim with `Space -` |
| Arranging windows | AeroSpace, every key on **⌃⌥** (Control+Option) |

Three things are shared between the tools:
- **Copies:** every yazi window, including the one inside nvim, shares one
  copy list. `y` in one and `p` in another works.
- **Folders:** zoxide learns the folders you `cd` into. In the shell `cd`
  *is* zoxide (`cd dotf` jumps to the dotfiles), and `Shift+Z` in yazi uses
  the same list. (`tp` is different: it lists ~/Development.)
- **Clipboard:** a copy in tmux's copy mode (`y`), a path copied in yazi
  (`c c`), and `⌘C` all go to the macOS clipboard. `⌘V` pastes anywhere.

---

## Cheat sheet: tmux

The prefix is **`Ctrl+a`**: press it, let go, then the key. The session pill
at the bottom left turns **yellow** while tmux waits for that key.

| Do | Keys |
|---|---|
| **Sessions** | |
| Session for this folder / a named one (shell commands) | `t` / `t name` |
| Pick a project from ~/Development | `Ctrl+a` `f`, or `tp` |
| Detach / reattach | `Ctrl+a` `d` / `tmux a` |
| List / previous / next session | `Ctrl+a` `s` / `Ctrl+a` `⌘←` / `Ctrl+a` `⌘→` |
| Back to the last session | `Ctrl+a` `Tab` |
| **Panes** | |
| Split side by side / stacked | `Ctrl+a` `v` / `Ctrl+a` `-` |
| Move / zoom / close | `Ctrl+a` `h` `j` `k` `l` / `Ctrl+a` `z` / `Ctrl+a` `x` |
| Resize (hold to repeat) | `Ctrl+a` `H` `J` `K` `L` |
| **Windows** | |
| New / rename | `Ctrl+a` `c` / `Ctrl+a` `,` |
| Go to 1–9 / previous / next | `Ctrl+a` `1`–`9` / `Ctrl+a` `Ctrl+h` / `Ctrl+a` `Ctrl+l` |
| Everything as a tree | `Ctrl+a` `w` |
| **Copy mode** (a purple COPY tag shows) | |
| Enter (or scroll up with the mouse) | `Ctrl+a` `Enter` |
| Move / page / top, bottom / search | `j` `k` / `Ctrl+u` `Ctrl+d` / `g` `G` / `/` |
| Select / copy to the clipboard / leave | `v` / `y` / `q` |
| **Keeping it** | |
| Save all sessions now / restore | `Ctrl+a` `Ctrl+s` / `Ctrl+a` `Ctrl+r` (auto-saved every 15 min) |
| Reload the config | `Ctrl+a` `r` |
| Command prompt | `Ctrl+a` `:` |

## Cheat sheet: yazi

The pattern for copying: **choose, mark, go, paste.** Nothing happens on
disk until `p`.

| Do | Keys |
|---|---|
| **Start and quit** | |
| Start / start and quit into the folder | `yazi` / `y` |
| Quit / quit, shell stays put / close tab | `q` / `Q` / `Ctrl+c` |
| Every key | `F1` |
| **Move** | |
| Up a folder / down / up / into | `h` `j` `k` `l` |
| Open / scroll the preview / file details | `Enter` / `J` `K` / `i` |
| Show or hide dotfiles | `.` |
| **Jump** | |
| Bookmarks: ~/Development / the dotfiles / todo | `g` `D` / `g` `.` / `g` `T` |
| Home / Downloads / type a path | `g` `h` / `g` `d` / `g` `Space` |
| A folder you use often (zoxide) / a file below here (fzf) | `Shift+Z` / `z` |
| Narrow this folder as you type / search names / contents | `f` / `s` / `S` |
| **Choose** | |
| Select (moves down) / range / unselect range | `Space` / `v` / `V` |
| All / invert / clear | `Ctrl+a` / `Ctrl+r` / `Esc` |
| **Mark, paste** | |
| Mark to copy / to move / cancel | `y` / `x` / `Shift+Y` |
| Paste (a clash gets `_1`) / overwrite / as a symlink | `p` / `P` / `-` |
| Big copy's progress | `w` |
| **Two panels, Far-style** | |
| Clone this folder into a new tab / flip tabs / tab 1–9 | `t` `t` / `Tab` / `1`–`9` |
| Send this folder to the other yazi windows | `g` `s` |
| **Files** | |
| New file / folder (end with `/`) / rename | `a` / `a` / `r` |
| To the Trash / delete for good | `d` / `D` |
| Copy path / folder path / file name | `c` `c` / `c` `d` / `c` `f` |

## Cheat sheet: nvim

The leader is **`Space`**. Pause after `Space` and a hint list (which-key)
shows what comes next.

| Do | Keys |
|---|---|
| **Find** | |
| Files / text in files (grep) / open buffers | `Space` `f` `f` / `Space` `f` `g` / `Space` `f` `b` |
| Symbols in this file / project / C++ macros | `Space` `f` `s` / `Space` `f` `w` / `Space` `f` `m` |
| Diagnostics / help | `Space` `f` `d` / `Space` `f` `h` |
| **Files** | |
| yazi at this file / at the project root | `Space` `-` / `Space` `_` |
| File tree (neo-tree) | `Space` `e` |
| **Code (LSP)** | |
| Definition / declaration / references / implementation | `g` `d` / `g` `D` / `g` `r` / `g` `I` |
| Docs under the cursor / signature help | `K` / `Space` `s` `h` |
| Rename / code action / format | `Space` `r` `n` / `Space` `c` `a` / `Space` `F` |
| This line's error / all errors in a list | `Space` `d` / `Space` `q` |
| C++: header ↔ source / clang-tidy fixes | `Space` `h` / `Space` `c` `f` |
| Completion: next / previous / accept | `Ctrl+n` / `Ctrl+p` / `Tab` or `Ctrl+y` |
| **Git (gitsigns)** | |
| Next / previous change | `]` `c` / `[` `c` |
| Preview / stage / undo stage / reset the change | `Space` `h` `p` / `Space` `h` `s` / `Space` `h` `u` / `Space` `h` `r` |
| Blame this line / toggle blame | `Space` `h` `b` / `Space` `g` `b` |
| **Debug** (F-keys need `fn` on the laptop) | |
| Start, continue / step over, into, out | `F5` / `F10` `F11` `F12` |
| Breakpoint / conditional / debug UI | `Space` `b` / `Space` `B` / `Space` `d` `u` |
| **Other** | |
| Move between splits | `Ctrl+h` `j` `k` `l` |
| Comment a line / a selection | `g` `c` `c` / `g` `c` |
| Clear search highlight / Markdown preview | `Esc` / `Space` `m` `p` |

### yazi inside nvim (`Space -`)

It's a full yazi, so every yazi key works, plus these from yazi.nvim:

| Do | Keys |
|---|---|
| Open the file in nvim | `Enter` |
| Open in a side-by-side / stacked split / new tab | `Ctrl+v` / `Ctrl+x` / `Ctrl+t` |
| Pick which window to open it in | `Ctrl+o` |
| Close yazi and grep in this folder | `Ctrl+s` |
| Send the selected files to the quickfix list | `Ctrl+q` |
| Make this folder nvim's working directory | `Ctrl+\` |
| yazi.nvim's own key list / close | `F1` / `q` |

**Here `Tab` is yazi.nvim's**, not the tab switch: it jumps yazi to the
folder of the next nvim split. Use `1`–`9` for yazi tabs inside nvim.

---

## The Danish Mac layout

Option types `[ ] { } | \ @ ~`, so keys that need those symbols are awkward.

| Tool | Awkward key | Use instead |
|---|---|---|
| AeroSpace | — | It's on ⌃⌥, so Option still types symbols |
| tmux | `Ctrl+a` `\|` (⌥ i), `Ctrl+a` `[` (⌥ 8) | `Ctrl+a` `v`, `Ctrl+a` `Enter` |
| yazi | `~` (a dead key), `[` `]` (⌥ 8 / ⌥ 9) | `F1`, `Tab` or `1`–`9` |
| yazi | `-` (symlink) | it's the key right of `.`; the key right of `0` types `+` |
| nvim | `]c` / `[c` (⌥ 9 / ⌥ 8, then `c`) | they work, just slower |
| nvim | `^` (first non-blank; a dead key) | `_` does the same |
| nvim | `@q` (run macro q) | `@` is ⌥ ' |

## Gotchas met so far

- **Config changes don't reach what's running.** tmux: `Ctrl+a` `r`. yazi:
  quit and start every yazi again. nvim: restart it. AeroSpace:
  `aerospace reload-config`.
- **One tmux server.** A second one (from a test, or `tmux -L`) quietly stops
  the 15-minute auto-save until it's gone.
- **In tmux, `Ctrl+a` isn't line start any more.** Use `⌘←`.
- **`t` is a shell command; `Ctrl+a` `t` is tmux's clock** (`q` leaves it).
- **yazi's selection isn't the copy.** `y` turns the selection into a copy
  mark, so the selection "disappears". `x` turns files red and deletes
  nothing until `p` moves them.
- **`a name` makes a file, `a name/` a folder.**
- **`Ctrl+c` on yazi's last tab quits yazi.**
- **In a yazi name box, `Esc` twice cancels.** The first switches to vi
  normal mode.
- **`Tab` means three things:** last session after tmux's prefix, next tab in
  yazi, next split's folder in nvim's yazi.
- **git refuses merge commits.** `git pull` rebases, and a merge that can't
  fast-forward is refused; rebase first.

---

## Drills

About ten minutes each, in `/tmp/practice`. Do them in order the first time,
then repeat the ones that felt slow. Each ends with how to tell you've got it.

### tmux

**T1. Sessions.** `cd /tmp/practice && t` makes a session named `practice`.
Detach (`Ctrl+a` `d`), then `t` in `~/Development/dotfiles` for a second one.
Flip between them with `Ctrl+a` `Tab`, then pick one from `Ctrl+a` `s`.
*Got it when switching projects never means a new terminal window.*

**T2. Panes.** In `practice`: `Ctrl+a` `v`, then `Ctrl+a` `-` in the right
pane. Move with `Ctrl+a` `h`/`l`, zoom one with `Ctrl+a` `z` and back,
widen one with `Ctrl+a` `L`. Close two with `Ctrl+a` `x`.
*Got it when `z` replaces squinting at a small pane.*

**T3. Windows.** Three windows named `code`, `shell`, `git` (`Ctrl+a` `c`,
then `Ctrl+a` `,`). Jump with `Ctrl+a` `1`–`3`.
*Got it when the bottom bar tells you where you are without looking twice.*

**T4. Copy mode.** Run `git -C /tmp/practice log --stat`, then
`Ctrl+a` `Enter`, `/` and search `main.cpp`. Select the line with `v` and
`j`/`k`, `y`, and paste it into another app with `⌘V`.
*Got it when you stop reaching for the mouse to copy terminal output.*

**T5. Surviving.** `Ctrl+a` `Ctrl+s`, quit Ghostty completely, open it and
run `tmux a`. Everything is where it was.
*Got it when closing a terminal stops feeling risky.*

### yazi

**Y1. Look around.** In a Ghostty window of its own: `cd /tmp/practice &&
yazi`. An image in `photos`, the rendered `notes/guide.md` (`J`/`K`), the git
marks in `projects/alpha`, `.` to hide dotfiles, `i` on a file, `F1`.

**Y2. Make and rename.** In `notes`: `a` `drafts/`, then `a` `plan.md`
inside it, `a` `archive/2026/`, and `r` on `note1.txt` to `first.txt`.

**Y3. Copy and move.** Select `note2`–`note4` (`v`, `j` `j`, `Esc`), `y`, go
to `projects/beta`, `p`. Then `note5` and `note6` with `x` into
`notes/archive`. Then `y` on `note7` and cancel with `Shift+Y`.
*Got it when you predict, before `p`, exactly what will land where.*

**Y4. Two panels.** In one window: `t` `t`, `g` `D` in the new tab, `Tab`
back, `y` a note, `Tab`, `p`. Then two yazi windows side by side
(`⌃⌥ Enter` for the second): `g` `s` in one to line them up, `y` there, `p`
in the other.

**Y5. Clashes, links, delete.** Paste the same file twice (`_1`), once more
with `P`, a symlink with `-`. Then `d` the symlink (the original stays) and
`D` the `_1` copy.

**Y6. Find, don't walk.** `Shift+Z` to a project you used today; `z` and
`main` to find `main.cpp` from the top; `f` `1` in `notes`; `c` `c` to copy a
path.
*Got it when moving three files between two projects is one `Shift+Z`, a few
`Space`s, `x` and `p`.*

### nvim

**N1. Find.** `cd /tmp/practice && nvim .`, then `Space` `f` `f` and
`main`, `Space` `f` `g` and `Total`, `Space` `f` `b` to come back.
*Got it when you stop opening files by walking a tree.*

**N2. The error.** In `projects/alpha/main.cpp`: `Space` `d` on the red line
reads the error, `K` on `Scale` shows its signature, and `g` `d` jumps to its
declaration in `util.h`. There, `Space` `h` flips to `util.cpp`, where it's
defined. `Ctrl+o` (repeated) walks back to `main.cpp`. Fix the call
(`Scale(Total, 2)`), and the red mark goes away.

**N3. Rename and format.** `Space` `r` `n` on `Total` renames it in the file.
Mess up some indentation, then `Space` `F`.

**N4. Git changes.** `]` `c` to the changed lines, `Space` `h` `p` to see
the change, `Space` `h` `s` to stage it, `Space` `h` `u` to undo that.
`Space` `g` `b` for blame.

**N5. yazi inside nvim.** `Space` `-` on `main.cpp`; `Enter` on `util.cpp`
opens it. `Space` `-` again and `Ctrl+v` on `util.h` opens it beside.
`Space` `_` opens at the project root; `Ctrl+s` there greps that folder.
*Got it when `Space -` is your reflex for "the file next to this one".*

### Together

**W1. Start the day.** `tp`, pick `practice`. Window 1: `nvim .`. Window 2:
a shell. `Space` `-` to open a file, `Ctrl+a` `2` to run something,
`Ctrl+a` `1` back.

**W2. Bring a file in.** In a standalone yazi window, `g` `D` and find
something to copy, `y`. In nvim: `Space` `_`, go to `projects/beta`, `p`,
`Enter` to open it.

**W3. Grab an error.** If N2 fixed it, `scripts/practice-folder.sh --fresh`
brings the error back. In window 2, `clang++ -c projects/alpha/main.cpp`,
then copy the error with copy mode and paste it into a note in nvim.

**W4. Finish the change.** Fix the error in nvim, `Space` `h` `p` to review,
`Space` `h` `s` to stage, then `git commit` in window 2. Then see the
no-merge-commits rule: `git switch -c side`, commit something,
`git switch main`, commit something else, `git merge side`. git refuses;
`git switch side && git rebase main`, then `git switch main && git merge side`
fast-forwards.

## Progress

- [ ] T1 sessions  · [ ] T2 panes · [ ] T3 windows · [ ] T4 copy mode · [ ] T5 surviving
- [ ] Y1 look · [ ] Y2 make · [ ] Y3 copy/move · [ ] Y4 two panels · [ ] Y5 clashes · [ ] Y6 find
- [ ] N1 find · [ ] N2 the error · [ ] N3 rename/format · [ ] N4 git · [ ] N5 yazi in nvim
- [ ] W1 start · [ ] W2 bring a file in · [ ] W3 grab an error · [ ] W4 finish
