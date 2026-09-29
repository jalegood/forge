# Agent Prompt: Bootstrap Forge with Its Own Pipeline

## Role

You are a senior developer building a development pipeline tool called Forge. You are acting as though the `/forge-plan` command has been invoked — your job is to read the Vision and Contract, then generate a dependency-ordered Workplan.

## Context

Forge is a spec-to-ship pipeline for Claude Code. You are bootstrapping it: building Forge using Forge's own methodology. The spec (`.forge/forge-spec-v0.2.md`) serves as both the blueprint and the contract for this build.

---

## Instructions

### Step 1: Read the spec

Read `forge-spec-v0.2.md` in full. This is your combined Vision + Contract for this project.

### Step 2: Scaffold `.forge/` if it doesn't exist

Create the directory structure defined in the spec:

```
.forge/
├── VISION.md
├── CONTRACT.md
├── WORKPLAN.md
└── templates/
    ├── scaffold.md
    ├── feature.md
    ├── clarify.md
    ├── refactor.md
    └── fix.md
```

### Step 3: Write VISION.md

Derive the Vision from the spec. Forge's vision is already implicit — extract and formalize it into the 3-question format (What / Who / Pillars).

### Step 4: Write CONTRACT.md

Extract the contractual elements from the spec into proper Contract format. Focus on:

- **Data Model:** What artifacts exist (VISION.md, CONTRACT.md, WORKPLAN.md, templates, commands, hooks)? What are their structures and relationships?
- **State Machines:** Task lifecycle (pending → active → done/blocked). Session lifecycle (start → execute → gate → commit → clear).
- **Interfaces:** Slash command signatures — what each command reads, does, and outputs. Context manifest resolution: input format, extraction logic, output format.
- **Rules:** Task sizing constraints. Context budget guidelines. Session boundary protocol. CLAUDE.md minimalism principle.
- **Boundaries:** What Forge doesn't do (no sub-agents, no hidden state, no auto-commit). What requires human approval (Contract modifications, workplan review).

Be precise. Every statement should be testable. Mark anything ambiguous with `<!-- UNRESOLVED: ... -->`.

### Step 5: Write WORKPLAN.md

Generate a dependency-ordered task list following the task format from the spec. Each task must:

- Be completable in a single clean Claude Code session
- Have a `Context` field pointing to specific CONTRACT sections
- Have a `Gate` field with an executable command (not prose)
- Touch one concern only

Think carefully about the dependency graph. The natural build order is:

1. Templates and static files (no dependencies)
2. The simplest command first (`forge-status` — read-only)
3. The planning command (`forge-plan` — reads files, generates output)
4. The execution command (`forge-next` — the complex one, depends on templates and manifest resolution)
5. Hook configuration
6. CLAUDE.md integration block
7. End-to-end validation

### Step 6: Write the prompt templates

Create all 5 templates in `.forge/templates/`. Each template should be 30-50 lines and include:

- A slot for resolved Contract context (`{{context}}`)
- Task-type-specific instructions
- A reminder to run the gate command
- An instruction to update the `Notes` field if work is incomplete

Keep them tight. These get injected fresh each session so they receive high attention priority.

---

## Output

When complete, report:

- Number of tasks generated in the workplan
- Any `<!-- UNRESOLVED -->` items that need human decision
- The first unblocked task ready for `/forge-next`

Do NOT begin executing tasks. This is the planning phase only. The human reviews and approves the workplan before execution begins.

---

## Constraints

- Do not invent requirements beyond what the spec defines
- Do not over-engineer the templates — they should be minimal and clear
- Task gates must be executable shell commands, not prose assertions
- If you're unsure whether something is a hard requirement or a suggestion in the spec, mark it `<!-- UNRESOLVED -->` and move on
