---
name: reality-audit
description: Full project reality audit — verify what actually works vs. what's stubbed, dead, or only documented; deliver a brutal verdict; then commit a decision record and execution plan. Use when a project feels stale, sprawled, or off track.
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# /reality-audit — Full Project Reality Audit: what works, what's stubbed, what's next

You are auditing a project that may have gone stale, sprawled, or drifted off track. Your job: a complete, brutally honest reality audit, then concrete committed artifacts that move the project as far forward as possible.

Do not flatter. Do not assume the docs are true. Docs are claims; code is evidence.

**Model note:** This is deep-reasoning work, not mechanical work. If this session is running on a fast/cheap model (Haiku/Sonnet-class), say so and recommend the user restart the command on the strongest model available before proceeding.

$ARGUMENTS

---

## Ground rules (apply to every phase)

- Lead every report section with the conclusion, then the evidence.
- Cite `file:line` for every claim about code.
- When you find something that contradicts what the docs — or the user — told you, say so plainly.
- Phases 0–4 are read-only. Do not fix, clean up, or "improve" anything while auditing. All writes happen in Phase 5.
- Sunk cost is never an argument. "We already built it" does not make it worth keeping.

---

## Phase 0 — Get the context you need (ask before digging)

The audit is only as good as your understanding of what the project is FOR. Phase 1's sprawl judgment and Phase 3's core-loop trace both depend on it. You need answers to:

1. **Purpose** — what is this project supposed to do?
2. **Users** — who uses it today (or who is it for)? Roughly how many people?
3. **Core value loop** — the ONE flow that, if it works, means the project succeeds.
4. **The user's own diagnosis** — what feels wrong, stalled, or off track to them?
5. **Constraints** — budget, stack, timeline, anything immovable.

First try to answer these yourself from the invocation arguments above plus a quick skim of README and CLAUDE.md. Then ask the user — inline, as regular chat text, never via a question tool — ONLY the items still missing or ambiguous. Keep it to one compact batch of questions and wait for answers before starting Phase 1.

If everything is already answered, or the user says "just go," proceed — but state your assumed answers explicitly at the top of the report and treat them as hypotheses to verify, not facts.

Treat the user's answers as context, not gospel. If they say "search works," verify it anyway.

## Phase 1 — Orient and size it

- Repo structure, recent git log arc — look for pivots, merge patterns, long gaps, and "chore" churn near the end of activity.
- Quantify sprawl: total LOC, the 5 biggest files, DB table/migration count, route/template/endpoint count, test file count. Then judge those numbers AGAINST THE PROJECT'S ACTUAL PURPOSE AND USER COUNT — 60K lines for a single-user tool is itself a finding.
- Version consistency across every file that declares one (package manifests, pyproject/setup/package.json/composer.json, source version constants, README badges, changelog).

## Phase 2 — Mine the docs for the official story AND the self-diagnosis

Read ALL planning artifacts: vision/roadmap/spec docs, NEXT/TODO trackers, changelogs, prior audits, plans, archived phases, `.claude/` commands and audit files.

- What does each doc claim is the current direction, and what does it claim is "complete"?
- Where do docs contradict each other or the code?
- CRITICAL: find the repo's own confession — abandoned rebuild specs, unimplemented audit findings, bug lists that were written and never actioned, "do not implement yet" plans. Stale projects usually contain an accurate self-diagnosis somebody wrote on the last active day. Find it and take it seriously.
- Are two contradictory futures alive at once (e.g., a "harden v1" backlog AND a "rebuild as v2" spec) with no decision record choosing one? That ambiguity is usually the root cause of the stall.

## Phase 3 — Code reality check (run parallel agents; be very thorough)

Launch parallel read-only subagents (Explore-type where available). Adapt the greps and patterns below to the project's actual language(s) and framework(s).

**Agent A — the core value loop:** trace the ONE flow the project exists for, end to end, in code. Does it actually work? Where does it break in practice (not in tests)? Note quality issues a green test suite would hide.

**Agent B — claimed-complete vs. actually-stubbed:** grep for TODO/FIXME/XXX/HACK, bare `pass` bodies, `NotImplementedError`, "not implemented" throws, hardcoded/empty returns, "would normally" / "in a real implementation" comments. Cross-reference every feature the docs call "complete/shipped" against its implementation. Find UI that exists with no backend behind it, and config/settings screens that store values nothing reads.

**Agent C — dead code and broken wiring:** modules with zero inbound references; blueprints/routers/controllers never registered; templates referenced by nothing; endpoints referenced by templates/JS that don't exist server-side; entire subsystems (queues, realtime, integrations) implemented but never invoked by any live flow.

**Agent D — tests and integrity:** how much of the suite is mock-everything vs. real behavior? Skipped/xfail markers? Would the suite stay green if the core feature were broken? (This is common — a fully green suite of hundreds of tests over a broken product.) Quick security/scoping pass: if there are users/teams/tenants, is data ACTUALLY scoped per tenant in the queries, or is multi-tenancy cosmetic?

## Phase 4 — Classify and deliver the verdict

Sort every major component into four tiers, with `file:line` evidence:

1. **Real and working**
2. **Built but unused** — dead weight; candidate for deletion, not completion
3. **Documented as complete but actually stubbed** — the credibility gap
4. **Missing but load-bearing** — gaps in the core value loop

Then deliver the verdict, leading with the TLDR:

- Is the original goal still feasible?
- Is the foundation worth keeping — patch it, trim it hard, or freeze-and-rebuild? (Most of a sprawled codebase is usually what you'd delete anyway.)
- What is the SHORTEST path to the core value loop working reliably?
- What expectations should the user recalibrate?

**Decision checkpoint:** if two directions are both genuinely defensible (e.g., patch vs. rebuild), present both with your recommendation and ask the user — inline — to choose before Phase 5. If the evidence clearly favors one direction, say so and proceed.

## Phase 5 — Move it forward (commit artifacts, don't just talk)

- **Branch:** if currently on `main`/`master`, create `chore/reality-audit-YYYY-MM-DD` first. Otherwise use the current working branch.
- **Decision record** — write and commit `docs/decisions/YYYY-MM-DD-<slug>.md`: chosen direction, what's frozen/cancelled, why, with the evidence.
- **Execution plan** — write and commit a sequenced plan: milestones with mechanically-verifiable acceptance criteria, dependency-ordered, with quality guardrails baked in (real-fixture/golden-set tests where detection or data quality matters; cost/budget kill-switches BEFORE any paid API; observability before scale).
- **Banner the stale trackers** — add a short pointer to the decision record at the top of NEXT/TODO/README-status docs whose direction was cancelled or superseded, so no future session resumes the dead direction.
- **Kick off milestone 1:**
  - If the repo has `scripts/ralph-runner.sh`: write runnable Ralph spec files per milestone, following the conventions in `.claude/commands/ralph-spec.md` (chunk sizing, review checkpoints, `**Branch:**` field).
  - Otherwise: end with a copy-paste kickoff prompt for the first milestone in the standard new-session format from CLAUDE.md — `# [repo-name] - [Task Type]: [description]` first line, `> **⮕ SONNET**`/`> **⮕ OPUS**` second line, wrapped in a fenced block of 6+ backticks.
- **Commit and push** everything to the working branch with clear messages. Do NOT open a pull request unless the user asks.

---

## Final report

End with a single consolidated report: the TLDR verdict first, then the four-tier classification, the contradictions found (docs vs. code, docs vs. docs, user's belief vs. reality), the chosen direction, and the list of committed artifacts with paths.
