#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <project-name> [project-path]"
    echo ""
    echo "Examples:"
    echo "  $0 my-renderer               # Creates ~/dev/my-renderer"
    echo "  $0 my-renderer ~/projects    # Creates ~/projects/my-renderer"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_DIR="${2:-$HOME/dev}/$PROJECT_NAME"

# Get dotfiles directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$DOTFILES_DIR/templates/cpp-project"

# Check if project already exists
if [ -d "$PROJECT_DIR" ]; then
    warn "Directory $PROJECT_DIR already exists!"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

info "Creating C++ project: $PROJECT_NAME"
info "Location: $PROJECT_DIR"

# Create directory structure
mkdir -p "$PROJECT_DIR"/{src,include,tests,doc,build}

info "Created directory structure"

# Copy templates
info "Copying configuration templates..."

# Copy CLAUDE.md template
if [ -f "$TEMPLATE_DIR/CLAUDE.md.template" ]; then
    sed "s/PROJECT_NAME/$PROJECT_NAME/g" "$TEMPLATE_DIR/CLAUDE.md.template" > "$PROJECT_DIR/CLAUDE.md"
    info "  ✓ CLAUDE.md"
fi

# Copy .clangd
if [ -f "$TEMPLATE_DIR/.clangd" ]; then
    cp "$TEMPLATE_DIR/.clangd" "$PROJECT_DIR/.clangd"
    info "  ✓ .clangd"
fi

# Copy CMakeLists.txt template
if [ -f "$TEMPLATE_DIR/CMakeLists.txt.template" ]; then
    sed "s/PROJECT_NAME/$PROJECT_NAME/g" "$TEMPLATE_DIR/CMakeLists.txt.template" > "$PROJECT_DIR/CMakeLists.txt"
    info "  ✓ CMakeLists.txt"
fi

# Copy .nvim.lua template
if [ -f "$TEMPLATE_DIR/.nvim.lua.template" ]; then
    sed "s/PROJECT_NAME/$PROJECT_NAME/g" "$TEMPLATE_DIR/.nvim.lua.template" > "$PROJECT_DIR/.nvim.lua"
    info "  ✓ .nvim.lua (debug configs)"
fi

# Create minimal source files
cat > "$PROJECT_DIR/src/main.cpp" << 'EOF'
#include <iostream>

int main(int argc, char* argv[])
{
    std::cout << "Hello from PROJECT_NAME!" << std::endl;
    return 0;
}
EOF
sed -i "s/PROJECT_NAME/$PROJECT_NAME/g" "$PROJECT_DIR/src/main.cpp"
info "  ✓ src/main.cpp"

cat > "$PROJECT_DIR/include/${PROJECT_NAME}.h" << 'EOF'
#ifndef PROJECT_NAME_H
#define PROJECT_NAME_H

// Add your headers here

#endif // PROJECT_NAME_H
EOF
sed -i "s/PROJECT_NAME/${PROJECT_NAME^^}/g" "$PROJECT_DIR/include/${PROJECT_NAME}.h"
info "  ✓ include/${PROJECT_NAME}.h"

# Create README
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

## Build

\`\`\`bash
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build -j8
\`\`\`

## Run

\`\`\`bash
./build/bin/$PROJECT_NAME
\`\`\`

## Development

See \`CLAUDE.md\` for development workflow and architecture notes.
EOF
info "  ✓ README.md"

# Create .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Build artifacts
build/
*.o
*.a
*.so
*.dylib

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Compiled binaries
bin/
lib/

# CMake
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
compile_commands.json

# OS
.DS_Store
Thumbs.db
EOF
info "  ✓ .gitignore"

# Initialize git repository
cd "$PROJECT_DIR"
git init
git add .
git commit -m "Initial commit: Bootstrap $PROJECT_NAME

Created with bootstrap-cpp-project.sh

🤖 Generated with Claude Code"

info ""
info "✓ Project created successfully!"
info ""
echo "Next steps:"
echo "  1. cd $PROJECT_DIR"
echo "  2. Edit CLAUDE.md with project details"
echo "  3. cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
echo "  4. cmake --build build"
echo "  5. nvim .  # Opens project with debug configs ready"
echo ""
echo "The project includes:"
echo "  - CLAUDE.md for Claude Code context"
echo "  - .clangd for LSP configuration"
echo "  - .nvim.lua for debug configurations"
echo "  - CMakeLists.txt with compile_commands.json export"
echo "  - Git repository initialized"
echo ""
