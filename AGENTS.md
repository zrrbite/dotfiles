# AGENTS.md

Instructions for AI coding agents (Codex, Copilot, Cursor and others) working
in this repo. Claude Code reads `CLAUDE.md` directly; this file points every
other agent at the same material rather than repeating it.

- **Working on the repo** (its layout, stow packages, installers, hooks):
  read [`CLAUDE.md`](CLAUDE.md).
- **Setting up a machine from it** ("apply this repo"): read
  [`doc/applying-the-setup.md`](doc/applying-the-setup.md) before running
  anything. Its first section asks two questions (whose machine, which OS)
  and sends you down one path, with prerequisites, the steps only the human
  can do, and how to verify.
- **Done** on macOS/Linux means `scripts/verify.sh` exits 0; report its output
  as the result. Windows has a checklist in the same doc.

Three rules matter enough to repeat here:

1. **Don't run the installers on a machine that isn't Martin's.** They replace
   `~/.zshrc` and assume his choices. Apply packages one at a time with a
   preview instead (`stow -n -t ~`, or `stow_windows.ps1 -DryRun`), as
   `doc/applying-the-setup.md` describes.
2. **Git identity and credentials live in `~/.gitconfig.local`**, never in the
   tracked `git/.gitconfig`. Create that file before linking the `git`
   package; `scripts/seed-gitconfig-local.sh` does it from an existing config.
3. **Don't link `claude/.claude/CLAUDE.md` on a work machine.** It sends tasks
   to a personal repo. The skills alongside it are fine.

Verify changes with `scripts/lint.sh` (shellcheck plus a stow dry run).
