# Checklist until Monday 26/10

Every step says **why** it matters, **how** to do it (exact commands), what **done** looks like, and what to do **if it fails**.
Total effort: about 1h for A–C, 2h30 for the rehearsal (D), 15 min for E, and 20 min on Monday morning (F).

Paths used below:
- Kit: `~/interview-kit` (this repo)
- Practice repo: `~/interview-practice` (a local pnpm + turbo monorepo: Next 15 app in `apps/web`, design system in `packages/ui` with Storybook, and a 2h challenge in `BRIEF.md`). Its clean starting point is commit `ec6df19`.

---

## A. Environment (≈ 40 min, do this first)

### A1. Node 22 everywhere
- **Why:** Next 15, Storybook and recent Vite need Node ≥ 20. Your machine also has a system Node 18 at `/usr/local/bin/node`, which was winning before.
- **Already done:** `nvm alias default 22.22.3`, and nvm now loads at the end of `~/.zshrc` (backup in `~/.zshrc.bak`).
- **How:**
  1. Quit VS Code completely (`Cmd+Q`, not just close the window) and close every terminal.
  2. Open VS Code again, open its terminal (`Ctrl+\``), run `node -v`.
- **Done when:** it prints `v22.22.3` in the VS Code terminal **and** in a normal Terminal window.
- **If it fails:** run `which node`. If it says `/usr/local/bin/node`, nvm isn't loading: check that the last lines of `~/.zshrc` are the nvm block.
- **Optional cleanup:** line 3 of `~/.zshrc` is `export PATH="$HOME/denisibanezrodriguesvieira/npm-global/bin:$HOME"`. It throws away the whole PATH and adds your home folder to it. The correct line ends with `:$PATH"` instead of `:$HOME"`. It doesn't break Node anymore, but it may break other tools.

### A2. pnpm via corepack
- **Why:** their repo almost certainly pins a pnpm version in `package.json` (`"packageManager": "pnpm@x.y.z"`). Corepack downloads exactly that version, so installs match their lockfile.
- **How:** `corepack enable`, then `pnpm -v`.
- **Done when:** `pnpm -v` prints a version (10.x today).
- **If it fails:** `npm i -g corepack` and repeat.

### A3. Claude Code up to date
- **Why:** skills, hooks and the `/feature` style commands depend on recent Claude Code features. An old version may ignore part of the kit silently.
- **How:** `claude update`, then `claude --version`.
- **Done when:** the version is ≥ 2.1. Open Claude in any folder and send "hi": it answers without asking you to log in.
- **If it fails:** `claude` then `/login`.

### A4. GitHub account
- **Why:** on the day you'll clone their repo, push a branch and open a PR. You have two accounts logged in (`denisibanez` and `ibanezPlanetun`), and the wrong one can push with the wrong identity or get a 403.
- **How:** `gh auth status`. If the active account isn't `denisibanez`: `gh auth switch -u denisibanez`.
- **Done when:** `gh auth status` shows `Active account: true` under **denisibanez**.
- **Also check:** `git config --global user.email` is the email you want on their commits (today: `denis.ibanez@outlook.com`).

### A5. Figma token (the kit reads designs through the Figma REST API)
- **Why:** if they give you a Figma link, the kit's `figma-to-code` skill downloads the frame as an outline, a palette and a PNG, so Claude can build it with your tokens. Without a token this path doesn't work, and you'd fall back to screenshots.
- **How:**
  1. figma.com → your avatar (top left) → **Settings** → **Security** tab → **Personal access tokens** → **Generate new token**.
  2. Name it `interview-kit`, set an expiration date after Monday, and give it the scope **File content: Read-only**. Nothing else is needed.
  3. Copy the token (it starts with `figd_`). Figma shows it only once.
  4. Add this line to the end of `~/.zshrc`: `export FIGMA_TOKEN="figd_..."`
  5. Quit VS Code (`Cmd+Q`) and the terminals, then reopen them.
- **Done when:** `echo ${FIGMA_TOKEN:+set}` prints `set`. This prints only the word, never the token itself.
- **Never:** paste the token into a chat, a commit or a screen you're sharing.

### A6. Screen sharing
- **Why:** on macOS, the first screen share of an app asks for permission and **only works after the app restarts**. Finding that out during the interview costs 5 minutes and your calm.
- **How:** *System Settings → Privacy & Security → Screen & System Audio Recording* → enable the meeting app (Meet runs in your browser, so enable the browser; otherwise Teams or Zoom). Quit and reopen that app.
- **Done when:** you've shared your screen in a test call with someone, and they could read the VS Code text.

