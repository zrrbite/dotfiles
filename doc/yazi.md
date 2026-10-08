# yazi

A cheat sheet for yazi, the terminal file manager, in the order you use it to
copy and move files between folders. Then a practice plan. Config:
`yazi/.config/yazi/`. Every key here was checked against yazi 26.9.1's own
keymap (`yazi-config/preset/keymap-default.toml` in its repo); keys were
renamed between releases, so check again after a big upgrade. This setup's
own additions (`g D`, `g .`, `g T`, `Tab`, `i`) are in `keymap.toml`.

## The one idea: choose, mark, go, paste

It's vim's yank and paste, applied to files:

1. **Choose** the file under the cursor, or several with `Space` or `v`.
2. **Mark** them: `y` to copy, `x` to move. The selection turns into a
   copy mark (moves show red). Nothing has changed on disk yet.
3. **Go** to the destination folder.
4. **Paste:** `p`. Only now are files copied or moved.

Every early surprise is step 2: the selection "disappears" because it became
a mark, and `x` turns files red without deleting anything.

## Start and quit

| Do | Keys |
|---|---|
| Start here / start, and leave the shell where you quit | `yazi` / `y` |
| Quit (with `y`: the shell lands in yazi's folder) | `q` |
| Quit, the shell stays put | `Q` |
| Close this tab, or quit if it's the last | `Ctrl+c` |
| Every key | `F1` (`fn+F1` on a laptop), or `~` |

yazi works well in its own Ghostty window, outside tmux: put that window on a
workspace of its own (`⌃⌥⇧ 5`) and reach it with `⌃⌥ 5`.

## Get around

| Do | Keys |
|---|---|
| Up a folder / down / up / into | `h` `j` `k` `l` |
| Open the file | `Enter` or `o` |
| Scroll the preview | `J` / `K` |
| Show / hide dotfiles (shown by default here) | `.` |
| A folder you use often, by name (zoxide) | `Z`, type part of the name, `Enter` |
| A file or folder anywhere below here (fzf) | `z` |
| Narrow this folder's list as you type (`Esc` clears) | `f` |
| Bookmarks: ~/Development / the dotfiles / the todo repo | `g` `D` / `g` `.` / `g` `T` |
| Home / Downloads / `~/.config` / type a path | `g` `h` / `g` `d` / `g` `c` / `g` `Space` |
| The hovered file's details (size, dates, type) | `i` |
| Search names / contents below here (fd / ripgrep) | `s` / `S` |

## Choose files

| Do | Keys |
|---|---|
| Select or unselect this file (then moves down a line) | `Space` |
| Select a range: start, move, done | `v`, `j`/`k`, `Esc` |
| Unselect a range | `V`, `j`/`k`, `Esc` |
| Select all / invert | `Ctrl+a` / `Ctrl+r` |
| **Clear the selection** | `Esc` (from `v` or `V`: twice, once to leave the mode) |

With nothing selected, the next command acts on the file under the cursor.
With a selection, it acts on the selection only, not on the cursor's file.

## Copy and move

| Do | Keys |
|---|---|
| Mark to copy / to move | `y` / `x` |
| Cancel the mark | `Y` or `X` |
| Paste here. A name that exists gets `_1`, never overwritten | `p` |
| Paste, overwriting what's there | `P` |
| Paste a symlink instead (absolute / relative path) | `-` / `_` |
| Progress of a big copy (it runs in the background) | `w` |

**Between two folders, use two tabs,** like Far's two panels: `t` `t`
clones the current folder into a new tab, `Z` or a `g` bookmark takes it to
the destination, and **`Tab`** flips between the tabs (`1`–`9` jump to one).
Mark in one, `Tab`, paste. `t` `r` names a tab.

**Or two yazi windows side by side:** open a second Ghostty window with
yazi, and AeroSpace tiles the two. A `y` in one and a `p` in the other works,
because yazi shares copy marks between instances here (`sync_yanked` in
`init.lua`).

## Create, rename, delete

| Do | Keys |
|---|---|
| New file / new folder (end with `/`; `a/b/` makes both) | `a` |
| Rename (the cursor starts before the extension) | `r` |
| To the Trash, so it can be recovered | `d` |
| Delete permanently | `D` |

In a name box, `Enter` confirms. It's vi-style: the first `Esc` switches to
normal mode, the second cancels.

## Copy a path to the clipboard

`c` then: `c` full path, `d` its folder's path, `f` file name, `n` name
without extension.

## In nvim

`Space` `-` opens yazi at the current file, `Space` `_` at the project root.
Pick a file and it opens in nvim.

## On the Danish Mac layout

- `~` is a dead key (⌥ ¨, then Space). `F1` opens the same key list.
- `[` / `]` (previous / next tab) are ⌥ 8 / ⌥ 9. They work since AeroSpace
  moved to ⌃⌥, but the number keys are quicker.

## Practice: seven steps

In a throwaway folder (a git repo with some notes, two images and a project
with a modified and an untracked file), one step at a time:

1. **Moving and previews:** `h j k l`, an image, a rendered `.md` (`J`/`K`),
   `.`, the git signs, `F1`.
2. **Create and rename:** a folder `drafts/`, a file inside it, nested
   `archive/2026/`, rename a note with `r`.
3. **Copy and move in one tree:** select three notes, `y`, paste them into
   another folder; cut two with `x` and move them; cancel a mark with `Y`.
4. **Between two tabs:** `t` `t`, `Z` or `g` `D` to the destination, copy
   across with `Tab`. Then the same with two yazi windows side by side.
5. **Clashes and links:** paste the same file twice (`_1`), `P` to
   overwrite, `-` for a symlink, `w` during a copy.
6. **Delete:** `d`, then find it in the Trash; `D` on something you don't
   need.
7. **Finding what to copy:** `f` to narrow a folder, `z` to find a file,
   `c` `c` to copy its path, yazi from nvim with `Space` `-`.

You've got it when moving three files from one project into another takes
one `Z`, a few `Space`s, `x` and `p`, without thinking about the keys.
