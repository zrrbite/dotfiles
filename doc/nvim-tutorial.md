# Neovim Mastery Tutorial

Practice these exercises directly in this file!
Open with: `nvim ~/dotfiles/doc/nvim-tutorial.md`

---

## Level 1: Movement Fundamentals

### Exercise 1.1: Vertical Movement

**Keys to learn:**
```
Ctrl+d    Half page DOWN
Ctrl+u    Half page UP
gg        Top of file
G         Bottom of file
50G       Go to line 50 (or :50)
```

**Do this now:**
1. Press `G` to go to the bottom of this file
2. Press `gg` to go back to the top
3. Press `50G` to jump to line 50
4. Press `Ctrl+d` three times to scroll down
5. Press `Ctrl+u` three times to scroll back up

✅ **Checkpoint:** You should be able to navigate without arrow keys!


### Exercise 1.2: Screen Positioning

**Keys to learn:**
```
zz    Center current line on screen
zt    Current line to TOP of screen
zb    Current line to BOTTOM of screen
H     Move cursor to HIGH (top of screen)
M     Move cursor to MIDDLE of screen
L     Move cursor to LOW (bottom of screen)
```

**Do this now:**
1. Go to line 30: `30G`
2. Center it on screen: `zz`
3. Put it at the top: `zt`
4. Put it at the bottom: `zb`
5. Now jump cursor to top of screen: `H`
6. Jump to middle: `M`
7. Jump to bottom: `L`

✅ **Checkpoint:** You understand `zz/zt/zb` moves SCREEN, `H/M/L` moves CURSOR.


### Exercise 1.3: Horizontal Movement

**Keys to learn:**
```
0     Start of line
^     First non-blank character
$     End of line
w     Next word
b     Back word
e     End of word
W/B   Next/back WORD (ignores punctuation)
```

**Practice on this line:**
```cpp
    void processUserInput(const std::string& input, int maxLength) {
```

**Do this now:**
1. Go to the line above (inside the code block)
2. Press `0` - cursor goes to column 0
3. Press `^` - cursor goes to 'v' in void (first non-blank)
4. Press `$` - cursor goes to end
5. Press `0` then `w` repeatedly - watch it jump word by word
6. Press `b` to go back word by word
7. Try `W` - it skips over `std::string` as one WORD

✅ **Checkpoint:** Never use arrow keys for horizontal movement!

---

## Level 2: Precision Movement

### Exercise 2.1: Character Finding (GAME CHANGER!)

**Keys to learn:**
```
f{char}   Find next {char} - cursor lands ON it
t{char}   Till next {char} - cursor lands BEFORE it
F{char}   Find previous {char}
T{char}   Till previous {char}
;         Repeat last f/F/t/T forward
,         Repeat last f/F/t/T backward
```

**Practice on this line:**
```cpp
void calculate(int x, int y) { return process(x) + compute(y); }
```

**Do this now:**
1. Go to start of the line above: `0`
2. Press `f(` - jumps to first `(`
3. Press `;` - jumps to next `(`
4. Press `;` - jumps to next `(`
5. Press `,` - goes back to previous `(`
6. Press `0` then `f{` - jumps to the `{`
7. Try `t)` - lands BEFORE the `)`, useful for deleting inside parens!

✅ **Checkpoint:** `f` and `;` should become your main horizontal movement!


### Exercise 2.2: Search Movement

**Keys to learn:**
```
*       Search word under cursor (forward)
#       Search word under cursor (backward)
/text   Search forward for "text"
?text   Search backward for "text"
n       Next match
N       Previous match
```

**Do this now:**
1. Put your cursor on the word "cursor" anywhere in this file
2. Press `*` - highlights ALL occurrences, jumps to next
3. Press `n` to go to next occurrence
4. Press `N` to go to previous
5. Press `#` to search backward instead
6. Try `/Exercise` then Enter - finds next "Exercise"
7. Press `n` to cycle through all Exercises

✅ **Checkpoint:** Use `*` constantly to find variable usages!

---

## Level 3: Text Objects (THE POWER OF VIM!)

### Exercise 3.1: Understanding Text Objects

**The pattern:** `{action}{a/i}{object}`
- `a` = "around" (includes delimiters)
- `i` = "inside" (excludes delimiters)

**Common objects:**
```
w     word
"     quotes
'     single quotes
(     parentheses (also `b`)
{     braces (also `B`)
[     brackets
<     angle brackets
t     XML/HTML tag
```

**Practice on this line:**
```cpp
std::string name = "Hello World";
```

