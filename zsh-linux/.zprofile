# zsh login shells on Linux: the zsh-linux package, stowed on Arch and Debian
# only. The Mac keeps its own ~/.zprofile, which Homebrew's installer asks for.
#
# zsh reads this before ~/.zshrc. On Arch it is what starts Hyprland.

# One ssh-agent for the whole login, started before Hyprland so Hyprland and
# every terminal it opens inherit it; otherwise each terminal's .zshrc would
# start its own. ssh-add stays in .zshrc, so a key's passphrase is asked in
# the first terminal.
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null
fi

# Debian's and Ubuntu's zsh read no /etc/profile at login, so the scripts in
# /etc/profile.d (snap's PATH, locale fixes) would be skipped; bash logins run
# them. Arch's /etc/zsh/zprofile already sources /etc/profile.
# Builtins only: this runs before PATH can be trusted.
if ! [[ -r /etc/zsh/zprofile && "$(</etc/zsh/zprofile)" == *(source|.)\ /etc/profile* ]]; then
    for _f in /etc/profile.d/*.sh(N); do
        [ -r "$_f" ] && emulate sh -c '. "$_f"'
    done
    unset _f
fi

# Start Hyprland on TTY1. start-hyprland (Hyprland 0.53+) is the supported
# launcher: it restarts Hyprland in safe mode after a crash. Falls back to
# Hyprland for older versions. A machine with neither (the Pi, WSL) just gets
# its shell: exec of a missing command would end the login instead.
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    if command -v start-hyprland >/dev/null 2>&1; then
        exec start-hyprland
    elif command -v Hyprland >/dev/null 2>&1; then
        exec Hyprland
    fi
fi
