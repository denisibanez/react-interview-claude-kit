# Next.js App Router data

## Server Component fetching (default for reads)
```tsx
// app/products/page.tsx
import { productsApi } from '@/products/api';

export default async function ProductsPage({ searchParams }: { searchParams: Promise<{ q?: string; page?: string }> }) {
  const { q = '', page = '1' } = await searchParams; // Next 15: params/searchParams are Promises
  const data = await productsApi.list({ search: q, page: Number(page) });
  return <ProductGrid items={data.items} />;
}
```
- Next 15: `fetch` is **not cached by default**. Opt in with `fetch(url, { next: { revalidate: 60, tags: ['products'] } })` or `cache: 'force-cache'`.
- `loading.tsx` = Suspense fallback (skeleton). `error.tsx` must be a client component with `reset()`. `not-found.tsx` + `notFound()`.
- Secrets stay server-side: use non-`NEXT_PUBLIC_` env vars in server code only (add `import 'server-only'` in those modules).

## Mutations: Server Actions + zod
```ts
// app/products/actions.ts
'use server';
import { revalidateTag } from 'next/cache';
import { z } from 'zod';

const createSchema = z.object({ title: z.string().min(1, 'Required'), price: z.coerce.number().positive() });
export type CreateState = { ok: boolean; errors?: Partial<Record<keyof z.infer<typeof createSchema>, string[]>> };

export async function createProduct(_prev: CreateState, formData: FormData): Promise<CreateState> {
  const parsed = createSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { ok: false, errors: parsed.error.flatten().fieldErrors };
  await productsApi.create(parsed.data);
  revalidateTag('products');
  return { ok: true };
}
```
Client side: `const [state, action, pending] = useActionState(createProduct, { ok: false });` then `<form action={action}>`.

## Route Handlers (when a client or external caller needs an endpoint)
`app/api/products/route.ts` → `export async function GET(req: Request) { return Response.json(data) }`.

## Client interactivity
Search-as-you-type, infinite lists and optimistic UI use a client component with TanStack Query, seeded from server data (`initialData`) or hydrated (`HydrationBoundary`).
