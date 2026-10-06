# zsh configuration for every Unix machine here: macOS, Arch, and Debian (the
# Pi, WSL). zsh is the login shell on all of them.
#
# What differs per OS lives in one small file, loaded first:
# .config/zsh/darwin.zsh or .config/zsh/linux.zsh, next to this file in the
# repo. Lines for one machine only go in ~/.zshrc.local, which is not tracked.
# Linux login setup (ssh-agent, Hyprland on TTY1) is zsh-linux/.zprofile.
#
# oh-my-zsh stays. No standard command is overridden: ls, cat, find and ps are
# left alone, and eza's listings are ll, lt and la.
#
# Every tool integration is guarded, because a fresh machine has none of them
# until its installer runs.

# -------------------------------------------------------------------- PATH --
# Keep $path (and therefore $PATH) free of duplicates. Without this, anything
# that re-sources this file -- a nested shell, `exec zsh` -- appends another
# copy of every entry. Set before the OS file, which adds entries too.
typeset -U path PATH

# Prepend a directory if it exists; most-specific last, so it ends up first.
# The OS file uses it too. Unset once PATH is built.
path_prepend() { [ -d "$1" ] && PATH="$1:$PATH"; }

# ----------------------------------------------------------------- OS file --
# First, because on macOS it sets up Homebrew, which supplies most of what the
# `command -v` checks below look for, and puts Homebrew's completions on fpath
# before oh-my-zsh runs compinit.
#
# Found through this file's real location (~/.zshrc is a link into the repo),
# not ~/.config/zsh, so a machine that pulled a new .zshrc but hasn't
# re-stowed still loads it.
#
# An OS file may define zsh_os_aliases. It is called after oh-my-zsh, whose own
# aliases (`d` among them) would otherwise replace the OS file's.
case "$OSTYPE" in
    darwin*) _zsh_os_file="${${(%):-%x}:A:h}/.config/zsh/darwin.zsh" ;;
    linux*)  _zsh_os_file="${${(%):-%x}:A:h}/.config/zsh/linux.zsh" ;;
    *)       _zsh_os_file="" ;;
esac
[ -n "$_zsh_os_file" ] && [ -f "$_zsh_os_file" ] && source "$_zsh_os_file"
unset _zsh_os_file

path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.local/bin"

unset -f path_prepend
export PATH

# ------------------------------------------------------------------ oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

# starship replaces the oh-my-zsh theme when present; leaving a theme set would
# have both drawing a prompt. Fall back to the previous theme if it is missing.
if command -v starship >/dev/null 2>&1; then
    ZSH_THEME=""
else
    ZSH_THEME="robbyrussell"
fi

plugins=(git)

