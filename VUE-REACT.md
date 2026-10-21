# Cheat sheet: Vue → React

| Vue 3 | React | Watch out |
|---|---|---|
| `ref()` / `reactive()` | `useState` / `useReducer` | state is immutable: `setX(prev => ...)`, never `obj.a = 1` |
| `computed` | derived value computed in render; `useMemo` only if it's expensive | don't store in state what you can calculate |
| `watch` / `watchEffect` | `useEffect` | only to sync with something **external** (API, DOM, timer). Complete deps + cleanup. Deriving data is not an effect |
| `onMounted` / `onUnmounted` | `useEffect(() => { ...; return cleanup }, [])` | in dev, StrictMode runs the effect twice on purpose |
| `v-model` | `value` + `onChange` (controlled) | or `defaultValue` (uncontrolled) + ref |
| `v-if` / `v-show` | `{cond && <X/>}` / `hidden` or a class | beware `{0 && ...}`, which renders "0". Use `cond ? <X/> : null` or `!!` |
| `v-for` + `:key` | `items.map(i => <X key={i.id} />)` | stable key, never the index |
| `props` + `defineProps` | typed function parameters | `type Props = ComponentProps<'button'> & {...}` |
| `emit('change', v)` | callback prop `onChange(v)` | named `onSomething` |
| slots / named slots | `children` / props that take a `ReactNode` | scoped slot = render prop `renderItem={(i) => ...}` |
| `provide` / `inject` | `createContext` + `useContext` | split state/dispatch to avoid re-renders |
| Pinia | Zustand (closest) / Redux Toolkit | selectors to subscribe only to what you need |
| composables (`useX`) | custom hooks (`useX`) | same idea; rules of hooks: top level only, never inside if/loop |
| `<Teleport>` | `createPortal` | |
| `<Suspense>` | `<Suspense>` + `lazy` / RSC | |
| `<KeepAlive>` | doesn't exist; keep state in the URL/store | |
| `nextTick` | `flushSync` (rare) or an effect | |
| template refs | `useRef` + `ref={el}` | React 19: `ref` is a regular prop on components |
| scoped CSS | CSS Modules / Tailwind / styled | |
| vue-router | react-router / Next App Router | in Next a route is a folder (`app/x/page.tsx`) |
| Vitest + @vue/test-utils | Vitest/Jest + Testing Library | query by role, `userEvent` |

## The 5 React interview gotchas
1. **Stale closure:** `setCount(count + 1)` twice = +1. Use `setCount(c => c + 1)`.
2. **Unnecessary useEffect:** filtering, sorting or deriving data belongs in render, not in an effect + state.
3. **Race condition on fetch:** use an `AbortController` in the cleanup, or React Query.
4. **Re-renders:** a new object or function on every render breaks the child's `memo`. `useCallback`/`useMemo` only when a `memo` or an effect dependency is involved.
5. **Wrong key:** an index as the key scrambles input state when you reorder or remove items.
