# TanStack Query v5

```ts
// products/queries.ts
import { keepPreviousData, queryOptions, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { productsApi, type ProductQuery } from './api';

export const productKeys = {
  all: ['products'] as const,
  list: (q: ProductQuery) => [...productKeys.all, 'list', q] as const,
  detail: (id: string) => [...productKeys.all, 'detail', id] as const,
};

export const productListOptions = (q: ProductQuery) =>
  queryOptions({
    queryKey: productKeys.list(q),
    queryFn: ({ signal }) => productsApi.list(q, signal),
    placeholderData: keepPreviousData,
    staleTime: 30_000,
  });

export const useProducts = (q: ProductQuery) => useQuery(productListOptions(q));

export function useCreateProduct() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: productsApi.create,
    onSuccess: () => qc.invalidateQueries({ queryKey: productKeys.all }),
  });
}
```
- v5 naming: `isPending` (no data yet) vs `isFetching` (any request in flight). `gcTime` replaced `cacheTime`.
- Provider: one `QueryClient` per app (in Next: created inside a client `Providers` component with `useState(() => new QueryClient())`).
- Tests: a fresh `QueryClient({ defaultOptions: { queries: { retry: false } } })` per test.
- Next SSR prefetch: `await qc.prefetchQuery(productListOptions(q))` in a server component, then `<HydrationBoundary state={dehydrate(qc)}>`.
- Infinite scroll: `useInfiniteQuery` with `getNextPageParam`, plus an `IntersectionObserver` sentinel.
