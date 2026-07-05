---
name: review-branch-quick
description: Cheapest branch-review tier — Sonnet does everything, no Opus verification pass. Only for trivial, low-stakes branches.
model: sonnet
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Review Branch — Quick (Low-Stakes) Tier

This is the **cheapest** of the three review tiers. Use it ONLY when you have consciously decided the branch is genuinely trivial and low-stakes — a small doc tweak, a config bump, a throwaway experiment. For anything touching real logic, real users, or production paths, use `/review-branch` (the safe default) or `/review-branch-full`.

If you are not sure which tier to use, you are in the wrong command — stop and run `/review-branch` instead.

## How to run it

Execute the **exact workflow documented in `/review-branch`** — read `.claude/commands/review-branch.md` for the full step-by-step — with these two changes, and nothing else:

1. **Step 2 — dispatch the `superpowers:code-reviewer` subagent with `model: sonnet`**, not Opus.
2. **Skip Step 4 entirely** — this tier has no separate Opus verification pass.

Everything else is identical: understand the scope (Step 1), act on every finding and fix it directly (Step 3), version & doc consistency (Step 5), commit & push (Step 6), and the calibration check. You, the orchestrator, run on Sonnet — pinned by this command's `model:` frontmatter.

$ARGUMENTS
