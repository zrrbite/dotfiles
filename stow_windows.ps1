# stow_windows.ps1 - GNU Stow equivalent for Windows
# Creates/removes symlinks from dotfiles packages to their target locations.
#
# Usage:
#   .\stow_windows.ps1 -List            # Show available packages
#   .\stow_windows.ps1 -DryRun git nvim # Show what would happen; change nothing
#   .\stow_windows.ps1 git              # Link the git package
#   .\stow_windows.ps1 git nvim clang   # Link multiple packages
#   .\stow_windows.ps1 -All             # Link all supported packages
#   .\stow_windows.ps1 -Delete git      # Remove symlinks for a package
#
# Requires the right to create symlinks: Developer Mode (Windows 10 AND 11)
# or an elevated shell. A non-admin user on Windows 11 without Developer Mode
# cannot create them. The script checks this before touching anything.
#
# Safe to re-run. An existing real file is moved to <target>.bak-<timestamp>
# (never overwriting an earlier backup) only once the link is certain to
# work, and moved back if creating the link fails anyway.

param(
    [switch]$All,
    [switch]$Delete,
    [switch]$List,
    [switch]$DryRun,
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Packages
)

# Colors for output
function Write-Info { Write-Host "  [+] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "  [!] $args" -ForegroundColor Yellow }
function Write-Err  { Write-Host "  [-] $args" -ForegroundColor Red }
function Write-Dry  { Write-Host "  [dry] $args" -ForegroundColor Cyan }

# Mappings below are written with backslashes; normalise to this platform's
# separator. On Windows that changes nothing -- it lets the script be tested
# under PowerShell on macOS/Linux with a scratch USERPROFILE.
function ConvertTo-PlatformPath([string]$Path) {
    return $Path -replace '[\\/]', [IO.Path]::DirectorySeparatorChar
}

# git\.gitconfig carries no identity or credential helper; those live in
# ~\.gitconfig.local, which it includes last. Carry the existing per-machine
# settings over before ~\.gitconfig is replaced, so a machine keeps its own
# identity (a work laptop keeps its work email) and its network setup.
# Mirrors scripts/seed-gitconfig-local.sh -- keep the key list in step.
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
        $keys = '^(user\.|credential\.|gpg\.|commit\.gpgsign$|tag\.gpgsign$|http\.|https\.|includeif\.|url\.|core\.autocrlf$|core\.sshcommand$)'
        $lines = @(& git config -f $source --get-regexp $keys 2>$null)
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
        if ($DryRun) {
            Write-Dry "would carry over to ~\.gitconfig.local: $key"
            continue
        }
        & git config -f $localCfg --add $key $value
        Write-Info "Carried over to ~\.gitconfig.local: $key"
    }
}

