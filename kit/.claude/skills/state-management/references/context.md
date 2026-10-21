# Context + useReducer (no library)

Split state and dispatch so components that only dispatch don't re-render, and memoise the value.

```tsx
import { createContext, useContext, useMemo, useReducer, type Dispatch, type ReactNode } from 'react';

type Item = { id: string; price: number; qty: number };
type State = { items: Item[] };
type Action =
  | { type: 'added'; item: Omit<Item, 'qty'> }
  | { type: 'removed'; id: string }
  | { type: 'cleared' };

export function cartReducer(state: State, action: Action): State {
  switch (action.type) {
    case 'added': {
      const found = state.items.some((i) => i.id === action.item.id);
      return {
        items: found
          ? state.items.map((i) => (i.id === action.item.id ? { ...i, qty: i.qty + 1 } : i))
          : [...state.items, { ...action.item, qty: 1 }],
      };
    }
    case 'removed': return { items: state.items.filter((i) => i.id !== action.id) };
    case 'cleared': return { items: [] };
    default: { const _exhaustive: never = action; return state; }
  }
}

const StateCtx = createContext<State | null>(null);
const DispatchCtx = createContext<Dispatch<Action> | null>(null);

export function CartProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(cartReducer, { items: [] });
  return (
    <DispatchCtx.Provider value={dispatch}>
      <StateCtx.Provider value={state}>{children}</StateCtx.Provider>
    </DispatchCtx.Provider>
  );
}

export function useCart() {
  const s = useContext(StateCtx);
  if (!s) throw new Error('useCart must be used inside <CartProvider>');
  return s;
}
export function useCartDispatch() {
  const d = useContext(DispatchCtx);
  if (!d) throw new Error('useCartDispatch must be used inside <CartProvider>');
  return d;
}
export const useCartTotal = () => {
  const { items } = useCart();
  return useMemo(() => items.reduce((t, i) => t + i.price * i.qty, 0), [items]);
};
```
The reducer is a pure function: test it directly. The `never` check makes adding an action without handling it a compile error, which is a great talking point.
When it outgrows this (many consumers, frequent updates), move to Zustand/RTK for selector-based subscriptions.
