---
name: api-layer
description: Consume a REST/HTTP API in a clean, typed, testable way — http client with typed errors, zod schemas at the boundary, resource services, query hooks (TanStack Query, RTK Query, SWR) or Next server-side fetching, interceptors (auth header, single-flight token refresh, error normalisation, retries) for fetch/axios/RTK Query, plus loading/error/empty/success UI states and MSW mocks. Use when the challenge involves fetching, listing, searching, paginating, creating or updating data.
---

# API layer

## Layers (each one is testable alone)
```
http client  →  schemas (zod)  →  service (per resource)  →  hook (query lib)  →  UI states
lib/http.ts     <res>/schemas.ts   <res>/api.ts               <res>/queries.ts     components
```
In a monorepo, put the client + schemas + services in a shared package (`packages/api` or `packages/shared`) when more than one app uses them. Follow STACK.md's structure (feature folders vs `services/`).

## 1. http client (only if the repo has none; otherwise reuse it)
```ts
// lib/http.ts
export class ApiError extends Error {
  constructor(public status: number, message: string, public body?: unknown) { super(message); this.name = 'ApiError'; }
}

const BASE_URL = import.meta.env.VITE_API_URL; // Next: process.env.NEXT_PUBLIC_API_URL

export async function http<T>(path: string, init: RequestInit & { parse: (data: unknown) => T }): Promise<T> {
  const { parse, ...rest } = init;
  const res = await fetch(`${BASE_URL}${path}`, {
    ...rest,
    headers: { 'Content-Type': 'application/json', ...rest.headers },
    signal: rest.signal ?? AbortSignal.timeout(10_000),
  });
  const body: unknown = res.status === 204 ? null : await res.json().catch(() => null);
  if (!res.ok) throw new ApiError(res.status, `HTTP ${res.status} on ${path}`, body);
  return parse(body);
}
```
If the repo uses axios/ky, keep it. Put the base URL, interceptors (auth, errors) and the parse step in one place.
**Interceptors** (auth header, 401 → single-flight refresh → retry, error normalisation, retry policy, Next BFF/middleware) → `references/interceptors.md`.

## 2. Schemas at the boundary
```ts
// products/schemas.ts
import { z } from 'zod';
export const productSchema = z.object({
  id: z.string(),
  title: z.string(),
  price: z.number().nonnegative(),
  thumbnail: z.string().url().optional(),
});
export const productPageSchema = z.object({ items: z.array(productSchema), total: z.number(), page: z.number() });
export type Product = z.infer<typeof productSchema>;
export type ProductPage = z.infer<typeof productPageSchema>;
```
Why: the API is untrusted, so a contract drift fails loudly in one place and every type inside the app is derived (no duplicated interfaces).

## 3. Service
```ts
// products/api.ts
export type ProductQuery = { search?: string; page?: number; pageSize?: number };
export const productsApi = {
  list: ({ search = '', page = 1, pageSize = 20 }: ProductQuery, signal?: AbortSignal) =>
    http(`/products?${new URLSearchParams({ q: search, page: String(page), limit: String(pageSize) })}`, {
      signal, parse: productPageSchema.parse,
    }),
  byId: (id: string, signal?: AbortSignal) => http(`/products/${id}`, { signal, parse: productSchema.parse }),
};
```

## 4. Hooks, by STACK (load one reference)
- TanStack Query → `references/tanstack-query.md`
- RTK Query → `references/rtk-query.md`
- Next App Router server fetching / server actions → `references/next-server.md`
- SWR: `useSWR(key, fetcher)` with the same service functions and keys as arrays.
- None of these, and no dependency approved: `useEffect` + `AbortController` + a `useReducer` status machine (`idle | loading | success | error`). Mention that you'd use a query lib in production for cache, dedupe and retries.

## 5. UI states (every data view)
```tsx
if (query.isPending) return <ProductGridSkeleton />;          // keeps the layout, no CLS
if (query.isError) return <ErrorState onRetry={() => query.refetch()} />;
if (query.data.items.length === 0) return <EmptyState title="No products found" />;
return <ProductGrid items={query.data.items} />;
```
- Search input: debounce 300 ms (`useDeferredValue` or a `useDebounce` hook). Keep the previous data while fetching (`placeholderData: keepPreviousData`).
- Filters, search and page live in the **URL** (`useSearchParams`), so the result is shareable and back-button friendly.
- Mutations: disable the submit while pending, show the success/error feedback, invalidate the related queries, and use an optimistic update only when it's cheap to roll back.

## 6. Mocks
MSW handlers in `mocks/handlers.ts`, reused by tests, Storybook and (optionally) dev. See the `testing` skill (`references/msw.md`).
