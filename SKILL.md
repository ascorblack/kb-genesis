---
name: kb-genesis
description: Analyze a project and create a structured .kb/ knowledge base from scratch. Universal standard for any language, framework, or stack. Produces agent-readable documentation that compounds across sessions.
user-invocable: true
argument-hint: "[mine-history] [create-hooks]"
allowed-tools: Read Bash Edit Write Glob Grep Agent
---

# KB Genesis — Create a Project Knowledge Base

You are creating a **structured knowledge base** (`.kb/` directory) for the current project. This KB will be read by AI coding agents (Claude Code, Codex, Gemini CLI, Cursor, etc.) at the start of every work session. It captures institutional knowledge that cannot be derived from reading code alone.

## Companion Skills

This skill has companion files for specialized tasks. Read them when needed:
- [kb-mine-history.md](kb-mine-history.md) — extract knowledge from existing AI agent conversation histories (Claude Code, Codex, OpenCode)
- [kb-create-hooks.md](kb-create-hooks.md) — create enforcement hooks that inject KB context at session start and guard deployments

## Why This Matters

Without a KB, every new agent session starts from zero. Agents repeat the same mistakes, miss non-obvious coupling, break deployments, and waste hours rediscovering what was already known. A good KB turns a stateless agent into one with institutional memory.

---

## Phase 1: Project Analysis

Before creating any files, you must deeply understand the project. Do ALL of the following:

### 1.1 Structural Analysis

```
Understand the project layout:
- What repositories or packages exist? (mono-repo vs. multi-repo vs. single repo)
- What is the dependency direction between them?
- What languages, frameworks, and runtimes are used?
- What is the build system? (npm, cargo, gradle, uv, poetry, make, just, etc.)
- What is the test framework and how are tests run?
- What CI/CD system is used? (GitHub Actions, GitLab CI, Jenkins, etc.)
- What infrastructure is used? (Kubernetes, Docker Compose, serverless, bare metal)
- What databases, caches, queues, and external services are involved?
```

**Actions:** Read every `README.md`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `Makefile`, `Justfile`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `docker-compose.yml`, `Dockerfile`, CI config files, and deployment configs you can find.

### 1.2 Architecture Mapping

```
Map the high-level architecture:
- What are the main services/components and what does each do?
- How do they communicate? (HTTP, gRPC, message queue, shared DB, IPC)
- What are the public API surfaces?
- What are the key abstractions/interfaces/protocols?
- Where is state stored and how is it shared?
- What are the security boundaries? (auth, RBAC, sandboxing)
```

**Actions:** Read entry points (`main.py`, `app.ts`, `main.go`, `lib.rs`), router/controller files, configuration files, and key interface/protocol definitions.

### 1.3 Convention Discovery

```
Identify project conventions:
- Code style rules beyond linter defaults
- Naming conventions for files, classes, functions, variables
- Error handling patterns (exceptions, Result types, error codes)
- Logging conventions (levels, format, structured vs. plain)
- Testing conventions (unit vs. integration vs. E2E, mocking rules)
- Git workflow (branching model, commit message format, PR process)
- Import/dependency rules (what can import what)
```

**Actions:** Read linter configs (`.eslintrc`, `ruff.toml`, `.golangci.yml`), read recent git history for commit message patterns, examine test directories for conventions.

### 1.4 Operational Knowledge

```
Understand how the project runs in production:
- How is it deployed? What are the exact commands?
- What environments exist? (dev, staging, production)
- How do you verify a deployment succeeded?
- What monitoring/alerting exists?
- What are the known failure modes?
- What are the manual operational procedures?
```

**Actions:** Read deployment scripts, CI/CD configs, Helm charts, Terraform files, runbooks, and ops documentation.

### 1.5 History Mining (CRITICAL)

```
Extract knowledge from existing agent conversation histories.
This is where the richest gotchas, bug patterns, and architectural 
decisions live — in the conversations where they were discovered.
```

**Actions:** If the `kb-mine-history` skill is available, invoke it now. Otherwise, follow these steps manually:

