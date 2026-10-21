#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): format the file with the repo's own prettier,
# then report design-system / TypeScript / a11y smells back to Claude (exit 2).
# Only lines changed vs HEAD are checked (whole file if untracked), so legacy code doesn't flood Claude.
# Append `// kit-allow` (or `/* kit-allow */`) to a line to silence it when it is intentional.
# Light mode: `touch .claude/.kit-state/guards-off` keeps prettier but skips the smell report.
set -uo pipefail
file=$(jq -r '.tool_input.file_path // empty')
[ -n "$file" ] && [ -f "$file" ] || exit 0
root="${CLAUDE_PROJECT_DIR:-$PWD}"

case "$file" in
  */node_modules/*|*/.claude/*|*/dist/*|*/build/*|*/.next/*|*/storybook-static/*|*/coverage/*) exit 0 ;;
esac
case "$file" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.css|*.scss|*.json|*.md|*.mdx|*.yml|*.yaml) ;;
  *) exit 0 ;;
esac

# 1. Format with the repo's prettier only (a global one may be a different version = noisy diff).
dir=$(dirname "$file")
while :; do
  if [ -x "$dir/node_modules/.bin/prettier" ]; then
    "$dir/node_modules/.bin/prettier" --write --log-level silent "$file" >/dev/null 2>&1 || true
    break
  fi
  [ "$dir" = "$root" ] || [ "$dir" = "/" ] && break
  dir=$(dirname "$dir")
done

# 2. Smell checks (code + styles only).
case "$file" in
  *.json|*.md|*.mdx|*.yml|*.yaml|*.d.ts) exit 0 ;;
esac

[ -f "$root/.claude/.kit-state/guards-off" ] && exit 0

# Changed line ranges ("start-end ...") vs HEAD; empty mode=all for new/untracked files or repos without commits.
fdir=$(dirname "$file"); fbase=$(basename "$file")
mode=all; ranges=""
if git -C "$fdir" rev-parse --verify -q HEAD >/dev/null 2>&1 \
  && git -C "$fdir" ls-files --error-unmatch -- "$fbase" >/dev/null 2>&1; then
  mode=diff
  ranges=$(git -C "$fdir" diff -U0 HEAD -- "$fbase" \
    | awk '/^@@/ { split($3, a, ","); s = substr(a[1], 2); n = (a[2] == "") ? 1 : a[2]; if (n > 0) printf "%d-%d ", s, s + n - 1 }')
  [ -z "$ranges" ] && exit 0
fi
only_changed() { # filters "N:line" input to changed lines
  if [ "$mode" = all ]; then cat; else
    awk -F: -v r="$ranges" 'BEGIN { n = split(r, R, " ") }
      { for (i = 1; i <= n; i++) { split(R[i], b, "-"); if ($1 + 0 >= b[1] + 0 && $1 + 0 <= b[2] + 0) { print; next } } }'
  fi
}

issues=""
add_issue() { # <hits> <message>
  [ -n "$1" ] && issues+="• $2"$'\n'"$(sed 's/^/    L/' <<<"$1")"$'\n'
}
check() { # <extended regex> <message>
  add_issue "$(grep -nE -- "$1" "$file" | grep -v 'kit-allow' | only_changed | head -5)" "$2"
}

is_test=false
case "$file" in *.test.*|*.spec.*|*/__tests__/*|*/e2e/*|*/tests/*) is_test=true ;; esac
is_token_file=false
case "$(basename "$file" | tr '[:upper:]' '[:lower:]')" in
  *token*|*theme*|*variables*|*_vars*|*palette*|*color*|*foundation*|globals.css|global.css|tailwind.config.*|*.config.*) is_token_file=true ;;
esac

case "$file" in
  *.ts|*.tsx)
    check '(:[[:space:]]*any\b|\bas[[:space:]]+any\b|<any>|\bany\[\]|Record<string,[[:space:]]*any>)' \
      "'any' — type it (unknown + narrowing, generics, z.infer, ComponentProps<...>)."
    check '@ts-(ignore|nocheck)' "@ts-ignore/@ts-nocheck — fix the type instead."
    $is_test || check '[A-Za-z0-9_)>]![.);,]' "Non-null assertion (!) — narrow the type or validate (zod) instead."
    ;;
esac
case "$file" in
  *.ts|*.tsx|*.js|*.jsx)
    check 'eslint-disable' "eslint-disable — fix the rule violation or justify it to the user."
    $is_test || check 'console\.(log|debug)\(' "console.log left in source."
    # Architecture boundaries: packages through their public exports, features through their index.ts.
    check "from[[:space:]]+['\"]([^'\"]*/)?packages/[^/'\"]+/src/|from[[:space:]]+['\"]@[^/'\"]+/[^/'\"]+/src/" \
      "Deep import into another package's src — import from the package's public exports."
    own_feature=$(sed -nE 's|.*/features/([^/]+)/.*|\1|p' <<<"$file")
    add_issue "$(grep -nE "from[[:space:]]+['\"][^'\"]*features/[^/'\"]+/[^'\"]+['\"]" "$file" \
      | grep -vE "features/${own_feature:-__none__}/" | grep -v 'kit-allow' | only_changed | head -5)" \
      "Deep import into another feature — import it through its index.ts (or compose both in the page)."
    # Next: a client module must not read server secrets.
    if head -5 "$file" | grep -qE "^[[:space:]]*['\"]use client['\"]"; then
      add_issue "$(grep -noE 'process\.env\.[A-Z_0-9]+' "$file" | grep -vE 'process\.env\.(NEXT_PUBLIC_[A-Z_0-9]*|NODE_ENV)$' \
        | only_changed | head -5)" \
        "Server env var in a 'use client' module — it is undefined in the browser (or leaks). Read it on the server and pass data down."
      case "$file" in
        */app/*/page.tsx|*/app/page.tsx|*/app/*/layout.tsx|*/app/layout.tsx)
          add_issue "$(grep -nE "^[[:space:]]*['\"]use client['\"]" "$file" | only_changed | head -1)" \
            "'use client' on a page/layout — keep it a Server Component and push the client boundary down to the interactive leaf." ;;
      esac
    fi
    ;;
