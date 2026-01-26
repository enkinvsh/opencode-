# Environment preferences (Windows + PowerShell)

- OS: Windows
- Primary shell/terminal: PowerShell (prefer PowerShell 7+ / `pwsh`; fallback Windows PowerShell 5.1)

## How to respond

- When giving commands for the user to run, prefer PowerShell syntax (avoid bash/zsh-specific constructs like `export`, `./script.sh`, `$(...)`, etc.).
- Use Windows-style paths (eg `C:\path\to\file`) and quote paths with spaces.
- If a command differs significantly between shells, provide the PowerShell version first and optionally a bash alternative.

## PowerShell conventions

- Env vars: `$env:NAME = "value"`
- Chain commands: use `;` (avoid relying on `&&`/`||` unless you explicitly target PowerShell 7+)
- Exit code: check `$LASTEXITCODE` when needed
- Common equivalents:
  - `ls` → `Get-ChildItem`
  - `cat` → `Get-Content`
  - `rm -rf` → `Remove-Item -Recurse -Force`
  - `cp` → `Copy-Item`
  - `mv` → `Move-Item`
