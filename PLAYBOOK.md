# Interview playbook

## 1. By Sunday: get the machine ready (the "environment")
Small things that, if they fail on the day, burn 15 minutes and your nerves:

- [ ] **Node:** your default Node is **v18.13** today, and Next 15, Vite 6 and Storybook 9 need Node ≥ 18.18/20. Run `nvm alias default 22.22.3` (already installed) and open a new terminal to check with `node -v`.
- [ ] **pnpm:** `corepack enable`. If the repo has `"packageManager"`, corepack uses the right version.
- [ ] **Claude Code:** `claude update` and confirm you're logged in. Try `/agents` and `/` (the kit's skills show up after the install).
- [ ] **GitHub:** `gh auth status` on your personal account (to clone their repo, push and open the PR).
- [ ] **Figma via REST (the kit's primary path):**
  1. Create a token in Figma: *Settings → Security → Personal access tokens*, scope **File content: read-only**.
  2. Add `export FIGMA_TOKEN=...` to `~/.zshrc` and open a new terminal (or restart VS Code, so Claude can see the variable).
  3. Test it in any repo with the kit installed by asking: "fetch this Figma frame: <link with node-id>". It should produce `spec.txt`, `palette.txt` and `render.png`.
  4. If their link returns **403**, the file isn't shared with your account. Ask for access right at the start of the interview.
- [ ] **Figma MCP (optional, plan B):** it's failing to connect today. If you want it as a backup: `claude mcp list` and re-authenticate.
- [ ] **Screen sharing:** on macOS the meeting app (Meet/Teams/Zoom) needs permission under *System Settings → Privacy & Security → Screen Recording*, and **it only works after restarting the app**. Do a test with someone beforehand.
- [ ] **Readability:** VS Code and terminal font at 16–18 (`Cmd +`) and a light or dark theme with good contrast.
- [ ] **Focus:** Do Not Disturb on, Slack, Teams and email closed, work repos closed in VS Code.

## 2. Rehearsal (Saturday or Sunday, 2h on the clock)
1. Set up a practice monorepo: pnpm + turbo, `apps/web` (Next or Vite) and `packages/ui` with Storybook.
2. Install the kit and run the full flow: recon → 3 items → 2 checkpoints spoken out loud → PR.
3. Suggested items: (a) `Badge` + `Card` components in the DS with tokens; (b) a list consuming a public API with search, pagination and states; (c) a form with validation; (d) husky + CI.
4. Write down what got stuck and adjust the kit.

## 3. On the day: the 2h plan
| Time | What |
|---|---|
| 0:00–0:15 | Read the whole brief. `install.sh`, then **kit-recon**. Run install, typecheck and tests. Note what's already broken |
| 0:15–0:25 | Prioritise the items (value × cost). Ask the interviewers 2–4 questions (see below) |
| loop | One item at a time: **type `/feature <item>`** (explicitly: in tests Claude skipped the loop when just asked to "fix X") → plan (shift+tab = plan mode) → test → implement → verify → notes → commit. `/clear` between items |
| before each checkpoint | **reviewer** agent on the diff, then the **checkpoint** skill to prepare what you'll say |
| last 10 min | PR description/README with decisions, trade-offs and next steps. Final commit |

**If the guards get noisy live:** `touch .claude/.kit-state/guards-off` (prettier keeps running) and `touch .claude/.kit-state/typecheck-off`. Delete the files to turn them back on.

**Golden rule:** if an item goes past ~25 min, cut scope and write down the TODO. Showing 4 well-done items is worth more than 1 perfect one.

**Parallelism that impresses (when it makes sense):** while you implement the feature, `test-writer` writes tests in the background and `tooling-engineer` sets up husky/CI. At the checkpoint, explain why you delegated each part.

### Good questions to ask at the start
- "What's the design source of truth: Figma, Storybook or tokens in code?"
- "Priority: visual fidelity, architecture or test coverage?"
- "Can I add dependencies (e.g. react-hook-form, MSW), or do you prefer I stick with what's in the repo?"
- "Should new components go into the DS package or stay in the app?"
- "Is there an expected architecture (feature folders, modules), or is that part of what you want to see?"
- "Is there a backend/API, or should I mock it?"

## 4. How to talk about using AI (they will ask)
- **AI as a pair, you as the owner:** "I set the plan and the patterns; the AI speeds up the typing; I review every diff."
- **Guardrails:** "I set up Claude Code hooks: every AI edit is checked for `any`, hardcoded colors and a11y smells, the typecheck runs when the AI finishes, and it must ask before installing a dependency or pushing. That keeps the AI within the DS rules." (They are Claude Code hooks, not git pre-commit hooks: say it precisely.)
- **Don't trust the AI reviewer blindly:** in the kit's own tests the reviewer agent once claimed a bug that a passing test disproved. Verify before you repeat it.
- **Validation:** "Nothing goes in without typecheck, tests and me reading the diff. Here I rejected X because..." (have 1 real example of something you corrected).
- **Context:** "First I mapped the repo (STACK.md) so the AI follows your conventions, not mine."

## 5. Likely questions from a DS-strong team
| Question | Answer outline |
|---|---|
| How do you structure tokens? | 3 layers: primitive → semantic → component. Components only use semantic tokens; a theme only remaps the semantic layer. CSS vars as the runtime source |
| Dark mode / multi-brand? | `[data-theme]` remapping the semantic tokens, no JS on the critical path. In Next, a script before paint to avoid the flash |
| How do you design a component API? | Extend native props, variants as a union with a default, composition (children/compound/asChild) instead of 15 booleans, controlled + uncontrolled |
| Accessibility? | Semantic element first, `useId` + `aria-describedby`/`aria-invalid`, keyboard, visible focus, modal focus (trap + restore), contrast via tokens, axe in tests/Storybook |
| A Figma value with no token? | Use the nearest token and flag the gap to design. If the value is intentional, create the semantic token, never hardcode |
| DS versioning in the monorepo? | Changesets + semver: removing/renaming a prop is major, a new variant is minor, a visual fix is patch. Deprecate before removing |
| How do you prevent visual regressions? | Stories covering the states + Chromatic (or Playwright `toHaveScreenshot` on the stories) in the PR |
| Wrapping a library (MUI/Radix)? | The app never imports the vendor directly. The DS wraps it, applies tokens and narrows the API, which lets you swap the vendor |
| Component performance? | Measure first; memo only where the profiler shows an expensive re-render; virtualise large lists; in Next, push `'use client'` down to the leaves |
| Server state vs client state? | Server cache in React Query/RTK Query; filters in the URL; a global store only for real client state |
| Context vs Zustand vs Redux? | Context = dependency injection for rarely changing values; Zustand = selector store with no ceremony; RTK = team-scale conventions, heavy async, RTK Query. Use what the repo has (`state-management` skill) |
| How do pages relate to the DS? | Atomic layering: DS has atoms → organisms + layout primitives; templates are data-free and slot-based (with stories); pages only fetch and compose (`layouts-templates`) |
| Why this folder structure? | Feature-based: each vertical flow owns its UI, data and rules; shared UI in the DS package; features talk via `index.ts`; pure rules testable without React (`architecture`) |

## 6. Lessons from your `airbnb-frontend` repo

**Show with pride (it's your style and in line with the market):**
- `cva` + `cn` (clsx + tailwind-merge) with `variants`/`defaultVariants` and `VariantProps`
- Props extending native attributes, `iconLeft`/`iconRight`/`loading` slots
- Foundation stories (ColorPalette, Typography, Elevations) and autodocs
- SVG → React components pipeline (svgr) for icons

**Avoid in the challenge (a DS team will notice):**
- **205 hardcoded hex colors** inside components (`text-[#717171]`, `#DD2A2A`): always use a token. The kit's guard catches this.
- `Meta<any>` and `as any` in stories: use `satisfies Meta<typeof Button>`.
- **600–750 line** components (SearchBar, DatePicker): split into subcomponents and hooks.
- `id` derived from the label (`label.replace(...)`): collisions. Use `useId()`.
- Mixing `export default` and named exports: pick one pattern, theirs.
- Tokens declared **twice** (`tailwind.config.ts` **and** `globals.css`). In Tailwind v4 the JS config isn't even read without `@config`. One source: `@theme`.
- No tests: in the challenge, at least 1 behaviour test per important component.
- `hover:to-primary-03` references a token that doesn't exist: the primary button's hover is broken.
