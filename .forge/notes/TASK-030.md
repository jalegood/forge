# TASK-030 — Create check-spec.js spec readiness gate script

## Outcome

Added `.forge/scripts/check-spec.js`, the deterministic spec readiness gate referenced in CONTRACT#interfaces/command-forge-spec and CONTRACT#data-model/artifacts (Spec Gate row). It validates a spec file passed as its first argument: required top-level sections present (`## Overview`, `## Requirements`, `## Non-Goals`), at least one requirement with an "Acceptance criteria" line followed by a real bullet, no requirement that is empty/HTML-comment-only or contains literal TODO/TBD text, and no `<!-- UNRESOLVED` markers beyond an allowed threshold (default 0, overridable with `--max-unresolved N`). Added `.forge/tests/test-check-spec.sh` with seven fixtures plus a real-instance assertion against `.forge/SPEC.md` (from TASK-048), all passing.

## Decisions

- Consumed `.forge/scripts/lib/markdown.js` (`parseHeadings`, `findHeading`, `sectionRange`, `normalizeSlug`) rather than writing a fourth section-scanning implementation, per TASK-050's notes flagging check-spec.js as the anticipated third/fourth duplicate.
- Modeled the acceptance-criteria check on the real SPEC.md's convention — a plain `Acceptance criteria:` line followed by a `-`/`*` bullet list — rather than requiring a specific heading level, since the Contract's SPEC Data Model shows it as body prose under the requirement, not a sub-heading.
- Treated "no placeholder/TODO text in Requirements" as a per-requirement check distinct from the acceptance-criteria check, even though an HTML-comment-only stub requirement fails both: the separate check gives a specific "empty or placeholder-only" / "contains TODO/TBD" error rather than only the generic "no requirement has acceptance criteria" message.
- Added an undocumented `--max-unresolved N` flag rather than hard-coding zero, since the task's own Notes field phrased the default as "zero blocking" (implying the threshold is a parameter with a default, not a fixed constant).

## Deviations

None — behavior matches the task's Notes description and mirrors check-ux-spec.js's structure (lib/markdown.js usage, fixture-file test style, stderr error list format, exit codes).

## Files

- .forge/scripts/check-spec.js
- .forge/tests/test-check-spec.sh
- .forge/WORKPLAN.md
