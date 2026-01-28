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
    # On Windows, prefer npm over bun due to bun stability issues
    # Bun on Windows has known segmentation fault issues
    if (Test-Command "npm") {
        return "npm"
    } elseif (Test-Command "pnpm") {
        return "pnpm"
    } elseif (Test-Command "yarn") {
        return "yarn"
    } elseif (Test-Command "bun") {
        Write-Warn "Bun detected, but using npm is recommended on Windows due to stability issues"
        return "bun"
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

function Test-OpenCodeInstalled {
    # Check for opencode binary in PATH
    if (Test-Command "opencode") {
        return $true
    }
    # Check common installation locations
    $commonPaths = @(
        "$env:APPDATA\npm\opencode.cmd",
        "$env:APPDATA\npm\opencode",
        "$env:USERPROFILE\.bun\bin\opencode.exe",
        "$env:USERPROFILE\scoop\shims\opencode.exe",
        "C:\ProgramData\chocolatey\bin\opencode.exe"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $true
        }
    }
    return $false
}

function Install-OpenCode {
    param([string]$PkgManager)
    
    Write-Info "Installing OpenCode CLI..."
    Write-Host ""
    
    switch ($PkgManager) {
        "bun" {
            bun install -g opencode-ai
        }
        "npm" {
            npm install -g opencode-ai
        }
        "pnpm" {
            pnpm install -g opencode-ai
        }
        "yarn" {
            yarn global add opencode-ai
        }
        default {
            throw "No package manager available to install OpenCode"
        }
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "OpenCode installation via $PkgManager may have failed."
        Write-Host ""
        Write-Host "Alternative installation methods:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  # Using Scoop (recommended for Windows):" -ForegroundColor Gray
        Write-Host "  scoop install opencode"
        Write-Host ""
        Write-Host "  # Using Chocolatey:" -ForegroundColor Gray
        Write-Host "  choco install opencode"
        Write-Host ""
        return $false
    }
    
    Write-Ok "OpenCode installed successfully"
    return $true
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
    param([string]$PkgManager = "npm")
    
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
            Write-Info "Adding plugin to configuration..."
            Install-AntigravityAuthPlugin -PkgManager $PkgManager
        }
    } else {
        Write-Warn "OpenCode config not found at $configFile"
        Write-Info "Creating config with Antigravity auth plugin..."
        Install-AntigravityAuthPlugin -PkgManager $PkgManager
    }
}

function Install-AntigravityAuthPlugin {
    param([string]$PkgManager = "npm")
    
    # Install npm packages for plugins
    Write-Info "Installing oh-my-opencode plugins via npm..."
    
    try {
        npm install -g oh-my-opencode 2>$null
        npm install -g opencode-antigravity-auth@1.3.2 2>$null
        npm install -g opencode-antigravity-quota@0.1.6 2>$null
        Write-Ok "Plugins installed successfully"
    } catch {
        Write-Warn "Some plugins may have failed to install"
    }
    
    # Ensure config directory exists
    if (-not (Test-Path $CONFIG_DIR)) {
        New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
    }
    
    $configFile = Join-Path $CONFIG_DIR "opencode.json"
    $omoConfigFile = Join-Path $CONFIG_DIR "oh-my-opencode.json"
    
    # Always create fresh opencode.json with full config
    Create-FreshConfig -ConfigFile $configFile
    
    # Create oh-my-opencode.json with agent configuration
    if (-not (Test-Path $omoConfigFile)) {
        Create-OmoConfig -ConfigFile $omoConfigFile
    }
}

function Create-FreshConfig {
    param([string]$ConfigFile)
    
    # Full OpenCode config with schema, plugins and provider
    # Based on setup-opencode.md documentation
    $configJson = @'
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "oh-my-opencode",
    "opencode-antigravity-auth@1.3.2",
    "opencode-antigravity-quota@0.1.6"
  ],
  "provider": {
    "google": {
      "name": "Google",
      "models": {
        "antigravity-claude-opus-4-5-thinking": {
          "name": "Claude Opus 4.5 Thinking (Antigravity)",
          "attachment": true,
          "limit": { "context": 200000, "output": 64000 },
          "modalities": { "input": ["text", "image", "pdf"], "output": ["text"] }
        },
        "antigravity-claude-sonnet-4-5-thinking": {
          "name": "Claude Sonnet 4.5 Thinking (Antigravity)",
          "attachment": true,
          "limit": { "context": 200000, "output": 64000 },
          "modalities": { "input": ["text", "image", "pdf"], "output": ["text"] }
        },
        "antigravity-gemini-3-flash": {
          "name": "Gemini 3 Flash (Antigravity)",
          "attachment": true,
          "limit": { "context": 1048576, "output": 65536 },
          "modalities": { "input": ["text", "image", "pdf"], "output": ["text"] }
        },
        "antigravity-gemini-3-pro": {
          "name": "Gemini 3 Pro (Antigravity)",
          "attachment": true,
          "limit": { "context": 1048576, "output": 65535 },
          "modalities": { "input": ["text", "image", "pdf"], "output": ["text"] }
        }
      }
    }
  }
}
'@
    
    $configJson | Set-Content $ConfigFile -Encoding UTF8
    Write-Ok "Created opencode.json with full Antigravity configuration"
}

