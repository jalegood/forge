# /forge-next Simulation — TASK-002

> This prompt simulates the `/forge-next` command. It was assembled mechanically:
> resolved the context manifest, filled the scaffold template slots, and wrapped
> with the execution protocol.
>
> **v2:** Contract interface sections expanded to be self-contained. Manifest
> Completeness rule added. See "Remaining Issues" at the end for what the
> simulation still surfaces.

---

## Pre-Execution

Before you begin work, update `.forge/WORKPLAN.md`: change TASK-002's status from `pending` to `active`.

---

# Scaffold Task

You are executing a **scaffold** task. Your job is to set up project structure, configuration, and boilerplate.

## Task

**ID:** TASK-002
**Description:** Implement /forge-status command
**Gate:** `test -s .claude/commands/forge-status.md && grep -q "WORKPLAN" .claude/commands/forge-status.md && echo "forge-status command valid"`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

### Command: `/forge-status`

- **Reads:** `.forge/WORKPLAN.md`
- **Task format:** Parses task entries: `## [TASK-XXX] Description` followed by Status, Type, Depends, Context, Gate, Notes fields.
- **Does:**
  - Counts tasks by status: `pending`, `active`, `done`, `blocked`
  - Identifies next unblocked task: first `pending` task whose `Depends` are all `done` or `none`
  - Lists any `clarify`-type tasks that are `pending` or `active` (these need human decisions)
- **Outputs:** Progress summary to the user — task counts by status, next unblocked task ID and description, clarify tasks awaiting input (if any). Read-only — no file modifications, no side effects.

## Instructions

1. **Read before writing.** Check what already exists. Don't overwrite working files.
2. **Structure first.** Create directories, config files, and boilerplate in a logical order.
3. **Follow conventions.** Match any existing project patterns (naming, file organization, code style).
4. **Keep it minimal.** Scaffold only what's needed. Don't add features, utilities, or abstractions that aren't in the task description.
5. **Wire things up.** Ensure new files are properly referenced (imports, config entries, package.json scripts).

## Completion

When you believe the scaffold is complete:

1. Run the gate command: `test -s .claude/commands/forge-status.md && grep -q "WORKPLAN" .claude/commands/forge-status.md && echo "forge-status command valid"`
2. If the gate **passes**: mark TASK-002 as `done` in WORKPLAN.md, report success, and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered

---

## Remaining Issues (post-fix)

Issues #1 (thin context) and its root cause are now resolved. The interface section is self-contained — it includes task format, status values, unblocked definition, and output format. The Manifest Completeness rule prevents recurrence on future projects.

Three structural issues remain. These are properties of the template/command architecture, not bugs to fix:

### 1. Scaffold template instructions don't fit slash commands

The template says "wire things up — ensure imports, config entries, package.json scripts." None of this applies to a Claude Code slash command (a standalone markdown prompt file). The agent will harmlessly ignore these instructions. Not worth adding a task type for — scaffold is a reasonable catch-all for non-code deliverables.

### 2. Template is not self-contained (by design)

The template has no instruction to mark the task `active` before starting or `done` after passing — those are the wrapping command's responsibility (steps 3 and 8 of `/forge-next`). In simulation, the Pre-Execution preamble and patched Completion section fill this gap. In the real implementation, `/forge-next` handles lifecycle transitions and the template handles execution. This two-layer split is intentional but means simulation prompts always need a wrapper.

### 3. Agent must know what a slash command file looks like

The Contract specifies what `/forge-status` does but not what format the deliverable takes. A Claude Code slash command is a markdown file in `.claude/commands/` that gets loaded as a prompt. Claude knows this from training. For non-Claude agents or for projects where the platform isn't obvious, the Contract's Platform Constraints section could describe the command file format. For Forge's own bootstrap this is acceptable — the user and executor both know the platform.
