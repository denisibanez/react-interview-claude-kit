---
name: layouts-templates
description: Page-level UI architecture with atomic design — atoms/molecules/organisms in the DS, layout primitives (Stack, Inline, Grid, Container, Box/Surface), slot-based templates (AppShell, PageLayout, ListDetail, Auth, Dashboard) and pages that only wire data into templates; mapped to Next App Router layouts, route groups and loading/error files, or to react-router nested routes. Includes responsive rules, landmarks/a11y and stories for templates. Use when building a screen, a page shell, a layout, a template, or when the user mentions atomic design, page, template, layout, shell or grid.
---

# Layouts and templates (atomic design, the useful parts)

## 1. Who owns which level
| Level | Example | Lives in | Knows about data? |
|---|---|---|---|
| Tokens | color, space, radius | DS (`ds-tokens`) | no |
| Atoms | Button, Input, Icon, Text | DS | no |
| Molecules | FormField (label + input + error), SearchBox | DS | no |
| Organisms | Header, DataTable, ListingCard | DS if generic, else `features/*/components` | via props only |
| **Layout primitives** | Stack, Inline, Grid, Container, Surface | DS | no |
| **Templates** | AppShell, PageLayout, ListDetailTemplate | DS (generic) or `shared/layouts` (app-specific) | no: **slots only** |
| **Pages** | `/listings`, `/listings/[id]` | app routes | **yes**: fetch, wire, compose |

Talking point: "Templates are data-free and slot-based, so they get stories with placeholder content and the same shell is reused across pages. Pages are the only place that knows about data."
Don't force the atom/molecule naming into folders unless the repo does it. Use the **layering**, not the vocabulary.

## 2. Layout primitives (add to the DS if missing; tokens only)
```tsx
// packages/ui/src/layout/Stack.tsx  (Tailwind + cva flavour; adapt to the repo's styling)
const stack = cva('flex', {
  variants: {
    direction: { column: 'flex-col', row: 'flex-row' },
    gap: { none: 'gap-0', xs: 'gap-1', sm: 'gap-2', md: 'gap-4', lg: 'gap-6', xl: 'gap-8' },
    align: { start: 'items-start', center: 'items-center', end: 'items-end', stretch: 'items-stretch' },
    justify: { start: 'justify-start', center: 'justify-center', between: 'justify-between', end: 'justify-end' },
    wrap: { true: 'flex-wrap' },
  },
  defaultVariants: { direction: 'column', gap: 'md', align: 'stretch' },
});
type StackProps = ComponentPropsWithoutRef<'div'> & VariantProps<typeof stack> & { as?: 'div' | 'section' | 'ul' | 'ol' | 'nav' };
export function Stack({ as: Tag = 'div', className, direction, gap, align, justify, wrap, ...props }: StackProps) {
  return <Tag className={cn(stack({ direction, gap, align, justify, wrap }), className)} {...props} />;
}
```
- `Inline` = Stack row + wrap. `Grid` with `cols` responsive variants (`{ base: 1, md: 2, lg: 3 }`) or `minItemWidth` (`grid-cols-[repeat(auto-fill,minmax(var(--item-min),1fr))]` via a token var). `Container` = max-width token + horizontal padding token. `Surface` = background/border/radius/shadow tokens.
- Gap values are a **union mapped to the spacing scale**, never `gap={13}`.
- Spacing between siblings belongs to the parent (gap), not margins on children. This is what makes components reusable in any layout.

## 3. Templates = slots
```tsx
// shared/layouts/PageLayout.tsx (or packages/ui/src/templates)
type PageLayoutProps = {
  title: ReactNode;
  description?: ReactNode;
  breadcrumbs?: ReactNode;
  actions?: ReactNode;      // primary/secondary buttons on the right
  aside?: ReactNode;        // filters / secondary panel
  children: ReactNode;      // main content
};
export function PageLayout({ title, description, breadcrumbs, actions, aside, children }: PageLayoutProps) {
  return (
    <Container className="py-section">
      <Stack gap="lg">
        {breadcrumbs}
        <Inline justify="between" align="center" gap="md">
          <Stack gap="xs"><h1 className="text-heading-lg">{title}</h1>{description && <p className="text-muted">{description}</p>}</Stack>
          {actions && <Inline gap="sm">{actions}</Inline>}
        </Inline>
        <div className={cn('grid gap-6', aside && 'lg:grid-cols-[var(--aside-width)_1fr]')}>
          {aside && <aside aria-label="Filters">{aside}</aside>}
          <section>{children}</section>
        </div>
      </Stack>
    </Container>
  );
}
```
Common templates: **AppShell** (header, nav, `main`, footer, skip link), **PageLayout** (above), **ListDetail** (list + detail pane, stacked on mobile), **Auth** (centered card), **Dashboard** (grid of cards with responsive columns), **Wizard** (steps + content + footer actions).

## 4. Pages: wire, don't style
```tsx
// app/listings/page.tsx (RSC) – composes, fetches, nothing else
export default async function ListingsPage({ searchParams }: Props) {
  const filters = parseFilters(await searchParams);       // zod
  return (
    <PageLayout title="Listings" actions={<NewListingButton />} aside={<ListingFilters value={filters} />}>
      <Suspense key={JSON.stringify(filters)} fallback={<ListingGridSkeleton />}>
        <ListingGrid filters={filters} />
      </Suspense>
    </PageLayout>
  );
}
```

## 5. Routing frameworks
- **Next App Router:** `app/layout.tsx` = AppShell (+ providers). Route groups for different shells: `app/(marketing)/layout.tsx`, `app/(app)/layout.tsx`, `app/(auth)/layout.tsx`. `loading.tsx` uses the template's skeleton, `error.tsx` the template's error state. Layouts persist across navigation (don't put per-page state there). `template.tsx` only if it must remount on navigation.
- **react-router:** a layout route with `<Outlet />` per shell; `errorElement` per route; lazy routes.
- **Vite SPA without a router:** a single AppShell in `App.tsx`.

## 6. Responsive and a11y
- Mobile first; breakpoints from the token/Tailwind config only. Ask which viewports Figma covers.
- Landmarks: one `header`, `nav` (with `aria-label` if several), one `main` (with `id` for the skip link), `aside`, `footer`. Headings in order: one `h1` per page (the template renders it from `title`).
- Skip link as the first focusable element in AppShell. Focus to `h1`/`main` after client navigation if the router doesn't.
- No `position: absolute` for layout; flex/grid only.

## 7. Stories for templates
`Templates/PageLayout` with placeholder blocks (`<Placeholder label="Main content" />`), variants: with/without aside, long title, mobile viewport (`parameters.viewport`). This shows the DS team you treat layout as part of the system.
