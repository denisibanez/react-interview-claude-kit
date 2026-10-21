---
name: checkpoint
description: Prepare what the candidate will say at an interview checkpoint, from the checkpoint notes and the git diff. Gives a spoken 60–90s script, the decisions and why, the trade-offs, how AI was used and validated, a demo path, and likely interviewer questions with crisp answers. Use when the user says checkpoint, asks to explain or present the work, or before sharing the screen.
---

# Checkpoint script

## Inputs
- `.claude/.kit-state/checkpoints.md`: the notes written per item.
- `git log --oneline <since last checkpoint>` and `git diff --stat`.
- `.claude/STACK.md`, for the interview language. Default to the user's language.

## Output (print it, don't write a file)

### 1. Spoken script (60–90 s, ~150–200 words)
Use the structure **Context → What I did → Key decision → Trade-off → Next**. Write it in first person, in plain words the candidate would actually say, with no jargon dumps.

### 2. Decisions table
| Decision | Why | Alternative considered | Why not |
|---|---|---|---|

Include at least one design-system decision (tokens, variants API, composition or a11y) and, on the first checkpoint, the architecture decision (`architecture` skill, section 4).

### 3. AI usage, transparently
- What the AI generated, what the candidate reviewed or changed, and what was rejected and why.
- How it was validated: typecheck, tests, the story, reading the diff.
- The guardrails in place: hooks that block `any` and hardcoded colours, the typecheck on stop, and the no-new-deps rule.

### 4. Demo path
3–5 steps: what to open (the Storybook story, the route, the test run) and in which order. Lead with the most impressive thing.

### 5. Likely questions → short answers
6–8 questions an interviewer from a **strong design-system team** would ask about *this* diff. Examples:
- why this variant API, and how it scales to new variants and themes;
- how the component is accessible (keyboard, screen reader, focus);
- controlled vs uncontrolled;
- where the tokens come from, how dark mode or theming works, and what happens when Figma has a value with no token;
- how the component would be versioned and published in the monorepo (changesets, semver, breaking changes);
- how visual regressions would be tested (Storybook + Chromatic or Playwright screenshots);
- performance (memoisation, rerenders, bundle) and why it was or wasn't needed.

### 6. Honest gaps
Name 1–3 things left undone and how they would be done. Saying it first is better than being caught.