1. Locate conversation histories (see History Mining section below)
2. Filter to conversations about THIS project only
3. Extract: bug patterns, architectural decisions, gotchas, failed approaches, deployment incidents
4. Deduplicate against what's already visible in code/docs

### 1.6 Business Context

```
Understand the non-technical context:
- What is this product? Who uses it?
- What are the current priorities and deadlines?
- Who works on what?
- What regulatory or compliance constraints exist?
- What are the known technical debt items and why they exist?
```

**Actions:** Read product docs, roadmaps, issue trackers (if accessible), and any planning documents.

---

## Phase 2: KB Structure

Create the `.kb/` directory with this exact structure. Adapt categories to the project — not every project needs every category, and some projects need additional ones.

### Standard Structure

```
.kb/
├── INDEX.md                    # Navigation hub — ALWAYS exists
├── README.md                   # KB usage guide — ALWAYS exists
├── architecture/               # System design and component docs
│   ├── overview.md             # Repo map, dependency graph, infrastructure
│   └── <component>.md          # One file per major component/service
├── runtime/                    # Runtime behavior and internals
│   ├── <subsystem>.md          # One file per runtime subsystem
│   └── known-issues.md         # Tracked bugs with status and severity
├── operations/                 # Deployment, monitoring, debugging
│   ├── deployment.md           # Full deployment runbook with commands
│   ├── debugging.md            # How to debug in production
│   └── <topic>.md              # Additional ops topics as needed
├── conventions/                # Rules, patterns, standards
│   ├── coding-rules.md         # Import boundaries, style, patterns
│   ├── testing.md              # Test structure, methodology, anti-patterns
│   └── <topic>.md              # Additional convention topics
├── gotchas/                    # Things that silently break
│   ├── common-bugs.md          # Bug catalog: symptom → root cause → fix
│   ├── cross-repo-changes.md   # Change cascades between components
│   └── hidden-dependencies.md  # Non-obvious coupling and side effects
└── context/                    # Business and project context
    ├── product.md              # What this is, who uses it, priorities
    ├── active-work.md          # Current initiatives and their status
    └── commands.md             # Build, test, lint, deploy command reference
```

### When to Add/Remove Categories

| If the project... | Add | Remove |
|---|---|---|
| Is a single repo with no deployment | — | `operations/`, reduce `gotchas/cross-repo-changes.md` |
| Has complex runtime behavior (orchestration, state machines, event systems) | `runtime/` with detailed subsystem docs | — |
| Is a library, not a service | `api/` for public API surface docs | `operations/`, `runtime/` |
| Has complex data pipelines | `pipelines/` or `data/` | — |
| Is infrastructure-heavy (IaC, platform) | `infrastructure/` | `runtime/` |
| Has no production deployment yet | — | `operations/deployment.md` (add when relevant) |

---

## Phase 3: File Format Standard

Every KB file MUST follow this format:

### Frontmatter

```markdown
---
title: "Human-readable title"
description: "One-line description — used for search and INDEX.md"
---
```

### Content Rules

1. **Write for AI agents, not humans.** Use tables, code blocks, and structured lists over flowing prose.

2. **Lead with the most important information.** An agent reading the first 20 lines should get the key insight.

3. **Use Symptom → Root Cause → Fix for bugs:**
   ```markdown
   ### Bug: Sessions Not Persisting After Pod Restart
   
   **Symptom:** User sessions disappear after Kubernetes pod restarts.
   **Root cause:** Session state stored in-process memory instead of Redis.
   **Fix:** Migrate session storage to Redis. See commit `abc123`.
   **Status:** RESOLVED (2026-03-15)
   ```

4. **Use tables for reference data:**
   ```markdown
   | Command | Purpose | When to Use |
   |---------|---------|-------------|
   | `npm run build` | Production build | Before deploy |
   | `npm run dev` | Dev server | Local development |
   | `npm test` | Run all tests | Before commit |
   ```

