# Documentation & Presentations

This directory contains documentation and presentations about the dotfiles and development workflow.

## Presentations

### Claude Code Presentation

**File:** `claude-code-presentation.tex`

A Beamer presentation (using Metropolis theme) about Claude Code and how it improves C++ development workflow.

**Topics covered:**
- What is Claude Code?
- Workflow improvements (bootstrap scripts, CLAUDE.md)
- Automated code quality (git hooks)
- Cross-platform dotfiles
- Unreal Engine development
- Real-world productivity gains

**Building the presentation:**

```bash
# Install dependencies (Arch Linux)
sudo pacman -S texlive-most texlive-fontsextra

# Build the PDF
make

# Or manually:
pdflatex claude-code-presentation.tex
pdflatex claude-code-presentation.tex  # Run twice for TOC

# View the PDF
make view

# Clean auxiliary files
make clean
```

**Requirements:**
- LaTeX distribution (TeX Live recommended)
- Metropolis Beamer theme
- fontawesome5 package

**Customization:**
- Edit title page (lines 23-27) with your name/institution
- Adjust content as needed for your audience
- Add/remove sections based on presentation length

## Other Documentation

### Window managers

- **[tiling-window-managers.md](tiling-window-managers.md)** — cross-platform
  comparison of tiling window managers and what this repo ships.
- **[hyprland.md](hyprland.md)** — the Linux setup: `SUPER`-based keybindings,
  the dwindle layout, and why this config does *not* match the other two.
- **Arch + Hyprland installation guide** — lives in the archinstall repo:
  [arch-hyprland-guide.md](https://github.com/zrrbite/archinstall/blob/main/doc/arch-hyprland-guide.md). This repo keeps only a pointer.
- **[aerospace-macos.md](aerospace-macos.md)** — using the tiling window manager
  on macOS: keybindings, layouts, and the gotchas (accordion, restarts losing
  window placement, where focus-follows-mouse actually comes from).
- **[glazewm.md](glazewm.md)** — the Windows setup: keybindings mirroring
  AeroSpace, the window rules that keep Office and games out of the tiler, and
  the `alt-r` binding reserved for PowerToys Run.
- **[status-bar-theming.md](status-bar-theming.md)** — the Nord colour contract
  shared by waybar and sketchybar, sketchybar's constraints versus waybar CSS,
  and how to add or restyle a module.

### Setting up a machine

- **[tools.md](tools.md)** — every tool this repo installs, what it's for,
  and which OS has it. The one-page answer to "what's on this machine?".
- **[applying-the-setup.md](applying-the-setup.md)** — for an AI agent (or a
  person) applying this repo to a new machine, especially a work one: what to
  check first, which packages are safe, and why `git` and `claude/CLAUDE.md`
  must not be applied as-is.
- **[Arch + Hyprland install guide](https://github.com/zrrbite/archinstall/blob/main/doc/arch-hyprland-guide.md)** (archinstall repo) — see above.

### Editors and workflow

- **[tmux.md](tmux.md)** — why tmux is worth it alongside AeroSpace and
  Ghostty, every key this config gives you, and a one-week plan for getting
  fluent.
- **[lazygit.md](lazygit.md)** — the git UI on trial: panels, staging by
  line, tidying commits before a push (fixup, reword, reorder), and seven
  practice steps. Opens from tmux (`Ctrl+a` `g`) and nvim (`Space` `g` `g`).
- **[nvim-tutorial.md](nvim-tutorial.md)** — Neovim setup walkthrough.
- **[vscode.md](vscode.md)** — default VS Code shortcuts on all three
  platforms. Note that this repo does not manage VS Code configuration.
- **[TYPESCRIPT_WORKFLOW.md](TYPESCRIPT_WORKFLOW.md)** — TypeScript project
  workflow and quality gates.

---

Quick-reference tables covering all of the above, plus links to reference
material in other repos, live in
**[zrrbite/cheatsheets](https://github.com/zrrbite/cheatsheets)**.
