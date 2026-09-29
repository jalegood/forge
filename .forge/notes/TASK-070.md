# TASK-070 — Bring forge-init's embedded template payloads under the script payloads' drift test

## Outcome

All eight template blocks in forge-init.md (seven unconditional plus ux-spec.md) now carry `<!-- forge-init:embed .forge/templates/X.md -->` markers and are content-diffed against their live originals by test-templates.sh, mirroring test-init-scripts.sh. Five embedded bodies had drifted — feature, fix, clarify, refactor, investigate — and were re-copied from the live templates.

## Decisions

- **The diff iterates `.forge/templates/*.md` by glob, not a hardcoded list**, and checks both directions: every live template must have a marker (a template a new project silently never receives — the OBS-002 failure mode), and every marker's payload must match. A template added later is covered the moment the file exists.
- **Drift direction: live authoritative in all five cases.** Each divergence was an older phrasing on the embed side (pre-TASK-031/053/055 wording); no embedded block carried a fix the live file lacked.
- **Embed-side field assertions removed as redundant.** Byte-identical to a passing original means passing; the clarify/investigate init-block checks now run only against the live files.
- **Resolved Q-007** (build the test vs narrow the rule): built. Dated Decisions row added; Q-007 removed from Open Questions.
- **Seeded-drift verification:** perturbed the embedded scaffold block, confirmed the diff fails loudly, restored.

## Files

- `.claude/commands/forge-init.md` — markers + re-copied template bodies
- `.forge/tests/test-templates.sh` — marker-keyed content diff section
- `.forge/STATUS.md` — Q-007 → Decisions
