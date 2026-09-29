# Spec

<!-- Forge's own behavioral specification. Scope: the acceptance-criteria layer only — what "good" looks like for the v0.3 behaviors CONTRACT.md structurally cannot express as invariants. Constraints, interfaces, data shapes, and state machines live in CONTRACT.md (Rules/Spec Precedence); this file references them by name and never restates them. Single file for now; split into .forge/specs/ at ~300 lines (STATUS.md Q-003 tracks the threshold). -->

## Overview

Forge is a contract-first execution pipeline for Claude Code: a human owns VISION.md and CONTRACT.md, planning produces a task DAG in WORKPLAN.md, and `/forge-next` executes one manifest-scoped task per session. The Contract pins down the pipeline's hard constraints, but it cannot express quality bars: what makes a `/forge-spec` intake interview good enough to draft from, what a checkpoint review packet must show before a human can confidently pass a span, and what an unattended span must look like from the operator's seat. This spec states those acceptance criteria so the tasks that build them (`/forge-spec`, the checkpoint machinery, the unattended guards) are built against explicit bars rather than inferred ones.

## Requirements

### [req-intake-coverage] Adaptive intake interview coverage

WHEN `/forge-spec` receives planning input, THE SYSTEM SHALL cover every intake category — target user, success criteria, edge cases, integration points, non-goals — before drafting, asking a question for a category only when the input does not already answer it.

Acceptance criteria:

- Each of the five categories is resolved by exactly one of: an interview answer, or a specific passage of the input. A general impression of the input does not resolve a category.
- A category the input already answers is not re-asked. Ceremony questions whose answers are verbatim in the input are a defect, not diligence.
- Drafting begins only after every category is either resolved or explicitly carried as an unresolved unknown per Interfaces/Command: `/forge-spec` (annotated, with a STATUS.md Open Questions row).

### [req-intake-disqualification] Draft disqualification

WHEN drafting completes and any plan-blocking unknown was neither asked about during the interview nor annotated, THE SYSTEM SHALL withhold the draft and resume the interview instead of presenting it.

Acceptance criteria:

- A plan-blocking unknown — one whose answer changes task structure, per `/forge-plan`'s plan-blocking vs implementation-detail classification — with no interview question and no annotation disqualifies the draft.
- Implementation-detail unknowns never disqualify a draft; they carry `<!-- ASSUMED: reason -->` annotations per Interfaces/Command: `/forge-spec`.
- A disqualified draft is never presented as complete, and its unasked questions are asked before a second draft.

### [req-checkpoint-fresh-gates] Fresh gate evidence at checkpoint

WHEN a checkpoint review packet is assembled, THE SYSTEM SHALL re-run every automated gate in the span and report the fresh results, flagging any gate that fails fresh on a task whose status is `done`.

Acceptance criteria:

- Gates are re-run at packet-assembly time; the span's task statuses alone are insufficient evidence, because a later task in the span can silently break an earlier task's gate.
- The completion-time baseline is the one implied by task status, not a stored value. `/forge-next` marks a task `done` only after its gate passes (Interfaces/Command: `/forge-next`), so `done` *is* the record that the gate passed at completion. Nothing stores gate results, and nothing needs to: an artifact `check-workplan.js` already validates is a stronger baseline than a hand-written result line that can drift from what actually ran.
- A regression — a gate failing fresh on a `done` task — is explicitly flagged; the packet never summarizes a span containing a regression as clean.
- Each automated gate is reported with its actual output, not a bare pass/fail — the packet is the mitigation for the weak-gate amplification risk in STATUS.md Risks. Output *drift* on a still-passing gate is not mechanically flagged; reporting the output is what puts it in front of the human.
- `manual:` gates in the span are listed with their verification steps, not executed.

### [req-checkpoint-self-contained] Self-contained review packet

WHEN a checkpoint task executes, THE SYSTEM SHALL present a review packet the human can judge without opening any other file.

Acceptance criteria:

- The packet contains everything Rules/Checkpoint Cadence enumerates: span tasks with descriptions and each task's file list (its `Files` line, or its record's `## Files` section when the record was externalized), gate results, manual verification steps, and the current STATUS.md Open Questions and Risks.
- The packet additionally embeds open STATUS.md Observations rows (`foundation` severity first) and any mid-span course-correction Decisions rows (see [req-unattended-correction]).
- The packet names the span's starting commit and the exact single rollback command.
- The packet ends with an explicit pass/fail question and execution stops until the human answers — an unanswered packet blocks all downstream tasks by construction.

