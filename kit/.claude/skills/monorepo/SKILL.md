---
name: monorepo
description: Work inside or extend a pnpm workspaces monorepo (optionally Turborepo/Nx) — run scripts per package with filters, add a new package (ui, shared, config), internal package strategies (source/JIT vs built with tsup/vite), exports maps, workspace:* deps, shared tsconfig/eslint configs, turbo pipelines and caching, pnpm catalogs, and versioning a design-system package with changesets. Use when creating/wiring packages, fixing cross-package imports, or running tasks across the repo.
---

# pnpm monorepo

## Everyday commands
| Goal | Command |
|---|---|
| run in one package | `pnpm --filter @scope/web dev` (`-F` short) |
| run in a package + its deps | `pnpm --filter @scope/web... build` |
| run everywhere | `pnpm -r test` / `pnpm -r --parallel dev` |
| only what changed vs main | `pnpm --filter "...[origin/main]" test` |
| add a dep to one package | `pnpm --filter @scope/ui add clsx` (ask the user first) |
| link an internal package | `pnpm --filter @scope/web add @scope/ui@workspace:*` |
| why is X installed | `pnpm why X` |
| turbo | `pnpm turbo run lint typecheck test --filter=@scope/ui` |

## Typical layout
```
apps/web            (Next or Vite app)
apps/docs           (Storybook, sometimes)
packages/ui         (design system: components, tokens, stories)
packages/shared     (types, zod schemas, api client, utils)
packages/config-*   (tsconfig, eslint, prettier presets)
pnpm-workspace.yaml   packages: ['apps/*', 'packages/*']
turbo.json
```

## New internal package (copy the conventions of an existing one first!)
```jsonc
// packages/shared/package.json (source/JIT strategy: no build step, consumer transpiles)
{
  "name": "@scope/shared",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": { ".": "./src/index.ts", "./schemas": "./src/schemas/index.ts" },
  "scripts": { "typecheck": "tsc --noEmit", "lint": "eslint .", "test": "vitest run" },
  "devDependencies": { "@scope/tsconfig": "workspace:*", "typescript": "catalog:" }
}
```
- Next consumer: `transpilePackages: ['@scope/ui', '@scope/shared']` in `next.config`. Vite consumes TS sources natively.
- **Built** strategy (publishable DS): `tsup src/index.ts --format esm,cjs --dts`, `exports` with `types`/`import`/`require`, `"files": ["dist"]`, `"sideEffects": ["**/*.css"]`, and `react`/`react-dom` as **peerDependencies**.
- tsconfig: `{ "extends": "@scope/tsconfig/react-library.json", "include": ["src"] }`.
- If `catalog:` appears in the repo, versions live in `pnpm-workspace.yaml` under `catalog:`. Use the catalog, don't pin locally.

## turbo.json essentials
```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**", ".next/**", "!.next/cache/**", "storybook-static/**"] },
    "typecheck": { "dependsOn": ["^build"] },
    "lint": {},
    "test": { "dependsOn": ["^build"], "outputs": ["coverage/**"] },
    "dev": { "cache": false, "persistent": true }
  }
}
```
(Turbo v1 uses `pipeline` instead of `tasks`.)

## Versioning the DS package (great DS talking point)
Changesets: `pnpm changeset` (pick packages + bump + summary) → `changeset version` → `changeset publish`. Semver rules for a DS: a removed or renamed prop or a changed default is **major**; a new variant/prop/component is **minor**; a visual fix is **patch**. Deprecate first (JSDoc `@deprecated` + console warn in dev), remove in the next major.

## Pitfalls
- Phantom deps: a package importing something it doesn't declare (works locally because of hoisting, breaks in CI/consumers). Declare it.
- Duplicate React: React must be a peer dependency in libraries. Check with `pnpm why react`.
- TS path aliases don't cross package boundaries. Use package names + `exports`.
