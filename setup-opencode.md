# Oh-My-OpenCode: Руководство по установке

> **Версия**: 3.0.0+ | **Обновлено**: Январь 2026

## Быстрая установка (One-liner)

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/main/install.ps1 | iex
```

### Через npm/bun (если Node.js уже установлен)

```bash
bunx oh-my-opencode install
# или
npx oh-my-opencode install
```

---

## Подробная установка

### Шаг 1: Требования

| Компонент | Минимальная версия | Проверка |
|-----------|-------------------|----------|
| Node.js | 18+ | `node --version` |
| **или** Bun | любая | `bun --version` |

**Установка Node.js:**

```bash
# macOS (Homebrew)
brew install node

# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Windows (winget)
winget install OpenJS.NodeJS.LTS

# Или через nvm (рекомендуется)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
nvm install --lts
```

### Шаг 2: Установка OpenCode CLI

```bash
curl -fsSL https://opencode.ai/install | bash
```

Альтернативные способы:
```bash
npm install -g @opencode-ai/cli
# или
bun install -g @opencode-ai/cli
```

Проверка:
```bash
opencode --version
```

### Шаг 3: Запуск интерактивного установщика oh-my-opencode

```bash
bunx oh-my-opencode install
```

Установщик спросит:
- Какие подписки у вас есть (Claude/ChatGPT/Gemini)
- Настроит конфигурационные файлы
- Предложит авторизоваться

### Шаг 4: Авторизация через Antigravity

```bash
opencode auth login
```

Выберите **Google** — откроется браузер для OAuth. После авторизации вернитесь в терминал.

---

## Конфигурация

### Файлы конфигурации

| Файл | Назначение |
|------|------------|
| `~/.config/opencode/opencode.json` | Плагины и провайдеры моделей |
| `~/.config/opencode/oh-my-opencode.json` | Агенты и категории |
| `~/.config/opencode/config.json` | Инструменты и MCP |

### Минимальная конфигурация opencode.json

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "oh-my-opencode",
    "opencode-antigravity-auth@beta",
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
```

### Конфигурация агентов oh-my-opencode.json (v3.0.0+)

```json
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
```

---

## Проверка установки

```bash
# Проверить плагины
opencode plugin list

# Проверить авторизацию
opencode auth status

# Запустить OpenCode
opencode

# Проверить квоту (внутри opencode)
/antigravity-quota
```

---

## Частые ошибки

### "Agent not configured"

**Причина**: Модель не прописана в конфигах.

**Решение**:
1. Проверьте что модель есть в `opencode.json` (секция `provider.google.models`)
2. Проверьте что агент использует правильный формат: `google/antigravity-claude-opus-4-5-thinking`
3. Перезапустите opencode

### "Authentication failed"

**Решение**:
```bash
opencode auth logout
opencode auth login
```

Выберите **Google** для Antigravity OAuth.

### "Model not found"

**Причина**: Неправильный провайдер.

**Решение**: Antigravity модели идут через провайдер `google`, не `anthropic`:
```
✅ google/antigravity-claude-opus-4-5-thinking
❌ anthropic/claude-opus-4-5-thinking
```

### Плагин не подхватывается

**Решение**:
1. Убедитесь что плагин в массиве `plugin` в `opencode.json`
2. Перезапустите opencode полностью (Ctrl+C и снова `opencode`)
3. Проверьте `opencode plugin list`

---

## Обновление

```bash
# Проверить версию
oh-my-opencode get-local-version

# Обновить
npm update -g oh-my-opencode
# или
bun update -g oh-my-opencode

# Диагностика
oh-my-opencode doctor
```

---

## Полезные команды

| Команда | Описание |
|---------|----------|
| `opencode` | Запуск OpenCode |
| `opencode auth login` | Авторизация |
| `opencode auth status` | Проверка авторизации |
| `opencode plugin list` | Список плагинов |
| `/antigravity-quota` | Проверка квоты (внутри opencode) |
| `oh-my-opencode doctor` | Диагностика установки |
| `@plan <описание>` | Запуск Prometheus (планировщик) |
| `/start-work` | Запуск Atlas (исполнитель) |
| `ulw <задача>` | Ultrawork режим |

---

## Ссылки

- **GitHub**: https://github.com/code-yeongyu/oh-my-opencode
- **Issues**: https://github.com/code-yeongyu/oh-my-opencode/issues
- **Changelog**: https://github.com/code-yeongyu/oh-my-opencode/releases
