# TASK-072 — Anchor forge script roots to the script location, not the shell cwd

## Outcome

Entry scripts (wp.js, check-workplan.js, migrate-notes.js, check-ux-spec.js) now resolve the project root through a shared `findRoot()` in lib/markdown.js: the nearest ancestor of the working directory containing `.forge/`, falling back to the installation root when no ancestor qualifies. Invoking from a subdirectory now finds the right project; invoking from the repo root behaves as before.

## Decisions

- **Walk-up resolution instead of the note's `path.resolve(__dirname, '..', '..')`.** The literal suggestion would have broken all four test suites, which run this repo's live scripts with `cd "$TMPDIR"` and rely on cwd selecting the fixture project. Walking up (git's own model) fixes the subdirectory failure, keeps cwd-based project targeting, and left every existing fixture untouched — strictly dominating both the bare `__dirname` anchor and the note's `--root` flag alternative, which would have required threading a flag through every harness.
- **`findRoot` lives in lib/markdown.js** — the only lib module three of the four entry scripts already require; migrate-notes.js gained the one-line require.
- Fallback to the installation root covers absolute-path invocation from outside any project.

## Deviations

- The task notes prescribed `__dirname` anchoring; implemented cwd-walk-up with `__dirname` fallback for the reason above. The gate's `(cd .forge/scripts && ...)` clause passes under both, but only walk-up keeps the fixture harnesses working.

## Files

- `.forge/scripts/lib/markdown.js` — findRoot() added and exported
- `.forge/scripts/wp.js`, `.forge/scripts/check-workplan.js`, `.forge/scripts/migrate-notes.js`, `.forge/scripts/check-ux-spec.js` — ROOT/uxPath via findRoot()
- `.claude/commands/forge-init.md` — four payloads re-copied (check-ux-spec.js's block is not markered until TASK-078, which re-copies it)
- `.forge/tests/test-wp.sh` — subdirectory and nearest-ancestor fixtures