**Do this now:**
1. Put cursor inside "Hello World" (on any letter)
2. Press `vi"` - visually selects inside quotes: `Hello World`
3. Press `Escape`, then `va"` - selects around quotes: `"Hello World"`
4. Press `Escape`, try `di"` - DELETES inside quotes
5. Press `u` to undo
6. Try `ci"` - CHANGES inside quotes (deletes and enters insert mode)
7. Press `Escape`, then `u` to undo

✅ **Checkpoint:** Think "delete inside quotes" = `di"`, not "select, then delete"


### Exercise 3.2: More Text Object Practice

**Practice on this function:**
```cpp
void process(std::vector<int> items) {
    for (auto& item : items) {
        std::cout << item << std::endl;
    }
}
```

**Do this now:**
1. Put cursor inside the `(std::vector<int> items)` parentheses
2. Press `di(` or `dib` - deletes everything inside parens
3. Press `u` to undo
4. Put cursor inside the `{ ... }` braces
5. Press `di{` or `diB` - deletes everything inside braces
6. Press `u` to undo
7. Try `ci(` to change the function parameters

✅ **Checkpoint:** `ci(`, `ci{`, `ci"` are your new best friends!

---

## Level 4: Jump List & Marks

### Exercise 4.1: Jump List (Time Travel!)

**Keys to learn:**
```
Ctrl+o    Jump back (older position)
Ctrl+i    Jump forward (newer position)
```

**Do this now:**
1. Go to line 1: `gg`
2. Go to line 50: `50G`
3. Go to line 100: `100G`
4. Search for "Exercise": `/Exercise` Enter
5. Now press `Ctrl+o` - goes back to line 100
6. Press `Ctrl+o` again - goes back to line 50
7. Press `Ctrl+o` again - goes back to line 1
8. Press `Ctrl+i` - goes forward again!

✅ **Checkpoint:** `Ctrl+o` is your "oops go back" button!


### Exercise 4.2: Marks (Bookmarks)

**Keys to learn:**
```
ma        Set mark 'a' at cursor position
'a        Jump to LINE of mark 'a'
`a        Jump to exact POSITION of mark 'a'
''        Jump to last position (before last jump)
'.        Jump to last edit location
:marks    List all marks
```

**Do this now:**
1. Go to line 20: `20G`
2. Set a mark: `ma` (mark 'a')
3. Go to line 80: `80G`
4. Set another mark: `mb` (mark 'b')
5. Go somewhere else: `gg`
6. Jump back to mark a: `'a`
7. Jump to mark b: `'b`
8. Type `:marks` to see your marks

✅ **Checkpoint:** Use marks for places you keep returning to!

---

## Level 5: Registers & Macros

### Exercise 5.1: Registers (Multiple Clipboards!)

**Keys to learn:**
```
"ayy      Yank (copy) line into register 'a'
"ap       Paste from register 'a'
"Ayy      APPEND to register 'a' (capital A)
"+y       Yank to system clipboard
"+p       Paste from system clipboard
:reg      View all registers
```

**Do this now:**
1. Go to any line with content
2. Press `"ayy` - yanks line to register 'a'
3. Go to another line, press `"byy` - yanks to register 'b'
4. Now paste from a: `"ap`
5. Paste from b: `"bp`
6. Type `:reg` to see all your registers

✅ **Checkpoint:** You have 26 clipboards (a-z)! Use them!


### Exercise 5.2: Macros (Record & Replay)

**Keys to learn:**
```
qa        Start recording macro into register 'a'
q         Stop recording
@a        Play macro 'a'
@@        Replay last macro
5@a       Play macro 'a' five times
```

**Practice:** Add "// TODO: " to each of these lines:
```
fix this bug
refactor this function
add error handling
write tests
update documentation
```

**Do this now:**
1. Go to "fix this bug" line
2. Start recording: `qa`
3. Go to start of line: `0`
4. Insert text: `I// TODO: ` then Escape
5. Move down: `j`
6. Stop recording: `q`
7. Now replay: `@a` (adds comment to next line)
8. Replay 3 more times: `3@a`

✅ **Checkpoint:** If you do something repetitive, record a macro!

---

## Level 6: LSP Navigation (Your Config)

### Exercise 6.1: Code Navigation

**Keys in your setup:**
```
gd          Go to definition
gD          Go to declaration
gr          Go to references
gI          Go to implementation
K           Hover documentation
Space+h     Switch header/source (C++)
```

**Do this in a real code file:**
1. Open a C++ or TypeScript file
2. Put cursor on a function call
3. Press `gd` - jumps to where it's defined
4. Press `Ctrl+o` to jump back
5. Press `gr` - shows all places it's used
6. Press `K` - shows documentation/type info


### Exercise 6.2: Diagnostics & Fixes

**Keys in your setup:**
```
Space+d     Show diagnostic at cursor
Space+q     List ALL diagnostics
]d          Jump to next diagnostic
[d          Jump to previous diagnostic
Space+ca    Code actions (fixes!)
Space+cf    Batch fix with clang-tidy (C++)
```

