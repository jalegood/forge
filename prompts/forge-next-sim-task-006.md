# /forge-next Simulation — TASK-006

> Assembled mechanically: resolved 2 manifest references, filled the scaffold
> template slots. Notes field guidance included. Issues noted at the end.

---

## Pre-Execution

Before you begin work, update `.forge/WORKPLAN.md`: change TASK-006's status from `pending` to `active`.

---

# Scaffold Task

You are executing a **scaffold** task. Your job is to set up project structure, configuration, and boilerplate.

## Task

**ID:** TASK-006
**Description:** Write CLAUDE.md integration block
**Gate:** `grep -q "Pipeline:" CLAUDE.md && grep -q "Workflow:" CLAUDE.md && grep -q "CONTRACT.md" CLAUDE.md && echo "CLAUDE.md integration block valid"`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

### CLAUDE.md Integration Block

Exactly 3 lines in the project's CLAUDE.md:

```markdown
## Forge

- Pipeline: .forge/ (VISION.md, CONTRACT.md, WORKPLAN.md)
- Workflow: /forge-next → review → commit → /clear
- Do not modify CONTRACT.md without asking first
```

### CLAUDE.md Minimalism

- CLAUDE.md contains at most 3 lines of Forge configuration.
- Behavioral enforcement belongs in hooks and prompt templates, not CLAUDE.md.
- Every CLAUDE.md line competes for ~100 remaining instruction slots.

## Task Notes

Only 3 lines. Must not compete for instruction slots.

## Instructions

1. **Read before writing.** Check whether `CLAUDE.md` already exists in the project root. If it does, append the integration block rather than overwriting.
2. **Structure first.** The content is specified verbatim in the Contract — reproduce it exactly.
3. **Follow conventions.** The integration block uses a `## Forge` section header with exactly 3 bullet lines beneath it.
4. **Keep it minimal.** Write exactly what the Contract specifies. No additional Forge instructions, no elaboration, no extra context.
5. **Wire things up.** Ensure the block is placed at the end of any existing CLAUDE.md content, or as the entire file if CLAUDE.md is absent.

## Practical Guidance

- The deliverable is `CLAUDE.md` in the project root (the same directory as `.forge/`).
- The content is given verbatim in the Contract's Integration Block section above. Reproduce it exactly — do not paraphrase, expand, or reorganize.
- For Forge's own build, `CLAUDE.md` does not currently exist. Create it with only the integration block.
- The 3-line count refers to the 3 bullet points. The `## Forge` section header is the container and does not count against the limit.
- Do not add any instructions that belong in hooks (e.g., "always run tests before committing") — that enforcement lives in `settings.json`, not here.

## Completion

When you believe the scaffold is complete:

1. Run the gate command: `grep -q "Pipeline:" CLAUDE.md && grep -q "Workflow:" CLAUDE.md && grep -q "CONTRACT.md" CLAUDE.md && echo "CLAUDE.md integration block valid"`
2. If the gate **passes**: mark TASK-006 as `done` in WORKPLAN.md, report success, and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered

---

## Issues Surfaced During Assembly

### 1. The gate's third check is satisfied by the Pipeline line

The gate runs `grep -q "CONTRACT.md" CLAUDE.md`, which is meant to verify the "Do not modify CONTRACT.md without asking first" line is present. However, the Pipeline line already contains the string `CONTRACT.md` (`.forge/ (VISION.md, CONTRACT.md, WORKPLAN.md)`), so the third check passes regardless of whether the "Do not modify" line is included. A file missing that third bullet would still pass the gate.

Low risk in practice — the Practical Guidance directs the agent to reproduce the content verbatim. But if a future fix task is needed to repair a broken CLAUDE.md, the gate wouldn't catch a partial file. A tighter gate would be `grep -q "Do not modify CONTRACT.md" CLAUDE.md`.

### 2. The content is fully specified — nothing to infer

Both resolved sections together are ~10 lines. The integration block content is given verbatim. This is the lowest-complexity task in the workplan. The main risk is the agent adding extra content rather than subtracting — the minimalism rule guards against this, and it's reinforced in Instruction #4 and Practical Guidance.

### 3. Append-vs-overwrite is implicit for other projects

The integration block is designed to be added to any project's CLAUDE.md. For Forge's own build, CLAUDE.md doesn't exist and will be created fresh. For other projects using Forge, it would be appended. The Contract doesn't specify this behavior explicitly — it's implied by "Exactly 3 lines of Forge configuration" (implying the file may have other content). Instruction #1 makes the append-vs-create logic explicit for the executing agent.
