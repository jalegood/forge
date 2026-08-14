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
- **Depends:** TASK-012
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
- **Depends:** TASK-012, TASK-013, TASK-014
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

- **Status:** pending
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#data-model/spec-data-model
- **Gate:** `test -s .claude/commands/forge-init.md && grep -q "SPEC.md" .claude/commands/forge-init.md && echo "forge-init SPEC stub present"`
- **Notes:** Stub follows the SPEC Data Model: Overview, Requirements (with REQ-slug/EARS comment guidance), Flows, Non-Goals. Mention the ~300-line split threshold to .forge/specs/ in a stub comment.

## [TASK-028] Update /forge-plan to read SPEC and emit SPEC# refs in manifests

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-027
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#data-model/spec-data-model, CONTRACT#data-model/context-manifest, CONTRACT#rules/spec-precedence
- **Gate:** `bash .forge/tests/smoke.sh && grep -q "SPEC#" .claude/commands/forge-plan.md && echo "forge-plan SPEC support present"`
- **Notes:** Completeness test spans SPEC and CONTRACT: behavior without constraint or constraint without behavior fails. Spec conflicts with CONTRACT are logged to STATUS.md Open Questions and become clarify tasks.

## [TASK-029] Update /forge-next to resolve SPEC# and specs/name# context references

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-027
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#data-model/context-manifest, CONTRACT#data-model/spec-data-model
- **Gate:** `bash .forge/tests/smoke.sh && grep -q "SPEC#" .claude/commands/forge-next.md && echo "forge-next SPEC# resolution present"`
- **Notes:** Same slug-matching resolution as CONTRACT#; specs/name# routes to .forge/specs/name.md.

## [TASK-030] Create check-spec.js spec readiness gate script

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-027
- **Context:** CONTRACT#data-model/spec-data-model, CONTRACT#rules/gate-patterns
- **Gate:** `bash .forge/tests/test-check-spec.sh`
- **Notes:** Validates a spec file: required sections present (Overview, Requirements, Non-Goals), at least one REQ with acceptance criteria, no unresolved `<!-- UNRESOLVED -->` markers above threshold (default: zero blocking), no placeholder/TODO text in Requirements. Mirrors check-ux-spec.js structure.

## [TASK-031] Update /forge-init to create STATUS.md stub

- **Status:** pending
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#data-model/status.md-data-model
- **Gate:** `grep -q "STATUS.md" .claude/commands/forge-init.md && echo "forge-init STATUS stub present"`
- **Notes:** Four-table stub per the STATUS.md Data Model. This repo's own .forge/STATUS.md is the reference instance.

## [TASK-032] Create /forge-spec intake command

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-030, TASK-031
- **Context:** CONTRACT#interfaces/command-forge-spec, CONTRACT#data-model/spec-data-model, CONTRACT#data-model/status.md-data-model
- **Gate:** `test -s .claude/commands/forge-spec.md && grep -q "ASSUMED" .claude/commands/forge-spec.md && grep -q "STATUS.md" .claude/commands/forge-spec.md && grep -q "check-spec" .claude/commands/forge-spec.md && grep -qi "interview" .claude/commands/forge-spec.md && echo "forge-spec command valid"`
- **Notes:** Interview-before-draft is the point — unasked questions become propagated assumptions. Accepts raw idea text or pasted ticket as $ARGUMENTS.

## [TASK-033] Update /forge-status to surface STATUS.md items

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-031
- **Context:** CONTRACT#interfaces/command-forge-status, CONTRACT#data-model/status.md-data-model
- **Gate:** `bash .forge/tests/smoke.sh && grep -q "STATUS.md" .claude/commands/forge-status.md && echo "forge-status STATUS integration present"`
- **Notes:** Surfaces open questions (flag Blocking ones) and blockers. Remains read-only.

## [TASK-034] Update clarify template to log decisions to STATUS.md

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-031
- **Context:** CONTRACT#data-model/status.md-data-model, CONTRACT#interfaces/prompt-template-interface
- **Gate:** `bash .forge/tests/smoke.sh && grep -q "STATUS.md" .forge/templates/clarify.md && echo "clarify template logs decisions"`
- **Notes:** On resolution: move the question from Open Questions to Decisions with date, rationale, and rejected alternatives.

