# Oh-My-OpenCode Universal Installer

Universal cross-platform installation scripts for [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) with automatic Node.js/Bun detection and setup wizard.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-blue)](https://github.com/enkinvsh/opencode-)

## Quick Start

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/enkinvsh/opencode-/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/enkinvsh/opencode-/main/install.ps1 | iex
```

### Manual Installation (if Node.js already installed)

```bash
bunx oh-my-opencode install
# or
npx oh-my-opencode install
```

---

## What This Does

The installer scripts automatically:

1. ✅ **Detect your platform** (Linux/macOS/Windows)
2. ✅ **Check for Node.js 18+ or Bun**
3. ✅ **Show installation instructions** if runtime not found
4. ✅ **Run the oh-my-opencode setup wizard**
5. ✅ **Verify auth plugin configuration**
6. ✅ **Display next steps** for getting started

---

## Requirements

| Component | Minimum Version | Check Command |
|-----------|----------------|---------------|
| Node.js | 18+ | `node --version` |
| **or** Bun | any | `bun --version` |
| OpenCode | latest | `opencode --version` |

### Installing Node.js

**macOS (Homebrew):**
```bash
brew install node
```

**Linux (nvm - recommended):**
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc  # or ~/.zshrc
nvm install --lts
```

**Windows (winget):**
```powershell
winget install OpenJS.NodeJS.LTS
```

### Installing Bun (alternative)

**Unix (Linux/macOS):**
```bash
curl -fsSL https://bun.sh/install | bash
```

**Windows (PowerShell):**
```powershell
powershell -c "irm bun.sh/install.ps1 | iex"
```

---

## Features

### `install.sh` (Linux/macOS)

- 🔒 **Security**: Script wrapped in `{ }` to prevent partial execution (follows NVM best practices)
- 🎯 **Smart detection**: Automatically finds npm, bun, pnpm, or yarn
- 🚨 **Error handling**: Uses `set -euo pipefail` for proper error propagation
- 🎨 **Colored output**: Clear info/warn/error messages
- 🔄 **Fallback support**: Works with curl or wget

### `install.ps1` (Windows)

- ✅ **Windows version check**: Ensures Windows 10 1809+ (build 17763)
- 🎯 **Package manager detection**: Supports npm, bun, pnpm, yarn
- 📦 **PowerShell 5.1+ compatible**: Works with both Windows PowerShell and PowerShell 7+
- 🎨 **Colored output**: Uses PowerShell native colors
- ⚙️ **Parameter support**: `--SkipAuthCheck`, `--NoColor`

---

## Configuration Files

After installation, oh-my-opencode creates three config files:

| File | Purpose |
|------|---------|
| `~/.config/opencode/opencode.json` | Plugins and model providers |
| `~/.config/opencode/oh-my-opencode.json` | Agents and task categories |
| `~/.config/opencode/config.json` | Tools and MCP integrations |

See [setup-opencode.md](./setup-opencode.md) for detailed configuration examples.

---

## Authentication

After installation, authenticate with Antigravity:

```bash
opencode auth login
```

Select **Google** when prompted. This will open your browser for OAuth authentication.

---

## Verification

Check your installation:

```bash
# Check plugins
opencode plugin list

# Check auth status
opencode auth status

# Start OpenCode
opencode

# Check quota (inside opencode)
/antigravity-quota
```

---

## Documentation

- **[setup-opencode.md](./setup-opencode.md)** - Detailed setup guide with configuration examples
- **[ideal-workflow-design-refactoring.md](./ideal-workflow-design-refactoring.md)** - Workflow guide for design refactoring (Russian)
- **[instructions.md](./instructions.md)** - Windows environment preferences

---

## Usage Examples

### Planning Workflow (Prometheus → Atlas)

For complex multi-step tasks:

```bash
# 1. Start planning session
@plan Refactor authentication to use NextAuth

# 2. Answer Prometheus questions (interactive interview)

# 3. Finalize plan
"Make it a plan"

# 4. Execute plan
/start-work
```

### Ultrawork Mode

For complex tasks where you don't want to explain context:

```bash
ulw Refactor the Button component to use CSS modules with dark mode support
```

### Quick Tasks

For simple one-off tasks:

```bash
# Just ask naturally
"Fix the TypeScript error in auth.ts"
```

---

## Troubleshooting

### "Agent not configured"

**Solution**: Ensure model is defined in both:
- `opencode.json` (provider models)
- `oh-my-opencode.json` (agent assignments)

Format: `google/antigravity-claude-opus-4-5-thinking` (not `anthropic/...`)

### "Authentication failed"

**Solution**:
```bash
opencode auth logout
opencode auth login
```

### Plugin not detected

**Solution**:
1. Add plugin to `plugin` array in `opencode.json`
2. Restart opencode completely
3. Verify with `opencode plugin list`

---

## Update

```bash
# Check version
oh-my-opencode get-local-version

# Update
npm update -g oh-my-opencode
# or
bun update -g oh-my-opencode

# Run diagnostics
oh-my-opencode doctor
```

---

## Development

### Local Testing

```bash
# Clone repository
git clone https://github.com/enkinvsh/opencode-.git
cd opencode-

# Test installer locally
./install.sh  # Unix
.\install.ps1 # Windows
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Security

These installers follow security best practices:

- ✅ Scripts wrapped to prevent partial execution
- ✅ HTTPS-only downloads
- ✅ No arbitrary code execution without user confirmation
- ✅ Clear error messages with remediation steps
- ✅ Respects existing installations

Based on research from:
- [NVM install script](https://github.com/nvm-sh/nvm/blob/master/install.sh)
- [Bun installers](https://github.com/oven-sh/bun/tree/main/src/cli)
- [Rustup init script](https://github.com/rust-lang/rustup/blob/master/rustup-init.sh)

---

## Credits

- **oh-my-opencode**: [code-yeongyu/oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)
- **OpenCode**: Base AI coding assistant framework
- **Antigravity**: Multi-account quota management system

---

## License

MIT License - see [LICENSE](LICENSE) for details

---

## Links

- **GitHub**: https://github.com/enkinvsh/opencode-
- **Issues**: https://github.com/enkinvsh/opencode-/issues
- **oh-my-opencode repo**: https://github.com/code-yeongyu/oh-my-opencode
