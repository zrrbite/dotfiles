#
# ~/.bash_profile
#

# Load .bashrc if it exists
[[ -f ~/.bashrc ]] && . ~/.bashrc

# Auto-start Hyprland on TTY1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec Hyprland
fi
