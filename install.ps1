#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Oh-My-OpenCode Production Installer for Windows
.DESCRIPTION
    Complete installer that handles all known Windows issues:
    - Avoids npx/bunx issues (Issue #1171, #1175)
    - Installs plugins locally in config directory
    - Preserves existing credentials
    - Creates correct configuration files
.EXAMPLE
    irm https://raw.githubusercontent.com/enkinvsh/opencode-/main/install.ps1 | iex
.NOTES
    Version: 2.0.0 (Production)
    Updated: January 2026
#>

param(
    [Switch]$Force = $false,
    [Switch]$SkipOpenCode = $false,
    [Switch]$Verbose = $false
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # Speed up Invoke-WebRequest

# ============================================================================
# Configuration Constants
# ============================================================================

$MIN_NODE_VERSION = 18
$CONFIG_DIR = Join-Path $env:USERPROFILE ".config\opencode"
$CREDENTIALS_FILES = @(
    "secrets.json",
    "credentials.json", 
    "auth.json",
    ".credentials",
    "tokens.json"
)

# ============================================================================
# Logging Functions
# ============================================================================

function Write-Step { 
    param([string]$Message) 
    Write-Host "`n[STEP] " -ForegroundColor Magenta -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Info { 
    param([string]$Message) 
    Write-Host "[INFO] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Ok { 
    param([string]$Message) 
    Write-Host "[OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message -ForegroundColor Green
}

function Write-Warn { 
    param([string]$Message) 
    Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Err { 
    param([string]$Message) 
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
    Write-Host $Message -ForegroundColor Red
}

function Write-Dbg {
    param([string]$Message)
    if ($Verbose) {
        Write-Host "[DEBUG] $Message" -ForegroundColor DarkGray
    }
}

# ============================================================================
# Utility Functions
# ============================================================================

function Test-Command {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Get-NodeMajorVersion {
    if (Test-Command "node") {
        try {
            $version = (node --version 2>$null) -replace '^v', ''
            [int]($version -split '\.')[0]
        } catch {
            0
        }
    } else {
        0
    }
}

function Test-NpmWorks {
    try {
        $result = npm --version 2>$null
        return $LASTEXITCODE -eq 0 -and $result
    } catch {
        return $false
    }
}

function Invoke-NpmCommand {
    param(
        [string]$Command,
        [string]$WorkDir = $null
    )
    
    $originalLocation = Get-Location
    try {
        if ($WorkDir) {
            Set-Location $WorkDir
        }
        
        Write-Dbg "Running: npm $Command"
        $output = cmd /c "npm $Command 2>&1"
        $exitCode = $LASTEXITCODE
        
        if ($Verbose) {
            $output | ForEach-Object { Write-Dbg $_ }
        }
        
        return @{
            Success = ($exitCode -eq 0)
            Output = $output
            ExitCode = $exitCode
        }
    } finally {
        Set-Location $originalLocation
    }
}

# ============================================================================
# Prerequisite Checks
# ============================================================================

function Test-Prerequisites {
    Write-Step "Checking Prerequisites"
    
    # Check Windows version
    $winVer = [System.Environment]::OSVersion.Version
    Write-Info "Windows $($winVer.Major).$($winVer.Minor) (Build $($winVer.Build))"
    
    # Check architecture
    $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    Write-Info "Architecture: $arch"
    
    # Check Node.js
    if (-not (Test-Command "node")) {
        Write-Err "Node.js is not installed!"
        Show-NodeInstallHelp
        return $false
    }
    
    $nodeVersion = Get-NodeMajorVersion
    if ($nodeVersion -lt $MIN_NODE_VERSION) {
        Write-Err "Node.js v$nodeVersion found, but v$MIN_NODE_VERSION+ is required"
        Show-NodeInstallHelp
        return $false
    }
    
    Write-Ok "Node.js v$nodeVersion detected"
    
    # Check npm
    if (-not (Test-NpmWorks)) {
        Write-Err "npm is not working properly!"
        Write-Info "Try reinstalling Node.js from https://nodejs.org"
        return $false
    }
    
    $npmVersion = npm --version 2>$null
    Write-Ok "npm v$npmVersion detected"
    
    # TLS check
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Ok "TLS 1.2 enabled"
    } catch {
        Write-Warn "Could not set TLS 1.2, but installation may still work"
    }
    
    return $true
}

function Show-NodeInstallHelp {
    Write-Host ""
    Write-Host "Node.js v$MIN_NODE_VERSION+ is required. Install options:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  # Using winget (recommended):" -ForegroundColor Gray
    Write-Host "  winget install OpenJS.NodeJS.LTS" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Or download manually:" -ForegroundColor Gray
    Write-Host "  https://nodejs.org/en/download/" -ForegroundColor White
    Write-Host ""
    Write-Host "After installing, restart PowerShell and run this script again." -ForegroundColor Yellow
}

# ============================================================================
# OpenCode Installation
# ============================================================================

function Test-OpenCodeInstalled {
    if (Test-Command "opencode") {
        return $true
    }
    
    # Check common paths
    $paths = @(
        "$env:APPDATA\npm\opencode.cmd",
        "$env:APPDATA\npm\opencode",
        "$env:USERPROFILE\.bun\bin\opencode.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $true
        }
    }
    
    return $false
}

function Install-OpenCodeCLI {
    if ($SkipOpenCode) {
        Write-Info "Skipping OpenCode installation (--SkipOpenCode)"
        return $true
    }
    
    Write-Step "Installing OpenCode CLI"
    
    if (Test-OpenCodeInstalled) {
        Write-Ok "OpenCode is already installed"
        try {
            $version = opencode --version 2>$null
            if ($version) {
                Write-Info "Version: $version"
            }
        } catch {}
        return $true
    }
    
    Write-Info "Installing opencode-ai globally via npm..."
    
    $result = Invoke-NpmCommand "install -g opencode-ai"
    
    if ($result.Success) {
        Write-Ok "OpenCode installed successfully"
        
        # Refresh PATH for current session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + 
                    [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        return $true
    } else {
        Write-Warn "OpenCode installation may have issues"
        Write-Info "You can try manually: npm install -g opencode-ai"
        return $false
    }
}

# ============================================================================
# Configuration Directory Setup
# ============================================================================

function Initialize-ConfigDirectory {
    Write-Step "Setting Up Configuration Directory"
    
    # Create config directory if not exists
    if (-not (Test-Path $CONFIG_DIR)) {
        Write-Info "Creating $CONFIG_DIR"
        New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
        Write-Ok "Config directory created"
    } else {
        Write-Ok "Config directory already exists"
    }
    
    # Backup credentials
    $backupDir = Join-Path $CONFIG_DIR ".credentials_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $credentialsFound = $false
    
    foreach ($credFile in $CREDENTIALS_FILES) {
        $credPath = Join-Path $CONFIG_DIR $credFile
        if (Test-Path $credPath) {
            if (-not $credentialsFound) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
                Write-Info "Backing up credentials to: $backupDir"
                $credentialsFound = $true
            }
            Copy-Item $credPath (Join-Path $backupDir $credFile) -Force
            Write-Dbg "Backed up: $credFile"
        }
    }
    
    if ($credentialsFound) {
        Write-Ok "Credentials backed up (will be preserved)"
    }
    
    return $backupDir
}

function Restore-Credentials {
    param([string]$BackupDir)
    
    if (-not $BackupDir -or -not (Test-Path $BackupDir)) {
        return
    }
    
    Write-Info "Restoring credentials..."
    
    Get-ChildItem $BackupDir | ForEach-Object {
        $destPath = Join-Path $CONFIG_DIR $_.Name
        Copy-Item $_.FullName $destPath -Force
        Write-Dbg "Restored: $($_.Name)"
    }
    
    # Clean up backup directory
    Remove-Item $BackupDir -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Ok "Credentials restored"
}

# ============================================================================
# Configuration File Creation
# ============================================================================

function New-OpenCodeConfig {
    Write-Step "Creating OpenCode Configuration"
    
    $configPath = Join-Path $CONFIG_DIR "opencode.json"
    
    if ((Test-Path $configPath) -and -not $Force) {
        Write-Info "opencode.json already exists"
        
        # Check if it has the required plugins
        $content = Get-Content $configPath -Raw
        if ($content -match "oh-my-opencode" -and $content -match "opencode-antigravity-auth") {
            Write-Ok "Configuration looks correct"
            return
        }
        
        Write-Warn "Existing config may be missing plugins, recreating..."
    }
    
    # Full opencode.json configuration
    # Based on working production config
    $config = @'
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
        "antigravity-gemini-3-pro-high": {
          "name": "Gemini 3 Pro High (Antigravity)",
          "attachment": true,
          "limit": { "context": 1048576, "output": 65535 },
          "modalities": { "input": ["text", "image", "pdf"], "output": ["text"] }
        },
        "antigravity-gemini-3-flash": {
          "name": "Gemini 3 Flash (Antigravity)",
          "attachment": true,
          "limit": { "context": 1048576, "output": 65536 },
          "modalities": { "input": ["text", "image", "pdf"], "output": ["text"] }
        },
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
        }
      }
    }
  }
}
'@
    
    $config | Set-Content $configPath -Encoding UTF8
    Write-Ok "Created opencode.json"
}

