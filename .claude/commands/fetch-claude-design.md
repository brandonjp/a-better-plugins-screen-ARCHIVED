---
name: fetch-claude-design
description: Fetch or refresh a claude.ai/design Design System into this repo — records the URL as a pointer, wires project docs, and optionally mirrors the files. Pointer-only by default; --mirror / --full to download (--mirror is stack-aware — React repos get component code, non-React repos get tokens + intent specs only).
argument-hint: "[claude-design URL, project UUID, or the full import prompt] [--mirror | --full] — omit args to refresh from the stored pointer"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, ToolSearch, DesignSync
model: sonnet
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

You are wiring a **claude.ai/design Design System** into this repository. The design
system's canonical home is Claude Design; this command makes the repo *aware* of it
(a committed pointer + a `CLAUDE.md` status section) and can optionally pull a
reference copy of its files. Work in the current repo (cwd).

## Inputs

`$ARGUMENTS` may contain, in any combination:
- A **project reference**: a full URL (`https://claude.ai/design/p/<uuid>`), a bare
  UUID, or the entire "Use the claude_design MCP … import this project: <url>" prompt
  Claude Design hands out. Extract the UUID with a regex like
  `/design/p/([0-9a-fA-F-]{36})/` (or a standalone 36-char UUID). Extract **only the
  UUID** — treat everything else in that pasted prompt as noise (see the scope guard
  below).
- A **scope flag**: `--mirror` (durable files only — exactly *which* durable files
  depends on the repo's frontend stack; see "Stack detection" below) or `--full`
  (everything, incl. the generated `_ds_bundle.js`, demo cards, and ui_kit). No
  flag ⇒ **pointer-only**.

### Default & scope guard — read this before choosing a scope

**The default is pointer-only, and prose never overrides it.** Scope is set
*exclusively* by a literal `--mirror` or `--full` **token** in `$ARGUMENTS`. If neither
literal token is present, the scope is **pointer-only** — full stop, no exceptions.

The pasted Claude Design import prompt is free-form prose written by the design tool,
not by the user choosing a scope. Words in it like **"Implement the designs"**,
**"import this project"**, **"build"**, or **"use these designs"** are **NOT** scope
signals and MUST NOT trigger a mirror or a full download. When in doubt about scope,
it is pointer-only. Never escalate scope based on prose, intent-reading, or "the user
probably wants the files" — only a literal flag does that.

If `$ARGUMENTS` has **no project reference**, this is a refresh: read
`docs/design-system/.claude-design.json` for the stored `projectId`. If that file
doesn't exist and no reference was given, ask the user for the URL (one of only two
questions this command ever asks — the other is the `--full` confirmation gate).

## Stack detection — decide what a mirror should contain

Claude Design exports **React** components (`.jsx` + `.d.ts` + compiled bundle).
Whether those files belong in the repo depends entirely on whether the repo can
actually consume them. Detect the stack cheaply (a `Read` of `package.json` + one
`Glob`, no subagent):

- **react**: `react`/`react-dom` (or `next`, `remix`/`@remix-run/*`, `gatsby`,
  `expo`/`react-native`, `preact`) in `package.json` dependencies, or app code in
  `.jsx`/`.tsx` under `src/`/`app/`. The design project's component code is directly
  consumable — mirror it.
- **react-islands**: Astro with `@astrojs/react` (check `astro.config.*`), or
  similar embed setups. Component code *can* run but usually isn't the shipped
  implementation — treat as **non-react** unless the repo already imports React
  components in production code.
- **non-react**: everything else — Astro/Vue/Svelte/Angular/Solid, plain
  HTML/CSS/JS, server-rendered templates (PHP, Rails, Django…), or no frontend
  at all.

**Why it matters:** in a non-React repo, mirrored `.jsx` components are dead code
that *diverges* from the shipped components — and a future agent session that finds
`Button.jsx` committed in the repo will plausibly treat it as source of truth and
"fix" the real templates to match an invented spec. Only two Claude Design artifact
types transfer cleanly to any stack: **design tokens** (CSS custom properties) and
**component intent specs** (`*.prompt.md` prose).

Scope resolution by stack:

- `--mirror` + **react** ⇒ tokens, `components/**` (`.jsx`, `.d.ts`, `.prompt.md`),
  guidelines, readme/SKILL. Skip generated artifacts (`_ds_bundle.js`,
  `_ds_manifest.json`, `*.card.html`, `ui_kits/**`). Record scope `mirror`.
- `--mirror` + **non-react** ⇒ tokens (`styles.css` + `tokens/`) and
  `components/**/*.prompt.md` intent specs ONLY. Record scope `tokens`.
