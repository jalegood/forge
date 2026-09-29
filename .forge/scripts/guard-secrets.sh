#!/usr/bin/env bash
# guard-secrets.sh — PreToolUse hook: block `git commit` when the staged diff
# adds a line matching a conservative secret pattern.
#
# CONTRACT#boundaries/hook-configuration: "A floor, not a substitute for a
# dedicated scanner." The pattern list is deliberately limited to the three
# classes the Contract names — cloud access keys, private-key headers, common
# API-key prefixes — all of which have distinctive fixed prefixes and fixed
# lengths. Generic `password =` style heuristics are excluded on purpose: a
# guard that cries wolf on ordinary code gets disabled, and a disabled guard
# catches nothing.
#
# Scope is the *added* lines of the *staged* diff. Unstaged content is not about
# to be committed, and deleting a line that contains a key is the fix, not the
# offense.
#
# Reads Claude Code's PreToolUse stdin contract (JSON, `tool_input.command`) and
# exits 2 to block — Claude Code treats 2 as "block and show stderr to the
# model", and any other nonzero as a non-blocking error.

set -u

payload=$(cat)

command=$(printf '%s' "$payload" | node -e 'let s="";process.stdin.on("data",d=>{s+=d}).on("end",()=>{try{const j=JSON.parse(s);const c=j&&j.tool_input&&j.tool_input.command;if(typeof c==="string")process.stdout.write(c);}catch(e){}});' 2>/dev/null)
[ -n "$command" ] || command="$payload"

printf '%s\n' "$command" | grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)' || exit 0

# Both greps take -E deliberately: in a basic regular expression GNU grep reads
# `\+` as the repetition operator, so `grep -v '^\+\+\+'` silently discards
# every line and the guard sees an empty diff.
added=$(git diff --cached --unified=0 2>/dev/null | grep -E '^\+' | grep -Ev '^\+\+\+')
[ -n "$added" ] || exit 0

# Each entry is "label|ERE". Anchored prefixes with length constraints, so a
# variable merely named `aws_key` does not trip anything.
patterns='cloud access key (AWS)|(AKIA|ASIA)[0-9A-Z]{16}
private key header|-----BEGIN [A-Z ]*PRIVATE KEY-----
GitHub token|gh[pousr]_[A-Za-z0-9]{36}
Slack token|xox[abprs]-[0-9A-Za-z-]{10,}
Stripe live key|sk_live_[0-9A-Za-z]{16,}
Anthropic API key|sk-ant-[A-Za-z0-9_-]{24,}
Google API key|AIza[0-9A-Za-z_-]{35}'

hits=""
while IFS='|' read -r label regex; do
  [ -n "$regex" ] || continue
  if printf '%s\n' "$added" | grep -Eq -- "$regex"; then
    hits="${hits}  - ${label}
"
  fi
done <<EOF
$patterns
EOF

if [ -n "$hits" ]; then
  cat >&2 <<MSG
Blocked by guard-secrets.sh: the staged diff adds what looks like a secret.

Matched:
${hits}
Unstage the offending lines and move the value to an environment variable or an
ignored file, then commit again. This guard is a floor, not a scanner — if it
fired on a false positive, the value still deserves a second look before it
enters history.
MSG
  exit 2
fi

exit 0
