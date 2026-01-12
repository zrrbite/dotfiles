#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage
if [ $# -lt 1 ]; then
    echo "Usage: $0 <project-name> [--framework=react|node|next|express]"
    echo "Example: $0 my-app --framework=react"
    exit 1
fi

PROJECT_NAME=$1
FRAMEWORK="node"  # default

# Parse framework option
for arg in "$@"; do
    case $arg in
        --framework=*)
            FRAMEWORK="${arg#*=}"
            shift
            ;;
    esac
done

# Validate framework
case $FRAMEWORK in
    react|node|next|express)
        ;;
    *)
        echo -e "${RED}Error: Invalid framework '$FRAMEWORK'${NC}"
        echo "Valid options: react, node, next, express"
        exit 1
        ;;
esac

# Project directory
PROJECT_DIR="$HOME/dev/$PROJECT_NAME"

echo -e "${BLUE}[INFO] Creating TypeScript project: $PROJECT_NAME${NC}"
echo -e "${BLUE}[INFO] Framework: $FRAMEWORK${NC}"
echo -e "${BLUE}[INFO] Location: $PROJECT_DIR${NC}"

# Create project directory
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create directory structure
mkdir -p src
mkdir -p tests

echo -e "${GREEN}[INFO] Created directory structure${NC}"

# Copy TypeScript configs from dotfiles
cp ~/dotfiles/typescript/tsconfig.json .
cp ~/dotfiles/typescript/.eslintrc.json .
cp ~/dotfiles/typescript/.prettierrc .
cp ~/dotfiles/typescript/.prettierignore .

# Create .gitignore
cat > .gitignore << 'EOF'
node_modules/
dist/
build/
coverage/
*.log
.env
.env.local
.DS_Store
EOF

# Create package.json based on framework
case $FRAMEWORK in
    react)
        cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx",
    "format": "prettier --write .",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "@vitejs/plugin-react": "^4.0.0",
    "eslint": "^8.45.0",
    "eslint-config-prettier": "^9.0.0",
    "prettier": "^3.0.0",
    "typescript": "^5.0.0",
    "vite": "^5.0.0"
  }
}
EOF
        # Create vite.config.ts
        cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
});
EOF
        # Create src/main.tsx
        cat > src/main.tsx << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root') as HTMLElement);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF
        # Create src/App.tsx
        cat > src/App.tsx << 'EOF'
import React from 'react';

const App: React.FC = () => {
  return (
    <div>
      <h1>Hello from React + TypeScript!</h1>
      <p>Project: PROJECT_NAME</p>
    </div>
  );
};

export default App;
EOF
        sed -i "s/PROJECT_NAME/$PROJECT_NAME/g" src/App.tsx
        # Create index.html
        cat > index.html << EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$PROJECT_NAME</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF
        # Update tsconfig for React
        cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowImportingTsExtensions": true,
    "noEmit": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF
        # Create tsconfig.node.json for Vite config
        cat > tsconfig.node.json << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOF
        ;;

    node|express)
        cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/main.ts",
    "build": "tsc",
    "start": "node dist/main.js",
    "lint": "eslint . --ext ts",
    "format": "prettier --write .",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.0",
    "@types/node": "^20.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.45.0",
    "eslint-config-prettier": "^9.0.0",
    "prettier": "^3.0.0",
    "tsx": "^4.0.0",
    "typescript": "^5.0.0"
  }
}
EOF
        # Create src/main.ts
        if [ "$FRAMEWORK" = "express" ]; then
            cat > src/main.ts << 'EOF'
import express, { Request, Response } from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (_req: Request, res: Response): void => {
  res.json({ message: 'Hello from Express + TypeScript!' });
});

app.listen(PORT, (): void => {
  console.log(`Server running on http://localhost:${PORT}`);
});
EOF
        else
            cat > src/main.ts << 'EOF'
const greet = (name: string): string => {
  return `Hello, ${name}!`;
};

