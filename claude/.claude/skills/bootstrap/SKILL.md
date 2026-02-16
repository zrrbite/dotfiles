---
disable-model-invocation: true
description: Scaffold a new project using dotfiles bootstrap scripts
---

# /bootstrap - Scaffold a New Project

Interactive project scaffolding using the bootstrap scripts from this dotfiles repo.

## Instructions

1. Ask the user what kind of project they want to create. Offer these options:
   - **C++** - CMake project with clangd, DAP debugging, clang-tidy
   - **TypeScript (Node)** - Node.js CLI app
   - **TypeScript (Express)** - Express API server
   - **TypeScript (React)** - React app with Vite
   - **TypeScript (Next.js)** - Next.js app with App Router

2. Ask for a project name (lowercase, hyphens ok).

3. Optionally ask for a custom path (default: `~/dev/<project-name>`).

4. Run the appropriate bootstrap script:
   - **C++**: `~/dotfiles/scripts/bootstrap-cpp-project.sh <name> [path]`
   - **TypeScript**: `~/dotfiles/scripts/bootstrap-ts-project.sh <name> --framework=<node|express|react|next> [path]`

5. After the script completes, show the user:
   - What was created (directory listing)
   - Next steps (cd into project, build/install, open in editor)
   - Remind them to edit `CLAUDE.md` in the new project with their specifics

6. If `$ARGUMENTS` is provided, use it as the project name and skip asking for it. Still ask for the project type if not obvious from context.
