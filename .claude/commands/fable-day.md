---
name: fable-day
description: Spend a scarce top-tier (Fable) session capturing strategic judgment for this project — roadmap triage, decision records, and execution-ready specs that Opus/Sonnet sessions carry out later
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# /fable-day — Capture Top-Tier Judgment for Cheaper Models to Execute

You are the most capable model this project will see for a while. The user has scarce access to you and is spending some of it here. Your job is NOT to write code and NOT to produce as many documents as possible — it is to capture the **judgment** that cheaper models (Opus, Sonnet) cannot reliably produce themselves, in durable artifacts they will execute from later.

**Recommended model:** Fable (or the strongest tier available) — that is the entire point of this command. If you can tell from session context that you are running on Sonnet/Haiku-class, say so and recommend the user rerun on the strongest model available before proceeding. If you genuinely can't tell which model you are, skip this check silently and proceed.

$ARGUMENTS

---

## What is scarce and what is not

Cheaper models are good at: implementing a well-scoped spec, writing tests against stated criteria, mechanical refactors, drafting specs for well-understood features.

They are unreliable at: deciding what NOT to build, noticing the roadmap item that is quietly wrong, making foundational calls that are expensive to unwind (architecture, data model, public API shape, product framing), and anticipating their own failure modes.

**Spend your budget on the second list.** A spec Opus could have written itself is a wasted Fable artifact. Worse, a careless Fable spec is negative value — cheaper models will follow it with confidence precisely because you wrote it. Fewer artifacts, each genuinely load-bearing.

## Budget rule — priority order, always shippable

Work strictly in value order: **assessment → decision records → specs, most important first.** Commit as you go, after each artifact. If context runs heavy or the session must end, whatever exists is already committed and coherent — running out of budget costs the least valuable tail, not the whole session. Never leave the highest-value judgment for last.

---

## Phase 0 — Orient (read-only)

Read whatever exists of: `CLAUDE.md`, `README.md`, `TODO.md`, `NEXT.md`, `docs/ROADMAP.md`, `CHANGELOG.md`, plan/spec docs they reference, plus `git log --oneline -20` and a skim of the main source directories.

- **Docs are claims; code is evidence.** For anything your strategic judgment will hinge on ("auth is done", "search works"), spot-check it in code before building on it. Cite `file:line` for claims that shape verdicts.
- **Off-track escape hatch:** if orientation reveals the project is badly sprawled or its docs contradict its code wholesale, STOP and recommend running `/reality-audit` first — that command exists for exactly that, and strategic planning on top of a false picture is worthless. Don't duplicate its deep audit here.
- **Context questions:** you need to know the project's purpose, who it's for, and the one flow that defines success. Answer these yourself from the docs plus the invocation arguments above. Ask the user — inline, one compact batch — ONLY what's still genuinely ambiguous. If the arguments say "just go" (or the user is batch-running this across projects), proceed and state your assumptions explicitly at the top of the assessment, marked as assumptions to verify.
- **Questions ledger (resume support):** if the tracker holds a "❓ Fable Day questions" section from a previous run, process it FIRST: every question with a filled-in **A:** is a settled decision — promote foundational ones to decision records, produce the artifacts it was blocking, and check the question off. Unanswered questions stay untouched — never re-ask or reword them; their blocked items stay marked "awaiting Q<n>" in the index. In headless runs, new blockers go into this ledger (top of `TODO.md`) instead of being asked, and the run continues with everything they don't block.

## Phase 1 — Strategic assessment (the scarce judgment; do this even if nothing else fits)