5. **Use code blocks with language identifiers:**
   ```markdown
   ```python
   # Correct: use the session manager
   session = await session_manager.get(session_id)
   
   # Wrong: direct database access
   session = await db.query("SELECT * FROM sessions WHERE id = ?", session_id)
   `` `
   ```

6. **Cross-reference other KB files with relative paths:**
   ```markdown
   See [Deployment Pipeline](../operations/deployment.md) for the full runbook.
   See [Known Issues](../runtime/known-issues.md#session-persistence) for status.
   ```

7. **End every file with a Cross-References section:**
   ```markdown
   ## Cross-References
   
   - [Architecture Overview](../architecture/overview.md) — system context
   - [Common Bugs](../gotchas/common-bugs.md) — related bug patterns
   ```

8. **Use emphasis for critical warnings:**
   ```markdown
   **CRITICAL:** Never run `sync.sh` manually — it overwrites production image tags.
   ```

9. **Reference file paths and function names, never line numbers** (line numbers shift).

10. **Keep individual files under 1000 lines.** Split large files by topic. Exception: `common-bugs.md` may grow larger as bugs accumulate.

---

## Phase 4: INDEX.md and README.md

### INDEX.md Template

```markdown
---
title: "Knowledge Base Index"
description: "Top-level index of all knowledge base topics with one-line descriptions"
---

# Knowledge Base Index

Read the relevant sections before starting work. Each link goes to a self-contained document.

## Architecture

- [Overview](architecture/overview.md) — repo map, dependency graph, infrastructure
- [<Component Name>](architecture/<component>.md) — <one-line description>

## Runtime Internals

- [<Subsystem>](runtime/<subsystem>.md) — <one-line description>
- [Known Issues](runtime/known-issues.md) — tracked bugs with status and severity

## Operations

- [Deployment Pipeline](operations/deployment.md) — full runbook with commands
- [Debugging](operations/debugging.md) — production debugging techniques

## Conventions

- [Coding Rules](conventions/coding-rules.md) — <key rules summary>
- [Testing](conventions/testing.md) — test structure and methodology

## Gotchas

- [Common Bugs](gotchas/common-bugs.md) — recurring bug patterns with fixes
- [Cross-Component Changes](gotchas/cross-repo-changes.md) — change cascades
- [Hidden Dependencies](gotchas/hidden-dependencies.md) — non-obvious coupling

## Context

- [Product & Business](context/product.md) — what this is, who uses it
- [Active Work](context/active-work.md) — current initiatives and status
- [Commands Reference](context/commands.md) — build, test, deploy commands
```

### README.md Template

```markdown
---
title: "Knowledge Base Guide"
description: "How to use this knowledge base, structure overview, and update guidelines"
---

# Project Knowledge Base

This directory is the **agent knowledge base** for [PROJECT_NAME]. It is designed to be read by AI agents at the start of work sessions.

## How to Use

1. **Always start with [INDEX.md](INDEX.md)** — lists all topics with one-line descriptions
2. **Read only what you need** — each file is self-contained for its topic
3. **Follow cross-references** — files link to related topics via relative paths
4. **Check gotchas before changes** — read [common-bugs.md](gotchas/common-bugs.md) before working in a new area

## Structure

| Directory | Contents |
|-----------|----------|
| `architecture/` | System design, component docs, dependency graph |
| `runtime/` | Runtime behavior, subsystem internals, known issues |
| `operations/` | Deployment, debugging, monitoring procedures |
| `conventions/` | Code rules, testing patterns, workflow standards |
| `gotchas/` | Bug patterns, change cascades, hidden dependencies |
| `context/` | Business context, active initiatives, command reference |

## Freshness

- Architecture and convention files change rarely — generally trustworthy
- `context/active-work.md` may become stale — verify against git log if in doubt
- `gotchas/common-bugs.md` is append-mostly — check if a bug is already documented before investigating
- File paths and class names are stable; line numbers are NOT included (they shift)

## When to Update

Update the KB when you discover:
- A non-obvious bug pattern or gotcha
- An architectural decision that changes how components interact
- A new deployment procedure or operational trick
- A hidden dependency between components

Do NOT add:
- Ephemeral task status or conversation-specific notes
- Information already derivable from reading the code or git history
- Detailed API docs that belong in code comments or generated docs

## Repository Boundary

[CHOOSE ONE — delete the other]

**Option A: KB is part of the project repo**
`.kb/` is committed alongside the project code. Changes to KB go in the same PR as code changes when relevant.

**Option B: KB is a standalone repo**
`.kb/` has its own `.git/` directory. Commits must use `git -C .kb ...`. Pushing the main project does NOT push KB changes.
```

