---
name: architecture
description: Identify, choose and justify the frontend architecture — type-based, feature-based (vertical slices), modular/domain monorepo packages, Feature-Sliced Design, DDD-lite / clean layering — plus folder layout, dependency rules between layers, public APIs (barrels), where shared code goes, and how to enforce boundaries with ESLint. Use at recon time, when the repo has no clear structure, when adding the first feature of a new area, or when the user mentions architecture, folder structure, feature/modular/DDD/clean/FSD, or "where should this go".
---

# Architecture: detect first, choose second, justify always

## 0. The repo already has one?
Then **follow it**, even if you'd choose differently. Write in STACK.md: the pattern, one example path, the dependency rule you inferred. At the checkpoint: "I followed your feature structure; the one thing I'd discuss is X."
Detect: `ls` the app's `src/` and the `packages/` folder; look for `features/`, `modules/`, `domains/`, `entities/`, `widgets/`, `shared/`, `core/`, `components/{atoms,molecules}`.

## 1. If you must choose (no structure, or a new app/package)

| Option | Shape | Pick when | Cost |
|---|---|---|---|
| **Type-based** | `components/ hooks/ services/ utils/` | tiny app, < ~5 screens | features smear across folders; doesn't scale |
| **Feature-based** (default) | `features/<name>/{components,hooks,api,schemas,store}` + `shared/` + `app/` | most challenges; a team per feature | needs a rule for cross-feature imports |
| **Modular monorepo** | `packages/ui` (DS), `packages/api-client`, `packages/<domain>`, `apps/*` consume | several apps share code; DS published separately | package wiring, versioning (changesets) |
| **Feature-Sliced Design** | `app → pages → widgets → features → entities → shared`, imports only downward | large product, many teams, strict rules | vocabulary overhead; overkill in 2h |
| **DDD-lite / clean** | per domain: `domain/` (types, pure rules) · `application/` (use cases, hooks) · `infrastructure/` (http, storage) · `ui/` | rich business rules (pricing, eligibility, workflows) | boilerplate if the domain is CRUD |

**Default for a 2h challenge:** feature-based inside the app, DS in `packages/ui`, shared API client/schemas in a package only if two apps need them. Borrow DDD's one good idea: **pure domain functions** (calculations, rules) separated from React and HTTP, so they're trivially testable.

## 2. Feature-based layout (fallback)
```
apps/web/src/
  app/ (or pages/, routes/)     # routing only: compose templates + features, no business logic
  features/
    listings/
      api/          # service + query hooks (api-layer)
      components/   # feature-specific UI (composes DS components)
      hooks/
      model/        # types, zod schemas, pure rules (+ tests)
      store/        # only if it has client state
      index.ts      # PUBLIC API of the feature
  shared/           # app-wide: http client, config, generic hooks, layout templates
packages/ui/        # design system: tokens, primitives, layout primitives
```

## 3. Dependency rules (the part interviewers probe)
- `app/pages → features → shared → packages/ui`. Never upward.
- A feature imports another feature **only via its `index.ts`** (or not at all: compose them in the page).
- The DS never imports app code. The DS has no data fetching and no business logic.
- Domain/model code imports nothing from React or HTTP.
- No deep imports into packages (`@scope/ui/src/...`): use the package's `exports`.

Enforce cheaply (if the repo has ESLint; ask before adding plugins):
```js
// eslint.config.mjs
{ rules: { 'no-restricted-imports': ['error', { patterns: [
  { group: ['@/features/*/*'], message: 'Import a feature through its index.ts' },
  { group: ['@scope/ui/src/*', '**/packages/*/src/*'], message: 'Use the package public exports' },
] }] } }
```
Heavier options: `eslint-plugin-boundaries`, Nx module boundaries, `dependency-cruiser`.

## 4. Justification script (adapt the nouns)
"I organised by feature because the challenge is a few vertical flows; each folder holds its UI, data and rules, so deleting or owning a feature is one folder. Shared UI lives in the DS package so the app only composes. Pure rules are separated from React, which is why they have unit tests without rendering. If this grew to many teams I'd add explicit boundaries (lint rule or FSD layers); I didn't now because it would be ceremony for 3 features."

## 5. Smells to avoid
- `utils/` dumping ground → name by purpose (`format-price.ts`) and colocate.
- Barrels that re-export everything from the app root (cycles, slow tests). One `index.ts` per feature/package is fine.
- Business logic in components or in `page.tsx`.
- A "common" feature everyone imports from: that's `shared/` or the DS.
