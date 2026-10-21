# Reusable DS patterns

## useControllableState (controlled + uncontrolled in one API)
```ts
import { useCallback, useRef, useState } from 'react';

export function useControllableState<T>({
  value, defaultValue, onChange,
}: { value?: T; defaultValue: T; onChange?: (next: T) => void }) {
  const [inner, setInner] = useState(defaultValue);
  const isControlled = value !== undefined;
  const current = isControlled ? value : inner;
  const onChangeRef = useRef(onChange);
  onChangeRef.current = onChange;

  const setValue = useCallback((next: T) => {
    if (!isControlled) setInner(next);
    onChangeRef.current?.(next);
  }, [isControlled]);

  return [current, setValue] as const;
}
```

## Compound components with typed context
```tsx
import { createContext, useContext, useId, type ReactNode } from 'react';

type AccordionCtx = { openId: string | null; toggle: (id: string) => void };
const Ctx = createContext<AccordionCtx | null>(null);
function useAccordion() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('Accordion.* must be used inside <Accordion>');
  return ctx;
}

export function Accordion({ children, defaultOpen = null }: { children: ReactNode; defaultOpen?: string | null }) {
  const [openId, setOpenId] = useControllableState({ defaultValue: defaultOpen });
  return <Ctx.Provider value={{ openId, toggle: (id) => setOpenId(openId === id ? null : id) }}>{children}</Ctx.Provider>;
}

function Item({ value, title, children }: { value: string; title: string; children: ReactNode }) {
  const id = useId(); // DOM ids only; `value` is the public key (works with defaultOpen)
  const { openId, toggle } = useAccordion();
  const open = openId === value;
  return (
    <div>
      <h3>
        <button aria-expanded={open} aria-controls={`${id}-panel`} id={`${id}-trigger`} onClick={() => toggle(value)}>
          {title}
        </button>
      </h3>
      <div id={`${id}-panel`} role="region" aria-labelledby={`${id}-trigger`} hidden={!open}>{children}</div>
    </div>
  );
}
Accordion.Item = Item;
```

## Polymorphic `as` prop (only if the repo already uses it; prefer asChild)
```tsx
import type { ComponentPropsWithoutRef, ElementType } from 'react';
type TextProps<E extends ElementType> = { as?: E; tone?: 'default' | 'muted' } & Omit<ComponentPropsWithoutRef<E>, 'as'>;
export function Text<E extends ElementType = 'p'>({ as, tone = 'default', className, ...p }: TextProps<E>) {
  const Comp = as ?? 'p';
  return <Comp className={cn(tone === 'muted' ? 'text-muted' : 'text-default', className)} {...p} />;
}
```

## Modal / Dialog
Prefer the native `<dialog>` (`showModal()` gives focus trap + Esc + inert backdrop for free) or Radix Dialog. Return focus to the trigger on close, label it with `aria-labelledby`, and lock body scroll.

## Lists / grids with states
Every data component handles **loading** (skeleton keeping the layout), **error** (message + retry), **empty** (illustration/text + CTA) and **success**. Expose `emptyState` / `errorState` slots in the DS.
