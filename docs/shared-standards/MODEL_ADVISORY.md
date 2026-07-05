<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Model Advisory

> **Purpose:** A reusable pattern for helping the user run each command on the *right* Claude model — cheap enough to not overpay, capable enough to not miss things. Any command can adopt it. It has two tiers: a **static model hint** the command declares up front (load-bearing, always shown), and an optional **runtime advisory** the running model emits when it notices a mismatch the static hint couldn't predict (best-effort).
>
> **Why this exists:** Running a subtle, judgment-heavy command on a light model can silently miss things and force an expensive scrap-and-rerun on a stronger model. Running mechanical work on an expensive model just wastes money. Both are avoidable if the command tells the user which model fits — and, where it can, notices at runtime when reality diverges.

---

## The core insight — declare fit, don't (only) detect it

Model fit is mostly a **property of the command**, not something to rediscover at runtime. Whoever authors the command knows whether it's mechanical or subtle — that judgment is available once, at authoring time, with full context. So the **load-bearing** mechanism is a *static declaration*, shown every run regardless of which model is executing.

The runtime self-check is a genuine but **weaker** supplement, for two structural reasons — know them so you weight the two tiers correctly:

1. **A model is an unreliable judge of whether a task exceeds its own ability.** The model you'd ask "is this too hard for me?" is the same model that would miss things — if it had the judgment to know it's out of its depth, it would likely have done better in the first place. So the *upgrade* advice (light model → suggest a stronger one) — the higher-stakes half — is the *least* reliable half. Do not treat it as a safety net.
2. **Models are unreliable at knowing which model they are.** Self-identification depends on the harness surfacing it in context, and often it isn't. So the runtime check must **no-op silently when the model genuinely can't tell** — which means it goes quiet in exactly some of the cases you'd want it loudest.

The reliable direction is the inverse: a strong model **can** accurately recognize when work is trivial. So *"you're overpaying for mechanical work, safe to re-run cheaper"* is the runtime advisory's most dependable output.

**Takeaway:** lead with the static hint. Use the runtime advisory to catch the runtime-only signal the static hint can't know (an unusually-shaped repo, a task that turned out bigger than it looked) — never as the primary defense.

---

## Tier 1 — Static model hint (load-bearing; every command that cares should have one)

Declare the recommended model in the command, in a short, always-visible form. Two places, use whichever fits:

- **Frontmatter `model:`** — when the command should default to a specific model (`model: sonnet` for mechanical commands, `model: opus` for judgment-heavy ones). This is the strongest signal: the harness can honor it directly.
- **A one-line "Recommended model" note in the body** — states the default *and the escalation condition*, so the reader knows when to override. Example:

  > **Recommended model:** Sonnet — this command is mechanical (parse, diff, doc edits). Use Opus only for a genuinely tricky first run in an unfamiliar or oddly-shaped repo.

The escalation condition is the valuable part: it's the authored judgment about *when the default stops being right*, which no runtime check can reconstruct as reliably.

This mirrors the "Prompts for New Sessions" `⮕ SONNET` / `⮕ OPUS` convention — same muscle, applied inside the command.

---

## Tier 2 — Runtime advisory (optional supplement; best-effort, honest about its limits)

Include this block only in commands where a model mismatch is genuinely costly (subtle, judgment-heavy, or expensive-to-rerun work) — not in trivial ones, where the instruction tokens and the model's self-reflection output aren't worth it.

Drop-in snippet (adapt the task specifics in brackets):

> **Model advisory.** From the session context, note which model you're running as — **if you genuinely can't tell, skip this silently; do not guess.** Then, in **one line before you start**, flag a mismatch *only if there is one*:
> - Running an **expensive** model (Opus) on what is really **mechanical** work → say it's safe and cheaper to re-run on Sonnet.
> - Running a **light** model on a genuinely **tricky/subtle** task *[name the condition for this command, e.g. "a first-time import into an unfamiliar or oddly-shaped repo"]* → suggest Opus for this one.
>
> If the model already fits the task, say nothing about it. Never block or switch models yourself — this is advice the user can act on or ignore; **proceed either way.**

### Guidance for authoring the block

- **Timing: advise *before* you start.** A warning after the work is done is wasted — the tokens are already spent.
- **Weight the two directions per the core insight.** The downgrade ("you're overpaying") is reliable. The upgrade ("this may be too hard for me") is best-effort — phrase it as a suggestion, never a guarantee of catching every mismatch.
- **Fresh invocation vs. mid-session switch.** For a *fresh* command run there's no sunk context, so a downgrade suggestion is clean — switching costs nothing but a new session. *Mid-session*, switching models means a new session and losing already-loaded context, which can make a downgrade a wash even when a cheaper model could do the remaining work. If the command runs mid-flow, note that the switch may not be worth the lost context.
- **One line, no ceremony.** This is a single advisory line, not a section. If there's no mismatch, it produces no output at all.

---

## Adoption checklist

- [ ] **Tier 1 always:** does the command declare a recommended model (frontmatter `model:` and/or a one-line "Recommended model" note with an escalation condition)?
- [ ] **Tier 2 where it pays:** is this command subtle/expensive enough that a mismatch would cost a scrapped rerun? If yes, include the runtime advisory block. If it's trivial, skip it.
- [ ] Does the runtime block **no-op silently** when the model can't self-identify (no guessing)?
- [ ] Does it advise **before** the work starts, in **one line**, and **proceed either way** without blocking?
