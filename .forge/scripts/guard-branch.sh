#!/usr/bin/env bash
# guard-branch.sh — PreToolUse hook: during an unattended run, block `git
# commit` on the repository's default branch.
#
# CONTRACT#rules/unattended-execution rule 1: "Work branch only. Never on the
# default branch. The branch is the blast radius."
#
# The guard is armed only by FORGE_UNATTENDED=1 and is otherwise inert, so
# ordinary interactive sessions — where committing straight to main is a normal,
# human-reviewed habit on personal projects — are untouched. Per
# CONTRACT#boundaries/hook-configuration the flag is set by the headless launcher
# that drives the loop, never typed by a human before a run: a forgotten
# `export` would silently restore main-committing behavior in exactly the case
# where nobody is watching to catch it.
#
# Reads Claude Code's PreToolUse stdin contract (JSON, `tool_input.command`) and
# exits 2 to block — Claude Code treats 2 as "block and show stderr to the
# model", and any other nonzero as a non-blocking error.

set -u

payload=$(cat)

# Not an unattended run: this guard has nothing to say. Checked before anything
# else so the interactive path costs one string comparison.
[ "${FORGE_UNATTENDED:-}" = "1" ] || exit 0

command=$(printf '%s' "$payload" | node -e 'let s="";process.stdin.on("data",d=>{s+=d}).on("end",()=>{try{const j=JSON.parse(s);const c=j&&j.tool_input&&j.tool_input.command;if(typeof c==="string")process.stdout.write(c);}catch(e){}});' 2>/dev/null)
[ -n "$command" ] || command="$payload"

printf '%s\n' "$command" | grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)' || exit 0

current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
[ -n "$current" ] || exit 0

# The default branch is the repo's, not a hardcoded `main`: a project on `trunk`
# or `master` must be protected on its own branch and nowhere else. Ask the
# remote's HEAD first (authoritative where there is a remote), then the local
# init default, then fall back.
default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
[ -n "$default" ] || default=$(git config --get init.defaultBranch 2>/dev/null)
[ -n "$default" ] || default=main

if [ "$current" = "$default" ]; then
  cat >&2 <<MSG
Blocked by guard-branch.sh: unattended commit on the default branch.

FORGE_UNATTENDED=1 and HEAD is on "$current", the repository's default branch.
CONTRACT#rules/unattended-execution rule 1 — "Work branch only. Never on the
default branch. The branch is the blast radius."

Create a work branch and commit there; the span reaches "$default" only through
checkpoint approval and a human merge (rule 5).
MSG
  exit 2
fi

exit 0
