#!/usr/bin/env bash
#
# The zsh steps of the Linux installers (install_arch.sh, install_debian.sh),
# shared so both do them the same way. Run after zsh and zsh-linux are stowed:
#
#   1. Clone oh-my-zsh, which zsh/.zshrc loads (clone only, as on macOS).
#   2. Retire ~/.bashrc and ~/.bash_profile if they still link to the Linux
#      bash files this repo used to have, putting back the distro's defaults
#      from /etc/skel. scripts/verify.sh checks for the same links.
#   3. Debian: link ~/.local/bin/bat and fd to batcat and fdfind, Debian's
#      names. Aliases would not reach `xargs bat` or yazi's previews.
#   4. Make zsh the login shell. Through sudo, which the installer already
#      holds, so there is no second password prompt.
#
# Every step is skipped when already done. Exits 1 if a step failed, after
# trying the rest.
#
# Usage: scripts/setup-zsh-linux.sh

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

status=0
me="$(id -un)"

# 1. oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing oh-my-zsh (clone only; ~/.zshrc stays the repo's)..."
    if ! git clone -q --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"; then
        warn "oh-my-zsh clone failed; zsh works without it"
        status=1
    fi
fi

# 2. Links to the retired bash files. Same patterns as scripts/verify.sh.
for f in "$HOME/.bashrc" "$HOME/.bash_profile"; do
    [ -L "$f" ] || continue
    case "$(readlink "$f")" in
        */bash/.bashrc-arch | */bash/.bashrc-wsl | */bash/.bashrc-raspbian | \
        */bash/.bash_profile-arch | */bash/.bash_profile-wsl | */bash/.bash_profile-raspbian)
            rm "$f"
            skel="/etc/skel/${f##*/}"
            if [ -f "$skel" ]; then
                cp "$skel" "$f"
                info "Retired $f (it linked to a removed bash file); restored $skel"
            else
                info "Retired $f (it linked to a removed bash file)"
            fi
            ;;
    esac
done

# 3. Debian's names for bat and fd
for pair in bat:batcat fd:fdfind; do
    name="${pair%%:*}"
    real="${pair##*:}"
    if ! command -v "$name" >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/$name" ] \
        && real_path="$(command -v "$real")"; then
        mkdir -p "$HOME/.local/bin"
        ln -s "$real_path" "$HOME/.local/bin/$name"
        info "Linked ~/.local/bin/$name -> $real_path"
    fi
done

# 4. The login shell
zsh_path="$(command -v zsh || true)"
current="$(getent passwd "$me" | cut -d: -f7)"
if [ -z "$zsh_path" ]; then
    warn "zsh is not installed; the login shell stays $current"
    status=1
elif [ "${current##*/}" != zsh ]; then
    if sudo chsh -s "$zsh_path" "$me"; then
        info "Login shell is now zsh (was $current); log out and back in to use it"
    else
        warn "Could not change the login shell. Run: sudo chsh -s $zsh_path $me"
        status=1
    fi
fi

exit $status
