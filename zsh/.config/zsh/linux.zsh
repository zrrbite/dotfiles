# Linux part of zsh/.zshrc (Arch, Debian, the Pi, WSL), which loads it before
# everything else. Login-time setup is in zsh-linux/.zprofile.

# System info when a terminal opens (fastfetch: Arch installs it, Debian
# doesn't). Not inside tmux, where it would flash in the prefix-f project
# popup, and not when output isn't a terminal.
if [ -z "$TMUX" ] && [ -t 1 ] && command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# Called by .zshrc after oh-my-zsh: its `d` (dirs -v) would replace ours.
zsh_os_aliases() {
    # WSL: shortcuts to the Windows drives. WSL sets WSL_DISTRO_NAME; the
    # kernel string is the fallback check.
    if [ -n "$WSL_DISTRO_NAME" ] || grep -qi microsoft /proc/version 2>/dev/null; then
        alias c='cd /mnt/c'
        alias d='cd /mnt/d'
        alias cdrive='cd /mnt/c'
        alias ddrive='cd /mnt/d'
        alias dev='cd /mnt/d/dev'
        alias downloads='cd /mnt/c/Users/$USER/Downloads'
        alias docs='cd /mnt/c/Users/$USER/Documents'
    fi
}
