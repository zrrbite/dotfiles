# TypeScript Workflow Documentation

Complete guide to the TypeScript development workflow with quality gates.

## Overview

The TypeScript workflow uses **three automated quality gates** that prevent broken code from being committed or pushed:

1. **Prettier** (Pre-commit) - Formatting
2. **TypeScript Compiler** (Pre-push) - Type checking
3. **ESLint** (Pre-push) - Code quality

## The Three Quality Gates

### Gate 1: Prettier (Pre-commit Hook) 🎨

**When it runs:** Every `git commit`

**Location:** `git/.git-hooks/pre-commit-ts`

**What it does:**
1. Gets all staged `.ts`, `.tsx`, `.js`, `.jsx` files
2. Runs `prettier --check` on each file
3. **Blocks commit** if any file isn't formatted correctly

**Configuration:** `typescript/.prettierrc`

```json
{
  "semi": true,              // Semicolons required
  "singleQuote": true,       // 'single' not "double"
  "printWidth": 100,         // Max line length
  "tabWidth": 2,             // 2-space indentation
  "useTabs": false,          // Spaces, not tabs
  "arrowParens": "always",   // (x) => not x =>
  "endOfLine": "lf"          // Unix line endings
}
```

**Example violations:**

```typescript
// ❌ Prettier rejects:
import React from "react";              // Double quotes
const [count,setCount]=useState(0);     // No spacing

// ✅ Prettier accepts:
import React from 'react';              // Single quotes
const [count, setCount] = useState(0);  // Proper spacing
```

**How to fix:**
```bash
npm run format         # Auto-format all files
git add .              # Re-stage formatted files
git commit             # Try again
```

**Bypass (not recommended):**
```bash
git commit --no-verify
```

---

### Gate 2: TypeScript Compiler (Pre-push Hook) 🔍

**When it runs:** Every `git push`

**Location:** `git/.git-hooks/pre-push-ts`

**What it does:**
1. Checks if `tsconfig.json` exists (skips if not a TS project)
2. Runs `tsc --noEmit` (type-check without building)
3. **Blocks push** if any type errors exist

**Configuration:** `typescript/tsconfig.json`

**Strict mode settings:**
- `"strict": true` - All strict type checks enabled
- `"noUnusedLocals": true` - No unused variables
- `"noUnusedParameters": true` - No unused function parameters
- `"noUncheckedIndexedAccess": true` - Array access returns `T | undefined`
- `"exactOptionalPropertyTypes": true` - Strict optional properties
- `"noImplicitReturns": true` - All code paths must return
- `"noFallthroughCasesInSwitch": true` - No fallthrough in switch

**Example violations:**

```typescript
// ❌ TypeScript rejects:
const handleClick = (e) => {        // Implicit 'any' type
  console.log(e);
};

let x: number = 'hello';            // Type mismatch

function process(data) {            // Missing param type
  return data.value;                // Unchecked property access
}

// ✅ TypeScript accepts:
const handleClick = (e: MouseEvent): void => {
  console.log(e);
};

let x: number = 42;

function process(data: { value: string }): string {
  return data.value;
}
```

**How to fix:**
```bash
npm run type-check     # See all type errors
# Fix the errors in your code
git push              # Try again
```

**Bypass (not recommended):**
```bash
git push --no-verify
```

---

### Gate 3: ESLint (Pre-push Hook) ⚡

**When it runs:** Every `git push` (after TypeScript check)

**Location:** `git/.git-hooks/pre-push-ts`

**What it does:**
1. Runs `npm run lint` (executes `eslint . --ext ts,tsx`)
2. **Blocks push** if any errors exist
3. Allows warnings but shows them

**Configuration:** `typescript/.eslintrc.json`

**Base configurations:**
```json
"extends": [
  "eslint:recommended",                                    // Standard JS rules
  "plugin:@typescript-eslint/recommended",                 // TS-specific rules
  "plugin:@typescript-eslint/recommended-requiring-type-checking", // Type-aware
  "prettier"                                               // Disable format rules
]
```

**Custom rules:**

#### Error-level rules (block push):

1. **`@typescript-eslint/no-unused-vars`** - No unused variables
   - Exception: Variables starting with `_` (e.g., `_unusedParam`)

2. **`@typescript-eslint/no-explicit-any`** - No `any` types
   - Must use explicit types everywhere

3. **`@typescript-eslint/no-floating-promises`** - Must handle promises
   - Async calls must be awaited or have `.catch()`

#### Warning-level rules (don't block, but shown):

1. **`@typescript-eslint/explicit-function-return-type`** - Function return types
   - Functions should specify `: void`, `: string`, `: JSX.Element`, etc.

2. **`no-console`** - Console usage
   - `console.log()` warns
   - `console.warn()` and `console.error()` allowed

**Example violations:**

```typescript
// ❌ ESLint errors (block push):
const Counter = () => {              // Missing return type (warning)
  return <div>...</div>;
};

async function fetchData() {
  fetch('/api/data');                // Floating promise (error)
}

const x: any = 5;                    // Explicit 'any' (error)

const unused = 42;                   // Unused variable (error)

// ❌ ESLint warnings (shown but don't block):
function greet(name: string) {       // Missing return type
  console.log(name);                 // console.log usage
}

// ✅ ESLint passes:
const Counter = (): JSX.Element => {
  return <div>...</div>;
};

async function fetchData(): Promise<void> {
  await fetch('/api/data');
}

const x: number = 5;

const _unused = 42;  // Prefix with _ if intentionally unused

function greet(name: string): void {
  console.warn(name);  // Use warn/error instead of log
}
```

**How to fix:**

```bash
npm run lint           # See all linting issues
npm run lint -- --fix  # Auto-fix some issues
# Manually fix remaining issues
git push              # Try again
```

---

## How They Work Together

### The Commit/Push Flow

```bash
# 1. Write code
vim src/Counter.tsx

# 2. Stage changes
git add src/Counter.tsx

# 3. Try to commit
git commit -m "Add counter"
# → Pre-commit hook runs automatically:
#   - Checks Prettier formatting on staged files
#   - If fails: ❌ Commit blocked, shows violations
#   - If passes: ✅ Commit succeeds

# 4. Fix formatting if needed
npm run format
git add .
git commit -m "Add counter"

# 5. Try to push
git push
# → Pre-push hook runs automatically:
#   Step 1: TypeScript type-checks entire project
#   - If fails: ❌ Push blocked, shows type errors
#
#   Step 2: ESLint lints entire project
#   - If fails: ❌ Push blocked, shows lint errors
#
#   - If both pass: ✅ Push succeeds
```

### Why Two Stages?

**Pre-commit (Fast):**
- Only checks **staged files**
- Prettier is very fast (~10-50ms per file)
- Quick feedback loop for formatting
- Runs on every commit

**Pre-push (Thorough):**
- Checks **entire project**
- TypeScript needs to analyze dependencies
- ESLint checks all rules across files
- Slower but more comprehensive
- Only runs when pushing (less frequent)

This two-stage approach balances **fast feedback** (commit) with **thorough validation** (push).

---

## Comparison to C++ Gates

| Feature | C++ | TypeScript |
|---------|-----|------------|
| **Formatting** | clang-format | Prettier |
| **Static Analysis** | clang-tidy | ESLint |
| **Type Checking** | Built into compiler | Separate `tsc` step |
| **Pre-commit** | clang-format on staged | Prettier on staged |
| **Pre-push** | clang-tidy on changed | tsc + ESLint on all |
| **Auto-fix** | `git cf` | `npm run format` |
| **Config files** | `.clang-format`, `.clang-tidy` | `.prettierrc`, `.eslintrc.json`, `tsconfig.json` |

**Key difference:**

