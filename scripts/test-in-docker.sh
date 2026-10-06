#!/usr/bin/env bash
#
# Run a Linux installer end to end in a throwaway Docker container, as a
# normal user with sudo, then check the result: scripts/test-zsh.sh and
# scripts/verify.sh as that user, plus what the zsh switch must leave behind.
# For trying Linux changes from the Mac. Needs Docker running.
#
# Usage: scripts/test-in-docker.sh IMAGE [--upgrade-from REF]
#   IMAGE  ubuntu:24.04, debian:12 (the Pi's base), or archlinux. archlinux
#          has no arm64 image, so it runs under emulation: slow, and its AUR
#          builds fail there (a known failure, unrelated to what is tested).
#   --upgrade-from REF
#          install at REF first, then return to the working tree and install
#          again -- what an existing machine does when it pulls.
#
# Copies the working tree, uncommitted changes included. Before installing it
# puts a real ~/.zshrc and ~/.zprofile in place, which the installer must back
# up. The container is removed at the end; KEEP=1 leaves it for a look.
#
# shellcheck disable=SC2016,SC2088  # $ and ~ in single quotes are for the container's shell; ~ in messages is display text

set -uo pipefail

IMAGE="${1:-}"
[ -n "$IMAGE" ] || { echo "usage: scripts/test-in-docker.sh IMAGE [--upgrade-from REF]"; exit 2; }
UPGRADE_FROM=""
if [ "${2:-}" = --upgrade-from ]; then
    UPGRADE_FROM="${3:-}"
    [ -n "$UPGRADE_FROM" ] || { echo "--upgrade-from needs a git ref"; exit 2; }
fi
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
FAILS=0
ok()  { echo -e "${GREEN}ok${NC}   $1"; }
bad() { echo -e "${RED}FAIL${NC} $1"; FAILS=$((FAILS + 1)); }

docker info >/dev/null 2>&1 || { echo "Docker isn't running: open -a Docker, then retry"; exit 2; }

platform=()
case "$IMAGE" in
    archlinux*) platform=(--platform linux/amd64); INSTALLER=install_arch.sh ;;
    *)          INSTALLER=install_debian.sh ;;
esac

cid="$(docker run -d "${platform[@]}" "$IMAGE" sleep infinity)" || exit 2
cleanup() {
    if [ "${KEEP:-0}" = 1 ]; then echo "kept container $cid"; else docker rm -f "$cid" >/dev/null; fi
}
trap cleanup EXIT

as_root()   { docker exec "$cid" bash -c "$1"; }
as_tester() { docker exec -u tester -e USER=tester -e HOME=/home/tester -w /home/tester "$cid" bash -c "$1"; }

echo "== $IMAGE: a user with sudo"
if [ "$INSTALLER" = install_arch.sh ]; then
    # pacman 7 sandboxes its downloads with a seccomp filter that an emulated
    # x86 container can't set up ("error restricting syscalls via seccomp").
    # Real Arch machines aren't affected.
    as_root 'sed -i "/^\[options\]/a DisableSandbox" /etc/pacman.conf
             pacman -Syu --noconfirm --needed sudo git >/dev/null' || exit 2
else
    # Docker's Debian and Ubuntu images leave out /usr/share/doc, which is
    # where Debian's fzf keeps its zsh key bindings. Real machines have it.
    as_root 'rm -f /etc/dpkg/dpkg.cfg.d/excludes /etc/dpkg/dpkg.cfg.d/docker
             apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq sudo git ca-certificates curl >/dev/null' || exit 2
fi
as_root 'useradd -m -s /bin/bash tester && echo "tester ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tester' || exit 2
as_tester 'git config --global user.name "Test User" && git config --global user.email test@example.com
           echo "# pre-existing" > ~/.zshrc && echo "# pre-existing" > ~/.zprofile' || exit 2

echo "== copying the working tree"
docker cp "$DOTFILES_DIR/." "$cid:/home/tester/dotfiles" >/dev/null \
    && as_root 'chown -R tester:tester /home/tester/dotfiles' || exit 2

