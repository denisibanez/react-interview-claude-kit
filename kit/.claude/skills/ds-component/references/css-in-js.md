# styled-components / Emotion

Use transient props (`$variant`) so styling props don't leak into the DOM. Values come from the typed theme.

```tsx
import styled, { css } from 'styled-components';
import type { ComponentProps } from 'react';

type Variant = 'primary' | 'secondary';
type Size = 'sm' | 'md';

const sizeStyles = {
  sm: css`height: ${({ theme }) => theme.space[8]}; padding: 0 ${({ theme }) => theme.space[3]};`,
  md: css`height: ${({ theme }) => theme.space[10]}; padding: 0 ${({ theme }) => theme.space[4]};`,
} satisfies Record<Size, ReturnType<typeof css>>;

const Root = styled.button<{ $variant: Variant; $size: Size }>`
  border-radius: ${({ theme }) => theme.radius.md};
  ${({ $size }) => sizeStyles[$size]}
  ${({ theme, $variant }) =>
    $variant === 'primary'
      ? css`background: ${theme.color.action.primary.bg}; color: ${theme.color.action.primary.fg};`
      : css`background: ${theme.color.bg.surface}; color: ${theme.color.text.default};`}
  &:focus-visible { outline: 2px solid ${({ theme }) => theme.color.focus}; outline-offset: 2px; }
`;

export type ButtonProps = ComponentProps<'button'> & { variant?: Variant; size?: Size };
export function Button({ variant = 'primary', size = 'md', ...props }: ButtonProps) {
  return <Root $variant={variant} $size={size} {...props} />;
}
```
Theme typing:
```ts
// styled.d.ts
import 'styled-components';
import type { AppTheme } from './theme';
declare module 'styled-components' { export interface DefaultTheme extends AppTheme {} }
```
For Emotion, augment `Theme` from `@emotion/react` the same way.
With Next App Router, styled-components needs the registry (`lib/registry.tsx` with `useServerInsertedHTML`) and client components only.
