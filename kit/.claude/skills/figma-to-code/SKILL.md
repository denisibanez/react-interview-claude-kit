---
name: figma-to-code
description: Implement a screen or component from a Figma link (via the Figma REST API script, the Figma MCP as fallback) or from a screenshot/image quickly and with high fidelity, reusing the repo's DS components and tokens instead of copying generated code. Covers inventory, token mapping, bottom-up build, responsive layout, assets/icons and a fidelity check. Use when the user shares a figma.com URL, a design screenshot, or mentions a layout, screen, mockup or prototype.
---

# Figma → code (fast and faithful)

## 0. Get the design

### A) REST API, the primary path (needs `FIGMA_TOKEN` in the env)
```bash
bash .claude/skills/figma-to-code/figma-fetch.sh '<figma url with node-id>' [max-depth=10]
```
Use that relative path with no redirects, so the permission allowlist matches.
It writes to `.claude/.kit-state/figma/<node>/`:
- `spec.txt`: an indented outline, one line per node. Type, name, size, auto-layout (`row/col gap pad align`, `size fill×hug`), bg/border with **Figma style names in `{}`**, radius, shadows, text (`family weight size/line-height`, color, style, content), instances (`→ Button/Primary {Size=lg}`), `[vars: ...]` when bound to variables.
- `palette.txt`: unique colors, type styles, spacing values, radii and the components used, with counts. **This is the seed of the token-mapping table.**
- `render.png`: a 2x render. **Read it** as the visual reference.
- `nodes.json`: the raw response, for anything the outline omits (`jq` into it).

Workflow:
1. Run the script on the frame the user gave you. Read `render.png`, then `spec.txt`, then `palette.txt`.
2. If `spec.txt` is huge, rerun with a lower depth for the overview, then run it on each sub-frame's node-id (right-click → Copy link to selection) as you build each section.
3. Errors: 403 means the token can't see the file (ask the user to open the link while logged in, or to request access); 404 means a wrong node-id; 429 means you're rate limited, so wait and reuse `nodes.json`.
4. The REST variables endpoint is Enterprise-only. Rely on the style names + `[vars: ...]` + the values in `palette.txt`.

### B) Figma MCP (if connected)
`get_metadata` (big frames) → `get_screenshot` → `get_variable_defs` → `get_design_context` → `get_code_connect_map`.
**Treat MCP-generated code as a spec, not as code.** It is React + Tailwind with hex colors and absolute values. Translate it into the repo's components and tokens.

### C) Neither works
Ask the user to paste a screenshot (or give an exported PNG path) plus key values from Dev Mode. Don't block on it. Approximate with tokens and list what to confirm.

## 1. Inventory (write it down, it's also great checkpoint material)
| Figma layer | Code | Status |
|---|---|---|
| Button/Primary | `@scope/ui` `<Button variant="primary">` | exists |
| Card/Listing | new `ListingCard` (composes Card + Badge) | create |
| color/brand/500 | `--color-action-primary-bg` | mapped |
| 18px/26px semibold | `text-lg font-semibold` | mapped |
| #7A7A7A (no var) | nearest `text-muted`, flag it | gap |

## 2. Build bottom-up
1. Tokens and gaps (`ds-tokens`).
2. Missing primitives in the DS (`ds-component`), each with a story.
3. Composites (cards, list items).
4. Page/section layout: flex/grid with gap tokens. **No absolute positioning** unless it's truly an overlay. Use semantic structure (`header`, `main`, `nav`, `section`, `h1..h3` in order).
5. Responsive: mobile first, Figma breakpoints mapped to the repo's breakpoints. Ask if only one viewport was designed.

## 3. Assets
- Icons: reuse the repo's icon set first. New SVGs become React components (svgr) using `currentColor`, with `aria-hidden` when decorative.
- Images: `next/image` in Next (with `sizes`), `loading="lazy"` elsewhere, and real `alt` text.

## 4. Fidelity check (before saying "done")
- Take a screenshot of the implementation: Playwright `page.screenshot`, or the user's screenshot of the Storybook story. Read it next to the Figma screenshot.
- Check, in order: **layout & spacing → typography (size, line-height, weight, letter-spacing) → colors → radius & shadows → states (hover, focus, disabled, error, empty, loading) → responsive.**
- List the remaining deviations explicitly, each with a reason (token gap, missing asset, time).

## 5. Speed tips
- Do one section per iteration and show it. Don't build the whole page blind.
- When a component exists in the DS but differs slightly, prefer an opt-in prop/variant in the DS (default unchanged) over a local copy.