console.log(greet('TypeScript'));
EOF
        fi
        # Update tsconfig for Node.js
        cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "outDir": "./dist",
    "rootDir": "./src",
    "resolveJsonModule": true,
    "declaration": true,
    "sourceMap": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
        ;;

    next)
        cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "format": "prettier --write .",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.45.0",
    "eslint-config-next": "^14.0.0",
    "eslint-config-prettier": "^9.0.0",
    "prettier": "^3.0.0",
    "typescript": "^5.0.0"
  }
}
EOF
        mkdir -p app
        cat > app/page.tsx << EOF
export default function Home(): JSX.Element {
  return (
    <main>
      <h1>Hello from Next.js + TypeScript!</h1>
      <p>Project: $PROJECT_NAME</p>
    </main>
  );
}
EOF
        cat > app/layout.tsx << 'EOF'
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'TypeScript Next.js App',
  description: 'Created with bootstrap-ts-project.sh',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}): JSX.Element {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
EOF
        cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
};

module.exports = nextConfig;
EOF
        # Update tsconfig for Next.js
        cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "jsx": "preserve",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowJs": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF
        ;;
esac

# Create CLAUDE.md
cat > CLAUDE.md << EOF
# $PROJECT_NAME

## Overview
TypeScript project created with bootstrap-ts-project.sh

**Framework**: $FRAMEWORK

## Commands

\`\`\`bash
npm install          # Install dependencies
npm run dev          # Start development server
npm run build        # Build for production
npm run lint         # Run ESLint
npm run format       # Format with Prettier
npm run type-check   # Type check without emitting files
\`\`\`

## Architecture

- **TypeScript**: Strict mode enabled, no implicit any
- **ESLint**: Enforces code quality
- **Prettier**: Consistent formatting
- **Project structure**:
  - \`src/\` - Source files
  - \`tests/\` - Test files
  - \`dist/\` - Build output (gitignored)

## Git Hooks

- **Pre-commit**: Runs Prettier on staged files
- **Pre-push**: Type checks and lints all files

## Development Workflow

1. Make changes in \`src/\`
2. Git will auto-format on commit
3. Push will fail if type errors or lint issues exist
4. Fix issues, then push again

## Neovim Integration

- LSP: \`ts_ls\` provides autocomplete, go-to-definition, refactoring
- DAP: F5 to debug, breakpoints with Space+b
- Format: Space+F to format file

## Notes

- Add any project-specific notes here
- Update this file as the project evolves
EOF

# Create .nvim.lua for project-local Neovim config
cat > .nvim.lua << 'EOF'
-- Project-local Neovim configuration
-- This file is automatically loaded when opening this project

-- DAP configuration for this specific project
local dap = require('dap')

-- Customize debug configuration if needed
-- Example: Set specific environment variables, change ports, etc.
EOF

echo -e "${GREEN}[INFO]   ✓ tsconfig.json${NC}"
echo -e "${GREEN}[INFO]   ✓ .eslintrc.json${NC}"
echo -e "${GREEN}[INFO]   ✓ .prettierrc${NC}"
echo -e "${GREEN}[INFO]   ✓ package.json${NC}"
echo -e "${GREEN}[INFO]   ✓ CLAUDE.md${NC}"
echo -e "${GREEN}[INFO]   ✓ .nvim.lua (DAP config)${NC}"
echo -e "${GREEN}[INFO]   ✓ src/main.${FRAMEWORK:0:1}${NC}"

# Initialize git repository
git init
echo -e "${GREEN}[INFO]   ✓ Git repository initialized${NC}"

# Set up git hooks (copy from dotfiles)
mkdir -p .git/hooks
cp ~/dotfiles/git/.git-hooks/pre-commit-ts .git/hooks/pre-commit
cp ~/dotfiles/git/.git-hooks/pre-push-ts .git/hooks/pre-push
chmod +x .git/hooks/pre-commit .git/hooks/pre-push
echo -e "${GREEN}[INFO]   ✓ Git hooks installed${NC}"

echo ""
echo -e "${GREEN}✓ Project created successfully!${NC}"
echo ""
echo -e "Next steps:"
echo -e "  ${BLUE}cd $PROJECT_DIR${NC}"
echo -e "  ${BLUE}npm install${NC}"
echo -e "  ${BLUE}npm run dev${NC}"
echo ""
