#!/usr/bin/env bash
# Verifies that the script payloads embedded in /forge-init are byte-identical
# to the live scripts they provision.
#
# Inlining a script into a command file creates two copies of one thing. The
# copy in forge-init.md is never executed here, so nothing else would notice it
# going stale — a new project would silently get an old lint script. Checking
# only that the filename appears in forge-init.md would pass against a payload
# three versions behind, which is why this diffs content.
#
# Each embedded block is marked in forge-init.md with:
#   <!-- forge-init:embed <path> -->
# followed by a fenced code block holding that file's exact contents.

set -e

INIT=".claude/commands/forge-init.md"
TMP="${TMPDIR:-/tmp}/forge-init-embed.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

test -s "$INIT"

# Extract the fenced block following the embed marker for $1.
extract() {
  awk -v want="$1" '
    $0 ~ /^<!-- forge-init:embed / {
      path = $3
      armed = (path == want)
      next
    }
    armed && /^```/ { infence = !infence; if (!infence) exit; next }
    armed && infence { print }
  ' "$INIT"
}

check() {
  local path="$1"
  echo "  checking $path"

  test -s "$path" || { echo "FAIL: $path does not exist in this project"; exit 1; }

  grep -q "^<!-- forge-init:embed $path -->\$" "$INIT" || {
    echo "FAIL: $INIT has no embed marker for $path"
    echo "      expected a line: <!-- forge-init:embed $path -->"
    exit 1
  }

  extract "$path" | tr -d '\r' > "$TMP/embedded"
  tr -d '\r' < "$path" > "$TMP/actual"

  test -s "$TMP/embedded" || { echo "FAIL: embedded block for $path is empty"; exit 1; }

  if ! diff -q "$TMP/actual" "$TMP/embedded" >/dev/null; then
    echo "FAIL: embedded copy of $path has drifted from the live file."
    echo "      Re-copy the file into its fenced block in $INIT."
    diff -u "$TMP/actual" "$TMP/embedded" | head -30
    exit 1
  fi
}

echo "Checking embedded script payloads in $INIT..."
check ".forge/scripts/lib/markdown.js"
check ".forge/scripts/lib/workplan.js"
check ".forge/scripts/check-workplan.js"
check ".forge/scripts/wp.js"
check ".forge/scripts/check-spec.js"
check ".forge/scripts/prose.js"
check ".forge/scripts/migrate-notes.js"
check ".forge/scripts/guard-push.sh"
check ".forge/scripts/guard-branch.sh"
check ".forge/scripts/guard-secrets.sh"

# check-ux-spec.js is conditional on the init-time interface question, so the
# check is gated on the live file rather than hardcoded into the list above —
# a project that answered "no" has neither the file nor the payload, and that
# is not drift (TASK-078).
if [ -s ".forge/scripts/check-ux-spec.js" ]; then
  check ".forge/scripts/check-ux-spec.js"
fi

# The provisioning steps must also be reachable: unconditional, and creating the
# lib/ subdirectory that markdown.js lives in.
grep -q "lib" "$INIT" || { echo "FAIL: $INIT never mentions the lib/ subdirectory"; exit 1; }

echo "  embedded payloads match the live scripts."
