---
disable-model-invocation: true
description: Fix a GitHub issue by number
---

# /fix-issue - Fix a GitHub Issue

Takes a GitHub issue number and implements a fix.

## Arguments

`$ARGUMENTS` should be a GitHub issue number (e.g., `42` or `#42`).

## Instructions

1. Strip any `#` prefix from `$ARGUMENTS` to get the issue number.

2. Run `gh issue view <number>` to read the issue title, body, and labels.

3. Analyze the issue to understand what needs to change. If the issue is unclear, summarize what you understand and ask for clarification before proceeding.

4. Read any project-level `CLAUDE.md` for build commands, architecture, and conventions.

5. Explore the relevant code to understand the current behavior.

6. Plan the fix. If it involves more than a few files, present the plan before implementing.

7. Implement the fix:
   - Follow existing code style and conventions
   - Add or update tests if the project has them
   - Keep changes minimal and focused on the issue

8. Verify the fix:
   - Build the project if applicable (check `CLAUDE.md` for build commands)
   - Run relevant tests if they exist

9. Summarize what you changed and why. Reference the issue number so it can be linked in a commit message (e.g., "Fixes #42").