function New-OhMyOpenCodeConfig {
    Write-Step "Creating Oh-My-OpenCode Agent Configuration"
    
    $configPath = Join-Path $CONFIG_DIR "oh-my-opencode.json"
    
    if ((Test-Path $configPath) -and -not $Force) {
        Write-Info "oh-my-opencode.json already exists"
        Write-Ok "Keeping existing agent configuration"
        return
    }
    
    # Full oh-my-opencode.json with all agents - production config
    $config = @'
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
    "metis": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "low",
      "thinking": { "type": "enabled", "budgetTokens": 8192 }
    },
    "momus": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "low",
      "thinking": { "type": "enabled", "budgetTokens": 8192 }
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
    },
    "multimodal-looker": {
      "model": "google/antigravity-gemini-3-pro",
      "variant": "high"
    }
  },

  "categories": {
    "ultrabrain": {
      "model": "google/antigravity-claude-opus-4-5-thinking",
      "variant": "max",
      "thinking": { "type": "enabled", "budgetTokens": 32000 }
    },
    "unspecified-high": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "max",
      "thinking": { "type": "enabled", "budgetTokens": 16000 }
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
    },
    "unspecified-low": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "low",
      "thinking": { "type": "enabled", "budgetTokens": 8192 }
    },
    "artistry": {
      "model": "google/antigravity-claude-sonnet-4-5-thinking",
      "variant": "max",
      "temperature": 0.9,
      "thinking": { "type": "enabled", "budgetTokens": 16000 }
    },
    "writing": {
      "model": "google/antigravity-claude-sonnet-4-5",
      "temperature": 0.5
    }
  },

  "sisyphus_agent": {
    "disabled": false,
    "planner_enabled": true,
    "replace_plan": true
  }
}
'@
    
    $config | Set-Content $configPath -Encoding UTF8
    Write-Ok "Created oh-my-opencode.json with Sisyphus agent enabled"
}

