# CSS Modules / SCSS Modules

Variants go through **data attributes** (no class-name string juggling, and they're easy to target in tests and themes).

```tsx
// Badge.tsx
import type { ComponentProps } from 'react';
import clsx from 'clsx'; // or the repo's cn / classnames
import styles from './Badge.module.scss';

export type BadgeProps = ComponentProps<'span'> & {
  tone?: 'neutral' | 'success' | 'warning' | 'danger';
  size?: 'sm' | 'md';
};

export function Badge({ tone = 'neutral', size = 'md', className, ...props }: BadgeProps) {
  return <span data-tone={tone} data-size={size} className={clsx(styles.root, className)} {...props} />;
}
```
```scss
// Badge.module.scss: tokens only, via CSS vars
.root {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  border-radius: var(--radius-full);
  font: var(--font-label-sm);

  &[data-size='sm'] { padding: var(--space-0-5) var(--space-2); }
  &[data-size='md'] { padding: var(--space-1) var(--space-3); }

  &[data-tone='neutral'] { background: var(--color-bg-neutral-subtle); color: var(--color-text-default); }
  &[data-tone='success'] { background: var(--color-bg-success-subtle); color: var(--color-text-success); }
  &[data-tone='warning'] { background: var(--color-bg-warning-subtle); color: var(--color-text-warning); }
  &[data-tone='danger']  { background: var(--color-bg-danger-subtle);  color: var(--color-text-danger); }
}
```
- Interactive states: `&:hover:not(:disabled)`, `&:focus-visible { outline: 2px solid var(--color-focus); outline-offset: 2px; }`.
- Breakpoints: use a shared mixin (`@include mq(md)`) if the repo has one, otherwise `@media (min-width: ...)` with token values.
- TS typing for `*.module.scss`: check that a `declare module '*.module.scss'` exists (Next/Vite ship it).
- Use the SCSS `@use` module system, not `@import` (deprecated).
