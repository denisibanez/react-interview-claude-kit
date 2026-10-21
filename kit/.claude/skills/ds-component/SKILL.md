---
name: ds-component
description: Build or extend a reusable design-system component (Button, Input/TextField, Select, Checkbox, Modal/Dialog, Tabs, Card, Badge, Tooltip...) with a typed variant API, ref forwarding, className merging, accessibility, tokens-only styling, a Storybook story and a behaviour test. Adapts to Tailwind+cva, CSS/SCSS Modules, CSS-in-JS or a UI library (MUI/Chakra/Radix/shadcn). Use for any new or changed reusable UI.
---

# DS component

## 0. Before creating
- Search the DS package for an existing component or primitive to extend: `rg -n "export (function|const) " <ui-pkg>/src`.
- If the repo wraps a UI lib (MUI, Radix, shadcn), **wrap and theme it**, don't re-implement it (see `references/ui-library.md`).
- Pick the styling reference that matches STACK.md:
  - Tailwind (+cva) → `references/tailwind-cva.md` (the candidate's own style)
  - CSS / SCSS Modules → `references/css-modules.md`
  - styled-components / Emotion → `references/css-in-js.md`
- Shared patterns (controllable state, compound components, polymorphism) → `references/patterns.md`.

## 1. API contract (what a DS reviewer checks)
- **Native props:** `ComponentPropsWithoutRef<'button'>` / `ComponentProps<'input'>`, spread onto the root element.
- **Ref:** React 19 takes `ref` as a normal prop (no `forwardRef`). React ≤18 uses `forwardRef` + `displayName`. Check the version in STACK.md.
- **`className`:** always merged last (`cn(...)`), so consumers can extend but tokens stay the base.
- **Variants:** string unions (`variant: 'primary' | 'secondary' | 'ghost'`, `size: 'sm' | 'md' | 'lg'`) with defaults, not a soup of booleans. Export the variant type.
- **State:** support controlled + uncontrolled (`value`/`defaultValue`/`onValueChange`) through `useControllableState`.
- **Composition:** slots via `children`, compound components (`Tabs.List`, `Tabs.Trigger`) for complex widgets, and `asChild` (Radix Slot) if the repo uses it, to render a link styled as a button.
- **Naming:** follow the repo (`onValueChange` vs `onChange`, `isDisabled` vs `disabled`).

## 2. Accessibility (non-negotiable)
- Use the semantic element first (`button`, `a`, `input`, `dialog`, `ul/li`). Use ARIA only to fill gaps.
- Labels: `<label htmlFor>` with ids from `useId()`, never ids derived from the label text.
- Errors and help text: `aria-invalid`, plus `aria-describedby` pointing at the help/error ids.
- Keyboard: Tab order, Enter/Space on buttons, arrows inside composite widgets (tabs, menu, radio group), Esc closes overlays, focus trap + focus return on modals.
- Visible focus with `:focus-visible` and a token ring. Disabled: native `disabled`, or `aria-disabled` when it must stay focusable (e.g. a tooltip on a disabled button).
- Icon-only buttons need `aria-label`. Loading: `aria-busy` and keep the width stable.
- Motion respects `prefers-reduced-motion`. Colors come from tokens with adequate contrast.

## 3. Files (adapt to the repo's layout)
```
<ui-pkg>/src/components/Button/
  Button.tsx            # component (< ~150 lines; split sub-parts)
  Button.styles.ts      # cva recipe / styled defs (or Button.module.scss)
  Button.test.tsx       # behaviour + a11y
  Button.stories.tsx    # all variants × states
  index.ts              # export { Button, type ButtonProps } from './Button'
```
Also export it from the package's public `index.ts` (and from the `exports` map if the package uses subpaths).

## 4. Deliverables per component
1. Component + types.
2. Story: Default, every variant, sizes, states (disabled, loading, error, with icon, long text), plus an "All variants" matrix (`storybook` skill).
3. Test: renders by role, main interaction with `userEvent`, keyboard, controlled vs uncontrolled if relevant, axe check if available (`testing` skill).
4. Exported from the package and used in the app (prove the integration).

## 5. Self-check
- [ ] tokens only (no hex/px/arbitrary values)
- [ ] extends native props, ref works, className merges
- [ ] keyboard + screen reader name + focus-visible
- [ ] story + test exist and pass
- [ ] no prop added "just in case"
