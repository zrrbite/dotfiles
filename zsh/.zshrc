# zsh configuration for macOS.
#
# zsh is the login shell here, so this file -- not bash/.bashrc-darwin -- is
# what actually runs. Kept deliberately close to the previous hand-written
# ~/.zshrc: oh-my-zsh stays, and the aggressive bash aliases that override ls,
# cat, find and ps are intentionally NOT ported.
#
# Every tool integration is guarded, because a fresh macOS install has none of
# them until `./install_darwin.sh` runs.

# ---------------------------------------------------------------- Homebrew --
# Must come before anything that checks `command -v`, since Homebrew supplies
# most of those binaries.
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# -------------------------------------------------------------------- PATH --
# One place, most-specific last so it ends up first. This replaces three
# overlapping exports, one of which hardcoded the entire system PATH along with
# an absolute /Users/<name> path, and another which added ~/.local/bin twice.
# Keep $path (and therefore $PATH) free of duplicates. Without this, anything
# that re-sources this file -- a nested shell, `exec zsh` -- appends another
# copy of every entry below.
typeset -U path PATH

path_prepend() { [ -d "$1" ] && PATH="$1:$PATH"; }

path_prepend "/usr/local/share/dotnet"
path_prepend "$HOME/.dotnet/tools"
path_prepend "/Library/Frameworks/Mono.framework/Versions/Current/Commands"
path_prepend "/opt/homebrew/opt/llvm/bin"
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
# Same prompt as Arch and Windows, from starship/.config/starship.toml
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# -------------------------------------------------------------------- tools --
# zoxide takes over `cd`, matching .bashrc-darwin
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"

if command -v fzf >/dev/null 2>&1; then
    # fzf 0.48+ ships shell integration behind --zsh
    eval "$(fzf --zsh)" 2>/dev/null

    # Nord palette, matching the bash config
    export FZF_DEFAULT_OPTS="--color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#A3BE8C \
--color=fg:#D8DEE9,header:#A3BE8C,info:#EBCB8B,pointer:#88C0D0 \
--color=marker:#88C0D0,fg+:#ECEFF4,prompt:#88C0D0,hl+:#A3BE8C \
--color=border:#4C566A"
fi

# ------------------------------------------------------------- line editing --
# macOS-style editing keys, matching the terminal configs. Ghostty and
# Alacritty send these sequences for the shortcuts in the right-hand column.
# Bound after oh-my-zsh and fzf, which set their own bindings and would
# otherwise win.
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
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null
fi
[ -f "$HOME/.ssh/id_ed25519" ] && ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null

# ------------------------------------------------------------------ aliases --
# Only additive ones. ls, cat, find and ps are deliberately left alone.
alias grep='grep --color=auto'

# The roast console. --usb is baked in because that is the only mode worth a
# shortcut; --demo and --replay are typed deliberately.
#
# DO NOT wrap this in caffeinate. The console forks its own
# `caffeinate -dimsu -w <its pid>` on --usb, so the Mac stays awake for exactly
# as long as the roast runs and the assertion dies with it -- even on a crash
# or a kill -9, because -w is watching the pid. An outer caffeinate would
# outlive a console that exited early and leave the machine awake for nothing.
#
# Two things caffeinate cannot do, worth knowing before a twelve-minute roast:
# -s (prevent system sleep) is valid only on AC power, and NOTHING here stops
# a MacBook sleeping when the lid is closed. Plugged in, lid open.
alias roast='"$HOME/Development/bullet-ble.git/build/bullet-console" --usb'

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
# graphics protocol); elsewhere it falls back to coloured blocks. Same
# aliases as bash/.bashrc-arch.
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

# ------------------------------------------------------------ zsh plugins --
# Loaded only if installed (Homebrew: zsh-autosuggestions,
# zsh-syntax-highlighting).
#   autosuggestions: the rest of a matching past command appears in grey;
#                    Right arrow or Cmd-Right (End) accepts it.
#   syntax-highlighting: commands turn green if they exist, red if not.
# syntax-highlighting must be sourced LAST, after every widget and bindkey,
# or it misses them -- keep this block at the end of the file.
_zsh_plugin_dir="$(brew --prefix 2>/dev/null)/share"
if [ -f "$_zsh_plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#616E88'   # Nord's comment grey
    source "$_zsh_plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
if [ -f "$_zsh_plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$_zsh_plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
unset _zsh_plugin_dir
