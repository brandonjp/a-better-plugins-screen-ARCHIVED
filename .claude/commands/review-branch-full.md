---
name: review-branch-full
description: Maximum-assurance branch-review tier — Opus does everything: orchestration, reviewing, applying fixes, and verification. For the most critical code paths.
model: opus
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Review Branch — Full (Maximum Assurance) Tier

This is the **maximum-assurance** of the three review tiers. Everything runs on Opus — orchestration, the code-reviewer subagent, applying the fixes, and the verification pass. Use it for branches touching the most critical paths (payments, auth, data migrations, anything where a subtle bug reaching production would be costly).

For almost every branch the default `/review-branch` is enough — it already runs the reviewer and the verification pass on Opus. Reach for this tier only when you specifically want the fix-application itself done on Opus too.

## How to run it

Execute the **exact workflow documented in `/review-branch`** — read `.claude/commands/review-branch.md` for the full step-by-step — with no changes to the steps.

The only difference from the default tier: **you, the orchestrator, run on Opus** — pinned by this command's `model:` frontmatter — so the reading, reasoning, and fix-application in Steps 1, 3, and 4 are all done on Opus, not Sonnet. The reviewer subagent (Step 2) and the verification subagent (Step 4) already run on `model: opus` in the documented workflow; keep them there.

$ARGUMENTS
