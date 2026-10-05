# Windows dotfiles installation script
# Requires the right to create symlinks: Developer Mode (Windows 10 and 11) or
# an elevated shell. Checked before anything is changed.
# Run: powershell -ExecutionPolicy Bypass -File install_windows.ps1

#Requires -Version 5.1

# Colors for output
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

Write-Info "Starting Windows dotfiles installation..."
Write-Host ""

# Can this account create symlinks? Every config below is a symlink, so test
# it directly in a scratch directory rather than inferring it from the Windows
# version: Windows 11 also needs Developer Mode for a non-admin user, and a
# managed machine may have it locked off. Nothing has been changed yet if this
# fails.
$probeDir = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-probe-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $probeDir | Out-Null
Set-Content -Path (Join-Path $probeDir "target") -Value "probe"
$canLink = $true
$script:linkFailures = 0
try {
    New-Item -ItemType SymbolicLink -Path (Join-Path $probeDir "link") -Target (Join-Path $probeDir "target") -ErrorAction Stop | Out-Null
} catch {
    $canLink = $false
} finally {
    Remove-Item $probeDir -Recurse -Force -ErrorAction SilentlyContinue
}
if (-not $canLink) {
    Write-Error "This account cannot create symlinks, so nothing was changed."
    Write-Host ""
    Write-Host "Enable Developer Mode (Windows 10 and 11):"
    Write-Host "  Settings > System > For developers > Developer Mode"
    Write-Host "or run this script from an elevated shell. On a managed machine this may need IT."
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # Reported: Windows PowerShell 5.1 may need elevation even with
        # Developer Mode on. PowerShell 7 does not.
        Write-Host "This is Windows PowerShell $($PSVersionTable.PSVersion); if Developer Mode is already on, try pwsh."
    }
    exit 1
}
Write-Info "Symlinks can be created ✓"

# Install Scoop if not present
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Scoop package manager..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    Write-Info "Scoop installed ✓"
} else {
    Write-Info "Scoop already installed ✓"
}

# Scoop needs its own git to manage buckets, even if system git exists.
if (-not (scoop list git 2>$null | Select-String -Pattern '^git\s')) {
    Write-Info "Installing git via Scoop (required for buckets)..."
    scoop install git
}

# Add extras bucket for meld, glazewm, etc.
Write-Info "Adding Scoop extras bucket..."
scoop bucket add extras 2>$null
scoop bucket add nerd-fonts 2>$null

# Install core packages
Write-Info "Installing packages via Scoop..."
$scoopPackages = @(
    # Core development
    "git",
    "neovim",
    "starship",
    "llvm",          # Includes clang, clang-format, clang-tidy, clangd
    "make",
    "cmake",

    # Modern CLI tools
    "ripgrep",
    "fd",
    "fzf",
    "bat",
    "eza",
    "zoxide",
    "delta",
    "duf",
    "procs",

    # Diff/merge
    "meld",

    # System info
    "fastfetch",

    # Font
    "nerd-fonts/JetBrainsMono-NF",

    # Per-app volume control
    "extras/eartrumpet",

    # System command-line utility (used by GlazeWM for volume keys)
    "nircmd",

    # Tiling window manager + bar
    "extras/glazewm",
    "extras/zebar",

    # Alt+drag to move/resize windows (Linux-style)
    "extras/altsnap"
)

foreach ($pkg in $scoopPackages) {
    if (scoop list $pkg 2>$null) {
        Write-Info "  $pkg already installed"
    } else {
        Write-Info "  Installing $pkg..."
        scoop install $pkg
    }
}

# Install Windows Terminal via winget (if available)
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Info "Installing Windows Terminal via winget..."
    winget install Microsoft.WindowsTerminal --silent --accept-package-agreements --accept-source-agreements 2>$null
}

Write-Host ""
Write-Info "Configuring dotfiles..."

# Get dotfiles directory (where this script lives)
$dotfilesDir = Split-Path -Parent $PSCommandPath
$homeDir = $env:USERPROFILE

