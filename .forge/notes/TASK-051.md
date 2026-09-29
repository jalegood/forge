# TASK-051 — Triage the ASSUMED marker backlog into STATUS.md

## Outcome

Every one of the 18 `<!-- ASSUMED: ... -->` markers in CONTRACT.md was triaged into
exactly one of the task's two outcomes: **14 confirmed** (marker removed, reasoning
logged to STATUS.md Decisions) and **4 surfaced** (marker kept, backed by an Open
Questions row). Two of the fourteen were not clean confirmations — the assumption
was materially wrong or imprecise, so the Contract prose was corrected in the same
pass rather than merely de-annotated. No marker was silently deleted.

CONTRACT.md now matches `ASSUMED` on 8 lines: the 4 surviving markers plus 4
passages that describe the marker convention itself (Interfaces/`/forge-plan`,
Rules/Contract-First, Boundaries) and were never inference annotations. STATUS.md
Decisions grew 28 → 33 rows; Open Questions gained Q-007 and had Q-003 amended.

## Decisions

- **Twelve routine confirmations collapsed into one Decisions row, not twelve.**
  Each was validated by shipped implementation or direct inspection — `.forge/VERSION`'s
  two-line format read off the real file, the guards and both stub-detection rules
  shipping with tests, `prose.js` already a hard dependency of four live gates. Twelve
  rows restating the same reasoning would bury the four substantive decisions beneath
  them. The task's own "more than three collapse into one" instinct applied to Decisions.
- **`DESIGN#` resolution wording corrected, not just confirmed.** The marker claimed
  the "same resolution pattern as UX#". Substantively true, but wrong in the one way
  that reaches an implementer: `UX#` strips `Flow:`/`Screen:` label prefixes before
  slugifying and `DESIGN#` has no prefix to strip. The Contract now states plain
  heading-slug matching through the shared resolver.
- **The hook exit-code assumption was factually wrong and is now fixed in the Contract.**
  Boundaries/Hook Configuration said guards "exit nonzero to block". TASK-047 discovered
  while implementing that Claude Code blocks on **exit 2** only and treats every other
  nonzero code as a non-blocking error that lets the tool run anyway. The shipped guards
  exit 2, so the Contract had been documenting a weaker guarantee than the code provides —
  and anyone writing a fourth guard from the Contract alone would have written one that
  fails open. The correction had lived only in the TASK-047 record until now; a record is
  not the spec, and manifests resolve the Contract.
- **Per-artifact UI granularity declined rather than deferred.** The marker at
  Interfaces/`/forge-init` deferred it "to a future task" that never materialised across
  the whole v0.3 cycle, while the re-ask path added later covers the real need. A deferral
  nobody schedules is a decision made by omission; it is now stated.
- **Q-003's claimed validation withdrawn.** The row asserted TASK-048 would validate the
  ~300-line SPEC split threshold by authoring this project's SPEC. That SPEC came in at
  96 lines, so nothing near the threshold was exercised. The question stays open with its
  false validation claim removed — a row that reads as answered stops getting asked.
- **The four surfaced markers are the ones with live doubt, not the ones that were hard.**
  Checkpoint cadence of 5 (two restatements, both under existing Q-002), the SPEC split
  threshold (Q-003), and the payload-fidelity generalisation (new Q-007).

## Deviations

- **The task Notes said 18 markers; `grep -c "ASSUMED"` reported 22.** Not a discrepancy
  in the backlog — 4 of the matches are prose that quotes the `<!-- ASSUMED: reason -->`
  convention while specifying it. The gate counts the mixed population, so its "< 18"
  threshold is measured against 22, not 18. The gate still discriminates correctly here
  (22 → 8 required real triage), so no gate rewrite was warranted.
- **Q-007 is a new Open Question the task did not anticipate.** Triaging the payload
  marker at Rules/Embedded Payload Synchronization surfaced that the rule mandates a
  content-diff test for template payloads while `test-init-scripts.sh` covers script
  payloads only — an unenforced Contract requirement. Surfacing it is the task's own
  prescribed outcome, so it was filed rather than logged as an observation.
- **No Observations rows were appended.** Nothing surfaced that was out of scope and
  would otherwise be lost. One candidate — an apparently malformed Decisions row whose
  cells split into six columns — proved to be correctly escaped `\|` inside code spans
  and a defect in the editing script instead, so there was nothing to record.

## Files

- `.forge/CONTRACT.md` — 14 markers removed; two passages rewritten (Data Model/Context
  Manifest `DESIGN#` bullet, Boundaries/Hook Configuration guard exit code)
- `.forge/STATUS.md` — 5 Decisions rows added, Q-003 amended, Q-007 added
- `.forge/WORKPLAN.md` — TASK-051 status and Notes (via `wp.js`)
- `.forge/notes/TASK-051.md` — this record
