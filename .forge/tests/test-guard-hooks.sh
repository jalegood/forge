#!/usr/bin/env bash
set -u

# Validates the three unattended-execution guards from
# CONTRACT#boundaries/hook-configuration:
#
#   guard-push.sh    — blocks `git push`, unconditionally
#   guard-branch.sh  — blocks `git commit` on the default branch, but only when
#                      FORGE_UNATTENDED=1 is set by the headless launcher
#   guard-secrets.sh — blocks `git commit` when the staged diff adds a line
#                      matching a conservative secret pattern
#
# CONTRACT#rules/unattended-execution rules 1 and 3 are "mechanically enforced
# by the branch guard and push guard hooks, not by instruction-following alone".
# That is the property under test: each guard is exercised through the real
# PreToolUse stdin contract (JSON with tool_input.command) and asserted on its
# exit code, because a guard that inspects the wrong field or fails open is
# indistinguishable from no guard at all — and it is the unattended run, where
# nobody is watching, that finds out.
#
# The negative cases carry as much weight as the positive ones. A branch guard
# that blocked in interactive sessions would break the personal-project workflow
# it was explicitly designed to leave alone.

PUSH="$(pwd)/.forge/scripts/guard-push.sh"
BRANCH="$(pwd)/.forge/scripts/guard-branch.sh"
SECRETS="$(pwd)/.forge/scripts/guard-secrets.sh"

ROOT="$(pwd)"
WORK=$(mktemp -d)
trap 'cd "$ROOT"; rm -rf "$WORK"' EXIT

OUT=""
RC=0

fail() { echo "FAILED: $1"; echo "--- guard output ---"; echo "$OUT"; exit 1; }

# Build a PreToolUse payload the way Claude Code delivers it. Built with node so
# that quoting inside the command survives verbatim — the guards are matched
# against real shell text, not a sanitized version of it.
hook_json() {
  printf '%s' "$1" | node -e 'let s="";process.stdin.on("data",d=>{s+=d}).on("end",()=>{process.stdout.write(JSON.stringify({session_id:"test",tool_name:"Bash",tool_input:{command:s}}))});'
}

# run <guard> <command> — feeds the payload to the guard, sets RC and OUT.
run() {
  RC=0
  OUT=$(hook_json "$2" | bash "$1" 2>&1) || RC=$?
}

# A blocked call must exit 2 specifically: Claude Code treats exit 2 as "block
# and show stderr to the model" and any other nonzero as a non-blocking error
# that lets the tool run anyway. "Nonzero" alone would not stop the commit.
blocked() { [ "$RC" = "2" ] || fail "$1 (expected exit 2, got $RC)"; }
allowed() { [ "$RC" = "0" ] || fail "$1 (expected exit 0, got $RC)"; }

for f in "$PUSH" "$BRANCH" "$SECRETS"; do
  test -s "$f" || { echo "FAILED: $f does not exist"; exit 1; }
done

echo "Checking guard-push.sh..."

run "$PUSH" 'git push'
blocked "a bare git push must be blocked"
run "$PUSH" 'git push origin v0.3'
blocked "git push with arguments must be blocked"
run "$PUSH" 'git push --force-with-lease'
blocked "a flagged git push must be blocked"
run "$PUSH" 'git -C /some/repo push'
blocked "git push behind a global flag must be blocked"
run "$PUSH" 'npm test && git push origin HEAD'
blocked "git push in a compound command must be blocked"
[ -n "$OUT" ] || fail "a blocked push must explain itself on stderr"
echo "  blocks publishing: OK"

run "$PUSH" 'git status'
allowed "git status must pass"
run "$PUSH" 'git commit -m "Implement the thing (TASK-047)"'
allowed "git commit must pass the push guard"
run "$PUSH" 'git log --oneline'
allowed "git log must pass"
# `pushed` is not `push`; a guard matching a bare substring would block prose.
run "$PUSH" 'echo "already git pushed earlier"'
allowed "a word merely containing push must not be blocked"
run "$PUSH" 'grep -r pushState src/'
allowed "an unrelated command containing push must not be blocked"
echo "  leaves everything else alone: OK"

# A payload the guard cannot parse must not become an escape hatch: the command
# text is still in there, and failing open on malformed JSON would make the
# guard defeatable by anything that perturbs the envelope.
RC=0; OUT=$(printf '%s' 'not json at all: git push origin main' | bash "$PUSH" 2>&1) || RC=$?
blocked "an unparseable payload containing git push must still be blocked"
RC=0; OUT=$(printf '%s' '{"tool_name":"Read","tool_input":{"file_path":"x"}}' | bash "$PUSH" 2>&1) || RC=$?
allowed "a payload with no command must pass"
echo "  fails closed on a malformed payload: OK"

