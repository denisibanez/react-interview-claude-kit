# Patterns and performance

## Composition (prefer, in order)
1. **`children`**: the default slot. `<Card>{content}</Card>`.
2. **Named slots as props**: `<PageHeader title actions={<Button/>} />` when the layout has fixed regions.
3. **Compound components** (shared Context): `<Tabs><Tabs.List><Tabs.Trigger/></Tabs.List><Tabs.Panel/></Tabs>` for widgets whose parts coordinate state. Throw a helpful error if a part is used outside the root.
4. **Render props**: `renderItem={(item) => ...}` when the parent owns data and the consumer owns markup (lists, comboboxes, virtualised rows).
5. **`asChild` / polymorphic `as`**: render a `Link` styled as a `Button` without nesting interactive elements.
6. **HOCs**: avoid in new code (typing pain, wrapper hell). Mention only for legacy (`connect`, `withRouter`).

Talking point: "Composition over configuration: a new requirement becomes a new child, not a new boolean prop."

## Controlled vs uncontrolled
- Controlled (`value` + `onChange`): parent needs the value live (validation as you type, syncing with URL).
- Uncontrolled (`defaultValue` + ref/FormData): simple forms, performance, server actions.
- DS components support **both** through `useControllableState`. Never switch between modes during the component's life.

## Error and loading boundaries
- `<Suspense fallback={<Skeleton/>}>` around data that suspends (RSC, `use`, `useSuspenseQuery`, `lazy`). Place it where a skeleton keeps the layout stable.
- Error boundary (class component, or `react-error-boundary`, or Next `error.tsx`) at the route and around risky widgets, with a retry. Errors in event handlers are not caught: handle them in the handler.
- Placement is a design decision: one boundary per independent region, so one failing widget doesn't blank the page.

## Code splitting
`lazy(() => import('./HeavyChart'))` + `Suspense` for heavy, below-the-fold or route-level code. Next: `next/dynamic` (with `ssr: false` only for browser-only libs).

## Lists
- Stable `key` from data. Extract the row into a component, `memo` it when the list is long and the parent re-renders often.
- > ~200 rows visible → virtualise (`@tanstack/react-virtual`), ask before adding the dep.
- Pagination/infinite: state in the URL, `keepPreviousData` to avoid flicker.

## Re-render diagnosis (measure before optimising)
1. React DevTools Profiler → "Highlight updates" + "Why did this render?".
2. Common causes and fixes:
   - state too high → move it down / colocate;
   - context value recreated each render → `useMemo` the value, split state/dispatch contexts;
   - big context consumed by many → selector store (Zustand/RTK) or split contexts;
   - new object/function props to a `memo` child → `useMemo`/`useCallback`, or pass primitives;
   - expensive child under a frequently updating parent → pass it as `children` (it won't re-render).
3. Typing lag → `useTransition`/`useDeferredValue`, debounce the request.

## Accessibility patterns that impress a DS team
- Roving tabindex for composite widgets (tabs, toolbar, radio group), arrows to move, Home/End.
- Focus management: move focus into dialogs, trap, restore on close; move focus to the heading after client navigation.
- Live regions (`aria-live="polite"`) for async results ("12 results").
- `prefers-reduced-motion` respected by animations.