### [req-unattended-halt-state] Legible halt state

WHEN an unattended span halts — at a hard stop per Rules/Unattended Execution, or by exhausting unblocked tasks — THE SYSTEM SHALL leave a state the operator can reconstruct from the artifacts alone: what ran, what halted it, and where to look next.

Acceptance criteria:

- Every task completed in the span has one commit ending `(TASK-XXX)`, status `done`, and a recorded file list per Rules/Traceability — inline as a `Files` line, or in its record's `## Files` section.
- The halting condition is recorded in the artifact its type dictates: a blocked task in workplan Notes plus a STATUS.md Blockers row; a `foundation` observation in STATUS.md Observations; a second consecutive gate failure in the still-`active` task's Notes.
- Uncommitted partial work from a halting task is left in the working tree and named in that task's Notes — never silently discarded.
- No push occurred during the span (Rules/Unattended Execution; enforced by the push guard in Boundaries/Hook Configuration).

### [req-unattended-correction] Course correction with a record

WHEN the loop is relaunched after the operator has halted it and edited WORKPLAN.md or STATUS.md to redirect work, THE SYSTEM SHALL proceed from the edited state without re-planning, and the span's checkpoint packet SHALL surface the correction's STATUS.md Decisions row.

Acceptance criteria:

- Direct edits to project-owned artifacts are the correction mechanism — no dedicated command or approval flow is required mid-span.
- Every correction leaves a dated STATUS.md Decisions row (what changed, why) before relaunch; the row is the reviewable trace of the redirect.
- The first WORKPLAN.md write after relaunch re-validates via `check-workplan.js` per Rules/Workplan Lint, so a correction that broke a workplan invariant halts the loop instead of propagating.
- A correction without a Decisions row is a checkpoint review finding, not an invisible event.

## Flows

**Spec intake** ([req-intake-coverage], [req-intake-disqualification]): raw input → adaptive interview until all five categories resolve → draft with `ASSUMED`/`UNRESOLVED` annotations → `check-spec.js` structural pass → disqualification check → human review before `/forge-plan` consumes it.

**Unattended span, operator's seat** ([req-unattended-halt-state], [req-unattended-correction], [req-checkpoint-fresh-gates], [req-checkpoint-self-contained]):

1. Operator launches the loop on a work branch; the launcher itself sets `FORGE_UNATTENDED=1` per Boundaries/Hook Configuration.
2. The loop chains `/forge-next` sessions per State Machines/Session Lifecycle: select → resolve → execute → gate → one commit per task.
3. The span halts at a hard stop or when no unblocked task remains, leaving the state [req-unattended-halt-state] requires.
4. The operator reads the halt state (git log, `/forge-status`, STATUS.md) and either corrects course ([req-unattended-correction]) and relaunches, or proceeds to the checkpoint.
5. The checkpoint presents its packet ([req-checkpoint-fresh-gates], [req-checkpoint-self-contained]); the human passes or fails it.
6. Pass → human merge and push, per Rules/Unattended Execution. Fail → `fix` tasks, a workplan edit, or rollback to the span's named starting commit.

## Non-Goals

- **Restating the Contract.** No data shapes, interfaces, invariants, or state machines appear here. If a statement in this file would restate a constraint, the constraint belongs in CONTRACT.md and this file points to it (Rules/Spec Precedence). This section is the guard against this file growing into a CONTRACT mirror.
- **Speccing behavior the Contract already expresses.** Command Reads/Does/Outputs, workplan lint invariants, gate patterns, task lifecycle, and manifest resolution are Contract-owned and fully specified there.
- **The unattended launcher script.** Only the convention it must follow (`FORGE_UNATTENDED=1`, work branch) is contracted; building the wrapper is future work.
- **v0.4 scope decisions.** Plugin packaging (Q-001), the node-schema factory model, and `/forge-sync` mechanics beyond its Contract interface are under open investigation and deliberately unspecced.
- **UX and visual design.** Forge is a CLI pipeline with no user-facing screens; no UX.md or DESIGN.md exists for this project.
- **Tuning defaults under open questions.** Checkpoint cadence (Q-002), the spec split threshold (Q-003), and the record externalization threshold (Q-004) are inherited as current defaults, not decided here.
