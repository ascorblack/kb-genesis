# KB Genesis — Project Knowledge Base Standard for AI Agents

A universal skill package for bootstrapping a structured knowledge base (`.kb/`) in any software project, optimized for AI coding agents (Claude Code, Codex, Gemini CLI, Cursor, etc.).

## Quick Install

### Claude Code (one command)

```bash
# From your project root:
git clone https://github.com/ascorblack/kb-genesis.git .claude/skills/kb-genesis
```

Then tell Claude Code:

> Create a knowledge base for this project using the kb-genesis skill

### Codex / Gemini CLI / Any Agent

```bash
# Clone into your project:
git clone https://github.com/ascorblack/kb-genesis.git kb-genesis

# Then tell the agent:
# "Read kb-genesis/kb-genesis.md and follow it to create a .kb/ for this project"
```

### Cursor / Windsurf

```bash
# Clone and copy the main skill as a rule:
git clone https://github.com/ascorblack/kb-genesis.git /tmp/kb-genesis
cp /tmp/kb-genesis/kb-genesis.md .cursor/rules/kb-genesis.mdc   # Cursor
cp /tmp/kb-genesis/kb-genesis.md .windsurf/rules/kb-genesis.md  # Windsurf
```

### Update to Latest Version

```bash
# If installed as Claude Code skills:
git -C .claude/skills/kb-genesis pull

# If installed in project root:
git -C kb-genesis pull
```

### Uninstall

```bash
rm -rf .claude/skills/kb-genesis  # or rm -rf kb-genesis
```

---

## What This Is

A set of skills (instructions) that an AI agent reads and follows to create a comprehensive, agent-readable knowledge base for a project. The KB captures institutional knowledge that can't be derived from code alone: architectural decisions, operational gotchas, bug patterns, conventions, and business context.

## Files

| File | Purpose |
|------|---------|
| `kb-genesis.md` | **Main skill.** Full standard and step-by-step process to analyze a project and create a KB from scratch |
| `kb-mine-history.md` | **History mining skill.** Extract knowledge from existing AI agent conversation histories (Claude Code, Codex, OpenCode) |
| `kb-create-hooks.md` | **Hooks skill.** Create enforcement hooks that inject KB context into agent sessions and guard deployments |

## Usage

### For Claude Code

Copy to your project and invoke:
```bash
# Option 1: Copy as skills
cp kb-genesis/*.md /path/to/project/.claude/skills/

# Option 2: Just send the file content to an agent
# "Read kb-genesis/kb-genesis.md and follow it for this project"
```

### For Codex / Other Agents

Paste the content of `kb-genesis.md` as the task prompt, or reference it in AGENTS.md:
```markdown
## Knowledge Base
Follow the instructions in `kb-genesis/kb-genesis.md` to create and maintain the project KB.
```

### For Humans

Send `kb-genesis.md` to anyone working with AI agents. They paste it into their agent's context, and the agent creates the KB for their project.

## Design Principles

- **Language/framework agnostic** — works for Python, TypeScript, Go, Rust, Java, or any stack
- **Agent-first formatting** — tables, code blocks, symptom-cause-fix patterns over prose
- **Hot/cold memory split** — always-loaded index + on-demand deep documents
- **Self-maintaining** — agents update the KB as they work, knowledge compounds over sessions
- **Hook-enforced** — deterministic injection at session start, not probabilistic rule-following
