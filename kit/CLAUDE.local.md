<!-- interview-kit:start -->
# Interview mode — working agreement

This is a live 2h technical challenge. The candidate (the user) must be able to explain every line.
Speed matters, but **control and clarity matter more than volume**.

## Always
- Read `.kit/STACK.md` first. If it is missing, run the `kit-recon` skill before writing any code.
- **Follow the repo's existing conventions** over the kit's defaults: naming, folder layout, export style, styling approach, test runner, state lib. The kit's patterns are the fallback when the repo has none.
- Code samples in the kit's skills **illustrate a pattern; they are not templates**. Translate them to the repo's stack from STACK.md (e.g. a cva sample becomes styled-components if that's what the repo uses). When the repo and a kit sample disagree, the repo wins.
- One challenge item at a time, through the `feature` skill: plan → (test) → implement → verify → checkpoint notes → commit.
- Small, reviewable diffs. Show the plan before large changes and wait for the user's OK.
- After each item, append talking points to `.kit/checkpoints.md` (the `checkpoint` skill reads it).
- Verify with the narrowest command: `pnpm --filter <pkg> <script>` instead of the whole monorepo.
- Architecture: follow the repo's; if there is none, pick one with the `architecture` skill and **state the reason** in the checkpoint notes. Pages wire data into slot-based templates (`layouts-templates`); the DS stays data-free.
- Every hook/approach choice must be justifiable in one sentence (`react-expert`): no effects for derived data or events, server data in the query layer, not in a store.

## Design system rules (this team is strong in DS — be strict)
- Never hardcode colors, spacing, radius, shadows, font sizes. Use tokens. If Figma has a value with no token, use the nearest token and **flag it**, or add a semantic token on purpose.
- Reuse the existing DS components before creating new ones. New reusable UI goes into the DS/ui package, not into the app.
- Every DS component: extends native element props, forwards ref, merges `className`, typed variants with defaults, accessible (semantic element, keyboard, focus-visible, aria wiring with `useId`), story covering variants + states, a behaviour test.
- Composition over configuration: prefer compound components / slots (`children`, `asChild`) over 15 boolean props.
- Keep files small (< ~200 lines). Split sub-components and hooks.

## TypeScript
- No `any`, no `@ts-ignore`, no non-null `!` to silence errors. Use `unknown` + narrowing, generics, `satisfies`, discriminated unions, `z.infer`.
- Validate external data at the boundary (zod or the repo's validator), type everything inside.

## Dependencies & git
- Never add a dependency without asking the user first (they must justify it in the checkpoint).
- Commits: Conventional Commits, one logical change each, via the `git-flow` agent. Never `--no-verify`, never force-push.
- Never add AI attribution / `Co-Authored-By` trailers to commits or PRs.

## The candidate's own style (from their airbnb-frontend repo) — keep the good, avoid the bad
Keep: `cva` + `cn` (clsx + tailwind-merge) variants with `defaultVariants`; props extending native attributes + `VariantProps`; `iconLeft`/`iconRight`/`loading` slots on buttons; Storybook autodocs + foundation stories (colors, typography, elevation); SVG → React icon pipeline (svgr).
Avoid (seen in that repo): hex literals inside components; `Meta<any>`/`as any` in stories; 600-line components; ids derived from labels (use `useId`); mixed default/named exports; tokens declared twice (tailwind config **and** CSS); missing tests.
<!-- interview-kit:end -->
