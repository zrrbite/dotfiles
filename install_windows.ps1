# Windows dotfiles installation script
# Requires: Windows 10 (Developer Mode) or Windows 11
# Run: powershell -ExecutionPolicy Bypass -File install_windows.ps1

#Requires -Version 5.1

# Colors for output
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

Write-Info "Starting Windows dotfiles installation..."
Write-Host ""

# Check Windows version
$winver = [System.Environment]::OSVersion.Version
$isWin11 = ($winver.Major -eq 10 -and $winver.Build -ge 22000) -or ($winver.Major -gt 10)

# Check Developer Mode (Windows 10 only)
if (-not $isWin11) {
    Write-Warn "Windows 10 detected. Checking Developer Mode..."
    $devMode = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ErrorAction SilentlyContinue
    if (-not $devMode -or $devMode.AllowDevelopmentWithoutDevLicense -ne 1) {
        Write-Error "Developer Mode is required on Windows 10 for symlinks"
        Write-Host ""
        Write-Host "Enable Developer Mode:"
        Write-Host "  Settings > Update & Security > For Developers > Developer Mode"
        Write-Host ""
        Write-Host "Then re-run this script."
        exit 1
    }
    Write-Info "Developer Mode enabled ✓"
}

# Install Scoop if not present
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Scoop package manager..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    Write-Info "Scoop installed ✓"
} else {
    Write-Info "Scoop already installed ✓"
}

# Add extras bucket for meld, etc.
Write-Info "Adding Scoop extras bucket..."
scoop bucket add extras 2>$null

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
    "git-delta",
    "duf",
    "procs",

    # Diff/merge
    "meld"
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

# Backup existing configs
$backupDir = "$homeDir\.config-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$needsBackup = $false

$configFiles = @(
    "$homeDir\.gitconfig",
    "$homeDir\.clang-format",
    "$homeDir\.clang-tidy",
    "$homeDir\.bashrc",
    "$homeDir\.config\starship.toml",
    "$env:LOCALAPPDATA\nvim"
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
        New-Item -ItemType SymbolicLink -Path $Target -Target $fullSource -Force | Out-Null
        Write-Info "  ✓ Linked: $Source -> $(Split-Path $Target -Leaf)"
    } catch {
        Write-Error "  ✗ Failed to link $Source : $_"
    }
}

# Stow packages (create symlinks)
Write-Info "Linking configuration files..."

# Git config and hooks
New-DotfileSymlink "git\.gitconfig" "$homeDir\.gitconfig"
New-DotfileSymlink "git\.git-hooks" "$homeDir\.git-hooks"

# Clang configs
New-DotfileSymlink "clang\.clang-format" "$homeDir\.clang-format"
New-DotfileSymlink "clang\.clang-tidy" "$homeDir\.clang-tidy"

# Neovim (Windows uses %LOCALAPPDATA%\nvim, not .config/nvim)
New-DotfileSymlink "nvim\.config\nvim" "$env:LOCALAPPDATA\nvim"

# Starship
New-DotfileSymlink "starship\.config\starship.toml" "$homeDir\.config\starship.toml"

# Bash config (for Git Bash)
New-DotfileSymlink "bash\.bashrc-windows" "$homeDir\.bashrc"

Write-Host ""
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
