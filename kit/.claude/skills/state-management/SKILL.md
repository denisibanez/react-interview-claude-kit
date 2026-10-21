---
name: state-management
description: Decide where state lives and which tool holds it — server cache (query lib), URL state, form state, local UI state, shared client state — and choose/justify Context vs Zustand vs Redux Toolkit (vs Jotai) with a decision matrix, migration paths and interview answers. Includes typed store setup, slices, selectors, persistence, SSR/Next per-request stores and testing. Use when adding cart/filters/auth/theme/wizard/global UI state or when the user mentions redux, toolkit, zustand, context, jotai, store or global state.
---

# State: put it in the right place first

| Kind of state | Lives in | Notes |
|---|---|---|
| Server data (lists, details) | TanStack Query / RTK Query / SWR / RSC | **never copy it into Redux/Zustand** |
| Filters, search, page, tab, selected id | URL (`useSearchParams`) | shareable, back button, SSR friendly |
| Form fields & validation | react-hook-form (or local state) | `forms` skill |
| Local UI (open, hover, step) | `useState` / `useReducer` | colocate; lift only when needed |
| Shared client state (cart, session UI, wizard, theme) | the repo's lib: Zustand / RTK / Context | load the matching reference |

Talking point: "I keep server cache and client state separate. That removes most global state, and with it the sync bugs."

## Choosing the shared-state tool
**If the repo already has one, use it.** Adding a second state lib is a red flag. Only choose when there's none.

| | Context + useReducer | Zustand | Redux Toolkit (+ RTK Query) | Jotai |
|---|---|---|---|---|
| Best for | low-frequency, tree-scoped values: theme, auth user, locale, DS config, compound components | app-wide client state with little ceremony: cart, UI prefs, wizard | large apps, many devs, complex flows, devtools/time travel, RTK Query already in use | many small independent atoms, derived state graphs |
| Re-renders | every consumer re-renders on any change (split contexts, memo value) | selector-based, only what you pick | selector-based (`useSelector`) | per atom |
| Boilerplate | low | lowest | medium (slices are fine) | low |
| Outside React | no | yes (`store.getState()`), handy in interceptors | yes (`store.getState()`/`dispatch`) | with `store` API |
| Middleware / devtools | none | `devtools`, `persist`, `immer` | built-in devtools, listener middleware, thunks | devtools add-on |
| SSR / Next | natural (provider per tree) | **per-request store via context** (no module singleton on the server) | `makeStore()` per request in a client provider | Provider per request |
| Dep | none | ~1 KB | RTK + react-redux | small |

Rules of thumb:
- Context is **dependency injection**, not a state manager. Fine for values that rarely change; for frequent updates read by many components, use a selector store.
- Server data never goes in any of these: query lib / RTK Query.
- No lib and a small need → Context + useReducer (zero deps, easy to justify). Growing → Zustand. Team-scale conventions, heavy async flows or RTK Query already present → RTK.

Interview answers:
- "Why not Redux?" → "The shared client state is a cart and a couple of UI flags; server data is in the query cache. Zustand gives selector subscriptions without the ceremony. If flows grew (many devs, complex async, devtools discipline), RTK is where I'd go, and the store API maps almost 1:1."
- "Why not just Context?" → "Context re-renders every consumer on each change. For a cart updated often and read in the header, list and drawer, a selector store avoids that. For theme or auth user, Context is perfect."
- "Why Redux here?" → "The repo already uses RTK and RTK Query; consistency beats preference. I added one slice following their pattern."
- Migration: Context+reducer → Zustand/RTK keeps the same reducer/actions; components switch from `useContext` to selectors.

## Next.js App Router caveat
Module-level stores are shared across requests on the server. Create the store per request inside a client provider (`useRef(createStore())` / `makeStore()`), and keep server components store-free (they get data by fetching).

## References (load the one in STACK.md)
- Zustand → `references/zustand.md`
- Redux Toolkit → `references/redux-toolkit.md`
- Context + useReducer (no lib, or small scope) → `references/context.md`

## Rules
- Derive, don't store: totals, filtered lists and flags are computed with selectors/`useMemo` only when they're expensive.
- Subscribe narrowly: selectors pick only what the component needs, which avoids re-renders.
- Actions are named by intent (`addedToCart`, `addItem`), not as setters for every field.
- The store is testable without React: test reducers/actions as pure functions.
