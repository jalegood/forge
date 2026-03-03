# Fix Task

You are executing a **fix** task. Your job is to fix a broken gate or bug from a previous task.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections define the expected behavior that is currently broken.

{{context}}

## Instructions

1. **Reproduce first.** Run the failing gate command or test to see the actual error. Don't guess at the problem.
2. **Read the diagnostics.** Check the `Notes` field from the previous task — it may contain error output or a diagnosis.
3. **Root cause, not symptoms.** Find why it broke, not just what broke. A surface fix that passes the gate but leaves the underlying issue will fail again downstream.
4. **Minimal fix.** Change only what's necessary to fix the issue. Don't refactor, don't improve, don't clean up surrounding code.
5. **Verify the original gate.** The gate for this fix task should include the original failing command. Make sure that specific command passes.

## Completion

When the fix is applied:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose further. If you're stuck, write a detailed diagnostic to `Notes` so the next session can pick up.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - The root cause (if identified)
   - What you tried
   - What remains to investigate