TypeScript has **three separate tools** (Prettier/tsc/ESLint) vs C++ has **two** (clang-format/clang-tidy), because:
- **Prettier** = Pure formatting (like clang-format)
- **TypeScript** = Type safety (built into C++ compiler)
- **ESLint** = Code quality (like clang-tidy)

In C++, `clang-tidy` does both static analysis AND some style checking. In TypeScript, these are separate concerns with specialized tools.

---

## Workflow Philosophy

### Separation of Concerns

1. **Prettier** = How code looks (formatting, style)
2. **TypeScript** = Type correctness (safety, bugs)
3. **ESLint** = Best practices (patterns, quality)

Each tool has one job and does it well.

### Progressive Enhancement

- **Basic:** Just Prettier → Consistent formatting
- **Better:** + TypeScript → Type safety prevents bugs
- **Best:** + ESLint → Catch code smells, enforce patterns

You can start with just Prettier and add the others as your project matures.

### Fail Fast

- Catch formatting issues at **commit time** (seconds after writing)
- Catch type/quality issues at **push time** (before code review)
- Never let broken code reach CI/CD or production

---

## Real-World Example

Let's trace a bad commit through all three gates:

### Step 1: Write bad code

```typescript
import React from "react";  // ❌ Double quotes

const Counter = () => {     // ❌ No return type
  const [count,setCount]=useState(0);  // ❌ Bad spacing

  const handleClick = (e) => {  // ❌ Implicit any
    setCount(count + 1);
  };

  console.log(count);  // ❌ console.log

  return <div>...</div>;
};
```

### Step 2: Try to commit

```bash
$ git add src/Counter.tsx
$ git commit -m "Add counter"

Checking TypeScript/JavaScript code formatting...
  ✗ src/Counter.tsx needs formatting

╔════════════════════════════════════════════════════════╗
║   CODE FORMATTING VIOLATIONS DETECTED!                ║
╚════════════════════════════════════════════════════════╝

How to fix:
  npm run format         # Format all files
  git add .              # Re-stage formatted files
  git commit             # Try again
```

**❌ Commit blocked by Gate 1 (Prettier)**

### Step 3: Fix formatting

```bash
$ npm run format
src/Counter.tsx 17ms

$ git add src/Counter.tsx
$ git commit -m "Add counter"
✓ All TypeScript/JavaScript files properly formatted
[main abc123] Add counter
```

**✅ Gate 1 passed, commit succeeds**

### Step 4: Try to push

```bash
$ git push

Running pre-push checks...
  → Type checking with tsc...

╔════════════════════════════════════════════════════════╗
║   TYPE ERRORS DETECTED!                               ║
╚════════════════════════════════════════════════════════╝

src/Counter.tsx(8,24): error TS7006:
  Parameter 'e' implicitly has an 'any' type.

Fix type errors before pushing.
```

**❌ Push blocked by Gate 2 (TypeScript)**

### Step 5: Fix type errors

```typescript
const handleClick = (): void => {  // Add return type, remove param
  setCount(count + 1);
};
```

```bash
$ git add src/Counter.tsx
$ git commit -m "Fix type errors"
$ git push

Running pre-push checks...
  → Type checking with tsc...
  ✓ Type checking passed
  → Linting with ESLint...

╔════════════════════════════════════════════════════════╗
║   LINT ERRORS DETECTED!                               ║
╚════════════════════════════════════════════════════════╝

src/Counter.tsx
  3:7  warning  Missing return type  @typescript-eslint/explicit-function-return-type
  11:3  warning  Unexpected console statement  no-console
```

**❌ Push blocked by Gate 3 (ESLint)** - Warnings shown but in this case there would be errors

### Step 6: Fix ESLint issues

```typescript
import React from 'react';

const Counter = (): JSX.Element => {  // ✅ Add return type
  const [count, setCount] = useState(0);

  const handleClick = (): void => {
    setCount(count + 1);
  };

  // ✅ Removed console.log

  return <div>...</div>;
};
```

