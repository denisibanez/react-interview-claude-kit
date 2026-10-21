---
name: kit-recon
description: Map an unfamiliar React/TypeScript repo or monorepo before writing any code. Detects package manager, workspaces, framework (Next/Vite), styling (Tailwind/SCSS/CSS-in-JS/UI library), state (Redux Toolkit/Zustand/Context), data fetching, validation (zod), tests (Jest/Vitest/Playwright), Storybook, lint/format/husky and CI, then writes .kit/STACK.md, which every other kit skill reads. Use at the very start of the challenge, or when STACK.md is missing or stale.
---

# Repo recon → `.kit/STACK.md`

Goal: in ~10 minutes, know the stack and the conventions well enough that every later change looks like it was written by the team.

## 1. Facts (deterministic)
Run exactly `bash .claude/skills/kit-recon/detect.sh` (relative path, no redirects: that is what the permission allowlist matches).
It prints the lockfile, workspaces, packages, relevant dependencies per package, scripts, config files, DS hints and git style.

## 2. Conventions (read, don't guess)
Open just enough to answer these. Cite real paths in STACK.md.
- **Architecture:** type-based, feature-based, modular packages, FSD or DDD-lite? Infer the dependency rule (who imports whom) and any lint boundaries. If there's none, say so: the `architecture` skill picks and justifies one. Where do apps vs packages live? Page templates/layouts?
- **Backend:** API given by the brief? `app/api` route handlers, `apps/api`, Prisma/Supabase/Mongo? Interceptors (axios instance, `prepareHeaders`, fetch wrapper)?
- **Design system:** which package/folder? Where are the tokens (CSS vars, `@theme`, tailwind config, SCSS maps, theme object)? How are variants done (cva, data-attributes, styled variants, MUI theme)? Read **one representative component + its story + its test** end to end.
- **Exports:** named or default? Barrel `index.ts`? Path aliases (`@/`, `@scope/ui`)?
- **Data:** how is an API called today (client, query lib, RTK Query, server components)? Where are types/schemas?
- **State:** store setup, slice/selector style.
- **Tests:** runner, location (`__tests__` or colocated), render helper (`renderWithProviders`?), MSW?
- **Quality gates:** eslint rules that will bite, prettier config, husky hooks, commitlint, CI steps.

## 3. Smoke-run
Run `pnpm install` (or the detected PM), then the narrowest typecheck, lint, test **and build** commands (the build often runs lint/type checks the others skip). Note anything **already broken before any change**, so nobody blames the candidate later. Don't start long-running servers here; the user decides.
**Time the typecheck** of the main app (`time pnpm --filter <app> typecheck`). The Stop hook runs it after every Claude turn: if it takes more than ~20 s, tell the user and suggest `touch .claude/.kit-state/typecheck-off` (then run it manually before each commit). Record the time in STACK.md.

## 4. Write `.kit/STACK.md` (create the `.kit/` folder; it is git-excluded. Never write kit notes inside `.claude/`: it needs extra approvals)
Keep it under ~80 lines, using this template:

```md
# STACK (recon at <time>)
| Area | Choice | Evidence |
|---|---|---|
| PM / workspaces | pnpm 9, apps/*, packages/* | pnpm-workspace.yaml |
| Framework | Next 15 App Router (apps/web) | apps/web/app/ |
| Architecture | feature-based, features import via index.ts | apps/web/src/features/ |
| Layouts | AppShell in app/layout.tsx, no templates yet | |
| Backend | external API (brief) / route handlers / none | |
| React | 19 → ref as prop, no forwardRef | apps/web/package.json |
| Styling | Tailwind v4 + cva | packages/ui/src/button.tsx |
| Tokens | packages/ui/src/styles/tokens.css (@theme) | |
| State | Zustand | apps/web/src/stores/cart.ts |
| Data | TanStack Query + fetch client | apps/web/src/lib/api.ts |
| Validation | zod | |
| Tests | Vitest + RTL, colocated *.test.tsx; Playwright in apps/web/e2e | |
| Storybook | 9, @storybook/react-vite, packages/ui | |
| Lint/format | eslint flat + prettier + husky/lint-staged | |
| CI | .github/workflows/ci.yml | |

## Commands
- typecheck time (Stop hook cost): ~N s
- dev: `pnpm --filter web dev`
- typecheck / lint / test (per package): ...

## Conventions to copy
- components: `packages/ui/src/<name>/<Name>.tsx` + `.stories.tsx` + `.test.tsx`, named exports, barrel
- ...

## Pre-existing issues (not ours)
- ...

## Open questions for the interviewers
- ...

## Interview language
- PT-BR / EN (ask the user if unknown)
```

## 5. Report to the user
A 10-line summary: the stack, the 3 conventions that matter most, what is broken already, and 2–4 smart questions to ask the interviewers (scope, priorities, design source of truth, test expectations).

The `references/` folders of the other skills are organised by stack choice. From now on, load only the reference that matches STACK.md.
