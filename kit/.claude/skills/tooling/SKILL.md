---
name: tooling
description: Configure or fix the quality toolchain — ESLint flat config (typescript-eslint, react-hooks, jsx-a11y, import sorting, storybook, prettier compat), Prettier (+ tailwind plugin), Husky v9 + lint-staged + commitlint, EditorConfig, and CI pipelines (GitHub Actions, Azure DevOps, GitLab) for pnpm monorepos with caching, lint/typecheck/test/build, Playwright and Storybook/Chromatic. Use when the challenge asks for any of these, or a hook/CI step fails.
---

# Tooling

**Extend what exists.** If the repo already has a config, change the minimum. Templates live in `templates/`:
- `templates/eslint.config.mjs`: flat config for React + TS + a11y + hooks + prettier
- `templates/prettier.config.mjs`
- `templates/commitlint.config.mjs`
- `templates/lint-staged.config.mjs`
- `templates/ci-github.yml` → `.github/workflows/ci.yml`
- `templates/ci-azure.yml` → `azure-pipelines.yml`

## Husky v9 + lint-staged + commitlint
```bash
pnpm add -D -w husky lint-staged @commitlint/cli @commitlint/config-conventional   # ask the user first
pnpm exec husky init                       # creates .husky/pre-commit and the "prepare": "husky" script
echo "pnpm exec lint-staged" > .husky/pre-commit
echo 'pnpm exec commitlint --edit "$1"' > .husky/commit-msg
```
- pre-commit stays **fast**: lint-staged on staged files only. Typecheck and tests go to pre-push or CI.
- Optional pre-push: `pnpm turbo run typecheck test --filter="...[origin/main]"`.

## ESLint notes
- Flat config (`eslint.config.mjs`) is the default since ESLint 9. Legacy `.eslintrc` repos: keep their format.
- In a monorepo, put the shared preset in `packages/eslint-config` and keep one thin `eslint.config.mjs` per package (or a root config with per-glob overrides).
- `eslint-config-prettier` goes **last**, to turn off formatting rules (prettier formats, eslint finds bugs).
- Next: `eslint-config-next` (or `@next/eslint-plugin-next` in flat config). `next lint` is deprecated in Next 15.5+, so use `eslint .`.

## CI principles (say these)
- Fail fast and cheap first: install (frozen lockfile, cached) → lint + typecheck + unit tests in parallel → build → e2e.
- Use the pnpm store cache + turbo cache (remote cache if available), and only run affected packages on PRs (`--filter=...[origin/main]`).
- Upload artifacts: Playwright report/traces, coverage, the Storybook build. Chromatic for visual review of DS changes.
- Require the CI checks + 1 review on main. Release with changesets.
