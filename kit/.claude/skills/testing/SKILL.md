---
name: testing
description: Test strategy and implementation for React/TS — TDD-lite (tests first for logic/schemas/hooks/reducers), React Testing Library component tests with userEvent and role queries, Jest vs Vitest setup differences, MSW for network, a11y checks with axe, Playwright e2e and visual snapshots, Storybook interaction tests. Use when writing or fixing tests, setting up a runner, or when the user mentions jest, vitest, RTL, playwright, TDD or coverage.
---

# Testing

## Strategy for a 2h challenge (say this out loud, it shows judgement)
1. **Test first, cheap and high value:** pure functions, zod schemas, reducers/slices/stores, custom hooks (`renderHook`). Seconds to write, they drive the design.
2. **One behaviour test per important component:** what the user sees and does. No implementation details.
3. **One Playwright happy path** for the main flow, if Playwright exists or time allows.
4. **Stories** cover visual states. `play` functions cover interactions inside Storybook.
Don't chase coverage numbers. Every test should protect a behaviour you'd hate to break.

## Runner (from STACK.md); load the reference
- Jest or Vitest + RTL → `references/unit.md`
- network mocking → `references/msw.md`
- e2e + visual → `references/playwright.md`

## RTL rules
- Query priority: `getByRole(name)` → `getByLabelText` → `getByText` → `getByTestId` (last resort).
- `const user = userEvent.setup()` before render, then `await user.click(...)`.
- Async: `await screen.findByRole(...)`. Never use arbitrary `waitFor` with sleeps.
- Assert what the user perceives: text, role, state (`toBeDisabled`, `toHaveAttribute('aria-expanded','true')`), calls on callbacks.
- One `renderWithProviders` helper (QueryClient with `retry:false`, a fresh store, theme, router) in `test/utils.tsx`, if the repo doesn't have one.

## Naming
`describe('<Button>')` → `it('calls onClick when pressed with Enter')`. Each name is a behaviour sentence.

## Before saying done
Run only the affected package: `pnpm --filter <pkg> test -- <pattern>` (Vitest: `vitest run <pattern>`; Jest: `jest <pattern>`).
