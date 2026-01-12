# Makefile for building LaTeX Beamer presentations

# Default target
all: presentation

# Build the presentation
presentation: claude-code-presentation.tex
	pdflatex claude-code-presentation.tex
	pdflatex claude-code-presentation.tex  # Run twice for TOC

# Clean auxiliary files
clean:
	rm -f *.aux *.log *.nav *.out *.snm *.toc *.vrb

# Clean everything including PDF
distclean: clean
	rm -f *.pdf

# Open the PDF (Linux)
view: presentation
	xdg-open claude-code-presentation.pdf

# Continuous build (requires latexmk)
watch:
	latexmk -pvc -pdf claude-code-presentation.tex

.PHONY: all presentation clean distclean view watch
