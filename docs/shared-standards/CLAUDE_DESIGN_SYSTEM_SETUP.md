# Claude Design System Setup

How to set up a claude.ai **Design System** for a project so that every future design session is grounded in the project's real brand and frontend code, instead of generic defaults.

## What This Is

Claude's design tool (claude.ai design sessions) has a **"Set up your design system"** feature: a one-time form per project. Once filled out, every design session for that project starts with the brand voice, palette, typography, and actual component code already loaded.

## When to Act

- **Starting ANY design work in a project** (new UI, landing page, redesign, component work): first check whether this project has a design system set up — look for a "Design system" status line in the project's `CLAUDE.md` (see [Recording Status](#recording-status-in-the-project) below).
- **If none exists:** remind the user this feature exists and offer to help fill out the form using the guidance below. Draft the answers from wherever the project actually documents its look — a brand/design doc, the README, the design-token file (e.g. `src/styles/variables.css`), and the frontend code — so the user can paste them in. See [Handing the Answers to the User](#handing-the-answers-to-the-user) for the exact clipboard format.
- **If one exists:** confirm the linked repo/assets are still current (especially after a repo rename — see gotchas).

## The Form, Field by Field

### 1. Company name and blurb

Product one-liner + what surfaces it ships (web / mobile / kiosk / CLI). Write it from the project's brand doc or README — don't improvise a new positioning statement. Keep it to 1–3 sentences.

### 2. Link code from GitHub

Link the project's repository so design sessions can read real component code, tokens, and styles.

- Use the GitHub app connection; grant access to new repos via **Configure** if the repo isn't listed yet.
- Have the **full repo URL** ready (`https://github.com/<owner>/<repo>`) — it's also repeated inside field 5's notes so the code is findable from the notes text alone.
- ⚠️ **Re-add the link after any repo rename.** The link does not follow renames — a renamed repo silently breaks the design system's code grounding.
- **Large codebases:** prefer linking a frontend-focused subfolder via **"Link code from your computer"** (Chrome/Edge only) instead of the whole monorepo.

### 3. Upload a .fig file

Only if Figma designs actually exist. The file is parsed locally, never uploaded. Skip entirely if the project has no Figma source of truth.

### 4. Add fonts, logos and assets

Add these once a logo/typeface is locked. **Skip pre-branding** — placeholder assets pollute future sessions worse than no assets.

### 5. Any other notes

**The highest-leverage field.** Include:

- Brand voice and tone
- Palette (actual hex values, not adjectives)
- Typography choices
- Recurring visual motifs
- **HARD RULES** — explicit prohibitions, e.g. "no photos of faces", "never use gradients"
- **The full GitHub repo URL** (`https://github.com/<owner>/<repo>`) — repeat it here even though field 2 links the repo, so a session working from the notes text alone can still find the code.
- A pointer to the project's brand/design doc **wherever it actually lives** — the path varies per project: `docs/brand/*.md`, `docs/DESIGN.md`, a `## Design` section in the README, or the design-token file itself (e.g. `src/styles/variables.css`). Find the real one; don't assume `docs/brand/`.

## Handing the Answers to the User

The user pastes these into the claude.ai form themselves. Only three fields carry pasteable text — fields **3** (Figma upload) and **4** (font / logo / asset drop-ins) are interactive file actions with nothing to paste, so **leave them out of the clipboard payload entirely**. If either is relevant, mention it once in chat as a "do this in the form yourself" note; don't clutter the copyable block with it.

Copy **one block** to the clipboard (per the clipboard auto-copy rule) containing, in order, separated by blank lines and nothing else:

1. **Field 1** — company name + blurb
2. **The full GitHub repo URL** (field 2's value, e.g. `https://github.com/<owner>/<repo>`)
3. **Field 5** — the notes (which itself repeats the repo URL)

```
<field 1 blurb>

https://github.com/<owner>/<repo>

<field 5 notes — brand voice, palette hex, typography, HARD RULES, repo URL, brand-doc pointer>
```

Copy all three at once so the user pastes in one motion. Do **not** pad the clipboard with the Figma/fonts fields, form-field headers, or `=== FIELD N ===` labels — just the three blocks, blank-line separated.

## Recording Status in the Project

After a design system is set up (or updated), record it in the project's own `CLAUDE.md` — **outside** the shared-ai-docs managed sentinel block — so future sessions in that repo know it exists:

```markdown
## Claude Design System

Set up YYYY-MM-DD. Linked repo: `<repo-name>`. Brand doc: `<actual path, e.g. docs/DESIGN.md>`.
⚠️ Re-add the GitHub link if this repo is ever renamed.
```

Keep this line current: update it after repo renames, brand-doc moves, or re-setup.
