# Development Guide

Best practices and workflows for developing with this dotfiles repository.

## Git Workflow (Solo Development)

### Feature Branch Workflow with Linear History

For solo development, use feature branches with fast-forward-only merges to maintain a clean, linear history while keeping branch anchors:

```bash
# Create a feature branch
git checkout -b feature/add-vim-config

# Make your changes and commit
git add .
git commit -m "Add vim configuration"

# When ready to merge back to main
git checkout main
git merge --ff-only feature/add-vim-config

# If merge fails (main moved forward), rebase first:
git checkout feature/add-vim-config
git rebase main
git checkout main
git merge --ff-only feature/add-vim-config

# Clean up the branch
git branch -d feature/add-vim-config
```

**Why this workflow?**

✅ **Linear history**: No merge commits cluttering `git log`  
✅ **Branch anchors**: Feature branch names preserved in reflog and can be tagged  
✅ **Clean rebases**: Easy to rebase feature work on latest main  
✅ **Enforces sync**: `--ff-only` fails if you forgot to rebase, preventing messy merges  

**Example history:**
```
* d4f7a2c (HEAD -> main, feature/add-vim-config) Add vim keybindings
* 3b8e1f9 Add vim color scheme  
* a7c2d5e Configure vim plugins
* 9f3b7a1 Initial vim config
```

**Configure git to enforce fast-forward-only:**
```bash
# Only allow fast-forward merges on main
git config branch.main.mergeoptions "--ff-only"

# Or globally for all branches:
git config --global merge.ff only
```

## Other Git Best Practices

### Commit Messages

Use conventional commit format:

```
<type>: <short summary>

<optional detailed description>

<optional footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `chore`: Maintenance tasks
- `style`: Formatting, missing semicolons, etc.

**Example:**
```bash
git commit -m "feat: add hyprlock restart keybinding

Add Super+Shift+F3 to force restart hyprlock when it crashes.
Useful when switching workspaces after a crash."
```

### Branch Naming

Use descriptive branch names with prefixes:

- `feature/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation updates
- `chore/` - Maintenance tasks

**Examples:**
```bash
feature/add-neovim-lsp
fix/hyprlock-crash
docs/update-readme
chore/cleanup-old-configs
```

## Testing Changes

Before committing:

1. **Stow the package** to test symlinks work
2. **Reload configs** (Hyprland, bash, etc.)
3. **Verify no broken configs** (check for syntax errors)
4. **Test on a clean system** if possible (VM or separate machine)

## Merging PRs (For Collaborators)

If working with collaborators:

```bash
# Prefer rebase + merge (linear history)
git checkout main
git pull --rebase
git merge --ff-only feature-branch

# Or use GitHub's "Rebase and merge" button
```

---

**Note:** This guide focuses on solo development workflows. For team workflows, consider using pull requests with squash merges or rebase merges depending on team preference.
