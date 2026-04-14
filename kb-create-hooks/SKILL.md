---
name: kb-create-hooks
description: Create enforcement hooks that inject .kb/ knowledge into AI agent sessions at startup and guard deployment commands. Supports Claude Code hooks and Codex/OpenCode equivalents.
user-invocable: true
allowed-tools: Read Bash Edit Write Glob Grep
---

# KB Create Hooks — Enforce Knowledge Base Usage

You are setting up hooks that **deterministically inject** the knowledge base into agent sessions. Hooks are more reliable than instructions in CLAUDE.md/AGENTS.md because they execute automatically — the agent cannot skip or forget them.

## What Gets Created

| Hook | Trigger | Purpose |
|------|---------|---------|
| **KB Enforcer** | Session start | Injects KB index + critical gotchas into agent context |
| **Deploy Guard** | Before shell commands | Detects deployment commands and injects deployment reminders |
| **KB Update Reminder** | Session end (optional) | Reminds agent to update KB with discoveries |

---

## Claude Code Hooks

Claude Code supports hooks via `.claude/settings.json`. Hooks run shell commands at lifecycle events and can inject `additionalContext` into the agent's conversation.

### Supported Hook Events

| Event | When It Fires |
|-------|--------------|
| `SessionStart` | Once at the beginning of every conversation |
| `PreToolUse` | Before each tool invocation (filtered by tool name) |
| `PostToolUse` | After each tool invocation |
| `Notification` | When the agent sends a notification |
| `Stop` | When the agent completes its response |

### File Structure

```
.claude/
├── settings.json          # Hook configuration
└── hooks/
    ├── enforce-kb.sh      # SessionStart: inject KB index
    └── guard-deploy.sh    # PreToolUse(Bash): deployment safety
```

### Step 1: Create the Hooks Directory

```bash
mkdir -p .claude/hooks
```

### Step 2: Create the KB Enforcer Hook

This hook runs at session start. It reads the KB index and injects it as mandatory context.

Create `.claude/hooks/enforce-kb.sh`:

```bash
#!/usr/bin/env bash
# Hook: SessionStart — inject KB index into agent context.
# Ensures every agent session starts with awareness of the knowledge base.

set -euo pipefail

KB_DIR="${CLAUDE_PROJECT_DIR:-.}/.kb"
INDEX="$KB_DIR/INDEX.md"

# If no KB exists yet, exit silently
if [[ ! -f "$INDEX" ]]; then
  exit 0
fi

# Read the KB index
KB_INDEX=$(cat "$INDEX")

# Read the last 30 lines of common-bugs.md as a quick reference
BUGS_QUICK=""
if [[ -f "$KB_DIR/gotchas/common-bugs.md" ]]; then
  BUGS_QUICK=$(tail -30 "$KB_DIR/gotchas/common-bugs.md")
fi

# Escape content for JSON embedding
escape_json() {
  python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$1"
}

KB_JSON=$(escape_json "$KB_INDEX")
BUGS_JSON=$(escape_json "$BUGS_QUICK")

# Remove surrounding quotes from json.dumps output for embedding
KB_ESCAPED="${KB_JSON:1:-1}"
BUGS_ESCAPED="${BUGS_JSON:1:-1}"

cat <<ENDJSON
{
  "additionalContext": "MANDATORY KB CHECK: Before ANY code changes, deployments, or architectural decisions, you MUST read the relevant .kb/ files. Here is the index:\n\n${KB_ESCAPED}\n\nQuick bug reference (read FULL file before working):\n\n${BUGS_ESCAPED}\n\nFAILURE TO READ KB BEFORE ACTING HAS CAUSED PRODUCTION INCIDENTS. This is not optional."
}
ENDJSON
```

```bash
chmod +x .claude/hooks/enforce-kb.sh
```

### Step 3: Create the Deploy Guard Hook

This hook fires before every Bash command. It pattern-matches deployment-related commands and injects safety reminders.

Create `.claude/hooks/guard-deploy.sh`:

