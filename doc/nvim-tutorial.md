# Neovim Mastery Tutorial

A progressive tutorial to level up your Neovim skills.
Work through each level, practicing until comfortable before moving on.

---

## Level 1: Movement Fundamentals

### 1.1 Vertical Movement (Master These First!)

| Key | Action |
|-----|--------|
| `Ctrl+d` | Half page DOWN |
| `Ctrl+u` | Half page UP |
| `gg` | Top of file |
| `G` | Bottom of file |
| `42G` or `:42` | Go to line 42 |

**Exercise:** Open a file with 100+ lines. Navigate using ONLY Ctrl+d/u (no arrow keys!)

### 1.2 Screen Positioning

| Key | Action |
|-----|--------|
| `zz` | Center current line |
| `zt` | Current line to top |
| `zb` | Current line to bottom |
| `H` | Jump to top of screen |
| `M` | Jump to middle of screen |
| `L` | Jump to bottom of screen |

**Exercise:** Go to line 50, then press `zt`, `zz`, `zb` to see the difference.

### 1.3 Horizontal Movement

| Key | Action |
|-----|--------|
| `0` | Start of line |
| `^` | First non-blank character |
| `$` | End of line |
| `w` | Next word |
| `b` | Back word |
| `e` | End of current word |
| `W/B/E` | Same but ignore punctuation |

**Exercise:** Navigate a line using ONLY w, b, e (no arrow keys!)

---

## Level 2: Precision Movement

### 2.1 Character Finding (Game Changer!)

| Key | Action |
|-----|--------|
| `f{char}` | Jump TO next {char} |
| `F{char}` | Jump TO previous {char} |
| `t{char}` | Jump TILL (before) next {char} |
| `T{char}` | Jump TILL previous {char} |
| `;` | Repeat last f/F/t/T forward |
| `,` | Repeat last f/F/t/T backward |

**Exercise:** On this line, use `f(` to jump to the parenthesis:
```cpp
void myFunction(int x, int y) { return x + y; }
```
Then use `;` to find the next `(` if there is one.

### 2.2 Search Movement

| Key | Action |
|-----|--------|
| `*` | Search word under cursor (forward) |
| `#` | Search word under cursor (backward) |
| `/pattern` | Search forward |
| `?pattern` | Search backward |
| `n` | Next match |
| `N` | Previous match |

**Exercise:** Put cursor on a variable name, press `*` to find all occurrences.

---

## Level 3: Text Objects (The Power of Vim!)

### 3.1 Inner vs Around

| Key | Action |
|-----|--------|
| `iw` | Inner word |
| `aw` | A word (includes space) |
| `i"` | Inner quotes |
| `a"` | Around quotes (includes quotes) |
| `i(` or `ib` | Inner parentheses |
| `a(` or `ab` | Around parentheses |
| `i{` or `iB` | Inner braces |
| `a{` or `aB` | Around braces |

### 3.2 Combining with Actions

| Command | Action |
|---------|--------|
| `diw` | Delete inner word |
| `ciw` | Change inner word |
| `yi"` | Yank (copy) inside quotes |
| `da(` | Delete around parentheses |
| `ci{` | Change inside braces |

**Exercise:** Given `"hello world"`, put cursor inside quotes and type `ci"` then type new text.

---

## Level 4: Jump List & Marks

### 4.1 Jump List (Time Travel!)

| Key | Action |
|-----|--------|
| `Ctrl+o` | Jump back (older position) |
| `Ctrl+i` | Jump forward (newer position) |
| `:jumps` | See jump history |

**Exercise:** Jump around a file (search, goto line, etc), then use Ctrl+o to retrace your steps.

### 4.2 Marks (Bookmarks)

| Key | Action |
|-----|--------|
| `ma` | Set mark 'a' at cursor |
| `'a` | Jump to line of mark 'a' |
| `` `a `` | Jump to exact position of mark 'a' |
| `''` | Jump to last position |
| `'.` | Jump to last edit |
| `:marks` | List all marks |

**Exercise:** Set a mark with `ma`, move elsewhere, then return with `'a`.

---

## Level 5: Registers & Macros

### 5.1 Registers (Multiple Clipboards!)

| Key | Action |
|-----|--------|
| `"ayy` | Yank line into register 'a' |
| `"ap` | Paste from register 'a' |
| `"Ayy` | APPEND to register 'a' |
| `"+y` | Yank to system clipboard |
| `"+p` | Paste from system clipboard |
| `:reg` | View all registers |

