#!/usr/bin/env bash
# Read-only fact sheet of a JS/TS repo, printed as markdown. Used by the kit-recon skill.
set -uo pipefail
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$root" || exit 1

files() { git ls-files --cached --others --exclude-standard 2>/dev/null || find . -type f -not -path '*/node_modules/*' | sed 's|^\./||'; }
ALL=$(files | grep -vE '(^|/)node_modules/')
pkgs=$(grep -E '(^|/)package\.json$' <<<"$ALL" | sort)

echo "# Stack facts (auto-detected in $root)"

echo; echo "## Package manager / runtime"
for f in pnpm-lock.yaml yarn.lock package-lock.json bun.lockb bun.lock; do [ -f "$f" ] && echo "- lockfile: $f"; done
[ -f package.json ] && jq -r '"- packageManager: \(.packageManager // "-")", "- engines.node: \(.engines.node // "-")"' package.json
for f in .nvmrc .node-version; do [ -f "$f" ] && echo "- $f: $(cat "$f")"; done
echo "- local node: $(node -v 2>/dev/null || echo none)"

echo; echo "## Workspaces"
[ -f pnpm-workspace.yaml ] && { echo '```yaml'; cat pnpm-workspace.yaml; echo '```'; }
[ -f package.json ] && jq -r '(.workspaces // empty) | if type=="array" then .[] else (.packages // [])[] end | "- workspace glob: \(.)"' package.json
for f in turbo.json nx.json lerna.json .changeset/config.json; do [ -f "$f" ] && echo "- $f present"; done

echo; echo "## Packages"
for p in $pkgs; do
  printf -- '- `%s` → %s\n' "$(dirname "$p")" "$(jq -r '"\(.name // "?")\(if .private then " (private)" else "" end)"' "$p")"
done

echo; echo "## Relevant dependencies (name@range → package dir)"
interesting='^(react|react-dom|next|vite|@vitejs/plugin-react[^@]*|typescript|tailwindcss|@tailwindcss/[^@]+|sass|styled-components|@emotion/react|@vanilla-extract/css|@mui/material|@chakra-ui/react|@mantine/core|antd|@radix-ui/[^@]+|@headlessui/react|class-variance-authority|tailwind-merge|clsx|@reduxjs/toolkit|react-redux|zustand|jotai|@tanstack/react-query|swr|axios|ky|zod|yup|valibot|react-hook-form|@hookform/resolvers|react-router(-dom)?|@tanstack/react-router|jest|vitest|@vitest/[^@]+|@testing-library/[^@]+|jest-axe|vitest-axe|msw|@playwright/test|cypress|storybook|@storybook/[^@]+|eslint|prettier|husky|lint-staged|@commitlint/cli|@changesets/cli|turbo|nx|tsup|style-dictionary|framer-motion|motion|next-intl|i18next|react-i18next|nuqs|@svgr/[^@]+|lucide-react|prisma|@prisma/client|drizzle-orm|@supabase/[^@]+|mongoose|mongodb|hono|express|fastify|@trpc/[^@]+|@prismicio/[^@]+|next-auth|@auth/[^@]+|async-mutex|eslint-plugin-boundaries|dependency-cruiser|@tanstack/react-virtual)@'
for p in $pkgs; do
  d=$(dirname "$p")
  jq -r '((.dependencies // {}) + (.devDependencies // {}) + (.peerDependencies // {})) | to_entries[] | "\(.key)@\(.value)"' "$p" 2>/dev/null \
    | grep -E "$interesting" | sed "s|\$|  ($d)|"
done | sort | sed 's/^/- /'

echo; echo "## Scripts"
for p in $pkgs; do
  s=$(jq -r '(.scripts // {}) | to_entries[] | "    - `\(.key)`: \(.value)"' "$p" 2>/dev/null)
  [ -n "$s" ] && { echo "- $(dirname "$p"):"; echo "$s"; }
done

echo; echo "## Config files"
grep -E '(^|/)(tsconfig[^/]*\.json|eslint\.config\.[cm]?[jt]s|\.eslintrc[^/]*|\.prettierrc[^/]*|prettier\.config\.[cm]?[jt]s|commitlint\.config\.[cm]?[jt]s|\.lintstagedrc[^/]*|lint-staged\.config\.[cm]?[jt]s|jest\.config\.[cm]?[jt]s|jest\.setup\.[jt]sx?|vitest\.(config|workspace)\.[cm]?[jt]s|vitest\.setup\.[jt]sx?|setupTests\.[jt]sx?|playwright\.config\.[jt]s|tailwind\.config\.[cm]?[jt]s|postcss\.config\.[cm]?[jt]s|next\.config\.[cm]?[jt]s|vite\.config\.[cm]?[jt]s|\.env\.example|Dockerfile|azure-pipelines\.ya?ml|\.gitlab-ci\.yml|\.editorconfig|components\.json)$' <<<"$ALL" | sed 's/^/- /'
grep -E '^(\.github/workflows/|\.husky/|\.storybook/)' <<<"$ALL" | sed 's/^/- /'

echo; echo "## Architecture hints"
grep -oE '(^|/)(features|modules|domains?|entities|widgets|shared|core|layouts?|templates|atoms|molecules|organisms|application|infrastructure)/' <<<"$ALL" \
  | sed -E 's|^/||' | sort | uniq -c | sort -rn | head -12 | awk '{ printf "- %s (%s files)\n", $2, $1 }'
grep -E '(^|/)app/(.*/)?(layout|template)\.tsx$|(^|/)app/\([^)]+\)/' <<<"$ALL" | sed -E 's|/[^/]+$||' | sort -u | head -8 | sed 's/^/- next layout\/route group: /'
grep -E '(^|/)app/api/.*route\.(ts|js)$|(^|/)pages/api/|(^|/)prisma/schema\.prisma$|(^|/)middleware\.(ts|js)$' <<<"$ALL" | head -8 | sed 's/^/- backend: /'
grep -lE 'interceptors\.(request|response)\.use|prepareHeaders|baseQueryWithReauth' $(grep -E '\.(ts|tsx|js)$' <<<"$ALL" | head -2000) 2>/dev/null | head -5 | sed 's/^/- interceptors: /'

echo; echo "## Design-system hints"
grep -iE '(^|/)(tokens?|theme|themes|design-system|designsystem|ds|ui|primitives|foundations)(/|\.|$)' <<<"$ALL" | grep -vE '\.(png|jpg|svg|woff2?)$' | sed -E 's|/[^/]+$||' | sort -u | head -25 | sed 's/^/- dir: /'
css_theme=$(grep -E '\.(css|scss)$' <<<"$ALL" | while read -r f; do grep -lE '@theme|--color-|\$color-' "$f" 2>/dev/null; done | head -10)
[ -n "$css_theme" ] && { echo "- files declaring tokens/vars:"; sed 's/^/    - /' <<<"$css_theme"; }
n_stories=$(grep -cE '\.stories\.(tsx|ts|jsx|mdx)$' <<<"$ALL"); echo "- stories: $n_stories"
n_tests=$(grep -cE '\.(test|spec)\.(tsx?|jsx?)$' <<<"$ALL"); echo "- unit/component tests: $n_tests"
grep -E '\.figma\.(tsx|ts)$' <<<"$ALL" | head -3 | sed 's/^/- figma code connect: /'

echo; echo "## Git"
echo "- branch: $(git branch --show-current 2>/dev/null)"
echo "- remotes: $(git remote -v 2>/dev/null | awk '{print $2}' | sort -u | tr '\n' ' ')"
echo "- recent commits (style reference):"
git log -8 --format='    - %s' 2>/dev/null