---

## Phase 5: Writing Each Category

### architecture/overview.md

Must contain:
- **Repository/package map** with one-line descriptions
- **Dependency direction** (what imports/calls what, and what MUST NOT)
- **Infrastructure baseline** (databases, caches, queues, external services)
- **Runtime URLs** (if applicable — dev, staging, production endpoints)
- **Technology stack** with versions

### architecture/<component>.md

Must contain:
- **Directory structure** of the component
- **Key classes/functions/types** with purpose (use tables)
- **Public API surface** (endpoints, exported functions, CLI commands)
- **Extension points** (where new functionality gets added)
- **Critical anti-patterns** (what NOT to do in this component)

### runtime/<subsystem>.md

Must contain:
- **How the subsystem works** at a conceptual level
- **Key data flow** (input → processing → output)
- **State management** (where state lives, how it's shared)
- **Extension/configuration mechanisms**
- **Debugging checklist** for when things go wrong

### runtime/known-issues.md

Format each issue as:

```markdown
### <N>. <Issue Title>

**Status:** UNRESOLVED | IDENTIFIED | MITIGATED | RESOLVED
**Severity:** CRITICAL | HIGH | MEDIUM | LOW
**Since:** <date>

**Symptom:** What the user/agent observes
**Root cause:** Why it happens (or "Under investigation")
**Current mitigation:** What's in place now
**Permanent fix:** What needs to happen (or "N/A — resolved")
**Related:** Links to other KB files, commits, issues
```

### operations/deployment.md

Must contain:
- **Deployment contract** (what system, what constraints)
- **Hard rules** (things that MUST or MUST NEVER be done)
- **Step-by-step deployment procedure** with exact commands
- **Post-deployment verification** with exact commands
- **Rollback procedure**
- **Known project/service IDs** (CI/CD identifiers)

### operations/debugging.md

Must contain:
- **How to inspect running services** (logs, shell access, metrics)
- **Common debugging patterns** with exact commands
- **How to verify deployed code** matches what was committed

### conventions/coding-rules.md

Must contain:
- **Import/dependency boundaries** (what can import what)
- **Enforced rules** (with references to tests/linters that enforce them)
- **State management rules** (in-memory vs. persistent, thread safety)
- **Error handling patterns**
- **Logging rules** (levels, format, what to log)
- **Critical anti-patterns** with "do this instead" examples

### conventions/testing.md

Must contain:
- **Test structure** (directories, naming, organization)
- **How to run tests** (exact commands)
- **Coverage thresholds** (if any)
- **Testing anti-patterns** specific to this project

### gotchas/common-bugs.md

The most valuable file in the KB. Format:

```markdown
## Bug Catalog

### <Category>

#### <Bug Title>

**Symptom:** What you observe
**Root cause:** Why it happens
**Fix:** What to do (with code snippets or commands)
**Prevention:** How to avoid it in the future
```

Group bugs by category (deployment, data, API, frontend, testing, etc.). This file grows over time — every agent session that discovers a non-obvious bug MUST add it here.

### gotchas/cross-repo-changes.md (or cross-component-changes.md)

Must contain:
- **Dependency direction** reminder
- **Real examples** of changes that cascaded between components
- **Checklists** for "if you change X, also check Y"
- **Deployment order** when multiple components change

### context/product.md

Must contain:
- **What this project is** (one paragraph)
- **Who uses it** (target users/customers)
- **Current priorities** (what matters most right now)
- **Strategic constraints** (regulatory, performance, compatibility)
- **Team structure** (who works on what — if relevant)

### context/commands.md

Must contain a **quick reference table** for every common operation:

```markdown
| Task | Command | Notes |
|------|---------|-------|
| Install dependencies | `npm install` | Run after pulling |
| Run dev server | `npm run dev` | http://localhost:3000 |
| Run all tests | `npm test` | Requires DB running |
| Lint | `npm run lint` | Auto-fixes with --fix |
| Build for production | `npm run build` | Output in dist/ |
| Deploy to staging | `./deploy.sh staging` | Requires VPN |
```

---

## Phase 6: Integration with Agent Config Files

After creating the KB, update the project's agent configuration files to reference it.

### CLAUDE.md / AGENTS.md Addition

Add this block to the project's `CLAUDE.md` and/or `AGENTS.md`:

```markdown
## Agent Knowledge Base (MANDATORY)

**Read `.kb/INDEX.md` BEFORE writing any code or making decisions.**

The KB at `.kb/` contains architecture docs, runtime internals, gotchas, conventions, and operational runbooks. Skipping it means repeating mistakes that are already documented.

### Before Starting Work

1. **Always read** `.kb/INDEX.md` — find which KB files are relevant
2. **Always read** `.kb/gotchas/common-bugs.md` — every known bug pattern is here
3. **Read** the specific KB files for your work area

### After Completing Work

Update `.kb/` if you discovered:
- A new bug pattern or gotcha → add to `gotchas/common-bugs.md`
- A cascading change pattern → add to `gotchas/cross-repo-changes.md`
- An architectural decision → add to the relevant `architecture/` file
- A new operational procedure → add to `operations/`
```

### Hooks Setup

After creating the KB, invoke the `kb-create-hooks` skill (or follow the hooks section in that file) to set up:
1. **SessionStart hook** — injects KB index into every agent session
2. **PreToolUse hook** — guards deployment commands with KB reminders

---

## Phase 7: Git Setup

### Option A: KB Inside Project Repo (Simple)

```bash
git add .kb/
git commit -m "Add agent knowledge base"
```

### Option B: KB as Standalone Repo (Multi-Repo Projects)

```bash
cd .kb
git init
git add .
git commit -m "Initial knowledge base"
git remote add origin <kb-repo-url>
git push -u origin main
```

Use Option B when:
- Multiple repos share the same KB
- KB updates should not trigger app CI/CD pipelines
- Different teams manage code vs. knowledge

---

## Phase 8: Verification

After creating the KB, verify:

1. **INDEX.md lists every file** — no orphaned documents
2. **Every file has frontmatter** — title and description
3. **Every file ends with Cross-References** — no dead-end documents
4. **Cross-references resolve** — no broken links
5. **No line numbers** — only file paths and function/class names
6. **No ephemeral information** — nothing that will be stale in a week
7. **Code blocks have language identifiers** — for proper rendering
8. **Commands are copy-pasteable** — exact commands, not pseudocode
9. **Gotchas have all four fields** — symptom, root cause, fix, prevention
10. **Known issues have status and severity** — trackable over time

---

## Maintenance Rules

These rules must be communicated to all agents working on the project:

1. **Read before work.** Always read INDEX.md and relevant sections before starting.
2. **Update after discoveries.** Every non-obvious finding gets added to the KB.
3. **Append, don't rewrite.** Add new entries to existing files; don't restructure without reason.
4. **Mark resolved issues.** When a known issue is fixed, update its status — don't delete it.
5. **Keep INDEX.md current.** Every new file gets an entry; every deleted file loses its entry.
6. **No stale dates.** Convert relative dates ("next week") to absolute dates ("2026-04-21").
7. **Commit KB separately** if it's a standalone repo.
8. **Prune quarterly.** Remove entries that are no longer relevant. A stale KB is worse than no KB.
