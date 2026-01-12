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

(Future documentation goes here)
