# KB Genesis — Project Knowledge Base Standard for AI Agents

A universal skill package for bootstrapping a structured knowledge base (`.kb/`) in any software project, optimized for AI coding agents (Claude Code, Codex, Gemini CLI, Cursor, etc.).

## Quick Install

### Claude Code (recommended)

```bash
# 1. Clone the repo
git clone https://github.com/ascorblack/kb-genesis.git ~/.local/share/kb-genesis

# 2. Install skills (creates symlinks — global, works in all projects)
~/.local/share/kb-genesis/install.sh
```

Three skills become available:

```
/kb-genesis       — Create a knowledge base for a project
/kb-mine-history  — Mine agent conversation histories for knowledge
/kb-create-hooks  — Set up enforcement hooks
```

#### Project-Local Install (single project only)

```bash
git clone https://github.com/ascorblack/kb-genesis.git ~/.local/share/kb-genesis
~/.local/share/kb-genesis/install.sh --project
```

### Codex / Gemini CLI / Any Agent

```bash
git clone https://github.com/ascorblack/kb-genesis.git kb-genesis
```

Then tell the agent:

> Read kb-genesis/kb-genesis/SKILL.md and follow it to create a .kb/ for this project

### Cursor / Windsurf

```bash
mkdir -p .cursor/rules   # or .windsurf/rules
curl -sL https://raw.githubusercontent.com/ascorblack/kb-genesis/main/kb-genesis/SKILL.md \
  > .cursor/rules/kb-genesis.mdc
```

### Update

```bash
git -C ~/.local/share/kb-genesis pull
```

Symlinks mean updates apply instantly — no reinstall needed.

### Uninstall

```bash
~/.local/share/kb-genesis/uninstall.sh
rm -rf ~/.local/share/kb-genesis
```

---

## How It Works

```
/kb-genesis          Analyze project → create .kb/ → verify → offer next steps
       ↓                                                    ↓
/kb-mine-history     Extract gotchas, decisions, bug patterns from past agent sessions
/kb-create-hooks     Set up SessionStart hook (KB injection) + PreToolUse hook (deploy guard)
```

1. **`/kb-genesis`** — Analyzes your project (repos, stack, conventions, infrastructure), creates a structured `.kb/` knowledge base, verifies it, and offers to run the companion skills
2. **`/kb-mine-history`** — Finds Claude Code / Codex / OpenCode conversation histories, filters by project, extracts bug patterns, architectural decisions, failed approaches, and operational knowledge into `.kb/` files
3. **`/kb-create-hooks`** — Creates enforcement hooks that auto-inject the KB into every agent session and guard deployment commands with safety reminders

## Structure

```
kb-genesis/
├── kb-genesis/           # /kb-genesis — main skill
│   └── SKILL.md
├── kb-mine-history/      # /kb-mine-history — conversation mining
│   └── SKILL.md
├── kb-create-hooks/      # /kb-create-hooks — enforcement hooks
│   └── SKILL.md
├── install.sh            # Symlink skills into ~/.claude/skills/
├── uninstall.sh          # Remove symlinks
└── README.md
```

## What This Is

A set of skills (instructions) that an AI agent reads and follows to create a comprehensive, agent-readable knowledge base for a project. The KB captures institutional knowledge that can't be derived from code alone: architectural decisions, operational gotchas, bug patterns, conventions, and business context.

## Design Principles

- **Language/framework agnostic** — Python, TypeScript, Go, Rust, Java, or any stack
- **Agent-first formatting** — tables, code blocks, symptom-cause-fix patterns over prose
- **Hot/cold memory split** — always-loaded index + on-demand deep documents
- **Self-maintaining** — agents update the KB as they work, knowledge compounds over sessions
- **Hook-enforced** — deterministic injection at session start, not probabilistic rule-following

## License

Public domain. Use however you want.
