# Persistence adapters (all implement the same repository)

```ts
// server/repos/types.ts
import type { Listing, ListingCreate, ListingQuery } from '@/features/listings/model/schemas';
export type Page<T> = { items: T[]; total: number; page: number; pageSize: number };
export interface ListingsRepo {
  list(q: ListingQuery): Promise<Page<Listing>>;
  byId(id: string): Promise<Listing | null>;
  create(input: ListingCreate): Promise<Listing>;
  update(id: string, patch: Partial<ListingCreate>): Promise<Listing | null>;
  remove(id: string): Promise<boolean>;
}
```
```ts
// server/repos/index.ts – the only place that knows the adapter
import 'server-only';
import { memoryListingsRepo } from './memory';
export const listingsRepo: ListingsRepo = memoryListingsRepo; // swap here
```

## 1. In-memory (default)
```ts
// server/repos/memory.ts
import seed from './seed/listings.json';
const db = new Map<string, Listing>(listingSchema.array().parse(seed).map((l) => [l.id, l]));

export const memoryListingsRepo: ListingsRepo = {
  async list({ search = '', page = 1, pageSize = 20 }) {
    const all = [...db.values()].filter((l) => l.title.toLowerCase().includes(search.toLowerCase()));
    return { items: all.slice((page - 1) * pageSize, page * pageSize), total: all.length, page, pageSize };
  },
  async byId(id) { return db.get(id) ?? null; },
  async create(input) { const l = { ...input, id: crypto.randomUUID() }; db.set(l.id, l); return l; },
  async update(id, patch) { const cur = db.get(id); if (!cur) return null; const next = { ...cur, ...patch }; db.set(id, next); return next; },
  async remove(id) { return db.delete(id); },
};
```
Caveat to say out loud: resets on server restart and isn't shared across serverless instances; fine for the demo.

## 2. Prisma + SQLite (best "real DB" in 2h)
Deps (ask first): `prisma` (dev) + `@prisma/client`.
```bash
pnpm --filter web add -D prisma && pnpm --filter web add @prisma/client
pnpm --filter web exec prisma init --datasource-provider sqlite
```
```prisma
// prisma/schema.prisma
model Listing {
  id        String   @id @default(cuid())
  title     String
  price     Int      // cents, never floats for money
  createdAt DateTime @default(now())
}
```
```bash
pnpm --filter web exec prisma migrate dev --name init
```
```ts
// server/db.ts – singleton (avoids exhausting connections on hot reload)
import 'server-only';
import { PrismaClient } from '@prisma/client';
const g = globalThis as unknown as { prisma?: PrismaClient };
export const prisma = g.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== 'production') g.prisma = prisma;

// server/repos/prisma.ts
export const prismaListingsRepo: ListingsRepo = {
  async list({ search = '', page = 1, pageSize = 20 }) {
    const where = { title: { contains: search } };
    const [items, total] = await prisma.$transaction([
      prisma.listing.findMany({ where, skip: (page - 1) * pageSize, take: pageSize, orderBy: { createdAt: 'desc' } }),
      prisma.listing.count({ where }),
    ]);
    return { items, total, page, pageSize };
  },
  byId: (id) => prisma.listing.findUnique({ where: { id } }),
  create: (data) => prisma.listing.create({ data }),
  async update(id, data) { try { return await prisma.listing.update({ where: { id }, data }); } catch { return null; } },
  async remove(id) { try { await prisma.listing.delete({ where: { id } }); return true; } catch { return false; } },
};
```
Add `prisma/dev.db` to `.gitignore`; seed with `prisma/seed.ts`. Drizzle is the lighter alternative if the repo prefers SQL-like code.

## 3. Supabase (only if the brief/repo uses it)
Deps: `@supabase/supabase-js` (`@supabase/ssr` for auth cookies in Next). Env: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (server only!) or the anon key + RLS.
```ts
import 'server-only';
import { createClient } from '@supabase/supabase-js';
import { env } from '@/server/env'; // zod-validated: z.object({ SUPABASE_URL: z.string().url(), SUPABASE_SERVICE_ROLE_KEY: z.string().min(1) }).parse(process.env)
const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
export const supabaseListingsRepo: ListingsRepo = {
  async list({ search = '', page = 1, pageSize = 20 }) {
    const from = (page - 1) * pageSize;
    const { data, count, error } = await supabase.from('listings')
      .select('*', { count: 'exact' }).ilike('title', `%${search}%`).range(from, from + pageSize - 1);
    if (error) throw error;
    return { items: listingSchema.array().parse(data), total: count ?? 0, page, pageSize };
  },
  // byId: .eq('id', id).maybeSingle(); create: .insert(x).select().single(); ...
};
```
Talking points: RLS policies for client-side access; service role key never reaches the browser; generated types (`supabase gen types`).
Validate env once with zod in `server/env.ts` (fails fast at boot, no `!` assertions).

## 4. MongoDB (only if the repo uses it)
Deps: `mongoose` (or the native `mongodb` driver). Env: `MONGODB_URI`. Needs a running instance (Docker `mongo:7` or Atlas).
```ts
import 'server-only';
import mongoose, { Schema, model, models } from 'mongoose';
const g = globalThis as unknown as { mongo?: Promise<typeof mongoose> };
export const connect = () => (g.mongo ??= mongoose.connect(env.MONGODB_URI));
const ListingModel = models.Listing ?? model('Listing', new Schema({ title: String, price: Number }, { timestamps: true }));
// list: await connect(); ListingModel.find({ title: new RegExp(escapeRegex(search), 'i') }).skip().limit().lean()
// map _id → id in the adapter so the rest of the app never sees Mongo types
```

## Note on "Prismic"
Prismic is a headless **CMS** (content: pages, blog, marketing), not a database. If the brief has CMS content, fetch it in RSC with `@prismicio/client` + slices; CRUD data still goes through one of the adapters above.
