# TASK-057 — Update /forge-next to externalize task records on completion

## Outcome

`/forge-next` step 8 ("Gate passes") now branches on an externalization threshold instead of unconditionally appending a `Files:` line. The agent drafts the task narrative, measures it, and either keeps it inline (3 lines or fewer) or writes `.forge/notes/TASK-XXX.md` in the Task Record Data Model shape (Outcome, Decisions, Deviations, Files) and leaves a one-line summary plus path in the workplan `Notes` field. The prose carries the two constraints that make the mechanism work rather than merely relocate the problem: the inline residue must name what the record contains (a bare pointer is called out as unacceptable output), and records must be self-sufficient without git history. A new Constraints bullet states that records are read only when a task declares one via `notes/TASK-XXX#section-name`, never on agent initiative.

## Decisions

- **Assertions went into `.forge/tests/smoke.sh` rather than a new test script.** The gate already invokes `smoke.sh`, and `smoke.sh` is the existing structural harness for command files. A separate script would not have run under the gate.
- **Tests assert the load-bearing prose, not just the path.** The gate's own greps (`notes/TASK`, `summary`) pass against a file that merely mentions the words. The smoke assertions additionally require the 3-line threshold, all four record sections, the "bare pointer" warning, and the git-optional clause — the parts that fail silently if dropped.
- **Both an inline example and an externalized example are shown.** The threshold is a judgment call made per task; two worked examples make the boundary concrete where a rule statement alone would not.
- **Threshold written as "3 lines" rather than "three lines"** to match the Contract's wording in Data Model/Task Record Data Model.

## Deviations

- **The `Files:` line is not duplicated inline when a task externalizes.** Rules/Traceability says `/forge-next` appends a `Files` line to the task's Notes; Data Model/Task Record Data Model says the inline residue is a one-line summary plus path, and gives the record a `## Files` section. For externalized tasks these conflict. Implementation follows the Data Model (files live in the record's `## Files`; inline residue is summary + path) on the grounds that it is the more specific and more recent statement, and that duplicating a long file list inline reproduces the bloat this task exists to remove. Inline-branch tasks keep the `Files:` line exactly as before, so the Traceability rule is unchanged for them. **This tension is unresolved in CONTRACT.md and warrants a clarify task** — Rules/Traceability should be amended to defer to the record for externalized tasks.

## Files

- `.claude/commands/forge-next.md` — step 8 "Gate passes" rewritten with the externalization threshold, worked examples, summary and self-sufficiency requirements; one Constraints bullet added
- `.forge/tests/smoke.sh` — new "record externalization protocol" assertion block
- `.forge/WORKPLAN.md` — TASK-057 status and Notes