## [TASK-035] Create checkpoint.md template and add to /forge-init template set

- **Status:** pending
- **Type:** scaffold
- **Depends:** TASK-031
- **Context:** CONTRACT#interfaces/task-types, CONTRACT#interfaces/prompt-template-interface, CONTRACT#rules/checkpoint-cadence
- **Gate:** `test -s .forge/templates/checkpoint.md && grep -q "checkpoint.md" .claude/commands/forge-init.md && echo "checkpoint template present"`
- **Notes:** Template instructs: assemble review packet (span tasks + Files lines, gate results, manual test steps, STATUS excerpt, span starting commit for rollback), present, wait for manual pass/fail. Produces no code.

## [TASK-036] Update /forge-plan to insert checkpoint tasks at cadence

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-035
- **Context:** CONTRACT#interfaces/command-forge-plan, CONTRACT#rules/checkpoint-cadence, CONTRACT#interfaces/task-types
- **Gate:** `bash .forge/tests/smoke.sh && grep -qi "checkpoint" .claude/commands/forge-plan.md && echo "forge-plan checkpoint cadence present"`
- **Notes:** Phase boundary or every 5 non-checkpoint tasks, whichever first; checkpoint Depends lists the full span; downstream tasks depend on the checkpoint.

## [TASK-037] Update /forge-next to execute checkpoint tasks with review packet

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-035
- **Context:** CONTRACT#interfaces/command-forge-next, CONTRACT#rules/checkpoint-cadence, CONTRACT#rules/unattended-execution, CONTRACT#data-model/status.md-data-model
- **Gate:** `bash .forge/tests/smoke.sh && grep -qi "checkpoint" .claude/commands/forge-next.md && grep -qi "review packet" .claude/commands/forge-next.md && echo "forge-next checkpoint execution present"`
- **Notes:** Checkpoint gates are always manual:. On block, append a STATUS.md Blockers row.

## [TASK-038] Create /forge-sync command and .forge/VERSION stamp

- **Status:** pending
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#interfaces/command-forge-sync, CONTRACT#data-model/artifacts
- **Gate:** `test -s .claude/commands/forge-sync.md && test -s .forge/VERSION && grep -q "VERSION" .claude/commands/forge-sync.md && grep -qi "never" .claude/commands/forge-sync.md && echo "forge-sync command valid"`
- **Notes:** VERSION line 1 = engine version (start at 0.3.0), line 2 = canonical repo URL. Sync diffs Forge-managed files only; project-owned artifacts are untouchable; per-file human approval.

## [TASK-047] Create unattended-execution guard hooks and wire into settings.json