### A7. Readability and focus
- **Why:** interviewers watch your screen through video compression. Small fonts are unreadable.
- **How:** VS Code: `Cmd +` until the editor is at 16–18. Terminal: same. Use a theme with strong contrast.
- **Done when:** someone in the test call (A6) can read code without zooming.

---

## B. Learn the kit (≈ 1h, read for real)

**Why this matters:** an interviewer may ask "what is this `.claude` folder?" or "why did the AI do X?". If you can't answer, the kit hurts you. You don't need to memorise it, but you must know what each part does and why it exists.

Open each file and, after reading, write down one sentence about what it does in your own words.

| # | File | What to get out of it | Time |
|---|---|---|---|
| B1 | `README.md` | What gets installed, how it stays out of git, the 4 guards | 5 min |
| B2 | `kit/CLAUDE.local.md` | The rules Claude follows in their repo. You should agree with every line | 5 min |
| B3 | `kit/.claude/skills/kit-recon/SKILL.md` | What the first 10 minutes look like, and what `.kit/STACK.md` contains | 5 min |
| B4 | `kit/.claude/skills/feature/SKILL.md` | The loop for each item (plan → test → implement → verify → notes → commit) and its "definition of done" | 10 min |
| B5 | `kit/.claude/skills/checkpoint/SKILL.md` | What the checkpoint script will look like, and why you must remove anything you didn't verify | 5 min |
| B6 | `kit/.claude/skills/ds-component/SKILL.md` | The checklist a design-system team uses to judge a component | 10 min |
| B7 | `kit/.claude/skills/architecture/SKILL.md` | §1 table and §4 justification script: how to defend a folder structure | 10 min |
| B8 | `kit/.claude/skills/state-management/SKILL.md` | The Context vs Zustand vs Redux table and the ready answers | 10 min |

Then:
- [ ] **B9. Guards:** read the comment at the top of `kit/.claude/hooks/post-edit.sh` and `guard-bash.sh`. Know the two "off switches": `touch .claude/.kit-state/guards-off` (stop the code-smell warnings) and `touch .claude/.kit-state/typecheck-off` (stop the typecheck after each answer). Delete the file to turn the guard back on.
- [ ] **B10. Say it out loud:** PLAYBOOK §4 (talking about AI), §4b (driving Claude live) and §5 (DS questions). Answer 5 questions from §5 out loud, about 30 s each. Speaking is a different skill from reading.
- [ ] **B11. Your kit pitch (write it down, two sentences):** what it is, and why it's public but kept out of their git. Example: *"I use a personal Claude Code setup I built: skills that make the AI follow your repo's conventions, and guards that block things like hardcoded colors or `any`. It's public on my GitHub, installed locally and excluded from git, so nothing of it lands in your repo."*

---

## C. Figma smoke test (≈ 10 min, needs A5)

- **Why:** the Figma script has only been tested with fake data. One real call proves the token, the scope and the script all work.
- **How:**
  1. `~/interview-kit/install.sh ~/interview-practice`, then `git -C ~/interview-practice status`: it must show **nothing** from the kit.
  2. In Figma, open any file of yours, right-click a frame → **Copy link to selection**. The link contains `node-id=`.
  3. `code ~/interview-practice`, open Claude Code there and say: `fetch this Figma frame: <link>`.
- **Done when:** the folder `~/interview-practice/.claude/.kit-state/figma/<node>/` has `spec.txt`, `palette.txt` and `render.png`, and Claude describes the frame correctly.
- **If it fails:**
  - **403:** the token's account can't see that file. On the day, ask them to share the file with your Figma account.
  - **"FIGMA_TOKEN is not set":** VS Code was opened before the token existed. `Cmd+Q` and reopen.
  - **Anything else:** copy the error and send it to me.
- **After:** leave the kit installed. The rehearsal (D) starts with it already there, or uninstall it to also practise the install.

---

## D. Timed rehearsal (2h30 with notes, Saturday or Sunday)

**Why:** this is the only test that checks the things that matter on Monday. Does the flow fit in 2h? Can you explain each diff? Where does Claude get stuck? Every kit fix after this comes from your notes.

**Setup (before starting the timer):**
- [ ] Practice repo clean: `cd ~/interview-practice && git status` shows nothing. If not, see "Reset" in E3.
- [ ] Kit installed (C1) and `git status` still clean.
- [ ] A visible timer, and a notes file open (paper is fine).
- [ ] Do Not Disturb on. Treat it as the real thing: no pausing.

**Timeline (same as Monday):**

