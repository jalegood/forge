# /forge-next Simulation — TASK-004

> Assembled mechanically: resolved 4 manifest references, filled the feature
> template slots, wrapped with execution protocol. Notes field guidance included.
> Issues noted at the end.

---

## Pre-Execution

Before you begin work, update `.forge/WORKPLAN.md`: change TASK-004's status from `pending` to `active`.

---

# Feature Task

You are executing a **feature** task. Your job is to implement a vertical slice of functionality.

## Task

**ID:** TASK-004
**Description:** Implement /forge-next command
**Gate:** `test -s .claude/commands/forge-next.md && grep -q "WORKPLAN" .claude/commands/forge-next.md && grep -q "template" .claude/commands/forge-next.md && grep -q "gate" .claude/commands/forge-next.md && echo "forge-next command valid"`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

### Command: `/forge-next`

- **Reads:** `.forge/WORKPLAN.md`, `.forge/CONTRACT.md` (referenced sections only), `.forge/templates/`
- **Task format:** Parses WORKPLAN.md entries: `## [TASK-XXX] Description` followed by Status, Type, Depends, Context, Gate, Notes fields.
- **Task selection:** If a task is already `active`, resumes it (the `Notes` field provides continuity from the previous session). Otherwise, finds the next unblocked `pending` task, or accepts a specific task ID (e.g., `/forge-next TASK-012`). A task is **unblocked** when its `Depends` field is `none` or all listed task IDs have status `done`. If a specified task has unmet dependencies, warns the human and asks for confirmation.
- **Does:**
  1. Selects the target task (see Task selection above)
  2. Resolves the context manifest: parses the `Context` field references (e.g., `CONTRACT#interfaces/command-forge-status`), extracts matching markdown sections from CONTRACT.md (each section runs from its header through the next same-level header), concatenates them
  3. Marks task `active` in WORKPLAN.md
  4. Loads the prompt template from `.forge/templates/{type}.md` matching the task's Type field
  5. Injects resolved context into the template at `{{context}}`, plus task details into `{{task_id}}`, `{{task_description}}`, `{{gate}}`
  6. Executes the task following the template instructions
  7. Runs the gate command. If the gate starts with `manual:`, presents the description to the human and asks for pass/fail confirmation instead of running a shell command.
  8. On pass: marks `done`, suggests commit message
  9. On fail: keeps `active`, writes diagnostic to `Notes`
- **Outputs:** Executed code changes, gate result, updated WORKPLAN.md

### Task Lifecycle

```
pending ──→ active ──→ done
  │            │
  │            └──→ blocked
  │                   │
  └───────────────────┘ (when blocker resolves)
```

- **pending:** Not yet started. All dependencies must be `done` to become unblocked.
- **active:** Currently being executed in a session. Exactly 0 or 1 tasks may be `active` at any time.
- **done:** Gate passed. Code committed. Terminal state.
- **blocked:** Cannot proceed. Requires a `clarify` task or dependency resolution. Returns to `pending` when unblocked.

Valid transitions: `pending→active`, `active→done`, `active→blocked`, `blocked→pending`.

### Session Lifecycle

```
start ──→ execute ──→ gate ──→ commit ──→ clear
                       │
                       └──→ notes ──→ commit/stash ──→ clear
```

**End of session (gate passes):**

1. `forge-next` marks task `done` in WORKPLAN.md
2. Human commits code + updated WORKPLAN.md together
3. Human runs `/clear`

**End of session (incomplete):**

1. `forge-next` writes a `Notes` entry: what was done, what remains, decisions made
2. Human commits partial progress or stashes
3. Task stays `active`
4. Human runs `/clear`

**Start of session:**

1. `forge-next` reads WORKPLAN.md
2. If resuming an `active` task, `Notes` field provides continuity
3. Fresh context window — full reasoning capacity

### Context Manifest

A context manifest is a list of Contract section references in a task's `Context` field. Format:

- `CONTRACT#section-name` — references a top-level section (e.g., `CONTRACT#data-model`)
- `CONTRACT#section-name/subsection` — references a subsection
- For multi-file contracts: `filename#section-name` (e.g., `combat#rules/damage-calc`)

Resolution: parse the references, extract matching markdown sections (header through next same-level header), concatenate, inject into prompt template at the `{{context}}` slot.

**Budget:** Resolved context must not exceed ~200 lines of Contract content per task. Exceeding this signals the Contract section is too large or the task scope is too broad.

## Task Notes

This is the most complex command. It must: find next unblocked task, resolve context manifest, inject into template, execute, run gate, update status.

## Instructions

