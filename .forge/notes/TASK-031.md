# TASK-031 — Update /forge-init to create STATUS.md stub

## Outcome

`/forge-init` now creates `.forge/STATUS.md` when absent, as a new step 4 placed
immediately after the SPEC.md step. The stub emits all five tables from the
STATUS.md Data Model — Open Questions, Decisions, Risks, Blockers, Observations —
with header rows only and no data rows, and carries the same no-overwrite rule as
every other init artifact. Steps 4 through 11 were renumbered to 5 through 12, and
`.forge/STATUS.md` was added to the completion report's created-files list.

## Decisions

- **Five tables, not four.** `CONTRACT#interfaces/command-forge-init` lists the stub
  as "Open Questions, Decisions, Risks, Blockers"; `CONTRACT#data-model/status.md-data-model`
  shows five, including Observations. Followed the Data Model: the more specific
  document governs the artifact's shape, the task's Notes field asked for five, and
  the gate greps for the Observations header row. Logged the Contract discrepancy as
  OBS-001 rather than editing CONTRACT.md.
- **Placed after SPEC.md rather than at the end.** STATUS.md is a document artifact,
  and the existing step order groups documents (VISION, CONTRACT, SPEC) ahead of
  templates, scripts, and settings. Appending it as a new step 12 would have split
  that grouping.
- **Renumbered rather than using "3b".** The command's steps are referenced by number
  from six other places in the file ("only if step 5 was answered yes", "Proceed to
  step 8"), so a fractional step would have left the cross-references readable but the
  numbering inconsistent. All cross-references were updated with the shift.
- **Added a rationale paragraph binding the Observations table to its consumers.**
  A stub missing that table silently disables `/forge-next`'s foundation-severity hard
  stop — `check-workplan.js` resolves `STATUS#observations` and treats absence as
  normal. The prose says so, so a future edit does not quietly drop the table.

## Deviations

- Contract's `/forge-init` interface bullet understates the stub by one table; the
  implementation follows the Data Model instead. See OBS-001 — a human decides whether
  to amend the Contract bullet.

## Observations logged

- **OBS-001** (normal) — Contract's forge-init interface bullet omits Observations from
  the STATUS.md stub description.
- **OBS-002** (normal) — forge-init step 5 creates 6 templates; the Contract names 7
  unconditional templates, so `checkpoint.md` is never created by init. Pre-existing,
  outside this task's gate.

## Files

- `.claude/commands/forge-init.md` — new step 4, steps 5–12 renumbered, cross-references
  updated, completion list extended
- `.forge/STATUS.md` — two observation rows appended
