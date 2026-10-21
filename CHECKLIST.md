# Checklist until Monday 26/10

Tick as you go. Details for each step are in [PLAYBOOK.md](PLAYBOOK.md).

## A. Environment (≈ 30 min, do it first)
- [x] Node 22 as default (`nvm alias default 22.22.3`; nvm now loads at the end of `~/.zshrc`, backup in `~/.zshrc.bak`)
- [ ] Restart VS Code and every terminal, then check `node -v` → `v22.22.3` in the VS Code terminal
- [ ] (Optional) fix line 3 of `~/.zshrc`: `export PATH="$HOME/denisibanezrodriguesvieira/npm-global/bin:$PATH"` (today it wipes PATH and adds `$HOME` to it)
- [ ] `corepack enable` and `pnpm -v`
- [ ] `claude update`, then open Claude in any repo and confirm you're logged in
- [ ] `gh auth status`: the **denisibanez** account is the active one (you also have `ibanezPlanetun` logged in; switch with `gh auth switch`)
- [ ] Figma token: Settings → Security → Personal access tokens, scope *File content: read-only*
- [ ] `export FIGMA_TOKEN=...` in `~/.zshrc`, restart the terminal/VS Code
- [ ] Screen sharing: allow the meeting app under *System Settings → Privacy & Security → Screen Recording*, restart the app, do a test call with someone
- [ ] VS Code + terminal font at 16–18, a high-contrast theme
- [ ] Bookmark: the kit repo, `BRIEF.md` of the practice repo, PLAYBOOK sections 3–5

## B. Learn the kit (≈ 1h, read, don't skim)
Read these end to end; you must be able to explain them if asked "what is this `.claude` setup?":
- [ ] `README.md` (what's inside, how it installs, the guards)
- [ ] `kit/CLAUDE.local.md` (the rules Claude follows)
- [ ] `kit-recon`, `feature`, `checkpoint` skills (the loop you will drive)
- [ ] `ds-component`, `architecture`, `state-management` skills (the decisions you'll defend)
- [ ] `kit/.claude/hooks/post-edit.sh` and `guard-bash.sh` headers: what they block or flag, how to turn them off
- [ ] PLAYBOOK §4 (talking about AI), §4b (driving Claude live), §5 (DS questions): say the answers **out loud** once
- [ ] Prepare your 2-sentence kit pitch: what it is, why it's public, why it's git-excluded

## C. Figma smoke test (≈ 10 min)
- [ ] Install the kit in the practice repo: `~/interview-kit/install.sh ~/interview-practice`
- [ ] In Claude: "fetch this Figma frame: <link with node-id>" (any file of yours)
- [ ] Check `.claude/.kit-state/figma/<node>/` has `spec.txt`, `palette.txt`, `render.png`
- [ ] If 403: the file isn't shared with your token's account. Remember to ask for access on the day

## D. Timed rehearsal (2h, Saturday or Sunday)
Setup: practice repo at `~/interview-practice`, brief in `BRIEF.md`, a timer visible, notes file open.
- [ ] 0:00 read `BRIEF.md` fully; install the kit; `git status` shows nothing from the kit
- [ ] "run kit-recon"; read `.kit/STACK.md`; note the typecheck time it reports
- [ ] 0:15 pick the order of items (value × cost) and write 2–3 questions you'd ask
- [ ] Each item: `/feature <item + acceptance criteria>` → read the plan → read each diff → commit via git-flow → `/clear`
- [ ] Hard stop on any item at ~25 min: cut scope, write the TODO
- [ ] 0:45 checkpoint 1: run `checkpoint`, edit out anything you didn't verify, **say it out loud** with a timer (60–90 s)
- [ ] 1:30 checkpoint 2: same, plus the `reviewer` agent first (verify its findings before repeating them)
- [ ] 1:50 PR description with decisions, trade-offs, next steps
- [ ] Write down, per item: minutes spent, where Claude got stuck, any guard that was noisy or wrong, anything you couldn't explain

## E. After the rehearsal
- [ ] Send me the notes → I adjust the kit on a new branch and give you the PR title/description
- [ ] Merge the PR, then `~/interview-kit/uninstall.sh ~/interview-practice` + `git checkout . && git clean -fd` there if you want a second run
- [ ] Optional second, shorter run (1h, 2 items) to test the fixes

## F. Monday morning
- [ ] `git -C ~/interview-kit pull` (latest kit version on `main`)
- [ ] `node -v`, `claude --version`, `gh auth status`, `echo ${FIGMA_TOKEN:+set}` (prints "set", never the token)
- [ ] Do Not Disturb on; Slack, Teams and email closed; work repos closed in VS Code
- [ ] Water, the PLAYBOOK §3 timeline on a second screen or on paper

## G. On the day (in order)
- [ ] Clone their repo → `~/interview-kit/install.sh <repo>` → `git status` clean
- [ ] Tell them about the kit (one sentence, PLAYBOOK §4)
- [ ] "run kit-recon" → ask your questions → plan the order
- [ ] Loop: `/feature` → plan → diff review → commit → `/clear`
- [ ] Before each checkpoint: `reviewer` → `checkpoint` → trim to what you verified
- [ ] Last 10 min: PR description, final commit, push (it asks for confirmation)
