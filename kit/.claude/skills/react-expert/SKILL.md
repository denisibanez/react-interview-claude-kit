---
name: react-expert
description: Senior React/Next judgement — pick the right hook, the right rendering/data approach and the right component pattern, and justify it. Covers useState vs useReducer, when NOT to useEffect, useMemo/useCallback/memo, useRef, useLayoutEffect, useId, useTransition/useDeferredValue, useSyncExternalStore, React 19 (use, useActionState, useOptimistic, useFormStatus), custom hooks, Suspense/error boundaries, composition patterns, performance and Next server/client decisions. Use when writing or reviewing any component or hook logic, when the user asks "which hook/approach is best", or mentions re-renders, effects, performance or patterns. For "Context vs Zustand vs Redux" use the state-management skill instead.
---

# React expert: choose, then justify

Every choice must fit in one sentence at the checkpoint: **"I used X because Y; Z would cost W."**

## 1. Decision tree: where does this value come from?
1. Can it be **computed** from props/state/URL? → compute it in render. Not state, not an effect.
2. Does it come from the **server**? → query lib / RSC (`api-layer`). Never `useEffect` + `useState` if a query lib exists.
3. Is it in the **URL** (filter, tab, page, selected id)? → `useSearchParams` / router.
4. Is it **form** input? → react-hook-form or uncontrolled + FormData (`forms`).
5. Is it **local UI** (open, hover, step)? → `useState`; several fields that change together or have transitions → `useReducer`.
6. Is it **shared client state**? → `state-management` (Context vs Zustand vs RTK matrix).
7. Does it **not affect rendering** (timer id, previous value, DOM node, latest callback)? → `useRef`.
8. Does it live **outside React** (browser API, third-party store, `matchMedia`, `online`)? → `useSyncExternalStore`.

## 2. Hook cheat sheet → `references/hooks.md`
Each hook with "use when / don't use when / pitfall / interview line". Load it when choosing or reviewing hooks.

## 3. Patterns and performance → `references/patterns.md`
Composition (children, slots, compound, render props, `asChild`), custom hooks, controlled/uncontrolled, error boundaries + Suspense, portals, lists/virtualisation, re-render diagnosis.

## 4. Next.js decisions → `nextjs` skill, section "Decision guide"
RSC vs client, server action vs route handler vs client fetch, caching, streaming.

## Non-negotiables (a senior reviewer flags these)
- No effect to derive data, to reset state on prop change (use `key`), or to handle an event (put it in the handler).
- Every effect that subscribes/fetches has a cleanup (`AbortController`, `removeEventListener`, `clearTimeout`).
- Complete dependency arrays. If a dep "causes loops", the design is wrong (move the function inside the effect, use a functional update, or an effect event).
- Functional updates when the next state depends on the previous one: `setCount(c => c + 1)`.
- Stable keys from data, never the index for dynamic lists.
- `memo`/`useMemo`/`useCallback` only with a reason (expensive calc, memoised child, effect dep). If the repo uses the **React Compiler**, don't add them by hand.
- Hooks: top level only, custom hooks start with `use`, return a stable small API (`{ data, status, actions }` or a tuple of 2).
- Types: props as `type Props = ComponentProps<'button'> & {...}`, events as `React.ChangeEvent<HTMLInputElement>`, children as `ReactNode`, no `React.FC` unless the repo uses it.
