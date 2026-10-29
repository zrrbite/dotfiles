#!/usr/bin/env bash
# Lay a deck's pages out N-up on large sheets and render them to PNG, for a fast visual
# pass over a whole deck (overflow, collisions, empty or crowded slides) in a few images.
# Dense slides still need a full-size look: pdftoppm -r 100 -f N -l N deck.pdf out/p
#
# Usage: contact-sheet.sh deck.pdf outdir [cols] [rows]   (default 5 x 5)
# Needs tectonic (pdfpages comes from its bundle) and pdftoppm (poppler).
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "usage: $0 deck.pdf outdir [cols] [rows]" >&2
    exit 2
fi

deck=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
outdir=$2
cols=${3:-5}
rows=${4:-5}
name=$(basename "$deck" .pdf)

mkdir -p "$outdir"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cp "$deck" "$work/deck.pdf"
cat > "$work/sheet.tex" <<EOF
\documentclass{article}
\usepackage[paperwidth=$((cols * 8))cm,paperheight=$((rows * 9 / 2))cm,margin=0pt]{geometry}
\usepackage{pdfpages}
\begin{document}
\includepdf[pages=-,nup=${cols}x${rows},frame,delta=3 3]{deck.pdf}
\end{document}
EOF

(cd "$work" && tectonic --chatter minimal sheet.tex >/dev/null 2>&1) || {
    echo "contact sheet build failed" >&2
    exit 1
}
pdftoppm -r 100 -png "$work/sheet.pdf" "$outdir/$name-sheet"
ls "$outdir"/"$name"-sheet*.png