**Do this in a file with warnings:**
1. Open a file with clang-tidy warnings
2. Press `Space+q` to see all issues
3. Press `]d` to jump to next warning
4. Press `Space+ca` to see available fixes
5. Select a fix and press Enter
6. Or use `Space+cf` to fix everything at once

---

## Level 7: Visual Block Mode

### Exercise 7.1: Column Editing

**Keys to learn:**
```
Ctrl+v    Enter visual BLOCK mode
I         Insert at start of each line
A         Append at end of each line
c         Change selected block
d         Delete selected block
```

**Add "public: " to each of these:**
```
int x;
int y;
int z;
string name;
bool active;
```

**Do this now:**
1. Put cursor on the `i` of first `int`
2. Press `Ctrl+v` to start block selection
3. Press `4j` to extend selection down 4 lines
4. Press `I` (capital I) to insert
5. Type `public: `
6. Press `Escape` - text appears on ALL lines!

✅ **Checkpoint:** Visual block mode is amazing for column edits!

---

## Level 8: Finding Your Way Around a Codebase

The keys a developer uses all day: get to a file, search the project, jump between a symbol and its uses, and
change something everywhere. Practise in the throwaway folder from [`practice.md`](practice.md)
(`scripts/practice-folder.sh` builds `/tmp/practice`, with a small C++ project in `projects/alpha`), then in a
real repo. Every picker below is telescope: type to filter, `Enter` to open (Exercise 8.5 has the rest).

### Exercise 8.1: Find a File

**Keys in your setup:**
```
Space+ff    Find files by name (fuzzy; skips git-ignored and hidden files)
Space+fo    Recently opened files
Space+fb    Files open right now (buffers)
```

**Do this:**
1. `cd /tmp/practice && nvim .`
2. Press `Space+ff` and type `alpmain`: fuzzy matching takes letters in order, so a bit of the folder and a
   bit of the name find `projects/alpha/main.cpp`. `Enter` opens it.
3. Open `util.cpp` the same way, then `Space+fb` to switch back to `main.cpp`.
4. Quit nvim, start it again, and press `Space+fo`: the files you just had open are at the top.

### Exercise 8.2: Search the Whole Project

**Keys in your setup:**
```
Space+fg    Live grep: results update as you type (ripgrep, so a regex works)
Space+fc    Grep the word under the cursor
Space+/     Fuzzy search inside this file only
Space+fr    Reopen the last search, with its text and position
*  / #      Next / previous match of the word, this file only (Level 2)
```

**Do this:**
1. `Space+fg`, type `Total`: every line in the project that says it, with a preview. `Enter` on one.
2. `Space+fg` again, type `Scale\(`: a regex, so you get the calls and the declaration, not the comment.
3. In `main.cpp`, put the cursor on `Add` and press `Space+fc`: everything that says `Add`, no typing.
4. `Space+/`, type `Doub`: matches in this file only.
5. Close the picker (`Esc` `Esc`), then `Space+fr`: the same search comes back where you left it.

### Exercise 8.3: Symbols - Jump to a Function by Name

**Keys in your setup:**
```
Space+fs    Symbols in this file (functions, classes, variables), from the language server
Space+fw    Symbols across the project: type part of a name
gO          This file's outline, in the location list (built into Neovim)
```

**Do this:**
1. In `util.cpp`, `Space+fs`: `Add` and `Scale`. `Enter` on `Scale` jumps to it.
2. `Space+fw`, type `Sca`: `Scale`, wherever the language server has seen it.
3. `gO`: the same outline as a list under the file. `Enter` on a line jumps; `:lclose` closes it.

clangd indexes a whole project when it has a `compile_commands.json` (CMake writes one with
`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`). Without it, as in the practice folder, `Space+fw` knows only the files
you have opened.

### Exercise 8.4: Who Uses This? Definitions and References

**Keys in your setup:**
```
gd / gD     Go to the definition / declaration
gr          All references, in the quickfix list
gI          Go to the implementation
Space+D     Go to the type's definition
]q / [q     Next / previous entry in the quickfix list
:copen      Show the quickfix list (:cclose hides it)
Ctrl+o      Back where you came from (repeat it)
```

**Do this:**
1. In `main.cpp`, cursor on `Scale`, press `gd`: you land on `Scale` in `util.cpp` (or its declaration in
   `util.h`). `Ctrl+o` comes back.
2. Open `util.h`, cursor on `Scale`, press `gr`: its uses go into the quickfix list, which opens below.
3. `]q` steps to the next use, `[q` back. `:copen` shows them all; `Enter` on a line jumps there.
4. `Ctrl+o` a few times walks back through everywhere you jumped.

