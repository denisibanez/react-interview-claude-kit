# Interceptors: auth, refresh, errors, retries, logging

One place for cross-cutting HTTP concerns. Reuse the repo's mechanism if it exists; this is the fallback.

| Concern | Request side | Response side |
|---|---|---|
| Auth | add `Authorization: Bearer <token>` | 401 → refresh once (single flight), retry, else logout |
| Context | `Accept-Language`, `X-Request-Id`, tenant header | — |
| Errors | — | normalise to `ApiError(status, message, body)`; map 4xx/5xx to UI-friendly messages in **one** place |
| Retries | — | retry idempotent requests (GET) on network/5xx with backoff; never retry POST blindly |
| Timeouts / abort | `AbortSignal.timeout(ms)` combined with the caller's signal | — |
| Observability | start time | log duration/status in dev; report 5xx |

## 1. fetch: a tiny interceptor chain (no dependency)
```ts
// shared/http/client.ts
type Req = { url: string; init: RequestInit };
type RequestInterceptor = (req: Req) => Req | Promise<Req>;
type ResponseInterceptor = (res: Response, req: Req, retry: () => Promise<Response>) => Response | Promise<Response>;

export function createHttp(baseUrl: string) {
  const onRequest: RequestInterceptor[] = [];
  const onResponse: ResponseInterceptor[] = [];

  async function send(path: string, init: RequestInit = {}): Promise<Response> {
    let req: Req = { url: `${baseUrl}${path}`, init: { ...init, headers: new Headers(init.headers) } };
    for (const fn of onRequest) req = await fn(req);
    const run = () => fetch(req.url, req.init);
    let res = await run();
    for (const fn of onResponse) res = await fn(res, req, run);
    return res;
  }

  async function json<T>(path: string, init: RequestInit & { parse: (d: unknown) => T }): Promise<T> {
    const { parse, ...rest } = init;
    const res = await send(path, rest);
    const body: unknown = res.status === 204 ? null : await res.json().catch(() => null);
    if (!res.ok) throw new ApiError(res.status, messageFor(res.status, body), body);
    return parse(body);
  }

  return { send, json, interceptors: { request: onRequest, response: onResponse } };
}
```
```ts
// shared/http/index.ts – register once
export const http = createHttp(env.API_URL);

http.interceptors.request.push(({ url, init }) => {
  const headers = new Headers(init.headers);
  const token = authStore.getState().accessToken;          // Zustand/RTK store read outside React
  if (token) headers.set('Authorization', `Bearer ${token}`);
  if (!headers.has('Content-Type') && init.body) headers.set('Content-Type', 'application/json');
  return { url, init: { ...init, headers } };
});

// 401 → refresh once, even if 5 requests fail at the same time (single flight)
let refreshing: Promise<boolean> | null = null;
http.interceptors.response.push(async (res, req, retry) => {
  if (res.status !== 401 || req.url.endsWith('/auth/refresh')) return res;
  refreshing ??= refreshToken().finally(() => { refreshing = null; });
  if (!(await refreshing)) { authStore.getState().logout(); return res; }
  const headers = new Headers(req.init.headers);
  headers.set('Authorization', `Bearer ${authStore.getState().accessToken}`);
  req.init = { ...req.init, headers };
  return retry();
});
```
`messageFor(status, body)` maps status codes to copy (422 → field errors from `body`, 409 → conflict, 5xx → "Something went wrong, try again").

## 2. axios (if the repo uses it)
```ts
export const api = axios.create({ baseURL: env.API_URL, timeout: 10_000 });

api.interceptors.request.use((config) => {
  const token = authStore.getState().accessToken;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

let refreshing: Promise<boolean> | null = null;
api.interceptors.response.use(
  (res) => res,
  async (error: AxiosError) => {
    const original = error.config as (InternalAxiosRequestConfig & { _retry?: boolean }) | undefined;
    if (error.response?.status === 401 && original && !original._retry) {
      original._retry = true;
      refreshing ??= refreshToken().finally(() => { refreshing = null; });
      if (await refreshing) return api(original);
      authStore.getState().logout();
    }
    return Promise.reject(toApiError(error));   // normalise once
  },
);
```
Return the `eject` ids in tests if you register interceptors per test.

## 3. RTK Query: `baseQueryWithReauth`
```ts
const rawBaseQuery = fetchBaseQuery({
  baseUrl: env.API_URL,
  prepareHeaders: (headers, { getState }) => {
    const token = (getState() as RootState).auth.accessToken;
    if (token) headers.set('Authorization', `Bearer ${token}`);
    return headers;
  },
});
const mutex = new Mutex(); // async-mutex (ask before adding) or a module-level promise like above

export const baseQueryWithReauth: BaseQueryFn<string | FetchArgs, unknown, FetchBaseQueryError> = async (args, api, extra) => {
  await mutex.waitForUnlock();
  let result = await rawBaseQuery(args, api, extra);
  if (result.error?.status === 401) {
    if (!mutex.isLocked()) {
      const release = await mutex.acquire();
      try {
        const refresh = await rawBaseQuery({ url: '/auth/refresh', method: 'POST' }, api, extra);
        if (refresh.data) api.dispatch(tokenRefreshed(refreshResponseSchema.parse(refresh.data)));
        else api.dispatch(loggedOut());
      } finally { release(); }
    } else {
      await mutex.waitForUnlock();
    }
    result = await rawBaseQuery(args, api, extra);
  }
  return result;
};
```

## 4. TanStack Query: global error/retry policy (not an interceptor, but the same role)
```ts
new QueryClient({
  defaultOptions: {
    queries: { retry: (count, err) => !(err instanceof ApiError && err.status < 500) && count < 2 },
  },
  queryCache: new QueryCache({ onError: (err, query) => { if (query.meta?.toastOnError) toast.error(errorMessage(err)); } }),
  mutationCache: new MutationCache({ onError: (err) => toast.error(errorMessage(err)) }),
});
```

## 5. Next.js
- Server side: wrap `fetch` in `server/http.ts` that reads the session from `cookies()` and adds the auth header; keep tokens in **httpOnly cookies**, not in JS-readable storage.
- `middleware.ts` = edge interceptor for **routes** (redirect unauthenticated users, i18n, headers), not for API data.
- BFF route handler (`app/api/*`) to hide upstream keys and normalise errors before they reach the browser.

## 6. Tests
- MSW: return 401 once then 200 → assert the refresh endpoint was called **once** for N parallel requests and the original requests succeed.
- Error normalisation: 422 body → `ApiError` with field errors.

Talking point: "Auth, error mapping and retries live in one module, so features never deal with tokens or status codes; the single-flight refresh avoids a refresh storm when several queries 401 at once."
