---
name: kb-mine-history
description: Extract institutional knowledge from AI agent conversation histories (Claude Code, Codex, OpenCode). Filters by project, identifies bug patterns, architectural decisions, gotchas, and failed approaches. Outputs structured entries for .kb/ files.
---

# KB Mine History — Extract Knowledge from Agent Conversations

You are mining existing AI agent conversation histories to extract institutional knowledge for the project's `.kb/` knowledge base. Conversations contain the richest source of gotchas, bug patterns, and architectural decisions — they capture the exact moment something was discovered.

---

## Step 1: Locate Conversation Histories

### Claude Code

```
History locations:
  ~/.claude/history.jsonl              — all user inputs, indexed by project
  ~/.claude/projects/<encoded-path>/   — full conversation sessions per project
  ~/.claude/sessions/                  — session metadata (PID, UUID, cwd)

Project path encoding: 
  /home/user/myproject → -home-user-myproject (slashes → hyphens, leading / removed)

File format: JSONL (one JSON object per line)

Session files: <session-id>.jsonl inside the project directory
  Each line contains: role, content, model, thinking, tool calls, timestamps
```

### Codex (OpenAI)

```
History locations:
  ~/.codex/history.jsonl               — user inputs with session IDs and timestamps
  ~/.codex/logs_*.sqlite               — detailed session logs in SQLite

File format: JSONL for history, SQLite for logs

Entry structure: {"session_id": "...", "ts": <unix_timestamp>, "text": "..."}
```

### OpenCode

```
History locations:
  ~/.opencode/sessions/                — session files (check for JSON/JSONL)
  ~/.opencode/history/                 — alternative location

Note: OpenCode storage may vary by version. Look for JSON/JSONL files 
      in ~/.opencode/ and its subdirectories.
```

### Cursor / Windsurf

```
Cursor:   ~/.cursor/  — IDE state, conversation history embedded in workspace state
Windsurf: ~/.windsurf/ — similar structure

Note: These IDEs store conversations differently (often in SQLite or proprietary format).
      May require specialized extraction tools.
```

---

## Step 2: Filter by Project

**CRITICAL: Only mine conversations from the target project.** Cross-project knowledge pollution degrades KB quality.

### Claude Code Filtering

```bash
# Find the project directory
PROJECT_PATH="/path/to/your/project"
ENCODED=$(echo "$PROJECT_PATH" | sed 's|^/||; s|/|-|g')
SESSIONS_DIR="$HOME/.claude/projects/-${ENCODED}"

# List all sessions for this project
ls "$SESSIONS_DIR"/*.jsonl 2>/dev/null | head -20

# Verify via history.jsonl — find entries for this project
python3 -c "
import json
with open('$HOME/.claude/history.jsonl') as f:
    for line in f:
        entry = json.loads(line)
        if entry.get('project','').startswith('$PROJECT_PATH'):
            print(f'{entry.get(\"sessionId\",\"?\")[:8]}  {entry.get(\"timestamp\",\"?\")[:19]}  {entry.get(\"display\",\"?\")[:80]}')
"
```

### Codex Filtering

```bash
# Codex history doesn't have project fields directly — 
# correlate session IDs with working directories from logs
python3 -c "
import json
with open('$HOME/.codex/history.jsonl') as f:
    for line in f:
        entry = json.loads(line)
        text = entry.get('text', '')
        # Look for project-specific keywords (file paths, module names, etc.)
        if any(kw in text.lower() for kw in ['keyword1', 'keyword2']):
            print(f'{entry[\"session_id\"][:8]}  {entry.get(\"text\",\"\")[:100]}')
"

# For SQLite logs — check if they contain working directory info
sqlite3 ~/.codex/logs_1.sqlite ".tables"
sqlite3 ~/.codex/logs_1.sqlite ".schema" | head -40
```

---

## Step 3: Extract Knowledge

Read through the filtered conversations and extract the following categories. For each extraction, note the source session and approximate date.

### 3.1 Bug Patterns and Gotchas

