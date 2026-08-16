# TASK-060 — Create migration script for existing oversized workplans

## Outcome

Added `.forge/scripts/migrate-notes.js`, which walks an existing WORKPLAN.md and, for
every task whose Notes exceed 3 lines, writes `.forge/notes/TASK-XXX.md` in Task Record
Data Model shape and replaces the inline Notes with a mechanically generated one-line
summary plus the record path. Notes of 3 lines or fewer are left byte-identical. The
externalization threshold previously governed only notes written from now on; projects
that predate it — the motivating case being a workplan at 2,177 lines across 67 tasks —
carried the whole debt inline with no way out.

Flags: `--dry-run` (report and write nothing), `--all` (every status, not just `done`),
`--force` (proceed despite a failing pre-flight lint). `.forge/tests/test-migrate-notes.sh`
covers the threshold boundary, record shape, summary generation, idempotency, every
safety property, and a read-only `--dry-run` against the repository's own workplan.

## Decisions

- **Records land whole under `## Outcome`, with `Decisions` and `Deviations` omitted.**
  A mechanical migration cannot tell a decision from a deviation from a plain account of
  what happened, and guessing would put words in the original author's mouth. Each record
  carries a provenance line explaining why it is flat. A `Files:` line is the one thing
  lifted into its own section, because that convention is unambiguous.
- **Summaries are the first sentence of the notes**, falling back to the task description
  when the notes yield none (a note that opens with a bullet list, for instance). Sentence
  detection requires a period followed by whitespace or end-of-value, so `wp.js` and
  `.forge/notes/x.md` are not mistaken for sentence ends — paths are the most common thing
  in these notes. Capped at 160 characters on a word boundary. There is always prose before
  the path: a bare pointer relocates the problem instead of solving it.
- **An existing record is never overwritten.** A task with long notes *and* a record on
  disk is skipped with a reported reason. That combination means a human wrote narrative by
  hand, and clobbering it is the one irreversible mistake this script could make.
- **Idempotency comes from two checks, not one.** Migrated residue is one line, so the
  threshold alone would already stop a second pass; the residue is also matched explicitly
  against `Record: .forge/notes/TASK-XXX.md`, so a summary a human later expanded past three
  lines is still not re-migrated.
- **The post-write lint is conditional on the pre-flight lint having passed.** It exists to
  catch damage this script did. A workplan that did not lint beforehand cannot be held to
  linting afterward, so under `--force` a still-failing lint is reported as a warning rather
  than treated as grounds to revert a migration that was fine.
- **`--force` is not embedded in forge-init.** `migrate-notes.js` is not added to
  forge-init.md's embedded script payloads alongside the other four; that is outside this
  task's gate and is recorded as OBS-005.

## Deviations

- **Only `done` tasks are migrated by default; the task notes said "every task whose notes
  exceed 3 lines."** A pending or active task's Notes are the planner's instructions to the
  agent that will execute it, and a record is read only when a task declares it in its
  Context field (CONTRACT#data-model/task-record-data-model, Addressing). Externalizing
  those notes would therefore move working instructions somewhere `/forge-next` will never
  look — a silent regression, not a cleanup. A blocked task's Notes say what is blocking it
  and what would unblock it, which its resumption needs. `--all` preserves the literal
  requirement for a human who has decided otherwise. The motivating 67-task workplan is
  mostly `done` tasks, so the debt this removes is substantially the same either way.

## Files

- `.forge/scripts/migrate-notes.js` (new)
- `.forge/tests/test-migrate-notes.sh` (new)
- `.forge/STATUS.md` (OBS-005)
- `.forge/WORKPLAN.md` (TASK-060 status and notes)