echo "Checking guard-branch.sh..."

# A real repository, because the guard's whole job is to compare the checked-out
# branch against the repo's default branch.
REPO="$WORK/repo"
mkdir -p "$REPO"
cd "$REPO"
git init -q -b main .
git config user.email t@example.com
git config user.name Test
git config init.defaultBranch main
echo seed > seed.txt
git add seed.txt
git commit -qm seed

RC=0; OUT=$(hook_json 'git commit -m "work (TASK-001)"' | FORGE_UNATTENDED=1 bash "$BRANCH" 2>&1) || RC=$?
blocked "an unattended commit on the default branch must be blocked"
[ -n "$OUT" ] || fail "a blocked commit must explain itself on stderr"

# env -u, not bare invocation: the interactive case is "flag absent", and a
# session that exports FORGE_UNATTENDED=1 (a headless run testing itself) would
# otherwise leak its arming state into this assertion and read a correct block
# as a failure.
RC=0; OUT=$(hook_json 'git commit -m "work (TASK-001)"' | env -u FORGE_UNATTENDED bash "$BRANCH" 2>&1) || RC=$?
allowed "an interactive commit on the default branch must pass — the guard is inert without the flag"

RC=0; OUT=$(hook_json 'git commit -m "work"' | FORGE_UNATTENDED=0 bash "$BRANCH" 2>&1) || RC=$?
allowed "FORGE_UNATTENDED=0 must not arm the guard"

RC=0; OUT=$(hook_json 'git status' | FORGE_UNATTENDED=1 bash "$BRANCH" 2>&1) || RC=$?
allowed "a non-commit command on the default branch must pass"
echo "  default branch: blocks only when armed: OK"

git checkout -q -b feature/task-047

RC=0; OUT=$(hook_json 'git commit -m "work (TASK-047)"' | FORGE_UNATTENDED=1 bash "$BRANCH" 2>&1) || RC=$?
allowed "an unattended commit on a work branch must pass — this is the supported path"

RC=0; OUT=$(hook_json 'git commit -m "work (TASK-047)"' | env -u FORGE_UNATTENDED bash "$BRANCH" 2>&1) || RC=$?
allowed "an interactive commit on a work branch must pass"
echo "  work branch: never blocks: OK"

# The default branch is read from the repo, not hardcoded. A repo whose default
# branch is `trunk` must be protected there and nowhere else; a guard hardcoding
# `main` would silently protect nothing.
TRUNK="$WORK/trunk-repo"
mkdir -p "$TRUNK"
cd "$TRUNK"
git init -q -b trunk .
git config user.email t@example.com
git config user.name Test
git config init.defaultBranch trunk
echo seed > seed.txt
git add seed.txt
git commit -qm seed

RC=0; OUT=$(hook_json 'git commit -m x' | FORGE_UNATTENDED=1 bash "$BRANCH" 2>&1) || RC=$?
blocked "the repo's own default branch (trunk) must be protected"

git checkout -q -b work
RC=0; OUT=$(hook_json 'git commit -m x' | FORGE_UNATTENDED=1 bash "$BRANCH" 2>&1) || RC=$?
allowed "a work branch in a trunk-default repo must pass"
echo "  default branch resolved from the repo: OK"

cd "$ROOT"

echo "Checking guard-secrets.sh..."

SREPO="$WORK/secrets-repo"
mkdir -p "$SREPO"
cd "$SREPO"
git init -q -b main .
git config user.email t@example.com
git config user.name Test
echo seed > seed.txt
git add seed.txt
git commit -qm seed

# A clean staged diff passes.
echo 'const timeout = 30;' > app.js
git add app.js
RC=0; OUT=$(hook_json 'git commit -m "add app"' | bash "$SECRETS" 2>&1) || RC=$?
allowed "a clean staged diff must pass"
echo "  clean diff: OK"

# Each pattern class blocks. The literal strings are split across printf
# arguments so this test file is not itself scanner bait.
printf 'aws_key = "AKIA%s"\n' "IOSFODNN7EXAMPLE" >> app.js
git add app.js
RC=0; OUT=$(hook_json 'git commit -m "add app"' | bash "$SECRETS" 2>&1) || RC=$?
blocked "a staged cloud access key must be blocked"
[ -n "$OUT" ] || fail "a blocked commit must explain itself on stderr"
git reset -q

