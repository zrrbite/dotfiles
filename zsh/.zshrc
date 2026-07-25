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
path_prepend "/opt/homebrew/opt/node@18/bin"
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

# ---------------------------------------------------------------- ssh-agent --
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null
fi
[ -f "$HOME/.ssh/id_ed25519" ] && ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null

# ------------------------------------------------------------------ aliases --
# Only additive ones. ls, cat, find and ps are deliberately left alone.
alias grep='grep --color=auto'
