---
name: backend-endpoint
description: Create a small, typed backend endpoint when the challenge needs one — Next.js Route Handlers or Server Actions, or a separate apps/api (Hono/Express/Fastify) in the monorepo — with zod validation, a consistent error shape, a repository interface and a persistence adapter (in-memory/JSON, Prisma + SQLite/Postgres, Supabase, MongoDB), plus tests. Use when the user needs an API route, endpoint, BFF, mock server, CRUD, database, Prisma, Supabase or Mongo.
---

# Backend endpoint (frontend challenge edition)

## 0. Do you even need one? (ask before building)
| Situation | Do this |
|---|---|
| The brief gives an API | Consume it (`api-layer`). No backend. |
| No API, data is only for the demo | **MSW** handlers or a static JSON + service. Fastest, testable, zero infra. |
| You need a BFF (hide a secret key, aggregate/transform calls, CORS) | **Next Route Handler** proxying the upstream API. |
| Real CRUD with persistence is part of the brief | Route Handlers/Server Actions + **repository** + adapter (below). |
| Monorepo already has `apps/api` | Add the route there, in their framework and style. |

Say it: "I didn't build a database because the brief is about the UI; the endpoint is behind a repository interface, so swapping the in-memory adapter for Prisma is one file."

## 1. Layers (same shape in Next or a separate server)
```
route.ts / action.ts   → parse input (zod) → call service → map result/error to HTTP
service (use cases)    → business rules, pure where possible (unit tested)
repository interface   → ListingsRepo { list(q), byId(id), create(input), update(id, patch), remove(id) }
adapter                → memory | prisma | supabase | mongo  (one file each)
schemas (zod)          → shared with the frontend (packages/shared or features/*/model)
```

## 2. Next Route Handler (App Router)
```ts
// app/api/listings/route.ts
import { NextResponse, type NextRequest } from 'next/server';
import { listingCreateSchema, listingQuerySchema } from '@/features/listings/model/schemas';
import { listingsRepo } from '@/server/repos';           // picks the adapter
import { problem } from '@/server/http';

export async function GET(req: NextRequest) {
  const parsed = listingQuerySchema.safeParse(Object.fromEntries(req.nextUrl.searchParams));
  if (!parsed.success) return problem(400, 'Invalid query', parsed.error.flatten());
  return NextResponse.json(await listingsRepo.list(parsed.data));
}

export async function POST(req: NextRequest) {
  const body: unknown = await req.json().catch(() => null);
  const parsed = listingCreateSchema.safeParse(body);
  if (!parsed.success) return problem(422, 'Validation failed', parsed.error.flatten());
  const created = await listingsRepo.create(parsed.data);
  return NextResponse.json(created, { status: 201, headers: { Location: `/api/listings/${created.id}` } });
}
```
```ts
// app/api/listings/[id]/route.ts  (Next 15: params is a Promise)
export async function GET(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const item = await listingsRepo.byId(id);
  return item ? NextResponse.json(item) : problem(404, 'Listing not found');
}
```
```ts
// server/http.ts – one error shape for the whole API (RFC 9457-ish)
import 'server-only';
export const problem = (status: number, title: string, details?: unknown) =>
  NextResponse.json({ status, title, details }, { status });
```
- Status codes: 200 read, 201 create (+ `Location`), 204 delete, 400 bad query, 401/403 auth, 404, 409 conflict, 422 validation, 500 unexpected (log it, don't leak the stack).
- Pagination: `?page=&pageSize=` → `{ items, total, page, pageSize }`. Filtering/sorting validated by zod enums.
- Server Action instead of a route when only your own forms call it (`api-layer/references/next-server.md`). Route Handler when a client lib, another app or an external caller needs it.
- Auth (if asked): read the session/cookie in the handler, 401 if missing; never trust ids from the body for ownership.

## 3. Persistence adapters → `references/persistence.md`
Pick by what the repo/brief already has. Order for a 2h challenge:
1. **In-memory** (Map + seed JSON): zero setup. Default.
2. **Prisma + SQLite**: real DB, migrations, typed client, one file DB, no server. Best "real" option.
3. **Supabase**: only if the brief or repo uses it (needs project + keys + network).
4. **MongoDB (mongoose)**: only if the repo uses it (needs a running server or Atlas).
Ask before adding any dependency.

## 4. Separate server (`apps/api`) → `references/standalone-server.md`
Hono (tiny, typed, runs anywhere) or Express/Fastify if the repo uses them. Same layers.

## 5. Tests
- Service/rules: unit tests, no HTTP.
- Route Handlers: call the exported `GET`/`POST` directly with `new NextRequest('http://x/api/listings?page=1')` and assert status + JSON. Use the in-memory adapter.
- Frontend keeps MSW handlers in sync with the same zod schemas.

## 6. Security checklist (one line each at the checkpoint)
Input validated with zod, output is a typed DTO (no internal fields), secrets only in server env (no `NEXT_PUBLIC_`), `import 'server-only'` in server modules, parameterised queries (ORM), rate limiting/CORS mentioned as next steps.
