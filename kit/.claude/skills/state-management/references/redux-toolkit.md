# Redux Toolkit (v2)

```ts
// store/index.ts
import { configureStore, combineReducers } from '@reduxjs/toolkit';
import { cartSlice } from '../features/cart/cartSlice';
import { productsApi } from '../services/productsApi';

const rootReducer = combineReducers({
  [cartSlice.reducerPath]: cartSlice.reducer,
  [productsApi.reducerPath]: productsApi.reducer,
});
export type RootState = ReturnType<typeof rootReducer>;

export const makeStore = (preloadedState?: Partial<RootState>) =>
  configureStore({
    reducer: rootReducer,
    preloadedState,
    middleware: (gDM) => gDM().concat(productsApi.middleware),
  });
export type AppStore = ReturnType<typeof makeStore>;
export type AppDispatch = AppStore['dispatch'];

// store/hooks.ts
import { useDispatch, useSelector } from 'react-redux';
export const useAppDispatch = useDispatch.withTypes<AppDispatch>();
export const useAppSelector = useSelector.withTypes<RootState>();
```
```ts
// features/cart/cartSlice.ts
import { createSlice, createSelector, type PayloadAction } from '@reduxjs/toolkit';

type CartItem = { id: string; title: string; price: number; qty: number };
type CartState = { items: CartItem[] };
const initialState: CartState = { items: [] };

export const cartSlice = createSlice({
  name: 'cart',
  initialState,
  reducers: {
    itemAdded(state, action: PayloadAction<Omit<CartItem, 'qty'>>) {
      const existing = state.items.find((i) => i.id === action.payload.id);
      if (existing) existing.qty += 1; // Immer: "mutations" are safe here
      else state.items.push({ ...action.payload, qty: 1 });
    },
    itemRemoved(state, action: PayloadAction<string>) {
      state.items = state.items.filter((i) => i.id !== action.payload);
    },
  },
  selectors: {
    selectItems: (s) => s.items,
  },
});
export const { itemAdded, itemRemoved } = cartSlice.actions;
export const { selectItems } = cartSlice.selectors;
export const selectCartTotal = createSelector([selectItems], (items) => items.reduce((t, i) => t + i.price * i.qty, 0));
```
- Async without RTK Query: `createAsyncThunk` + `extraReducers` (pending, fulfilled, rejected). Prefer RTK Query for server data.
- Next App Router: create the store per request in a client `StoreProvider` (`useRef(makeStore())`), never as a module singleton on the server.
- Tests: reducer tests are pure (`cartSlice.reducer(state, itemAdded(x))`). Component tests use `renderWithProviders(ui, { preloadedState })` with a fresh `makeStore`.
