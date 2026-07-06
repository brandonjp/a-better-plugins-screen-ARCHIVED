# Project Guide

## Ralph Loop — Automated Plan Execution

This project uses **Ralph**, an automated orchestrator that implements chunked plans via Claude CLI.

| Resource | Path | Purpose |
|---|---|---|
| **Run a spec** | `scripts/ralph-runner.sh` | Execute a spec with implement → review → fix loop |
| **Create a spec** | `/ralph-spec` command | Claude command to generate properly structured specs |
| **Example specs** | `docs/archive/plan-*.md` | Completed specs showing the expected format |

```bash
# Create a Ralph spec (in Claude Code)
/ralph-spec

# Preview execution
bash scripts/ralph-runner.sh docs/plan-my-feature.md --dry-run

# Execute (auto-resumes if interrupted — just re-run the same command)
bash scripts/ralph-runner.sh docs/plan-my-feature.md

# Re-run review for a specific chunk
bash scripts/ralph-runner.sh docs/plan-my-feature.md --review-only 2
```

The Ralph loop uses Sonnet for implementation and Opus for review by default. Press Ctrl+C to abort gracefully (progress is saved). See `scripts/ralph-runner.sh --help` for all options.

<!-- shared-ai-docs:begin — MANAGED shared standards block. Do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Project-specific content belongs OUTSIDE this block (above or below the sentinels). The sync replaces only what is between the begin/end markers. -->

## Shared Docs Freshness

Some of this project's files (docs/shared-standards/, shared `.claude/commands/`, `scripts/ralph-runner.sh`, this managed block) are synced from the shared-ai-docs repo and can go stale if this project missed a sync. **When the user says anything like "check for shared docs updates", "are the shared docs current?", "before you begin, check if any shared-ai-docs need updates", or "is this project synced?"** — run the `/check-shared-docs` workflow (a read-only dry-run report; it changes nothing). If they ask to actually update/pull/sync them, use `/sync-shared-to-here`. Never blindly overwrite a locally customized copy — the dry run FLAGs those; they need a smart merge that preserves the local tailoring.

## Git Workflow

- **Fetch before rebase:** Always run `git fetch origin` before rebasing onto `origin/main` or any remote branch.
- **Commit all generated artifacts:** Plans, specs, `.superpowers/` brainstorm files, ralph-state files, and any other generated docs — always commit them. Never leave generated artifacts untracked.

## Ralph Loops & the Machine-Level Queue

- This project's ralph runner is the synced copy at `scripts/ralph-runner.sh`. Since v4.11 it survives Claude usage/plan limits on its own: when a limit is hit it waits `--limit-wait` minutes (default 20) and retries until the limit lifts. Run unattended (no TTY), it never blocks on its r/s/q prompt — it exits 2 with progress saved.
- **When the user wants to run SEVERAL ralph loops (this project's and/or other projects') back-to-back** — e.g. overnight, sharing one Claude plan-limit budget — point them to the machine-level queue runner (do NOT reinvent one):
  `/Users/brandonjp/Dropbox/Dropbox2/ProjectsDropbox/AI-Shared-Directives/shared-ai-docs/bin/ralph-queue.sh`
- Queue file format, one job per line: `<absolute-repo-dir> ::: <ralph command>`. The launch command to give the user (wrapped per the copy/paste rules):
  `caffeinate -i bash <path-to-ralph-queue.sh> <queue-file>`
  (`caffeinate -i` is a built-in macOS utility that prevents idle sleep while the command runs, so the Mac can't doze off mid-queue. Knobs: `--interval MIN` between limit rechecks, default 20; `--dry-run`; `--reset`.)
- The queue runs jobs sequentially, waits out usage limits itself, skips a job on real (non-limit) failure so the rest keep going, and records completed jobs in `<queue-file>.state` so re-running the same command resumes cleanly. Per-job logs: `~/.ralph-queue/logs/`. Queue jobs that invoke ralph-runner are executed with shared-ai-docs' canonical runner (not this project's synced copy), so queue-file snippets using `bash scripts/ralph-runner.sh …` are correct even if this repo's copy is stale.
- The user's personal `/ralph-queue` command (in `~/.claude/commands/`) automates queue-file setup; suggest it when relevant.
- **Anytime you hand the user a ralph plan run command** (`bash scripts/ralph-runner.sh …`), ALWAYS also give the same job as a ready-to-paste TWO-line queue snippet: a `#` comment header identifying the project + task (handoff-prompt style; `ralph-queue.sh` skips `#` lines), then the job line with the repo's real absolute path + the real command:
  ```
  # <repo-name> - Ralph: <specific task description>
  <absolute-repo-dir> ::: bash scripts/ralph-runner.sh docs/plan-<n>.md --branch feature/<n>
  ```
  Label the two clearly ("run it directly" vs "or as a ralph-queue job") so the user can either run it now or paste the snippet into their current queue file unchanged.