[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# ------------------------------------------------------------------- prompt --
# Same prompt everywhere, from starship/.config/starship.toml
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# -------------------------------------------------------------------- tools --
# zoxide takes over `cd`
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"

if command -v fzf >/dev/null 2>&1; then
    # fzf 0.48+ ships its zsh integration behind --zsh. Older ones (Debian 12
    # has 0.38, Ubuntu 24.04 0.44) don't; Debian packages the same scripts as
    # examples instead. stderr is dropped because both restore the shell's
    # options when done, and a zsh without a terminal (zsh -ic from a script)
    # can't switch zle back on: "can't change option: zle". A terminal never
    # sees it.
    if _fzf_zsh="$(fzf --zsh 2>/dev/null)"; then
        eval "$_fzf_zsh" 2>/dev/null
    else
        for _f in /usr/share/doc/fzf/examples/key-bindings.zsh \
                  /usr/share/doc/fzf/examples/completion.zsh; do
            [ -f "$_f" ] && source "$_f" 2>/dev/null
        done
        unset _f
    fi
    unset _fzf_zsh

    # Nord palette
    export FZF_DEFAULT_OPTS="--color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#A3BE8C \
--color=fg:#D8DEE9,header:#A3BE8C,info:#EBCB8B,pointer:#88C0D0 \
--color=marker:#88C0D0,fg+:#ECEFF4,prompt:#88C0D0,hl+:#A3BE8C \
--color=border:#4C566A"
fi

# ------------------------------------------------------------- line editing --
# macOS-style editing keys, matching the terminal configs. Ghostty and
# Alacritty send these sequences for the shortcuts in the right-hand column;
# on a terminal that doesn't send them, they never trigger. Bound after
# oh-my-zsh and fzf, which set their own bindings and would otherwise win.
#
# Home/End arrive in several forms: \e[H / \e[F straight from the terminal,
# \eOH / \eOF in application-cursor mode, and \e[1~ / \e[4~ inside tmux,
# which re-encodes keys for its own TERM (screen-256color). Bind them all.
# Cmd-Left/Right send Home/End rather than Ctrl-A/E so they still work inside
# tmux, whose prefix is Ctrl-A.
bindkey '^[[H'  beginning-of-line    # Cmd-Left
bindkey '^[OH'  beginning-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[F'  end-of-line          # Cmd-Right
bindkey '^[OF'  end-of-line
bindkey '^[[4~' end-of-line
bindkey '^[b'   backward-word        # Option-Left
bindkey '^[f'   forward-word         # Option-Right
bindkey '^[^?'  backward-kill-word   # Option-Backspace
bindkey '^U'    backward-kill-line   # Cmd-Backspace: to line start, as in macOS
                                     # (zsh's default ^U clears the whole line)

# direnv: loads a folder's .envrc on cd and unloads it on leaving (env vars, a
# Python venv via `use venv`, see direnv/.config/direnv/direnvrc). An .envrc
# runs only after `direnv allow`, and again after each edit.
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# ---------------------------------------------------------------- ssh-agent --
# On Linux, zsh-linux/.zprofile has usually started one already, at login.
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null
fi
[ -f "$HOME/.ssh/id_ed25519" ] && ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null

# ------------------------------------------------------------------ aliases --
# Only additive ones: ls, cat, find and ps are deliberately left alone.
alias grep='grep --color=auto'

# eza listings. These replace oh-my-zsh's ll and la (plain ls -lh, ls -lAh).
if command -v eza >/dev/null 2>&1; then
    alias ll='eza -la --icons --git'
    alias lt='eza -T --icons --git-ignore'
    alias la='eza -a --icons'
fi

# fzf shortcuts: pick a file, then view or edit it.
alias fcpp='fd -e cpp -e hpp | fzf | xargs bat'                # C++ files, in bat
alias ftodo='rg -l "TODO" | fzf | xargs -o nvim'               # files with a TODO, in nvim
alias fmd='fd -e md | fzf'                                     # Markdown files
alias ffunc='rg "^function" | fzf | cut -d: -f1 | xargs bat'   # function definitions, in bat

# The OS file's aliases, now that oh-my-zsh's are in place.
if (( $+functions[zsh_os_aliases] )); then
    zsh_os_aliases
    unfunction zsh_os_aliases
fi

# ------------------------------------------------------------- files, images --
# y -- yazi, the terminal file manager (yazi/.config/yazi). Unlike plain
# `yazi`, quitting with q leaves this shell in the directory you browsed to.
# The wrapper from yazi's docs; `builtin cd` because zoxide wraps cd.
y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# chafa -- images in the terminal. In Ghostty it draws the real image (kitty
# graphics protocol), in foot as Sixel; elsewhere it falls back to coloured
# blocks.
alias chafa-ascii='chafa --format symbols --symbols ascii --colors none -s 60x20'
alias chafa-block='chafa --format symbols --symbols block -s 60x20'
# fimg -- fuzzy-find images below here, previewing each as you move
alias fimg='fd -e png -e jpg -e jpeg -e gif -e webp -e bmp -e heic | fzf --preview "chafa -s \${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES} {}"'

# ---------------------------------------------------------------------- tmux --
# t        -- tmux session named after the current directory, started in it
# t name   -- attach to session "name", creating it if it doesn't exist
# One terminal window with a session per project, instead of a terminal window
# per project spread across workspaces. Sessions outlive the window: close it,
# open a new one, `t` again.
#
# Inside tmux it switches the current client rather than nesting tmux in
# tmux. tmux forbids "." and ":" in session names, so they become "_"
# (dotfiles.git -> dotfiles_git).
t() {
    command -v tmux >/dev/null 2>&1 || { echo "t: tmux is not installed" >&2; return 1; }
    local name="${1:-${PWD:t}}"
    name="${name//[.:]/_}"
    if [ -n "$TMUX" ]; then
        tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$PWD"
        tmux switch-client -t "=$name"
    else
        tmux new-session -A -s "$name" -c "$PWD"
    fi
}
# Tab-complete existing session names.
_t() { compadd -- ${(f)"$(tmux list-sessions -F '#S' 2>/dev/null)"} }
(( $+functions[compdef] )) && compdef _t t

# tp -- project picker: fuzzy-find a folder under ~/Development (or the
# space-separated dirs in $TP_ROOTS) and open its tmux session via `t`, so
# the session gets the same name `t` would give it there. Also bound to
# prefix f in tmux, which runs this in a popup (tmux/.tmux.conf).
tp() {
    command -v fzf >/dev/null 2>&1 || { echo "tp: fzf is not installed" >&2; return 1; }
    local root dir
    dir="$(
        for root in ${=TP_ROOTS:-$HOME/Development}; do
            find "$root" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null
        done | sed "s|^$HOME/|~/|" | sort |
        fzf --reverse --prompt='project> ' --height=100% \
            --preview 'eza -1 --group-directories-first --icons=always "${HOME}/$(echo {} | cut -c3-)" 2>/dev/null || ls "${HOME}/$(echo {} | cut -c3-)"'
    )" || return 0
    ( builtin cd -- "${dir/#\~/$HOME}" && t )
}

# ------------------------------------------------------------- this machine --
# Untracked lines for one machine only: a work proxy, an SDK path. Before the
# plugins, so syntax highlighting sees anything defined here.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# ------------------------------------------------------------ zsh plugins --
# Loaded only if installed. Homebrew, pacman and apt each put them somewhere
# else: $HOMEBREW_PREFIX/share, /usr/share/zsh/plugins, /usr/share.
#   autosuggestions: the rest of a matching past command appears in grey;
#                    Right arrow or Cmd-Right (End) accepts it.
#   syntax-highlighting: commands turn green if they exist, red if not.
# syntax-highlighting must be sourced LAST, after every widget and bindkey,
# or it misses them -- keep this block at the end of the file.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#616E88'   # Nord's comment grey
for _p in zsh-autosuggestions zsh-syntax-highlighting; do
    for _d in ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share} /usr/share/zsh/plugins /usr/share; do
        if [ -f "$_d/$_p/$_p.zsh" ]; then
            source "$_d/$_p/$_p.zsh"
            break
        fi
    done
done
unset _p _d
