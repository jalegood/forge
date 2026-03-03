## Pre-Revision Notes

### What the research puts pressure on

**1. CLAUDE.md is not a reliable enforcement mechanism.**
The v0.1 spec places pipeline instructions in CLAUDE.md ("Always check WORKPLAN.md for current task status," "Never modify CONTRACT.md without human approval"). But Claude Code's system prompt wraps CLAUDE.md with a disclaimer that the content "may or may not be relevant." With ~150 instruction slots total and ~50 consumed by the system prompt, every line in CLAUDE.md competes for attention. The v0.1 integration block is 5 lines of behavioral rules — exactly the kind of content that gets deprioritized as context fills. This means the spec's safety rails (don't modify CONTRACT, commit after gates) are advisory at best.

**Fix:** CLAUDE.md should do almost nothing — point to files, state the tech stack, declare the pipeline exists. Behavioral enforcement moves to hooks (deterministic, can't be ignored) and to the slash command prompts themselves (fresh context, high attention).

**2. Slash commands are fragile and have a character budget.**
The spec defines 5 slash commands. The research documents chronic discovery failures and a character budget limit where excess commands get silently excluded. If the user has other commands or skills installed, Forge commands could be the ones dropped.

**Fix:** Reduce the command count. Merge `forge-gate` into `forge-next` (gate is the natural end of execution, not a separate step). Keep `forge-status` lightweight. Consider whether `forge-plan` and `forge-init` can be a single command. Also: document that users should run `/context` to verify commands loaded.

**3. Task size "L (4-5 prompts)" is too large.**
The research shows quality degrades after ~50 exchanges and hits a cliff at 70% context capacity. A task requiring 4-5 prompts of back-and-forth could easily push past the quality window, especially with Contract context injected. The v0.1 sizing encourages tasks that are too large for reliable single-session execution.

**Fix:** Redefine sizing. Maximum task size should target a single focused prompt with one review cycle. If a task needs more, it should be decomposed. "One task, one session, one commit" should be the default rhythm.

**4. Session boundaries are the critical gap.**
The v0.1 spec describes a multi-session pipeline but has no explicit protocol for what happens between sessions. The research shows: context continuation doesn't re-read CLAUDE.md, compaction is unreliable at exactly the wrong moment, and the "Document & Clear" pattern consistently outperforms continuation. The spec needs to make session transitions a first-class concern.

**Fix:** Add a session handoff protocol. Each session ends by updating WORKPLAN.md status and writing a brief log entry. Each session starts by reading WORKPLAN.md. Git commit is the persistence boundary. `/clear` between tasks, not continuation.

**5. Gates must be deterministic, not AI-judged.**
The v0.1 `Assert` field says things like "`npm run build` exits 0, project structure matches CONTRACT#interfaces." The first half is deterministic. The second half requires AI judgment — exactly the kind of thing the research shows Claude will sycophantically agree with ("yes, it matches") or silently drop requirements from. The research documents agents deleting tests instead of fixing them, and declaring completion while "most of the functionality is missing."

**Fix:** Assert fields should be executable commands or scripts only. Structural/behavioral assertions belong in test files that get run as part of the gate, not as prose that the AI self-evaluates.

**6. Context Manifests are validated but need guardrails.**
The research strongly validates selective context injection — it's exactly what power users do. But the spec doesn't address what happens when a manifest pulls in too much. A single Contract section could be 500 lines. There's no budget or warning mechanism.

**Fix:** Add a soft token budget per task (~2000 lines of injected context max). If a manifest exceeds this, it's a signal that either the Contract section is too large or the task scope is too broad.

**7. Hooks are more reliable than instructions.**
The research is emphatic: deterministic hooks (auto-lint on file edit, block commit without passing tests) create a quality floor that doesn't depend on instruction-following. The v0.1 spec has no hook layer at all.

**Fix:** Add a hooks layer. Auto-lint after edits. Block commits without test pass. These are the actual enforcement mechanisms; CLAUDE.md rules are just reminders.

**8. The user experience needs attention.**
v0.1 reads like an architecture doc, not a tool you'd enjoy using. The pipeline should feel like a cadence — prep, execute, review, commit, next. The spec should describe the human workflow, not just the file structure.

---

# Forge v0.2 — Spec-to-Ship Pipeline for Claude Code

> A lightweight development pipeline that turns you into the architect and gate reviewer while Claude Code handles execution. You make decisions at defined checkpoints. AI handles everything between them.

---

## Design Principles

1. **One task, one session, one commit.** Sessions are cheap. Context quality is not. Every task is scoped to complete in a single clean session.

2. **Deterministic enforcement over instruction-following.** Hooks and scripts enforce quality. CLAUDE.md reminds. If it matters, it must not depend on Claude reading a rule.

3. **Git is the memory.** Across sessions, git is the only reliable state. Commits are checkpoints. The workplan is the log. Everything else is ephemeral.

4. **Progressive context, not total context.** Each task sees only the Contract sections it needs. The full spec never enters the context window.

5. **You are the architect.** You own the Vision and Contract. The AI derives plans and writes code. You review gates. The automation boundary is the Contract.

---

## The Pipeline

Four layers with decreasing human involvement:

| Layer | Name      | You  | AI  | Artifact             |
| ----- | --------- | ---- | --- | -------------------- |
| 0     | Vision    | 100% | 0%  | `.forge/VISION.md`   |
| 1     | Contract  | 80%  | 20% | `.forge/CONTRACT.md` |
| 2     | Workplan  | 20%  | 80% | `.forge/WORKPLAN.md` |
| 3     | Execution | 5%   | 95% | Committed code       |

Everything above the Contract is _your judgment_. Everything below it is _mechanically derivable_ from what's above.

---

## Layer 0 — Vision

**File:** `.forge/VISION.md`
**Owner:** You. Entirely.

One page. Opinionated. Answers three questions:

1. **What is this?** — One sentence.
2. **Who is it for?** — Target user and their pain.
3. **What are the pillars?** — 3-5 non-negotiable principles that guide every decision downstream.

```markdown
What: A hosted webhook relay that lets indie devs test integrations locally.
Who: Solo devs tired of ngrok and localhost tunneling pain.
Pillars:

- Zero-config first experience
- Works behind corporate firewalls
- Never touches or stores payload data
```

Vision is **immutable during a sprint**. If it changes, you're starting a new project, not pivoting mid-build.

---

## Layer 1 — Contract

**File:** `.forge/CONTRACT.md`
**Owner:** You, with AI assistance for drafting.

The hard constraints and interface definitions. Spec and architecture merged into one source of truth.

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

<!-- Business logic, validation, invariants. What must be true. -->

## Boundaries

<!-- Auth, permissions, rate limits, platform constraints. What's off-limits. -->
```

### Contract Principles

- Describes **what and why**, never how.
- Every statement is **testable** — if you can't write an assertion for it, it's too vague.
- Ambiguities get a `<!-- UNRESOLVED: ... -->` tag — these become `clarify` tasks in the workplan.
- Each section uses **anchored headers** (e.g., `## Data Model`, `### User Entity`) that become addressable references in task manifests.
- **Keep sections focused.** If any single section exceeds ~200 lines, break it into subsections. Large sections defeat the purpose of selective injection.

---

## Layer 2 — Workplan

**File:** `.forge/WORKPLAN.md`
**Owner:** AI-generated, human-reviewed.

A dependency-ordered task list where each task is a self-contained work packet scoped to a single session.

### Task Format

```markdown
## [TASK-001] Setup project scaffold

- **Status:** pending | active | done | blocked
- **Type:** scaffold | feature | clarify | refactor | fix
- **Depends:** none
- **Context:** CONTRACT#data-model, CONTRACT#boundaries
- **Gate:** `npm run build && npm test`
- **Notes:** (empty until execution; used for handoff notes between sessions)
```

> **Changed from v0.1:** `Refs` renamed to `Context` for clarity. `Assert` renamed to `Gate` and restricted to executable commands. `Size` field removed — if a task feels large, decompose it instead of labeling it. `Files` field removed — Claude can determine which files to touch from the Context and task description. `Notes` field added for session continuity.

### Field Definitions

- **Context** — The **context manifest**. Pointers to specific Contract sections that get injected into the session. Only these sections enter the context window. Format: `CONTRACT#section-name` or `CONTRACT#section-name/subsection`.
- **Gate** — A shell command that must exit 0 for the task to pass. This is the acceptance criteria. If you can't express it as a command, write a test file first (`clarify` or `scaffold` task), then reference that test in the gate.
- **Depends** — Task IDs that must be `done` first. Makes the workplan a DAG — you always know the next unblocked task.
- **Notes** — Written by the AI at the end of a session if the task isn't complete, or by you to provide guidance. Read at the start of the next session.

### Task Types

| Type       | When                                         | You do             |
| ---------- | -------------------------------------------- | ------------------ |
| `scaffold` | Project setup, config, boilerplate           | Review gate result |
| `feature`  | Vertical slice of functionality              | Review gate result |
| `clarify`  | Resolve an `<!-- UNRESOLVED -->` in Contract | Make a decision    |
| `refactor` | Improve structure without changing behavior  | Review gate result |
| `fix`      | Broken gate from a previous task             | Review gate result |

### Task Sizing

Every task should be completable in a **single clean Claude Code session** — roughly one focused prompt plus one review/correction cycle. If you find yourself needing 3+ exchanges to complete a task, it's too large. Decompose it.

Rules of thumb:

- One task should touch **one concern** (one API endpoint, one component, one data migration).
- If a task description has the word "and" connecting two distinct pieces of work, split it.
- Scaffold tasks can be larger (boilerplate is low-risk). Feature tasks should be tight.

---

## Context Manifests

Every task carries a `Context` field listing _exactly_ which Contract sections the AI needs. At execution time, only those sections get extracted and injected into the prompt.

**Why this matters:**

- **Token efficiency:** A 2000-line Contract doesn't eat your context window when you only need 80 lines.
- **Focus:** The AI can't hallucinate against sections it never sees.
- **Deterministic:** Manifest resolution is mechanical — parse the refs, extract the sections, build the prompt.

**Budget guideline:** If a task's resolved context exceeds ~200 lines of Contract content, either the Contract sections are too large (break them up) or the task scope is too broad (decompose it).

---

## Planning at Scale

For small projects, `/forge-plan` reads the full Contract in one pass and generates the entire Workplan. For large projects — especially those with multiple overlapping systems — the Contract itself can exceed what fits comfortably in a planning session. A 3000-line Contract consumes ~15% of the context window before Claude writes a single task, and quality degrades for systems planned later in the pass ("lost in the middle").

### Scoped Planning Passes

Instead of one monolithic planning pass, plan one system at a time. Each pass loads only the relevant Contract sections plus shared context.

**The pattern:**

```
Pass 1: Data Model + Boundaries                → scaffold tasks
Pass 2: Combat (Rules + State Machines + Interfaces for combat)  → feature tasks
Pass 3: Inventory (same sections, scoped to inventory)           → feature tasks
Pass 4: Crafting (depends on Inventory tasks from Pass 3)        → feature tasks
```

**How to scope a pass:**

Use `/forge-plan` with a scope indicator. The simplest convention is a `<!-- PLANNING SCOPE -->` comment at the top of CONTRACT.md that you update before each pass:

```markdown
<!-- PLANNING SCOPE: data-model, boundaries -->
```

Or, for contracts large enough to warrant it, split into multiple files:

```
.forge/
├── CONTRACT.md              # shared: Data Model, Boundaries
├── contracts/
│   ├── combat.md            # Rules, State Machines, Interfaces for combat
│   ├── inventory.md         # same structure, scoped to inventory
│   └── crafting.md          # same structure, scoped to crafting
```

When using multiple files, the Context manifest syntax extends naturally: `CONTRACT#data-model`, `combat#rules/damage-calc`, `inventory#interfaces/container-api`.

### Cross-System Dependencies

Systems rarely exist in isolation. When planning Pass 3 (Inventory), the planner needs to know what Pass 2 (Combat) already produced — not to re-read the Combat contract, but to reference the existing tasks as dependencies.

This works automatically: `/forge-plan` preserves `done` and `active` tasks and can see their IDs. When generating new tasks, it wires `Depends` fields to existing task IDs. The Workplan is the integration layer — even if the Contract is split by system, the Workplan is always a single file with a unified DAG.

### When to Split

Not every project needs scoped planning. Rules of thumb:

- **Contract under ~500 lines:** Single pass is fine.
- **Contract 500-1500 lines:** Consider two passes (foundations + features), but a single pass may still work.
- **Contract over 1500 lines:** Scoped passes are strongly recommended. Plan the shared foundations first (Data Model, Boundaries), then each system independently.

The cost of splitting is minimal (an extra `/clear` and `/forge-plan` invocation). The cost of not splitting is degraded task quality for later systems and missed cross-system dependencies.

---

## Layer 3 — Execution

### The Workflow Loop

This is your working rhythm:

```
1. /forge-next          → Claude picks the next task, does the work, runs the gate
2. You review           → Read the code and gate result. Does it match intent?
3. On pass: commit      → One task, one commit. Git is the checkpoint.
4. /clear               → Fresh session. Full reasoning capacity for next task.
5. Repeat.
```

> **Changed from v0.1:** The loop now has an explicit `/clear` step. This is not optional hygiene — it's a structural requirement. The research is unambiguous: continued sessions degrade. Fresh sessions with targeted context outperform extended sessions every time.

### Commands

Forge ships 3 commands in `.claude/commands/`:

> **Changed from v0.1:** Reduced from 5 to 3 commands. `forge-gate` merged into `forge-next` (gate is the end of execution, not a separate step). `forge-init` merged into `forge-plan` (init only runs once and is trivial). Fewer commands = less character budget consumed = lower risk of silent exclusion.

**`/forge-plan`**
Reads VISION.md + CONTRACT.md. On first run, scaffolds `.forge/` if needed and generates WORKPLAN.md. On subsequent runs, regenerates only `pending` tasks — preserves `done` and `active`. You review and edit the output before proceeding.

**`/forge-next`**
The main execution command:

1. Reads WORKPLAN.md, finds the next unblocked `pending` task
2. Resolves the context manifest (extracts referenced Contract sections)
3. Marks task `active`
4. Executes using the appropriate prompt template for the task type
5. Runs the gate command
6. Reports result: pass → marks `done`, suggests commit message; fail → keeps `active`, writes diagnostic to `Notes`

**`/forge-status`**
Prints workplan progress: done/active/pending/blocked counts, next unblocked task, any `clarify` tasks awaiting your input. Lightweight — read-only, no context cost.

### Prompt Templates

Each task type has a prompt template in `.forge/templates/` that structures how Claude approaches the work. Templates include:

- The resolved Contract context (from the manifest)
- Task-type-specific instructions (e.g., "scaffold" emphasizes structure; "feature" emphasizes tests first)
- A reminder to run the gate command before reporting completion
- An instruction to update the `Notes` field if work is incomplete

Templates are short (~30-50 lines). They are injected fresh each session, so they get high attention priority.

---

## Hooks — Deterministic Quality Floor

> **New in v0.2.** The research shows that behavioral rules in CLAUDE.md get ignored as context fills. Hooks execute deterministically regardless of what the AI remembers.

Add these to `.claude/settings.json`:

### Recommended Hooks

**PostToolUse — Auto-lint after file edits** (~200ms, non-blocking)
Runs your linter/formatter after every file write. Catches style violations immediately instead of burning tokens on correction prompts.

**PreToolUse — Block commits without tests passing**
Prevents `git commit` unless `npm test` (or equivalent) exits 0. This is your most important safety rail — it cannot be skipped by instruction drift.

### Why Hooks Over Rules

| Mechanism                   | Reliable?             | Can be ignored? | Token cost                     |
| --------------------------- | --------------------- | --------------- | ------------------------------ |
| CLAUDE.md rule              | Degrades with context | Yes             | Competes for instruction slots |
| Prompt template instruction | High (fresh context)  | Possible        | Per-session only               |
| Hook                        | Always executes       | No              | Zero                           |

Use CLAUDE.md for _awareness_ ("this project uses Forge"). Use hooks for _enforcement_ ("don't commit without tests").

---

## Session Boundary Protocol

> **New in v0.2.** This is the most failure-prone part of any multi-session AI pipeline. The spec now treats session transitions as a first-class concern.

### End of Session

When a task completes (gate passes):

1. `forge-next` marks the task `done` in WORKPLAN.md
2. You commit the code + the updated WORKPLAN.md together
3. You run `/clear`

When a task is incomplete (session ending before gate passes):

1. `forge-next` writes a `Notes` entry on the task: what was done, what remains, any decisions made
2. You commit any working partial progress (or stash it)
3. Task stays `active`
4. You run `/clear`

### Start of Session

Every session starts by reading WORKPLAN.md. The `forge-next` command does this automatically. If resuming an `active` task, the `Notes` field provides continuity without requiring conversation history.

### Why `/clear` Instead of Continuing

- Fresh session = full 200K reasoning capacity
- Context continuation doesn't re-read CLAUDE.md or rules files (documented bug)
- Auto-compaction is unreliable and can loop at high utilization
- The workplan + git commit already preserve everything that matters

---

## CLAUDE.md Integration

Keep this minimal. Every line competes for the ~100 remaining instruction slots.

```markdown
## Forge

- Pipeline: .forge/ (VISION.md, CONTRACT.md, WORKPLAN.md)
- Workflow: /forge-next → review → commit → /clear
- Do not modify CONTRACT.md without asking first
```

Three lines. The slash commands contain the detailed instructions. The hooks enforce the behavioral constraints. CLAUDE.md just establishes awareness.

> **Changed from v0.1:** Reduced from 5 lines of behavioral rules to 3 lines of orientation. Behavioral enforcement moved to hooks and prompt templates where it's more reliable.

---

## Directory Structure

```
project-root/
├── .forge/
│   ├── VISION.md
│   ├── CONTRACT.md
│   ├── WORKPLAN.md
│   └── templates/           # prompt templates per task type
│       ├── scaffold.md
│       ├── feature.md
│       ├── clarify.md
│       ├── refactor.md
│       └── fix.md
├── .claude/
│   ├── commands/
│   │   ├── forge-plan.md
│   │   ├── forge-next.md
│   │   └── forge-status.md
│   └── settings.json        # hooks configuration
├── CLAUDE.md                 # minimal pipeline pointer
└── ... (project files)
```

---

## What Forge Does and Doesn't Do

**Does:**

- Give you a repeatable rhythm: plan → execute → gate → commit → clear
- Keep Claude focused with surgical context injection
- Enforce quality with deterministic hooks, not hopeful instructions
- Treat session boundaries as an engineering concern, not an afterthought
- Use git as the persistence and rollback mechanism

**Doesn't:**

- Use sub-agents (unreliable context inheritance, 7x token cost)
- Hide state (everything is readable markdown)
- Depend on conversation continuity (every session is self-contained)
- Require lock-in (the files are useful even without the commands)
- Auto-commit or push (you are the final gate)

---

## Build Plan

Forge can be built in **3 sessions**, each scoped to complete cleanly.

### Session 1: Pipeline Files

**Goal:** `.forge/` directory with all artifacts, ready to fill for any project.

| Step | Deliverable                                                        |
| ---- | ------------------------------------------------------------------ |
| 1    | VISION.md template with inline guidance                            |
| 2    | CONTRACT.md template with section structure and anchor conventions |
| 3    | WORKPLAN.md template with task format                              |
| 4    | All 5 prompt templates (scaffold, feature, clarify, refactor, fix) |

**Gate:** Templates exist, are well-structured, and contain clear inline documentation.

### Session 2: Commands + Hooks

**Goal:** Working slash commands and hook configuration.

| Step | Deliverable                                                       |
| ---- | ----------------------------------------------------------------- |
| 1    | `forge-plan` — reads Vision + Contract, outputs Workplan          |
| 2    | `forge-next` — finds task, resolves manifest, executes, runs gate |
| 3    | `forge-status` — prints progress summary                          |
| 4    | Hook configuration in settings.json (auto-lint + commit gate)     |
| 5    | CLAUDE.md integration block                                       |

**Gate:** `/forge-plan` generates a workplan from sample input. `/forge-status` reads it correctly.

### Session 3: End-to-End Validation

Take a real project idea, write a Vision + Contract, generate a Workplan, and execute 2-3 tasks through the full loop including `/clear` between tasks. This validates that the session boundary protocol works and surfaces friction.

**Gate:** 2-3 tasks complete the full cycle: `/forge-next` → review → gate pass → commit → `/clear` → next task starts cleanly.

---

_Forge v0.2 — Revised Spec_
