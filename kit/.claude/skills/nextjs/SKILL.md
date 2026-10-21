---
name: nextjs
description: Next.js App Router specifics (13.4–15+) — server vs client components and where to put 'use client', data fetching and caching, async params/searchParams in Next 15, loading/error/not-found files, server actions, route handlers, metadata, next/image and next/font, middleware, env vars, and common pitfalls (hydration mismatch, window access, passing functions to client components). Also Pages Router quick notes. Use whenever the repo has next in STACK.md.
---

# Next.js (App Router)

## Decision guide (say the why)
| Need | Choose | Why |
|---|---|---|
| Read data for first render, SEO | Server Component `await fetch/db` | no client JS, no loading waterfall, secrets stay server-side |
| Interactive data (search as you type, infinite scroll, polling, optimistic) | client component + TanStack Query, seeded/hydrated from the server | cache, dedupe, background refetch |
| Mutation from your own form | Server Action + `useActionState` (+ `useOptimistic`) | progressive enhancement, typed, `revalidateTag` |
| Endpoint for a client lib, another app, webhook, external caller | Route Handler `app/api/*/route.ts` (`backend-endpoint` skill) | real HTTP contract |
| Hide an upstream API key / aggregate calls | Route Handler as BFF | secret never reaches the browser |
| Redirect by auth/locale before render | `middleware.ts` | runs before the route, at the edge |
| Slow part of a page | `<Suspense>` around it (streaming) or `loading.tsx` | the rest of the page shows immediately |
| Data that changes rarely | `fetch(..., { next: { revalidate: N, tags } })` / `unstable_cache` / `'use cache'` (if the repo enables it) | static speed with freshness |
| Per-user data | dynamic (cookies/headers), no shared cache | correctness |
| Filters/pagination | `searchParams` on the server page, `useSearchParams`/`nuqs` on the client | shareable URLs, back button |

## Server vs Client
- Every file under `app/` is a **Server Component** by default: async, no hooks, no browser APIs, can read secrets and the DB/API directly.
- Add `'use client'` at the **leaf** that needs state, effects, event handlers or browser APIs. Keep pages and layouts on the server and pass serialisable props down.
- You can't pass functions from server to client components (except Server Actions). Pass data instead.
- Providers (QueryClient, store, theme) go in a client `app/providers.tsx`, rendered in `layout.tsx`.

## Files per route
`page.tsx`, `layout.tsx`, `loading.tsx` (Suspense skeleton), `error.tsx` (`'use client'`, gets `error` + `reset`), `not-found.tsx`, `route.ts` (API handler), `opengraph-image.tsx`. Route groups `(group)` organise without changing the URL; `[id]` is dynamic, `[...slug]` catch-all.

## Next 15 changes to remember
- `params` and `searchParams` are **Promises**: `const { id } = await params;`. In client components use `use(params)` or `useParams()`.
- `fetch` is uncached by default. Opt in with `{ cache: 'force-cache' }` or `{ next: { revalidate: 60, tags: ['x'] } }`.
- `cookies()`, `headers()` and `draftMode()` are async.
- React 19: `useActionState`, `useOptimistic`, `use`, `ref` as a prop.

## Data
See `api-layer/references/next-server.md` (RSC fetching, server actions with zod, route handlers, TanStack hydration).

## Metadata / SEO
`export const metadata: Metadata = { title: '...', description: '...' }` or `generateMetadata({ params })`.

## Assets
- `next/image`: always set `alt`, plus `width`/`height` or `fill` + `sizes`. Remote hosts go in `images.remotePatterns`.
- `next/font`: `const inter = Inter({ subsets: ['latin'], variable: '--font-sans' })`, then put the variable class on `<html>` and map it to the typography token.

## Pitfalls
- Hydration mismatch: `Date.now()`, `Math.random()`, `localStorage` or `window` in render. Move them to `useEffect`, or use `suppressHydrationWarning` for theme attributes only.
- Importing a server-only module into a client component leaks secrets or breaks the build. Mark the module with `import 'server-only'`.
- Large client bundles from `'use client'` at the top of a tree: push the boundary down.
- `useSearchParams` in a client component needs a `<Suspense>` boundary on statically rendered pages.

## Pages Router (if the repo uses `pages/`)
`getServerSideProps` / `getStaticProps` + `revalidate`; API routes in `pages/api`; `_app.tsx` for providers; `useRouter` from `next/router` (not `next/navigation`).
