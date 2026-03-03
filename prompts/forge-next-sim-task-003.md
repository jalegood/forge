# /forge-next Simulation — TASK-003

> Assembled mechanically: resolved 4 manifest references, filled the feature
> template slots, wrapped with execution protocol. Notes field guidance included.
> Issues noted at the end.

---

## Pre-Execution

Before you begin work, update `.forge/WORKPLAN.md`: change TASK-003's status from `pending` to `active`.

---

# Feature Task

You are executing a **feature** task. Your job is to implement a vertical slice of functionality.

## Task

**ID:** TASK-003
**Description:** Implement /forge-plan command
**Gate:** `test -s .claude/commands/forge-plan.md && grep -q "VISION" .claude/commands/forge-plan.md && grep -q "CONTRACT" .claude/commands/forge-plan.md && grep -q -i "manifest\|completeness\|independently" .claude/commands/forge-plan.md && echo "forge-plan command valid"`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

### Command: `/forge-plan`

- **Reads:** `.forge/VISION.md` (What/Who/Pillars format), `.forge/CONTRACT.md` (sections: Data Model, State Machines, Interfaces, Rules, Boundaries), `.forge/WORKPLAN.md` (if exists)
- **Does:**
  - On first run: scaffolds `.forge/` if needed, writes `.claude/settings.json` if absent (see Hook Configuration), generates WORKPLAN.md
  - On subsequent runs: regenerates only `pending` tasks; preserves `done` and `active` tasks exactly as-is
  - Orders tasks as a dependency DAG — no task runs before its `Depends` entries are all `done`
- **Output task format:** Each task in WORKPLAN.md uses this structure: `## [TASK-XXX] Description` followed by fields — Status (`pending` for new tasks), Type (`scaffold|feature|clarify|refactor|fix|investigate`), Depends (`none` or comma-separated task IDs), Context (manifest references like `CONTRACT#section-name`), Gate (shell command or `manual:` prefix), Notes (empty for new tasks). Task IDs are sequential and unique (TASK-001, TASK-002, ...).
- **Task sizing:** One task per concern. If a description uses "and" connecting two distinct pieces of work, split it. Each task should complete in a single clean session.
- **Manifest generation:** Each task's Context field must list all Contract sections needed to execute independently (see Manifest Completeness rule).
- **Outputs:** Updated `.forge/WORKPLAN.md`
- **Human action required:** Review and edit the workplan before proceeding

### Context Manifest

A context manifest is a list of Contract section references in a task's `Context` field. Format:

- `CONTRACT#section-name` — references a top-level section (e.g., `CONTRACT#data-model`)
- `CONTRACT#section-name/subsection` — references a subsection
- For multi-file contracts: `filename#section-name` (e.g., `combat#rules/damage-calc`)

Resolution: parse the references, extract matching markdown sections (header through next same-level header), concatenate, inject into prompt template at the `{{context}}` slot.

**Budget:** Resolved context must not exceed ~200 lines of Contract content per task. Exceeding this signals the Contract section is too large or the task scope is too broad.

### Workplan Integrity

- WORKPLAN.md is a single file with a unified DAG, even when the Contract is split across multiple files.
- `forge-plan` preserves `done` and `active` tasks on re-run; only regenerates `pending` tasks.
- Task IDs are sequential and unique (TASK-001, TASK-002, ...).

### Manifest Completeness

A task's context manifest must include all Contract sections needed to execute the task independently. The test: could an agent with no prior knowledge of the project produce the correct deliverable using only the resolved context?

When an interface section references concepts defined elsewhere (task statuses, data formats, transition rules), either:

- **Inline** the essential details into the interface section (preferred — keeps manifests lean), or
- **Widen** the manifest to include the referenced sections

`/forge-plan` should generate manifests that pass this test. The human reviewer should verify: read only the resolved context for a task and ask whether it's sufficient to do the work.

## Task Notes

The /forge-plan command prompt must include an explicit instruction about manifest completeness. When generating tasks, the AI planner must verify each manifest passes the completeness test: could an agent with no prior knowledge produce the correct deliverable from the resolved context alone? This is the operational leverage point — if it's not in this prompt, future projects will produce narrow manifests.

