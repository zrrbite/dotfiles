# tmux

How tmux is set up here, the keys that config gives you, and a one-week plan
for getting fluent with it. Config: `tmux/.tmux.conf`. The `t` command lives in
`zsh/.zshrc`, the shell config on macOS and Linux alike.

## Why use it in this setup

AeroSpace and Ghostty already split and tab windows, so tmux isn't needed for
that. Its value here is **sessions that outlive the terminal**:

- **One terminal, one session per project.** You don't need a terminal window
  per project spread across workspaces.
- **Close the window and nothing is lost.** Reopen it, run `tmux a`, and
  everything is where you left it, scrollback included.
- **SSH sessions survive a dropped connection or a closed lid.** Start tmux
  on the Pi, detach, and reattach later.

## Keys

The prefix is **`Ctrl+a`**: press it, let go, then the key. `Ctrl+a` `?`
lists every binding.

| Do | Keys |
|---|---|
| **Sessions** | |
| Session for this folder / a named one (a shell command, not a key) | `t` / `t name` |
| **Pick a project** from a fuzzy list of ~/Development, then go to (or create) its session | `Ctrl+a` `f`, or `tp` at a shell prompt |
| Same, from anywhere (Raycast, ⌥ Space) | **tmux session**, then a session name or a folder ("dotf" → `dotfiles`, found with zoxide) |
| Detach (leave it running) | `Ctrl+a` `d` |
| Reattach from a new terminal | `tmux a` (or `t name`) |
| Pick a session from a list | `Ctrl+a` `s` |
| Back to the previous session | `Ctrl+a` `Tab` |
| Previous / next session | `Ctrl+a` `⌘ ←` / `⌘ →`. Keep pressing ⌘ → to cycle without the prefix. (`Ctrl+a` `(` / `)` also work.) |
| **Panes** | |
| Split side by side / stacked | `Ctrl+a` `v` (or `\|`) / `Ctrl+a` `-`. On a Danish Mac, `\|` is ⌥ i, which AeroSpace takes, so use `v` |
| Move between panes | `Ctrl+a` `h` `j` `k` `l`, or click |
| Zoom a pane / back | `Ctrl+a` `z` |
| Resize (hold to repeat) | `Ctrl+a` `H` `J` `K` `L` |
| Close the pane | `Ctrl+a` `x` |
| **Windows** | |
| New window | `Ctrl+a` `c` |
| Jump to window 1–9 / previous / next | `Ctrl+a` `1`–`9` / `Ctrl+a` `Ctrl+h` / `Ctrl+a` `Ctrl+l` |
| Rename window | `Ctrl+a` `,` |
| Tree of every session and window | `Ctrl+a` `w` |
| **Scrollback and copying** (vi keys) | |
| Enter copy mode | `Ctrl+a` `[` |
| Move / page / search | `j` `k`, `Ctrl+u` `Ctrl+d`, `g` `G`, `/` |
| Select / copy / leave | `v` / `y` / `q`. Paste with `⌘V`. |
| **Surviving a reboot** (tmux-resurrect + tmux-continuum) | |
| Automatic | saved every 15 minutes, and restored when tmux next starts |
| Save every session now (e.g. right before a restart) | `Ctrl+a` `Ctrl+s` |
| Restore the last save by hand | `Ctrl+a` `Ctrl+r` |
| **Other** | |
| tmux command prompt | `Ctrl+a` `:` |
| Reload the config | `Ctrl+a` `r` |
| Send a literal `Ctrl+a` (line start in the shell, or an inner tmux) | `Ctrl+a` `Ctrl+a` |

Gotchas:
- **`Ctrl+a` `t` is tmux's clock, not the `t` command.** `q` leaves it.
- **Inside tmux, `Ctrl+a` no longer goes to the shell.** For line start, use
  `⌘ ←`: Ghostty and Alacritty send Home, which works in tmux.
- **Last-session isn't `Ctrl+a` `L`**, tmux's default, because `L` resizes
  here. It's `Tab`.
- **Sessions survive a reboot automatically.** They're saved every 15
  minutes, and the first tmux start afterwards restores them, so at most 15
  minutes of layout changes are lost. `Ctrl+a` `Ctrl+s` right before a
  restart loses nothing. Auto-save only runs while there's a single tmux
  server (normal use). To start truly empty, delete the saves in
  `~/.local/share/tmux/resurrect` first.
- **The status bar:**
  - left: your session, in a pill that turns **yellow while `Ctrl+a` is
    pressed**, plus **COPY** in copy mode;
  - right: all sessions (the current one bright), only when the window is
    120+ columns wide so window names keep their room, and the machine name.
- **Config changes don't reach running sessions.** Reload with `Ctrl+a` `r`.
  Terminal features such as colour need a detach and reattach as well.

## A week to get fluent

About 10–15 minutes a day, done during normal work rather than as separate
practice. **The rule all week: every time you open a terminal, type `t`
first.**

**Day 1: Sessions.**
- Make sessions for two projects you're working on.
- Mid-task, quit Ghostty entirely, reopen it and run `tmux a`.
- You've got it when you stop opening new terminal windows to switch
  projects.

**Day 2: Panes.**
- Build an editor + shell + log layout for one project.
- Zoom into the editor with `z` and back.
- Resize with `H`/`L`.
- You've got it when `z` replaces squinting at a small pane.

**Day 3: Windows.**
- Give one project three named windows (code / server / git) and move
  between them by number.
- Rule of thumb: panes for things you look at together, windows for separate
  tasks in the same project.

**Day 4: Scrollback and copying.**
- Run something with long output, enter copy mode, and search it with `/`.
- Copy a line with `v` … `y`, then paste it into another app.
- If `y` doesn't reach the macOS clipboard, that's a config bug. Report it.

**Day 5: Remote.**
- `ssh` to the Pi, run `tmux new -s pi`, start something long-running,
  detach, and close the lid.
- Later, `ssh` in again and run `tmux a`.
- With tmux on both ends, `Ctrl+a` goes to the Mac's tmux. Press
  `Ctrl+a` `Ctrl+a` to reach the Pi's.
- Update the Pi's dotfiles first ("Updating a machine" in
  `doc/applying-the-setup.md`).

**Day 6: Command line and scripting.**
- Try `Ctrl+a` `:` with `new -s scratch`, `rename-session x` and
  `kill-session`.
- From a shell: `tmux new -d -s web -c ~/some/project` creates a session
  without entering it, and `tmux send-keys -t web 'npm run dev' Enter` types
  into it.
- Write a three-line script that builds one project's layout.

**Day 7: Review and tune.**
- List the keys you actually reach for and the ones that feel clumsy, and
  change the config to fit.
- One candidate: the status bar repeats the date and time sketchybar already
  shows. That space could show the prefix being active, or the current
  command.
