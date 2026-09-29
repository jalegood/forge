# TASK-065 — Restore requirement-slug matching in the shared markdown resolver

## Outcome

`headingCompact` in `.forge/scripts/lib/markdown.js` now compacts a heading that opens with a bracketed token to that token alone, so `### [req-login] User Login` matches the reference segment `req-login`. Before the fix, the whole heading text was compacted, so no `SPEC#requirements/req-*` reference could resolve — and because check-workplan.js invariant 5 turns an unresolvable reference into a hard error, the SPEC manifest rule that `/forge-plan` step 5 mandates could not be satisfied by any task. The rule now has a test file (`.forge/tests/test-markdown.sh`, 11 checks) where it previously had none, and the TASK-035 and TASK-037 manifests carry real `SPEC#requirements/req-*` references, which is the end-to-end proof the resolution path works.

The regression's root cause was a Contract gap rather than a coding slip: Data Model/Context Manifest listed the reference form but never stated the matching rule, so TASK-050's extraction of the resolver from its two callers dropped a rule that was never written down. The Contract text was closed on 2026-08-16 and is what this task implements.

## Decisions

- **Matched on the bracket, not on the filename.** The fix is in `headingCompact` and applies to any document. Special-casing SPEC.md would have missed per-feature spec files under `.forge/specs/`, which carry the same requirement headings; a test asserts the rule fires for a `specs/…#` reference.
- **A bracketed heading matches its slug and nothing else.** `SPEC#requirements/req-login-user-login` (slug plus compacted name) deliberately does *not* resolve. Allowing it would let a manifest reference resolve today and silently break the next time the requirement's prose name is edited, which is the exact failure the rule exists to prevent. There is a test pinning this direction too.
- **Fixed both copies of the resolver.** `.claude/commands/forge-init.md` embeds `lib/markdown.js` verbatim as an init payload; leaving it stale would have shipped the broken resolver to every newly initialized project. `test-init-scripts.sh` diffs the two and passes.
- **Wired `test-markdown.sh` into `smoke.sh`.** The resolver backs check-workplan.js invariant 5, check-ux-spec.js, and `/forge-next`'s manifest resolution — a silent regression there invalidates every manifest at once. This follows the precedent already set for `prose.js`. A test nothing runs would not have caught this bug either.
- **Left `resolveRef`'s dropped `segment` field alone.** `resolveSegments` returns the failing segment but `resolveRef` discards it when it rewraps the reason string. A draft test asserted on it; the assertion was rewritten to check the reason text instead rather than widen a `fix` task's blast radius. The reason string still names the segment, so no diagnostic information is lost today.

## Deviations

None from the Contract. Two things worth recording that are outside this task's scope:

- **`test-prose.sh` fails at HEAD, independent of this change** (verified by stashing all work and re-running). Its final live-case assertion requires that `.claude/commands/forge-init.md` does *not* instruct STATUS.md creation, and TASK-031 (commit f7d4e60) made it do exactly that. The assertion even says "update TASK-031 and this test together"; TASK-031 landed without doing so. Because `smoke.sh` runs `test-prose.sh`, `smoke.sh` is red, and the nine pending tasks gated on it all inherit the failure. Filed as TASK-066, inserted ahead of TASK-053 so it precedes every affected task in file order, with Depends edges added from TASK-033/034/036/037/049/051/053/054/055. It is now the next unblocked task.
- **`findHeading`'s `prefix` option builds its regex in a template literal** — `` `^${prefix}:\s*` `` — where `\s` degrades to a literal `s`, producing `/^Screen:s*/`. It is benign only because `s*` matches empty, so the intended prefix check still passes; the whitespace requirement is simply not enforced. Not touched here (out of scope for a minimal fix), but it is a latent trap for anyone who later tightens that option.

## Files

- `.forge/scripts/lib/markdown.js` — bracketed-heading rule in `headingCompact`
- `.claude/commands/forge-init.md` — same change in the embedded payload copy
- `.forge/tests/test-markdown.sh` — new; 11 checks over the resolver
- `.forge/tests/smoke.sh` — runs the new test
- `.forge/WORKPLAN.md` — TASK-035 and TASK-037 manifests widened with `SPEC#requirements/req-*` references; TASK-065 status