### Exercise 8.5: Inside Any Picker

**Keys while a picker is open** (you are typing in it):
```
Ctrl+n / Ctrl+p       Next / previous result
Enter                 Open it here
Ctrl+v / Ctrl+x       Open it in a side-by-side / stacked split
Ctrl+t                Open it in a new tab
Ctrl+u / Ctrl+d       Scroll the preview up / down
Ctrl+q                Send ALL results to the quickfix list
Ctrl+/                Show the picker's keys
Esc Esc               Close (the first Esc stops typing; then ? also shows the keys)
```

**Do this:**
1. `Space+fg`, type `Total`, `Ctrl+n` to the second result, `Ctrl+v`: it opens beside the file you had.
2. `Space+fr`, then `Ctrl+q`: every result is now in the quickfix list. `]q` walks them.

`Alt+q` (send only the results you marked with `Tab`) needs Option to act as Alt, which this Ghostty setup
leaves off for the Danish layout. Narrow the search instead, then `Ctrl+q`.

### Exercise 8.6: Change Something Everywhere

**Keys in your setup:**
```
Space+rn                      Rename a symbol, in every file the language server knows
Space+ca                      Code actions: the language server's fixes and refactors
:cdo s/old/new/g | update     A substitution on every quickfix entry, saving each file
```

**Do this:**
1. Rename a symbol: in `main.cpp`, cursor on `Total`, `Space+rn`, type `Sum`, `Enter`. Every use changes,
   and only that variable: the word `Total` inside the string stays.
2. Change text everywhere: `Space+fg`, type `Doubled`, `Ctrl+q`, then
   `:cdo s/Doubled/Twice/g | update`. Each listed line is changed and its file saved.
3. In a shell, `git -C /tmp/practice diff` shows both changes.
   `scripts/practice-folder.sh --fresh` puts everything back.

Use `Space+rn` for code: it knows scope, so a local variable and a function of the same name stay apart. Use
`:cdo` for plain text: comments, strings, docs.

### Exercise 8.7: Every Error at Once

**Keys in your setup:**
```
Space+fd    Diagnostics in every open file, searchable
Space+q     This file's diagnostics in the location list
]d / [d     Next / previous diagnostic in this file
```

**Do this:**
1. Open `main.cpp` and `util.cpp`. `main.cpp` has the `Scale` error, unless you fixed it in drill N2
   (`--fresh` brings it back).
2. `Space+fd`: the error is listed, with the file. `Enter` jumps to it, and `Space+d` reads it.

✅ **Checkpoint:** You can reach any file, line, symbol, or use of a symbol in a few keys, without the tree.

---

## Quick Reference Card

### Movement
```
Ctrl+d/u     Half page down/up
gg / G       Top / bottom of file
50G          Go to line 50
zz           Center screen on cursor
H / M / L    Top / middle / bottom of screen
w / b / e    Word forward / back / end
f{c} / ;     Find char / repeat
* / #        Search word under cursor
```

### Editing
```
ciw          Change inner word
ci" ci( ci{  Change inside quotes/parens/braces
diw di" di(  Delete inside
yiw yi" yi(  Yank inside
.            Repeat last change
```

### Navigation
```
Ctrl+o / Ctrl+i  Jump back / forward
gd               Go to definition
gr               Go to references (quickfix list)
]q / [q          Next / previous quickfix entry
```

### Finding (Level 8)
```
Space+ff / fo / fb   Files: by name / recent / open now
Space+fg / fc        Grep the project / the word under the cursor
Space+/              Search this file
Space+fs / fw        Symbols: this file / the project
Space+fd             Diagnostics in open files
Space+fr             Reopen the last search
In a picker          Ctrl+v/x/t split or tab, Ctrl+q all to quickfix
```

---

## Progress Tracker

- [ ] Level 1: Movement Fundamentals
- [ ] Level 2: Precision Movement (f/;)
- [ ] Level 3: Text Objects (ci"/di{)
- [ ] Level 4: Jump List & Marks
- [ ] Level 5: Registers & Macros
- [ ] Level 6: LSP Navigation
- [ ] Level 7: Visual Block Mode
- [ ] Level 8: Finding Your Way Around a Codebase

**Date Started:** ___________
**Date Completed:** ___________

---

## Daily Practice Tips

1. **Disable arrow keys** - forces better habits
2. **One motion per day** - master before adding more
3. **Use `.` command** - repeats last change
4. **Think in text objects** - "change inside parens" not "select then type"
5. **Record repetitive tasks** - macros save time
6. **Use `*` constantly** - find all occurrences instantly

---

*Tutorial created with Claude Code. Happy Vimming!* 🚀
