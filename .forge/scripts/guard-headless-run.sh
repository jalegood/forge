#!/bin/sh
# guard-headless-run.sh — circuit breakers for the v0.3-headless unattended
# run, installed as .git/hooks/pre-commit. Policy: .forge/HEADLESS-RUN.md.
#
# Armed only by FORGE_UNATTENDED=1, the same convention as guard-branch.sh:
# interactive commits outside the run are untouched. Git's pre-commit contract
# blocks on any nonzero exit; the human bypass is `git commit --no-verify`,
# which the agent never passes.
#
# Experiment-scoped: delete alongside .git/hooks/pre-commit when the branch
# merges.

set -u

[ "${FORGE_UNATTENDED:-}" = "1" ] || exit 0

fail() {
  printf 'Blocked by guard-headless-run.sh: %s\n' "$1" >&2
  exit 1
}

# 1. Branch pin — this run commits to exactly one branch.
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[ "$branch" = "v0.3-headless" ] || \
  fail "unattended commit on '$branch'; the run is pinned to v0.3-headless (HEADLESS-RUN.md breaker 1)"

# 2. Vision lock — Vision changes are proposals to the human, never commits.
if git diff --cached --name-only | grep -q '^\.forge/VISION\.md$'; then
  fail "staged diff touches .forge/VISION.md; Vision changes are proposed, not made (HEADLESS-RUN.md breaker 2)"
fi

# 3. Task ceiling — the run charter's formula, verbatim.
count=$(git log --oneline | grep -c '(TASK-')
[ "$count" -lt 100 ] || \
  fail "task-commit ceiling reached ($count >= 100); the run stops and reports (HEADLESS-RUN.md breaker 3)"

# 4. Workplan lint.
node .forge/scripts/check-workplan.js >/dev/null 2>&1 || \
  fail "check-workplan.js rejects WORKPLAN.md (HEADLESS-RUN.md breaker 4)"

# 5. Status lint — armed the moment the script exists.
if [ -f .forge/scripts/check-status.js ]; then
  node .forge/scripts/check-status.js >/dev/null 2>&1 || \
    fail "check-status.js rejects STATUS.md (HEADLESS-RUN.md breaker 5)"
fi

# 6. Test suite — the regression breaker. FORGE_UNATTENDED is unset so the
# armed session env does not leak into test fixtures; the guard tests set the
# flag explicitly per case.
for t in .forge/tests/smoke.sh .forge/tests/test-*.sh; do
  [ -f "$t" ] || continue
  env -u FORGE_UNATTENDED bash "$t" >/dev/null 2>&1 || \
    fail "test suite red: $t (HEADLESS-RUN.md breaker 6)"
done

# 7. Secret scan over staged added lines — same floor as guard-secrets.sh.
added=$(git diff --cached --unified=0 2>/dev/null | grep -E '^\+' | grep -Ev '^\+\+\+' || true)
if [ -n "$added" ]; then
  if printf '%s\n' "$added" | grep -Eq -- '(AKIA|ASIA)[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36}|xox[abprs]-[0-9A-Za-z-]{10,}|sk_live_[0-9A-Za-z]{16,}|sk-ant-[A-Za-z0-9_-]{24,}|AIza[0-9A-Za-z_-]{35}'; then
    fail "staged diff matches a secret pattern (HEADLESS-RUN.md breaker 7)"
  fi
fi

exit 0
