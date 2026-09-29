#!/usr/bin/env bash
# guard-push.sh — PreToolUse hook: block `git push`, unconditionally.
#
# CONTRACT#rules/unattended-execution rule 3: "No pushing. Publishing is always
# human." CONTRACT#boundaries/hook-configuration makes this guard always active
# — it is not gated on FORGE_UNATTENDED, because the rule it enforces is not
# either. An interactive session has a human at the keyboard who can lift the
# hook deliberately; what must not exist is a path where publishing happens
# because nobody remembered it shouldn't.
#
# Reads Claude Code's PreToolUse stdin contract (JSON, `tool_input.command`) and
# exits 2 to block. Exit 2 specifically: Claude Code treats 2 as "block the call
# and feed stderr back to the model", and any other nonzero as a non-blocking
# error that lets the tool run anyway.

set -u

payload=$(cat)

# Prefer the parsed command. If the envelope is unparseable, fall back to the
# raw payload as the haystack rather than allowing the call: a guard that opens
# the gate whenever it cannot read the request is defeatable by anything that
# perturbs the envelope.
command=$(printf '%s' "$payload" | node -e 'let s="";process.stdin.on("data",d=>{s+=d}).on("end",()=>{try{const j=JSON.parse(s);const c=j&&j.tool_input&&j.tool_input.command;if(typeof c==="string")process.stdout.write(c);}catch(e){}});' 2>/dev/null)
[ -n "$command" ] || command="$payload"

# `git push`, allowing global flags in between (`git -C dir push`, `git
# --no-pager push`). The trailing boundary is what keeps `git pushed` and
# `pushState` from matching — a substring test would block prose about pushing.
if printf '%s\n' "$command" | grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+push([[:space:]]|$)'; then
  cat >&2 <<'MSG'
Blocked by guard-push.sh: publishing is human-only.

CONTRACT#rules/unattended-execution rule 3 — "No pushing. Publishing is always
human." This guard is unconditional: unlike the branch and secret guards, it is
active in ordinary interactive sessions too, not only unattended ones.

If you are an agent: commit the work and hand it to the human to push.

If you are a human and meant to push: this hook only sees Claude Code's Bash
tool, so run the same command from a terminal outside Claude Code and it will
go through. To opt out permanently, remove the guard-push.sh entry from
.claude/settings.json.
MSG
  exit 2
fi

exit 0
