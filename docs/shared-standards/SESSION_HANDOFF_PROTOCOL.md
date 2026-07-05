# Session Handoff Protocol — no orphan follow-ups, cold-start-ready docs

**Status:** Universal standard — applies to every project synced with shared-ai-docs.
**Audience:** AI agents (Claude Code and similar) working in Brandon's repos; also useful to humans closing a work session.
**Companion:** the condensed rules live in the shared `CLAUDE.md` managed block ("Session Handoff & Follow-Up Capture"); this doc is the full standard.

---

## The problem this solves

Two recurring failure modes, both observed repeatedly in real sessions:

1. **Orphan follow-ups.** After substantive work (especially code reviews and multi-tangent sessions), the agent's chat response says things like "you might want to consider X" or "a future improvement would be Y" — but nothing gets written to the project's tracker. The chat scrolls away; the follow-up dies. Brandon then has to ask "was that documented anywhere?", and ~30-40% of the time the answer is no. That question should never need asking.
2. **Hot-context follow-ups.** Sessions that sprawled into unexpected tangents produce follow-up tasks that would execute *better* in a fresh session — but the agent neither says so nor prepares the handoff, so the work either continues in a polluted context or evaporates.

## Rule 1 — If a follow-up is worth mentioning, it's worth writing down

Any of the following, appearing anywhere in a response, is a **follow-up** and MUST be persisted to the project's tracker (`TODO.md`, `NEXT.md`, plan doc, or issue tracker — whatever the project uses) **in the same turn, before ending the response**:

- "You might want to consider…" / "worth looking into…" / "I'd recommend eventually…"
- A discovered problem that was out of scope and left unfixed.
- A task explicitly deferred ("later", "next session", "when X lands").
- Review findings not applied.
- Anything phrased as advice about future work.

Then **say where it was recorded** — e.g. "(added to `TODO.md` → Next)". The confirmation is part of the rule: Brandon should be able to see, without asking, that nothing lives only in chat.

Corollary: **if it isn't worth a tracker line, don't present it as a follow-up.** Passing observations are fine as prose; the moment something is framed as "should happen later," it's tracker-or-silence.

## Rule 2 — Assume the context clears after every response

Write project docs so a brand-new session (or a `/clear`) can resume from the tracker alone:

- The tracker's "Now"/"Next" items must be self-contained: file paths, command names, enough context that a cold agent needs no chat history.
- When a session materially changed project state (versions, decisions, new workflows), the durable docs (README status line, CHANGELOG, decision records) carry it — not just the chat summary.
- End substantive work sessions with a one-line cold-start pointer: *"Next session can start cold from `TODO.md` → Now."* If that sentence would be false, fix the docs until it's true.

## Rule 3 — Fresh-session triage for follow-ups

At the end of substantive work — especially when the session wandered into unplanned tangents — classify every follow-up into exactly one bucket:

1. **Do now** — small, in-scope, context helps → just do it (per the Bias to Action preference).
2. **Tracker for later** — real but not urgent → tracker line per Rule 1.
3. **Better in a fresh session** — the task is substantial and the current context is polluted with tangents it doesn't need → do ALL of:
   - Add the tracker line (Rule 1 still applies — the prompt supplements the tracker, never replaces it).
   - Say explicitly that a fresh session is the better venue and why (one clause is enough: "heavy tangent context").
   - Provide a ready-to-paste handoff prompt per the "Prompts for New Sessions" format (`# [repo] - [Type]: [task]` + model recommendation), wrapped in a 6+-backtick fence and copied to the clipboard (`pbcopy`) per the standing clipboard rule.

Signals that bucket 3 applies: the session fixed things unrelated to the original request; the follow-up needs none of the current context; a code review just produced a batch of independent fixes; the follow-up is itself review-sized.

## Trigger discipline — event-based, not size-based

Do **not** poll context size or build token-count hooks; the cost/noise isn't worth it. The triggers are events:

- Finishing any substantive task or review → run the Rule 3 triage.
- The harness warning that context is heavy (e.g. the >100k notice) → treat as a cue to *proactively* offer bucket-3 handoffs for whatever remains, not as an emergency.
- `/session-close` (where installed) → executes Rules 1-3 as part of wrap-up.

## Self-check before ending a turn

Scan the response you are about to send for follow-up language — *consider, might want, later, next step, eventually, worth exploring, future improvement, TODO*. Every hit must map to either (a) a tracker line written this turn, or (b) work you actually did. If neither: write the tracker line or cut the sentence.

---

*Added 2026-07-05 after a depression-atw-book session review; the "handled it well" pattern that session demonstrated (review doc + cross-referenced TODO + cold-start pointer) is the behavior this standard makes mandatory.*