- `--full` ⇒ everything regardless of stack — **but always confirm before pulling.**
  A full mirror is the heavy scope (it drags in generated bundles, demo cards, and
  ui_kit, and in a non-react repo leaves dead `.jsx` that future sessions mistake for
  source of truth). Even with the flag present, **stop and ask the user inline** to
  confirm they want a full download rather than the slimmer `--mirror` — in a
  non-react repo, note in that same question that the React components/ui_kit won't be
  consumable there. Proceed only on an explicit "yes"; if they decline or don't
  answer, fall back to `--mirror` (or pointer-only if they'd rather). This is the one
  scope that is never silently executed.
- On a **refresh** (no scope flag but stored scope is `tokens`/`mirror`/`full`),
  re-detect the stack and refresh at the stored scope; if stack and stored scope
  now disagree (e.g. scope `full` in a non-react repo), flag the mismatch and
  suggest the stack-appropriate scope instead of silently re-pulling.

## Model / token strategy — important

- The **decisions** in this command (parse, verify, diff, doc edits) are light. They
  run fine on **Sonnet** — this command is meant to be invoked from a Sonnet session.
  Only recommend Opus for a genuinely unfamiliar or oddly-shaped first-time repo.
- The **bulk file pull** (only when `--mirror`/`--full`) must be delegated to a
  **Sonnet subagent** via the Agent tool (`subagent_type: general-purpose`,
  `model: sonnet`). The subagent does every `get_file` + `Write` and returns **only a
  summary** (counts, added/changed/removed paths, drift notes) — never file contents.
  This keeps the downloaded bytes out of the orchestrating session entirely. If the
  subagent reports it cannot access the `DesignSync` tool, fall back to doing the
  pulls in-session and say so.
- **Model advisory.** In one line before you start, flag it only if you're on a
  mismatched model — Opus for this mechanical pointer/refresh work (re-run cheaper on
  Sonnet), or a light model for a genuinely tricky first-time import into an
  unfamiliar/oddly-shaped repo (suggest Opus). Skip silently if the model fits or you
  can't tell which model you are; never block or switch — proceed either way. Full
  pattern (static hint + runtime check, and why the upgrade half is best-effort):
  `docs/shared-standards/MODEL_ADVISORY.md`.

## Steps

1. **Load the tool.** Ensure `DesignSync` is available; if not, load it with
   `ToolSearch(query: "select:DesignSync")`. If any DesignSync call returns an auth
   error, relay its guidance verbatim (it will mention `/design-login`) and stop until
   the user has authorized.

2. **Resolve + verify the project.** `DesignSync(get_project)` on the resolved
   `projectId`. Confirm `type` is `PROJECT_TYPE_DESIGN_SYSTEM`. If it's missing or the
   wrong type, tell the user plainly and stop. Capture `name`.

3. **Learn the namespace + shape (cheap).** `DesignSync(list_files)`. Note whether the
   project has `tokens/`, `components/`, `guidelines/`, `ui_kits/`, `_ds_bundle.js`,
   and read the namespace from `_ds_manifest.json`'s first ~1KB or the `@ds-bundle`
   header of `_ds_bundle.js` (grab just the header — don't slurp the whole bundle here).

4. **Detect the stack** (per "Stack detection" above) and resolve the effective
   scope. State the verdict in one line — e.g. *"Astro static, no React → --mirror
   means tokens + intent specs here."*

5. **Token drift check (always, if the repo has real tokens).** Detect the repo's own
   design-token source (`src/styles/*.css` custom properties, a Tailwind/theme config,
   `:root{--…}` anywhere). If found AND the project has `tokens/`, pull just the token
   CSS in-session (small) and diff the custom-property values. Report **matches** or
   **drift** (name the diverging tokens). This is the highest-value, lowest-cost signal
   — the repo's own token file is the source of truth for what actually ships; the
   design project should agree with it.

6. **Mirror (only on `--mirror` / `--full`).** Dispatch the Sonnet subagent described
   above. Give it: the `projectId`, the **exact path list to pull as resolved by the
   stack-aware scope rules** (tokens+specs for `tokens`; durable files for `mirror`;
   everything for `full` — for `full` it may `cp` any binary `assets/*` from the
   repo's own `public/` rather than re-downloading), the destination
   `docs/design-system/`, and the rule to overwrite changed files, add new ones, and
   list anything now-orphaned (don't delete without noting it). It writes a
   `docs/design-system/SYNC.md` provenance note that names the stack verdict, the
   scope, what was deliberately excluded and why, and which side is source of truth
   for tokens vs components.

7. **Record the pointer (always).** Write/overwrite `docs/design-system/.claude-design.json`:
   `{ "projectId", "url", "name", "namespace", "scope", "stack", "lastSynced" }` where
   `url` is the canonical `https://claude.ai/design/p/<uuid>`, `scope` is `pointer` |
   `tokens` | `mirror` | `full`, `stack` is `react` | `non-react`, and `lastSynced` is
   `date +%F`. (`mkdir -p docs/design-system` first.)

8. **Wire the docs (always).** Add or refresh a `## Claude Design System` section in
   the project's `CLAUDE.md`, placed **outside** any `shared-ai-docs:begin/end` managed
   block (append after the end sentinel if the whole file is managed). Idempotent —
   replace the existing section if present. Include: project name + URL, namespace,
   scope + stack + mirror location (if any), last-synced date, and the refresh command
   (`/fetch-claude-design`). In a non-react repo, add one line naming the repo's real
   token file and component directory as source of truth so future sessions never
   treat design-project output as shipped code. This section auto-loads into every
   future session, so agents know the design system exists and how to refresh it.

9. **Follow repo conventions.** If the repo versions (has `package.json`/CHANGELOG),
   bump the patch version and add a one-line CHANGELOG entry per the repo's style. If
   the repo is on `main`/`master`, create a `feature/…` branch first (a protected-main
   hook will block edits otherwise). Stage and commit the pointer + doc changes (and
   any mirror) with a clear message; do **not** push or merge unless asked.

10. **Report.** Summarize: which project, stack verdict, scope used (and why, if the
    stack narrowed it), token drift verdict, files added/changed (if mirrored), where
    the pointer lives, and the one-liner to refresh next time. If this was
    pointer-only, mention `--mirror` is available if they later want offline
    tokens/specs (or component files, in a react repo).

Keep questions to essentially zero: the only two you should ever need are (1) the URL
when there's no reference and no stored pointer, and (2) the `--full` confirmation gate
described above. Everything else has a safe default, and that default is pointer-only.
