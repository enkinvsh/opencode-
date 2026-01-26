#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Oh-My-OpenCode Universal Installer for Windows
.DESCRIPTION
    Checks for Node.js/Bun and runs the oh-my-opencode install wizard
.EXAMPLE
    irm https://raw.githubusercontent.com/user/repo/main/install.ps1 | iex
#>

param(
    [Switch]$NoColor = $false,
    [Switch]$SkipAuthCheck = $false
)

$ErrorActionPreference = 'Stop'

$PACKAGE_NAME = "oh-my-opencode"
$CONFIG_DIR = "$env:USERPROFILE\.config\opencode"
$MIN_NODE_VERSION = 18

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Ok { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Test-Command {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Get-NodeMajorVersion {
    if (Test-Command "node") {
        $version = (node --version) -replace '^v', ''
        [int]($version -split '\.')[0]
    } else {
        0
    }
}

function Test-WindowsVersion {
    $MinBuild = 17763
    $WinVer = [System.Environment]::OSVersion.Version
    
    if ($WinVer.Major -lt 10 -or ($WinVer.Major -eq 10 -and $WinVer.Build -lt $MinBuild)) {
        Write-Warn "Windows 10 1809 (build $MinBuild) or newer recommended."
        Write-Warn "Current: Windows $($WinVer.Major) build $($WinVer.Build)"
        return $false
    }
    return $true
}

function Get-PackageManager {
    if (Test-Command "bun") {
        return "bun"
    } elseif (Test-Command "npm") {
        return "npm"
    } elseif (Test-Command "pnpm") {
        return "pnpm"
    } elseif (Test-Command "yarn") {
        return "yarn"
    }
    return "none"
}

function Show-NodeInstallHint {
    Write-Host ""
    Write-Err "Node.js v$MIN_NODE_VERSION+ or Bun is required but not found."
    Write-Host ""
    Write-Host "Install options:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  # Using winget (recommended):" -ForegroundColor Gray
    Write-Host "  winget install OpenJS.NodeJS.LTS"
    Write-Host ""
    Write-Host "  # Or install Bun:" -ForegroundColor Gray
    Write-Host "  powershell -c `"irm bun.sh/install.ps1 | iex`""
    Write-Host ""
    Write-Host "  # Or download manually:" -ForegroundColor Gray
    Write-Host "  https://nodejs.org/en/download/"
    Write-Host ""
    Write-Host "After installing, restart PowerShell and re-run this installer."
    Write-Host ""
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    $null = Test-WindowsVersion
    
    $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    Write-Info "Platform: Windows ($arch)"
    
    Write-Ok "Prerequisites check passed"
}

function Test-NodeRuntime {
    Write-Info "Checking Node.js runtime..."
    
    $pkgManager = Get-PackageManager
    
    if ($pkgManager -eq "bun") {
        $bunVersion = (bun --version 2>$null) -replace '^', ''
        Write-Ok "Found Bun v$bunVersion"
        return "bun"
    }
    
    if (Test-Command "node") {
        $nodeVersion = Get-NodeMajorVersion
        
        if ($nodeVersion -ge $MIN_NODE_VERSION) {
            Write-Ok "Found Node.js v$nodeVersion"
            
            if ($pkgManager -ne "none") {
                return $pkgManager
            }
        } else {
            Write-Warn "Node.js v$nodeVersion found, but v$MIN_NODE_VERSION+ is required"
        }
    }
    
    return "none"
}

function Invoke-SetupWizard {
    param([string]$PkgManager)
    
    Write-Info "Running oh-my-opencode setup wizard..."
    Write-Host ""
    
    switch ($PkgManager) {
        "bun" {
            bunx $PACKAGE_NAME install
        }
        "npm" {
            npx $PACKAGE_NAME install
        }
        "pnpm" {
            pnpm dlx $PACKAGE_NAME install
        }
        "yarn" {
            yarn dlx $PACKAGE_NAME install
        }
        default {
            if (Test-Command "oh-my-opencode") {
                oh-my-opencode install
            } else {
                throw "Could not run setup wizard"
            }
        }
    }
}

function Test-AuthPlugins {
    if ($SkipAuthCheck) {
        Write-Info "Skipping auth plugins check (--SkipAuthCheck)"
        return
    }
    
    Write-Info "Checking auth plugins configuration..."
    
    $configFile = Join-Path $CONFIG_DIR "opencode.json"
    
    if (Test-Path $configFile) {
        $content = Get-Content $configFile -Raw
        if ($content -match "opencode-antigravity-auth") {
            Write-Ok "Antigravity auth plugin already configured"
        } else {
            Write-Warn "Antigravity auth plugin not found in config"
            Write-Info "You may need to add it manually or run 'opencode auth login'"
        }
    } else {
        Write-Warn "OpenCode config not found at $configFile"
        Write-Info "The setup wizard will create it for you"
    }
}

function Show-SuccessMessage {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "   Oh-My-OpenCode installed successfully!   " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Authenticate with Antigravity:" -ForegroundColor White
    Write-Host "     opencode auth login" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  2. Start OpenCode:" -ForegroundColor White
    Write-Host "     opencode" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  3. Check quota status (inside opencode):" -ForegroundColor White
    Write-Host "     /antigravity-quota" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Documentation:" -ForegroundColor White
    Write-Host "  - GitHub: https://github.com/code-yeongyu/oh-my-opencode" -ForegroundColor Gray
    Write-Host ""
}

function Main {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Oh-My-OpenCode Universal Installer   " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-Prerequisites
    
    $pkgManager = Test-NodeRuntime
    
    if ($pkgManager -eq "none") {
        Show-NodeInstallHint
        exit 1
    }
    
    Write-Host ""
    Invoke-SetupWizard -PkgManager $pkgManager
    
    Test-AuthPlugins
    
    Show-SuccessMessage
}

Main