```bash
$ git add src/Counter.tsx
$ git commit -m "Fix ESLint warnings"
$ git push

Running pre-push checks...
  → Type checking with tsc...
  ✓ Type checking passed
  → Linting with ESLint...
  ✓ Linting passed

✓ All pre-push checks passed. Proceeding with push...

Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
To github.com:user/repo.git
   abc123..def456  main -> main
```

**✅ All gates passed, push succeeds!**

---

## Quick Reference

### Common Commands

```bash
# Check what's wrong
npm run type-check      # TypeScript type errors
npm run lint            # ESLint issues
npx prettier --check .  # Prettier formatting issues

# Fix issues
npm run format          # Auto-fix Prettier
npm run lint -- --fix   # Auto-fix some ESLint issues
# Type errors must be fixed manually

# Bypass (not recommended)
git commit --no-verify  # Skip pre-commit hook
git push --no-verify    # Skip pre-push hook
```

### File Locations

```
dotfiles/
├── typescript/               # Stow package
│   ├── .eslintrc.json       # ESLint config
│   ├── .prettierrc          # Prettier config
│   ├── .prettierignore      # Files to skip
│   └── tsconfig.json        # TypeScript config
├── git/.git-hooks/
│   ├── pre-commit-ts        # Prettier gate
│   └── pre-push-ts          # TypeScript + ESLint gates
└── scripts/
    └── bootstrap-ts-project.sh  # Creates new TS projects
```

### Bootstrap a New Project

```bash
# Node.js CLI app
~/dotfiles/scripts/bootstrap-ts-project.sh my-app --framework=node

# Express API
~/dotfiles/scripts/bootstrap-ts-project.sh my-api --framework=express

# React app (Vite)
~/dotfiles/scripts/bootstrap-ts-project.sh my-web --framework=react

# Next.js app
~/dotfiles/scripts/bootstrap-ts-project.sh my-site --framework=next
```

All frameworks include:
- ✅ Strict TypeScript config
- ✅ ESLint + Prettier configured
- ✅ Git hooks installed automatically
- ✅ CLAUDE.md with project context
- ✅ .nvim.lua with DAP debugging ready

---

## Troubleshooting

### Hook not running

**Problem:** Git hook doesn't execute

**Solution:**
```bash
# Check if hooks are executable
ls -la .git/hooks/pre-commit .git/hooks/pre-push

# Make them executable
chmod +x .git/hooks/pre-commit .git/hooks/pre-push
```

### "prettier: command not found"

**Problem:** Prettier not installed

**Solution:**
```bash
# Install locally in project
npm install

# Or install globally
npm install -g prettier
```

### ESLint parsing errors

**Problem:** `ESLint was configured to run on ... however that TSConfig does not include this file`

**Solution:** Update `.eslintrc.json`:
```json
{
  "parserOptions": {
    "project": ["./tsconfig.json", "./tsconfig.node.json"]
  }
}
```

### Hooks running on non-TS projects

**Problem:** Pre-push hook tries to run on non-TypeScript projects

**Solution:** The hook automatically detects `tsconfig.json` and skips if not found. If it's still running incorrectly, check the hook script.

---

## Why This Works

### You Can't Push Broken Code

The three gates ensure:
- ✅ **Consistent formatting** across the entire team
- ✅ **Type safety** prevents runtime errors
- ✅ **Best practices** enforced automatically

No manual checking required. No code review comments about formatting. No "I'll fix it later."

### Time Savings

**Before quality gates:**
- 30-60 min: Manual code review finding formatting issues
- 15-30 min: Debugging type errors in production
- 20-40 min: Refactoring to fix code smells

**With quality gates:**
- 0 min: Formatting auto-fixed
- 0 min: Type errors caught before push
- 0 min: Code smells caught by ESLint

**Result:** 65-130 minutes saved per project, plus fewer bugs in production.

---

## Learn More

- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [ESLint Rules](https://eslint.org/docs/rules/)
- [Prettier Options](https://prettier.io/docs/en/options.html)
- [TypeScript ESLint](https://typescript-eslint.io/)

---

**Created with Claude Code**