# git\.gitconfig carries no identity or credential helper; those live in
# ~\.gitconfig.local, which it includes last. Carry the existing ones over
# before ~\.gitconfig is replaced, so a machine keeps its own identity (a work
# laptop keeps its work email). Mirrors scripts/seed-gitconfig-local.sh.
function Initialize-GitconfigLocal {
    $localCfg = Join-Path $env:USERPROFILE ".gitconfig.local"
    $source = Join-Path $env:USERPROFILE ".gitconfig"
    if (Test-Path $localCfg) {
        Write-Info "~\.gitconfig.local already exists -- leaving it alone"
        return
    }
    $lines = @()
    if ((Test-Path $source) -and -not (Get-Item $source -Force).LinkType -and
        (Get-Command git -ErrorAction SilentlyContinue)) {
        # Same key list as scripts/seed-gitconfig-local.sh and stow_windows.ps1.
        $lines = @(& git config -f $source --get-regexp '^(user\.|credential\.|gpg\.|commit\.gpgsign$|tag\.gpgsign$|http\.|https\.|includeif\.|url\.|core\.autocrlf$|core\.sshcommand$|core\.hookspath$|core\.excludesfile$)' 2>$null)
    }
    if ($lines.Count -eq 0) {
        Write-Warn "No existing git identity to carry over. Create ~\.gitconfig.local:"
        Write-Warn '  git config -f ~/.gitconfig.local user.name  "Your Name"'
        Write-Warn '  git config -f ~/.gitconfig.local user.email "you@example.com"'
        Write-Warn '  git config -f ~/.gitconfig.local credential.helper manager'
        return
    }
    foreach ($line in $lines) {
        $key, $value = $line -split ' ', 2
        # Windows PowerShell drops empty-string arguments to native commands,
        # so a key with no value cannot be copied faithfully. Say so instead.
        if ([string]::IsNullOrEmpty($value)) {
            Write-Warn "Not copied (empty value): $key"
            continue
        }
        & git config -f $localCfg --add $key $value
        Write-Info "Carried over to ~\.gitconfig.local: $key"
    }
}

Initialize-GitconfigLocal

# Backup existing configs
$backupDir = "$homeDir\.config-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$needsBackup = $false

$configFiles = @(
    "$homeDir\.gitconfig",
    "$homeDir\.gitignore-global",
    "$homeDir\.claude\skills",
    "$homeDir\.clang-format",
    "$homeDir\.clang-tidy",
    "$homeDir\.bashrc",
    "$homeDir\.config\starship.toml",
    "$env:LOCALAPPDATA\nvim",
    "$homeDir\.glzr\glazewm\config.yaml",
    "$homeDir\.glzr\zebar\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$homeDir\.config\fastfetch\config.jsonc"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        if (-not $needsBackup) {
            Write-Info "Backing up existing configs to $backupDir"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            $needsBackup = $true
        }
        $dest = Join-Path $backupDir (Split-Path $file -Leaf)
        Copy-Item -Path $file -Destination $dest -Recurse -Force
    }
}

# Create symlinks helper function
function New-DotfileSymlink {
    param(
        [string]$Source,
        [string]$Target
    )

    $fullSource = Join-Path $dotfilesDir $Source

    if (-not (Test-Path $fullSource)) {
        Write-Warn "Source not found: $fullSource"
        return
    }

    # Remove existing target if it's not a symlink
    if (Test-Path $Target) {
        $item = Get-Item $Target
        if (-not $item.LinkType) {
            Remove-Item $Target -Recurse -Force
        }
    }

    # Create parent directory if needed
    $parentDir = Split-Path -Parent $Target
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Create symlink
    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $fullSource -Force -ErrorAction Stop | Out-Null
        Write-Info "  ✓ Linked: $Source -> $(Split-Path $Target -Leaf)"
    } catch {
        Write-Error "  ✗ Failed to link $Source : $_"
        Write-Warn "    Enable Developer Mode (Settings > For Developers) or run as Administrator."
        $script:linkFailures++
    }
}

# Stow packages (create symlinks)
Write-Info "Linking configuration files..."

# Git config and hooks
New-DotfileSymlink "git\.gitconfig" "$homeDir\.gitconfig"
New-DotfileSymlink "git\.git-hooks" "$homeDir\.git-hooks"
# .gitconfig points core.excludesFile here
New-DotfileSymlink "git\.gitignore-global" "$homeDir\.gitignore-global"

# Clang configs
New-DotfileSymlink "clang\.clang-format" "$homeDir\.clang-format"
New-DotfileSymlink "clang\.clang-tidy" "$homeDir\.clang-tidy"

