---
name: ds-tokens
description: Create, extend or consume design tokens (color, typography, spacing, radius, shadow, motion, z-index) and theming/dark mode, wired into whatever styling the repo uses (Tailwind v4 @theme, Tailwind v3 config, SCSS, CSS Modules, CSS-in-JS theme, MUI/Chakra theme). Also maps Figma variables to code tokens. Use when touching colors/spacing/typography, adding a theme, or when a Figma value has no token.
---

# Design tokens

## Model: 3 layers
1. **Primitive (reference)**: raw values with no meaning, e.g. `--color-red-500`, `--space-4: 1rem`, `--radius-2: 8px`.
2. **Semantic (system)**: intent, e.g. `--color-bg-surface`, `--color-text-muted`, `--color-border-danger`, `--color-action-primary-bg`. **Components use only this layer.** Themes (dark, brand) remap only this layer.
3. **Component (optional)**: `--button-primary-bg: var(--color-action-primary-bg)`. Add it only when a component needs an override point.

Naming: `category-property-variant-state`, e.g. `--color-action-primary-bg-hover`. Use kebab-case in CSS and camelCase in TS. Stay consistent with what is already in the repo.

## Source of truth
- **CSS custom properties are the runtime source of truth.** Every styling approach can read them, and they switch at runtime (themes) with no JS.
- Typed TS mirror (when components need values in JS, like charts or canvas):
```ts
export const tokens = {
  color: { bg: { surface: 'var(--color-bg-surface)' } },
  space: { 4: 'var(--space-4)' },
} as const;
export type ColorToken = keyof typeof tokens.color;
```
- If the repo uses Style Dictionary / Tokens Studio JSON, edit the JSON and rebuild. Never hand-edit the generated output.

## Theming
```css
:root, [data-theme='light'] { --color-bg-surface: var(--color-neutral-0); --color-text-default: var(--color-neutral-900); }
[data-theme='dark'] { --color-bg-surface: var(--color-neutral-900); --color-text-default: var(--color-neutral-50); }
@media (prefers-color-scheme: dark) { :root:not([data-theme='light']) { /* same as dark */ } }
```
- Toggle by setting `document.documentElement.dataset.theme`. In Next, set it before paint (an inline script or `next-themes` if the repo already has it) to avoid a flash.
- Motion: respect `@media (prefers-reduced-motion: reduce)`.

## Wiring per styling approach (load only what STACK.md says)
- **Tailwind v4**: tokens in CSS, **no** `tailwind.config` theme. Generated utilities: `bg-surface`, `text-muted`.
```css
@import 'tailwindcss';
@theme {                         /* primitives: become utilities + vars */
  --color-neutral-0: #fff; --color-neutral-900: #1a1a1a;
  --spacing: 0.25rem;            /* p-4 = 1rem */
  --radius-md: 8px;
}
@theme inline {                  /* semantic: utilities reference runtime vars, so themes work */
  --color-surface: var(--color-bg-surface);
  --color-muted: var(--color-text-muted);
}
```
- **Tailwind v3**: `theme.extend.colors = { surface: 'var(--color-bg-surface)', ... }` in `tailwind.config`, with the vars declared in a global CSS file. Declare each token once, not in both places.
- **SCSS / CSS Modules**: use the CSS vars directly (`color: var(--color-text-default)`). SCSS maps and mixins are for generating vars and media queries only, e.g. `@each $name, $value in $space { --space-#{$name}: #{$value}; }`.
- **styled-components / Emotion**: a typed theme object whose values are `var(--...)` strings, plus module augmentation of `DefaultTheme` / `Theme` for type safety.
- **MUI / Chakra / Mantine**: map tokens into `createTheme` / `extendTheme` (palette, spacing, shape, typography, `components.MuiButton.styleOverrides`). Don't fight the lib with global CSS.

## Figma variables → tokens
1. With Figma MCP: call `get_variable_defs` on the frame to get the variable names and values used.
2. Build a mapping table (Figma variable → code token). Reuse existing tokens wherever the value matches.
3. A value with no token: use the nearest semantic token and flag the gap, or add a semantic token on purpose. Never hardcode the hex.

## Documentation
Add or extend the foundation stories (`Foundations/Colors`, `Typography`, `Spacing`, `Elevation`) that render the tokens programmatically from the TS mirror or the CSS vars. DS teams love this.

## Checklist
- [ ] No hex/px values outside token files (the post-edit hook flags them)
- [ ] Semantic layer used by components; themes remap only semantics
- [ ] Contrast of text/bg pairs ≥ 4.5:1 (normal text)
- [ ] Dark mode/theme switch verified in Storybook (toolbar global) or app
