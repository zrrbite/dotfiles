#!/usr/bin/env bash
# Build one or more Beamer decks with Tectonic and report only what matters:
# errors, Overfull/Underfull boxes (with their source line and size) and page count.
# Tectonic's font-substitution chatter is dropped.
#
# Usage: build-check.sh deck.tex [more.tex ...]
# Run it from the directory that holds preamble.tex.
set -uo pipefail

if [ $# -eq 0 ]; then
    echo "usage: $0 deck.tex [more.tex ...]" >&2
    exit 2
fi

status=0
for tex in "$@"; do
    pdf="${tex%.tex}.pdf"
    out=$(tectonic --chatter minimal "$tex" 2>&1)
    rc=$?
    problems=$(printf '%s\n' "$out" | grep -E -i "error|overfull|underfull" | sort -u |
        sed -E 's/^warning: [^:]*:([0-9]+): /  line \1: /')
    if [ $rc -ne 0 ]; then
        echo "$tex: BUILD FAILED"
        printf '%s\n' "$out" | tail -20
        status=1
        continue
    fi
    pages=$(pdfinfo "$pdf" 2>/dev/null | awk '/^Pages:/{print $2}')
    if [ -z "$problems" ]; then
        echo "$tex: clean, ${pages:-?} pages"
    else
        echo "$tex: ${pages:-?} pages"
        printf '%s\n' "$problems"
    fi
done
exit $status
