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

## [TASK-014] End-to-end validation of forge-init entry point

- **Status:** pending
- **Type:** investigate
- **Depends:** TASK-012, TASK-013, TASK-014
- **Context:** CONTRACT#interfaces/command-forge-init, CONTRACT#interfaces/command-forge-plan, CONTRACT#interfaces/command-forge-next, CONTRACT#state-machines/session-lifecycle
- **Gate:** `manual: Simulate a fresh project setup: (1) verify forge-init creates all expected files without overwriting existing ones, (2) verify forge-plan runs lean (no scaffold output), (3) verify forge-next fails fast with a clear message if templates are missing, (4) run one full task through the pipeline to confirm the new entry point works end to end`
- **Notes:**

## [TASK-015] End-to-end manual validation of enhanced workflow

- **Status:** pending
- **Type:** investigate
- **Depends:** TASK-008, TASK-009, TASK-010
- **Context:** CONTRACT#state-machines/session-lifecycle, CONTRACT#rules/session-boundary-protocol, CONTRACT#rules/test-first-convention, CONTRACT#rules/traceability
- **Gate:** `manual: Complete 2-3 tasks through the full /forge-next → review → commit → /clear cycle. Verify: (1) feature/fix templates prompt test-first ordering, (2) completed task Notes contain a Files: line, (3) suggested commit message ends with (TASK-XXX)`
- **Notes:**
