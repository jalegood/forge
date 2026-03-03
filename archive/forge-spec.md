# Forge — Spec-to-Ship Pipeline for Claude Code

> A lightweight, domain-agnostic development pipeline that turns you into the architect and gate reviewer while Claude Code handles execution.

---

## Core Concept

Forge is a **layered pipeline** living in `.forge/` that progressively transforms a product vision into committed code. You make decisions at defined checkpoints. AI handles everything between them.

The pipeline has **four layers with decreasing human involvement**:

| Layer | Name | You | AI | Artifact |
|-------|------|-----|-----|----------|
| 0 | Vision | 100% | 0% | `VISION.md` |
| 1 | Contract | 80% | 20% | `CONTRACT.md` |
| 2 | Workplan | 20% | 80% | `WORKPLAN.md` |
| 3 | Execution | 5% | 95% | Committed code |

**Key principle:** Everything above the Contract is *your judgment*. Everything below it is *mechanically derivable* from what's above. The Contract is the automation boundary.

---

## Layer 0 — Vision (`VISION.md`)

One page. Opinionated. Human-only. Answers three questions:

1. **What is this?** — One sentence.
2. **Who is it for?** — Target user and their pain.
3. **What are the pillars?** — 3-5 non-negotiable design/product principles that guide every decision downstream.

**Example (game):**
```
What: A factory-building game about managing pipeweed production.
Who: Players who love optimization puzzles and incremental progress.
Pillars:
  - Factory optimization is the core loop
  - Complexity emerges from simple, composable systems
  - Player decisions have visible downstream consequences
```

**Example (SaaS):**
```
What: A hosted webhook relay that lets indie devs test integrations locally.
Who: Solo devs tired of ngrok and localhost tunneling pain.
Pillars:
  - Zero-config first experience
  - Works behind corporate firewalls
  - Never touches or stores payload data
```

Vision is **immutable during a sprint**. If it changes, you're starting a new project, not pivoting mid-build.

---

## Layer 1 — Contract (`CONTRACT.md`)

The hard constraints and interface definitions. This is where your spec and architecture merge into one source of truth, organized by concern.

### Structure

```markdown
# Contract

## Data Model
<!-- Entities, relationships, state shapes. What exists. -->

## State Machines
<!-- Lifecycle of key entities. Valid transitions. -->

## Interfaces
<!-- API shapes, component props, event contracts. How things talk. -->

## Rules
<!-- Business logic, game mechanics, validation. What's true. -->

## Boundaries
<!-- Auth, permissions, rate limits, platform constraints. What's off-limits. -->
```

Each section uses **anchored headers** (e.g., `## Data Model`, `### Player Entity`) that become addressable references for Context Manifests (see below).

### Contract Principles

- Describes **what and why**, never how (no implementation details)
- Every statement is **testable** — if you can't write an assertion for it, it's too vague
- Ambiguities get a `<!-- UNRESOLVED: ... -->` comment — these become workplan tasks of type `clarify`

---

## Layer 2 — Workplan (`WORKPLAN.md`)

A **dependency-ordered task list** where each task is a self-contained work packet. AI generates this from Vision + Contract; you review, reorder, and approve.

### Task Format

```markdown
## [TASK-001] Setup project scaffold
- **Status:** pending | active | done | blocked
- **Type:** scaffold | feature | clarify | refactor | fix
- **Depends:** none
- **Files:** package.json, tsconfig.json, src/index.ts
- **Refs:** CONTRACT#data-model, CONTRACT#boundaries
- **Assert:** `npm run build` exits 0, project structure matches CONTRACT#interfaces
- **Size:** S (1 prompt) | M (2-3 prompts) | L (4-5 prompts)
```

### Key fields

- **Depends** — other task IDs that must be `done` first. This makes the workplan a DAG, so you always know the next unblocked task without thinking.
- **Refs** — the **Context Manifest**. Pointers to specific Contract sections. Only these sections get injected into the execution session. This is what keeps token usage tight and prevents the AI from hallucinating against stale context.
- **Assert** — concrete acceptance criteria. The gate check. If you can't write this, the task isn't well-defined yet.
- **Size** — rough estimate. If it's bigger than L, break it down further.

### Task Types

| Type | When | Human involvement |
|------|------|-------------------|
| `scaffold` | Project setup, config, boilerplate | Gate review only |
| `feature` | Vertical slice of functionality | Gate review only |
| `clarify` | Resolve a `<!-- UNRESOLVED -->` in Contract | Decision required |
| `refactor` | Improve structure without changing behavior | Gate review only |
| `fix` | Broken assertion from integration check | Gate review only |

---

## Context Manifests — The Novel Bit

Every task carries a `Refs` field that lists *exactly* which Contract sections the AI needs. When a session starts, only those sections get extracted and injected.

**Why this matters:**

- **Token efficiency**: A 2000-line Contract doesn't eat your context window when you only need 80 lines of it.
- **Focus**: The AI can't hallucinate against sections it never sees.
- **Automation-ready**: Manifest resolution is mechanical — parse the refs, extract the sections, build the prompt. No human judgment needed.