esac

if ! $is_token_file && ! $is_test; then
  case "$file" in
    *.tsx|*.jsx|*.ts|*.css|*.scss|*.sass|*.less)
      check '(^|[^&0-9A-Za-z_])#[0-9a-fA-F]{3}([0-9a-fA-F]{1}|[0-9a-fA-F]{3}|[0-9a-fA-F]{5})?\b' \
        "Hardcoded hex color — use a design token (CSS var / theme / Tailwind token class)."
      check '\b(rgba?|hsla?|oklch)\([[:space:]]*[0-9.]' \
        "Literal color function — use a design token."
      check '-\[(#|[0-9.]+(px|rem|em)\])' \
        "Tailwind arbitrary value — use the token scale (or add a token on purpose and flag it)."
      ;;
  esac
fi

case "$file" in
  *.tsx|*.jsx)
    check '<(div|span|li)[^>]*[[:space:]]onClick=' \
      "Clickable non-interactive element — use <button>/<a> (keyboard + screen reader)."
    check 'key=\{[[:space:]]*(index|i|idx)[[:space:]]*\}' "Array index used as React key — use a stable id."
    check '<img\b' "Raw <img> — check alt text (and next/image if this is Next)."
    check 'dangerouslySetInnerHTML' "dangerouslySetInnerHTML — XSS risk; sanitise (DOMPurify) or render as text/components."
    lines=$(wc -l <"$file" | tr -d ' ')
    head_lines=0
    [ "$mode" = diff ] && head_lines=$(git -C "$fdir" show "HEAD:./$fbase" 2>/dev/null | wc -l | tr -d ' ')
    # Only flag when this change pushed the file over the limit (legacy big files stay quiet).
    if ! $is_test && [ "$lines" -gt 220 ] && [ "$head_lines" -le 220 ]; then
      issues+="• File has $lines lines — split sub-components / hooks (DS team will notice)."$'\n'
    fi
    ;;
esac

if [ -n "$issues" ]; then
  {
    echo "Interview-kit quality guard on ${file#$root/}:"
    printf '%s' "$issues"
    echo "Fix these, or add '// kit-allow' on the line if intentional and tell the user why."
  } >&2
  exit 2
fi
exit 0
