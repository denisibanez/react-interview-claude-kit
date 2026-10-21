# Tailwind + cva (the candidate's own style, upgraded)

`cn` helper (usually already in `lib/utils.ts`):
```ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
export const cn = (...inputs: ClassValue[]) => twMerge(clsx(inputs));
```

## Button (React 19: ref is a regular prop)
```tsx
// Button.styles.ts
import { cva, type VariantProps } from 'class-variance-authority';

export const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 rounded-md font-medium transition-colors ' +
    'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-focus focus-visible:ring-offset-2 ' +
    'disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        primary: 'bg-action-primary text-on-action hover:bg-action-primary-hover',
        secondary: 'bg-surface border border-default text-default hover:bg-surface-hover',
        ghost: 'bg-transparent text-default hover:bg-surface-hover',
        danger: 'bg-danger text-on-action hover:bg-danger-hover',
      },
      size: { sm: 'h-8 px-3 text-sm', md: 'h-10 px-4 text-base', lg: 'h-12 px-6 text-lg' },
      fullWidth: { true: 'w-full' },
    },
    defaultVariants: { variant: 'primary', size: 'md' },
  },
);
export type ButtonVariants = VariantProps<typeof buttonVariants>;
```
```tsx
// Button.tsx
import type { ComponentProps, ReactNode } from 'react';
import { cn } from '../../lib/utils';
import { buttonVariants, type ButtonVariants } from './Button.styles';
import { Spinner } from '../Spinner';

export type ButtonProps = ComponentProps<'button'> &
  ButtonVariants & { loading?: boolean; iconLeft?: ReactNode; iconRight?: ReactNode };

export function Button({
  className, variant, size, fullWidth, loading = false, iconLeft, iconRight,
  disabled, children, type = 'button', ...props
}: ButtonProps) {
  return (
    <button
      type={type}
      className={cn(buttonVariants({ variant, size, fullWidth }), className)}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      {...props}
    >
      {loading ? <Spinner aria-hidden /> : iconLeft}
      {children}
      {!loading && iconRight}
    </button>
  );
}
```
React ≤18: `export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(props, ref) {...})`, using `ComponentPropsWithoutRef<'button'>`.

`asChild` (if the repo uses Radix): `const Comp = asChild ? Slot : 'button'`, from `@radix-ui/react-slot`.

## TextField with correct a11y wiring
```tsx
import { useId, type ComponentProps } from 'react';
import { cn } from '../../lib/utils';

export type TextFieldProps = Omit<ComponentProps<'input'>, 'size'> & {
  label: string;
  helperText?: string;
  error?: string;
};

export function TextField({ label, helperText, error, className, id, ...props }: TextFieldProps) {
  const autoId = useId();
  const inputId = id ?? autoId;
  const describedBy = error ? `${inputId}-error` : helperText ? `${inputId}-help` : undefined;

  return (
    <div className={cn('flex flex-col gap-1', className)}>
      <label htmlFor={inputId} className="text-sm font-medium text-default">{label}</label>
      <input
        id={inputId}
        aria-invalid={error ? true : undefined}
        aria-describedby={describedBy}
        className={cn(
          'h-10 rounded-md border border-default bg-surface px-3 text-default',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-focus',
          error && 'border-danger',
        )}
        {...props}
      />
      {error ? (
        <p id={`${inputId}-error`} role="alert" className="text-sm text-danger">{error}</p>
      ) : helperText ? (
        <p id={`${inputId}-help`} className="text-sm text-muted">{helperText}</p>
      ) : null}
    </div>
  );
}
```
Works with react-hook-form via `{...register('email')}`, since it spreads native props. With React ≤18, wrap it in `forwardRef` so `register`'s ref reaches the input.

## Notes
- Class names like `bg-action-primary` assume semantic tokens exist (`ds-tokens`). Use the repo's real token names.
- Keep complex conditional classes in `cva` `compoundVariants`, not in inline ternaries.
- Prettier + `prettier-plugin-tailwindcss` sorts the classes (if the repo has it).
