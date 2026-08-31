# Workplan

## [TASK-001] Create prompt templates for all 5 task types

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#interfaces/prompt-template-interface
- **Gate:** `ls .forge/templates/scaffold.md .forge/templates/feature.md .forge/templates/clarify.md .forge/templates/refactor.md .forge/templates/fix.md && echo "All templates exist"`
- **Notes:**

## [TASK-002] Implement /forge-status command

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-status
- **Gate:** `test -s .claude/commands/forge-status.md && grep -q "WORKPLAN" .claude/commands/forge-status.md && echo "forge-status command valid"`
- **Notes:**

## [TASK-003] Implement /forge-plan command

- **Status:** done
- **Type:** feature
- **Depends:** TASK-001
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#data-model/context-manifest, CONTRACT#rules/workplan-integrity, CONTRACT#rules/manifest-completeness
- **Gate:** `test -s .claude/commands/forge-plan.md && grep -q "VISION" .claude/commands/forge-plan.md && grep -q "CONTRACT" .claude/commands/forge-plan.md && grep -q -i "manifest\|completeness\|independently" .claude/commands/forge-plan.md && echo "forge-plan command valid"`
- **Notes:** The /forge-plan command prompt must include an explicit instruction about manifest completeness. When generating tasks, the AI planner must verify each manifest passes the completeness test: could an agent with no prior knowledge produce the correct deliverable from the resolved context alone? This is the operational leverage point — if it's not in this prompt, future projects will produce narrow manifests. See CONTRACT#rules/manifest-completeness.

## [TASK-004] Implement /forge-next command

- **Status:** done
- **Type:** feature
- **Depends:** TASK-001, TASK-003
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#state-machines/task-lifecycle, CONTRACT#state-machines/session-lifecycle, CONTRACT#data-model/context-manifest
- **Gate:** `test -s .claude/commands/forge-next.md && grep -q "WORKPLAN" .claude/commands/forge-next.md && grep -q "template" .claude/commands/forge-next.md && grep -q "gate" .claude/commands/forge-next.md && echo "forge-next command valid"`
- **Notes:** This is the most complex command. It must: find next unblocked task, resolve context manifest, inject into template, execute, run gate, update status.

## [TASK-005] Configure hooks in settings.json

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#boundaries/hook-configuration
- **Gate:** `node -e "JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'))" && grep -q "PostToolUse\|PreToolUse" .claude/settings.json && echo "Valid JSON with hooks configured"`
- **Notes:** Per resolved CONTRACT decision: auto-create settings.json only if absent. PostToolUse lint hook enabled. PreToolUse commit hook disabled by default (enable after test infra exists). Gate passed.

## [TASK-006] Write CLAUDE.md integration block

- **Status:** done
- **Type:** scaffold
- **Depends:** TASK-002, TASK-003, TASK-004
- **Context:** CONTRACT#interfaces/claudemd-integration-block, CONTRACT#rules/claudemd-minimalism
- **Gate:** `grep -q "Pipeline:" CLAUDE.md && grep -q "Workflow:" CLAUDE.md && grep -q "CONTRACT.md" CLAUDE.md && echo "CLAUDE.md integration block valid"`
- **Notes:** Only 3 lines. Must not compete for instruction slots.

## [TASK-007] Structural smoke test

- **Status:** done
- **Type:** scaffold
- **Depends:** TASK-004, TASK-005, TASK-006
- **Context:** CONTRACT#rules/gate-patterns, CONTRACT#state-machines/task-lifecycle
- **Gate:** `bash .forge/tests/smoke.sh`
- **Notes:** Create a test script that validates the pipeline plumbing: command files exist and reference correct artifacts, WORKPLAN.md task format is parseable (status/type/depends/context/gate fields present), settings.json is valid JSON with hook config, CLAUDE.md has the integration block. This is structural validation only — does not test Claude execution.

## [TASK-008] Update feature.md and fix.md templates with test-first ordering instructions

- **Status:** done
- **Type:** feature
- **Depends:** TASK-007
- **Context:** CONTRACT#rules/test-first-convention, CONTRACT#interfaces/prompt-template-interface
- **Gate:** `grep -q "Write tests" .forge/templates/feature.md && grep -q "Write a failing test" .forge/templates/fix.md && echo "Test-first instructions present"`
- **Notes:**

## [TASK-009] Update /forge-next to append Files manifest on task completion

- **Status:** done
- **Type:** feature
- **Depends:** TASK-007
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#rules/traceability
- **Gate:** `grep -qi "Files\|file manifest\|git diff" .claude/commands/forge-next.md && echo "forge-next file manifest present"`
- **Notes:** Files: .claude/commands/forge-next.md, .forge/WORKPLAN.md

## [TASK-010] Update /forge-plan to enforce test commands in feature and fix gates

- **Status:** done
- **Type:** feature
- **Depends:** TASK-007
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#rules/test-first-convention, CONTRACT#rules/gate-patterns
- **Gate:** `grep -qi "test.*command\|test-first\|feature.*fix" .claude/commands/forge-plan.md && echo "forge-plan test gate enforcement present"`
- **Notes:** Files: .claude/commands/forge-plan.md, .forge/WORKPLAN.md

## [TASK-011] Create /forge-init command

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#boundaries/hook-configuration, CONTRACT#interfaces/claudemd-integration-block, CONTRACT#rules/claudemd-minimalism
- **Gate:** `test -s .claude/commands/forge-init.md && grep -q "VISION.md" .claude/commands/forge-init.md && grep -q "scaffold.md" .claude/commands/forge-init.md && grep -q "forge-plan" .claude/commands/forge-init.md && echo "forge-init command valid"`
- **Notes:** Files: .claude/commands/forge-init.md, .forge/WORKPLAN.md

## [TASK-012] Simplify /forge-plan — remove first-run scaffold step

- **Status:** done
- **Type:** refactor
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#interfaces/command-forge-init
- **Gate:** `bash .forge/tests/smoke.sh && ! grep -q "First-run scaffold" .claude/commands/forge-plan.md && echo "forge-plan scaffold step removed"`
- **Notes:** Files: .claude/commands/forge-plan.md, .forge/WORKPLAN.md

## [TASK-013] Update /forge-next to fail-fast on missing template file

- **Status:** done
- **Type:** scaffold
- **Depends:** TASK-012
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#interfaces/command-forge-init
- **Gate:** `bash .forge/tests/smoke.sh && grep -qi "forge-init\|template.*missing\|missing.*template" .claude/commands/forge-next.md && echo "forge-next fail-fast behavior present"`
- **Notes:** Files: .claude/commands/forge-next.md, .forge/WORKPLAN.md

## [TASK-016] Enhance /forge-plan with pre-task unknown classification and ASSUMED annotation

- **Status:** done
- **Type:** refactor
- **Depends:** TASK-012
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#rules/contract-first, CONTRACT#boundaries/what-requires-human-approval
- **Gate:** `test -s .claude/commands/forge-plan.md && grep -q "ASSUMED" .claude/commands/forge-plan.md && grep -q "Plan-blocking\|plan-blocking" .claude/commands/forge-plan.md && echo "forge-plan unknown classification present"`
- **Notes:** Merged coverage check and unknown-classification into a single pre-task validation step. Added plan-blocking vs implementation-detail classification. Replaced stop-and-ask ceremony with direct CONTRACT.md writes using ASSUMED annotations — Claude Code's native file-write confirmation is the approval gate. Updated clarify task type to reflect its new scope (implementation-detail unknowns only). Files: .claude/commands/forge-plan.md, .forge/CONTRACT.md, .forge/WORKPLAN.md

## [TASK-014] End-to-end validation of forge-init entry point

- **Status:** done
- **Type:** investigate
- **Depends:** TASK-012, TASK-013
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#interfaces/command-forge-plan, CONTRACT#interfaces/command-forge-next, CONTRACT#state-machines/session-lifecycle
- **Gate:** `manual: Simulate a fresh project setup: (1) verify forge-init creates all expected files without overwriting existing ones, (2) verify forge-plan runs lean (no scaffold output), (3) verify forge-next fails fast with a clear message if templates are missing, (4) run one full task through the pipeline to confirm the new entry point works end to end`
- **Notes:** Task completed by user

## [TASK-015] End-to-end manual validation of enhanced workflow

- **Status:** done
- **Type:** investigate
- **Depends:** TASK-008, TASK-009, TASK-010
- **Context:** CONTRACT#state-machines/session-lifecycle, CONTRACT#rules/session-boundary-protocol, CONTRACT#rules/test-first-convention, CONTRACT#rules/traceability
- **Gate:** `manual: Complete 2-3 tasks through the full /forge-next → review → commit → /clear cycle. Verify: (1) feature/fix templates prompt test-first ordering, (2) completed task Notes contain a Files: line, (3) suggested commit message ends with (TASK-XXX)`
- **Notes:** Task completed by user

## [TASK-017] Update /forge-init to create UX artifacts

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#data-model/ux.md-data-model, CONTRACT#rules/gate-patterns
- **Gate:** `test -s .claude/commands/forge-init.md && grep -q "UX.md" .claude/commands/forge-init.md && grep -q "ux-spec.md" .claude/commands/forge-init.md && grep -q "check-ux-spec.js" .claude/commands/forge-init.md && echo "forge-init UX artifact creation present"`
- **Notes:** Files: .claude/commands/forge-init.md, .forge/templates/ux-spec.md, .forge/scripts/check-ux-spec.js, .forge/WORKPLAN.md

## [TASK-018] Update /forge-plan to read UX.md and generate ux-spec task DAG

- **Status:** done
- **Type:** feature
- **Depends:** TASK-017
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#data-model/context-manifest, CONTRACT#interfaces/task-types, CONTRACT#rules/ux-spec-first
- **Gate:** `bash .forge/tests/smoke.sh && grep -qi "UX\.md\|ux-spec" .claude/commands/forge-plan.md && echo "forge-plan UX pipeline support present"`
- **Notes:** Files: .claude/commands/forge-plan.md, .forge/WORKPLAN.md

## [TASK-019] Update /forge-next to resolve UX# context manifest references

- **Status:** done
- **Type:** feature
- **Depends:** TASK-017
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#data-model/context-manifest
- **Gate:** `bash .forge/tests/smoke.sh && grep -qi "UX#\|UX\.md" .claude/commands/forge-next.md && echo "forge-next UX# resolution present"`
- **Notes:** Files: .claude/commands/forge-next.md, .forge/WORKPLAN.md

## [TASK-020] End-to-end validation of UX pipeline

- **Status:** done
- **Type:** investigate
- **Depends:** TASK-017, TASK-018, TASK-019
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#interfaces/command-forge-plan, CONTRACT#interfaces/command-forge-next, CONTRACT#rules/ux-spec-first, CONTRACT#data-model/ux.md-data-model
- **Gate:** `manual: Simulate a full UX pipeline: (1) verify forge-init creates UX.md stub, ux-spec.md template, and check-ux-spec.js without overwriting existing files; (2) fill in a screen spec in UX.md, verify forge-plan generates a ux-spec task with the correct gate command; (3) run forge-next on the ux-spec task and verify it loads ux-spec.md template with UX# context resolved correctly; (4) verify check-ux-spec.js rejects an incomplete spec and passes a complete one`
- **Notes:**

## [TASK-021] Update /forge-init to create DESIGN.md stub

- **Status:** done
- **Type:** scaffold
- **Depends:** TASK-020
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#data-model/design.md-data-model
- **Gate:** `test -s .claude/commands/forge-init.md && grep -q "DESIGN.md" .claude/commands/forge-init.md && echo "forge-init DESIGN.md creation present"`
- **Notes:** Files: .claude/commands/forge-init.md, .forge/WORKPLAN.md

## [TASK-022] Update /forge-plan to include DESIGN# refs in feature manifests

- **Status:** done
- **Type:** feature
- **Depends:** TASK-021
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#data-model/design.md-data-model, CONTRACT#data-model/context-manifest
- **Gate:** `bash .forge/tests/smoke.sh && grep -qi "DESIGN#\|DESIGN\.md" .claude/commands/forge-plan.md && echo "forge-plan DESIGN# support present"`
- **Notes:** Files: .claude/commands/forge-plan.md, .forge/WORKPLAN.md

## [TASK-023] Update /forge-next to resolve DESIGN# context manifest references

- **Status:** done
- **Type:** feature
- **Depends:** TASK-021
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#data-model/context-manifest, CONTRACT#data-model/design.md-data-model
- **Gate:** `bash .forge/tests/smoke.sh && grep -qi "DESIGN#\|DESIGN\.md" .claude/commands/forge-next.md && echo "forge-next DESIGN# resolution present"`
- **Notes:** Files: .claude/commands/forge-next.md, .forge/WORKPLAN.md

## [TASK-042] Make /forge-init interactive: ask about user-facing UI, skip UX/DESIGN artifacts when not needed

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#data-model/artifacts
- **Gate:** `test -s .claude/commands/forge-init.md && grep -qi "user-facing" .claude/commands/forge-init.md && grep -qi "does this project have a user-facing interface" .claude/commands/forge-init.md && grep -q "UX.md" .claude/commands/forge-init.md && grep -q "DESIGN.md" .claude/commands/forge-init.md && grep -qi "skip" .claude/commands/forge-init.md && echo "forge-init interactive UX/DESIGN gating present"`
- **Notes:** Ask before creating any of UX.md, DESIGN.md, check-ux-spec.js. Yes: create all three as before (existing stub content unchanged). No: skip all three, no other file's creation logic changes. Re-running forge-init re-asks; no-overwrite rule handles the rest — answering yes later creates the files then, answering no after they exist is a no-op. Step 9's completion report/next-steps now list UX.md/DESIGN.md conditionally on step 4's answer, with numbering closed up when they're omitted. Gate passed.
  Files: .claude/commands/forge-init.md, .forge/CONTRACT.md, .forge/WORKPLAN.md

## [TASK-050] Extract shared markdown section resolution into one module

