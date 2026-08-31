# TASK-083 — Build obs.js as the sole Observations writer

## Outcome

`obs.js` implements CONTRACT#interfaces/observation-script: `add` (mints the ID against the file at write time, stamps the date, escapes pipes, disposition `open`), `set` (targeted field write refusing invalid lifecycle transitions), `list` (projection with computed age, `--json`, disposition/severity filters, foundation first), and `sweep` (closes `planned:` rows whose task is `done`, reports unlinked `accepted` rows and exact-duplicate text). Every write follows write-lint-revert through check-status.js. First live sweep closed 8 rows.

## Decisions

- **`sweep` reports by default and writes only under `--apply`.** The Contract calls sweep deterministic, not silent: a pass that mutates STATUS.md as a side effect of being *read* would surprise `/forge-next`, which runs it every session. The judgment-free close is still automatic once asked for.
- **`set` rejects invalid transitions before writing**, and the lint catches what the transition table cannot know (a `planned:` link to a nonexistent task) — the write is reverted and the pre-write value stands. Both paths are fixtured.
- **Fixture discipline (TASK-056):** the transition fixture attempts `planned: → accepted`, genuinely absent from the lifecycle; the sweep fixture carries a second `planned:` row whose task is *pending* and asserts it survives, so "closes everything" cannot pass; the escaping fixture writes a literal pipe and reads it back **through parseTable**, since the failure being prevented is a row vanishing from readers rather than a wrong-looking string.
- **The fixture project gets its own copies of obs.js, check-status.js, and lib/** — obs.js walks up to the nearest `.forge`, so running the repo's copy against a fixture would have pointed the lint at the repo's own STATUS.md.

## Live sweep result

8 rows closed: OBS-003, 005, 006, 012, 013, 016, 018 (their planning tasks landed earlier in this run) and OBS-019 (TASK-098). Remaining open: OBS-008 (parked for v0.4 by the human on 2026-08-16) and OBS-017 (a decayed count-gate on a done task; zero forward risk). No `foundation` rows open.

## Files

- `.forge/scripts/obs.js` (new)
- `.forge/tests/test-obs.sh` (new)
- `.forge/tests/smoke.sh` — suite wired
- `.forge/STATUS.md` — 8 rows swept to `closed`