```bash
#!/usr/bin/env bash
# Hook: PreToolUse(Bash) — inject deployment reminders when deploy commands are detected.
# This is a reminder, not a blocker — the command still executes.

set -euo pipefail

# Read the tool input from stdin
INPUT=$(cat)

# Extract the command being run
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null || echo "")

# ─── Customize these patterns for your project ───
# Add patterns that match YOUR deployment commands
DEPLOY_PATTERNS=(
  # CI/CD triggers
  'glab api.*pipeline'
  'glab api.*play'
  'glab api.*deploy'
  'gh workflow run'
  'gh api.*dispatches'
  # Direct deployment
  'helm upgrade'
  'helm install'
  'helmfile'
  'kubectl.*apply'
  'kubectl.*set image'
  'terraform apply'
  'pulumi up'
  'cdk deploy'
  'serverless deploy'
  'fly deploy'
  'railway up'
  # Dangerous scripts
  'deploy\.sh'
  'sync\.sh'
  'release\.sh'
)

# Build a combined regex from the patterns
REGEX=$(IFS='|'; echo "${DEPLOY_PATTERNS[*]}")

if echo "$COMMAND" | grep -qiE "$REGEX"; then
  cat <<'ENDJSON'
{
  "additionalContext": "DEPLOY COMMAND DETECTED: Ensure you have read .kb/operations/deployment.md in this session. Key reminders:\n- Follow the deployment runbook step by step\n- Always verify the deployment succeeded (check pod status, image tags, logs)\n- If this is a rollback, document what went wrong in .kb/gotchas/common-bugs.md"
}
ENDJSON
fi

exit 0
```

```bash
chmod +x .claude/hooks/guard-deploy.sh
```

### Step 4: Configure settings.json

Create or update `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/enforce-kb.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/guard-deploy.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**Important:** If `.claude/settings.json` already exists, MERGE the hooks — don't overwrite existing settings. Read the file first, then add or update the hooks section.

### Step 5: Verify Hooks Work

```bash
# Test the enforcer hook manually
CLAUDE_PROJECT_DIR="$(pwd)" bash .claude/hooks/enforce-kb.sh

# Test the deploy guard with a fake deploy command
echo '{"tool_input":{"command":"helm upgrade my-release ./chart"}}' | \
  CLAUDE_PROJECT_DIR="$(pwd)" bash .claude/hooks/guard-deploy.sh

# Test with a non-deploy command (should produce no output)
echo '{"tool_input":{"command":"ls -la"}}' | \
  CLAUDE_PROJECT_DIR="$(pwd)" bash .claude/hooks/guard-deploy.sh
```

---

## Codex Equivalents

OpenAI Codex uses `AGENTS.md` as its primary instruction mechanism and does not have a hook system identical to Claude Code. However, there are equivalent approaches:

### Option 1: AGENTS.md Inline Instructions

Add a strong preamble to `AGENTS.md` that references the KB:

```markdown
# AGENTS.md

## MANDATORY: Knowledge Base

**Before ANY work, read `.kb/INDEX.md` and the relevant KB sections.**

The `.kb/` directory contains:
- Architecture docs: `.kb/architecture/`
- Known bugs: `.kb/gotchas/common-bugs.md`
- Deployment runbook: `.kb/operations/deployment.md`
- Coding rules: `.kb/conventions/coding-rules.md`

Failure to read the KB before working has caused production incidents.
This instruction takes priority over all other instructions.
```

### Option 2: Wrapper Script for Codex CLI

Create a wrapper that pre-loads KB context before launching Codex:

```bash
#!/usr/bin/env bash
# codex-with-kb.sh — Launch Codex CLI with KB context pre-loaded

KB_DIR=".kb"
if [[ -f "$KB_DIR/INDEX.md" ]]; then
  KB_CONTEXT="MANDATORY: Read .kb/INDEX.md before any work. Key files:
$(cat "$KB_DIR/INDEX.md" | head -50)

Known bugs (read full file before working):
$(tail -30 "$KB_DIR/gotchas/common-bugs.md" 2>/dev/null || echo 'No bugs file yet')"

  echo "KB context loaded. Starting Codex..."
  # Prepend KB context to the user's prompt
  codex "$@" --instructions "$(echo "$KB_CONTEXT")"
else
  codex "$@"
