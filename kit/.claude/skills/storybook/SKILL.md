---
name: storybook
description: Write or fix Storybook stories and config — typed CSF3 stories (no any), variant matrices, interaction tests with play functions, a11y addon, decorators for providers (theme, QueryClient, store, router), MSW for data components, foundation/token docs, Storybook 8 vs 9 differences, Next vs Vite frameworks. Use whenever a component is created/changed or the user mentions Storybook.
---

# Storybook

## Version check
- **SB 9**: test utils come from `storybook/test`; `@storybook/addon-essentials` is built in; the Vitest integration is `@storybook/addon-vitest`. The framework package is `@storybook/nextjs`, `@storybook/nextjs-vite` or `@storybook/react-vite`.
- **SB 8**: test utils come from `@storybook/test`; essentials is a separate addon.
- Import `Meta`/`StoryObj` from the framework package the repo uses (`@storybook/react-vite`, `@storybook/nextjs`), or from `@storybook/react`.

## Typed CSF3 story, never `Meta<any>`
```tsx
import type { Meta, StoryObj } from '@storybook/react-vite';
import { expect, fn, userEvent, within } from 'storybook/test'; // SB8: '@storybook/test'
import { Button } from './Button';

const meta = {
  title: 'Components/Button',          // follow the repo's hierarchy
  component: Button,
  tags: ['autodocs'],
  args: { children: 'Button', onClick: fn() },
  argTypes: {
    variant: { control: 'inline-radio', options: ['primary', 'secondary', 'ghost', 'danger'] },
    size: { control: 'inline-radio', options: ['sm', 'md', 'lg'] },
  },
  parameters: { layout: 'centered' },
} satisfies Meta<typeof Button>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Primary: Story = {};
export const Secondary: Story = { args: { variant: 'secondary' } };
export const Loading: Story = { args: { loading: true } };
export const Disabled: Story = { args: { disabled: true } };

export const AllVariants: Story = {
  render: (args) => (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, max-content)', gap: 'var(--space-4)' }}>
      {(['primary', 'secondary', 'ghost', 'danger'] as const).flatMap((variant) =>
        (['sm', 'md', 'lg'] as const).map((size) => (
          <Button key={`${variant}-${size}`} {...args} variant={variant} size={size}>{variant} {size}</Button>
        )),
      )}
    </div>
  ),
};

export const ClickInteraction: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole('button', { name: /button/i }));
    await expect(args.onClick).toHaveBeenCalledOnce();
  },
};
```

## Decorators / providers (in `.storybook/preview.tsx`)
```tsx
import type { Preview } from '@storybook/react-vite';
import '../src/styles/globals.css'; // tokens + base styles

const preview: Preview = {
  globalTypes: {
    theme: { description: 'Theme', toolbar: { icon: 'mirror', items: ['light', 'dark'], dynamicTitle: true } },
  },
  initialGlobals: { theme: 'light' },
  decorators: [
    (Story, ctx) => {
      document.documentElement.dataset.theme = ctx.globals.theme;
      return <Story />;
    },
  ],
  parameters: { a11y: { test: 'error' } }, // SB9 a11y addon: fail on violations
};
export default preview;
```
- QueryClient: create one per story (`retry: false`) and wrap it in `QueryClientProvider`.
- Redux/Zustand: a decorator that creates a fresh store with `preloadedState` from `parameters.store`.
- Next: `@storybook/nextjs` mocks `next/navigation` and `next/image`. Use `parameters.nextjs.appDirectory: true` for App Router components.
- Data components: `msw-storybook-addon` with `parameters.msw.handlers`, reusing the same handlers as the tests.

## What DS reviewers like to see
- One story per meaningful state, plus the `AllVariants` matrix.
- Interaction tests (`play`) for behaviour, and the a11y panel clean.
- Foundations docs: Colors, Typography, Spacing, Elevation rendered from tokens (`Foundations/*`).
- `parameters.docs.description.component` with one paragraph of usage guidance (when to use, when not to).
- Visual regression: Chromatic (if configured) or Playwright screenshots of story iframes (`/iframe.html?id=components-button--all-variants`).

## Commands
`pnpm --filter <ui-pkg> storybook` (dev), `build-storybook` (CI). SB9 + Vitest: `vitest --project storybook`.