## Claude Design Systems

When starting design work in this project (new UI, landing page, redesign, component work), check whether a claude.ai Design System is set up — look for a "Claude Design System" status section in this project's `CLAUDE.md` (outside this managed block). If there isn't one, remind the user the feature exists and help fill out the setup form: see `docs/shared-standards/CLAUDE_DESIGN_SYSTEM_SETUP.md` for field-by-field guidance. When you hand the answers over, copy ONE clipboard block — field 1 (blurb), the full repo URL, and field 5 (notes), blank-line separated — and skip the Figma/fonts fields (nothing to paste). Draft field 5 from the project's real brand/design doc wherever it lives (`docs/DESIGN.md`, `docs/brand/*.md`, the README, or the design-token file); don't assume `docs/brand/`.

## Communication Style

### Scope Questions
When the user asks "should this be a Ralph loop?", "worth a PR?", "is this better as X?" — give a direct yes/no + one sentence why. Do not explain the tool, its benefits, trade-offs, or general guidance. Treat these as experienced-developer shorthand.

### Prefer Inline Questions Over AskUserQuestion
Never use the `AskUserQuestion` tool — it obliterates any text the user has typed. Ask clarifying questions inline as regular chat text instead.

## Branch & PR Workflow

- **When the user names a specific branch or PR**: ALWAYS check out that branch (or fetch and base your work on it) before making any changes. If you are assigned a separate working branch by the system, merge or rebase the user's specified branch into yours first so you have its code. Never start work from `main` alone when the user has pointed you at a feature branch.
- **Why this matters**: Ignoring the user's specified branch leads to missing context, merge conflicts, duplicated work, and wasted tokens. Treat the user's branch/PR reference as a hard requirement, not a suggestion.

# User Preferences

## Session Handoff & Follow-Up Capture — no orphan follow-ups

Full standard: `docs/shared-standards/SESSION_HANDOFF_PROTOCOL.md`. The rules, condensed:

- **If a follow-up is worth mentioning, it's worth writing down.** Any "consider X later", "worth looking into", deferred task, out-of-scope discovery, or unapplied review finding that appears in a response MUST be written to the project's tracker (`TODO.md`/`NEXT.md`/plan doc) in the SAME turn — then say where it was recorded (e.g. "(added to `TODO.md` → Next)"). Never leave a follow-up living only in chat; Brandon should never have to ask "was that documented?". If it isn't worth a tracker line, don't frame it as a follow-up.
- **Assume the context clears after every response.** After substantive work, leave the tracker + durable docs in a state where a brand-new session resumes cold from `TODO.md` alone, and end with a one-line cold-start pointer. If that pointer would be false, fix the docs first.
- **Fresh-session triage.** When a session sprawled into tangents, classify each follow-up: (1) do now; (2) tracker for later; (3) substantial task that would run better in a clean-context session → add the tracker line AND say so AND provide a ready-to-paste handoff prompt (per "Prompts for New Sessions", 6+ backtick fence, `pbcopy`'d).
- **Event-based, not size-based.** No token-count polling or hooks; triggers are finishing substantive work, `/session-close`, or the harness's own heavy-context warning (treat that as a cue to proactively offer bucket-3 handoffs).
- **Self-check before ending a turn:** scan your response for follow-up language (*consider, might want, later, eventually, worth exploring, next step*) — every hit maps to a tracker line written this turn, or gets cut.

## Model Sanity Check — flag model mismatches in BOTH directions

The model ladder, cheapest to most capable: **Sonnet → Opus → Fable** (Fable 5 is a Mythos-class tier above Opus — strongest on ambitious, ambiguous, or creative work). Before starting ANY substantive task, do a quick sanity check in both directions:

**Downgrade — flag when a cheaper model would do.** Could a cheaper tier handle this well (Opus for most work, Sonnet for well-scoped tasks with clear instructions)? If the current session is running a more expensive model than the task needs (e.g. Fable doing something Opus-capable), say so up front in ONE line — e.g. "FYI: this is Opus-capable — want a handoff prompt for a cheaper session?" — before doing the work. If asked for the handoff, format it per "Prompts for New Sessions" below.

**Escalate — flag when the task looks Fable-shaped.** Do NOT self-assess capability ("am I good enough for this?" always answers yes — see `docs/shared-standards/MODEL_ADVISORY.md`). Instead check the TASK against these objective triggers, any of which is worth a flag:

- Requirements are genuinely ambiguous or taste-driven: product framing, greenfield architecture, design direction, naming, "make this good" briefs.
- You've made 2+ failed attempts at the same bug, or a fix keeps regressing/bouncing back in review.
- An early decision would be expensive to unwind later (cross-repo impact, foundational architecture, public API shape).
- The user wants a second opinion, or the output is hard to verify cheaply.

When a trigger matches, say so in ONE line — e.g. "this looks Fable-shaped (ambiguous architecture) — want a handoff prompt for a Fable session?" — then proceed either way. Never block on it, never claim certainty that a stronger model is needed; it's an offer the user can ignore.

- Skip the flag (either direction) when the task is trivial enough that answering now costs less than a handoff round-trip — just do it.
- This is about matching capacity to the task: reserving expensive models for work that genuinely needs them (deep multi-file reasoning, subtle debugging, ambiguous architecture) AND not quietly under-serving that work with a lighter tier.

## Prompt Formatting for Copy/Paste

When giving me a prompt to copy/paste elsewhere, ALWAYS wrap the entire prompt in a fenced code block using 6+ backticks so it's easy to select and copy on mobile. Never use tables inside prompts meant for copying — use bullet lists or plain text instead. I often work from the Claude mobile app where table selection is broken.

## Clipboard in Claude Code CLI

When running in Claude Code CLI (or any desktop terminal harness) and generating any prompt, command, snippet, PR body, or other text meant to be pasted elsewhere, ALWAYS copy it to the clipboard automatically as part of the same response — don't wait to be asked. Still show the content in chat so I can see what was copied.

- **macOS:** `pbcopy` via a heredoc.
- **Linux:** `xclip -selection clipboard` or `wl-copy`.
- **Windows:** `clip`.
- Use a unique heredoc sentinel (e.g., `PROMPT_EOF`) when content may contain `EOF`.
- Does NOT apply to inline answers, code edits made via file-edit tools, or content only relevant within the current session.

**Why:** skipping this forces a predictable two-step ("generate prompt" → "now copy it") that should be one step. If I have to ask you to `pbcopy` it, you missed the rule.

## Prompts for New Sessions

Whenever you generate a prompt meant to be pasted into a new chat session — whether from a slash command or a freeform request like "give me a prompt to tackle X" — follow this format:

**First line** — heading with the project name:

```
# [repo-name] - [Task Type]: [specific task description]
```

**Second line** — model recommendation:

```
> **⮕ SONNET**
```
or
```
> **⮕ OPUS**
```
or
```
> **⮕ FABLE**
```

Use your judgment to recommend the right model for the task:
- **SONNET** for: straightforward implementations, config changes, small bug fixes, docs updates, well-scoped tasks with clear instructions, tasks where the prompt itself provides sufficient context
- **OPUS** for: complex multi-file refactors, architectural decisions, ambiguous requirements that need interpretation, tasks requiring deep codebase reasoning, debugging subtle issues, anything where you'd want the model to think carefully about tradeoffs
- **FABLE** for: genuinely ambitious, ambiguous, or creative work — greenfield architecture with wide blast radius, taste-driven design/product decisions, second-opinion reviews of critical work, problems that have already defeated an Opus session. Fable is the scarce tier — recommend it only when one of those actually applies, not as a better-safe-than-sorry default.

When in doubt between Sonnet and Opus, recommend OPUS — it's better to over-spec than to waste a session on a model that struggles with the task. Do NOT resolve doubt by escalating to FABLE; that tier needs a positive reason.

**General rules:**
- Use the actual repository/folder name (e.g., `booklink-fyi`, `audiobees`, `splitgive`)
- Task type examples: `Feature`, `Fix`, `Refactor`, `Test`, `Docs`, `Config`, `Setup`
- Be specific in the description — never use generic text like "continue development" or "next steps"
- This applies to ALL generated prompts for new sessions, not just `/whats-next` or `/session-close`

<!-- shared-ai-docs:end -->
