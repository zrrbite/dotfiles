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
