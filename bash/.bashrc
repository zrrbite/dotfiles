#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias chafa-ascii='chafa --format symbols --symbols ascii --colors none -s 60x20'
alias chafa-block='chafa --format symbols --symbols block -s 60x20'
PS1='[\u@\h \W]\$ '
eval "$(starship init bash)"

# SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi
if [ -f ~/.ssh/id_ed25519 ]; then
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi

toilet -f mono12 "Arch" --metal

# fzf - fuzzy finder
eval "$(fzf --bash)"

# zoxide - smarter cd
eval "$(zoxide init bash)"