- **Status:** pending
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#boundaries/hook-configuration, CONTRACT#rules/unattended-execution, CONTRACT#interfaces/command-forge-init, CONTRACT#data-model/artifacts
- **Gate:** `bash .forge/tests/test-guard-hooks.sh`
- **Notes:** Three deterministic PreToolUse guard scripts per CONTRACT#boundaries/hook-configuration:
  1. `.forge/scripts/guard-push.sh` — blocks any Bash command matching `git push`, unconditionally.
  2. `.forge/scripts/guard-branch.sh` — blocks `git commit` when `FORGE_UNATTENDED=1` is set AND the current branch equals the repo's default branch; no-op otherwise (ordinary interactive sessions are untouched).
  3. `.forge/scripts/guard-secrets.sh` — blocks `git commit` when the staged diff matches a conservative secret-pattern list (cloud access keys, private-key headers, common API-key prefixes).

  `FORGE_UNATTENDED=1` must be set by the headless-loop launcher script itself (e.g. the `while ... claude -p "/forge-next" ... done` wrapper), never by a human typing `export` before a run. This is deliberate, not an implementation detail to skip: per human discussion (2026-07-31), this project is used both at work (branch-protected — direct main commits already impossible server-side) and on personal projects (direct main commits are the normal, human-reviewed, interactive habit). Making the flag manual would mean a forgotten `export` before an unattended run silently falls back to normal main-committing behavior — exactly the one case where nobody is watching to catch it. Sourcing the flag from the launcher script instead removes the "did I remember" failure mode in both directions: ordinary interactive `/forge-next` never has it set (guard stays inert, personal-project workflow untouched), and every unattended invocation has it set automatically (guard is always live). Building the launcher/wrapper script itself is out of scope for this task — it's a future task once headless looping is built; this task only defines and documents the convention the wrapper must follow (see CONTRACT#boundaries/hook-configuration).

  Wire all three into `.claude/settings.json`'s `PreToolUse` array (Bash matcher), alongside the existing PostToolUse lint hook — do not remove or reorder it. Also update `.claude/commands/forge-init.md`'s settings.json-creation step so new projects get all three guards by default (per CONTRACT#interfaces/command-forge-init), following the TASK-043 precedent of keeping forge-init.md's embedded canonical copies in sync with the locally-deployed scripts.

  Test script `.forge/tests/test-guard-hooks.sh` (mirrors TASK-025/TASK-030's fixture pattern) exercises, per guard: push guard blocks a `git push` command and passes one without; branch guard blocks only when both `FORGE_UNATTENDED=1` is set and the current branch is the default-branch fixture, passes when either condition is false; secret guard blocks a fixture staged diff containing a known secret pattern and passes a clean fixture diff. Each script reads the PreToolUse hook's stdin JSON contract (`tool_input.command`) and exits nonzero to block.

  Origin: identified during a risk discussion on auto-commit during unattended execution (2026-07-31) — CONTRACT already specified the unattended-execution policy (work-branch-only, no-push, hard-stops) but nothing mechanically enforced it. Coverage gap resolved in CONTRACT.md by this planning pass before this task was generated (Boundaries#hook-configuration, Data Model#artifacts, Interfaces#command-forge-init).

## [TASK-046] Checkpoint: v0.3 machinery complete

- **Status:** pending
- **Type:** checkpoint
- **Depends:** TASK-026, TASK-028, TASK-029, TASK-032, TASK-033, TASK-034, TASK-036, TASK-037, TASK-038, TASK-047
- **Context:** CONTRACT#rules/checkpoint-cadence, CONTRACT#rules/unattended-execution, CONTRACT#data-model/status.md-data-model
- **Gate:** `manual: Review the v0.3 build span before validation and docs. Packet must contain: each task completed in the span with its description and Files line, the gate result for each, check-workplan.js output on the current workplan, current STATUS.md Open Questions and Risks, and the span's starting commit for rollback.`
- **Notes:** First executable checkpoint in Forge's history — executing it is itself the live validation that TASK-035 and TASK-037 work. Span is 15 tasks, over the cadence of 5: v0.3's own plan predates its checkpoint machinery, so this is the only position where a checkpoint is executable (see STATUS.md Decisions, 2026-07-31). Normal cadence applies from v0.4. Depends lists the span's leaf tasks, which transitively cover all of TASK-025..038 plus TASK-047 (added in a later planning pass the same day — the guard hooks are part of v0.3's unattended-execution machinery and must be reviewed in the same checkpoint, not deferred to v0.4).

## [TASK-039] End-to-end validation of v0.3 pipeline

- **Status:** pending
- **Type:** investigate
- **Depends:** TASK-046
- **Context:** CONTRACT#interfaces/command-forge-spec, CONTRACT#rules/workplan-lint, CONTRACT#rules/checkpoint-cadence, CONTRACT#rules/unattended-execution, CONTRACT#rules/spec-precedence
- **Gate:** `manual: In a scratch project: (1) forge-init creates SPEC.md, STATUS.md, checkpoint.md, both check scripts, and VERSION without overwriting; (2) forge-spec runs an intake interview and produces a spec that passes check-spec.js with open questions logged to STATUS.md; (3) forge-plan emits SPEC# manifests and a checkpoint task, and check-workplan.js passes; (4) forge-next resolves SPEC# refs and executes a checkpoint with a complete review packet; (5) forge-status surfaces STATUS.md items; (6) simulate a 2-3 task unattended span on a work branch honoring the hard stops`
- **Notes:**

## [TASK-040] Update README and CLAUDE.md for v0.3

- **Status:** pending
- **Type:** scaffold
- **Depends:** TASK-039
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
