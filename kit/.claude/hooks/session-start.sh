#!/usr/bin/env bash
# SessionStart: re-inject the stack profile so it survives /clear and compaction.
root="${CLAUDE_PROJECT_DIR:-$PWD}"

# Skills/agents are already listed to Claude by Claude Code itself; don't repeat them here.
echo "Interview kit active. Rules: CLAUDE.local.md. Start each challenge item with the feature skill."

if [ -f "$root/.kit/STACK.md" ]; then
  echo
  echo "--- .kit/STACK.md ---"
  cat "$root/.kit/STACK.md"
else
  echo "No .kit/STACK.md yet: run the kit-recon skill before writing code."
fi

if [ -f "$root/.claude/.kit-state/typecheck-off" ]; then
  echo "(Stop-hook typecheck is OFF: delete .claude/.kit-state/typecheck-off to re-enable.)"
fi
if [ -f "$root/.claude/.kit-state/guards-off" ]; then
  echo "(Post-edit smell report is OFF: delete .claude/.kit-state/guards-off to re-enable.)"
fi
exit 0
