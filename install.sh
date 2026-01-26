#!/usr/bin/env bash
{ # Wrap entire script to ensure full download before execution

set -euo pipefail

# =============================================================================
# Oh-My-OpenCode Universal Installer (Linux/macOS)
# Usage: curl -fsSL https://raw.githubusercontent.com/user/repo/main/install.sh | bash
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PACKAGE_NAME="oh-my-opencode"
CONFIG_DIR="${HOME}/.config/opencode"
MIN_NODE_VERSION=18

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

die() {
    error "$1"
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# -----------------------------------------------------------------------------
# Platform Detection
# -----------------------------------------------------------------------------

detect_platform() {
    local platform
    platform=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    case "$platform" in
        darwin)
            echo "macos"
            ;;
        linux)
            echo "linux"
            ;;
        mingw*|msys*|cygwin*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

detect_arch() {
    local arch
    arch=$(uname -m)
    
    case "$arch" in
        x86_64|amd64)
            echo "x64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Version Comparison
# -----------------------------------------------------------------------------

version_gte() {
    # Returns 0 if $1 >= $2
    local v1="$1"
    local v2="$2"
    
    # Extract major version
    local major1=$(echo "$v1" | cut -d. -f1 | sed 's/v//')
    local major2=$(echo "$v2" | cut -d. -f1 | sed 's/v//')
    
    if [ "$major1" -ge "$major2" ]; then
        return 0
    else
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Package Manager Detection
# -----------------------------------------------------------------------------

detect_package_manager() {
    if command_exists bun; then
        echo "bun"
    elif command_exists npm; then
        echo "npm"
    elif command_exists pnpm; then
        echo "pnpm"
    elif command_exists yarn; then
        echo "yarn"
    else
        echo "none"
    fi
}

get_node_version() {
    if command_exists node; then
        node --version | sed 's/v//' | cut -d. -f1
    else
        echo "0"
    fi
}

# -----------------------------------------------------------------------------
# Installation Functions
# -----------------------------------------------------------------------------

check_prerequisites() {
    info "Checking prerequisites..."
    
    local platform=$(detect_platform)
    local arch=$(detect_arch)
    
    info "Platform: $platform ($arch)"
    
    # Check for Windows (should use PowerShell installer)
    if [ "$platform" = "windows" ]; then
        warn "Windows detected. Use PowerShell installer instead:"
        echo ""
        echo "    irm https://raw.githubusercontent.com/user/repo/main/install.ps1 | iex"
        echo ""
        exit 0
    fi
    
    # Check for curl or wget (for potential future downloads)
    if ! command_exists curl && ! command_exists wget; then
        die "curl or wget is required. Please install one of them."
    fi
    
    success "Prerequisites check passed"
}

check_node_runtime() {
    info "Checking Node.js runtime..."
    
    local pkg_manager=$(detect_package_manager)
    
    if [ "$pkg_manager" = "bun" ]; then
        local bun_version=$(bun --version 2>/dev/null || echo "0")
        success "Found Bun v${bun_version}"
        echo "bun"
        return 0
    fi
    
    if command_exists node; then
        local node_version=$(get_node_version)
        
        if [ "$node_version" -ge "$MIN_NODE_VERSION" ]; then
            success "Found Node.js v${node_version}"
            
            if [ "$pkg_manager" != "none" ]; then
                echo "$pkg_manager"
                return 0
            fi
        else
            warn "Node.js v${node_version} found, but v${MIN_NODE_VERSION}+ is required"
        fi
    fi
    
    echo "none"
    return 1
}

install_nodejs_hint() {
    local platform=$(detect_platform)
    
    echo ""
    error "Node.js v${MIN_NODE_VERSION}+ or Bun is required but not found."
    echo ""
    echo "Install options:"
    echo ""
    
    if [ "$platform" = "macos" ]; then
        echo "  ${CYAN}# Using Homebrew (recommended for macOS):${NC}"
        echo "  brew install node"
        echo ""
        echo "  ${CYAN}# Or install Bun:${NC}"
        echo "  curl -fsSL https://bun.sh/install | bash"
    else
        echo "  ${CYAN}# Using nvm (recommended):${NC}"
        echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
        echo "  source ~/.bashrc  # or ~/.zshrc"
        echo "  nvm install --lts"
        echo ""
        echo "  ${CYAN}# Or install Bun:${NC}"
        echo "  curl -fsSL https://bun.sh/install | bash"
        echo ""
        echo "  ${CYAN}# Or using your package manager:${NC}"
        echo "  # Debian/Ubuntu: sudo apt install nodejs npm"
        echo "  # Fedora: sudo dnf install nodejs npm"
        echo "  # Arch: sudo pacman -S nodejs npm"
    fi
    
    echo ""
    echo "After installing Node.js or Bun, re-run this installer."
    echo ""
}

install_package() {
    local pkg_manager="$1"
    
    info "Installing ${PACKAGE_NAME} using ${pkg_manager}..."
    
    case "$pkg_manager" in
        bun)
            bun install -g "$PACKAGE_NAME" || bunx "$PACKAGE_NAME" install
            ;;
        npm)
            npm install -g "$PACKAGE_NAME" || npx "$PACKAGE_NAME" install
            ;;
        pnpm)
            pnpm add -g "$PACKAGE_NAME"
            ;;
        yarn)
            yarn global add "$PACKAGE_NAME"
            ;;
        *)
            die "Unknown package manager: $pkg_manager"
            ;;
    esac
}