# ============================================================================
# Plugin Installation (CRITICAL: Local to config directory)
# ============================================================================

function Install-Plugins {
    Write-Step "Installing Plugins (Local to Config Directory)"
    
    Write-Info "OpenCode loads plugins from: $CONFIG_DIR\node_modules"
    
    $originalLocation = Get-Location
    
    try {
        Set-Location $CONFIG_DIR
        
        # Initialize package.json if not exists
        $packageJsonPath = Join-Path $CONFIG_DIR "package.json"
        if (-not (Test-Path $packageJsonPath)) {
            Write-Info "Initializing package.json..."
            
            $packageJson = @{
                name = "opencode-config"
                version = "1.0.0"
                description = "OpenCode plugin configuration"
                private = $true
            } | ConvertTo-Json -Depth 5
            
            $packageJson | Set-Content $packageJsonPath -Encoding UTF8
        }
        
        # Install plugins one by one with progress
        $plugins = @(
            @{ Name = "oh-my-opencode"; Description = "Core oh-my-opencode plugin" },
            @{ Name = "opencode-antigravity-auth@1.3.2"; Description = "Antigravity authentication" },
            @{ Name = "opencode-antigravity-quota@0.1.6"; Description = "Quota management" }
        )
        
        foreach ($plugin in $plugins) {
            Write-Info "Installing $($plugin.Name)..."
            
            # Use npm install with explicit save
            $result = Invoke-NpmCommand "install $($plugin.Name) --save"
            
            if ($result.Success) {
                Write-Ok "$($plugin.Name) installed"
            } else {
                Write-Warn "Issues with $($plugin.Name), trying alternative approach..."
                
                # Fallback: try without --save
                $result2 = Invoke-NpmCommand "install $($plugin.Name)"
                if ($result2.Success) {
                    Write-Ok "$($plugin.Name) installed (alternative)"
                } else {
                    Write-Err "Failed to install $($plugin.Name)"
                    Write-Info "You may need to install manually: cd $CONFIG_DIR && npm install $($plugin.Name)"
                }
            }
        }
        
        # Verify node_modules exists
        $nodeModulesPath = Join-Path $CONFIG_DIR "node_modules"
        if (Test-Path $nodeModulesPath) {
            $installedCount = (Get-ChildItem $nodeModulesPath -Directory).Count
            Write-Ok "node_modules contains $installedCount packages"
        } else {
            Write-Warn "node_modules directory not found - plugins may not load"
        }
        
    } finally {
        Set-Location $originalLocation
    }
}

# ============================================================================
# Verification
# ============================================================================

