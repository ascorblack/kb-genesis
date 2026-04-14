# KB Genesis — Project Knowledge Base Standard for AI Agents

A universal skill for bootstrapping a structured knowledge base (`.kb/`) in any software project, optimized for AI coding agents (Claude Code, Codex, Gemini CLI, Cursor, etc.).

## Quick Install

### Claude Code — Global (all your projects)

```bash
git clone https://github.com/ascorblack/kb-genesis.git ~/.claude/skills/kb-genesis
```

After install, use in any project:

```
/kb-genesis
```

### Claude Code — Single Project

```bash
git clone https://github.com/ascorblack/kb-genesis.git .claude/skills/kb-genesis
```

### Codex / Gemini CLI / Any Agent

```bash
git clone https://github.com/ascorblack/kb-genesis.git kb-genesis
```

Then tell the agent:

> Read kb-genesis/SKILL.md and follow it to create a .kb/ for this project

### Cursor / Windsurf

```bash
# Cursor
mkdir -p .cursor/rules
curl -sL https://raw.githubusercontent.com/ascorblack/kb-genesis/main/SKILL.md \
  > .cursor/rules/kb-genesis.mdc

# Windsurf
mkdir -p .windsurf/rules
curl -sL https://raw.githubusercontent.com/ascorblack/kb-genesis/main/SKILL.md \
  > .windsurf/rules/kb-genesis.md
```

### Update

```bash
git -C ~/.claude/skills/kb-genesis pull        # global
git -C .claude/skills/kb-genesis pull           # project-local
```

### Uninstall

```bash
rm -rf ~/.claude/skills/kb-genesis              # global
rm -rf .claude/skills/kb-genesis                # project-local
```

---

## How It Works

After installing, type `/kb-genesis` in Claude Code. The agent will:

1. **Analyze** your project — repos, dependencies, stack, conventions, infrastructure
2. **Mine history** — extract gotchas and decisions from past agent conversations
3. **Create `.kb/`** — structured knowledge base with architecture, runtime, operations, conventions, gotchas, and context docs
4. **Set up hooks** — auto-inject KB into future sessions, guard deployments
5. **Integrate** — update CLAUDE.md / AGENTS.md to reference the KB

## Files

```
kb-genesis/
├── SKILL.md              # Main skill — invoked via /kb-genesis
├── kb-mine-history.md    # Companion: conversation history mining
├── kb-create-hooks.md    # Companion: enforcement hooks setup
└── README.md             # This file
```

| File | Purpose |
|------|---------|
| `SKILL.md` | **Main skill.** Full standard and 8-phase process to analyze a project and create a KB |
| `kb-mine-history.md` | **Companion.** Extract knowledge from Claude Code / Codex / OpenCode conversation histories |
| `kb-create-hooks.md` | **Companion.** Create SessionStart and PreToolUse hooks for Claude Code, Codex, Cursor, Windsurf |

## What This Is

A set of instructions that an AI agent reads and follows to create a comprehensive, agent-readable knowledge base for a project. The KB captures institutional knowledge that can't be derived from code alone: architectural decisions, operational gotchas, bug patterns, conventions, and business context.

## Design Principles

- **Language/framework agnostic** — Python, TypeScript, Go, Rust, Java, or any stack
- **Agent-first formatting** — tables, code blocks, symptom-cause-fix patterns over prose
- **Hot/cold memory split** — always-loaded index + on-demand deep documents
- **Self-maintaining** — agents update the KB as they work, knowledge compounds over sessions
- **Hook-enforced** — deterministic injection at session start, not probabilistic rule-following

## License

Public domain. Use however you want.