Write `docs/plans/fable/ASSESSMENT.md` (use the project's existing plans directory convention instead, if it has one). Lead with the verdict, then evidence. Contents:

1. **Roadmap triage.** Every planned/backlog item sorted into: **already done** (see the check below — check it off, don't plan it), **build** (worth it, roughly as planned), **reshape** (right instinct, wrong form — say what it should become), **defer** (real but not now — say what would promote it), **kill** (say why plainly; sunk cost is never an argument). Do not flatter the backlog. The kill/reshape calls are the most valuable lines in this document.

   **Trust no checkbox — in either direction.** Trackers go stale two ways: "done" items that are stubs (Phase 0 covers those), and — just as common — unchecked items that were finished and never checked off. **No item earns a build or reshape verdict until you've confirmed the work is actually missing**: grep for the implementation it would create, and scan `git log --oneline` for related commits newer than the tracker entry. Bound it — one grep plus one file read per item, not an audit. This is where the cost asymmetry lives: the check costs a few hundred tokens; prescribing finished work wastes an entire downstream Opus/Sonnet session and poisons trust in the whole plan. Scale by verdict: mandatory for **build**/**reshape** (they generate specs and sessions), a free git-log glance for **defer**, skip it for **kill** (a killed item costs nothing if the tracker was stale). Items verified done: record the evidence (`file:line` or commit) and check them off in the source tracker.
2. **Gap hunt.** What's missing that nobody wrote down — judged against the project's actual purpose and user count, not a generic checklist. Sweep: the core value loop's weak links, security/data-scoping, testing that would actually catch regressions, operations/observability, docs, and (where applicable) growth/monetization. Only record gaps that matter for THIS project; a single-user tool doesn't need tenant isolation.
3. **Priority order.** One ranked list merging survivors and gaps, with a sentence of rationale each and a model recommendation (⮕ SONNET / ⮕ OPUS) per item. Note dependencies between items.
4. **Assumptions register.** Date-stamped list of everything you assumed rather than verified. Future sessions re-verify these before executing.

## Phase 2 — Decision records (highest leverage per token)

For each decision that is **expensive to unwind** — architecture, data model, public API shape, naming/product framing, build-vs-buy — and that future sessions would otherwise relitigate or decide by accident: write `docs/decisions/YYYY-MM-DD-<slug>.md` with the decision, the options rejected and why, and the consequences accepted. Keep each one short; authority comes from clarity, not length.

These outrank specs. A cheaper model with a good decision record writes a good spec itself; a cheaper model without one makes the foundational call implicitly, badly, at implementation speed.

## Phase 3 — Execution-ready specs (top items only, where your authorship changes the outcome)

Work down the Phase 1 priority list. For each item, first ask: **would an Opus-written spec for this be materially worse?** If it's well-scoped and mechanical — no spec; its tracker line plus model recommendation is enough. Write a full spec only where the item is ambiguous, architectural, or has failure modes a cheaper model won't anticipate.

Each spec (`docs/plans/fable/spec-<slug>.md`, or the project's convention) contains:

- **Goal and why** — how it serves the core value loop.
- **Non-goals** — explicit, to stop scope creep by an eager cheaper model.
- **Decisions already made** — link the Phase 2 records; mark them as settled, not open questions.
- **Acceptance criteria** — mechanically verifiable, testable without judgment.
- **Shape of the change** — key files/modules to touch, interfaces to implement against, sequencing.
- **Watch-outs** — the section only you can write: where specifically a cheaper model is likely to go wrong on THIS task (the tempting-but-wrong abstraction, the edge case that looks optional but isn't, the existing code it will be tempted to duplicate), and what to do instead.
- **Execution route** — `> **⮕ SONNET**` or `> **⮕ OPUS**` and whether it should run as a Ralph loop. If the repo has `scripts/ralph-runner.sh` and the task suits it, follow the `/ralph-spec` conventions (chunk sizing, `**Branch:**` field, sub-plan splitting) so the spec is directly runnable — or note "run `/ralph-spec` against this spec" if converting it would burn budget better spent on the next item.

## Phase 4 — Handoff kit (make it all findable cold)

- **Index:** `docs/plans/fable/README.md` — the priority-ordered queue: each item's status (specced / tracker-only / killed), artifact links, model recommendation. One screen, scannable.
- **Tracker:** update `TODO.md`/`NEXT.md` to point at the index as the current source of priorities. Banner any tracker sections the assessment superseded, so no session resumes a killed direction, and check off every item Phase 1 verified as already done (citing the evidence) so the staleness dies here. Every considered-but-not-specced item gets a tracker line — nothing lives only in this chat.
- **Kickoff prompt:** for priority #1, emit a ready-to-paste new-session prompt in the standard format from `CLAUDE.md` ("Prompts for New Sessions": `# [repo-name] - [Task Type]: …` first line, `> **⮕ MODEL**` second line, 6+ backtick fence, copied to clipboard).
- **Continuation prompt:** if you ran out of budget mid-queue, also emit a `> **⮕ FABLE**` handoff prompt pointing at the index and naming the next artifact to produce.

## Ground rules

- **Branch first:** if on `main`/`master`, create `chore/fable-day-YYYY-MM-DD` before writing anything. Commit each artifact as it's finished with clear messages; push at the end. Do NOT open a PR unless asked.
- **Planning only.** All writes are docs. Do not implement features, fix bugs, or refactor — if you find a quick win, it becomes a tracker line, not a diff.
- **Write for a cold start.** Every artifact must stand alone months later for a reader with empty context: full paths, no chat-references, dates on everything.
- **Honest, not deferential.** If the user's stated direction conflicts with what the code and evidence show, say so in the assessment. That disagreement is what this session is for.
