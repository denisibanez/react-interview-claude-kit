#!/usr/bin/env bash
# Stop: typecheck only the packages that own changed .ts/.tsx files, and only report errors
# located in those changed files (pre-existing errors elsewhere are not Claude's problem).
# Disable with: touch .claude/.kit-state/typecheck-off
set -uo pipefail
input=$(cat)
[ "$(jq -r '.stop_hook_active // false' <<<"$input")" = "true" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$root" || exit 0
state="$root/.claude/.kit-state"
mkdir -p "$state"
[ -f "$state/typecheck-off" ] && exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

changed=$(git status --porcelain --untracked-files=all \
  | sed -E 's/^.. //; s/.* -> //' \
  | grep -E '\.(ts|tsx|mts|cts)$' | grep -vE '^\.claude/|\.d\.ts$' || true)
[ -z "$changed" ] && exit 0

sig=$({ echo "$changed"; for f in $changed; do [ -f "$f" ] && cat "$f"; done; } | shasum | cut -d' ' -f1)
[ -f "$state/typecheck.ok" ] && [ "$(cat "$state/typecheck.ok")" = "$sig" ] && exit 0

pm=npm
[ -f pnpm-lock.yaml ] && pm=pnpm
[ -f yarn.lock ] && pm=yarn

find_bin() { # <start dir> <bin>
  local d="$1"
  while :; do
    [ -x "$d/node_modules/.bin/$2" ] && { echo "$d/node_modules/.bin/$2"; return; }
    [ "$d" = "." ] || [ "$d" = "/" ] && return
    d=$(dirname "$d")
  done
}

pkgs=$(for f in $changed; do
  d=$(dirname "$f")
  while [ "$d" != "." ] && [ ! -f "$d/tsconfig.json" ]; do d=$(dirname "$d"); done
  echo "$d"
done | sort -u)

report=""
for p in $pkgs; do
  [ -f "$p/tsconfig.json" ] || continue
  script=""
  [ -f "$p/package.json" ] && script=$(jq -r '(.scripts // {}) | keys[] | select(test("^(typecheck|type-check|check-types|types|tsc)$"))' "$p/package.json" | head -1)
  if [ -n "$script" ]; then
    out=$(cd "$p" && $pm run -s "$script" 2>&1)
  else
    tsc=$(find_bin "$p" tsc)
    [ -z "$tsc" ] && continue
    if jq -e '(.references | length > 0) and ((.files // ["x"]) | length == 0)' "$p/tsconfig.json" >/dev/null 2>&1; then
      out=$(cd "$p" && "$tsc" -b --pretty false 2>&1)
    else
      out=$(cd "$p" && "$tsc" --noEmit --pretty false -p . 2>&1)
    fi
  fi
  # keep only errors that point at files changed in this session (paths are relative to the package)
  patterns=""
  for f in $changed; do
    if [ "$p" = "." ]; then
      patterns+="$f"$'\n'
    elif [ "${f#"$p"/}" != "$f" ]; then
      patterns+="${f#"$p"/}"$'\n'
    fi
  done
  patterns=$(printf '%s' "$patterns" | sed '/^$/d')
  [ -z "$patterns" ] && continue
  errs=$(grep -E 'error TS[0-9]+' <<<"$out" | grep -F -f <(echo "$patterns") | head -30)
  [ -n "$errs" ] && report+="[$p]"$'\n'"$errs"$'\n'
done

if [ -n "$report" ]; then
  {
    echo "Interview-kit typecheck: errors in files you changed. Fix them before finishing:"
    printf '%s' "$report"
  } >&2
  exit 2
fi
echo "$sig" >"$state/typecheck.ok"
exit 0
