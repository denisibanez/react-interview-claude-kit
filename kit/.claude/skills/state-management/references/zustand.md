# Zustand (v4/v5)

```ts
// stores/cart.ts
import { create } from 'zustand';
import { persist, createJSONStorage, devtools } from 'zustand/middleware';

export type CartItem = { id: string; title: string; price: number; qty: number };

type CartState = {
  items: CartItem[];
  add: (item: Omit<CartItem, 'qty'>) => void;
  remove: (id: string) => void;
  setQty: (id: string, qty: number) => void;
  clear: () => void;
};

export const useCartStore = create<CartState>()(
  devtools(
    persist(
      (set) => ({
        items: [],
        add: (item) =>
          set((s) => {
            const existing = s.items.find((i) => i.id === item.id);
            return {
              items: existing
                ? s.items.map((i) => (i.id === item.id ? { ...i, qty: i.qty + 1 } : i))
                : [...s.items, { ...item, qty: 1 }],
            };
          }),
        remove: (id) => set((s) => ({ items: s.items.filter((i) => i.id !== id) })),
        setQty: (id, qty) => set((s) => ({ items: s.items.map((i) => (i.id === id ? { ...i, qty: Math.max(1, qty) } : i)) })),
        clear: () => set({ items: [] }),
      }),
      { name: 'cart', storage: createJSONStorage(() => localStorage) },
    ),
  ),
);

// selectors: subscribe narrowly
export const selectCartCount = (s: CartState) => s.items.reduce((n, i) => n + i.qty, 0);
export const selectCartTotal = (s: CartState) => s.items.reduce((sum, i) => sum + i.price * i.qty, 0);
```
Usage: `const count = useCartStore(selectCartCount);`. To pick several fields, use `useShallow` (v5: `import { useShallow } from 'zustand/react/shallow'`).
Tests: `useCartStore.setState({ items: [] })` in `beforeEach`; call `useCartStore.getState().add(...)` and assert the state.
Next SSR: persisted stores hydrate on the client. Guard against hydration mismatch (render the count after mount, or use `skipHydration` + `rehydrate()` in an effect).