**Ref syntax:** `CONTRACT#section-name` or `CONTRACT#section-name/subsection`

**Example manifest for a "player inventory" task:**
```
Refs: CONTRACT#data-model/player-entity, CONTRACT#rules/inventory-limits, CONTRACT#interfaces/inventory-api
```

The slash command `forge-next` resolves these refs automatically before handing the task to Claude Code.

---

## Layer 3 — Execution (Slash Commands)

Forge integrates with Claude Code via custom slash commands in `.claude/commands/`.

### Commands

**`/forge-init`**
Scaffolds the `.forge/` directory with template files. Run once per project.

**`/forge-plan`**
Reads `VISION.md` + `CONTRACT.md`, generates `WORKPLAN.md`. You review and edit the output. Re-runnable — regenerates only `pending` tasks, preserves `done`.

**`/forge-next`**
The main execution command. It:
1. Finds the next unblocked `pending` task
2. Resolves its Context Manifest (extracts only referenced Contract sections)
3. Loads the appropriate prompt template for the task's `type`
4. Executes (code + assertion)
5. Reports result for gate review

**`/forge-gate`**
Runs the assertion for the current/specified task. Reports pass/fail. On pass, marks task `done` and suggests commit message.

**`/forge-status`**
Prints workplan progress: done/active/pending/blocked counts, next unblocked task, and any `clarify` tasks awaiting human input.

---

## CLAUDE.md Integration

The project's `CLAUDE.md` gets a small block pointing Claude Code to the pipeline:

```markdown
## Forge Pipeline
This project uses Forge for structured development.
- Pipeline files: .forge/
- Always check .forge/WORKPLAN.md for current task status before starting work
- Use /forge-next to begin work on the next task
- Never modify CONTRACT.md without human approval
- Commit after each task passes its gate
```

This ensures Claude Code respects the pipeline even in freeform sessions.

---

## Directory Structure

```
project-root/
├── .forge/
│   ├── VISION.md
│   ├── CONTRACT.md
│   ├── WORKPLAN.md
│   └── templates/          # prompt templates per task type
│       ├── scaffold.md
│       ├── feature.md
│       ├── clarify.md
│       ├── refactor.md
│       └── fix.md
├── .claude/
│   └── commands/
│       ├── forge-init.md
│       ├── forge-plan.md
│       ├── forge-next.md
│       ├── forge-gate.md
│       └── forge-status.md
├── CLAUDE.md
└── ... (project files)
```

---

## What Forge Doesn't Do

- **No sub-agents.** You are the orchestrator. This is intentional — it's more stable and you maintain decision authority.
- **No hidden state.** Everything is in readable markdown files. No databases, no caches, no magic.
- **No lock-in.** The files are useful even without the slash commands. You can run the pipeline manually by reading WORKPLAN.md and copy-pasting context.

---

## Domain Adaptation

The framework is identical across domains. What changes:

| What varies | Game example | SaaS example |
|------------|--------------|--------------|
| Vision pillars | "Factory optimization is core loop" | "Zero-config first experience" |
| Contract sections | State machines, game rules, entity stats | API contracts, auth flows, billing rules |
| Task types emphasis | More `feature` + `clarify` | More `scaffold` + `feature` |
| Prompt templates | "Implement mechanic X that satisfies rules Y" | "Build endpoint X that satisfies contract Y" |

---

## Build Plan — Session-Sized Executables

This framework can be built in **2 sessions**.

### Session 1: Foundation (Size M — ~3 prompts)

**Goal:** `.forge/` directory with all template files, ready to fill in for any project.

| Step | Deliverable | Depends |
|------|------------|---------|
| 1a | `forge-init` slash command that scaffolds `.forge/` with empty templates | — |
| 1b | `VISION.md` template with inline guidance comments | — |
| 1c | `CONTRACT.md` template with section structure and ref anchor conventions | — |
| 1d | `WORKPLAN.md` template with task format and status conventions | — |
| 1e | All 5 prompt templates (`scaffold`, `feature`, `clarify`, `refactor`, `fix`) | — |

**Gate:** Running `/forge-init` in a clean project creates the full directory structure with usable templates.

### Session 2: Slash Commands + Integration (Size M — ~3 prompts)

**Goal:** Working Claude Code commands that drive the pipeline.

| Step | Deliverable | Depends |
|------|------------|---------|
| 2a | `forge-plan` command — reads Vision + Contract, outputs Workplan draft | Session 1 |
| 2b | `forge-next` command — finds unblocked task, resolves Context Manifest, executes | Session 1 |
| 2c | `forge-gate` command — runs assertion, reports result, updates status | 2b |
| 2d | `forge-status` command — prints progress summary | Session 1 |
| 2e | `CLAUDE.md` injection block | Session 1 |

**Gate:** Full loop works end-to-end: `/forge-plan` → `/forge-next` → `/forge-gate` → `/forge-status` shows progress.

### Optional Session 3: Battle Test

Take Halfling Hustle's existing spec, split it into Vision + Contract using the templates, generate a Workplan, and execute 2-3 tasks through the pipeline. This validates the framework against a real project and surfaces any friction points.

---

*Forge v0.1 — Starter Spec*