### 5.2 Macros (Record & Replay)

| Key | Action |
|-----|--------|
| `qa` | Start recording macro to register 'a' |
| `q` | Stop recording |
| `@a` | Play macro 'a' |
| `@@` | Replay last macro |
| `10@a` | Play macro 'a' 10 times |

**Exercise:** Record a macro that deletes a line and moves down: `qa` `dd` `j` `q`, then replay with `@a`.

---

## Level 6: LSP Navigation (Your Setup)

### 6.1 Go To Commands

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to references |
| `gI` | Go to implementation |
| `K` | Hover documentation |
| `Space+h` | Switch header/source (C++) |

### 6.2 Diagnostics

| Key | Action |
|-----|--------|
| `Space+d` | Show diagnostic at cursor |
| `Space+q` | List all diagnostics |
| `]d` | Next diagnostic |
| `[d` | Previous diagnostic |
| `Space+ca` | Code actions (fixes!) |
| `Space+cf` | Batch fix (clang-tidy) |

### 6.3 Telescope (Fuzzy Finding)

| Key | Action |
|-----|--------|
| `Space+ff` | Find files |
| `Space+fg` | Find by grep |
| `Space+fb` | Find buffers |
| `Space+fs` | Find symbols (current file) |
| `Space+fw` | Find symbols (workspace) |

---

## Level 7: Advanced Editing

### 7.1 Multi-cursor Alternative: Global Commands

```vim
:%s/old/new/g       " Replace all in file
:%s/old/new/gc      " Replace all with confirmation
:g/pattern/d        " Delete all lines matching pattern
:g/pattern/normal A; " Append ; to all matching lines
```

### 7.2 Visual Block Mode

| Key | Action |
|-----|--------|
| `Ctrl+v` | Enter visual block mode |
| `I` | Insert at start of each line |
| `A` | Append at end of each line |
| `c` | Change selected block |

**Exercise:** Select a column of text with Ctrl+v, then press `I` to insert text on all lines.

### 7.3 Useful Commands

```vim
:earlier 5m         " File state 5 minutes ago
:later 5m           " Undo the earlier
gq{motion}          " Format text (e.g., gqap for paragraph)
gu{motion}          " Lowercase
gU{motion}          " Uppercase
Ctrl+a / Ctrl+x     " Increment/decrement number
```

---

## Practice Challenges

### Challenge 1: Navigation Race
Open a 500+ line file. Get to line 250 in under 3 keystrokes.
**Solution:** `250G` or `:250` or `50%`

### Challenge 2: Surgical Editing
Change the function name without retyping parameters:
```cpp
void oldFunctionName(int x, int y, std::string z)
```
**Solution:** Put cursor on `oldFunctionName`, then `ciw` and type new name.

### Challenge 3: Multi-line Edit
Add `//` comment to lines 10-20:
**Solution:** `:10,20s/^/\/\/ /` or use visual block mode.

### Challenge 4: Find & Replace in Selection
Replace "foo" with "bar" only in a selected block:
**Solution:** Visual select, then `:s/foo/bar/g`

---

## Daily Practice Routine

1. **Disable arrow keys** (forces you to use hjkl and better motions)
2. **One new motion per day** - master it before adding another
3. **Use `.` command** - repeat last change
4. **Think in text objects** - "delete inside parentheses" not "select and delete"
5. **Watch yourself** - if doing something repetitive, there's a better way

---

## Your Specific Workflow Tips (C++/TypeScript)

### C++ Development
- `Space+h` - Toggle header/source constantly
- `Space+ca` on function declaration - Generate implementation
- `Space+cf` - Batch fix clang-tidy warnings
- `Space+fw` - Find any symbol in project
- `Space+fm` - Find macros (#define)

### TypeScript Development
- `gd` - Jump into library definitions
- `gr` - Find all usages before refactoring
- `Space+ca` - Auto-import, quick fixes
- `K` - Check types on hover

---

## Progress Tracker

- [ ] Level 1: Basic Movement
- [ ] Level 2: Precision Movement  
- [ ] Level 3: Text Objects
- [ ] Level 4: Jump List & Marks
- [ ] Level 5: Registers & Macros
- [ ] Level 6: LSP Navigation
- [ ] Level 7: Advanced Editing

**Started:** ___________
**Completed:** ___________

