# macOS part of zsh/.zshrc, which loads it before everything else.
# path_prepend comes from .zshrc.

# Homebrew. Must come before anything that checks `command -v`, since Homebrew
# supplies most of those binaries. Also sets HOMEBREW_PREFIX, where .zshrc
# finds the zsh plugins.
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# dotnet comes from Homebrew (brew shellenv above). The old Microsoft installer's
# /usr/local/share/dotnet is no longer put in front: its SDKs (6.0, 7.0) cannot
# build .NET 10 projects, and it shadowed Homebrew's (2026-10-07). path_helper
# still lists it from /etc/paths.d, after Homebrew.
path_prepend "$HOME/.dotnet/tools"
path_prepend "/Library/Frameworks/Mono.framework/Versions/Current/Commands"
path_prepend "/opt/homebrew/opt/llvm/bin"

# Called by .zshrc after oh-my-zsh.
zsh_os_aliases() {
    # The roast console. --usb is baked in because that is the only mode worth
    # a shortcut; --demo and --replay are typed deliberately.
    #
    # DO NOT wrap this in caffeinate. The console forks its own
    # `caffeinate -dimsu -w <its pid>` on --usb, so the Mac stays awake for
    # exactly as long as the roast runs and the assertion dies with it -- even
    # on a crash or a kill -9, because -w is watching the pid. An outer
    # caffeinate would outlive a console that exited early and leave the
    # machine awake for nothing.
    #
    # Two things caffeinate cannot do, worth knowing before a twelve-minute
    # roast: -s (prevent system sleep) is valid only on AC power, and NOTHING
    # here stops a MacBook sleeping when the lid is closed. Plugged in, lid
    # open.
    alias roast='"$HOME/Development/bullet-ble.git/build/bullet-console" --usb'
}
