# Wrapping a UI library (MUI, Chakra, Mantine, Ant, Radix, shadcn)

Principle: **the app imports from our DS package, never from the vendor directly.** The DS wraps the vendor, which buys a stable API, our tokens and a swappable vendor.

## Themed library (MUI / Chakra / Mantine)
- Tokens go into the theme (`createTheme({ palette, spacing, shape, typography, components })`). Variants live in `components.MuiButton.variants` / `styleOverrides`, not in ad-hoc `sx` across the app.
- The wrapper narrows the API to what the DS supports:
```tsx
import MuiButton, { type ButtonProps as MuiButtonProps } from '@mui/material/Button';
export type ButtonProps = Omit<MuiButtonProps, 'variant' | 'color'> & { variant?: 'primary' | 'secondary' | 'ghost' };
const map = { primary: { variant: 'contained', color: 'primary' }, secondary: { variant: 'outlined', color: 'primary' }, ghost: { variant: 'text', color: 'inherit' } } as const;
export function Button({ variant = 'primary', ...props }: ButtonProps) {
  return <MuiButton disableElevation {...map[variant]} {...props} />;
}
```
- `sx` is fine for one-off layout. Repeated styling belongs in the theme.

## Headless (Radix / Headless UI / React Aria)
- The vendor gives behaviour + a11y. We add styling with tokens. Re-export compound parts with our styles:
```tsx
import * as RadixTabs from '@radix-ui/react-tabs';
export const Tabs = RadixTabs.Root;
export function TabsList({ className, ...p }: RadixTabs.TabsListProps) { return <RadixTabs.List className={cn('flex gap-2 border-b border-default', className)} {...p} />; }
export function TabsTrigger({ className, ...p }: RadixTabs.TabsTriggerProps) {
  return <RadixTabs.Trigger className={cn('px-3 py-2 text-muted data-[state=active]:text-default data-[state=active]:border-b-2 data-[state=active]:border-action-primary', className)} {...p} />;
}
export const TabsContent = RadixTabs.Content;
```
- Style states through `data-state` / `data-disabled` attributes.

## shadcn/ui
- Components are copied into the repo (`components/ui`). They already follow cva + cn + Radix. Edit them in place to use our tokens. `components.json` tells you the aliases. Run the CLI to add one only if the user OKs it (it's a code generator, not a dependency, but it touches files).
