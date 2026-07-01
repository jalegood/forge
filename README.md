# Forge

A spec-to-ship development pipeline for Claude Code. You make decisions at defined checkpoints. AI handles everything between them.

## What Forge Does

Forge gives you a repeatable rhythm for building software with Claude Code across multiple sessions:

1. **You** write the Vision (what you're building) and Contract (the hard constraints)
2. **AI** generates a task-by-task Workplan from your Contract
3. **You** review the plan
4. **AI** executes one task per session with surgical context injection
5. **You** review the output and approve the commit
6. Repeat until done

Every task gets only the Contract sections it needs (not the whole spec), runs in a fresh session (full reasoning capacity), and ends with an automated gate check before you commit.

## Quick Start

### 1. Copy the commands

Copy `.claude/commands/` from this repo into your project:

```text
cp -r .claude/commands/ /path/to/your-project/.claude/commands/
```

That's the only thing you need to copy. Everything else — templates, scripts, stub files, hook config — is created by `/forge-init` in the next step.

### 2. Bootstrap the pipeline

```text
/forge-init
```

This creates all required scaffold files — `.forge/VISION.md`, `.forge/CONTRACT.md`, `.forge/UX.md`, `.forge/DESIGN.md`, prompt templates, gate scripts, hook config, and a `CLAUDE.md` integration block. Safe to re-run: existing files are never overwritten.

### 3. Write your Vision

Edit `.forge/VISION.md`:

```markdown
What: [One sentence — what is this?]
Who: [Target user and their pain]
Pillars:

- [Non-negotiable principle 1]
- [Non-negotiable principle 2]
- [Non-negotiable principle 3]
```

### 4. Write your Contract

Edit `.forge/CONTRACT.md` with these sections:

- **Data Model** — entities, relationships, state shapes
- **State Machines** — lifecycle of key entities
- **Interfaces** — API shapes, component props, event contracts
- **Rules** — business logic, validation, invariants
- **Boundaries** — auth, permissions, constraints

Every statement should be testable. If something is ambiguous, mark it with `<!-- UNRESOLVED: ... -->`.

Two optional spec files feed into the pipeline alongside the Contract:

- **`.forge/UX.md`** — screen-level experience spec: flows, states, copy, emotional intent. `/forge-plan` generates `ux-spec` tasks (one per screen) that gate feature tasks — no feature task for a screen can run until its `ux-spec` task is done.
- **`.forge/DESIGN.md`** — visual design system: tokens, typography, spacing, component specs. Hand-author it or generate it with a design tool. Feature tasks automatically reference `DESIGN#tokens` and relevant component sections when implementing screens.

Fill these in before running `/forge-plan` if you want the pipeline to include UX and design context.

### 5. Generate the Workplan

Run `/forge-plan`. Review the generated tasks. Edit anything that doesn't look right.

### 6. Start building

```text
/forge-next
```

## The Workflow Loop

```text
1. /forge-next          → AI picks the next task, does the work, runs the gate
2. You review           → Read the code and gate result. Does it match intent?
3. On pass: commit      → One task, one commit.
4. /clear               → Fresh session for the next task.
5. Repeat.
```

**Why `/clear` between every task?** Fresh sessions give Claude full 200K reasoning capacity. Continued sessions degrade. The workplan and git history carry everything forward — conversation history is disposable.

## Commands

### `/forge-init`

Bootstraps a new Forge project by creating all required scaffold files. Safe to re-run — never overwrites existing files.

- Creates `.forge/VISION.md` and `.forge/CONTRACT.md` stubs
- Creates all six prompt templates under `.forge/templates/`
- Creates `.claude/settings.json` with placeholder hook config
- Appends the Forge integration block to `CLAUDE.md` (or creates it)

Run this once in a new project before writing your Vision or Contract.

### `/forge-plan`

Reads your Vision + Contract and generates (or regenerates) the Workplan.

- First run: creates WORKPLAN.md with dependency-ordered tasks
- Subsequent runs: regenerates `pending` tasks only — `done` and `active` tasks are preserved
- Always review the output before proceeding

### `/forge-next`

The main execution command. Picks the next unblocked task, injects relevant Contract context, executes, and runs the gate.

- **Override:** `/forge-next TASK-012` to execute a specific task out of order
- If the specified task has unmet dependencies, you'll be warned and asked to confirm

### `/forge-status`

Read-only progress summary: done/active/pending/blocked counts, next unblocked task, any `clarify` tasks awaiting your input.

## Task Types

| Type          | Purpose                                     | Typical Gate                                          |
| ------------- | ------------------------------------------- | ----------------------------------------------------- |
| `scaffold`    | Project setup, config, boilerplate          | Structure checks                                      |
| `feature`     | Vertical slice of functionality             | `npm test && npm run build`                           |
| `ux-spec`     | Author or complete a screen spec in UX.md   | `node .forge/scripts/check-ux-spec.js "Screen Name"` |
| `clarify`     | Resolve a `<!-- UNRESOLVED -->` in Contract | Contract updated, ambiguity removed                   |
| `refactor`    | Improve structure, preserve behavior        | Existing tests pass                                   |
| `fix`         | Repair a broken gate or bug                 | Original failing command passes                       |
| `investigate` | Diagnose issues, explore unknowns           | `manual:` — findings documented in Notes              |

## Common Scenarios

### The Contract needs to change mid-build

This will happen. A good Contract evolves as you learn from implementation.

1. Update the specific sections in CONTRACT.md
2. Review WORKPLAN.md — identify tasks that reference the changed sections:
   - **Done tasks** that implemented against old definitions may need `fix` tasks
   - **Pending tasks** with Context pointing to changed sections may need re-scoping
3. Either manually add corrective tasks, or run `/forge-plan` to regenerate pending tasks
4. Commit the Contract change + workplan updates together

The key: don't let the Contract drift from reality. A wrong Contract is worse than a changed one.

### Code review feedback after a task is "done"

The gate passed, you committed, but a review (yours or a teammate's) surfaces issues.

- **Design feedback / missed edge cases:** Create a `fix` task referencing the original. Set its Context to the same Contract sections. The gate should include the original gate plus any new assertions.
- **Naming or style concerns:** Create a `refactor` task. Gate: existing tests still pass.
- **Fundamental approach was wrong:** This is really a Contract amendment (see above). Update the Contract first, then create corrective tasks.

### Investigating a bug or performance issue

You don't know what's wrong yet. You need to explore before you can plan a fix.

Use an `investigate` task:

```markdown
## [TASK-XXX] Investigate slow query on user dashboard

- **Status:** pending
- **Type:** investigate
- **Gate:** `manual: Root cause identified and documented in Notes`
```

The deliverable is understanding, not code. Write findings to Notes, propose follow-up tasks. Don't fix the issue in the investigation task — that's scope creep.

### A task is too big (discovered mid-session)

You're 3 exchanges in and realize this task is actually two tasks.

1. Stop. Don't keep pushing.
2. Write what you've accomplished and what remains to `Notes`
3. Commit partial progress
4. Edit WORKPLAN.md: shrink the current task to cover what's done, add a new task for the remainder
5. `/clear` and continue with the new task

Splitting mid-session is normal, not a failure. The spec's rule: if a task needs 3+ exchanges, it's too big.

### Hotfix / production emergency

Something breaks and you need to fix it now, outside the planned sequence.

1. `/clear` if you have an active session
2. Add a `fix` task to WORKPLAN.md with `Depends: none` (bypasses the DAG)
3. `/forge-next TASK-XXX` to execute it immediately
4. Commit, then resume the planned sequence

The workplan stays accurate as a log of what actually happened, even if the execution order wasn't what you planned.

### Working out of order

The next unblocked task is TASK-006 but you want to work on TASK-008.

Use the override: `/forge-next TASK-008`

If TASK-008 has unmet dependencies, Forge will warn you. Sometimes this is fine (the dependency is satisfied in practice even if not marked `done`). Sometimes it's a signal to reconsider.

### Resuming after a break

You left the project for days or weeks.

1. Run `/forge-status` to see where things stand
2. Check for any `active` tasks — these were interrupted. Read their `Notes` for context.
3. Run `/forge-next` to pick up where you left off

The workplan + git log tell the full story. You don't need conversation history.

### Large projects (scoped planning)

If your Contract exceeds ~500 lines, plan in passes instead of all at once:

1. Plan shared foundations first: Data Model + Boundaries → scaffold tasks
2. Plan each system independently: System A → feature tasks, System B → feature tasks
3. Cross-system dependencies wire up automatically through the unified workplan DAG

See the spec's "Planning at Scale" section for the full pattern.

## Gate Patterns

Gates validate structure, not quality. Match your gate to the deliverable:

| Deliverable    | Strategy           | Example                                                             |
| -------------- | ------------------ | ------------------------------------------------------------------- |
| Code           | Test suite / build | `npm test && npm run build`                                         |
| Config / JSON  | Parse + key check  | `node -e "JSON.parse(require('fs').readFileSync('f.json','utf8'))"` |
| Markdown       | Structural check   | `grep -q '{{context}}' file.md`                                     |
| Human judgment | `manual:` prefix   | `manual: Verify the UI matches the mockup`                          |

When the gate starts with `manual:`, Forge presents the description to you instead of running a command. Automated gates are always preferred — use `manual:` only when no structural check is possible.

## File Structure

```text
project-root/
├── .forge/
│   ├── VISION.md              # What, who, pillars (you own this)
│   ├── CONTRACT.md            # Hard constraints and interfaces (you own this)
│   ├── UX.md                  # Screen-level experience spec (optional)
│   ├── DESIGN.md              # Visual design system: tokens, components (optional)
│   ├── WORKPLAN.md            # Task DAG (AI generates, you review)
│   ├── templates/             # Prompt templates per task type
│   │   ├── scaffold.md
│   │   ├── feature.md
│   │   ├── ux-spec.md
│   │   ├── clarify.md
│   │   ├── refactor.md
│   │   ├── fix.md
│   │   └── investigate.md
│   ├── scripts/
│   │   └── check-ux-spec.js   # Gate script for ux-spec tasks
│   └── tests/                 # Smoke tests for pipeline validation
├── .claude/
│   ├── commands/              # Slash commands — copy these from Forge repo
│   │   ├── forge-init.md
│   │   ├── forge-plan.md
│   │   ├── forge-next.md
│   │   └── forge-status.md
│   └── settings.json          # Hook configuration
├── CLAUDE.md                  # Minimal 3-line pipeline pointer
└── ... (project files)
```

## Design Principles

1. **One task, one session, one commit.** Sessions are cheap. Context quality is not.
2. **Deterministic enforcement over instruction-following.** Hooks and scripts enforce quality. CLAUDE.md reminds. If it matters, it must not depend on Claude reading a rule.
3. **Git is the memory.** Commits are checkpoints. The workplan is the log. Everything else is ephemeral.
4. **Progressive context, not total context.** Each task sees only the Contract sections it needs.
5. **You are the architect.** You own the Vision and Contract. AI derives plans and writes code. You review gates.

## Troubleshooting

**Commands don't appear.** Run `/context` to verify Forge commands loaded. Slash commands have a character budget — if you have many other commands or skills, Forge's may be silently excluded.

**Gate passes but output is wrong.** Gates check structure, not quality. You are the quality gate. If a gate is too lenient, strengthen it before the next task.

**Context seems stale.** Run `/clear` and start a fresh session. Context continuation doesn't re-read configuration files — this is a known Claude Code behavior.

**Task is too big.** Split it. Write Notes, commit partial progress, edit the workplan, `/clear`, continue. This is the most common mid-session adjustment and is expected.

**Workplan feels outdated after Contract changes.** Run `/forge-plan` to regenerate pending tasks. Done tasks are preserved — add `fix` tasks manually if completed work needs to be reconciled with the new Contract.

**Hook fails on first run.** The pre-commit test hook is disabled by default. Enable it after your test infrastructure exists. Check `.claude/settings.json` to verify hook configuration.