## Instructions

1. **Tests first.** Write or update tests that express the expected behavior before implementing.
2. **One concern only.** This task should touch one API endpoint, one component, or one data flow. If you find yourself reaching into unrelated areas, stop — that's a separate task.
3. **Contract is law.** The context above defines what this feature must do. Don't invent requirements beyond what's specified. Don't skip requirements that are specified.
4. **Interfaces matter.** Match the shapes, types, and contracts defined above. Downstream tasks depend on your interfaces being correct.
5. **Keep it tight.** No premature abstractions, no "while I'm here" improvements, no speculative generality.

## Practical Guidance

- The deliverable is a **Claude Code slash command file** at `.claude/commands/forge-plan.md`. This is a markdown prompt file — when a user types `/forge-plan`, Claude loads this file as instructions. See `.claude/commands/forge-status.md` for the established pattern.
- Create the file in the existing `.claude/commands/` directory.
- The command prompt you write will be the instructions Claude follows every time a user runs `/forge-plan` on any project. It must be general-purpose, not specific to Forge's own build.

## Completion

When you believe the feature is complete:

1. Run the gate command: `test -s .claude/commands/forge-plan.md && grep -q "VISION" .claude/commands/forge-plan.md && grep -q "CONTRACT" .claude/commands/forge-plan.md && grep -q -i "manifest\|completeness\|independently" .claude/commands/forge-plan.md && echo "forge-plan command valid"`
2. If the gate **passes**: mark TASK-003 as `done` in WORKPLAN.md, report success, and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered

---

## Issues Surfaced During Assembly

### 1. "Tests first" doesn't apply to prompt files

The feature template's first instruction is "Write or update tests that express the expected behavior before implementing." A slash command is a markdown prompt file — there's nothing to unit test. The agent will need to interpret this as "verify the Contract spec is clear before writing" or skip it. Same issue as TASK-002's scaffold template.

This is the second time this comes up. The template taxonomy (scaffold/feature/clarify/refactor/fix/investigate) was designed for code deliverables. Slash command creation is a recurring task type in Forge's own build that doesn't fit cleanly. Not worth adding a `command` type — but worth noting that the first execution of any template against a non-code deliverable will require the agent to adapt instructions.

### 2. First-run scaffold behavior is underspecified

The interface section says "scaffolds `.forge/` if needed" but doesn't detail what the scaffold contains. The forge-plan command needs to know: create VISION.md, CONTRACT.md, WORKPLAN.md, and `templates/` with all 6 template files. This information exists in the Data Model artifacts table (`CONTRACT#data-model/artifacts`) but that section is not in the manifest.

The agent writing the command can infer the scaffold contents from the artifacts referenced elsewhere in the context (VISION.md, CONTRACT.md, WORKPLAN.md all appear in the interface section). But the templates directory and its 6 files are not mentioned anywhere in the resolved context. An agent with no prior Forge knowledge might scaffold `.forge/` with only the three markdown files and miss the templates entirely.

**Recommendation:** Either widen the manifest to include `CONTRACT#data-model/artifacts`, or add a brief scaffold listing to the `/forge-plan` interface section. The latter is preferred for self-containment.

### 3. This is the highest-leverage deliverable

The `/forge-plan` command generates workplans for every future project. Every design decision baked into this prompt — task sizing heuristics, manifest completeness checks, DAG ordering strategy, gate pattern selection — propagates to all downstream work. The quality bar for this deliverable is higher than for forge-status (which is read-only and low-risk).

The simulation prompt includes the Notes field guidance about manifest completeness, and the gate checks for its presence. But there's no structural way to verify that the command prompt produces _good_ workplans — only that it mentions the right concepts. The real validation happens in TASK-008 (end-to-end manual testing).

### 4. Resolved context is well-sized

4 sections totaling ~40 lines of Contract content. Well within the 200-line budget. The sections cover: what the command does (interface), how manifests work (data model), what constraints apply (workplan integrity), and the completeness requirement (manifest completeness). This is a good example of a manifest that passes the completeness test — except for Issue #2 above.
