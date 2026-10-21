# Unit / component tests (Vitest or Jest + RTL)

## Differences that bite
| | Vitest | Jest |
|---|---|---|
| mocks | `vi.fn()`, `vi.mock()`, `vi.spyOn` | `jest.fn()`, `jest.mock()` |
| globals | `globals: true` in config, or import from `vitest` | global by default |
| env | `environment: 'jsdom'` (or `happy-dom`) | `testEnvironment: 'jsdom'` (`jest-environment-jsdom`) |
| setup | `setupFiles: ['./vitest.setup.ts']` | `setupFilesAfterEnv: ['<rootDir>/jest.setup.ts']` |
| jest-dom | `import '@testing-library/jest-dom/vitest'` | `import '@testing-library/jest-dom'` |
| TS/JSX | native via Vite | `next/jest`, `ts-jest` or `@swc/jest` |
| paths | `vite-tsconfig-paths` or `resolve.alias` | `moduleNameMapper: { '^@/(.*)$': '<rootDir>/src/$1' }` |
| CSS modules | handled | `identity-obj-proxy` |

Next: `const createJestConfig = require('next/jest')({ dir: './' })`.

## Minimal Vitest config (only if the package has none)
```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()],
  test: { environment: 'jsdom', globals: true, setupFiles: ['./vitest.setup.ts'], css: true },
});
```
```ts
// vitest.setup.ts
import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach } from 'vitest';
afterEach(() => cleanup());
```

## Component test
```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

describe('<Button>', () => {
  it('fires onClick on click and keyboard', async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Save</Button>);
    const btn = screen.getByRole('button', { name: 'Save' });
    await user.click(btn);
    btn.focus();
    await user.keyboard('{Enter}');
    expect(onClick).toHaveBeenCalledTimes(2);
  });

  it('is disabled and busy while loading', () => {
    render(<Button loading>Save</Button>);
    const btn = screen.getByRole('button', { name: /save/i });
    expect(btn).toBeDisabled();
    expect(btn).toHaveAttribute('aria-busy', 'true');
  });
});
```

## Hook test
```ts
import { renderHook, act } from '@testing-library/react';
it('debounces the value', () => {
  vi.useFakeTimers();
  const { result, rerender } = renderHook(({ v }) => useDebounce(v, 300), { initialProps: { v: 'a' } });
  rerender({ v: 'ab' });
  expect(result.current).toBe('a');
  act(() => vi.advanceTimersByTime(300));
  expect(result.current).toBe('ab');
  vi.useRealTimers();
});
```

## Providers helper
```tsx
// test/utils.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, type RenderOptions } from '@testing-library/react';
import type { ReactElement, ReactNode } from 'react';

export function renderWithProviders(ui: ReactElement, options?: RenderOptions) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const Wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return { client, ...render(ui, { wrapper: Wrapper, ...options }) };
}
```
Add the store (fresh `makeStore(preloadedState)`), theme or router (`MemoryRouter`) as the app needs.

## a11y
If `jest-axe`/`vitest-axe` exists: `expect(await axe(container)).toHaveNoViolations()`.

## Next.js mocks
```ts
vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn(), back: vi.fn() }),
  useSearchParams: () => new URLSearchParams(''),
  usePathname: () => '/',
}));
```
Async Server Components can't be rendered by RTL. Test their data functions separately, and cover the page with Playwright.