# Can this user create symlinks at all? Answered once, up front, in a scratch
# directory -- so a machine that can't never gets as far as moving a real
# config aside.
function Test-SymlinkPermission {
    $probeDir = Join-Path ([IO.Path]::GetTempPath()) ("stow-probe-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $probeDir | Out-Null
    $target = Join-Path $probeDir "target"
    $link = Join-Path $probeDir "link"
    Set-Content -Path $target -Value "probe"
    try {
        New-Item -ItemType SymbolicLink -Path $link -Target $target -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    } finally {
        Remove-Item $probeDir -Recurse -Force -ErrorAction SilentlyContinue
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
        # .gitconfig points core.excludesFile here
        @{ Source = "git\.gitignore-global"; Target = "$homeDir\.gitignore-global" }
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
        # Git Bash's terminal (mintty): Nord colours and font
        @{ Source = "bash\.minttyrc"; Target = "$homeDir\.minttyrc" }
    )
    "fastfetch" = @(
        @{ Source = "fastfetch\.config\fastfetch\config-windows.jsonc"; Target = "$homeDir\.config\fastfetch\config.jsonc" }
    )
    "glazewm" = @(
        @{ Source = "glazewm\.glzr\glazewm\config.yaml"; Target = "$homeDir\.glzr\glazewm\config.yaml" }
    )
    "zebar" = @(
        @{ Source = "zebar\.glzr\zebar\settings.json"; Target = "$homeDir\.glzr\zebar\settings.json" }
    )
    # Skills only. claude\.claude\CLAUDE.md holds personal working rules (it
    # sends tasks to a private repo) and is deliberately not linked here.
    "claude" = @(
        @{ Source = "claude\.claude\skills"; Target = "$homeDir\.claude\skills" }
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
    Write-Host "Usage: .\stow_windows.ps1 [-All] [-Delete] [-DryRun] [-List] <package ...>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\stow_windows.ps1 -List          # Show available packages"
    Write-Host "  .\stow_windows.ps1 -DryRun git    # Preview, change nothing"
    Write-Host "  .\stow_windows.ps1 git            # Link git package"
    Write-Host "  .\stow_windows.ps1 -Delete git    # Remove git symlinks"
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

function Write-SymlinkHelp {
    Write-Host "    Enable Developer Mode (Settings > System > For developers), or run" -ForegroundColor DarkGray
    Write-Host "    from an elevated shell. On a managed machine this may need IT." -ForegroundColor DarkGray
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # Windows PowerShell 5.1's New-Item has been reported to need elevation
        # for symlinks even with Developer Mode on; PowerShell 7 does not.
        Write-Host "    This is Windows PowerShell $($PSVersionTable.PSVersion); if Developer Mode is" -ForegroundColor DarkGray
        Write-Host "    already on, try PowerShell 7 (pwsh) instead." -ForegroundColor DarkGray
    }
}

# Probed in a dry run too, so a preview can't look clean on a machine where
# the real run would stop.
if (-not $Delete -and -not (Test-SymlinkPermission)) {
    if ($DryRun) {
        Write-Warn "This account cannot create symlinks -- a real run would stop here."
        Write-SymlinkHelp
    } else {
        Write-Err "This account cannot create symlinks, so nothing was changed."
        Write-SymlinkHelp
        exit 1
    }
}

$action = if ($Delete) { "Unstowing" } elseif ($DryRun) { "Dry run for" } else { "Stowing" }
Write-Host "$action packages: $($Packages -join ', ')" -ForegroundColor Cyan

if (-not $Delete -and $Packages -contains 'git') {
    Initialize-GitconfigLocal
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$failures = 0

foreach ($pkg in $Packages) {
    Write-Host ""
    Write-Host "  $pkg" -ForegroundColor White

    foreach ($mapping in $packageMappings[$pkg]) {
        $sourcePath = ConvertTo-PlatformPath (Join-Path $dotfilesDir $mapping.Source)
        $targetPath = ConvertTo-PlatformPath $mapping.Target

        if ($Delete) {
            if (Test-Path $targetPath) {
                $item = Get-Item $targetPath -Force
                if ($item.LinkType -eq "SymbolicLink") {
                    if ($DryRun) { Write-Dry "would remove $targetPath"; continue }
                    Remove-Item $targetPath -Force
                    Write-Info "Removed: $targetPath"
                } else {
                    Write-Warn "Skipped (not a symlink): $targetPath"
                }
            } else {
                Write-Warn "Not found: $targetPath"
            }
            continue
        }

        if (-not (Test-Path $sourcePath)) {
            Write-Err "Source not found: $sourcePath"
            $failures++
            continue
        }

        # What is there now?
        $backup = $null
        if (Test-Path $targetPath) {
            $item = Get-Item $targetPath -Force
            if ($item.LinkType -eq "SymbolicLink") {
                if ((ConvertTo-PlatformPath "$($item.Target)") -eq $sourcePath) {
                    Write-Info "Already linked: $targetPath"
                    continue
                }
                if ($DryRun) { Write-Dry "would replace symlink $targetPath -> $sourcePath"; continue }
                Remove-Item $targetPath -Force
            } else {
                $backup = "$targetPath.bak-$stamp"
                if ($DryRun) {
                    Write-Dry "would move $targetPath -> $backup, then link it to $($mapping.Source)"
                    continue
                }
            }
        } elseif ($DryRun) {
            Write-Dry "would link $targetPath -> $($mapping.Source)"
            continue
        }

        $parentDir = Split-Path -Parent $targetPath
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        try {
            if ($backup) {
                Move-Item $targetPath $backup -ErrorAction Stop
                Write-Warn "Backed up existing: $targetPath -> $backup"
            }
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -ErrorAction Stop | Out-Null
            Write-Info "Linked: $targetPath -> $($mapping.Source)"
        } catch {
            Write-Err "Failed: $targetPath - $_"
            $failures++
            # Put the original back, so a failed link never leaves the
            # machine without its config.
            if ($backup -and (Test-Path $backup) -and -not (Test-Path $targetPath)) {
                Move-Item $backup $targetPath
                Write-Warn "Restored the original: $targetPath"
            }
        }
    }
}

Write-Host ""
if ($failures -gt 0) {
    Write-Err "$failures item(s) failed -- see above."
    exit 1
}
