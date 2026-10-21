#!/usr/bin/env bash
# PreToolUse (Bash): block destructive commands, ask before pushes and new dependencies.
set -uo pipefail
cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

decide() {
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

if grep -qE 'git[[:space:]]+push\b.*([[:space:]]--force(-with-lease)?\b|[[:space:]]-f\b)' <<<"$cmd"; then
  decide deny "Interview kit: force push is blocked."
fi
if grep -qE -- '--no-verify\b' <<<"$cmd"; then
  decide deny "Interview kit: hooks (husky/lint-staged) must run. Fix the failure instead of bypassing it."
fi
if grep -qE 'git[[:space:]]+(reset[[:space:]]+--hard|clean[[:space:]]+-[a-zA-Z]*f|checkout[[:space:]]+--[[:space:]]|restore[[:space:]]+(--staged[[:space:]]+)?\.)' <<<"$cmd"; then
  decide deny "Interview kit: destructive git command. Ask the user and let them run it."
fi
if grep -qE '\brm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[[:space:]]+(/|~|\$HOME|\*|\.\.?/?([[:space:]]|$))' <<<"$cmd"; then
  decide deny "Interview kit: broad rm -r blocked. Remove specific paths only."
fi

# Screen share safety: don't print secrets.
if grep -qE '(^|[;&|[:space:]])(printenv|env)([[:space:]]*($|[;&|]))' <<<"$cmd" \
  || grep -qE '\$\{?[A-Za-z_]*(TOKEN|SECRET|PASSWORD|API_KEY|PRIVATE_KEY)' <<<"$cmd" \
  || grep -qE '\b(cat|less|more|head|tail|bat|grep|rg)\b[^;&|]*(^|[[:space:]/])\.env(\.[A-Za-z0-9_-]+)?([[:space:]]|$)' <<<"$cmd" \
     && ! grep -qE '\.env\.(example|sample|template)\b' <<<"$cmd"; then
  decide ask "This may print secrets (env vars / .env) — risky during screen share. Confirm with the user."
fi

if grep -qE '\b(pnpm|npm|yarn|bun)\b[^;&|]*[[:space:]]add\b' <<<"$cmd" \
  || grep -qE '\b(pnpm|npm|bun)\b[^;&|]*[[:space:]](install|i)([[:space:]]+-[^[:space:]]+)*[[:space:]]+[@a-zA-Z]' <<<"$cmd"; then
  decide ask "New dependency: confirm with the user (they need to justify it in the checkpoint)."
fi
if grep -qE '\bgit[[:space:]]+push\b' <<<"$cmd"; then
  decide ask "Push: confirm with the user."
fi
if grep -qE '\bgh[[:space:]]+pr[[:space:]]+(create|merge)\b' <<<"$cmd"; then
  decide ask "PR create/merge: confirm with the user."
fi
exit 0