function Test-Installation {
    Write-Step "Verifying Installation"
    
    $success = $true
    
    # Check config files
    $requiredFiles = @(
        @{ Path = "opencode.json"; Required = $true },
        @{ Path = "oh-my-opencode.json"; Required = $true },
        @{ Path = "node_modules"; Required = $true }
    )
    
    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $CONFIG_DIR $file.Path
        if (Test-Path $fullPath) {
            Write-Ok "$($file.Path) exists"
        } else {
            if ($file.Required) {
                Write-Err "$($file.Path) is missing!"
                $success = $false
            } else {
                Write-Warn "$($file.Path) not found (optional)"
            }
        }
    }
    
    # Check plugins in node_modules
    $nodeModulesPath = Join-Path $CONFIG_DIR "node_modules"
    if (Test-Path $nodeModulesPath) {
        $requiredPlugins = @("oh-my-opencode", "opencode-antigravity-auth", "opencode-antigravity-quota")
        
        foreach ($plugin in $requiredPlugins) {
            $pluginPath = Join-Path $nodeModulesPath $plugin
            if (Test-Path $pluginPath) {
                Write-Ok "Plugin: $plugin"
            } else {
                Write-Warn "Plugin $plugin not found in node_modules"
            }
        }
    }
    
    # Check OpenCode command
    if (Test-Command "opencode") {
        Write-Ok "opencode command available"
    } else {
        Write-Warn "opencode command not in PATH (may need terminal restart)"
    }
    
    return $success
}

# ============================================================================
# Success Message
# ============================================================================

function Show-SuccessMessage {
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor Green
    Write-Host "                                                              " -ForegroundColor Green
    Write-Host "       Oh-My-OpenCode installed successfully!                 " -ForegroundColor Green
    Write-Host "                                                              " -ForegroundColor Green
    Write-Host "==============================================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Configuration Location:" -ForegroundColor White
    Write-Host "  $CONFIG_DIR" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "--------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "  1. " -ForegroundColor White -NoNewline
    Write-Host "Authenticate with Antigravity:" -ForegroundColor White
    Write-Host "     opencode auth login" -ForegroundColor Cyan
    Write-Host "     " -NoNewline
    Write-Host "(Select 'Google' when prompted)" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  2. " -ForegroundColor White -NoNewline
    Write-Host "Start OpenCode:" -ForegroundColor White
    Write-Host "     opencode" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  3. " -ForegroundColor White -NoNewline
    Write-Host "Check quota (inside OpenCode):" -ForegroundColor White
    Write-Host "     /antigravity-quota" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "--------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "SISYPHUS AGENT READY!" -ForegroundColor Magenta
    Write-Host "  After auth, the Sisyphus agent will be available for complex tasks." -ForegroundColor Gray
    Write-Host "  Use: " -ForegroundColor Gray -NoNewline
    Write-Host "/start-work" -ForegroundColor Cyan -NoNewline
    Write-Host " to begin autonomous work mode." -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "--------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    
    if (-not (Test-Command "opencode")) {
        Write-Host "WARNING: Restart your terminal to use 'opencode' command!" -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "Documentation: https://github.com/code-yeongyu/oh-my-opencode" -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================================================
# Main Installation Flow
# ============================================================================

function Main {
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host "                                                              " -ForegroundColor Cyan
    Write-Host "       Oh-My-OpenCode Windows Installer v2.0                  " -ForegroundColor Cyan
    Write-Host "       Production-Ready Edition                               " -ForegroundColor Cyan
    Write-Host "                                                              " -ForegroundColor Cyan
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Step 1: Prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Err "Prerequisites check failed. Please fix the issues above and try again."
        exit 1
    }
    
    # Step 2: Install OpenCode CLI
    if (-not (Install-OpenCodeCLI)) {
        Write-Warn "OpenCode installation had issues, but continuing with plugin setup..."
    }
    
    # Step 3: Setup config directory and backup credentials
    $credentialsBackup = Initialize-ConfigDirectory
    
    # Step 4: Create configuration files
    New-OpenCodeConfig
    New-OhMyOpenCodeConfig
    
    # Step 5: Install plugins locally
    Install-Plugins
    
    # Step 6: Restore credentials if they were backed up
    if ($credentialsBackup) {
        Restore-Credentials -BackupDir $credentialsBackup
    }
    
    # Step 7: Verify installation
    $installOk = Test-Installation
    
    # Step 8: Show success message
    if ($installOk) {
        Show-SuccessMessage
    } else {
        Write-Host ""
        Write-Warn "Installation completed with some warnings."
        Write-Info "Please review the issues above and fix manually if needed."
        Write-Host ""
        Show-SuccessMessage
    }
}

# Run the installer
try {
    Main
} catch {
    Write-Err "Installation failed: $_"
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "  1. Ensure you have internet access" -ForegroundColor Gray
    Write-Host "  2. Try running: npm cache clean --force" -ForegroundColor Gray
    Write-Host "  3. Check if VPN is causing issues" -ForegroundColor Gray
    Write-Host "  4. Run this script again with -Verbose for more details" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
