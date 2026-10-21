#!/usr/bin/env bash
# SessionStart: re-inject the stack profile so it survives /clear and compaction.
root="${CLAUDE_PROJECT_DIR:-$PWD}"

echo "Interview kit active. Rules: CLAUDE.local.md. Skills: kit-recon, feature, ds-tokens, ds-component, storybook, figma-to-code, api-layer, state-management, forms, testing, monorepo, tooling, nextjs, checkpoint, ship. Agents: git-flow, reviewer, test-writer, tooling-engineer."

if [ -f "$root/.claude/STACK.md" ]; then
  echo
  echo "--- .claude/STACK.md ---"
  cat "$root/.claude/STACK.md"
else
  echo "No .claude/STACK.md yet: run the kit-recon skill before writing code."
fi

if [ -f "$root/.claude/.kit-state/typecheck-off" ]; then
  echo "(Stop-hook typecheck is OFF: delete .claude/.kit-state/typecheck-off to re-enable.)"
fi
exit 0
