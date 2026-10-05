# stow_windows.ps1 - GNU Stow equivalent for Windows
# Creates/removes symlinks from dotfiles packages to their target locations.
#
# Usage:
#   .\stow_windows.ps1 git              # Link the git package
#   .\stow_windows.ps1 git nvim clang   # Link multiple packages
#   .\stow_windows.ps1 -All             # Link all supported packages
#   .\stow_windows.ps1 -Delete git      # Remove symlinks for a package
#   .\stow_windows.ps1 -Delete -All     # Remove all symlinks
#   .\stow_windows.ps1 -List            # Show available packages
#
# Requires: Windows 10 (Developer Mode) or Windows 11

param(
    [switch]$All,
    [switch]$Delete,
    [switch]$List,
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Packages
)

# Colors for output
function Write-Info { Write-Host "  [+] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "  [!] $args" -ForegroundColor Yellow }
function Write-Err  { Write-Host "  [-] $args" -ForegroundColor Red }

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
        $lines = @(& git config -f $source --get-regexp '^(user\.|credential\.|gpg\.|commit\.gpgsign$|tag\.gpgsign$)' 2>$null)
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

$dotfilesDir = Split-Path -Parent $PSCommandPath
$homeDir = $env:USERPROFILE

# Package mappings: source (relative to dotfiles dir) -> target (absolute path)
# Mirrors what GNU Stow would do, with Windows-specific target paths.
$packageMappings = @{
    "git" = @(
        @{ Source = "git\.gitconfig"; Target = "$homeDir\.gitconfig" }
        @{ Source = "git\.git-hooks"; Target = "$homeDir\.git-hooks" }
    )
    "clang" = @(
        @{ Source = "clang\.clang-format"; Target = "$homeDir\.clang-format" }
        @{ Source = "clang\.clang-tidy";   Target = "$homeDir\.clang-tidy" }
    )
    "nvim" = @(
        # Windows: nvim config lives in %LOCALAPPDATA%\nvim, not ~/.config/nvim
        @{ Source = "nvim\.config\nvim"; Target = "$env:LOCALAPPDATA\nvim" }
    )
    "starship" = @(
        @{ Source = "starship\.config\starship.toml"; Target = "$homeDir\.config\starship.toml" }
    )
    "bash" = @(
        @{ Source = "bash\.bashrc-windows"; Target = "$homeDir\.bashrc" }
    )
}

# List packages and exit
if ($List) {
    Write-Host "Available packages:" -ForegroundColor Cyan
    foreach ($pkg in ($packageMappings.Keys | Sort-Object)) {
        $mappings = $packageMappings[$pkg]
        Write-Host "  $pkg" -ForegroundColor White
        foreach ($m in $mappings) {
            Write-Host "    $($m.Source) -> $($m.Target)" -ForegroundColor DarkGray
        }
    }
    exit 0
}

# Resolve which packages to process
if ($All) {
    $Packages = $packageMappings.Keys | Sort-Object
} elseif (-not $Packages -or $Packages.Count -eq 0) {
    Write-Host "Usage: .\stow_windows.ps1 [-All] [-Delete] [-List] <package ...>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\stow_windows.ps1 git           # Link git package"
    Write-Host "  .\stow_windows.ps1 -All           # Link all packages"
    Write-Host "  .\stow_windows.ps1 -Delete git    # Remove git symlinks"
    Write-Host "  .\stow_windows.ps1 -List          # Show available packages"
    exit 1
}

# Validate packages
foreach ($pkg in $Packages) {
    if (-not $packageMappings.ContainsKey($pkg)) {
        Write-Err "Unknown package: $pkg"
        Write-Host "  Run .\stow_windows.ps1 -List to see available packages" -ForegroundColor DarkGray
        exit 1
    }
}

$action = if ($Delete) { "Unstowing" } else { "Stowing" }
Write-Host "$action packages: $($Packages -join ', ')" -ForegroundColor Cyan

if (-not $Delete -and $Packages -contains 'git') {
    Initialize-GitconfigLocal
}

foreach ($pkg in $Packages) {
    Write-Host ""
    Write-Host "  $pkg" -ForegroundColor White

    foreach ($mapping in $packageMappings[$pkg]) {
        $sourcePath = Join-Path $dotfilesDir $mapping.Source
        $targetPath = $mapping.Target

        if ($Delete) {
            # Remove symlink
            if (Test-Path $targetPath) {
                $item = Get-Item $targetPath -Force
                if ($item.LinkType -eq "SymbolicLink") {
                    Remove-Item $targetPath -Force
                    Write-Info "Removed: $targetPath"
                } else {
                    Write-Warn "Skipped (not a symlink): $targetPath"
                }
            } else {
                Write-Warn "Not found: $targetPath"
            }
        } else {
            # Create symlink
            if (-not (Test-Path $sourcePath)) {
                Write-Err "Source not found: $sourcePath"
                continue
            }

            # Check if target already exists
            if (Test-Path $targetPath) {
                $item = Get-Item $targetPath -Force
                if ($item.LinkType -eq "SymbolicLink") {
                    $existingTarget = $item.Target
                    if ($existingTarget -eq $sourcePath) {
                        Write-Info "Already linked: $targetPath"
                        continue
                    }
                    # Remove old symlink and re-create
                    Remove-Item $targetPath -Force
                } else {
                    Write-Warn "Backing up existing: $targetPath -> $targetPath.bak"
                    Move-Item $targetPath "$targetPath.bak" -Force
                }
            }

            # Create parent directory if needed
            $parentDir = Split-Path -Parent $targetPath
            if (-not (Test-Path $parentDir)) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }

            try {
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                Write-Info "Linked: $targetPath -> $($mapping.Source)"
            } catch {
                Write-Err "Failed: $targetPath - $_"
                Write-Host "    Make sure Developer Mode is enabled or run as Administrator" -ForegroundColor DarkGray
            }
        }
    }
}

Write-Host ""
