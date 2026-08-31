#!/usr/bin/env bash
# hook-status-lint.sh — PostToolUse hook: validate .forge/STATUS.md after any
# edit that touches it (CONTRACT#rules/status-lint,
# CONTRACT#boundaries/hook-configuration).
#
# STATUS.md is the artifact this Contract most explicitly invites the human to
# hand-edit, and the only one whose malformed rows are read by a mechanical
# hard stop — so it is the artifact where an edit-time check pays for itself
# most. Catching a bad edit at the moment it is made beats catching it at the
# next command, when the session that made it is gone.
#
# This is a wrapper, not a second lint: check-status.js keeps its own exit
# codes (CONTRACT#interfaces/script-exit-codes — 0 success, 1 validation
# failure) and this translates. Claude Code's hook contract blocks on exit 2
# and treats every other nonzero exit as a non-blocking error, so a wrapper
# that passed the script's exit 1 straight through would report a malformed
# table and prevent nothing.

set -u

payload=$(cat)

# Only STATUS.md is this hook's business. The path is read from the PostToolUse
# stdin contract; a payload we cannot parse is not an error worth blocking on,
# because the tool call has already run and the next command's lint still
# catches the file.
file=$(printf '%s' "$payload" | node -e 'let s="";process.stdin.on("data",d=>{s+=d}).on("end",()=>{try{const j=JSON.parse(s);const p=(j&&j.tool_input&&(j.tool_input.file_path||j.tool_input.path))||"";process.stdout.write(String(p));}catch(e){}});' 2>/dev/null)

case "$file" in
  *STATUS.md) ;;
  *) exit 0 ;;
esac

# check-status.js is resolved next to this script, not through the shell's cwd
# (the TASK-072 lesson): a hook fires from whatever directory the tool call ran
# in. The script then finds the project itself by walking up to the nearest
# .forge, so it lints the STATUS.md that was actually edited.
here=$(cd "$(dirname "$0")" && pwd)
out=$(node "$here/check-status.js" 2>&1)
rc=$?

if [ "$rc" -ne 0 ]; then
  cat >&2 <<MSG
Blocked by hook-status-lint.sh: .forge/STATUS.md failed the status lint.

$out

CONTRACT#rules/status-lint. A malformed row is not a dropped row — at
foundation severity it disables the pipeline's one mechanical hard stop while
every report shows a clear queue. Fix the rows above, or write through
.forge/scripts/obs.js, which validates before its write stands.
MSG
  exit 2
fi

exit 0
