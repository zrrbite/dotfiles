# VS Code shortcuts

Default keybindings worth knowing, on all three platforms.

**This repo does not manage VS Code.** Unlike `nvim/`, `hypr/` and `glazewm/`,
there is no `vscode/` stow package — `settings.json` lives only in the local
profile and there is no `keybindings.json` at all. So everything below is
stock, not personal configuration. If VS Code ever becomes a primary editor,
adding a stow package is the first step; until then this is a reference for the
defaults you get on a fresh install.

`⌘` Command · `⌥` Option/Alt · `⇧` Shift · `⌃` Control

## Command palette and quick open

| Action | macOS | Windows / Linux |
|---|---|---|
| Command palette | `⇧⌘P` or `F1` | `Ctrl+Shift+P` or `F1` |
| Quick open file | `⌘P` | `Ctrl+P` |
| Go to line | `⌃G` | `Ctrl+G` |
| Go to symbol in file | `⇧⌘O` | `Ctrl+Shift+O` |
| Go to symbol in workspace | `⌘T` | `Ctrl+T` |
| Settings | `⌘,` | `Ctrl+,` |
| Keyboard shortcuts | `⌘K ⌘S` | `Ctrl+K Ctrl+S` |

Quick open takes more than filenames: prefix with `>` for commands, `@` for
symbols in the current file, `#` for workspace symbols, `:` for a line number.
Learning that one box replaces about half the shortcuts below.

## Navigation

| Action | macOS | Windows / Linux |
|---|---|---|
| Go to definition | `F12` | `F12` |
| Peek definition | `⌥F12` | `Alt+F12` |
| Go to references | `⇧F12` | `Shift+F12` |
| Go to implementation | `⌘F12` | `Ctrl+F12` |
| Go back / forward | `⌃-` / `⌃⇧-` | `Alt+←` / `Alt+→` |
| Show hover | `⌘K ⌘I` | `Ctrl+K Ctrl+I` |
| Jump to matching bracket | `⇧⌘\` | `Ctrl+Shift+\` |
| Problems panel | `⇧⌘M` | `Ctrl+Shift+M` |
| Next / previous problem | `F8` / `⇧F8` | `F8` / `Shift+F8` |

## Editing

| Action | macOS | Windows / Linux |
|---|---|---|
| Move line up / down | `⌥↑` / `⌥↓` | `Alt+↑` / `Alt+↓` |
| Copy line up / down | `⇧⌥↑` / `⇧⌥↓` | `Shift+Alt+↑` / `Shift+Alt+↓` |
| Delete line | `⇧⌘K` | `Ctrl+Shift+K` |
| Insert line below / above | `⌘Enter` / `⇧⌘Enter` | `Ctrl+Enter` / `Ctrl+Shift+Enter` |
| Toggle line comment | `⌘/` | `Ctrl+/` |
| Toggle block comment | `⇧⌥A` | `Shift+Alt+A` |
| Indent / outdent | `⌘]` / `⌘[` | `Ctrl+]` / `Ctrl+[` |
| Expand / shrink selection | `⌃⇧⌘→` / `⌃⇧⌘←` | `Shift+Alt+→` / `Shift+Alt+←` |
| Rename symbol | `F2` | `F2` |
| Quick fix | `⌘.` | `Ctrl+.` |
| Format document | `⇧⌥F` | `Shift+Alt+F` |

## Multiple cursors

| Action | macOS | Windows / Linux |
|---|---|---|
| Add cursor above / below | `⌥⌘↑` / `⌥⌘↓` | `Ctrl+Alt+↑` / `Ctrl+Alt+↓` |
| Add cursor at next match | `⌘D` | `Ctrl+D` |
| Select all occurrences | `⇧⌘L` | `Ctrl+Shift+L` |
| Add cursor by click | `⌥`+click | `Alt`+click |
| Column (box) selection | `⇧⌥`+drag | `Shift+Alt`+drag |

`⌘D` repeatedly is the one to internalise — it is the everyday replacement for a
regex replace, and `⌘K ⌘D` skips an unwanted match.

## Search

| Action | macOS | Windows / Linux |
|---|---|---|
| Find | `⌘F` | `Ctrl+F` |
| Replace | `⌥⌘F` | `Ctrl+H` |
| Find in files | `⇧⌘F` | `Ctrl+Shift+F` |
| Replace in files | `⇧⌘H` | `Ctrl+Shift+H` |
| Find next / previous | `⌘G` / `⇧⌘G` | `F3` / `Shift+F3` |

## Files, tabs and layout

| Action | macOS | Windows / Linux |
|---|---|---|
| Save / save all | `⌘S` / `⌥⌘S` | `Ctrl+S` / `Ctrl+K S` |
| Close editor | `⌘W` | `Ctrl+W` |
| Reopen closed editor | `⇧⌘T` | `Ctrl+Shift+T` |
| Next / previous editor | `⌥⌘→` / `⌥⌘←` | `Ctrl+PgDn` / `Ctrl+PgUp` |
| Split editor | `⌘\` | `Ctrl+\` |
| Focus editor group 1/2/3 | `⌘1` / `⌘2` / `⌘3` | `Ctrl+1` / `Ctrl+2` / `Ctrl+3` |
| Toggle sidebar | `⌘B` | `Ctrl+B` |
| Toggle panel | `⌘J` | `Ctrl+J` |
| Zen mode | `⌘K Z` | `Ctrl+K Z` |

Sidebar views: `⇧⌘E` explorer, `⇧⌘F` search, `⌃⇧G` source control, `⇧⌘D` debug,
`⇧⌘X` extensions.

## Terminal

| Action | macOS | Windows / Linux |
|---|---|---|
| Toggle terminal | ``⌃` `` | ``Ctrl+` `` |
| New terminal | ``⌃⇧` `` | ``Ctrl+Shift+` `` |
| Split terminal | `⌘\` | `Ctrl+Shift+5` |

## Debugging

| Action | All platforms |
|---|---|
| Start / continue | `F5` |
| Stop | `⇧F5` / `Shift+F5` |
| Step over | `F10` |
| Step into | `F11` |
| Step out | `⇧F11` / `Shift+F11` |
| Toggle breakpoint | `F9` |

These match the nvim DAP bindings in `nvim/.config/nvim/lua/plugins/init.lua`,
which were chosen to line up with them.

## Coming from nvim

There is no vim extension installed. If that changes, `vscodevim.vim` is the
usual choice, and the two settings that matter most are
`"vim.useSystemClipboard": true` and remapping `jk` to escape in
`vim.insertModeKeyBindings`.

## References

- [Official keyboard shortcut reference](https://code.visualstudio.com/docs/getstarted/keybindings) —
  printable PDFs per platform, and the authority when this page is wrong
- [Key bindings reference](https://code.visualstudio.com/docs/getstarted/keybindings#_keyboard-shortcuts-reference)