function Create-OmoConfig {
    param([string]$ConfigFile)
    
    # oh-my-opencode.json with agent configuration
    # Based on setup-opencode.md documentation
    $configJson = @'
{
  "$schema": "https://oh-my-opencode.dev/schema.json",
  
  "agents": {
    "sisyphus": {
      "model": "google/antigravity-claude-opus-4-5-thinking",
      "variant": "max",
      "thinking": { "type": "enabled", "budgetTokens": 32000 }
    },
    "sisyphus-junior": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "max",
      "thinking": { "type": "enabled", "budgetTokens": 16000 }
    },
    "prometheus": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "max",
      "thinking": { "type": "enabled", "budgetTokens": 16000 }
    },
    "atlas": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "max",
      "thinking": { "type": "enabled", "budgetTokens": 16000 }
    },
    "oracle": {
      "model": "google/antigravity-claude-opus-4-5-thinking",
      "variant": "max",
      "thinking": { "type": "enabled", "budgetTokens": 32000 }
    },
    "explore": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "low",
      "thinking": { "type": "enabled", "budgetTokens": 8192 }
    },
    "librarian": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "low",
      "thinking": { "type": "enabled", "budgetTokens": 8192 }
    }
  },

  "categories": {
    "ultrabrain": {
      "model": "google/antigravity-claude-opus-4-5-thinking",
      "variant": "max",
      "thinking": { "type": "enabled", "budgetTokens": 32000 }
    },
    "visual-engineering": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "max",
      "thinking": { "type": "enabled", "budgetTokens": 16000 }
    },
    "quick": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "low",
      "thinking": { "type": "enabled", "budgetTokens": 8192 }
    }
  },

  "sisyphus_agent": {
    "disabled": false,
    "planner_enabled": true,
    "replace_plan": true
  }
}
'@
    
    $configJson | Set-Content $ConfigFile -Encoding UTF8
    Write-Ok "Created oh-my-opencode.json with agent configuration"
}

function Show-SuccessMessage {
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "   Oh-My-OpenCode installed successfully!   " -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    
    # Check if opencode is available in PATH
    if (-not (Test-Command "opencode")) {
        Write-Host ""
        Write-Host "IMPORTANT: 'opencode' command not found in PATH!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "You need to restart your terminal (close and reopen PowerShell)" -ForegroundColor Yellow
        Write-Host "for the PATH changes to take effect." -ForegroundColor Yellow
        Write-Host ""
        
        # Show where the binary might be located
        $bunBinPath = "$env:USERPROFILE\.bun\bin"
        $npmBinPath = "$env:APPDATA\npm"
        
        if (Test-Path $bunBinPath) {
            Write-Host "Bun bin directory found at: $bunBinPath" -ForegroundColor Gray
        }
        if (Test-Path $npmBinPath) {
            Write-Host "npm bin directory found at: $npmBinPath" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "If 'opencode' still doesn't work after restart, ensure the bin" -ForegroundColor Gray
        Write-Host "directory is in your PATH environment variable." -ForegroundColor Gray
        Write-Host ""
    }
    
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
    
    # Check if OpenCode is installed, install if not
    Write-Host ""
    Write-Info "Checking OpenCode installation..."
    
    if (-not (Test-OpenCodeInstalled)) {
        Write-Warn "OpenCode CLI not found. Installing..."
        $installed = Install-OpenCode -PkgManager $pkgManager
        if (-not $installed) {
            Write-Err "Failed to install OpenCode. Please install it manually and re-run this script."
            exit 1
        }
    } else {
        Write-Ok "OpenCode CLI is already installed"
    }
    
    Write-Host ""
    Invoke-SetupWizard -PkgManager $pkgManager
    
    Test-AuthPlugins -PkgManager $pkgManager
    
    Show-SuccessMessage
}

Main