| Time | What you do | What to watch / write down |
|---|---|---|
| 0:00 | Read `BRIEF.md` fully (6 items) | Which items are worth the most |
| 0:05 | In Claude: `run kit-recon`. Read `.kit/STACK.md` | Does it get the stack right? Does it report the typecheck time? It should list the planted problems (hex color in Card, `any` in page.tsx...) |
| 0:15 | Choose the order of items (value × cost). Write the 2–3 questions you'd ask the interviewers | Time spent deciding |
| 0:20 | Item loop, one item at a time (see below) | Minutes per item |
| 0:45 | **Checkpoint 1** (see below) | Did the script sound like you? |
| 1:30 | **Checkpoint 2**, same, but run the `reviewer` agent first | Did the reviewer find something real? Did it invent anything? |
| 1:50 | Ask Claude for the PR description (decisions, trade-offs, next steps). Final commit | |
| 2:00 | Stop. Write your notes (E1) | |

**The item loop (repeat for each item):**
1. Type `/feature <item from BRIEF.md + what "done" means>`. Example: `/feature item 1: Badge in packages/ui, variants neutral/success/danger, sizes sm/md, story and test, follow Button's pattern`.
2. Claude shows a plan. **Read it.** Cut scope there if it's too big. Then say "ok".
3. As it edits, **read each diff**. If you can't explain a line, ask "why this?" or reject it.
4. When it says it's done, check the result yourself: the test output, the page in the browser (`pnpm --filter web dev`) or Storybook (`pnpm --filter @practice/ui storybook`).
5. "commit it" (the `git-flow` agent commits, never with an AI trailer). Then `/clear` before the next item.
6. **If an item passes ~25 min:** stop it, keep what works, and say "write the rest as TODO in the checkpoint notes".

**Each checkpoint:**
1. Before 1:30, say "use the reviewer agent on the diff since the last checkpoint". Check anything it calls "must fix" against the code and tests before believing it.
2. Say "prepare my checkpoint". Claude prints a script (60–90 s), a decisions table, the AI usage and likely questions.
3. **Edit the script:** remove anything you didn't actually check yourself.
4. Start a timer and **say it out loud**, as if they were listening. Then answer 2 of the likely questions out loud.

---

## E. After the rehearsal (≈ 15 min)

### E1. Notes to send me
Per item: minutes spent; where Claude got stuck or went in a wrong direction; any guard that was noisy or wrong; anything you couldn't explain; anything you wished the kit did. Also: did kit-recon get everything right? How long did a typical Claude answer take?

### E2. What I do with them
I fix the kit on a new branch and send you the PR title and description. You review and merge.

### E3. Reset the practice repo (for a second run)
```bash
~/interview-kit/uninstall.sh ~/interview-practice
cd ~/interview-practice && git reset --hard ec6df19 && git clean -fd
```
`ec6df19` is the clean starting commit. This throws away everything from the rehearsal, so do it only after writing your notes.

### E4. Optional second run (1h)
Two items only, to test the fixes and your speed.

---

## F. Monday morning (≈ 20 min, before the interview)

- [ ] **Latest kit:** `cd ~/interview-kit && git switch main && git pull`
- [ ] **Tools:** `node -v` (v22.22.3), `pnpm -v`, `claude --version`, `gh auth status` (denisibanez active), `echo ${FIGMA_TOKEN:+set}` (prints `set`)
- [ ] **Quiet:** Do Not Disturb on. Close Slack, Teams, email and any work repo in VS Code (nothing private on screen when you share it).
- [ ] **At hand:** water; PLAYBOOK §3 (the 2h timeline) and §4 (the AI talk) on paper or a second screen; your kit pitch (B11).
- [ ] **Screen share:** open the meeting link 5 minutes early and test sharing VS Code.

---

## G. During the interview (in order)

1. **Clone** their repo: `gh repo clone <org>/<repo> ~/<repo> && cd ~/<repo>` (or the link they send).
2. **Install the kit:** `~/interview-kit/install.sh .`, then `git status` must show nothing new.
3. **Say your kit pitch** (B11) when you start, or at the latest at the first checkpoint.
4. **Recon:** open Claude in the repo and say `run kit-recon`. While it runs, read the brief.
5. **Questions:** ask 2–4 (PLAYBOOK §3, plus the ones kit-recon suggests). Decide the order of items.
6. **Loop:** `/feature` → plan → read diffs → verify → commit → `/clear`. Keep the 25-minute limit per item.
7. **Before each checkpoint:** `reviewer` → `checkpoint` → trim to what you verified → speak.
8. **Last 10 minutes:** PR description, final commit, push (Claude asks for confirmation before pushing), open the PR if they want one.
9. **After:** `~/interview-kit/uninstall.sh .` if you keep the repo.
