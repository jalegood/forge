# TASK-093 — Convert STATUS.md Decisions from a table to dated sections

## Outcome

The 44-row Decisions table (single cells over 2,100 characters, ~40KB of padding) is now 44 dated sections, newest first: `### YYYY-MM-DD — Title`, decision prose, `**Why:**`, `**Rejected alternatives:**`. Content preserved verbatim by an escape-aware migration (unescaping the `\|` cells the table format forced). STATUS.md shrank from ~95KB to ~58KB and every entry is now readable in a terminal and reviewable in a diff.

## Decisions

- **Titles derive from each row's bold lead** (the established row convention), falling back to the first ten words; the lead stays in the body so nothing is lost to truncation.
- **The paragraph label is "Rejected alternatives:"**, not the column's "Alternatives rejected" — keeps the load-bearing content while letting the gate assert the table header's absence cleanly.
- **Blast radius followed in the same diff** (the task's "every reference" clause): CONTRACT skeleton + a new normative paragraph (one dated section per decision), Status Lint scope wording (four tables + heading shape), Markdown Table Parsing five→four, both agent-disposition "Decisions row"→"entry" sites, clarify.md's logging step, checkpoint.md's packet item, forge-next.md's packet wording, test-templates.sh's clarify phrases, and both template payloads re-copied.
- Gate repaired pre-activation (recorded per protocol): the authored `! grep "Alternatives rejected"` would have banned the migrated paragraph labels too; narrowed to the literal table-header form. The probe verified the repaired gate still failed pre-work.

## Files

- `.forge/STATUS.md` — the migration
- `.forge/CONTRACT.md` — skeleton, normative paragraph, lint scope, table-count, two entry-wording sites
- `.forge/templates/clarify.md`, `.forge/templates/checkpoint.md` — writer/reader instructions
- `.claude/commands/forge-next.md` — packet wording
- `.forge/tests/test-templates.sh` — clarify phrase set
- `.claude/commands/forge-init.md` — two template payloads re-copied
