---
name: tidy
description: Run clang-tidy and clang-format on C++ files. Analyze warnings, fix issues, and enforce coding standards.
disable-model-invocation: true
---

# /tidy — C++ Code Quality with clang-tidy and clang-format

Run LLVM code quality tools on the current project's C++ files.

## Usage

- `/tidy` — Run clang-tidy on changed files (git diff), report and fix issues
- `/tidy all` — Run clang-tidy on all C++ source files
- `/tidy format` — Run clang-format on all C++ files (fix in place)
- `/tidy check` — Dry-run: report issues without fixing

## Workflow

1. **Detect project setup**: Look for `compile_commands.json` (check project root, `build/` dir). Warn if missing — clang-tidy works best with it.

2. **Find target files**: 
   - Default: files changed vs HEAD (`git diff --name-only HEAD` filtered to `.cpp`, `.hpp`, `.h`, `.cc`, `.cxx`)
   - With `all`: find all C++ source files in `src/`, `include/`, or project root
   - Respect `.clang-tidy` config (project-local or `~/.clang-tidy`)

3. **Run clang-tidy**:
   ```bash
   clang-tidy <files> -p <compile_commands_dir> --fix
   ```
   - If `check` mode: add `--dry-run` instead of `--fix`
   - Parse output: group by file, categorize (error vs warning vs note)
   - For each non-trivial warning: explain what the check catches and why it matters

4. **Run clang-format** (when `format` arg or after tidy fixes):
   ```bash
   clang-format -i <files>
   ```
   - Uses project `.clang-format` or `~/.clang-format`

5. **Report summary**:
   - Files checked, issues found, issues fixed
   - Any remaining issues that need manual attention
   - Suggest `git cf` (git clang-format) for staging formatted changes

## Notes

- This project's `.clang-tidy` follows Unreal Engine coding standards by default (PascalCase, no member suffix, UE prefixes)
- The global config at `~/.clang-tidy` applies when no project-local config exists
- Pre-commit hook already enforces clang-format; pre-push enforces clang-tidy
- Use `--fix` judiciously — review diffs before committing automated fixes