echo 'const timeout = 30;' > app.js
printf -- '-----BEGIN RSA PRIVATE %s-----\n' "KEY" >> app.js
git add app.js
RC=0; OUT=$(hook_json 'git commit -m x' | bash "$SECRETS" 2>&1) || RC=$?
blocked "a staged private-key header must be blocked"
git reset -q

echo 'const timeout = 30;' > app.js
printf 'token = "ghp_%s"\n' "0123456789abcdefghijklmnopqrstuvwxyz" >> app.js
git add app.js
RC=0; OUT=$(hook_json 'git commit -m x' | bash "$SECRETS" 2>&1) || RC=$?
blocked "a staged API-key prefix must be blocked"
git reset -q
echo "  all three pattern classes: OK"

# Only the staged diff counts. The guard runs before a commit, so an unstaged
# secret is not about to be committed; blocking on it would make the guard fire
# on scratch files.
echo 'const timeout = 30;' > app.js
git add app.js
printf 'aws_key = "AKIA%s"\n' "IOSFODNN7EXAMPLE" > scratch.txt
RC=0; OUT=$(hook_json 'git commit -m x' | bash "$SECRETS" 2>&1) || RC=$?
allowed "an unstaged secret must not block the commit"
rm -f scratch.txt
git reset -q

# Removing a secret is not adding one.
printf 'aws_key = "AKIA%s"\n' "IOSFODNN7EXAMPLE" > legacy.txt
git add legacy.txt
git commit -qm legacy
git rm -q legacy.txt
RC=0; OUT=$(hook_json 'git commit -m "remove the legacy key"' | bash "$SECRETS" 2>&1) || RC=$?
allowed "deleting a line containing a secret must not be blocked"
git reset -q --hard HEAD
echo "  scans added lines of the staged diff only: OK"

# Non-commit commands are not the secret guard's business.
printf 'aws_key = "AKIA%s"\n' "IOSFODNN7EXAMPLE" > app2.js
git add app2.js
RC=0; OUT=$(hook_json 'git status' | bash "$SECRETS" 2>&1) || RC=$?
allowed "a non-commit command must pass even with a secret staged"
echo "  scoped to git commit: OK"

cd "$ROOT"

echo "Checking settings.json wiring..."

node -e '
const fs = require("fs");
const s = JSON.parse(fs.readFileSync(".claude/settings.json", "utf8"));
const pre = (s.hooks && s.hooks.PreToolUse) || [];
const want = ["guard-push.sh", "guard-branch.sh", "guard-secrets.sh"];
for (const w of want) {
  const hit = pre.find(e => (e.hooks || []).some(h => (h.command || "").includes(w)));
  if (!hit) { console.error("FAIL: " + w + " is not wired into PreToolUse"); process.exit(1); }
  // A guard matched against the wrong tool never runs: these inspect Bash calls.
  if (!/Bash/.test(hit.matcher || "")) {
    console.error("FAIL: " + w + " is wired under matcher \"" + hit.matcher + "\" — must match Bash");
    process.exit(1);
  }
}
// The PostToolUse lint hook predates this task and must survive it.
const post = (s.hooks && s.hooks.PostToolUse) || [];
if (!post.length) { console.error("FAIL: the PostToolUse lint hook was removed"); process.exit(1); }
' || { echo "FAILED: settings.json wiring"; exit 1; }
echo "  three guards wired under Bash, lint hook intact: OK"

echo "Checking /forge-init provisions the guards..."

# CONTRACT#interfaces/command-forge-init: new projects ship the guards by
# default. Asserted through prose.js because forge-init.md fences the settings
# JSON and the script payloads — a match inside a fence would report the
# provisioning step present when only the embedded copy was.
node .forge/scripts/prose.js .claude/commands/forge-init.md \
  "guard-push\.sh" "guard-branch\.sh" "guard-secrets\.sh" || \
  { echo "FAILED: forge-init.md does not provision the three guards"; exit 1; }
node .forge/scripts/prose.js .claude/commands/forge-init.md "FORGE_UNATTENDED" || \
  { echo "FAILED: forge-init.md does not document the FORGE_UNATTENDED convention"; exit 1; }

# The embedded payloads are diffed against the live files by test-init-scripts.sh.
# Running it here is what makes this gate cover the drift, rather than asserting
# that the filenames appear somewhere.
bash .forge/tests/test-init-scripts.sh > /dev/null || \
  { echo "FAILED: embedded guard payloads have drifted from the live scripts"; exit 1; }
echo "  forge-init.md provisions and embeds the guards: OK"

echo ""
echo "All guard hook checks passed."
