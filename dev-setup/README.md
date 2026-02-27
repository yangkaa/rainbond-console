# Rainbond AI Development Environment Setup

Standardized AI development workflow for the Rainbond team using Claude Code + Superpowers.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed (`npm install -g @anthropic-ai/claude-code`)
- Git
- jq (`brew install jq` on macOS)
- Three Rainbond repos cloned into the same parent directory:
  ```
  <code-dir>/
    rainbond/
    rainbond-console/
    rainbond-ui/
  ```

## Installation

```bash
cd rainbond-console
bash dev-setup/setup.sh
```

The script will:
- Auto-detect your repository locations
- Install global Claude Code configuration (`~/.claude/`)
- Install 6 workflow commands
- Install Superpowers plugin (14 process discipline skills)
- Run verification checks

## Usage

Start a new Claude Code session after installation:

```bash
claude
```

Then describe your task in natural language. The AI will automatically guide you through the correct workflow.

### Standard Development Flow

```
Describe your requirement
    ↓ AI auto-triggers brainstorming (cannot skip)
Design discussion & approval
    ↓ /spec-gen
Task specification generated
    ↓ /spec-driven commit-1
TDD execution (Red → Green → Refactor)
    ↓ automatic
Build verification + Code review
    ↓ /check-api-compat (if cross-repo)
API compatibility check
    ↓
Done — commit created automatically
```

### Available Commands

| Command | Purpose |
|---------|---------|
| `/design` | Interactive feature design discussion |
| `/spec-gen` | Generate task specs from design docs |
| `/spec-driven <spec> <commit-id>` | Execute tasks from specs with TDD |
| `/tdd <task>` | Generic TDD workflow |
| `/cross-repo-feature` | Cross-repo development guide (Go → Python → React) |
| `/check-api-compat` | API compatibility check across repos |
| `/brainstorm` | Superpowers: structured brainstorming |
| `/write-plan` | Superpowers: create execution plan |
| `/execute-plan` | Superpowers: execute plan |
| `/verify` | Repo-specific build & lint check |

### Per-Repo Commands

These are available only within the respective repository:

- **rainbond**: `/add-api`, `/verify`
- **rainbond-console**: `/add-api`, `/add-openapi`, `/verify`
- **rainbond-ui**: `/add-page`, `/add-api-call`

## What Gets Installed

| File | Purpose |
|------|---------|
| `~/.claude/CLAUDE.md` | Global dev standards + Rainbond architecture map |
| `~/.claude/commands/*.md` | 6 global workflow commands |
| `~/.claude/statusline-command.sh` | Git branch + context usage status line |
| Superpowers plugin v4.3.1 | 14 process discipline skills (TDD, debugging, verification, code review) |

Project-level configs (`CLAUDE.md`, `.claude/commands/`, `.claude/settings.json`) are already in each repository and shared via git automatically.

## Updating

Re-run the setup script to update. It will:
- Back up your existing `~/.claude/CLAUDE.md`
- Pull latest Superpowers plugin
- Preserve your other settings
