# Separate API app in the monorepo

Only when the repo already has one, or the brief explicitly asks for a standalone server.

## Hono (default if nothing exists: tiny, typed, zod validator, typed RPC client)
Deps (ask first): `hono`, `@hono/node-server`, `@hono/zod-validator`, `tsx` (dev).
```ts
// apps/api/src/index.ts
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { zValidator } from '@hono/zod-validator';
import { serve } from '@hono/node-server';
import { listingCreateSchema, listingQuerySchema } from '@scope/shared/listings';
import { listingsRepo } from './repos';

const app = new Hono()
  .use('/api/*', cors({ origin: process.env.WEB_ORIGIN ?? 'http://localhost:3000' }))
  .get('/api/listings', zValidator('query', listingQuerySchema), async (c) => c.json(await listingsRepo.list(c.req.valid('query'))))
  .get('/api/listings/:id', async (c) => {
    const item = await listingsRepo.byId(c.req.param('id'));
    return item ? c.json(item) : c.json({ status: 404, title: 'Listing not found' }, 404);
  })
  .post('/api/listings', zValidator('json', listingCreateSchema), async (c) => c.json(await listingsRepo.create(c.req.valid('json')), 201));

app.onError((err, c) => { console.error(err); return c.json({ status: 500, title: 'Unexpected error' }, 500); }); // kit-allow: server log
export type AppType = typeof app;   // frontend can use hono/client for a typed RPC client
serve({ fetch: app.fetch, port: Number(process.env.PORT ?? 4000) });
```
`apps/api/package.json` scripts: `"dev": "tsx watch src/index.ts"`, `"build": "tsc -p ."`, `"typecheck": "tsc --noEmit"`. Wire it in `turbo.json` like the other apps.

## Express / Fastify (if the repo uses them)
Same layers: router → `schema.safeParse(req.body)` → service → repo; one error middleware producing `{ status, title, details }`. Fastify can use `fastify-type-provider-zod`.

## Shared contract
Put zod schemas + inferred types in `packages/shared` (or `packages/api-contract`) so the web app and the API validate the same shapes. That's the monorepo's strongest argument; say it.

## Test
`app.request('/api/listings?page=1')` (Hono) or `supertest` (Express) against the in-memory repo.
