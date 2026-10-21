# Interview Kit (React / TS / Design System)

A kit of **skills, agents and guards** for Claude Code that you install into any repo (whatever the company sends) in 5 seconds, **without touching git**. It is not a scaffold: it creates no app. It teaches Claude to work **within their repo's conventions**, with the patterns you know as the fallback.

## Install into the challenge repo
```bash
~/interview-kit/install.sh ~/path/to/their-repo
cd ~/path/to/their-repo && git status   # nothing from the kit should show up
```
Then open Claude Code in the repo and say: **"run kit-recon"**. Start every challenge item with **`/feature <item>`**: skills are model-invoked and can be skipped, an explicit slash command is not.

Uninstall: `~/interview-kit/uninstall.sh ~/path/to/repo`

How it stays invisible: everything goes into `.claude/` + `CLAUDE.local.md` and is listed in `.git/info/exclude`, the local ignore file that is never committed. If the repo already has a `.claude/`, nothing is overwritten: items with the same name are skipped and `settings.local.json` is merged, with a backup.

## What's inside

### Skills (18; Claude loads them from context, or you call them with `/name`)
| Skill | Purpose |
|---|---|
| `kit-recon` | Maps the repo (pnpm, Next/Vite, Tailwind/SCSS, Redux/Zustand, Jest/Vitest...) and writes `.kit/STACK.md`, which every other skill reads |
| `feature` | The loop for each item: understand → plan → test first → implement → verify → notes → commit |
| `ds-tokens` | 3-layer tokens, themes/dark mode, Tailwind v4/v3, SCSS, CSS-in-JS, MUI; Figma variables → tokens |
| `ds-component` | DS component: variant API, ref, className, a11y, story + test. References per styling approach (cva, CSS Modules, styled, UI lib) |
| `storybook` | Typed CSF3 (no `any`), variant matrix, `play`, a11y, decorators, MSW, SB8 vs SB9 |
| `figma-to-code` | **Figma REST API** (`figma-fetch.sh`: outline + palette + PNG, needs `FIGMA_TOKEN`), MCP or screenshot as fallback → inventory → tokens → bottom-up → fidelity check |
| `api-layer` | HTTP client + zod + service + hooks (TanStack/RTK Query/Next server) + loading/error/empty states; **interceptors** (auth, single-flight refresh, error mapping, retries) for fetch/axios/RTK Query |
| `state-management` | Where each piece of state lives + **Context vs Zustand vs RTK (vs Jotai) matrix** with ready interview answers; per-request stores in Next |
| `react-expert` | Which hook / pattern / perf approach and why: hook table (when, when not, pitfall, one-liner), effect smells, composition, boundaries, re-render diagnosis |
| `architecture` | Detect or choose type-based / feature-based / modular / FSD / DDD-lite, dependency rules, ESLint boundaries, justification script |
| `layouts-templates` | Atomic design at page level: layout primitives (Stack, Grid, Container), slot-based templates (AppShell, PageLayout, ListDetail), pages that only wire data, Next layouts/route groups |
| `backend-endpoint` | Do you need a backend? Next Route Handlers / Server Actions or `apps/api` (Hono), zod, error shape, repository + adapters (memory, Prisma+SQLite, Supabase, Mongo) |
| `forms` | react-hook-form + zod, a11y, server errors, server actions |
| `testing` | TDD-lite strategy, RTL, Jest vs Vitest, MSW, Playwright, axe |
| `monorepo` | pnpm filters, new package, exports, turbo, catalogs, changesets |
| `tooling` | ESLint flat config, Prettier, Husky + lint-staged + commitlint, CI (GitHub/Azure) with templates |
| `nextjs` | App Router, RSC vs client, Next 15 (async params, caching), actions, pitfalls |
| `checkpoint` | Builds your spoken script + decisions + AI usage + likely questions |

### Agents (subagents with their own context; only `tooling-engineer` should run in the background during the challenge)
| Agent | Purpose |
|---|---|
| `git-flow` | Branch, atomic Conventional commits, push, PR with a good description. Never `--no-verify`, never force push, no AI trailer |
| `reviewer` | Staff/DS-level review of the diff (bugs, a11y, tokens, TS, tests), read-only. Use it before each checkpoint |
| `test-writer` | Writes tests in the repo's style while you implement |
| `tooling-engineer` | Sets up eslint/husky/CI in the background without touching feature code |

### Guards (automatic hooks)
| Hook | What it does |
|---|---|
| **SessionStart** | Injects `STACK.md` into the context (survives `/clear` and compaction) |
| **PreToolUse / Bash** | **Blocks** force push, `--no-verify`, `reset --hard`, broad `rm -rf`. **Asks** before installing a dependency, pushing, creating a PR, or printing secrets (`printenv`, `$…TOKEN`, `cat .env*`) during screen share |
| **PostToolUse / Edit** | Runs the **repo's prettier** on the file and flags, **only on lines changed vs HEAD**: `any`, `@ts-ignore`, non-null `!`, `console.log`, **hardcoded hex/rgb**, Tailwind arbitrary values, `div onClick`, `key={index}`, `<img>`, `dangerouslySetInnerHTML`, deep imports into another package/feature, server env vars in `'use client'` files, `'use client'` on a page/layout, a change pushing a file past 220 lines. Claude fixes them itself (or marks `// kit-allow` with a reason). Light mode: `touch .claude/.kit-state/guards-off` |
| **Stop** | Typecheck of **only the changed packages**, reporting **only errors in the files you touched** (errors that already existed in the repo don't block). Turn off: `touch .claude/.kit-state/typecheck-off` |

## Supporting files (for you to read)
- [CHECKLIST.md](CHECKLIST.md): step-by-step actions until the interview, the rehearsal and the day itself
- [PLAYBOOK.md](PLAYBOOK.md): checklist before Monday, the 2h plan, how to talk about AI, DS questions, lessons from your airbnb repo
- [VUE-REACT.md](VUE-REACT.md): Vue → React cheat sheet
