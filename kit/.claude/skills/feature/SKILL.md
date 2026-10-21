---
name: feature
description: Main loop for implementing one item of the technical challenge end to end (understand → plan → test-first where cheap → implement with the matching kit skill → verify → checkpoint notes → commit). Use whenever the user starts a new challenge item, task or requirement.
---

# One challenge item, end to end

The candidate will be asked to explain this at a checkpoint, so optimise for **clarity and control**, not volume.

## 0. Context
Read `.kit/STACK.md`. If it is missing, run `kit-recon` first.

## 1. Understand (≤ 2 min)
- Restate the item as acceptance criteria (Given/When/Then bullets).
- List your assumptions. If one would change the design, **ask** instead of guessing.
- Name the out-of-scope items explicitly.

## 2. Plan (show it, wait for OK)
Keep it to ≤ 10 lines:
- the files to create or edit (real paths, following STACK conventions);
- the existing DS components / hooks / utils you will **reuse** (grep first: `rg -n "export (function|const) " packages/ui/src`);
- the tests you will write first;
- the risks / trade-offs (one line each).

## 3. Tests first (only where they're cheap and high value)
- Pure logic, zod schemas, reducers/slices, custom hooks → write the test first (red).
- Components → one behaviour test (role-based query + userEvent) for the main interaction.
- Skip test-first for pure layout. Cover layout with a story instead.
- In parallel, the `test-writer` agent can write tests in the background while you implement.
See the `testing` skill.

## 4. Implement with the right skill
**Load the matching skill below before editing** (e.g. any change in the DS package → `ds-component`), even for a "small fix": the skill carries the checklist the reviewers will use.

| Need | Skill |
|---|---|
| tokens / theme / dark mode | `ds-tokens` |
| reusable UI component | `ds-component` (+ `storybook`) |
| screen from a Figma link / screenshot | `figma-to-code` |
| API call, loading/error/empty | `api-layer` |
| shared client state | `state-management` |
| form + validation | `forms` |
| new package / workspace wiring | `monorepo` |
| lint / prettier / husky / CI | `tooling` (or the `tooling-engineer` agent in background) |
| Next specifics (RSC, routes, actions) | `nextjs` |
| which hook / pattern / perf approach | `react-expert` |
| where code goes, folder structure, boundaries | `architecture` |
| page shell, template, layout primitives | `layouts-templates` |
| API route, BFF, CRUD with persistence | `backend-endpoint` |
| auth header, token refresh, error mapping | `api-layer` → `references/interceptors.md` |

Rules: reuse before creating, tokens only, small files, no new dependency without asking.

## 5. Verify (narrowest commands): definition of done
- Every behaviour you changed or fixed has a test that would fail without your change (a11y fixes included: assert the role/name/`aria-*`). No new test only for pure styling/token swaps.
- Run the package's **test** script, not only typecheck. Stories updated when a component's API or states changed.
- Anything that takes under a minute (a missing `aria-invalid`, an `alt`) is **done now**, not listed as "next".
- `pnpm --filter <pkg> typecheck`, `lint`, `test` (use the real script names from STACK.md).
- For UI, check it in the running app or Storybook. Mention the URL to the user.
- Self-review `git diff`. For bigger items, ask the `reviewer` agent for a pass.

## 6. Checkpoint notes
Append to `.kit/checkpoints.md`:
```md
## <item> — <time>
- What: ...
- Decisions: ... (why; alternative considered)
- Trade-offs / next with more time: ...
- Tests: ...
- AI usage: what the AI generated; what was checked automatically (tests, typecheck, guards); **"To verify by you:"** 1–3 concrete things the candidate must read or try before claiming them
```
Never write the candidate's actions in first person ("I verified…", "I rejected…") unless the user actually told you so. These notes are read out loud in the interview: invented claims are worse than none.

## 7. Commit
Delegate to the `git-flow` agent: one Conventional Commit per logical change.

## Timebox
If an item passes ~25 min, stop and tell the user. Propose the smallest shippable slice, and write the rest as TODOs in the checkpoint notes. Shipping more items partially beats one item perfectly.