# Neovim (Windows uses %LOCALAPPDATA%\nvim, not .config/nvim)
New-DotfileSymlink "nvim\.config\nvim" "$env:LOCALAPPDATA\nvim"

# Starship
New-DotfileSymlink "starship\.config\starship.toml" "$homeDir\.config\starship.toml"

# Bash config (for Git Bash)
New-DotfileSymlink "bash\.bashrc-windows" "$homeDir\.bashrc"
New-DotfileSymlink "bash\.minttyrc" "$homeDir\.minttyrc"

# Claude Code skills
New-DotfileSymlink "claude\.claude\skills" "$homeDir\.claude\skills"

# GlazeWM tiling window manager
New-DotfileSymlink "glazewm\.glzr\glazewm\config.yaml" "$homeDir\.glzr\glazewm\config.yaml"

# Zebar status bar (companion to GlazeWM)
New-DotfileSymlink "zebar\.glzr\zebar\settings.json" "$homeDir\.glzr\zebar\settings.json"

# Windows Terminal (Nord theme, JetBrains Mono Nerd Font)
$wtSettingsDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (Test-Path $wtSettingsDir) {
    New-DotfileSymlink "windowsterminal\settings.json" "$wtSettingsDir\settings.json"
} else {
    Write-Warn "Windows Terminal (Store) not found, skipping settings symlink"
}

# Fastfetch (Windows-specific config with Windows logo)
New-DotfileSymlink "fastfetch\.config\fastfetch\config-windows.jsonc" "$homeDir\.config\fastfetch\config.jsonc"

# Set desktop wallpaper
$wallpaper = Join-Path $dotfilesDir "hypr\.local\share\wallpapers\pexels-ahmedadly-1270184.jpg"
if (Test-Path $wallpaper) {
    Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
    [Wallpaper]::SystemParametersInfo(0x0014, 0, (Resolve-Path $wallpaper).Path, 0x0003) | Out-Null
    Write-Info "  ✓ Desktop wallpaper set"
}

Write-Host ""
if ($script:linkFailures -gt 0) {
    Write-Error "$($script:linkFailures) link(s) failed -- see above. Their originals are in $backupDir."
    exit 1
}
Write-Info "✓ Installation complete!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart your terminal (PowerShell, Git Bash, or Windows Terminal)"
Write-Host "  2. Verify git config: git config --global --list"
Write-Host "  3. Test nvim: nvim (LSP, DAP, plugins should auto-install)"
Write-Host "  4. Test starship: bash (should show custom prompt)"
Write-Host ""
Write-Host "Installed tools:"
Write-Host "  - Git + hooks (pre-commit, pre-push with clang-tidy)"
Write-Host "  - Neovim (full IDE: LSP, DAP, Git integration)"
Write-Host "  - Clang tools (clang-format, clang-tidy, clangd)"
Write-Host "  - Modern CLI: ripgrep, fd, fzf, bat, eza, zoxide, git-delta"
Write-Host "  - Windows Terminal (recommended)"
Write-Host "  - GlazeWM tiling window manager (run: glazewm)"
Write-Host "  - Zebar status bar (auto-starts with GlazeWM)"
Write-Host ""
Write-Host "GlazeWM:"
Write-Host "  - Config: ~/.glzr/glazewm/config.yaml (symlinked)"
Write-Host "  - Start: glazewm  (consider adding to Startup folder)"
Write-Host "  - Keybinds: alt+{h,j,k,l} focus, alt+shift+{h,j,k,l} move,"
Write-Host "              alt+{1-9} workspace, alt+enter terminal, alt+shift+q close,"
Write-Host "              alt+r resize mode, alt+shift+e exit WM, alt+shift+r reload"
Write-Host ""
Write-Host "Git Bash usage:"
Write-Host "  - Bash config: ~/.bashrc (symlinked from dotfiles)"
Write-Host "  - Aliases: eza, bat, fzf, ripgrep all work"
Write-Host "  - Starship prompt enabled"
Write-Host ""
Write-Host "PowerShell usage:"
Write-Host "  - No PowerShell profile configured (Git Bash recommended)"
Write-Host "  - To add PowerShell support, create a profile with starship init"
Write-Host ""
