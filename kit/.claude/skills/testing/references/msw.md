# MSW v2 (network mocking shared by tests, Storybook and dev)

```ts
// mocks/handlers.ts
import { http, HttpResponse, delay } from 'msw';
import type { ProductPage } from '../products/schemas';

const page: ProductPage = { items: [{ id: '1', title: 'Chair', price: 120 }], total: 1, page: 1 };

export const handlers = [
  http.get('*/products', async ({ request }) => {
    const q = new URL(request.url).searchParams.get('q') ?? '';
    await delay(150);
    return HttpResponse.json({ ...page, items: page.items.filter((p) => p.title.toLowerCase().includes(q.toLowerCase())) });
  }),
];
```
```ts
// mocks/server.ts (node, tests)
import { setupServer } from 'msw/node';
import { handlers } from './handlers';
export const server = setupServer(...handlers);
```
```ts
// in the test setup file
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```
Per-test override for error/empty states:
```ts
server.use(http.get('*/products', () => HttpResponse.json({ message: 'boom' }, { status: 500 })));
server.use(http.get('*/products', () => HttpResponse.json({ items: [], total: 0, page: 1 })));
```
- Browser/Storybook: `setupWorker` from `msw/browser` (needs `npx msw init public/`), or `msw-storybook-addon` with `parameters.msw.handlers`.
- Jest + MSW v2 needs a jsdom environment with the fetch/TextEncoder globals (`jest-fixed-jsdom`). Vitest works out of the box.
