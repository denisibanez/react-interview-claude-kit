# RTK Query (when the repo uses Redux Toolkit)

```ts
// services/productsApi.ts
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';
import { productPageSchema, productSchema, type Product, type ProductPage } from '../products/schemas';
import type { ProductQuery } from '../products/api';

export const productsApi = createApi({
  reducerPath: 'productsApi',
  baseQuery: fetchBaseQuery({ baseUrl: import.meta.env.VITE_API_URL }),
  tagTypes: ['Product'],
  endpoints: (build) => ({
    listProducts: build.query<ProductPage, ProductQuery>({
      query: ({ search = '', page = 1, pageSize = 20 }) => ({ url: '/products', params: { q: search, page, limit: pageSize } }),
      transformResponse: (raw: unknown) => productPageSchema.parse(raw),
      providesTags: (res) => [
        ...(res?.items.map(({ id }) => ({ type: 'Product' as const, id })) ?? []),
        { type: 'Product', id: 'LIST' },
      ],
    }),
    getProduct: build.query<Product, string>({
      query: (id) => `/products/${id}`,
      transformResponse: (raw: unknown) => productSchema.parse(raw),
      providesTags: (_r, _e, id) => [{ type: 'Product', id }],
    }),
    createProduct: build.mutation<Product, Omit<Product, 'id'>>({
      query: (body) => ({ url: '/products', method: 'POST', body }),
      invalidatesTags: [{ type: 'Product', id: 'LIST' }],
    }),
  }),
});
export const { useListProductsQuery, useGetProductQuery, useCreateProductMutation } = productsApi;
```
Store wiring: add `[productsApi.reducerPath]: productsApi.reducer` and `.concat(productsApi.middleware)` (see `state-management/references/redux-toolkit.md`).
Hook states: `isLoading` (first load), `isFetching`, `isError`, `error`, `data`, `refetch`. Use `skip`/`skipToken` for conditional queries.