fi
```

### Option 3: Pre-Commit Hook for All Tools

Add a git pre-commit hook that validates KB consistency:

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit — Verify KB is consistent before committing

KB_DIR=".kb"

if [[ ! -d "$KB_DIR" ]]; then
  exit 0  # No KB yet
fi

# Check that INDEX.md references all .kb/*.md files
ERRORS=0

for f in $(find "$KB_DIR" -name "*.md" -not -name "INDEX.md" -not -name "README.md" | sort); do
  RELATIVE=$(echo "$f" | sed "s|^$KB_DIR/||")
  if ! grep -q "$RELATIVE" "$KB_DIR/INDEX.md"; then
    echo "WARNING: $RELATIVE is not listed in .kb/INDEX.md"
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo "$ERRORS KB file(s) not indexed. Update .kb/INDEX.md before committing."
  echo "(To skip this check: git commit --no-verify)"
  exit 1
fi
```

---

## Gemini CLI Equivalents

Gemini CLI uses `GEMINI.md` for instructions, similar to Codex. Use the same AGENTS.md approach (Option 1) but in `GEMINI.md`:

```markdown
# GEMINI.md

## Knowledge Base (Required Reading)

Before any code changes, read `.kb/INDEX.md` to find relevant documentation.
Before any deployment, read `.kb/operations/deployment.md`.
Before working on a new area, read `.kb/gotchas/common-bugs.md`.
```

---

## Cursor / Windsurf Equivalents

### Cursor: Always-On Rule

Create `.cursor/rules/kb-enforcer.mdc`:

```markdown
---
description: Enforce reading .kb/ knowledge base before any work
globs:
alwaysApply: true
---

Before making any code changes:
1. Read `.kb/INDEX.md` to identify relevant knowledge base sections
2. Read `.kb/gotchas/common-bugs.md` for known bug patterns
3. Read the specific `.kb/` files relevant to the area you're modifying

Before any deployment-related changes:
1. Read `.kb/operations/deployment.md` for the deployment runbook

After completing work:
1. If you discovered a non-obvious bug or gotcha, add it to `.kb/gotchas/common-bugs.md`
2. If you made an architectural decision, document it in the relevant `.kb/architecture/` file
```

### Windsurf: Rules File

Create `.windsurf/rules/kb-enforcer.md`:

```markdown
---
trigger: always
---

# Knowledge Base Requirement

Read `.kb/INDEX.md` before any work. Read `.kb/gotchas/common-bugs.md` before working in a new area. Read `.kb/operations/deployment.md` before any deployment.

Update `.kb/` when you discover non-obvious bugs, architectural decisions, or operational procedures.
```

---

## Optional: KB Update Reminder (Stop Hook)

This Claude Code hook fires when the agent finishes its response. It reminds the agent to update the KB if significant work was done.

Add to `.claude/hooks/remind-kb-update.sh`:

```bash
#!/usr/bin/env bash
# Hook: Stop — remind agent to update KB after significant work

set -euo pipefail

KB_DIR="${CLAUDE_PROJECT_DIR:-.}/.kb"

if [[ ! -d "$KB_DIR" ]]; then
  exit 0
fi

cat <<'ENDJSON'
{
  "additionalContext": "KB UPDATE CHECK: If you discovered a non-obvious bug, gotcha, architectural insight, or operational procedure during this session, add it to the appropriate .kb/ file now. The KB is only valuable if it stays current."
}
ENDJSON
```

Add to `settings.json`:
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/remind-kb-update.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**Note:** The Stop hook fires on EVERY response, which can be noisy. Enable it only during periods of active discovery (onboarding a new team member, major refactors, incident response). Disable it for routine work by commenting out the hook in settings.json.

---

## Verification Checklist

After setting up hooks:

- [ ] `.claude/hooks/enforce-kb.sh` exists and is executable (`chmod +x`)
- [ ] `.claude/hooks/guard-deploy.sh` exists and is executable
- [ ] `.claude/settings.json` contains the hooks configuration
- [ ] Running `enforce-kb.sh` manually produces valid JSON with `additionalContext`
- [ ] Running `guard-deploy.sh` with a deploy command produces a warning
- [ ] Running `guard-deploy.sh` with a normal command produces no output
- [ ] Starting a new Claude Code session shows KB context in the conversation
- [ ] `AGENTS.md` and/or `CLAUDE.md` reference the KB as mandatory reading
- [ ] For non-Claude-Code tools: equivalent instructions are in AGENTS.md / GEMINI.md / .cursor/rules/