- **Status:** done
- **Type:** refactor
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest, CONTRACT#rules/gate-patterns
- **Gate:** `bash .forge/tests/test-check-ux-spec.sh && bash .forge/tests/test-check-workplan.sh && bash .forge/tests/smoke.sh && test -s .forge/scripts/lib/markdown.js && grep -q "lib/markdown" .forge/scripts/check-ux-spec.js && grep -q "lib/markdown" .forge/scripts/check-workplan.js && echo "resolution module extracted"`
- **Notes:** Two divergent implementations of "find a heading, extract through the next same-or-higher heading" exist in this repo today:
  - `check-ux-spec.js` scans with an ad-hoc `/^#{1,4} /m` regex and is **not** fence-aware.
  - `check-workplan.js` uses a level-scoped `parseHeadings` that **skips fenced code blocks**.

  CONTRACT.md alone contains 8 fenced blocks holding heading-like lines, so the two algorithms disagree on real project input. `check-spec.js` (TASK-030) would become the third implementation, and forge-next.md step 3 specifies the same algorithm a fourth time in prose.

  Extract `.forge/scripts/lib/markdown.js` exporting `parseHeadings` (fence-aware) and `resolveRef` (segment navigation, level scoping, slug matching), lifted from check-workplan.js — it is the correct implementation. Rewrite check-ux-spec.js to consume it.

  **This is a behavior change, not a pure refactor.** check-ux-spec.js becomes fence-aware, so a screen spec containing a fenced block with `#`-prefixed lines will now scope correctly where it previously truncated early. Add a fixture to test-check-ux-spec.sh covering exactly that case *before* swapping the implementation, so the change is demonstrated rather than assumed. Preserve check-ux-spec.js's screen-name matching and its column-scoping fix from TASK-043.

  TASK-030 must consume this module rather than adding implementation #3. Justified by the present-tense triplication, not by the factory-model brainstorm that surfaced it ("resolve is the sleeper") — the future abstraction is a bonus, not the rationale.

  Done. `.forge/scripts/lib/markdown.js` exports `parseHeadings` (fence-aware), `normalizeSlug`, `headingCompact`, `sectionRange`, `findHeading`, `resolveSegments`, `createLoader`, `resolveRef` — lifted from check-workplan.js, which now consumes it with no behavior change (all 13 fixtures plus the real-workplan case still pass; error text preserved via `resolveRef`'s cosmetic `displayBase` option).

  `resolveRef`/`resolveSegments` now return the resolved `section` content, not just `{ok}` — check-workplan.js only needed a yes/no, but check-ux-spec.js and check-spec.js (TASK-030) need the text. `findHeading` takes optional `level`/`prefix` constraints, which is how check-ux-spec.js keeps matching `#### Screen: <name>` specifically rather than any heading of that name.

  Behavior change landed as predicted, and was larger than the notes anticipated: check-ux-spec.js had **two** non-fence-aware scans, not one. Fixing only the screen-level scan moved fixture 3 from "Missing section: ##### States" to "States table has no data rows" — the `##### States` sub-section lookup was still matching the quoted heading inside the fence. Both scans now go through the module. Fixture 3 in test-check-ux-spec.sh was added *before* the swap and observed failing against the old implementation.

  Not changed: the mandatory-field checks still use `indexOf` on the screen body, so a fenced block containing `**Emotional intent:**` would satisfy them. Same class of bug, different mechanism (inline text, not heading resolution) — left alone to keep this a single structural change.

  Files: .forge/scripts/lib/markdown.js, .forge/scripts/check-workplan.js, .forge/scripts/check-ux-spec.js, .forge/tests/test-check-ux-spec.sh, .forge/WORKPLAN.md

## [TASK-056] Add notes/ namespace to context manifest resolution

- **Status:** done
- **Type:** feature
- **Depends:** TASK-050
- **Context:** CONTRACT#data-model/task-record-data-model, CONTRACT#data-model/context-manifest, CONTRACT#rules/workplan-access-discipline
- **Gate:** `bash .forge/tests/test-check-workplan.sh && node .forge/scripts/check-workplan.js && grep -q "notes/TASK" .claude/commands/forge-next.md && echo "notes namespace resolvable"`
- **Notes:** Makes `notes/TASK-XXX#section` a first-class manifest reference so a task that needs a prior task's record *declares* it, rather than relying on an agent choosing to go look.

  Smaller than it appears: `check-workplan.js`'s `loadFile` already joins the prefix onto `.forge/`, so `notes/TASK-029` resolves to `.forge/notes/TASK-029.md` by the same path that makes `specs/name#` work. Verify that with a fixture rather than assuming it, then add the form to forge-next's reference-format list and source-file routing. If the resolver moved to `lib/markdown.js` in TASK-050, the fixture belongs there.

  Done, and the prediction held: **zero resolution code changed.** `createLoader` in `lib/markdown.js` joins any prefix onto `.forge/`, so `notes/TASK-029#deviations` already loaded `.forge/notes/TASK-029.md`. The work was proving it and documenting it.

  Three fixtures in test-check-workplan.sh (14-16), backed by a synthetic `.forge/notes/TASK-029.md` in Task Record Data Model shape: a resolving reference, a missing record file, and a missing section inside an existing record. The passing fixture was checked for discrimination — removing the record file turns it into `source file .forge/notes/TASK-029.md not found`, so it passes on real resolution rather than on the reference being skipped.

  `.forge/notes/` does not exist yet; TASK-057 creates the first real record. The namespace is resolvable ahead of anything to resolve, which is the right order — TASK-057 can write records knowing they are already addressable.

  **Scope call:** also added the form to `/forge-plan`'s reference-format list, which the task description did not name. Declaration happens at plan time, so a planner that does not know the form never emits it and the namespace stays inert. Both entries carry the Data Model's "never agent initiative" constraint — forge-next's navigation rules state a record is read only when a task declares it, and forge-plan's entry states declaring is the supported path for cross-task access.

  Files: .forge/tests/test-check-workplan.sh, .claude/commands/forge-next.md, .claude/commands/forge-plan.md, .forge/WORKPLAN.md

## [TASK-057] Update /forge-next to externalize task records on completion

- **Status:** done
- **Type:** feature
- **Depends:** TASK-056
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#data-model/task-record-data-model, CONTRACT#rules/traceability
- **Gate:** `bash .forge/tests/smoke.sh && grep -q "notes/TASK" .claude/commands/forge-next.md && grep -qi "summary" .claude/commands/forge-next.md && echo "record externalization present"`
- **Notes:** Added the externalization threshold to /forge-next step 8 with smoke.sh assertions; one deviation on where the Files list lives, needing a CONTRACT clarify. Record: .forge/notes/TASK-057.md

## [TASK-061] Reconcile Rules/Traceability with record externalization

- **Status:** done
- **Type:** clarify
- **Depends:** TASK-057
- **Context:** CONTRACT#rules/traceability, CONTRACT#data-model/task-record-data-model, CONTRACT#rules/contract-amendment-protocol, notes/TASK-057#deviations
- **Gate:** `bash .forge/tests/smoke.sh && node .forge/scripts/check-workplan.js && awk '/^### Traceability$/{f=1;next} f&&/^### /{exit} f' .forge/CONTRACT.md | grep -qi "externaliz" && test $(grep -c "^| 2026-" .forge/STATUS.md) -gt 21 && echo "traceability record conflict resolved"`
- **Notes:** Confirmed the TASK-057 deviation and amended Traceability, Checkpoint Cadence, and two SPEC criteria; scope reached past CONTRACT into SPEC, and no fix task was needed for any done task. Record: .forge/notes/TASK-061.md

## [TASK-058] Create wp.js deterministic workplan query and mutation script

- **Status:** done
- **Type:** feature
- **Depends:** TASK-050
- **Context:** CONTRACT#rules/workplan-access-discipline, CONTRACT#state-machines/task-lifecycle, CONTRACT#interfaces/command-forge-next
- **Gate:** `bash .forge/tests/test-wp.sh`
- **Notes:** Built wp.js (next/get/status/set/append-notes) plus lib/workplan.js as the one workplan parser, with check-workplan.js refactored onto it; commands are not yet converted (TASK-059). Decisions on mutation safety and lifecycle enforcement, and one deviation expanding /forge-init step 10. Record: .forge/notes/TASK-058.md

## [TASK-059] Convert /forge-next and /forge-status to wp.js projection

- **Status:** done
- **Type:** feature
- **Depends:** TASK-058
- **Context:** CONTRACT#rules/workplan-access-discipline, CONTRACT#interfaces/command-forge-next, CONTRACT#interfaces/command-forge-status
- **Gate:** `bash .forge/tests/smoke.sh && bash .forge/tests/test-wp.sh && grep -q "wp.js" .claude/commands/forge-next.md && grep -q "wp.js" .claude/commands/forge-status.md && echo "projection wired"`
- **Notes:** Both commands converted to wp.js projection; one deviation (forge-status report gained two lines). Observations gap in forge-next is owned by TASK-053, not fixed here. Record: .forge/notes/TASK-059.md

## [TASK-031] Update /forge-init to create STATUS.md stub

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#data-model/status.md-data-model
- **Gate:** `node .forge/scripts/prose.js .claude/commands/forge-init.md "STATUS\.md" && grep -q "| ID | Raised by | Kind | Severity |" .claude/commands/forge-init.md && echo "forge-init STATUS stub present"`
- **Notes:** Added step 4 creating the five-table STATUS.md stub; steps 5-12 renumbered. One deviation: Contract's forge-init bullet lists four tables, Data Model five — followed the Data Model, logged OBS-001/OBS-002. Record: .forge/notes/TASK-031.md

## [TASK-063] Make the foundation-observation hard stop mechanical in wp.js

- **Status:** done
- **Type:** feature
- **Depends:** TASK-058
- **Context:** CONTRACT#rules/unattended-execution, CONTRACT#data-model/status-md-data-model
- **Gate:** `bash .forge/tests/test-wp.sh && bash .forge/tests/smoke.sh && echo "foundation halt mechanical"`
- **Notes:** wp.js next now halts (exit 2) on an open foundation-severity observation, with --force and triage as the two exits; CONTRACT rule 4 amended to make the stop mechanical. Decisions on the resume-active exemption and triage-not-override; three deviations including a forced re-embed of forge-init.md. Record: .forge/notes/TASK-063.md

## [TASK-066] Realign test-prose.sh with forge-init's STATUS.md instruction

- **Status:** done
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#rules/gate-patterns, CONTRACT#rules/test-first-convention, notes/TASK-031#outcome
- **Gate:** `bash .forge/tests/test-prose.sh && bash .forge/tests/smoke.sh && echo "prose assertion realigned"`
- **Notes:** Inverted test-prose.sh live case: asserts prose.js finds the STATUS.md instruction TASK-031 added, with module.exports as the new payload-only negative. smoke.sh green again. Record: .forge/notes/TASK-066.md

## [TASK-053] Update /forge-next to surface and record observations

- **Status:** done
- **Type:** feature
- **Depends:** TASK-031, TASK-066
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#data-model/status.md-data-model, CONTRACT#rules/unattended-execution
- **Gate:** `bash .forge/tests/smoke.sh && node .forge/scripts/check-workplan.js && node .forge/scripts/prose.js .claude/commands/forge-next.md "observation" "foundation" "STATUS\.md" && echo "forge-next observation handling present"`
- **Notes:** Two additions to forge-next, at opposite ends of the command.

  **At session start, before task selection:** read STATUS.md Observations and report every `open` row with `foundation` severity. This is the primary loop closure — `/forge-plan` runs at project start and occasionally after, while `/forge-next` runs every session, so anything routed through planning sits unread for weeks (see STATUS.md Decisions, 2026-08-14).

  **At task completion:** append observation rows produced during execution. Never promote one to a task — only a human does that.

  Also wire the unattended hard stop: a new `foundation`-severity observation halts the loop, with the current task finishing cleanly first (CONTRACT#rules/unattended-execution, hard stop 4).
  Added foundation-observation reporting before task selection (Step 1, closes the resume-active reporting gap wp.js next exempts from its halt) and observation-row recording at task completion (Step 8, one-line rows appended directly to STATUS.md); no deviations.
  Files: .claude/commands/forge-next.md

## [TASK-054] Add the observation step to all prompt templates

- **Status:** done
- **Type:** feature
- **Depends:** TASK-031, TASK-066
- **Context:** CONTRACT#interfaces/prompt-template-interface, CONTRACT#data-model/status.md-data-model
- **Gate:** `bash .forge/tests/smoke.sh && test $(grep -l "Observations" .forge/templates/*.md | wc -l) -ge 7 && echo "templates record observations"`
- **Notes:** Uniform observation step added to all 7 live templates and all 7 copies embedded in /forge-init; new test-templates.sh pins the wording in both, wired into smoke.sh. Two deviations, both on investigate.md orphaned proposal language. Record: .forge/notes/TASK-054.md

## [TASK-055] Wire observations into /forge-status and /forge-plan read paths

- **Status:** done
- **Type:** feature
- **Depends:** TASK-031, TASK-066
- **Context:** CONTRACT#interfaces/command-forge-status, CONTRACT#interfaces/command-forge-plan, CONTRACT#data-model/status.md-data-model
- **Gate:** `bash .forge/tests/smoke.sh && node .forge/scripts/prose.js .claude/commands/forge-status.md "observation" && node .forge/scripts/prose.js .claude/commands/forge-plan.md "observation" "accepted" && echo "observation read paths wired"`
- **Notes:** Added accepted-row observation intake to /forge-plan step 1; /forge-status was already wired and needed no change (verified test-first). smoke.sh now asserts both read paths. Decisions on intake placement and prose.js assertions; one out-of-scope Contract inconsistency logged as OBS-004. Record: .forge/notes/TASK-055.md

## [TASK-060] Create migration script for existing oversized workplans

- **Status:** done
- **Type:** feature
- **Depends:** TASK-057
- **Context:** CONTRACT#data-model/task-record-data-model, CONTRACT#rules/workplan-access-discipline
- **Gate:** `bash .forge/tests/test-migrate-notes.sh`
- **Notes:** Added migrate-notes.js plus its test; externalizes >3-line Notes into records with mechanical summaries. One deviation: done-only by default (--all for the rest), since pending notes are the executing agent's instructions. Record: .forge/notes/TASK-060.md

## [TASK-024] End-to-end validation of DESIGN.md pipeline

- **Status:** done
- **Type:** investigate
- **Depends:** TASK-021, TASK-022, TASK-023, TASK-042
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#interfaces/command-forge-plan, CONTRACT#interfaces/command-forge-next, CONTRACT#data-model/design.md-data-model
- **Gate:** `manual: Simulate a full DESIGN.md pipeline: (0) verify forge-init asks whether the project has a user-facing interface, creates UX.md/DESIGN.md/check-ux-spec.js only when answered yes, and cleanly skips all three when answered no; (1) verify forge-init creates DESIGN.md stub without overwriting existing files (yes branch); (2) populate DESIGN.md with tokens, verify forge-plan includes DESIGN#tokens in a feature task context manifest; (3) verify forge-next resolves DESIGN# references correctly from DESIGN.md; (4) verify a feature task referencing both UX# and DESIGN# receives both resolved contexts`
- **Notes:** Pipeline wiring (steps 0-4) confirmed correct by inspection and by re-running forge-init's actual stub content and forge-plan's own detection commands. Widened into a holistic design/UX review per human request; found 2 confirmed live bugs and 3 quality/clarity smells:
  (A) CONFIRMED BUG: forge-plan's UX/DESIGN coverage checks have no stub-detection guard (unlike VISION.md's `<!-- What this project builds` check) — an untouched UX.md/DESIGN.md stub's literal `[Name]`/`[Component Name]` bracket headings pass every "has a real flow/screen/component" test verbatim (`grep -c "^#### Screen:"` on the raw stub returns 1). Silently generates a ux-spec task for a screen named "[Name]" and injects placeholder-comment noise into manifests.
  (B) CONFIRMED BUG: check-ux-spec.js's vague-term scan runs against the whole States table body, not just the Experience column. Verified false positive: a fully precise, rule-compliant screen with State label "Slow network" was rejected for containing "slow", even though the word appeared outside the column the rule is meant to police.
  (C) SMELL: "generated with a design tool" language in CONTRACT.md/README.md/forge-init.md is vestigial post-Stitch-removal — no mechanism backs it. Human confirmed it "never seemed to matter" in practice. Resolution agreed: simple rewording, not a new tool-integration mechanism.
  (D) SMELL: UX.md's `Global > Style Notes` and DESIGN.md's top-level `Style Notes` share an identical heading for overlapping subject matter, inviting duplication despite the Boundaries rule trying to separate ownership.
  (E) SMELL: neither stub includes a filled worked example demonstrating the numeric-precision convention in situ.
  Human approved lumping follow-ups per efficiency preference — see TASK-043 (bug fixes A+B) and TASK-044 (documentation polish C+D+E) added via /forge-plan.
  Files: .forge/WORKPLAN.md

## [TASK-043] Fix confirmed UX/DESIGN pipeline bugs: stub-detection guard + check-ux-spec.js column scoping

- **Status:** done
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#rules/ux-spec-precision, CONTRACT#rules/ux-spec-first
- **Gate:** `bash .forge/tests/smoke.sh && bash .forge/tests/test-check-ux-spec.sh && grep -qi "stub" .claude/commands/forge-plan.md && echo "UX/DESIGN pipeline bugs fixed"`
- **Notes:** Two confirmed bugs from TASK-024's investigation, lumped per human direction to cut corners:
  (1) forge-plan.md's UX/DESIGN coverage checks must treat literal forge-init stub placeholders (`### Flow: [Name]`, `#### Screen: [Name]`, `### [Component Name]`, a content-free `## Tokens`) as NOT present — see CONTRACT#interfaces/command-forge-plan's "UX coverage" and "DESIGN coverage stub detection" bullets (amended by this planning session). Verified live: `grep -c "^#### Screen:"` on the raw, untouched forge-init stub returns 1. Update forge-plan.md's UX coverage and DESIGN coverage instructions to explicitly exclude these literal placeholder headings before counting flows/screens/components/tokens as real.
  (2) `.forge/scripts/check-ux-spec.js`'s vague-term scan currently matches against the whole States table body (`statesBody`). Scope it to the Experience column only (3rd `|`-delimited cell of each data row) — State and Trigger labels legitimately contain words like "slow"/"fast" without violating CONTRACT#rules/ux-spec-precision, which governs only cells describing time/physics/sensation (i.e., Experience). Verified live: a screen with State `"Slow network"` and a fully precise Experience value (`"opacity 0→1 over 200ms"`) was incorrectly rejected for containing "slow".
  Create `.forge/tests/test-check-ux-spec.sh` (mirrors the pattern used by TASK-025's `test-check-workplan.sh` / TASK-030's `test-check-spec.sh`): one fixture where a non-Experience column contains a "vague" word (must now PASS), one fixture where the Experience column itself contains a vague word like "smooth" (must still FAIL). Gate passed. Also patched forge-init.md's embedded copy of check-ux-spec.js — it's the canonical source new projects bootstrap from, so fixing only the locally-deployed script would have left the bug shipping to every future `/forge-init`.
  Files: .claude/commands/forge-init.md, .claude/commands/forge-plan.md, .forge/CONTRACT.md, .forge/scripts/check-ux-spec.js, .forge/tests/test-check-ux-spec.sh, .forge/WORKPLAN.md

## [TASK-044] Polish DESIGN/UX documentation smells: design-tool wording, duplicate heading name, worked examples

- **Status:** done
- **Type:** refactor
- **Depends:** none
- **Context:** CONTRACT#data-model/artifacts, CONTRACT#data-model/design.md-data-model, CONTRACT#data-model/ux.md-data-model, CONTRACT#interfaces/command-forge-init
- **Gate:** `bash .forge/tests/smoke.sh && ! grep -qiE "generated with a design tool|tool-assisted|generate it with a design tool" .forge/CONTRACT.md README.md .claude/commands/forge-init.md && grep -q "Interaction Notes" .claude/commands/forge-init.md && grep -qE "ease-out|spring\(" .claude/commands/forge-init.md && echo "DESIGN/UX doc polish complete"`
- **Notes:** Three smells from TASK-024, lumped per human direction. Human confirmed a simple rewording is fine for (1) — no new tool-integration mechanism needed.
  (1) Remove the vestigial "design tool" framing left over from the removed Google Stitch integration (see `945243a Remove Google Stitch references from design-system docs` — this finishes that cleanup). Replace with plain "hand-authored" language. Locations: CONTRACT.md Artifacts table DESIGN.md row (also change Owner column from "Human (tool-assisted)" to "Human (100%)"), CONTRACT.md's DESIGN.md Data Model "Authoring" paragraph, README.md's DESIGN.md description line, forge-init.md's step-9 next-steps line. Keep it simple, e.g.: "DESIGN.md is hand-authored markdown — copy in values from whatever source you use."
  (2) Rename UX.md's Global-section `### Style Notes` to `### Interaction Notes` (in forge-init.md's UX.md stub block and CONTRACT.md's UX.md Data Model structure block) to disambiguate from DESIGN.md's top-level `## Style Notes`. Leave DESIGN.md's heading as-is — it's the better fit for "Style Notes." Update the Boundaries prose too if it names the old heading.
  (3) Add ONE filled worked example to each stub in forge-init.md, as an HTML comment beneath the relevant table/section — NOT a live data row, since a real row would falsely satisfy check-ux-spec.js's "has data rows" check for an otherwise-unfilled screen, recreating the exact stub-detection problem TASK-043 fixes. E.g., under UX.md's States table: `<!-- Example: | Loading | Fetch triggered | Skeleton fade-in, opacity 0→1 over 200ms | -->`. Under DESIGN.md's Colors: `<!-- Example: primary: #4F46E5, surface: #FFFFFF, error: #DC2626 -->`.
  Gate passed. All three items done: reworded design-tool language to plain "hand-authored" framing in CONTRACT.md (Artifacts table + Authoring paragraph, Owner changed to "Human (100%)"), README.md, and forge-init.md's next-steps line; renamed UX.md's Global "Style Notes" to "Interaction Notes" in both forge-init.md's stub and CONTRACT.md's mirrored structure block (DESIGN.md's "Style Notes" left as-is); added HTML-comment worked examples to both stubs in forge-init.md and to CONTRACT.md's illustrative structure blocks.
  Files: .claude/commands/forge-init.md, .forge/CONTRACT.md, README.md, .forge/WORKPLAN.md

## [TASK-045] Make ux-spec.md template creation conditional on forge-init's user-facing UI question

- **Status:** done
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-init
- **Gate:** `test -s .claude/commands/forge-init.md && grep -q "ux-spec.md" .claude/commands/forge-init.md && ! (awk '/### 3\. Create/,/### 4\./' .claude/commands/forge-init.md | grep -qi "ux-spec.md") && echo "ux-spec.md creation is now conditional"`
- **Notes:** Follow-up to TASK-042, which made UX.md/DESIGN.md/check-ux-spec.js conditional on the "does this project have a user-facing interface" question but missed `.forge/templates/ux-spec.md` — step 3 (template creation) runs before step 4 (the question) and creates all 7 templates unconditionally, including ux-spec.md. For a "no" answer, this template is permanently dead weight: forge-plan can never generate a `ux-spec` task without UX.md present with real flows. Fixed: moved ux-spec.md's creation out of step 3's unconditional list into step 4's "if yes" branch alongside UX.md/DESIGN.md/check-ux-spec.js; updated step 3's heading (7→6 unconditional templates) and step 9's completion report list; updated CONTRACT.md's interfaces/command-forge-init "Does" bullets to match. Also caught and fixed a weak gate command during verification: the original `grep -qv` check only proved *some* line in range lacked the string, not that the string was absent — replaced with a proper negated match.
  Files: .claude/commands/forge-init.md, .forge/CONTRACT.md, .forge/WORKPLAN.md

## [TASK-025] Create check-workplan.js lint script with test fixtures

- **Status:** done
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-lint, CONTRACT#rules/task-ordering, CONTRACT#state-machines/task-lifecycle, CONTRACT#data-model/context-manifest, CONTRACT#interfaces/task-types
- **Gate:** `bash .forge/tests/test-check-workplan.sh`
- **Notes:** Test script exercises: exit 0 on the current .forge/WORKPLAN.md, exit 1 on fixtures seeding each invariant violation (missing field, unknown dep, forward dep, cycle, two active tasks, unresolvable Context ref, feature gate without test command, checkpoint gate without manual: prefix). Known issue: done tasks TASK-012 and TASK-014 contain self-referencing Depends typos — the script must treat violations in done tasks as warnings, errors only for pending/active tasks, so the current workplan passes. Second known issue: task IDs are NOT monotonic in file order (TASK-016 precedes TASK-014; TASK-042/043/044 precede TASK-024 and the whole TASK-025..041 block; TASK-046 sits between TASK-038 and TASK-039, while the lower-numbered TASK-045 sits far earlier). Invariant 2 must therefore compare **file position**, never ID ordinal — a linter that infers order from the ID number will report false cycles across the existing workplan. See CONTRACT#rules/task-ordering for the full three-ordering model. Invariants 2 and 3 are NOT redundant despite the overlap: invariant 2's file-order check is scoped to pending/active tasks, so a cycle confined to done tasks (exactly TASK-012 and TASK-014's self-deps) escapes it — invariant 3 must run real cycle detection over the whole graph, reporting done-task cycles as warnings. Do not delete invariant 3 as dead code. Baseline for the exit-0 fixture: the current workplan has 46 tasks, zero file-order violations, 4 ID-vs-file-position inversions, and 2 done-task self-deps.

  Implementation notes for future maintainers: (1) `.forge/CONTRACT.md` uses CRLF line endings — the script normalizes `\r\n`→`\n` on every file it reads before regexing, otherwise a bare `\r` at end-of-line breaks non-multiline `$`-anchored matches. (2) CONTRACT.md's illustrative fenced code blocks (e.g. the UX.md/DESIGN.md structure examples under Data Model) contain literal `#`-prefixed lines like `## Global` — `parseHeadings` must skip lines between ``` fences or those get parsed as real headings and prematurely close enclosing sections. (3) Context-manifest matching compacts both the reference segment and the heading text to bare lowercase alnum (strip everything else, no hyphens) before comparing — this tolerates the mixed "x.md-data-model" vs "xmd-integration-block" punctuation conventions already present in this file's own hand-written Context fields; a strict hyphen-preserving slugify (matching /forge-next's documented algorithm literally) breaks on `CLAUDE.md`-derived refs. (4) Invariant 6 (feature/fix gates need a test command) exempts gates whose only file targets are non-code (e.g. `.md` command/template files, `.forge/VERSION`) per CONTRACT#rules/gate-patterns, which designates structural checks as correct for markdown artifacts — without this, TASK-003/004/032/038's legitimate structural gates would false-positive. (5) Severity policy extends the done-task "frozen history" warning-not-error treatment (explicit in the Contract for invariants 2 and 3) to invariants 6 and 7 as well, for consistency; invariants 1, 4, and 5 have no status exemption. None of this required a CONTRACT.md amendment — it's implementation detail resolving ambiguity already visible by reading the whole file, not new policy.

  Files: .forge/scripts/check-workplan.js, .forge/tests/test-check-workplan.sh, .forge/WORKPLAN.md

## [TASK-026] Wire check-workplan.js into /forge-plan and /forge-next

- **Status:** done
- **Type:** feature
- **Depends:** TASK-025
- **Context:** CONTRACT#rules/workplan-lint, CONTRACT#interfaces/command-forge-plan, CONTRACT#interfaces/command-forge-next
- **Gate:** `bash .forge/tests/smoke.sh && grep -q "check-workplan" .claude/commands/forge-plan.md && grep -q "check-workplan" .claude/commands/forge-next.md && echo "workplan lint wired"`
- **Notes:** Both commands run the script after any WORKPLAN.md write; nonzero exit blocks proceeding.
  Wired at each write point: forge-plan.md's step 7 (Write WORKPLAN.md); forge-next.md's step 4 (mark active) and step 8 (mark done/blocked/notes-update, covering all three result branches). Each site instructs re-running the script until it exits 0 before proceeding. Verified live: `node .forge/scripts/check-workplan.js` on the current workplan exits 0 with only the 4 expected done-task frozen-history warnings (TASK-012/TASK-014 self-deps) noted in TASK-025.
  Files: .claude/commands/forge-next.md, .claude/commands/forge-plan.md, .forge/WORKPLAN.md

## [TASK-027] Update /forge-init to create SPEC.md stub

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#data-model/spec-data-model
- **Gate:** `test -s .claude/commands/forge-init.md && grep -q "SPEC.md" .claude/commands/forge-init.md && echo "forge-init SPEC stub present"`
- **Notes:** Stub follows the SPEC Data Model: Overview, Requirements (with REQ-slug/EARS comment guidance), Flows, Non-Goals. Mention the ~300-line split threshold to .forge/specs/ in a stub comment. Inserted as new unconditional step 3 (after CONTRACT.md, before templates), renumbering steps 3-9 to 4-10 and updating all internal step cross-references (the UX-question branch, DESIGN.md/check-ux-spec.js gating, and the completion report's file list and next-steps list). SPEC.md creation is unconditional — not gated on the user-facing-interface question, matching CONTRACT's Interfaces list where SPEC.md sits outside the UX/DESIGN conditional block. Gate passed.
  Files: .claude/commands/forge-init.md, .forge/WORKPLAN.md

## [TASK-028] Update /forge-plan to read SPEC and emit SPEC# refs in manifests

- **Status:** done
- **Type:** feature
- **Depends:** TASK-027
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#data-model/spec-data-model, CONTRACT#data-model/context-manifest, CONTRACT#rules/spec-precedence
- **Gate:** `bash .forge/tests/smoke.sh && grep -q "SPEC#" .claude/commands/forge-plan.md && echo "forge-plan SPEC support present"`
- **Notes:** Completeness test spans SPEC and CONTRACT: behavior without constraint or constraint without behavior fails. Spec conflicts with CONTRACT are logged to STATUS.md Open Questions and become clarify tasks.
  Implemented: step 1 now reads SPEC.md/specs/*.md/STATUS.md when present. Step 2 adds a Spec conflict check — SPEC vs CONTRACT disagreements are logged to STATUS.md Open Questions and produce a `clarify` task (Contract wins per spec-precedence), not silently resolved. Step 4 adds a SPEC coverage block mirroring UX/DESIGN's pattern, including stub detection for the literal `### [REQ-slug] Requirement Name` placeholder from forge-init's SPEC.md stub — an unedited stub counts as zero requirements. Step 5 adds `SPEC#`/`specs/name#` to the reference format list and a SPEC manifest rules block: `feature`/`fix` tasks implementing a requirement must carry both `SPEC#requirements/req-slug` and the constraining `CONTRACT#` sections together (completeness test explicitly extended to span both files, per CONTRACT#rules/spec-precedence). No changes needed to step 6 (gates) — SPEC-referencing tasks are still `feature`/`fix` and use the existing test-suite gate style. Gate passed.
  Files: .claude/commands/forge-plan.md, .forge/WORKPLAN.md

## [TASK-029] Update /forge-next to resolve SPEC# and specs/name# context references

- **Status:** done
- **Type:** feature
- **Depends:** TASK-027
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#data-model/context-manifest, CONTRACT#data-model/spec-data-model
- **Gate:** `bash .forge/tests/smoke.sh && grep -q "SPEC#" .claude/commands/forge-next.md && echo "forge-next SPEC# resolution present"`
- **Notes:** Same slug-matching resolution as CONTRACT#; specs/name# routes to .forge/specs/name.md.
  Added SPEC# and specs/name# to forge-next.md's step 3 reference-format list, source-file routing sentence, and nested-navigation block. One deviation from plain CONTRACT#-style slug matching: SPEC.md's `### [req-slug] Requirement Name` requirement headings match on the bracketed req-slug alone (strip brackets, lowercase, compare directly), ignoring the trailing "Requirement Name" text — a plain slugify of the whole heading (brackets and all) would never equal a bare `SPEC#requirements/req-login` reference. Also added `specs/name#section-name/subsection` (nested form) alongside the top-level form already implied by CONTRACT.md's Context Manifest section. Gate passed.
  Files: .claude/commands/forge-next.md, .forge/WORKPLAN.md

## [TASK-048] Author .forge/SPEC.md for Forge itself

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#data-model/spec-data-model, CONTRACT#rules/spec-precedence, CONTRACT#interfaces/command-forge-spec, CONTRACT#rules/checkpoint-cadence, CONTRACT#rules/unattended-execution
- **Gate:** `test -s .forge/SPEC.md && grep -q "^## Overview" .forge/SPEC.md && grep -q "^## Requirements" .forge/SPEC.md && grep -q "^## Non-Goals" .forge/SPEC.md && grep -q "THE SYSTEM SHALL" .forge/SPEC.md && node .forge/scripts/check-workplan.js && echo "SPEC.md authored"`
- **Notes:** Closes the dogfooding gap: TASK-027/028/029 shipped SPEC# support and this project has no SPEC.md. Hand-authored — `/forge-spec` (TASK-032) does not exist yet, same as STATUS.md was hand-authored ahead of TASK-031.

  **Scope discipline is the whole point.** Forge's CONTRACT is unusually behavior-rich (every command already has Reads/Does/Outputs), so a naive SPEC.md would duplicate it and violate CONTRACT#rules/spec-precedence in the repo that defines that rule. Restrict this file to the acceptance-criteria layer — the v0.3 behavior CONTRACT structurally cannot express as invariants:
  - What makes an intake interview *good* (`/forge-spec`): which questions must be asked before drafting, what disqualifies a draft.
  - What a checkpoint review packet must contain to actually confer confidence on a span.
  - What an unattended span looks like from the operator's seat: what halts it, what it leaves behind, how a course correction is made.

  Write requirements as `### [REQ-slug] Name` with EARS statements (`WHEN <trigger>, THE SYSTEM SHALL <response>`) plus testable acceptance criteria. Reference CONTRACT concepts by name; never redefine a data shape or interface. Populate Non-Goals explicitly — it is the guard against this file growing into a CONTRACT mirror.

  Serves as the real-instance fixture for TASK-030 and validates two open risks early: SPEC/CONTRACT duplication (STATUS.md Risks) and the ~300-line split threshold (STATUS.md Q-003). Context omits `SPEC#` self-references deliberately — check-workplan.js invariant 5 errors on refs to a file that does not exist yet.

  Authored at 121 lines with 6 requirements across the three mandated areas (intake interview quality, checkpoint packet confidence, unattended-span operator experience) — single file, well under the Q-003 split threshold. Three spec-level decisions resolved by human interview before drafting and logged to STATUS.md Decisions (2026-08-14): adaptive intake bar (not strict checklist), mid-span course corrections via direct edits plus a mandatory Decisions row, and checkpoint packets re-running span gates fresh rather than trusting recorded results. No ASSUMED markers added — every judgment call was either interviewed or derived from existing CONTRACT/STATUS content.
  Files: .forge/SPEC.md, .forge/STATUS.md, .forge/WORKPLAN.md

## [TASK-030] Create check-spec.js spec readiness gate script

- **Status:** done
- **Type:** feature
- **Depends:** TASK-027, TASK-048, TASK-050
- **Context:** CONTRACT#data-model/spec-data-model, CONTRACT#rules/gate-patterns
- **Gate:** `bash .forge/tests/test-check-spec.sh`
- **Notes:** Added check-spec.js (spec readiness gate: required sections, acceptance criteria, unresolved-marker threshold, placeholder/TODO check) consuming lib/markdown.js; test suite passes against synthetic fixtures and the real SPEC.md. No deviations. Record: .forge/notes/TASK-030.md

## [TASK-032] Create /forge-spec intake command

- **Status:** done
- **Type:** feature
- **Depends:** TASK-030, TASK-031
- **Context:** CONTRACT#interfaces/command-forge-spec, CONTRACT#data-model/spec-data-model, CONTRACT#data-model/status.md-data-model, SPEC#requirements/req-intake-coverage, SPEC#requirements/req-intake-disqualification
- **Gate:** `test -s .claude/commands/forge-spec.md && grep -q "ASSUMED" .claude/commands/forge-spec.md && grep -q "STATUS.md" .claude/commands/forge-spec.md && grep -q "check-spec" .claude/commands/forge-spec.md && grep -qi "interview" .claude/commands/forge-spec.md && echo "forge-spec command valid"`
- **Notes:** Created /forge-spec: adaptive five-category intake interview before drafting, draft disqualification on unasked plan-blocking unknowns, STATUS.md Q-row handoff, check-spec.js gate. Two decisions worth reading (out-of-manifest SPEC refs; --max-unresolved reconciliation) and one deviation. Record: .forge/notes/TASK-032.md

## [TASK-033] Update /forge-status to surface STATUS.md items

- **Status:** done
- **Type:** feature
- **Depends:** TASK-031, TASK-066
- **Context:** CONTRACT#interfaces/command-forge-status, CONTRACT#data-model/status.md-data-model
- **Gate:** `bash .forge/tests/smoke.sh && grep -q "STATUS.md" .claude/commands/forge-status.md && echo "forge-status STATUS integration present"`
- **Notes:** Deliverable already present from TASK-059; this task added the prose.js assertions that lock it (all mutation-verified) and surfaced open questions by Q-XXX ID. One deviation: IDs go marginally past the Contract Outputs line. Record: .forge/notes/TASK-033.md

## [TASK-034] Update clarify template to log decisions to STATUS.md

- **Status:** done
- **Type:** feature
- **Depends:** TASK-031, TASK-066
- **Context:** CONTRACT#data-model/status.md-data-model, CONTRACT#interfaces/prompt-template-interface
- **Gate:** `bash .forge/tests/smoke.sh && grep -q "STATUS.md" .forge/templates/clarify.md && echo "clarify template logs decisions"`
- **Notes:** On resolution: move the question from Open Questions to Decisions with date, rationale, and rejected alternatives.
  Added the STATUS.md decision-logging step (Decisions row with date/why/rejected alternatives; the Open Questions row is deleted, not copied) to both the live clarify template and the copy embedded in forge-init.md, and pinned all six phrases in test-templates.sh for both copies. The declared gate clause grep -q "STATUS.md" was already satisfied by the observation step, so the load-bearing assertions went into the templates suite that smoke.sh runs.
  Files: .forge/templates/clarify.md, .claude/commands/forge-init.md, .forge/tests/test-templates.sh

## [TASK-065] Restore requirement-slug matching in the shared markdown resolver

- **Status:** done
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest, CONTRACT#rules/workplan-lint, CONTRACT#rules/test-first-convention
- **Gate:** `bash .forge/tests/test-markdown.sh && node .forge/scripts/check-workplan.js && node .forge/scripts/wp.js get TASK-035 | grep -q "SPEC#requirements/req-checkpoint-self-contained" && echo "req-slug refs resolve and are in use"`
- **Notes:** Bracketed-heading rule restored in headingCompact (lib + forge-init embedded copy); new .forge/tests/test-markdown.sh wired into smoke.sh; TASK-035/037 manifests now carry real SPEC#requirements/req-* refs. Decisions on match scope and one out-of-scope finding: test-prose.sh is red at HEAD from TASK-031. Record: .forge/notes/TASK-065.md

## [TASK-064] Resolve the fresh-gates conflict: records store no gate results

- **Status:** done
- **Type:** clarify
- **Depends:** none
- **Context:** SPEC#requirements, CONTRACT#data-model/task-record-data-model
- **Gate:** `grep -q "req-checkpoint-fresh-gates" .forge/STATUS.md && node .forge/scripts/check-workplan.js && echo "fresh-gates conflict resolved"`
- **Notes:** Amended SPEC req-checkpoint-fresh-gates to derive the completion-time baseline from `done` status instead of a stored gate result; Q-005 moved to a dated Decisions row. Three options weighed, one deviation (fix landed in SPEC.md, not CONTRACT.md), one accepted cost (output drift no longer mechanically flagged). Unblocks TASK-035/TASK-037 with no record-model change. Record: .forge/notes/TASK-064.md

## [TASK-035] Create checkpoint.md template and add to /forge-init template set

- **Status:** done
- **Type:** scaffold
- **Depends:** TASK-031, TASK-064, TASK-065
- **Context:** CONTRACT#interfaces/task-types, CONTRACT#interfaces/prompt-template-interface, CONTRACT#rules/checkpoint-cadence, SPEC#requirements/req-checkpoint-self-contained
- **Gate:** `test -s .forge/templates/checkpoint.md && grep -q "checkpoint.md" .claude/commands/forge-init.md && echo "checkpoint template present"`
- **Notes:** Created checkpoint.md (live + forge-init embed, now 7 unconditional templates) instructing span assembly via wp.js get, fresh gate re-runs with regression flagging, STATUS.md excerpts, rollback command, and a hard stop on the pass/fail question. Six decisions incl. the workplan-access choice; one deviation (~55 lines vs the ~30-50 interface guidance). Closes OBS-002. Record: .forge/notes/TASK-035.md

## [TASK-036] Update /forge-plan to insert checkpoint tasks at cadence

- **Status:** done
- **Type:** feature
- **Depends:** TASK-035, TASK-066
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#rules/checkpoint-cadence, CONTRACT#interfaces/task-types
- **Gate:** `bash .forge/tests/smoke.sh && node .forge/scripts/prose.js .claude/commands/forge-plan.md "checkpoint" "cadence" && echo "forge-plan checkpoint cadence present"`
- **Notes:** Added checkpoint cadence generation to /forge-plan step 4 plus the missing checkpoint task type; real assertions went into smoke.sh since the declared gate is two bare words. One deviation (touched the step 5/6 type enumerations). Record: .forge/notes/TASK-036.md

## [TASK-037] Update /forge-next to execute checkpoint tasks with review packet

- **Status:** done
- **Type:** feature
- **Depends:** TASK-035, TASK-064, TASK-066
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#rules/checkpoint-cadence, CONTRACT#rules/unattended-execution, CONTRACT#data-model/status.md-data-model, SPEC#requirements/req-checkpoint-fresh-gates
- **Gate:** `bash .forge/tests/smoke.sh && grep -qi "checkpoint" .claude/commands/forge-next.md && grep -qi "review packet" .claude/commands/forge-next.md && echo "forge-next checkpoint execution present"`
- **Notes:** Specified checkpoint execution in forge-next.md (packet from Depends, fresh gates, blocked-on-fail + Blockers row) and locked it with prose.js assertions in smoke.sh; one deviation reconciling the span source against the Contract Interfaces bullet. Record: .forge/notes/TASK-037.md

## [TASK-038] Create /forge-sync command and .forge/VERSION stamp

- **Status:** done
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-sync, CONTRACT#data-model/artifacts
- **Gate:** `test -s .claude/commands/forge-sync.md && test -s .forge/VERSION && grep -q "VERSION" .claude/commands/forge-sync.md && grep -qi "never" .claude/commands/forge-sync.md && echo "forge-sync command valid"`
- **Notes:** Built /forge-sync (four-state classification via a two-clone three-way diff) and the VERSION stamp; smoke.sh carries the real assertions since the task gate is vacuous. Decisions on baseline degradation and restamp hold-back; two observations raised. Record: .forge/notes/TASK-038.md

## [TASK-047] Create unattended-execution guard hooks and wire into settings.json

- **Status:** done
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#boundaries/hook-configuration, CONTRACT#rules/unattended-execution, CONTRACT#interfaces/command-forge-init, CONTRACT#data-model/artifacts
- **Gate:** `bash .forge/tests/test-guard-hooks.sh`
- **Notes:** Three PreToolUse guards (push/branch/secrets) live, wired into settings.json and provisioned by /forge-init; blocked = exit 2, guards fail closed, default branch read from the repo. Two decisions worth reading (exit-code semantics, narrow secret patterns) and two deviations (OBS-011 duplicates fixed in passing, BRE \+ trap). Record: .forge/notes/TASK-047.md

## [TASK-062] Make /forge-init provision check-workplan.js and lib/markdown.js

- **Status:** done
- **Type:** fix
- **Depends:** TASK-026
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#rules/workplan-lint, CONTRACT#rules/gate-patterns
- **Gate:** `bash .forge/tests/test-init-scripts.sh && bash .forge/tests/smoke.sh && echo "init provisions lint scripts"`
- **Notes:** forge-init now embeds both lint scripts as step 10, guarded by a content-diff drift test; verified end-to-end in a scratch project. One deviation: the CONTRACT bullet was tightened before the task rather than during. Record: .forge/notes/TASK-062.md
  Also provision .forge/scripts/prose.js — added by the TASK-059 follow-up audit, and four gates (TASK-031, 036, 053, 055) now depend on it, so a project without it cannot run them.

## [TASK-051] Triage the ASSUMED marker backlog into STATUS.md

- **Status:** done
- **Type:** clarify
- **Depends:** TASK-066
- **Context:** CONTRACT#data-model/status.md-data-model, CONTRACT#rules/contract-amendment-protocol, CONTRACT#rules/contract-first
- **Gate:** `bash .forge/tests/smoke.sh && node .forge/scripts/check-workplan.js && test $(grep -c "ASSUMED" .forge/CONTRACT.md) -lt 18 && test $(grep -c "^| 2026-" .forge/STATUS.md) -gt 8 && echo "assumption backlog triaged"`
- **Notes:** Triaged all 18 CONTRACT ASSUMED markers: 14 confirmed and removed, 4 surfaced against Q-002/Q-003/new Q-007. Two were corrections, not clean confirms — the guard hook contract said "nonzero blocks" when only exit 2 does, and DESIGN# resolution was misdescribed as identical to UX#. Five Decisions rows logged. Record: .forge/notes/TASK-051.md

## [TASK-067] Reconcile the Contract's Interfaces bullets with STATUS.md's five-table Data Model

- **Status:** done
- **Type:** clarify
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#interfaces/command-forge-plan, CONTRACT#data-model/status.md-data-model, CONTRACT#rules/contract-amendment-protocol
- **Gate:** `node .forge/scripts/check-workplan.js && bash .forge/tests/smoke.sh && grep -q "Blockers, and Observations tables" .forge/CONTRACT.md && grep -qi "blocking open questions, observations" .forge/CONTRACT.md && test $(grep -c "^| 2026-" .forge/STATUS.md) -gt 24 && echo "STATUS table drift reconciled"`
- **Notes:** Closes OBS-001 and OBS-004 — two instances of one defect: an Interfaces bullet describing STATUS.md more narrowly than the Data Model that governs it. Both are Contract-text corrections; no command file or script changes.

  1. **OBS-001** — `Interfaces/Command: /forge-init` says the stub is created "with Open Questions, Decisions, Risks, Blockers tables". The STATUS.md Data Model mandates five tables, `check-workplan.js` resolves `STATUS#observations`, and `/forge-next` halts on open `foundation` rows — so a stub missing Observations silently disables that hard stop. TASK-031 already followed the Data Model and built the five-table stub; only the Contract bullet is wrong. Target wording: "…Decisions, Risks, Blockers, and Observations tables".
  2. **OBS-004** — `Interfaces/Command: /forge-plan`'s Reads line annotates `.forge/STATUS.md` as "(when present — blocking open questions)", though the same interface's Does line requires accepted-Observations intake from that file. Target wording: "(when present — blocking open questions, observations marked accepted)".

  Log one dated Decisions row covering both. The gate's `-gt 24` is the row count at planning time, so it requires the row to exist without demanding a specific total.
  Applied both corrections verbatim from the planned target wording: /forge-init now names five stub tables, /forge-plan Reads now names accepted-observation intake. One dated Decisions row logged; OBS-001 and OBS-004 moved accepted -> closed. Contract-text only, no command or script changes.
  Files: .forge/CONTRACT.md, .forge/STATUS.md

## [TASK-068] Reconcile the Contract's check-spec.js invocation with the script's unresolved-marker threshold

- **Status:** done
- **Type:** clarify
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-spec, CONTRACT#data-model/spec-data-model, CONTRACT#rules/contract-amendment-protocol, notes/TASK-032#decisions
- **Gate:** `bash .forge/tests/test-check-spec.sh && node .forge/scripts/check-workplan.js && grep -q "max-unresolved" .forge/CONTRACT.md && test $(grep -c "^| 2026-" .forge/STATUS.md) -gt 24 && echo "check-spec invocation reconciled"`
- **Notes:** Closes OBS-007. `Interfaces/Command: /forge-spec` mandates two things that contradict each other as written: annotate every unresolvable unknown with `<!-- UNRESOLVED: ... -->`, and run `node .forge/scripts/check-spec.js <file>`. The script treats any unresolved marker as a failure unless `--max-unresolved N` is passed, so following the Contract literally produces a spec that cannot pass its own gate. The reconciliation exists only in `forge-spec.md` prose (`--max-unresolved 2`) — a command file, and therefore not manifest-addressable, which is the same failure mode as the requirement-heading rule fixed on 2026-08-16.

  Decide which side is authoritative and amend the Contract to say so: either the invocation carries a threshold (state the default and where it comes from), or the script's default changes and `forge-spec.md`'s flag use is dropped. `notes/TASK-032#decisions` records why the flag was introduced — read it before choosing. Log a dated Decisions row with the rejected alternative.
  Resolved via Option A: CONTRACT#interfaces/command-forge-spec now invokes the gate as `check-spec.js <file> --max-unresolved N`, script default stays 0, N declares the markers deliberately carried (each Q-row backed) and is reported to the human. Closes OBS-007; forge-spec.md needed no change. Raised OBS-018 (foundation) — five workplan gates count dated STATUS.md rows against absolute thresholds now all below the actual count.
  Files: .forge/CONTRACT.md, .forge/STATUS.md

## [TASK-094] Isolate FORGE_UNATTENDED in the guard hook test

- **Status:** done
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#boundaries/hook-configuration, CONTRACT#rules/test-first-convention, CONTRACT#rules/gate-patterns
- **Gate:** `FORGE_UNATTENDED=1 bash .forge/tests/test-guard-hooks.sh && env -u FORGE_UNATTENDED bash .forge/tests/test-guard-hooks.sh && bash .forge/tests/smoke.sh && grep -q "env -u FORGE_UNATTENDED" .forge/tests/test-guard-hooks.sh && echo "guard tests control their environment"`
- **Notes:** Found 2026-08-30 at headless-run start: the suite went red the moment the session environment armed `FORGE_UNATTENDED=1`, because `test-guard-hooks.sh`'s interactive-case assertions rely on the flag being *absent from the inherited environment* rather than unsetting it. A guard test that inherits its arming state from whoever runs it fails in exactly the unattended context the guards exist for. Fix: run every interactive-case invocation under `env -u FORGE_UNATTENDED`; armed cases keep setting the flag explicitly per case. Gate discrimination: the first clause fails today (with the flag set, the inert-guard assertion reports a false block) and the grep clause fails today (`env -u` appears nowhere in the file).
  Fixed: interactive-case guard-branch invocations (default-branch inert case, work-branch case) now run under env -u FORGE_UNATTENDED; armed cases already set the flag per case. No deviations.
  Files: .forge/tests/test-guard-hooks.sh

## [TASK-069] Make /forge-init provision check-spec.js, prose.js, and migrate-notes.js

- **Status:** done
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#data-model/artifacts, CONTRACT#rules/embedded-payload-synchronization, notes/TASK-062#decisions
- **Gate:** `bash .forge/tests/test-init-scripts.sh && bash .forge/tests/smoke.sh && node .forge/scripts/check-workplan.js && echo "init provisions the three missing gate scripts"`
- **Notes:** Closes OBS-005, which is wider than the row states. `forge-init.md` embeds four script payloads — `lib/markdown.js`, `lib/workplan.js`, `check-workplan.js`, `wp.js` — and omits three:

  - **`check-spec.js`** is the most serious: the Contract has always required `/forge-init` to create it, and `forge-init.md` mentions it zero times. A scaffolded project cannot run `/forge-spec`'s gate at all. This is a live Contract violation, not a gap.
  - **`prose.js`** — four existing gates (TASK-031, 036, 053, 055) invoke it. TASK-062's record claims it was provisioned; it was not. Verify that claim against the file rather than trusting the note.
  - **`migrate-notes.js`** — the original OBS-005 subject. Inert until a project's workplan predates the externalization threshold, which is exactly when it cannot be fetched.

  The Contract was amended by this planning pass to name all seven scripts in one bullet and to add Artifacts rows for the four that had none. Follow `notes/TASK-062#decisions` for the established pattern: copy each payload whole, precede it with `<!-- forge-init:embed <path> -->`, and extend `test-init-scripts.sh` so the content diff covers the new blocks. Also fix `forge-init.md`'s created-files summary, which currently lists `lib/markdown.js` and `check-workplan.js` twice.

  Scope boundary: do not restructure how `forge-init.md` distributes scripts. It is already ~1,900 lines and mostly fenced payload, and that is a real design smell — but replacing verbatim embedding is a v0.4 distribution question that overlaps TASK-041 (plugin packaging), not this repair.
  Embedded check-spec.js, prose.js, migrate-notes.js payloads with markers in step 11; test-init-scripts.sh now diffs all ten payloads. Deviation: the claimed duplicate summary entries no longer exist (fixed with OBS-011), so only the three new entries were added.
  Files: .claude/commands/forge-init.md, .forge/tests/test-init-scripts.sh

## [TASK-070] Bring forge-init's embedded template payloads under the script payloads' drift test

- **Status:** done
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#rules/embedded-payload-synchronization, CONTRACT#interfaces/command-forge-init, CONTRACT#interfaces/prompt-template-interface, notes/TASK-054#deviations
- **Gate:** `bash .forge/tests/test-templates.sh && bash .forge/tests/smoke.sh && grep -q "forge-init:embed .forge/templates/feature.md" .claude/commands/forge-init.md && echo "template payloads content-diffed"`
- **Notes:** Markers on all 8 template blocks, marker-keyed glob-driven content diff in test-templates.sh, five stale bodies re-copied (live authoritative); resolves Q-007. Record: .forge/notes/TASK-070.md

## [TASK-071] Restore SPEC traceability on TASK-032's context manifest

- **Status:** done
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#rules/spec-precedence, SPEC#requirements/req-intake-coverage, SPEC#requirements/req-intake-disqualification, notes/TASK-032#outcome
- **Gate:** `node .forge/scripts/check-workplan.js && node .forge/scripts/wp.js get TASK-032 | grep -q "SPEC#requirements/req-intake-coverage" && node .forge/scripts/wp.js get TASK-032 | grep -q "SPEC#requirements/req-intake-disqualification" && bash .forge/tests/smoke.sh && echo "TASK-032 manifest reconciled"`
- **Notes:** Closes OBS-006. TASK-032's Context carries only `CONTRACT#` refs though `SPEC#requirements/req-intake-coverage` and `req-intake-disqualification` govern `/forge-spec` directly — the SPEC manifest rule `/forge-plan` mandates was not applied. Add both refs to TASK-032's Context field.

  **The deliverable is fine; only the record is wrong.** Verified during planning: `forge-spec.md` already states the "specific passage, not a general impression" bar, the do-not-re-ask rule, draft withholding, the implementation-detail exemption, and it names both req slugs. So this is a traceability repair, not a behavioral fix — SPEC-to-task traceability is the entire reason `SPEC#` refs exist (STATUS.md Decisions, 2026-08-16). One thing to confirm rather than assume: req-intake-disqualification requires that a disqualified draft's unasked questions are asked *before a second draft*, and the resume-the-interview step is the one criterion planning could not find asserted in the command's prose. If it is genuinely absent, add it — that is in scope here.

  Amending a `done` task's manifest is deliberate and narrow. `/forge-plan` preserves done tasks on regeneration; it does not forbid a corrective task from editing one, and Rules/Contract Amendment Protocol step 3 contemplates exactly this reconciliation. Use `wp.js` for the write so the file stays byte-identical elsewhere and is re-linted automatically.

  **Considered and rejected:** a `check-workplan.js` invariant warning when a `feature`/`fix` task carries no `SPEC#` ref. Forge's SPEC.md covers only intake, checkpoints, and unattended spans, so most tasks legitimately implement no requirement — the check would warn on roughly six current pending tasks and train readers to ignore warnings. The requirement-coverage lint in Q-006 remains the right home for this, once Q-003 settles whether per-feature specs give tasks a feature identity.
  Added both SPEC refs to TASK-032 Context via wp.js. Verified the resume-the-interview criterion already exists at forge-spec.md:129 (go back to step 3, ask, draft again) — no command change needed.
  Files: .forge/WORKPLAN.md

## [TASK-073] Add the gate discrimination requirement to /forge-plan's gate authoring

- **Status:** done
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#rules/gate-discrimination, CONTRACT#interfaces/command-forge-plan, CONTRACT#rules/gate-patterns, CONTRACT#rules/test-first-convention, CONTRACT#rules/workplan-lint
- **Gate:** `bash .forge/tests/smoke.sh && node .forge/scripts/prose.js .claude/commands/forge-plan.md "vacuous" "pre-work" "append-only" && node .forge/scripts/check-workplan.js && echo "forge-plan gate discrimination present"`
- **Notes:** First of three tasks closing OBS-013, and the one the observation names directly: "/forge-plan's gate-authoring rule that produces them is still unchanged."

  Step 6 (Generate gates) currently teaches gate *strategy* by deliverable type and enforces one property — that `feature`/`fix` gates invoke a test command. It never asks whether the gate can fail. Add the discrimination requirement per CONTRACT#rules/gate-discrimination: a gate asserts the change, not the topic. The concrete substitution to teach is `grep -qi "<topic>" <file>` → `node .forge/scripts/prose.js <file> "<phrase this task adds>"`, which is what four of the recorded instances (OBS-008, OBS-010, OBS-013, TASK-034) each needed.

  **Teach both vacuous shapes, not just the topic-grep one** (scope added 2026-08-19 on OBS-018 triage; see Decisions). The count shape — `test $(grep -c "<pattern>" <file>) -gt N` against an append-only artifact — is the second, and it fails differently: it can discriminate on the day it is authored and decay into vacuity as the file grows, so it is not caught by asking "is this word already present?". OBS-017 and OBS-018 are its two recorded instances. The substitution to teach is the absolute count → a phrase assertion naming the task's own row (`grep -q "<phrase this task's row contains>" .forge/STATUS.md`), with the carve-out that a count is fine where the quantity moves in the direction the task drives it and would fail if the task did nothing. Contract obligation 1 now states both shapes; this task carries them into `/forge-plan`'s step 6.

  Carry the test-first interaction explicitly — it is the part most likely to be dropped. A bare `bash .forge/tests/smoke.sh` satisfies invariant 6 and passes before the work by construction, so the gate must additionally name the new assertion the task creates. Without this, applying the new rule naively would put `/forge-plan` in conflict with Rules/Test-First Convention on every `feature` task.

  The self-check at the end of step 6 ("does this gate command invoke a test suite?") is the right place to hang the second question ("could this gate fail right now?"), rather than adding a parallel structure.

  This task's own gate follows the rule it installs: `vacuous` and `pre-work` appear nowhere in `forge-plan.md` today — verified at planning time — so the gate fails before the work and cannot pass on a pre-existing mention.
  Added the discrimination block to step 6: both vacuous shapes (topic on-arrival, count decay) with substitutions, the manual: precedence note, the test-first interaction, and the pre-work-failure question hung on the existing self-check with a pointer to the wp.js probe.
  Files: .claude/commands/forge-plan.md

## [TASK-074] Make the gate-discrimination probe mechanical in wp.js

- **Status:** done
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#rules/gate-discrimination, CONTRACT#rules/workplan-access-discipline, CONTRACT#state-machines/task-lifecycle, CONTRACT#rules/gate-patterns, notes/TASK-063#decisions
- **Gate:** `bash .forge/tests/test-wp.sh && bash .forge/tests/smoke.sh && bash .forge/tests/test-init-scripts.sh && grep -q "vacuous" .forge/tests/test-wp.sh && echo "gate probe mechanical"`
- **Notes:** Probe live at pending→active (exit 4), foundation halt renumbered to exit 3, bash -c runner with loud spawn failure; fixtures discriminate. Record: .forge/notes/TASK-074.md

## [TASK-075] Update /forge-next to handle a refused gate-discrimination probe

- **Status:** done
- **Type:** feature
- **Depends:** TASK-074
- **Context:** CONTRACT#rules/gate-discrimination, CONTRACT#interfaces/command-forge-next, CONTRACT#data-model/status.md-data-model, CONTRACT#rules/workplan-access-discipline
- **Gate:** `bash .forge/tests/smoke.sh && node .forge/scripts/prose.js .claude/commands/forge-next.md "vacuous" "gate-discrimination probe" && node .forge/scripts/check-workplan.js && echo "forge-next probe handling present"`
- **Notes:** The command-side half of TASK-074. `wp.js` refuses the transition; `/forge-next` step 3 has to know what the refusal means and what to do, or the session halts on an error message with no route forward.

  Two routes, and distinguishing them is the whole deliverable — they look identical from the exit code:

  1. **The gate is wrong.** Repair it via `wp.js set TASK-XXX gate '<discriminating gate>'` while the task is still `pending`, then retry the transition. The repaired gate lands in this task's diff, which is what makes the fix reviewable at the checkpoint rather than invisible.
  2. **The gate is right and the work is already done** — a prior task absorbed this task's scope. This is the OBS-008 condition. It is a scope finding, not a gate defect: report it to the human and do not silently mark the task `done`, which is what happened to TASK-033.

  Never pass `--force`; it is the human's override (CONTRACT#rules/gate-discrimination, obligation 2).

  Assertions go in `smoke.sh` via `prose.js`, following TASK-036/TASK-037's precedent — both found their declared workplan gates too weak to carry the real check and put the load-bearing assertions in the suite. Here the declared gate is already phrase-specific, so the suite assertions are reinforcement rather than rescue.

  Scope boundary: this task does not add an Observations row for the OBS-008 condition automatically. `/forge-next` already appends observation rows at completion (TASK-053) and the existing channel covers it; a second, probe-specific writer would be a parallel path to the same table.
  Exit-4 handling added to forge-next.md step 4: the two routes (repair the gate in this diff; report absorbed scope, the OBS-008 condition), never --force. Reinforcement assertions added to smoke.sh via prose.js.
  Files: .claude/commands/forge-next.md, .forge/tests/smoke.sh

## [TASK-076] Repair three gates that cannot fail

- **Status:** pending
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#rules/gate-discrimination, CONTRACT#rules/gate-patterns, CONTRACT#interfaces/command-forge-plan, CONTRACT#data-model/spec-data-model, CONTRACT#rules/test-first-convention
- **Gate:** `bash .forge/tests/test-check-spec.sh && bash .forge/tests/smoke.sh && node .forge/scripts/prose.js .claude/commands/forge-plan.md "Describe what this project builds" && ! grep -q "awk '\$1 >=" .claude/commands/forge-plan.md .forge/CONTRACT.md && grep -q "Fixture 5c" .forge/tests/test-check-spec.sh && echo "vacuous gates repaired"`
- **Notes:** Three independent instances of the OBS-013 failure mode, found by the 2026-08-17 workflow audit. Grouped because they are one defect class, not because they share code — each is a check that structurally cannot fail. Sequenced alongside TASK-073..075: those change what gates get *authored*, these repair gates already shipped.

  1. **The VISION stub check never matches.** [forge-plan.md:23](.claude/commands/forge-plan.md:23) stops planning if VISION.md "contains `<!-- What this project builds`" — but the stub `/forge-init` actually writes reads `<!-- Describe what this project builds. One paragraph. -->` ([forge-init.md:16](.claude/commands/forge-init.md:16)). The literal never matches, so `/forge-plan` will happily plan against an untouched VISION.md. Verified: `grep -c "Describe what this project builds" .claude/commands/forge-plan.md` returns 0. Fix the literal in forge-plan.md to match what forge-init writes. Note the irony before changing anything else: CONTRACT#interfaces/command-forge-plan's UX stub-detection bullet and TASK-024's notes both cite this check as the *model* for stub detection, so the pattern was propagated from a broken original.

  2. **The screen-mapping gate always exits 0.** `grep -c "^#### Screen:" .forge/UX.md | awk '$1 >= N'` is prescribed in three places — [CONTRACT.md:339](.forge/CONTRACT.md:339), [forge-plan.md:112](.claude/commands/forge-plan.md:112), and forge-plan.md's step 6 gate table. awk's exit code does not reflect whether the condition matched, and the pipeline's exit is awk's, so a mapping task with 1 of 5 screens written passes. Verified live: `printf '#### Screen: A\n' | grep -c "^#### Screen:" | awk '$1 >= 5'` exits 0. Replace all three with `test $(grep -c "^#### Screen:" .forge/UX.md) -ge N`. This is a CONTRACT edit — follow Rules/Contract Amendment Protocol, and note that no *existing* task carries this gate form, so no `fix` task is owed downstream.

  3. **`check-spec.js --max-unresolved` disables itself on a malformed value.** [check-spec.js:13](.forge/scripts/check-spec.js:13) does `Number(args[idx + 1])`; a missing or non-numeric value yields `NaN`, and `count > NaN` is always false — so the unresolved-marker check is skipped entirely rather than applied strictly. Verified: `node .forge/scripts/check-spec.js .forge/SPEC.md --max-unresolved` (no value) exits 0 without complaint. Guard with `Number.isFinite` and reject a malformed value as a usage error rather than defaulting silently in either direction.

  Gate discrimination check, since this task is about exactly that: assertion 1 fails now (`Describe what this project builds` appears nowhere in forge-plan.md); assertion 2 fails now (the awk form is present 2× in forge-plan.md, 1× in CONTRACT.md); assertion 3 fails now (`test-check-spec.sh` covers `--max-unresolved 1` at fixture 5b but has no 5c — the malformed-value case is the new fixture, and `Fixture 5c` is the name to use). `test-check-spec.sh` carries the test-first obligation for item 3 per Rules/Test-First Convention.

## [TASK-077] Reconcile four Contract passages that misdescribe their own commands

- **Status:** pending
- **Type:** clarify
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#interfaces/command-forge-plan, CONTRACT#interfaces/command-forge-status, CONTRACT#rules/traceability, CONTRACT#data-model/task-record-data-model, CONTRACT#rules/contract-amendment-protocol
- **Gate:** `node .forge/scripts/check-workplan.js && bash .forge/tests/smoke.sh && node .forge/scripts/prose.js .forge/CONTRACT.md "observations every session" "blocked tasks" && grep -q '\*\*Blocked tasks:\*\*' .claude/commands/forge-status.md && grep -q "no side effects" .forge/STATUS.md && echo "contract self-contradictions reconciled"`
- **Notes:** Four places where CONTRACT.md disagrees with itself or describes a command more narrowly than the command actually behaves — same defect family as OBS-001/OBS-004 and TASK-067, but distinct instances TASK-067 does not cover. All four are Contract-text corrections plus one command-prose line; no script changes. Log one dated Decisions row covering all four.

  1. **forge-next's Reads line contradicts its own Observations bullet.** [CONTRACT.md:357](.forge/CONTRACT.md:357) annotates `.forge/STATUS.md` as "(checkpoint tasks only)", but the same interface's Observations bullet at line 374 requires reading Observations *before selecting a task* — every session — and `/forge-next` steps 1 and 8 implement exactly that. The Reads line is the stale half. Target wording names both uses: checkpoint packets and the every-session observation read. The gate asserts the phrase `observations every session`, which appears nowhere in CONTRACT.md today.

  2. **Interfaces item 8 still states the pre-TASK-061 Files rule.** [CONTRACT.md:368](.forge/CONTRACT.md:368) says `/forge-next` "appends `Files: <comma-separated list>` to the task's Notes field" unconditionally, but Rules/Traceability was amended on 2026-08-15 to branch on the externalization threshold: inline tasks keep the `Files` line, externalized tasks put it in the record's `## Files` and never duplicate it inline. Two sections now specify different writes for one operation. Traceability is the amended, more specific one — point item 8 at it rather than restating the branch a third time.

  3. **`/forge-plan`'s "no side effects" claim is false as written.** [forge-plan.md:27](.claude/commands/forge-plan.md:27) says "This command's only write is WORKPLAN.md" and its Constraints repeat "No side effects beyond writing WORKPLAN.md" — yet step 2 writes `<!-- ASSUMED -->` annotations into CONTRACT.md and the spec-conflict check appends STATUS.md Open Questions rows, both licensed by CONTRACT#interfaces/command-forge-plan's own Does bullets. [CONTRACT.md:352](.forge/CONTRACT.md:352)'s Outputs line has the same gap. An agent honoring the constraint literally would refuse the spec-conflict logging its own step 2 mandates. Decide the honest scope — the two writes are contract-licensed and should stay — and correct both the command prose and the Outputs line to name all three artifacts.

  4. **`/forge-status` computes a blocked-tasks list that nothing reports.** `wp.js status` already derives and prints blocked tasks — the data is paid for on every invocation — but [forge-status.md:29](.claude/commands/forge-status.md:29)-57's Output Format has no slot for it, so a blocked task surfaces only as a number in the counts line. A task sitting `blocked` with no STATUS.md Blockers row is invisible in the report. Note the Contract's forge-status Outputs line says "blockers from STATUS.md", which is the **Blockers table** — a different thing from blocked tasks, and probably how the gap opened. Add a `**Blocked tasks:**` slot to the Output Format (omitted when none, matching the other conditional slots) and amend `CONTRACT#interfaces/command-forge-status`'s Does and Outputs to name it. This is the one item touching a command file rather than only Contract text; it stays read-only and adds no new computation.

  **Why item 4 is here rather than in its own task:** it is the same file, the same section type (Interfaces bullets narrower than reality), and the same Decisions row as items 1-3, so a separate session would re-read the same context to write one line. This follows the lumping precedent the human set on TASK-024 → TASK-043/044.

  **The Decisions-row assertion is phrase-based, not count-based, and that is deliberate.** This gate originally read `test $(grep -c "^| 2026-" .forge/STATUS.md) -gt 26`; the OBS-009 reopening row landed the same day and satisfied it pre-work within the hour — a live demonstration of the rot that has already made TASK-067/068's `-gt 24` vacuous. A row count asserts that *someone wrote something*, which any unrelated row satisfies. `grep -q "no side effects" .forge/STATUS.md` asserts that *this* decision was recorded, and it cannot be satisfied by another task's row. Item 3's Decisions row must therefore contain the phrase `no side effects` verbatim. When writing gates for the other count-based clauses in this workplan, prefer this shape.

## [TASK-078] Bring check-ux-spec.js's forge-init payload under the drift test

- **Status:** pending
- **Type:** fix
- **Depends:** TASK-069
- **Context:** CONTRACT#rules/embedded-payload-synchronization, CONTRACT#interfaces/command-forge-init, CONTRACT#rules/gate-patterns, notes/TASK-062#decisions
- **Gate:** `bash .forge/tests/test-init-scripts.sh && bash .forge/tests/test-check-ux-spec.sh && bash .forge/tests/smoke.sh && grep -q "forge-init:embed .forge/scripts/check-ux-spec.js" .claude/commands/forge-init.md && echo "ux-spec payload content-diffed"`
- **Notes:** The most serious single finding of the 2026-08-17 audit, and the only one shipping a *reverted bug fix* to every new project.

  `/forge-init` step 8 embeds `check-ux-spec.js`, but the embedded copy is the **pre-TASK-050 implementation**: ad-hoc `/^#{1,4} /m` regex scanning, no `lib/markdown.js` require, not fence-aware, and missing the CRLF normalization. TASK-050 rewrote the live script to be fence-aware through the shared resolver — and TASK-050's Files list does not include `forge-init.md`, so the embed was never re-copied. TASK-043 had previously patched this same block for the column-scoping fix, establishing that keeping it in sync was understood to matter; the sync then lapsed anyway, which is the argument for a mechanism over diligence.

  Consequence: every project scaffolded since TASK-050 receives a `check-ux-spec.js` that truncates a screen section at the first fenced block — the exact defect TASK-050's fixture 3 was written to prove fixed. Verified by diffing the embedded block against `.forge/scripts/check-ux-spec.js`: structurally divergent, not whitespace.

  This is a live violation of all three requirements of CONTRACT#rules/embedded-payload-synchronization — no `forge-init:embed` marker, not byte-identical to its original, not covered by any content diff. `test-init-scripts.sh` keys on the markers, so the block is invisible to it.

  Three changes:
  1. Re-copy `.forge/scripts/check-ux-spec.js` whole into step 8's fenced block, replacing the stale payload. The live script is authoritative — but read both first and confirm nothing in the embed is a fix the live file never received.
  2. Add `<!-- forge-init:embed .forge/scripts/check-ux-spec.js -->` immediately before the fence.
  3. Extend `test-init-scripts.sh` to cover it. `check-ux-spec.js` is conditional on the step 6 interface question, unlike the four unconditional scripts the test covers today — the diff must key on marker presence rather than a hardcoded list, so a project answering "no" is not a test failure.

  **Sequenced after TASK-069** deliberately: that task extends `test-init-scripts.sh` to three more script payloads, and both tasks edit the same test. Landing this second means extending an already-extended test rather than colliding with it. TASK-069's scope explicitly excludes restructuring how forge-init distributes scripts; this task inherits that boundary — re-copy and cover, do not redesign. If TASK-041's plugin-packaging investigation lands first and changes distribution, revisit rather than executing this as written.

## [TASK-079] Make the manifest slug-matching rule normative in the Contract

- **Status:** pending
- **Type:** clarify
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest, CONTRACT#interfaces/command-forge-next, CONTRACT#rules/contract-amendment-protocol, CONTRACT#rules/manifest-completeness
- **Gate:** `bash .forge/tests/test-markdown.sh && bash .forge/tests/smoke.sh && node .forge/scripts/prose.js .forge/CONTRACT.md "alphanumeric compaction" && node .forge/scripts/prose.js .claude/commands/forge-next.md "alphanumeric compaction" && grep -q "claudemd-integration-block" .forge/tests/test-markdown.sh && grep -q "alphanumeric compaction" .forge/STATUS.md && echo "slug rule reconciled"`
- **Notes:** `/forge-next` documents a slug algorithm that `lib/markdown.js` does not implement, and the documented one fails on references live in this workplan today.

  **The divergence.** [forge-next.md:97](.claude/commands/forge-next.md:97)-101 instructs: lowercase the heading, "replace runs of non-alphanumeric characters with single hyphens, trim leading/trailing hyphens", then "compare to the reference segment" — a hyphen-preserving slugify applied to the heading only. `lib/markdown.js`'s `normalizeSlug` instead strips every non-alphanumeric character outright, and applies that compaction to **both** sides.

  **Verified against real refs in this file:**

  | Heading | Reference segment | Documented | Implemented |
  | ------- | ----------------- | ---------- | ----------- |
  | `### CLAUDE.md Integration Block` | `claudemd-integration-block` (TASK-006) | `claude-md-integration-block` → **no match** | `claudemdintegrationblock` → match |
  | `### UX.md Data Model` | `ux.md-data-model` (TASK-017) | `ux-md-data-model` → **no match** | `uxmddatamodel` → match |
  | `## Data Model` | `data-model` | `data-model` → match | `datamodel` → match |

  So an agent following step 3's prose literally — which is the documented fallback when `lib/markdown.js` is absent, and the only instruction a human reading the command has — would report "Could not resolve context reference" for manifests that `check-workplan.js` validates as fine. The failure is silent in the worst direction: the agent proceeds with partial context and warns about a reference that is actually correct.

  **The fix is not just to correct the prose.** The compaction rule currently lives in exactly one command file and one script, and CONTRACT#data-model/context-manifest — which is where manifest resolution is specified — is silent on it. That is the same defect the 2026-08-16 decision fixed for requirement-heading matching, and its reasoning applies verbatim: *"A resolution rule that lives only in a consumer is not a contract."* TASK-050's extraction dropped the req-slug rule precisely because no Contract section named it. Three edits:

  1. **Amend `CONTRACT#data-model/context-manifest`** to state the matching rule normatively, beside the requirement-heading exception already there: both the heading text and the reference segment are compacted to lowercase alphanumerics before comparison. Explain *why* it is looser than a strict hyphen-slug — it tolerates the mixed `ux.md-data-model` / `claudemd-integration-block` punctuation this project's own hand-written Context fields already carry, per TASK-025's note (3). Follow Rules/Contract Amendment Protocol.
  2. **Rewrite [forge-next.md:97](.claude/commands/forge-next.md:97)-101** to describe what actually happens, and point at the Contract section as the normative source rather than restating the algorithm a second time. Keep the documented exceptions — the `Flow:`/`Screen:` prefix stripping and the bracketed req-slug rule — which are correct as written.
  3. **Add a fixture to `test-markdown.sh`** covering a punctuation-mismatched reference. `claudemd-integration-block` against a `CLAUDE.md Integration Block` heading is the case to pin, since it is live in TASK-006 and is the one a hyphen-preserving implementation would break. The file's header comment explains it exists because a matching rule was silently dropped once; this is the second such rule.

  **Not in scope: changing the implementation.** `normalizeSlug` is correct and the Contract should ratify it. A strict hyphen-preserving slugify would break every `.md`-derived reference in this workplan — TASK-025 rejected that explicitly. This task moves the rule to where it is addressable, it does not relitigate it.

  Gate discrimination: `alphanumeric compaction` appears in neither CONTRACT.md, forge-next.md, nor STATUS.md today, and `test-markdown.sh` has no `claudemd-integration-block` fixture — all four clauses verified failing at authoring time. The Decisions-row assertion is phrase-based rather than a row count, for the reason spelled out in TASK-077's notes.

## [TASK-080] Add a drift test over the task-type enum's five restatements

- **Status:** pending
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#interfaces/task-types, CONTRACT#rules/embedded-payload-synchronization, CONTRACT#rules/workplan-lint, CONTRACT#rules/gate-patterns, CONTRACT#rules/test-first-convention
- **Gate:** `bash .forge/tests/test-task-types.sh && bash .forge/tests/smoke.sh && grep -q "test-task-types" .forge/tests/smoke.sh && echo "task-type enum drift-checked"`
- **Notes:** Closes OBS-012, triaged `accepted` on 2026-08-17. The row says four restatement sites; there are **five**:

  | # | Site | Kind |
  | - | ---- | ---- |
  | 1 | [lib/workplan.js:25](.forge/scripts/lib/workplan.js:25) `VALID_TYPES` | executable — the only copy that can reject a bad value |
  | 2 | [CONTRACT.md:428](.forge/CONTRACT.md:428)-437 Task Types table | normative prose |
  | 3 | [forge-plan.md:74](.claude/commands/forge-plan.md:74) fenced task-format block | copyable template |
  | 4 | [forge-plan.md:93](.claude/commands/forge-plan.md:93)-102 task-types table | prose |
  | 5 | [forge-next.md:41](.claude/commands/forge-next.md:41) wp.js output-shape block | documents literal script output |

  Site 5 is the one OBS-012 missed — worth noting, because an incomplete list of copies is the same failure as an unchecked copy.

  **Do not consolidate.** Each prose copy earns its place: forge-plan's fenced block is a template a planner reproduces verbatim, forge-next's block documents what `wp.js` actually prints, and the two tables carry per-type gate guidance that a pointer would lose. The duplication is deliberate; the *absence of a check on it* is the defect. `checkpoint` silently fell out of site 4 and stayed missing until TASK-036 noticed by hand — Vision pillar 2's exact failure mode.

  **Build `.forge/tests/test-task-types.sh`:** parse `VALID_TYPES` out of `lib/workplan.js` as the source of truth, then assert every member appears at each of the four prose sites, and — equally important — that no site names a type absent from `VALID_TYPES`. Both directions matter: a type added to the Contract but never to the enum is as broken as one dropped from a table, and only the second direction would have caught the `checkpoint` drift. Follow `test-init-scripts.sh`'s shape (derive from the original, assert against the copies) rather than hardcoding the eight type names, which would make the test one more copy to drift.

  Wire it into `smoke.sh` beside the other suites, per the pattern at [smoke.sh:252](.forge/tests/smoke.sh:252)-269.

  **Test-first:** write the test before touching anything, and confirm it fails on a seeded drift — delete `checkpoint` from forge-plan.md's table, watch it fail, restore. A drift test that has never seen drift proves nothing, which is the lesson of TASK-056's fixture-discrimination check.

  Gate discrimination: `.forge/tests/test-task-types.sh` does not exist and `smoke.sh` does not reference it, both verified at authoring time — the gate cannot pass before the work.

  **Scope boundary:** this is a check over the existing enum, not a change to it. Adding, removing, or renaming a task type is out of scope; if the test surfaces a genuine disagreement about what the enum *should* contain, log it and stop rather than picking a side.

## [TASK-072] Anchor forge script roots to the script location, not the shell cwd

- **Status:** done
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-access-discipline, CONTRACT#rules/gate-patterns, CONTRACT#boundaries/platform-constraints
- **Gate:** `bash .forge/tests/test-wp.sh && bash .forge/tests/test-init-scripts.sh && bash .forge/tests/smoke.sh && (cd .forge/scripts && node wp.js status > /dev/null && node check-workplan.js > /dev/null) && echo "forge scripts resolve their own root"`
- **Notes:** findRoot() walk-up resolution in lib/markdown.js, shared by all four entry scripts; deviation from the __dirname suggestion to keep fixture harnesses working. Record: .forge/notes/TASK-072.md

## [TASK-046] Checkpoint: v0.3 machinery complete

- **Status:** pending
- **Type:** checkpoint
- **Depends:** TASK-026, TASK-028, TASK-029, TASK-032, TASK-033, TASK-034, TASK-036, TASK-037, TASK-038, TASK-047, TASK-051, TASK-053, TASK-054, TASK-055, TASK-059, TASK-060, TASK-062, TASK-067, TASK-068, TASK-069, TASK-070, TASK-071, TASK-072, TASK-073, TASK-074, TASK-075, TASK-076, TASK-077, TASK-078, TASK-079, TASK-080, TASK-094
- **Context:** CONTRACT#rules/checkpoint-cadence, CONTRACT#rules/unattended-execution, CONTRACT#data-model/status.md-data-model
- **Gate:** `manual: Review the v0.3 build span before validation and docs. Packet must contain: each task completed in the span with its description and Files line, the gate result for each, check-workplan.js output on the current workplan, current STATUS.md Open Questions and Risks, and the span's starting commit for rollback.`
- **Notes:** First executable checkpoint in Forge's history — executing it is itself the live validation that TASK-035 and TASK-037 work. Span is 20 tasks, far over the cadence of 5: v0.3's own plan predates its checkpoint machinery, so this is the only position where a checkpoint is executable (see STATUS.md Decisions, 2026-07-31) — inserting a second checkpoint earlier in the span would hit the same "Template file missing" hard stop. Normal cadence applies from v0.4. Depends lists the span's leaf tasks, which transitively cover all of TASK-025..038 plus TASK-047 (added in a later planning pass the same day — the guard hooks are part of v0.3's unattended-execution machinery and must be reviewed in the same checkpoint, not deferred to v0.4) plus TASK-067..071 (the 2026-08-16 observation-backlog triage — these repair v0.3 machinery this checkpoint reviews, and TASK-069 in particular must land before TASK-039, whose gate asserts that `/forge-init` creates both check scripts) plus TASK-073..075 (the OBS-013 gate-discrimination work — these must land *before* this packet, not after, because the packet re-runs every gate in the span and a span of vacuous gates re-run fresh is a span of evidence that proves nothing) plus TASK-076..078 (the 2026-08-17 workflow audit — TASK-076 repairs three already-shipped gates that cannot fail, which is the same fresh-re-run argument as TASK-073..075; TASK-077 reconciles three self-contradicting Contract passages the packet's readers would otherwise hit; TASK-078 fixes a stale `/forge-init` payload shipping a reverted bug fix to every new project). Q-006 evaluation: after passing or failing the packet, record whether this span read as a coherent review unit or as unrelated work reviewed together — that judgment is the evidence for or against feature-aligned checkpoint cadence, and it cannot be recovered later.

## [TASK-093] Convert STATUS.md Decisions from a table to dated sections

- **Status:** pending
- **Type:** refactor
- **Depends:** TASK-046
- **Context:** CONTRACT#data-model/status.md-data-model, CONTRACT#rules/contract-amendment-protocol, CONTRACT#data-model/markdown-table-parsing, CONTRACT#rules/status-lint
- **Gate:** `grep -q "^### 2026-" .forge/STATUS.md && ! grep -q "Alternatives rejected" .forge/STATUS.md && node .forge/scripts/prose.js .forge/CONTRACT.md "one dated section per decision" && bash .forge/tests/smoke.sh && node .forge/scripts/check-workplan.js && echo "decisions read as history"`
- **Notes:** ideas/ux-nearterm.md item 4, decided 2026-08-30 (see STATUS Decisions). STATUS.md is ~95KB in ~90 lines with single Decisions cells over 2,100 characters — unreadable in a terminal, unreviewable in a diff, hostile to hand-editing. Decisions are append-only prose history; a table is the wrong container. Amend `CONTRACT#data-model/status.md-data-model`: `## Decisions` holds `### YYYY-MM-DD — Title` sections, newest first, body free prose with recommended **Why:** and **Alternatives rejected:** paragraphs — one dated section per decision. The other four tables stay tables (machine-read, short cells). Update the skeleton in the Data Model, the Rules/Status Lint scope wording (four tables plus the Decisions heading shape), and every Contract reference to a "Decisions row" (unattended-execution auto-disposition wording, observation-lifecycle exception 2, /forge-plan) to "Decisions entry". Migrate every existing row mechanically — date plus bolded lead becomes the heading, cells become paragraphs; content is preserved verbatim, not rewritten. Sequenced **before** TASK-082 so check-status.js is built once against the final shape. Gate discrimination: no `### 2026-` heading exists in STATUS.md today; the "Alternatives rejected" column header does (clause 2 fails pre-work); the prose.js phrase appears nowhere in CONTRACT.md.

## [TASK-081] Teach lib/markdown.js to parse tables by column name

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-046
- **Context:** CONTRACT#data-model/markdown-table-parsing, CONTRACT#data-model/status.md-data-model, CONTRACT#rules/test-first-convention
- **Gate:** `bash .forge/tests/test-markdown.sh && grep -q "parseTable" .forge/tests/test-markdown.sh && bash .forge/tests/smoke.sh && echo "one table parser"`
- **Notes:** The foundation for check-status.js and obs.js, per `CONTRACT#data-model/markdown-table-parsing`: the shared parser lives in `lib/markdown.js`, and no caller re-implements table splitting. Export a `parseTable` that returns header-keyed rows (parse by column name, never position), honors `\|` escapes and pipes inside backtick spans, and reports a row with the wrong cell count as a structured error — never a silently dropped row. Test-first in `test-markdown.sh`: fixtures must include an escaped pipe in a cell, a pipe inside a backtick span, and a malformed row, and the malformed-row fixture must fail if the parser skips instead of erroring. Scope boundary: migrating check-ux-spec.js's States-table reading onto the new parser is out of scope — log an observation if the duplication matters.

## [TASK-082] Build check-status.js and bring the live STATUS.md under it

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-081, TASK-093
- **Context:** CONTRACT#rules/status-lint, CONTRACT#data-model/status.md-data-model, CONTRACT#state-machines/observation-lifecycle, CONTRACT#interfaces/script-exit-codes, CONTRACT#data-model/markdown-table-parsing
- **Gate:** `bash .forge/tests/test-check-status.sh && node .forge/scripts/check-status.js && grep -q "test-check-status" .forge/tests/smoke.sh && bash .forge/tests/smoke.sh && echo "status lint live"`
- **Notes:** Implements `CONTRACT#rules/status-lint` on the post-TASK-093 shape: every table present has the columns its Data Model skeleton declares in order; every row parses to exactly that column count (error, never a skipped row); Observation IDs unique and monotonic; Kind/Severity/Disposition enumerated; `planned:TASK-XXX` names an existing task and `duplicate:OBS-YYY` names an existing non-duplicate row; `accepted` rows older than one checkpoint span without a task link warn; Decisions headings match `### YYYY-MM-DD — `. Errors exit 1 and block, warnings print. **Migration lands in the same diff:** the live Observations table gains its mandated Date column (dates recovered from the git history of each row's introduction), because the moment check-status.js exists the headless-run pre-commit breaker arms it — the file and the lint must go green together. The PostToolUse hook wiring is TASK-088's scope, not here.

## [TASK-083] Build obs.js as the sole Observations writer

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-082
- **Context:** CONTRACT#interfaces/observation-script, CONTRACT#state-machines/observation-lifecycle, CONTRACT#rules/status-lint, CONTRACT#interfaces/script-exit-codes, CONTRACT#data-model/status.md-data-model
- **Gate:** `bash .forge/tests/test-obs.sh && grep -q "test-obs" .forge/tests/smoke.sh && bash .forge/tests/smoke.sh && node .forge/scripts/obs.js list > /dev/null && echo "observations have one writer"`
- **Notes:** Implements `CONTRACT#interfaces/observation-script` exactly: `add` (mints ID at write time, stamps date, escapes pipes, Disposition `open`), `set` (targeted field write refusing invalid lifecycle transitions), `list` (projection with computed age in days, `--json`, disposition/severity filters), `sweep` (closes `planned:` rows whose task is `done`, reports unlinked `accepted` rows and exact-duplicate text — no judgment, no input). Every write follows write-validate-revert through check-status.js, the pattern wp.js established. Fixture discipline per TASK-056: a fixture that passes with the feature reverted proves nothing — the transition-refusal fixture must attempt a genuinely invalid transition, and sweep's close fixture must include a `planned:` row whose task is *not* done and assert it survives. First live `sweep` will close several rows this planning pass left at `planned:` with their tasks already done — run it and record the result in this task's notes.

## [TASK-095] Checkpoint: observation machinery core

- **Status:** pending
- **Type:** checkpoint
- **Depends:** TASK-093, TASK-081, TASK-082, TASK-083
- **Context:** CONTRACT#rules/checkpoint-cadence, CONTRACT#rules/unattended-execution, CONTRACT#data-model/status.md-data-model
- **Gate:** `manual: Review the observation-machinery core span. Packet must contain: each task in the span with description and Files, fresh re-runs of every automated gate in the span with regressions flagged, check-workplan.js and check-status.js output on the current artifacts, current STATUS.md Open Questions and Risks, and the span's starting commit for rollback.`
- **Notes:** First checkpoint inserted by the 2026-08-30 headless planning pass, at the Contract's cadence of 5 (4 tasks + this). Under HEADLESS-RUN.md authority the run itself reviews the packet and records pass/fail; the packet is written to `.forge/notes/TASK-095.md` so the human can re-review the span at merge.

## [TASK-084] Integrate obs.js into /forge-next

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-095
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#rules/unattended-execution, CONTRACT#interfaces/observation-script, CONTRACT#interfaces/script-exit-codes
- **Gate:** `node .forge/scripts/prose.js .claude/commands/forge-next.md "obs.js sweep" "guided triage" && bash .forge/tests/smoke.sh && node .forge/scripts/check-workplan.js && echo "the loop closes at forge-next"`
- **Notes:** The command-side half of the Observations overhaul, per the amended `CONTRACT#interfaces/command-forge-next`: run `obs.js sweep` before selection; on the exit-**3** halt enter the guided triage flow (present each open row in plain language with a recommended disposition and reasoning, apply answers via `obs.js set`, retry selection — never a separate command); during unattended spans, apply only the two permitted auto-dispositions and otherwise write the triage packet to disk and stop; record completion-time observations via `obs.js add`, replacing any hand-written row-format instruction (the format belongs to the script — `CONTRACT#interfaces/prompt-template-interface` reasoning applies to command prose too); never promote an observation to a task. Update the wp.js output-shape block for the exit-code split TASK-074 landed. This also delivers ideas/ux-nearterm.md item 5's substance — the alert surface at session start, where attention already is.

## [TASK-085] Project the observation backlog through /forge-status

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-095
- **Context:** CONTRACT#interfaces/command-forge-status, CONTRACT#interfaces/observation-script, CONTRACT#data-model/status.md-data-model
- **Gate:** `node .forge/scripts/prose.js .claude/commands/forge-status.md "obs.js list" "backlog counts by disposition" && bash .forge/tests/smoke.sh && echo "status reads the queue"`
- **Notes:** Per the amended `CONTRACT#interfaces/command-forge-status`: open `foundation` rows first, each with the raising task's description and age in days; the `accepted` awaiting-planning queue; backlog counts by disposition — all obtained through `obs.js list --json`, never by reading STATUS.md in full. A bare ID is not a report: the reader must be able to act without opening another file. Verify at execution that the gate's phrases are genuinely absent from forge-status.md pre-work; tighten them if not.

## [TASK-086] Close the accepted-observation loop in /forge-plan

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-095
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#interfaces/observation-script, CONTRACT#state-machines/observation-lifecycle
- **Gate:** `node .forge/scripts/prose.js .claude/commands/forge-plan.md "obs.js set" && bash .forge/tests/smoke.sh && node .forge/scripts/check-workplan.js && echo "accepted rows reach planned"`
- **Notes:** Per the amended `CONTRACT#interfaces/command-forge-plan`: observation intake consumes `accepted` rows as planning input, and when planning generates a task for one, it advances the row to `planned:TASK-XXX` via `obs.js set` — the one STATUS.md write this command makes, closing the loop that previously let an accepted row sit unplanned and unseen. Rows in any other disposition are not planned. Update forge-plan.md's intake step accordingly; keep the change scoped to command prose.

## [TASK-087] Delegate observation recording in the templates to obs.js

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-095, TASK-070
- **Context:** CONTRACT#interfaces/prompt-template-interface, CONTRACT#interfaces/observation-script, CONTRACT#rules/embedded-payload-synchronization
- **Gate:** `grep -rq "obs.js add" .forge/templates && bash .forge/tests/test-templates.sh && bash .forge/tests/test-init-scripts.sh && bash .forge/tests/smoke.sh && echo "templates carry judgment not format"`
- **Notes:** Per `CONTRACT#interfaces/prompt-template-interface`: every template instructs recording out-of-scope findings by invoking `obs.js add`, applying the in-scope fix test rather than logging reflexively — the template carries the *judgment*, the script owns the *format*. Remove any restatement of the row layout from the templates (reintroducing it is the duplication obs.js exists to remove). Re-copy every changed template's forge-init.md payload whole; the TASK-070 marker diff enforces this mechanically.

## [TASK-088] Ship the observation machinery in /forge-init

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-069, TASK-083, TASK-087
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#rules/embedded-payload-synchronization, CONTRACT#boundaries/hook-configuration, CONTRACT#rules/status-lint
- **Gate:** `grep -q "forge-init:embed .forge/scripts/obs.js" .claude/commands/forge-init.md && grep -q "forge-init:embed .forge/scripts/check-status.js" .claude/commands/forge-init.md && grep -q "check-status" .claude/settings.json && bash .forge/tests/test-init-scripts.sh && bash .forge/tests/smoke.sh && echo "scaffolds get the machinery"`
- **Notes:** Three changes, one concern — a scaffolded project must receive the observation machinery whole: (1) embed `obs.js` and `check-status.js` payloads with `forge-init:embed` markers so the content diff covers them (the nine-script bullet in the amended Contract already mandates both); (2) the STATUS.md stub gains the Date column so its columns match the Data Model skeleton exactly — a stub whose columns disagree makes every row obs.js writes malformed on arrival; (3) the settings.json payload gains the PostToolUse STATUS.md hook invoking check-status.js through a wrapper that exits **2** on lint failure per `CONTRACT#interfaces/script-exit-codes`'s hook-contract paragraph, and this repo's own `.claude/settings.json` gets the same hook (dogfood; hook config snapshots at session start, so it arms from the next session).

## [TASK-096] Checkpoint: observation machinery integrated

- **Status:** pending
- **Type:** checkpoint
- **Depends:** TASK-084, TASK-085, TASK-086, TASK-087, TASK-088
- **Context:** CONTRACT#rules/checkpoint-cadence, CONTRACT#rules/unattended-execution, CONTRACT#data-model/status.md-data-model
- **Gate:** `manual: Review the observation-integration span. Packet must contain: each task in the span with description and Files, fresh re-runs of every automated gate in the span with regressions flagged, check-workplan.js and check-status.js output, current STATUS.md Open Questions and Risks, and the span's starting commit for rollback.`
- **Notes:** Second checkpoint of the headless planning pass, closing the five command/template integration tasks. Same review-and-record protocol as TASK-095.

## [TASK-089] Give /forge-init its missing VERSION step

- **Status:** pending
- **Type:** fix
- **Depends:** TASK-096
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#interfaces/command-forge-sync, CONTRACT#data-model/artifacts
- **Gate:** `grep -q "forge/VERSION" .claude/commands/forge-init.md && grep -q "VERSION" .forge/tests/test-init-scripts.sh && bash .forge/tests/test-init-scripts.sh && bash .forge/tests/smoke.sh && echo "init stamps the engine version"`
- **Notes:** Closes OBS-014. `CONTRACT#interfaces/command-forge-init` requires creating `.forge/VERSION` if absent (line 1: engine version stamp; line 2: canonical repo URL — read the live file for the exact format), but forge-init.md contains no VERSION step at all, so a newly scaffolded project has no stamp and `/forge-sync` stops at step 1. Add the step, the created-files list entry, and a `test-init-scripts.sh` assertion. Gate discrimination verified at planning: `forge/VERSION` appears nowhere in forge-init.md and `VERSION` nowhere in test-init-scripts.sh.

## [TASK-090] Widen forge-sync.md's managed globs to the Contract's set

- **Status:** pending
- **Type:** fix
- **Depends:** TASK-096
- **Context:** CONTRACT#interfaces/command-forge-sync, CONTRACT#data-model/artifacts
- **Gate:** `grep -q "scripts/lib" .claude/commands/forge-sync.md && grep -q "guard-" .claude/commands/forge-sync.md && bash .forge/tests/smoke.sh && node .forge/scripts/check-workplan.js && echo "sync sees every managed script"`
- **Notes:** Closes OBS-015. The 2026-08-29 Contract amendment already widened `CONTRACT#interfaces/command-forge-sync`'s globs to `.forge/scripts/*.js`, `.forge/scripts/lib/*.js`, and `.forge/scripts/guard-*.sh`; forge-sync.md still says `check-*.js` only, at three sites (the managed-globs list near line 13, the example diff listing near line 81, and the "Only the three managed globs are writable" constraint near line 108). Reconcile all three to the Contract's set. Gate discrimination verified at planning: `scripts/lib` and `guard-` appear nowhere in forge-sync.md.

## [TASK-091] Emit the workplan graph from wp.js

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-096
- **Context:** CONTRACT#rules/workplan-access-discipline, CONTRACT#rules/task-ordering, CONTRACT#data-model/artifacts, CONTRACT#rules/embedded-payload-synchronization
- **Gate:** `bash .forge/tests/test-wp.sh && grep -q "graph --mermaid" .forge/tests/test-wp.sh && node .forge/scripts/wp.js graph --mermaid | grep -q "flowchart" && bash .forge/tests/smoke.sh && echo "the DAG is visible"`
- **Notes:** ideas/ux-nearterm.md item 1 — the highest-leverage item on its list. `wp.js graph --json` emits nodes (id, description, status, type) and edges (depends); `--mermaid` renders the same structure as a flowchart, which displays in GitHub and terminal-adjacent tooling for zero rendering code. This is the DAG's data model; every later rendering layer consumes it, and TASK-092 is its first consumer. Projection only — no new state, no workplan mutation. Re-copy the wp.js forge-init payload whole (the marker diff enforces).

## [TASK-092] Make /forge-status graph-aware

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-091
- **Context:** CONTRACT#interfaces/command-forge-status, CONTRACT#rules/workplan-access-discipline
- **Gate:** `node .forge/scripts/prose.js .claude/commands/forge-status.md "startable" "choke point" && bash .forge/tests/smoke.sh && echo "position not just counts"`
- **Notes:** ideas/ux-nearterm.md item 2: replace "18 pending, next: TASK-XXX" with the shape of remaining work — depth, width, the full startable set, and choke points (high fan-in nodes such as checkpoints) — derived from two traversals over `wp.js graph --json`. The current report shows a queue of one while ten tasks are equally startable; correct for an unattended span, a real loss for a human deciding where to spend a session. Verify at execution that "startable" and "choke point" are absent from forge-status.md pre-work.

## [TASK-097] Checkpoint: v0.3+ projection and repairs

- **Status:** pending
- **Type:** checkpoint
- **Depends:** TASK-089, TASK-090, TASK-091, TASK-092
- **Context:** CONTRACT#rules/checkpoint-cadence, CONTRACT#rules/unattended-execution, CONTRACT#data-model/status.md-data-model
- **Gate:** `manual: Review the projection-and-repairs span. Packet must contain: each task in the span with description and Files, fresh re-runs of every automated gate in the span with regressions flagged, check-workplan.js and check-status.js output, current STATUS.md Open Questions and Risks, and the span's starting commit for rollback.`
- **Notes:** Third checkpoint of the headless planning pass, closing the graph-projection and observation-repair span before end-to-end validation and docs. Same review-and-record protocol as TASK-095.

## [TASK-039] End-to-end validation of v0.3 pipeline

- **Status:** pending
- **Type:** investigate
- **Depends:** TASK-097
- **Context:** CONTRACT#interfaces/command-forge-spec, CONTRACT#rules/workplan-lint, CONTRACT#rules/checkpoint-cadence, CONTRACT#rules/unattended-execution, CONTRACT#rules/spec-precedence
- **Gate:** `manual: In a scratch project: (1) forge-init creates SPEC.md, STATUS.md, checkpoint.md, both check scripts, and VERSION without overwriting; (2) forge-spec runs an intake interview and produces a spec that passes check-spec.js with open questions logged to STATUS.md; (3) forge-plan emits SPEC# manifests and a checkpoint task, and check-workplan.js passes; (4) forge-next resolves SPEC# refs and executes a checkpoint with a complete review packet; (5) forge-status surfaces STATUS.md items; (6) simulate a 2-3 task unattended span on a work branch honoring the hard stops`
- **Notes:**

## [TASK-049] Retire forge-spec-v0.2.md as a separate source of truth

- **Status:** pending
- **Type:** refactor
- **Depends:** TASK-046, TASK-066
- **Context:** CONTRACT#rules/contract-amendment-protocol, CONTRACT#rules/context-budget, CONTRACT#data-model/artifacts
- **Gate:** `bash .forge/tests/smoke.sh && node .forge/scripts/check-workplan.js && test -f archive/forge-spec-v0.2.md && test ! -f forge-spec-v0.2.md && grep -q "Planning at Scale" .forge/CONTRACT.md && ! grep -q "the spec's" README.md && echo "narrative spec retired"`
- **Notes:** The root narrative spec doc is a third source of truth about the same system alongside CONTRACT.md and README.md — and it is the one that drifted (still describes 3 commands, no UX/DESIGN, no SPEC/STATUS/checkpoint/sync). Maintaining it by hand reproduces, inside this repo, the exact drift problem v0.3 exists to solve.

  Three steps, in order:
  1. **Preserve the one load-bearing section.** "Planning at Scale" (scoped planning passes, split thresholds, cross-system dependency wiring) is a rule with no home in CONTRACT. Add it as `### Planning at Scale` under `## Rules`, following CONTRACT#rules/contract-amendment-protocol. It belongs beside Context Budget — same concern at a larger grain.
  2. **Fix the dangling pointer.** [README.md:225](README.md:225) reads "See the spec's 'Planning at Scale' section for the full pattern" — repoint it at the CONTRACT rule.
  3. **Archive.** Move `forge-spec-v0.2.md` to `archive/` beside `archive/forge-spec.md` (the v0.1), matching the established precedent. Also archive `prompts/forge-plan-bootstrap.md`, which reads the retired file as its blueprint and is a spent bootstrap artifact.

  Sequenced after TASK-046 deliberately: the CONTRACT amendment in step 1 would otherwise land mid-span and invalidate manifests the checkpoint is meant to review. Contract-First anchor for this task is Data Model#artifacts — the amendment is itself the deliverable.

## [TASK-040] Update README and CLAUDE.md for v0.3

- **Status:** pending
- **Type:** scaffold
- **Depends:** TASK-039, TASK-049
- **Context:** CONTRACT#interfaces/claudemd-integration-block, CONTRACT#boundaries/platform-constraints, CONTRACT#rules/unattended-execution
- **Gate:** `grep -q "forge-spec" README.md && grep -q "forge-sync" README.md && grep -qi "checkpoint" README.md && grep -q "SPEC.md" CLAUDE.md && echo "docs updated"`
- **Notes:** README: new commands, checkpoint/unattended workflow section, SPEC and STATUS in file structure, template count 7→8. CLAUDE.md: update Pipeline line per amended integration block.

## [TASK-041] Investigate plugin packaging for Forge distribution

- **Status:** pending
- **Type:** investigate
- **Depends:** TASK-040
- **Context:** CONTRACT#boundaries/platform-constraints, CONTRACT#interfaces/command-forge-sync
- **Gate:** `manual: Findings documented in Notes — plugin structure (commands/skills/hooks bundling), marketplace hosting options, migration path from copied commands, template override resolution order (project .forge/templates/ over plugin defaults), and whether /forge-sync is subsumed or retained`
- **Notes:** Tracked as STATUS.md Q-001. Decision gate for v0.4 scope.

## [TASK-052] Investigate node-schema model for Forge's own machinery

- **Status:** pending
- **Type:** investigate
- **Depends:** TASK-040
- **Context:** CONTRACT#interfaces/task-types, CONTRACT#data-model/context-manifest, CONTRACT#rules/checkpoint-cadence
- **Gate:** `manual: Findings documented in Notes — (1) the item/type catalog and whether Forge's real artifacts fit it without escape hatches; (2) node schema fields, specifically power source (deterministic script / AI / human) and mutates (writes back to shared state); (3) the result of re-expressing Forge's 8 task types, 6 commands, and 3 scripts in that schema, naming every place it did not fit; (4) a go/no-go recommendation for v0.4 with the cost of the next step`
- **Notes:** Runs the cheap test proposed at the end of forge-factory-brainstorm.md: write the schema, re-express Forge's existing machinery in it, and see whether the abstraction holds. The deliverable is one throwaway YAML file plus findings — no runtime, no generic runner, no changes to any command. If describing Forge requires escape hatches, that is the answer and it cost a day.

  Deliberately scoped as investigation, not construction. Building a node schema, plant graph, item catalog, or generic runner before this test is abstraction bloat against an unvalidated model — the failure mode named in claude-code-workflow-pitfalls.md and conceded by the brainstorm itself.

  Two constraints to carry in, both from the brainstorm's own "where the metaphor will bite you" section: rework is a cycle, not forward flow, so any graph over task *instances* grows at runtime and is really an append-only event log; and throughput is the wrong objective function — see VISION pillar 6, which now names the correct one explicitly.

  Sibling to TASK-041 (plugin packaging). Both are v0.4 scope-decision gates and both should land before any v0.4 planning pass.

