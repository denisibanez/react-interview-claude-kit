# Hooks: when, when not, pitfall, interview line

| Hook | Use when | Don't use when | Pitfall | Say it like this |
|---|---|---|---|---|
| `useState` | independent local value | value can be derived; shared across distant components | stale closure → functional update; objects must be replaced, not mutated | "Local, independent, owned by this component." |
| `useReducer` | several fields change together, explicit transitions (wizard, status machine, cart) | one boolean | forgetting exhaustiveness → `never` check in `default` | "Transitions are named and the reducer is a pure function I can unit test." |
| `useEffect` | sync with something **external**: subscription, DOM API, non-React widget, analytics, fetch **without** a query lib | deriving data, reacting to an event, resetting state on prop change, chaining state updates | missing cleanup, missing deps, runs twice in StrictMode dev (that's on purpose) | "Effects are for syncing with the outside world; everything else is render or handlers." |
| `useLayoutEffect` | measure DOM and re-position **before paint** (tooltip, popover, auto-size) | anything not visual | blocks paint; warns on SSR (use an isomorphic wrapper or `useEffect`) | "I need the measurement before the browser paints, otherwise it flickers." |
| `useRef` | DOM node, timer id, previous value, latest callback, instance value that must not re-render | data shown on screen | reading/writing `ref.current` during render | "It's mutable and doesn't trigger a render." |
| `useMemo` | measurably expensive calc; referential stability for a memoised child or an effect dep | cheap calcs "just in case" | wrong deps = stale value | "Memoised because it feeds `memo(List)`; otherwise it'd break its memo every render." |
| `useCallback` | callback passed to a `memo` child or used as an effect/hook dep | inline handlers on DOM elements | useless if the child isn't memoised | same as above |
| `memo` | pure, expensive child that re-renders with the same props | everything | new object/array/fn props defeat it | "The profiler showed X re-rendering N times on each keystroke." |
| `useContext` | low-frequency shared values (theme, auth user, locale, DS config, compound component wiring) | high-frequency updates to many consumers | every consumer re-renders on any change → split contexts, memo the value | "Context is dependency injection, not a state manager." |
| `useId` | ids for `htmlFor`, `aria-describedby`, `aria-controls` | list keys | ids derived from labels collide | "SSR-safe unique ids for a11y wiring." |
| `useTransition` | non-urgent update that may be slow (filtering a big list, tab switch, router push) | input value itself | can't wrap controlled input value | "Typing stays responsive; the heavy update is interruptible." |
| `useDeferredValue` | show stale results while the new ones render (search results from a typed query) | debouncing network requests (that's a debounce) | it's not a debounce: requests still fire per value | "Rendering priority, not request throttling." |
| `useSyncExternalStore` | subscribe to an external store / browser API (`matchMedia`, `navigator.onLine`, a custom store) | React state | `getSnapshot` must return a cached value | "Tearing-safe subscription to something React doesn't own." |
| `useImperativeHandle` | DS component exposing a narrow imperative API (`focus()`, `open()`) | normal data flow | leaks implementation | "Expose only `focus`, not the DOM node." |
| `use` (19) | unwrap a promise passed from a server component (with Suspense) or read context conditionally | creating promises in render | uncached promise in render = infinite suspend | "Server starts the fetch, client streams it in." |
| `useActionState` (19) | form submit with server/async action, pending + returned state | client-only complex forms (use RHF) | action signature `(prevState, formData)` | "Progressive enhancement, works before JS loads." |
| `useOptimistic` (19) | instant UI for a mutation that usually succeeds (like, add to list) | expensive rollbacks | must be inside a transition/action | "Optimistic with automatic rollback when the action settles." |
| `useFormStatus` (19) | submit button inside a `<form action>` reading `pending` | outside a form | must be in a **child** of the form | "The DS SubmitButton knows its own pending state." |
| `useEffectEvent` (19.2) | read latest props/state inside an effect without re-running it | event handlers | only call it from effects | "Separates the reactive part from the non-reactive part." |

## Effect smells → fix
```tsx
// ✗ derived state via effect
const [full, setFull] = useState(''); useEffect(() => setFull(`${first} ${last}`), [first, last]);
// ✓
const full = `${first} ${last}`;

// ✗ reset on prop change
useEffect(() => setDraft(''), [userId]);
// ✓ remount with a key
<Editor key={userId} />

// ✗ event logic in effect
useEffect(() => { if (submitted) post(data) }, [submitted]);
// ✓ in the handler
const onSubmit = () => post(data);

// ✓ legit effect: fetch without a query lib
useEffect(() => {
  const ctrl = new AbortController();
  dispatch({ type: 'loading' });
  api.list(q, ctrl.signal)
    .then((data) => dispatch({ type: 'success', data }))
    .catch((e) => { if (!ctrl.signal.aborted) dispatch({ type: 'error', error: e }) });
  return () => ctrl.abort();
}, [q]);
```

## Custom hooks worth having (write only if the repo lacks them)
- `useDebouncedValue(value, ms)`: `useState` + `useEffect` with `setTimeout`/cleanup.
- `useControllableState({ value, defaultValue, onChange })`: DS controlled/uncontrolled (see `ds-component/references/patterns.md`).
- `useMediaQuery(query)`: `useSyncExternalStore` with `matchMedia`.
- `useDisclosure()`: `{ isOpen, open, close, toggle }` for overlays.
Test custom hooks with `renderHook` from Testing Library.