**What to look for:**
- Conversations where an agent (or user) debugged something for a long time
- Moments where the root cause was surprising or non-obvious
- Errors that appeared in production but not in tests
- Fixes that required understanding something not documented

**Extract format:**
```markdown
#### <Bug Title>

**Symptom:** <what was observed>
**Root cause:** <why it happened>
**Fix:** <what was done>
**Prevention:** <how to avoid it>
**Source:** Session <id>, <date>
```

### 3.2 Architectural Decisions

**What to look for:**
- Discussions about "should we use X or Y?"
- Explanations of why something was built a certain way
- Trade-off analysis (performance vs. simplicity, etc.)
- Decisions to NOT do something (and why)

**Extract format:**
```markdown
#### Decision: <What Was Decided>

**Context:** <why the decision was needed>
**Choice:** <what was chosen>
**Alternatives considered:** <what was rejected and why>
**Consequences:** <what this means for future work>
**Source:** Session <id>, <date>
```

### 3.3 Failed Approaches

**What to look for:**
- Approaches that were tried and abandoned
- Solutions that worked locally but failed in production
- Migrations or refactors that were rolled back
- Performance optimizations that made things worse

**Extract format:**
```markdown
#### Failed: <What Was Tried>

**Goal:** <what they were trying to achieve>
**Approach:** <what was tried>
**Why it failed:** <specific reason>
**What worked instead:** <the successful alternative>
**Source:** Session <id>, <date>
```

### 3.4 Operational Knowledge

**What to look for:**
- Deployment incidents and how they were resolved
- Debugging sessions with useful kubectl/docker/SSH commands
- Configuration changes that had unexpected effects
- Performance tuning discoveries

**Extract format:**
```markdown
#### Ops: <Title>

**Situation:** <what happened>
**Discovery:** <what was learned>
**Procedure:** <steps to reproduce or handle>
**Source:** Session <id>, <date>
```

### 3.5 Convention Discoveries

**What to look for:**
- Moments where an agent was corrected ("no, don't do it that way")
- Style or pattern preferences expressed by the user
- Rules that emerged from debugging ("always check X before Y")

**Extract format:**
```markdown
#### Convention: <Rule>

**Why:** <the reason this rule exists>
**Example:** <correct usage>
**Anti-pattern:** <what to avoid>
**Source:** Session <id>, <date>
```

---

## Step 4: Automated Extraction Script

For large conversation histories, use this script to pre-filter interesting sessions:

```bash
#!/usr/bin/env bash
# mine-kb-from-history.sh — Pre-filter conversations for KB-worthy content
# Usage: ./mine-kb-from-history.sh /path/to/project [output-dir]

set -euo pipefail

PROJECT_PATH="${1:?Usage: $0 /path/to/project [output-dir]}"
OUTPUT_DIR="${2:-.kb-mining-output}"
mkdir -p "$OUTPUT_DIR"

# ── Claude Code ──────────────────────────────────────────────
ENCODED=$(echo "$PROJECT_PATH" | sed 's|^/||; s|/|-|g')
CLAUDE_DIR="$HOME/.claude/projects/-${ENCODED}"

if [[ -d "$CLAUDE_DIR" ]]; then
  echo "=== Mining Claude Code conversations ==="
  
  # Keywords that indicate KB-worthy content
  KEYWORDS='bug|fix|broke|broken|issue|gotcha|mistake|wrong|revert|rollback|deploy|incident|decision|architecture|refactor|migration|workaround|hack|TODO|FIXME|CRITICAL|WARNING|never|always|must not|do not'
  
  for session in "$CLAUDE_DIR"/*.jsonl; do
    SESSION_ID=$(basename "$session" .jsonl)
    
    # Count KB-worthy keywords in session
    HITS=$(python3 -c "
import json, re, sys
count = 0
pattern = re.compile(r'($KEYWORDS)', re.IGNORECASE)
with open('$session') as f:
    for line in f:
        try:
            entry = json.loads(line)
            content = str(entry.get('content', ''))
            count += len(pattern.findall(content))
        except: pass
print(count)
" 2>/dev/null || echo "0")
    
    if [[ "$HITS" -gt 10 ]]; then
      echo "  High-signal session: $SESSION_ID ($HITS keyword hits)"
      
      # Extract user messages and assistant conclusions
      python3 -c "
import json, sys
with open('$session') as f:
    for line in f:
        try:
            entry = json.loads(line)
            role = entry.get('role', '')
            content = entry.get('content', '')
            if role in ('user', 'assistant') and isinstance(content, str) and len(content) > 50:
                # Truncate long entries
                display = content[:500] + ('...' if len(content) > 500 else '')
                print(f'[{role}] {display}')
                print('---')
        except: pass
" > "$OUTPUT_DIR/claude-${SESSION_ID:0:8}.txt" 2>/dev/null
    fi
  done
fi

# ── Codex ────────────────────────────────────────────────────
CODEX_HISTORY="$HOME/.codex/history.jsonl"

if [[ -f "$CODEX_HISTORY" ]]; then
  echo "=== Mining Codex conversations ==="
  
  python3 -c "
import json
with open('$CODEX_HISTORY') as f:
    for line in f:
        try:
            entry = json.loads(line)
            text = entry.get('text', '')
            # Filter by project-specific paths or module names
            project_base = '$(basename "$PROJECT_PATH")'
            if project_base.lower() in text.lower() or any(
                kw in text.lower() for kw in ['bug', 'fix', 'broke', 'deploy', 'revert']
            ):
                sid = entry.get('session_id', '?')[:8]
                ts = entry.get('ts', 0)
                print(f'[{sid}] {text[:200]}')
        except: pass
" > "$OUTPUT_DIR/codex-filtered.txt" 2>/dev/null
  
  CODEX_LINES=$(wc -l < "$OUTPUT_DIR/codex-filtered.txt" 2>/dev/null || echo "0")
  echo "  Found $CODEX_LINES relevant Codex entries"
fi

echo ""
echo "=== Output written to $OUTPUT_DIR/ ==="
echo "Review the files and extract KB entries manually."
echo "High-signal sessions have the most keyword hits — start there."
```

---

## Step 5: Deduplicate and Merge

Before adding extracted knowledge to the KB:

1. **Check if the KB already documents this.** Search existing `.kb/` files for the topic.
2. **Check if the code already shows this.** If the fix is obvious from reading the code, don't add a KB entry.
3. **Check if git history explains this.** If a commit message fully explains the decision, a KB entry adds no value.
4. **Merge related entries.** Multiple conversations about the same bug become one KB entry.
5. **Remove session references.** The final KB entries should not reference session IDs — those are ephemeral.

---

## Step 6: Place Extracted Knowledge

Route each extracted entry to the correct KB file:

| Category | Target File |
|----------|-------------|
| Bug patterns | `gotchas/common-bugs.md` |
| Failed approaches | `gotchas/common-bugs.md` (as anti-patterns) |
| Architectural decisions | `architecture/<relevant-component>.md` or `architecture/overview.md` |
| Cross-component cascades | `gotchas/cross-repo-changes.md` |
| Hidden dependencies | `gotchas/hidden-dependencies.md` |
| Deployment incidents | `operations/deployment.md` |
| Debugging techniques | `operations/debugging.md` |
| Convention discoveries | `conventions/coding-rules.md` or `conventions/testing.md` |
| Operational procedures | `operations/<relevant-topic>.md` |
| Business context | `context/product.md` |

---

## Quality Checklist

Before finalizing mined entries:

- [ ] Every entry has a clear symptom/situation (not just a fix)
- [ ] Root causes are specific (not "it was broken")
- [ ] Fixes include enough detail to reproduce
- [ ] No sensitive data (tokens, passwords, internal URLs that shouldn't be in a KB)
- [ ] Dates are absolute, not relative
- [ ] No session IDs or conversation-specific references in final KB entries
- [ ] Entries are grouped logically, not chronologically
- [ ] Duplicate entries are merged
