---
disable-model-invocation: true
description: Code review the current diff for bugs, security issues, and style
---

# /review - Code Review

Review the current changes for bugs, security issues, and style violations.

## Instructions

1. Run `git diff` to see unstaged changes. If empty, run `git diff --cached` for staged changes. If both empty, run `git diff HEAD~1` for the last commit.

2. Read any project-level `CLAUDE.md` or `.clang-tidy` for project-specific style rules.

3. Review the diff for:
   - **Bugs**: Logic errors, off-by-one, null/undefined access, resource leaks, race conditions
   - **Security**: Injection (SQL, command, XSS), hardcoded secrets, buffer overflows, unsafe deserialization
   - **Style**: Naming conventions, formatting, dead code, overly complex logic
   - **Best practices**: Error handling, missing tests for new logic, API misuse

4. Present findings grouped by severity:
   - **Critical**: Must fix before merge (bugs, security)
   - **Warning**: Should fix (style, best practices)
   - **Nit**: Optional improvements

5. For each finding, include:
   - File and line number
   - What the issue is
   - A suggested fix (code snippet if helpful)

6. If the diff is clean, say so briefly. Don't invent issues.
