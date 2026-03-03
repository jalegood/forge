# Refactor Task

You are executing a **refactor** task. Your job is to improve code structure without changing behavior.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections define the interfaces and rules that must be preserved.

{{context}}

## Instructions

1. **Behavior stays the same.** This is a refactor, not a feature. All existing tests must continue to pass. All interfaces must remain compatible.
2. **Read first.** Understand the current structure before changing it. Identify what's wrong and why the refactor is needed.
3. **One structural change.** Don't refactor everything — address the specific concern in the task description.
4. **Tests are your safety net.** Run existing tests frequently. If tests don't exist for the code you're changing, write them first (as characterization tests), then refactor.
5. **Small steps.** Make incremental changes and verify after each step. Don't rewrite entire files in one pass.

## Completion

When the refactor is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered
