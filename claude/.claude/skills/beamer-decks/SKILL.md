---
name: beamer-decks
description: Build LaTeX Beamer slide decks as PDFs in Martin's house style — Metropolis theme with a visible progress bar, Fira Sans, built with Tectonic, one idea per slide with assertion titles, a practical takeaway box, a source line on every slide, status flags for uncertain claims, and bulleted source lists — then verify every page visually before calling it done. Use this whenever the user asks for Beamer, LaTeX slides, a PDF slide deck, "presentations" or "decks" made from a repo's notes or docs, or wants existing .tex slides restyled, refit or extended, even if they don't say "Beamer". Not for claude.ai Slides artifacts or .pptx files.
---

# Beamer decks

Decks that summarise a body of material (a repo's chapters, notes, research) for a
specific audience, built reproducibly from `.tex` and checked page by page. The house style
came out of the sourdough-science decks (`zrrbite/sourdough-science`, `slides/`), which are
the worked example to look at when in doubt.

## Setup

- **Engine: Tectonic** (`brew install tectonic`; on Linux the release binary or the distro
  package). It is one small binary that fetches only the packages a deck uses, which is why
  it is preferred over a TeX Live install. The first build downloads packages; later ones
  are cached.
- **pdftoppm** (poppler) for rendering pages to images, and **pdfinfo** for page counts.
- Copy from this skill into the project's deck directory (usually `slides/`):
  - `assets/preamble.tex` — the shared look and macros. One per project; decks `\input` it.
  - `assets/Makefile` — `make` builds every `NN-name.tex`; decks are numbered.
  - `assets/deck-template.tex` — a skeleton showing every pattern below. Copy it to
    `01-name.tex` and replace the content.
- Set `\renewcommand{\takeawaylabel}{...}` in the preamble to suit the audience ("In the
  kitchen" for bakers, "In practice", "For the team").
- **Check that PDFs can be committed.** A global gitignore often drops `*.pdf`
  (`git check-ignore -v slides/x.pdf`). If the README links the PDFs, add `!slides/*.pdf` to
  the repo's `.gitignore`.

## Content rules

The decks are derived from source material, so faithfulness comes first:

- **Ground every claim in the sources.** Simplify the wording, never the strength of a claim.
  Copy numbers exactly (temperatures, doses, ratios, years).
- **Carry the source's uncertainty.** Wherever the material marks something as a
  hypothesis, contested, untested or the author's own result, put the matching flag on the
  slide: `\hypothesis`, `\contested`, `\untested`, `\ownresult`. A deck that drops these
  overstates its sources. Define extra flags locally with `\flagtag{flag}{not peer-reviewed}`.
- **Cite on the slide.** `\source{Author (year); ...}` as the last thing in each frame
  whose claims come from literature.
- **When the sources contradict each other, don't resolve it silently.** Pick the more
  authoritative one for the slide, and report the contradiction (file:line) to the user.
  Summarising a whole body of material side by side reliably surfaces these, and they are
  worth more than the deck.
- **Say in the README that the decks are derived**: where a deck and its source disagree,
  the source wins.

## Slide style

- **One idea per slide, and the title states it.** "Feeding at peak protects the yeast",
  not "Feeding". A reader skimming titles alone should get the argument.
- **At most about five bullets**, short phrases, no paragraphs. Metropolis's title bar
  leaves less room than the default theme, so budget for it.
- **`\takeaway{...}`** for the practical consequence, when the slide has one. One line is
  better than two.
- **Tables** when the source compares things, **TikZ diagrams** for sequences, causes and
  timelines. Recreate a source's mermaid or other diagrams in TikZ, simplified if needed.
- **Structure:** title frame; a "What this deck covers" slide listing the practical
  questions answered (and a key to the flags); a `\section` per topic (Metropolis draws the
  section pages); a "Takeaways" slide of 5–7 bullets; an "Open questions" slide; the
  Sources.
- **Sources slide:** an `[allowframebreaks]` frame with `\srcgroup{...}` headings and a
  `sourcelist` of `\src{Author (year)}{Title. \emph{Journal} vol:pages.}` entries. One
  source per bullet, author and year in bold, continuing onto "(cont.)" slides rather than
  shrinking the type. Never a two-column block of run-on text.

## LaTeX traps (each one cost a rebuild cycle)

- **A brace group right after `\begin{frame}{Title}` is read as a frame subtitle** and
  silently disappears. `{\small \begin{tabularx}...}` loses the whole table. Use the
  `tablebox` environment, `\begingroup ... \endgroup`, or start the frame with text.
- **Beamer's itemize resets the font size**, so `\scriptsize\begin{itemize}` does nothing.
  Set it with `\setbeamerfont{itemize/enumerate body}{size=...}` inside a group, as
  `sourcelist` does.
- **Coloured text on the dark title bar is unreadable.** That is why the flags are filled
  tags; keep any new flag in that style.
- **Unicode works** (XeTeX under Tectonic): °C → × ≥ ≈ ₂ ¹⁰ – —. Still escape `% & # _ $`,
  and `~` is a non-breaking space, not "approximately"; write ≈.
- **`\centering` in a frame also centres the `\source` line.** Wrap a diagram in a
  `center` environment instead.
- **TikZ labels:** keep them outside boxes and off lines (`node[pos=0.2,right]`, or an
  explicit `\node at (x,y)`), and give `minimum width` to boxes that should line up.
- **`--chatter minimal` still prints font-substitution noise.** `scripts/build-check.sh`
  filters it and keeps only errors and box warnings.

## Verify before calling it done

Overflow in Beamer is often silent on the page and only a warning in the log, and a clean
log does not mean a good-looking slide. So:

1. **Build and read the warnings.** `scripts/build-check.sh 01-name.tex` (run from the
   deck directory). Fix every error and every Overfull `\vbox`/`\hbox` above about 1 pt.
   An overfull vbox means the slide runs into the footer.
2. **Look at every page.** `pdftoppm -r 80 -png deck.pdf <scratch>/p`, then read each image.
   Check that nothing touches the footer, the source line clears it, nothing is clipped or
   overlapping, diagram labels don't collide, and no slide is near-empty or crammed.
   Render to a scratch directory, never into the repo.
3. **For a whole deck, or after a theme change, use contact sheets.**
   `scripts/contact-sheet.sh deck.pdf <scratch>/sheets` lays 25 slides on one image, so a
   35-page deck is two images. Then look at dense slides at full size.
4. Fix, rebuild, look again. A preamble change touches every deck: rebuild all of them and
   re-check.

## Several decks at once

One deck per part of the material, written in parallel by one agent each, works well. The
lead owns `preamble.tex` and the Makefile; the agents edit only their own deck and add any
local styles after `\input{preamble}`. Give each agent the content rules, the slide style,
the traps and the verification loop above, its source files, the audience, a target slide
count, and its own scratch directory for renders. Ask it to report its page count and any
contradictions it found in the sources (file:line), not to fix them. If the preamble
changes while they work, tell every running agent to rebuild and re-check, since their
layouts move.
