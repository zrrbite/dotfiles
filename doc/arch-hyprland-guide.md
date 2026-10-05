# Arch Linux + Hyprland Setup Guide

A complete guide for setting up Arch Linux with Hyprland compositor.

---

## Part 1: Preparing Installation Media

Download the Arch ISO from https://archlinux.org/download/

### Option A: Bootable USB (Bare Metal)

Use [Rufus](https://rufus.ie/) on Windows to create a bootable USB drive:

1. Download and run Rufus
2. Insert a USB drive (4GB+ recommended)
3. Select your USB drive under "Device"
4. Click "SELECT" and choose the Arch ISO
5. Partition scheme: **GPT** (for UEFI) or **MBR** (for legacy BIOS)
6. File system: **FAT32**
7. Click "START"
8. When prompted, select "Write in ISO Image mode"
9. Wait for completion

**On Linux**, you can use `dd`:

```bash
sudo dd bs=4M if=archlinux-*.iso of=/dev/sdX status=progress oflag=sync
```

Replace `/dev/sdX` with your USB device (check with `lsblk`). **Warning:** This will erase the USB drive.

Boot from the USB:
1. Insert USB into target machine
2. Enter BIOS/UEFI (usually F2, F12, Del, or Esc during boot)
3. Set USB as first boot device, or use boot menu
4. Save and reboot

### Option B: VirtualBox VM (Testing/Learning)

VirtualBox is useful for testing or learning before committing to bare metal.

1. Create new VM:
   - Name: Arch
   - Type: Linux
   - Version: Arch Linux (64-bit)

2. Resources:
   - RAM: 4096 MB (minimum 2048)
   - Hard disk: 20GB+, VDI, dynamically allocated

3. Display settings (Settings → Display):
   - Video Memory: **128 MB**
   - Graphics Controller: **VMSVGA**
   - Enable **3D Acceleration**

4. Network settings (Settings → Network → Adapter 1):
   - Enable Network Adapter: **checked**
   - Attached to: **NAT**

5. Mount Arch ISO:
   - Settings → Storage → Empty disk under Controller: IDE
   - Click disk icon → Choose your Arch ISO

6. Boot the VM

> **Note:** VirtualBox-specific steps are marked with **(VirtualBox)** throughout this guide. Skip these on bare metal.

---

## Part 2: Arch Installation

### Verify network in live ISO

```bash
ip a
ping -c 3 archlinux.org
```

### Run the installer

```bash
archinstall
```

**Critical settings in archinstall:**
- **Network configuration**: Select **NetworkManager** (important!)
- Everything else to your preference

Complete the installation and reboot.

---

## Part 3: Post-Install Setup

> **Quick Setup Alternative:** If you want a pre-configured Nord-themed Hyprland environment instead of manual configuration, see [Using Dotfiles](#using-dotfiles) after completing the post-install network setup. The dotfiles repo automates Parts 4-9 with tested configs.

### If you have no network after reboot

```bash
sudo systemctl enable --now systemd-networkd
sudo systemctl enable --now systemd-resolved

sudo tee /etc/systemd/network/20-wired.network << EOF
[Match]
Name=enp0s3

[Network]
DHCP=yes
EOF

sudo systemctl restart systemd-networkd
```

---

## Using Dotfiles

For a quick, pre-configured setup instead of manual configuration, use the [dotfiles repo](https://github.com/zrrbite/dotfiles):

```bash
git clone https://github.com/zrrbite/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

This installs all packages and symlinks configs for:
- **Hyprland** + hyprpaper + hyprlock + cliphist
- **Foot** terminal (Nord theme, transparency)
- **Waybar** status bar (Nord theme)
- **Rofi** app launcher (replaces wofi)
- **Mako** notifications
- **Starship** prompt
- **Neovim** IDE setup (LSP, treesitter)
- **Git** config with aliases
- Audio via pipewire

After install, log out and select Hyprland as your session.

See `~/dotfiles/README.md` for key bindings (`Super + F1` shows all) and how to manage configs with GNU Stow.

> **Note:** If you prefer manual control or want to understand each component, continue with the sections below. The dotfiles can also serve as reference configs.

---

## Part 4: Install Hyprland and Desktop Environment

> **Bare Metal:** Install GPU drivers first! See [Bare Metal Differences](#bare-metal-differences) for AMD/NVIDIA/Intel driver setup.

### Core packages

```bash
sudo pacman -S hyprland foot wofi waybar hyprpaper
```

- `hyprland` — Wayland compositor
- `foot` — terminal emulator
- `wofi` — application launcher
- `waybar` — status bar
- `hyprpaper` — wallpaper manager

### Portal and permissions

```bash
sudo pacman -S xdg-desktop-portal-wlr polkit
```

### Fonts (fixes waybar icons)

```bash
sudo pacman -S ttf-font-awesome otf-font-awesome ttf-nerd-fonts-symbols
```

### VirtualBox guest additions (VirtualBox only)

```bash
sudo pacman -S virtualbox-guest-utils
sudo systemctl enable --now vboxservice
```

Skip this on bare metal.

### Clipboard support

```bash
sudo pacman -S wl-clipboard
```

### Audio

```bash
sudo pacman -S pipewire pipewire-pulse wireplumber pamixer
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

Optional GUI mixer:
```bash
sudo pacman -S pavucontrol
```

Add volume keybinds to `hyprland.conf`:
```
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
```

---

## Part 5: Hyprland Configuration

> **Reference:** See `~/dotfiles/hypr/` for a complete Nord-themed Hyprland config with hyprlock and clipboard history.

### ~/.config/hypr/hyprland.conf

```bash
mkdir -p ~/.config/hypr
nano ~/.config/hypr/hyprland.conf
```

```ini
# Monitor config (VirtualBox example - see "Bare Metal Differences" for real hardware)
monitor = Virtual-1, 1920x1080@60, 0x0, 1

# Variables
$terminal = foot
$menu = wofi --show drun
$mainMod = SUPER

# Autostart
exec-once = hyprpaper
exec-once = waybar

# Environment for VirtualBox (remove on bare metal, except NVIDIA may need WLR_NO_HARDWARE_CURSORS)
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_RENDERER_ALLOW_SOFTWARE,1

# Danish keyboard layout
input {
    kb_layout = dk
}

# Key bindings
bind = $mainMod, Q, exec, $terminal
bind = $mainMod, C, killactive
bind = $mainMod, M, exit
bind = $mainMod, R, exec, $menu
bind = $mainMod, V, togglefloating
bind = $mainMod, F, fullscreen

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9

# Move window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Scroll through workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1
```

### Auto-start Hyprland on login

Edit `~/.bash_profile`:

```bash
nano ~/.bash_profile
```

Add at the end:

```bash
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    # VirtualBox only - remove these two lines on bare metal (except NVIDIA may need the first)
    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_RENDERER_ALLOW_SOFTWARE=1
    exec Hyprland
fi
```

---

## Part 6: Foot Terminal Configuration

> **Reference:** See `~/dotfiles/foot/` for a Nord-themed foot config with transparency and padding.

### ~/.config/foot/foot.ini

```bash
mkdir -p ~/.config/foot
nano ~/.config/foot/foot.ini
```

```ini
[main]
font=monospace:size=14

[key-bindings]
font-increase=Control+Shift+plus
font-decrease=Control+Shift+minus
font-reset=Control+Shift+0
```

---

## Part 7: Terminal Customization

### Themes for Foot

Foot uses manual color configuration. Add to `~/.config/foot/foot.ini`:

**Dracula theme example:**

```ini
[colors]
background=282a36
foreground=f8f8f2
regular0=21222c
regular1=ff5555
regular2=50fa7b
regular3=f1fa8c
regular4=bd93f9
regular5=ff79c6
regular6=8be9fd
regular7=f8f8f2
bright0=6272a4
bright1=ff6e6e
bright2=69ff94
bright3=ffffa5
bright4=d6acff
bright5=ff92df
bright6=a4ffff
bright7=ffffff
```

**Pre-made themes:**

```bash
git clone https://codeberg.org/toonn/foot-themes.git ~/.config/foot/themes
```

Then in `foot.ini`:

```ini
include=~/.config/foot/themes/dracula
```

### System info on launch (fastfetch)

```bash
sudo pacman -S fastfetch
echo "fastfetch" >> ~/.bashrc
```

Shows system info with ASCII logo when you open a terminal.

### ASCII text banners

```bash
sudo pacman -S figlet toilet
```

Add to `~/.bashrc`:

```bash
figlet "Arch"
# Or fancier:
toilet -f mono12 "Arch" --metal
```

### Fortune and cowsay

```bash
sudo pacman -S fortune-mod cowsay
```

Add to `~/.bashrc`:

```bash
fortune | cowsay
```

Random quotes with ASCII cow on each terminal launch.

---

## Part 8: Wallpaper Setup

### Download a wallpaper

```bash
mkdir -p ~/Pictures
cd ~/Pictures
curl -L -o wallpaper.jpg "https://images.unsplash.com/photo-1511300636408-a63a89df3482?w=1920"
```

### ~/.config/hypr/hyprpaper.conf

**Important:** Use full paths, not `~`. First check your monitor name:

```bash
hyprctl monitors
```

Then create the config:

```bash
nano ~/.config/hypr/hyprpaper.conf
```

```
preload = /home/YOURUSERNAME/Pictures/wallpaper.jpg
wallpaper = Virtual-1,/home/YOURUSERNAME/Pictures/wallpaper.jpg
splash = false
```

Replace `YOURUSERNAME` with your actual username and `Virtual-1` with your monitor name from `hyprctl monitors`.

---

## Part 9: Waybar Configuration

> **Reference:** See `~/dotfiles/waybar/` for a complete Nord-themed waybar with workspaces, clock, and system info.

The default waybar config may not show Hyprland workspaces. Create a custom config:

```bash
mkdir -p ~/.config/waybar
nano ~/.config/waybar/config
```

```json
{
    "layer": "top",
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["cpu", "memory", "clock"],
    
    "hyprland/workspaces": {
        "format": "{id}"
    },
    "clock": {
        "format": "{:%H:%M}"
    },
    "cpu": {
        "format": "CPU {usage}%"
    },
    "memory": {
        "format": "MEM {}%"
    }
}
```

Restart waybar:

```bash
pkill waybar; waybar &
```

---

## Part 10: Development Tools

> **Reference:** The dotfiles repo includes configs for git (with extensive aliases), neovim (LSP + treesitter), starship prompt, and clang-format/clang-tidy. See `~/dotfiles/README.md` for the full list.

### Essential packages

```bash
sudo pacman -S git base-devel cmake make neovim tmux
```

### Git configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global init.defaultBranch main
git config --global core.editor nvim
```

View config with `git config --global --list` or edit directly at `~/.gitconfig`.

### GitHub SSH setup (recommended)

SSH keys are more convenient than tokens — no password prompts for push/pull.

```bash
sudo pacman -S openssh
```

Generate an SSH key:

```bash
ssh-keygen -t ed25519 -C "your@email.com"
```

Press Enter to accept the default location (`~/.ssh/id_ed25519`). Optionally set a passphrase.

Start the SSH agent and add your key:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

Copy your public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Add the key to GitHub:
1. Go to https://github.com/settings/keys
2. Click "New SSH key"
3. Paste your public key and save

Test the connection:

```bash
ssh -T git@github.com
```

You should see: "Hi username! You've successfully authenticated..."

**Using SSH URLs:** Clone repos with SSH URLs instead of HTTPS:

```bash
# SSH (recommended)
git clone git@github.com:username/repo.git

# Instead of HTTPS
git clone https://github.com/username/repo.git
```

**Auto-start SSH agent:** Add to `~/.bashrc`:

```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2> /dev/null
fi
```

### Starship prompt (git branch, status, etc.)

```bash
sudo pacman -S starship ttf-jetbrains-mono-nerd
echo 'eval "$(starship init bash)"' >> ~/.bashrc
fc-cache -fv
source ~/.bashrc
```

Update font in `~/.config/foot/foot.ini`:

```ini
[main]
font=JetBrainsMono Nerd Font Mono:size=14
```

Open a new terminal for changes to take effect.

**Presets:**

```bash
starship preset --list                              # List all presets
starship preset nerd-font-symbols -o ~/.config/starship.toml
starship preset tokyo-night -o ~/.config/starship.toml
starship preset pastel-powerline -o ~/.config/starship.toml
```

**VS Code terminal font:**

Add to `~/.config/Code/User/settings.json`:

```json
{
    "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font Mono"
}
```

### LLVM/Clang toolchain

```bash
sudo pacman -S llvm clang clang-tools-extra
```

This gives you:
- `clang` / `clang++` — compilers
- `clangd` — language server
- `clang-format` — code formatter
- `clang-tidy` — linter

### Claude Code

```bash
sudo pacman -S nodejs npm
npm install -g @anthropic-ai/claude-code
```

If you get permission errors with global npm:

```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
npm install -g @anthropic-ai/claude-code
```

Run with `claude`. It will prompt for authentication on first run.

### VS Code

```bash
sudo pacman -S code
```

**VS Code setup:**
1. Open VS Code: `code`
2. Install the **clangd** extension (by LLVM)
3. Disable Microsoft C/C++ IntelliSense when prompted
4. Install **Vim** extension (by vscodevim) for vim keybindings
5. Install **CodeLLDB** extension for debugging

### JetBrains Rider (recommended for Unreal Engine)

Rider has superior UE support: native project handling, UnrealLink plugin, Blueprint references, and a debugger that works well with UE.

```bash
yay -S rider
```

Or install JetBrains Toolbox to manage all JetBrains IDEs:

```bash
yay -S jetbrains-toolbox
```

Note: Rider requires a license (free for students/non-commercial use).

### Generate compile_commands.json for clangd

When building projects with CMake:

```bash
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_COMPILER=clang++ ..
ln -s build/compile_commands.json .
```

### Optional: clang-format config

Create `~/.clang-format`:

```yaml
BasedOnStyle: LLVM
IndentWidth: 4
```

### Optional: clang-tidy config

Create `~/.clang-tidy`:

```yaml
Checks: '*,-llvmlibc-*,-fuchsia-*,-google-*,-zircon-*,-abseil-*'
WarningsAsErrors: ''
```

---

## Part 11: Unreal Engine (Bare Metal Only)

**Requirements:**
- 340+ GB disk space (190 GB final install)
- 32 GB RAM recommended (16 GB minimum)
- Several hours build time

### Link Epic Games to GitHub

1. Create/login at epicgames.com
2. Go to Account → Connected Accounts
3. Link your GitHub account
4. Accept the EpicGames GitHub organization invite

### Clone and build

```bash
git clone https://github.com/EpicGames/UnrealEngine.git
cd UnrealEngine
./Setup.sh
./GenerateProjectFiles.sh
./Engine/Build/BatchFiles/Linux/Build.sh UnrealEditor Linux Development -Progress
```

### VS Code integration

Generate project files with VS Code support:

```bash
./GenerateProjectFiles.sh -vscode
```

This creates `.vscode/` folder and `compile_commands.json` for clangd.

### Build task (`.vscode/tasks.json`)

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build UE Editor",
            "type": "shell",
            "command": "./Engine/Build/BatchFiles/Linux/Build.sh",
            "args": [
                "UnrealEditor",
                "Linux", 
                "Development",
                "-Progress"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": "$gcc"
        }
    ]
}
```

Build with `Ctrl + Shift + B`.

### VS Code debugging

Install the **CodeLLDB** extension in VS Code.

Create `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug UE Editor",
            "type": "lldb",
            "request": "launch",
            "program": "${workspaceFolder}/Engine/Binaries/Linux/UnrealEditor",
            "args": ["/path/to/YourProject.uproject"],
            "cwd": "${workspaceFolder}",
            "env": {
                "LD_LIBRARY_PATH": "${workspaceFolder}/Engine/Binaries/Linux"
            }
        },
        {
            "name": "Attach to UE",
            "type": "lldb",
            "request": "attach",
            "program": "${workspaceFolder}/Engine/Binaries/Linux/UnrealEditor",
            "pid": "${command:pickProcess}"
        }
    ]
}
```

Build with debug symbols:

```bash
./Engine/Build/BatchFiles/Linux/Build.sh UnrealEditor Linux Debug -Progress
```

Note: Debug builds are much slower and larger than Development builds.

---

## Part 12: AUR and Google Chrome

Chrome isn't in the official repos — you need the AUR (Arch User Repository).

### Install yay (AUR helper)

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay
```

### Install Google Chrome

```bash
yay -S google-chrome
```

Launch with `google-chrome-stable` or find it in wofi.

### Install Zoom

```bash
yay -S zoom
```

---

## Part 13: Other Useful Packages

```bash
sudo pacman -S firefox thunar
```

- `firefox` — web browser
- `thunar` — file manager

---

## Cheat Sheet: Hyprland

| Shortcut | Action |
|----------|--------|
| `Super + Q` | Open terminal |
| `Super + C` | Close window |
| `Super + M` | Exit Hyprland |
| `Super + R` | Open app launcher (wofi) |
| `Super + V` | Toggle floating |
| `Super + F` | Toggle fullscreen |
| `Super + Arrow keys` | Move focus |
| `Super + 1-9` | Switch to workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Super + Scroll` | Cycle workspaces |
| `Super + Left drag` | Move window |
| `Super + Right drag` | Resize window |

---

## Cheat Sheet: tmux

Install: `sudo pacman -S tmux`

Default prefix: `Ctrl + B`

| Shortcut | Action |
|----------|--------|
| `tmux` | Start new session |
| `tmux attach` | Reattach to session |
| `Ctrl+B, c` | New window |
| `Ctrl+B, n` | Next window |
| `Ctrl+B, p` | Previous window |
| `Ctrl+B, %` | Vertical split |
| `Ctrl+B, "` | Horizontal split |
| `Ctrl+B, Arrow keys` | Move between panes |
| `Ctrl+B, d` | Detach session |
| `Ctrl+B, x` | Kill pane |
| `Ctrl+B, &` | Kill window |
| `Ctrl+B, [` | Scroll mode (q to exit) |
| `Ctrl+B, z` | Toggle pane zoom |

---

## Cheat Sheet: Neovim

Start: `nvim` or `nvim filename`

| Shortcut | Mode | Action |
|----------|------|--------|
| `i` | Normal | Enter insert mode |
| `Esc` | Insert | Return to normal mode |
| `h/j/k/l` | Normal | Move left/down/up/right |
| `w` | Normal | Next word |
| `b` | Normal | Previous word |
| `0` | Normal | Start of line |
| `$` | Normal | End of line |
| `gg` | Normal | Start of file |
| `G` | Normal | End of file |
| `dd` | Normal | Delete line |
| `yy` | Normal | Yank (copy) line |
| `p` | Normal | Paste |
| `u` | Normal | Undo |
| `Ctrl+R` | Normal | Redo |
| `/pattern` | Normal | Search |
| `n` | Normal | Next search result |
| `N` | Normal | Previous search result |
| `:w` | Command | Save |
| `:q` | Command | Quit |
| `:wq` | Command | Save and quit |
| `:q!` | Command | Quit without saving |
| `v` | Normal | Visual mode (select) |
| `V` | Normal | Visual line mode |
| `Ctrl+V` | Normal | Visual block mode |

---

## Cheat Sheet: Foot Terminal

| Shortcut | Action |
|----------|--------|
| `Ctrl + Shift + C` | Copy |
| `Ctrl + Shift + V` | Paste |
| `Ctrl + Shift + +` | Increase font size |
| `Ctrl + Shift + -` | Decrease font size |
| `Ctrl + Shift + 0` | Reset font size |
| `Middle click` | Paste selection |

---

## VirtualBox Tips (VirtualBox only)

Skip this section on bare metal.

**Enable clipboard sharing:**
- Devices → Shared Clipboard → Bidirectional

**Resize VM display:**
- View → Auto-resize Guest Display
- Or: `Right Ctrl + F` for fullscreen

**If display doesn't auto-resize:**
```bash
sudo systemctl enable --now vboxservice
reboot
```

**Expand disk space:**

1. Shut down the VM
2. In VirtualBox: File → Tools → Virtual Media Manager
3. Select your Arch VDI
4. Drag the Size slider to your desired size
5. Click Apply
6. Boot the VM and resize the partition:

```bash
lsblk                           # Check partition layout
sudo pacman -S parted
sudo parted /dev/sda
# In parted:
print                           # See partitions
resizepart 2 100%              # Replace 2 with your root partition number
quit
```

Then resize the filesystem:

```bash
# For ext4:
sudo resize2fs /dev/sda2

# For btrfs:
sudo btrfs filesystem resize max /
```

---

## Quick Reference: Package Summary

```bash
# All official packages in one command
sudo pacman -S \
    hyprland foot wofi waybar hyprpaper \
    xdg-desktop-portal-wlr polkit \
    ttf-font-awesome otf-font-awesome ttf-nerd-fonts-symbols ttf-jetbrains-mono-nerd \
    wl-clipboard \
    pipewire pipewire-pulse wireplumber pamixer pavucontrol \
    git base-devel cmake make neovim tmux nodejs npm starship \
    llvm clang clang-tools-extra \
    code firefox thunar

# Enable audio (run as your user, not root)
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# VirtualBox only
sudo pacman -S virtualbox-guest-utils
sudo systemctl enable --now vboxservice

# Claude Code
npm install -g @anthropic-ai/claude-code

# AUR packages (after installing yay)
yay -S google-chrome rider zoom
# Or for JetBrains Toolbox:
# yay -S jetbrains-toolbox
```

---

## Bare Metal Differences

When installing on real hardware instead of VirtualBox, make these changes:

### Skip these packages

```bash
# Don't need these
virtualbox-guest-utils
```

### Skip these environment variables

Remove from `~/.bash_profile` and `hyprland.conf`:

```bash
# Not needed on bare metal
WLR_NO_HARDWARE_CURSORS=1
WLR_RENDERER_ALLOW_SOFTWARE=1
```

### Install GPU drivers instead

**AMD:**
```bash
sudo pacman -S mesa vulkan-radeon libva-mesa-driver
```

**NVIDIA (detailed setup for RTX cards):**

Install drivers (use nvidia-open for RTX 20 series and newer):

```bash
# For RTX 20+ series (recommended)
sudo pacman -S nvidia-open nvidia-utils nvidia-settings

# Or for older cards / if open drivers have issues
sudo pacman -S nvidia nvidia-utils nvidia-settings

# For brand new GPUs (if drivers are lagging in main repo)
# yay -S nvidia-beta
```

Vulkan support (needed for UE):

```bash
sudo pacman -S vulkan-icd-loader lib32-vulkan-icd-loader
```

Enable DRM kernel mode setting. Edit `/etc/default/grub`:

```
GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1"
```

Then regenerate grub config:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Or if using systemd-boot, add `nvidia_drm.modeset=1` to your kernel options in `/boot/loader/entries/arch.conf`.

Early loading (recommended). Edit `/etc/mkinitcpio.conf`:

```
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```

Then regenerate initramfs:

```bash
sudo mkinitcpio -P
```

Add to `hyprland.conf` for NVIDIA:

```
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
```

Reboot after all changes.

**NVIDIA tips:**
- Hardware cursors are buggy on Wayland — keep `WLR_NO_HARDWARE_CURSORS=1`
- Chrome/Electron apps may need `--ozone-platform=wayland` flag
- Use `nvidia-settings` to troubleshoot screen tearing
- Hyprland's explicit sync helps with NVIDIA — update Hyprland regularly

**Intel:**
```bash
sudo pacman -S mesa vulkan-intel intel-media-driver
```

### Monitor configuration

Replace the VirtualBox monitor line with your actual displays:

```bash
# Check connected monitors
hyprctl monitors
# Or before starting Hyprland:
wlr-randr
```

Example for a real monitor:
```
monitor = DP-1, 2560x1440@144, 0x0, 1
monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1
```

### Terminal

Kitty should work on bare metal (GPU acceleration available):
```bash
sudo pacman -S kitty
```

Change in `hyprland.conf`:
```
$terminal = kitty
```

### Clipboard

Should work without issues. If not:
```bash
sudo pacman -S wl-clipboard
```

### Audio

Same setup, but might need firmware:
```bash
sudo pacman -S sof-firmware alsa-firmware
```

---

## Troubleshooting

**Black screen with cursor after starting Hyprland:**
- This is normal — press `Super + Q` to open terminal

**No network after install:**
- Check NetworkManager: `sudo systemctl enable --now NetworkManager`
- Or use systemd-networkd (see Part 3)

**Hyprland crashes in VirtualBox:**
- Ensure 3D acceleration is enabled
- Add software rendering environment variables

**Waybar shows weird symbols:**
- Install font-awesome and nerd-fonts packages

**Waybar not showing workspaces:**
- Create custom waybar config (see Part 8)

**Can't paste into terminal:**
- Use `Ctrl + Shift + V` (not `Ctrl + V`)
- Enable clipboard sharing in VirtualBox

**Hyprpaper "does not have a target" error:**
- Use full paths in hyprpaper.conf, not `~`
- Check monitor name with `hyprctl monitors`
- Format: `wallpaper = Virtual-1,/full/path/to/image.jpg`
