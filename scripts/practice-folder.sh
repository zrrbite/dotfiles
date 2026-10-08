#!/usr/bin/env bash
#
# Build a throwaway folder for the drills in doc/practice.md: notes, a
# Markdown guide, two images, a hidden file, and a small C++ project in git
# with one modified and one untracked file (so yazi and nvim show git signs,
# and clangd has an error to find). Everything in it is safe to wreck.
#
# Usage: scripts/practice-folder.sh [--fresh] [DIR]    (DIR: /tmp/practice)
#   --fresh  delete DIR and build it again, but only if this script made it
#
# .git/practice-folder marks a folder as ours, so --fresh never deletes
# anything else.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FRESH=false
if [ "${1:-}" = "--fresh" ]; then FRESH=true; shift; fi
DIR="${1:-/tmp/practice}"

if [ -e "$DIR" ]; then
    if [ ! -f "$DIR/.git/practice-folder" ]; then
        echo "$DIR exists and this script didn't make it; leaving it alone." >&2
        exit 1
    elif [ "$FRESH" = true ]; then
        rm -rf "$DIR"
    else
        echo "$DIR already exists. To build it again: $0 --fresh $DIR" >&2
        exit 1
    fi
fi

mkdir -p "$DIR"/notes/archive "$DIR"/photos "$DIR"/projects/alpha "$DIR"/projects/beta
cd "$DIR"

for i in $(seq 1 12); do echo "Note $i" > "notes/note$i.txt"; done
echo "Old notes from 2025" > notes/archive/2025.txt
cp "$DOTFILES_DIR/doc/yazi.md" notes/guide.md   # Markdown, for the rendered preview
cp "$DOTFILES_DIR/hypr/.local/share/wallpapers/arch-minimalist.png" photos/
cp "$DOTFILES_DIR/hypr/.local/share/wallpapers/arch.jpg" photos/
echo "API_KEY=changeme" > .env-example
echo "Beta" > projects/beta/beta.txt

# The C++ project, in the dotfiles' clang-format style so `Space F` and the
# pre-commit hook leave it alone.
cp "$DOTFILES_DIR/clang/.clang-format" projects/alpha/
cat > projects/alpha/README.md <<'EOF'
# alpha

A tiny C++ project to practise nvim's LSP keys on. `util.h` and `util.cpp`
are a header/source pair (`Space h` switches between them).
EOF
cat > projects/alpha/util.h <<'EOF'
#pragma once

int Add(int A, int B);
int Scale(int Value, int Factor);
EOF
cat > projects/alpha/util.cpp <<'EOF'
#include "util.h"

int Add(int A, int B)
{
	return A + B;
}

int Scale(int Value, int Factor)
{
	return Value * Factor;
}
EOF
cat > projects/alpha/main.cpp <<'EOF'
#include <iostream>

#include "util.h"

int main()
{
	const int Total = Add(2, 3);
	std::cout << "Total: " << Total << '\n';
	return 0;
}
EOF

git init -q -b main
git add -A
git -c user.name=practice -c user.email=practice@localhost commit -q -m "Practice project"
touch .git/practice-folder

# After the commit: one modified file (with an error for clangd to flag) and
# one untracked file.
cat > projects/alpha/main.cpp <<'EOF'
#include <iostream>

#include "util.h"

int main()
{
	const int Total = Add(2, 3);
	std::cout << "Total: " << Total << '\n';

	// clangd flags the next line: Scale takes two arguments.
	const int Doubled = Scale(Total);
	std::cout << "Doubled: " << Doubled << '\n';
	return 0;
}
EOF
echo "- [ ] fix the Scale call in main.cpp" > projects/alpha/todo.txt

echo "Practice folder ready: $DIR"
echo "Drills: $DOTFILES_DIR/doc/practice.md"