run_setup_wizard() {
    local pkg_manager="$1"
    
    info "Running oh-my-opencode setup wizard..."
    echo ""
    
    case "$pkg_manager" in
        bun)
            bunx "$PACKAGE_NAME" install
            ;;
        npm)
            npx "$PACKAGE_NAME" install
            ;;
        pnpm)
            pnpm dlx "$PACKAGE_NAME" install
            ;;
        yarn)
            yarn dlx "$PACKAGE_NAME" install
            ;;
        *)
            # Fallback: try running directly if globally installed
            if command_exists oh-my-opencode; then
                oh-my-opencode install
            else
                die "Could not run setup wizard"
            fi
            ;;
    esac
}

setup_auth_plugins() {
    info "Checking auth plugins configuration..."
    
    local opencode_config="${CONFIG_DIR}/opencode.json"
    
    if [ -f "$opencode_config" ]; then
        if grep -q "opencode-antigravity-auth" "$opencode_config" 2>/dev/null; then
            success "Antigravity auth plugin already configured"
        else
            warn "Antigravity auth plugin not found in config"
            info "You may need to add it manually or run 'opencode auth login'"
        fi
    else
        warn "OpenCode config not found at $opencode_config"
        info "The setup wizard will create it for you"
    fi
}

print_success_message() {
    echo ""
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}   Oh-My-OpenCode installed successfully!   ${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Authenticate with Antigravity:"
    echo "     ${CYAN}opencode auth login${NC}"
    echo ""
    echo "  2. Start OpenCode:"
    echo "     ${CYAN}opencode${NC}"
    echo ""
    echo "  3. Check quota status:"
    echo "     ${CYAN}/antigravity-quota${NC}"
    echo ""
    echo "Documentation:"
    echo "  - Setup guide: ${CYAN}~/.config/opencode/setup-opencode.md${NC}"
    echo "  - GitHub: ${CYAN}https://github.com/code-yeongyu/oh-my-opencode${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Main Installation Flow
# -----------------------------------------------------------------------------

main() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Oh-My-OpenCode Universal Installer   ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # Step 1: Check prerequisites
    check_prerequisites
    
    # Step 2: Check Node.js/Bun
    local pkg_manager
    pkg_manager=$(check_node_runtime) || true
    
    if [ "$pkg_manager" = "none" ] || [ -z "$pkg_manager" ]; then
        install_nodejs_hint
        exit 1
    fi
    
    # Step 3: Run the interactive installer
    echo ""
    run_setup_wizard "$pkg_manager"
    
    # Step 4: Verify auth plugins
    setup_auth_plugins
    
    # Step 5: Success message
    print_success_message
}

# Run main function with all arguments
main "$@"

} # End of script wrapper - ensures full download before execution