if [ -n "$UPGRADE_FROM" ]; then
    echo "== installing at $UPGRADE_FROM first, like a machine set up before"
    as_tester "cd ~/dotfiles
        stashed=false
        if [ -n \"\$(git status --porcelain)\" ]; then git stash push -u -q && stashed=true; fi
        git checkout -q --detach '$UPGRADE_FROM' || exit 1
        ./$INSTALLER > ~/install-old.log 2>&1 || echo \"     (that installer exited \$?; ~/install-old.log)\"
        git checkout -q -
        if \$stashed; then git stash pop -q; fi" || { bad "could not install at $UPGRADE_FROM"; exit 1; }
fi

echo "== $INSTALLER (full log: ~/install.log in the container)"
if as_tester "cd ~/dotfiles && ./$INSTALLER > ~/install.log 2>&1"; then
    ok "installer exited 0"
else
    as_tester 'sed -n "/Finished with/,/^\$/p" ~/install.log | sed "s/^/     /"'
    if [ "$INSTALLER" = install_arch.sh ]; then
        echo "     (on archlinux the AUR step fails under emulation; judged by the checks below)"
    else
        bad "installer exited non-zero (its problems are listed above)"
    fi
fi

echo "== checks"
if as_tester 'cd ~/dotfiles && scripts/test-zsh.sh'; then ok "scripts/test-zsh.sh"; else bad "scripts/test-zsh.sh (above)"; fi
if as_tester 'cd ~/dotfiles && scripts/verify.sh'; then ok "scripts/verify.sh"; else bad "scripts/verify.sh (above)"; fi

login="$(as_tester 'getent passwd tester | cut -d: -f7')"
if [ "${login##*/}" = zsh ]; then ok "login shell is $login"; else bad "login shell is $login, not zsh"; fi
if as_tester "grep -qx '$login' /etc/shells"; then
    ok "login shell is listed in /etc/shells"
else
    bad "login shell $login is not listed in /etc/shells"
fi
# Debian's and Ubuntu's zsh read no /etc/profile at login, so /etc/profile.d
# (snap's PATH, locale fixes) would be skipped; bash logins read it.
as_root 'echo "export DOTFILES_PROFILE_D=yes" > /etc/profile.d/zz-dotfiles-test.sh'
got="$(as_tester 'SSH_AUTH_SOCK=x zsh -l -c "echo \${DOTFILES_PROFILE_D:-missing}"' 2>/dev/null | tail -1)"
if [ "$got" = yes ]; then ok "a zsh login reads /etc/profile.d"; else bad "a zsh login skips /etc/profile.d (got $got)"; fi
as_root 'rm -f /etc/profile.d/zz-dotfiles-test.sh'

if as_tester 'ls ~/.config-backup-*/.zshrc ~/.config-backup-*/.zprofile >/dev/null 2>&1'; then
    ok "the pre-existing ~/.zshrc and ~/.zprofile were backed up"
else
    bad "the pre-existing ~/.zshrc and ~/.zprofile were not backed up"
fi
if as_tester '[ "$(readlink -f ~/.zshrc)" = ~/dotfiles/zsh/.zshrc ] && [ "$(readlink -f ~/.zprofile)" = ~/dotfiles/zsh-linux/.zprofile ]'; then
    ok "~/.zshrc and ~/.zprofile link into the repo"
else
    bad "~/.zshrc or ~/.zprofile doesn't link into the repo: $(as_tester 'ls -l ~/.zshrc ~/.zprofile 2>&1')"
fi
for f in .bashrc .bash_profile; do
    if as_tester "[ -L ~/$f ] && readlink ~/$f | grep -q /bash/"; then
        bad "~/$f still links to the repo's bash files"
    else
        ok "~/$f doesn't link into the repo"
    fi
done
if [ -n "$UPGRADE_FROM" ]; then
    if as_tester 'cmp -s ~/.bashrc /etc/skel/.bashrc'; then
        ok "~/.bashrc is the distro default again"
    else
        bad "~/.bashrc is not /etc/skel/.bashrc: $(as_tester 'ls -l ~/.bashrc 2>&1')"
    fi
fi

echo "== verify.sh catches a half-done switch"
as_tester 'cp ~/.bashrc ~/.bashrc.keep && ln -sfn ~/dotfiles/bash/.bashrc-wsl ~/.bashrc'
out="$(as_tester 'cd ~/dotfiles && scripts/verify.sh' 2>&1)"; rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q 'still links to a retired bash file'; then
    ok "verify.sh fails on a ~/.bashrc left linked to a removed bash file"
else
    bad "verify.sh missed a ~/.bashrc linked to a removed bash file (exit $rc)"
fi
as_tester 'rm ~/.bashrc && mv ~/.bashrc.keep ~/.bashrc'
as_root 'chsh -s /bin/bash tester'
out="$(as_tester 'cd ~/dotfiles && scripts/verify.sh' 2>&1)"; rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q 'login shell is /bin/bash, not zsh'; then
    ok "verify.sh fails when the login shell isn't zsh"
else
    bad "verify.sh missed a bash login shell (exit $rc)"
fi
if echo "$out" | grep -q 'sudo chsh -s /usr/bin/zsh'; then
    ok "verify.sh's chsh advice names /usr/bin/zsh"
else
    bad "verify.sh's chsh advice doesn't name /usr/bin/zsh"
fi
# A zsh that /etc/shells doesn't list (on Arch, /usr/sbin/zsh is one).
as_root 'mkdir -p /opt/zsh && ln -sf "$(grep -m1 -x ".*/zsh" /etc/shells)" /opt/zsh/zsh && chsh -s /opt/zsh/zsh tester' 2>/dev/null
out="$(as_tester 'cd ~/dotfiles && scripts/verify.sh' 2>&1)"; rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q 'is not listed in /etc/shells'; then
    ok "verify.sh fails when the login shell isn't in /etc/shells"
else
    bad "verify.sh missed a login shell missing from /etc/shells (exit $rc)"
fi
as_root 'chsh -s "$(grep -m1 -x ".*/zsh" /etc/shells)" tester'
# A tmux server started before the switch keeps opening bash panes.
as_tester 'SHELL=/bin/bash tmux new-session -d -s before-switch'
out="$(as_tester 'cd ~/dotfiles && scripts/verify.sh' 2>&1)"
if echo "$out" | grep -q 'tmux server'; then
    ok "verify.sh warns about a tmux server still opening bash"
else
    bad "verify.sh missed a tmux server still opening bash"
fi
as_tester 'tmux kill-server'

echo "== zsh startup time, three runs (seconds)"
as_tester 'command -v zsh >/dev/null && zsh -c "zmodload zsh/datetime; for i in 1 2 3; do s=\$EPOCHREALTIME; SSH_AUTH_SOCK=/dev/null zsh -i -c exit >/dev/null 2>&1; printf \"     %.2f\n\" \$((EPOCHREALTIME - s)); done"'

echo
if [ "$FAILS" -gt 0 ]; then
    echo -e "${RED}$FAILS check(s) failed${NC} on $IMAGE${UPGRADE_FROM:+ (upgrade from $UPGRADE_FROM)}"
    exit 1
fi
echo -e "${GREEN}All checks passed${NC} on $IMAGE${UPGRADE_FROM:+ (upgrade from $UPGRADE_FROM)}"