1. **Verify the Contract spec is clear before writing.** Read through all four Context sections. Identify any ambiguities or gaps before implementing.
2. **One concern only.** This task should touch one API endpoint, one component, or one data flow. If you find yourself reaching into unrelated areas, stop — that's a separate task.
3. **Contract is law.** The context above defines what this feature must do. Don't invent requirements beyond what's specified. Don't skip requirements that are specified.
4. **Interfaces matter.** Match the shapes, types, and contracts defined above. Downstream tasks depend on your interfaces being correct.
5. **Keep it tight.** No premature abstractions, no "while I'm here" improvements, no speculative generality.

## Practical Guidance

- The deliverable is a **Claude Code slash command file** at `.claude/commands/forge-next.md`. This is a markdown prompt file — when a user types `/forge-next`, Claude loads this file as instructions. See `.claude/commands/forge-status.md` and `.claude/commands/forge-plan.md` for established patterns.
- Create the file in the existing `.claude/commands/` directory.
- The command prompt you write will be the instructions Claude follows every time a user runs `/forge-next` on any project. It must be general-purpose, not specific to Forge's own build.
- This is the most complex of the three commands. It orchestrates: task selection → manifest resolution → template injection → execution → gate → status update. Structure the prompt as a clear step sequence so Claude can follow it reliably.
- The command accepts an optional argument: a specific task ID (e.g., `/forge-next TASK-012`). The prompt should handle both the default case (auto-select next unblocked) and the explicit case.
- The Session Lifecycle's "start of session" block implies that `/forge-next` should also handle resuming an `active` task. If an active task already exists in the workplan, the command should resume it (using its `Notes` for continuity) rather than selecting a new pending task. See Issue #1 below.

## Completion

When you believe the feature is complete:

1. Run the gate command: `test -s .claude/commands/forge-next.md && grep -q "WORKPLAN" .claude/commands/forge-next.md && grep -q "template" .claude/commands/forge-next.md && grep -q "gate" .claude/commands/forge-next.md && echo "forge-next command valid"`
2. If the gate **passes**: mark TASK-004 as `done` in WORKPLAN.md, report success, and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered

---

## Issues Surfaced During Assembly

### 1. "Resume active task" behavior is implied but not explicit in the interface

The `/forge-next` interface section describes task selection as: "Finds the next unblocked `pending` task, or accepts a specific task ID." It only mentions `pending` tasks.

But the Session Lifecycle section says: "If resuming an `active` task, `Notes` field provides continuity." This implies `/forge-next` should detect an existing `active` task and resume it automatically — checking for `active` before looking for `pending`.

The full intended behavior appears to be:

1. If a task is already `active`, resume it (use Notes for continuity)
2. If a specific task ID is provided, select that task (warn if dependencies unmet)
3. Otherwise, find the next unblocked `pending` task

Both sections are in the manifest, so the executing agent has the information to reconcile them. But the interface section should ideally state this explicitly to avoid ambiguity.

**Recommendation:** Amend the interface's Task selection to: "If a task is already `active`, resumes it. Otherwise, finds the next unblocked `pending` task, or accepts a specific task ID." This inlines the resume behavior and eliminates the cross-reference gap. This prompt's Practical Guidance section includes the reconciled behavior as a workaround.

### 2. "Tests first" doesn't apply to prompt files (recurring)

Same issue as TASK-002 and TASK-003. The feature template's first instruction is about writing tests. A slash command is a markdown prompt file — there's nothing to unit test. Instruction #1 has been adapted to "Verify the Contract spec is clear before writing" as with TASK-003.

This is the third occurrence. If Forge's own build had more tasks after this, a `clarify` task to address the template-vs-prompt-deliverable mismatch would be warranted. Since TASK-008 (end-to-end validation) is the next opportunity to observe this, it can be evaluated then.

### 3. This is the core orchestration command

`/forge-next` is the command users run most frequently — every task execution goes through it. Unlike `/forge-plan` (run once or occasionally) and `/forge-status` (read-only), this command has side effects on every run: it modifies WORKPLAN.md, reads and parses CONTRACT.md sections, loads templates, and executes work. The quality bar is high because errors here compound across every future session.

The command must encode manifest resolution clearly — this is the step where references like `CONTRACT#interfaces/command-forge-status` get parsed, matched against CONTRACT.md headers, extracted, and injected. If these instructions are ambiguous, Claude will resolve manifests incorrectly and tasks will execute with wrong or missing context.

### 4. Resolved context is well-sized

4 sections totaling ~75 lines of Contract content. Well within the 200-line budget. The sections cover: what the command does (interface), valid task states and transitions (task lifecycle), session boundary behavior (session lifecycle), and how manifests are resolved (context manifest). Both Issue #1 sections are present in the resolved context, so the agent can reconcile the resume behavior even without the Contract amendment.

### 5. Slash command length concern carries forward

The `/forge-plan` command is ~380 lines. `/forge-next` will likely be comparable or longer given its 9-step orchestration. The same character budget concern from TASK-003 applies. Monitor during TASK-008 end-to-end testing.
