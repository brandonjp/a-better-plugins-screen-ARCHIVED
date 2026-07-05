---
name: review-branch
description: Deep code review of branch work — default (balanced) tier. Sonnet orchestrates and applies fixes, Opus reviews and verifies. See /review-branch-quick and /review-branch-full for the other tiers.
model: sonnet
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Review Branch — Deep Code Review & Cleanup

You are performing an exhaustive code review of all recent work on the current branch. Your goal is to get this branch into a state where it is ready for production release.

**This is NOT a quick skim.** A real branch with meaningful work will have dozens of findings across correctness, style, accessibility, encoding, type safety, edge cases, and more. If you only find 1-2 issues, you haven't looked hard enough.

## Review tiers — pick consciously, default to this one

There are three review commands. **This one, `/review-branch`, is the default** — reach for it by reflex, and use it whenever you are unsure. It is the safe choice, so forgetting which tier to pick fails toward safety, not toward risk.

| Command | Orchestrator (applies fixes) | Reviewer subagent | Verification pass | Use when |
|---|---|---|---|---|
| `/review-branch` | Sonnet | **Opus** | **Opus** (always) | The default. Almost every branch. Balanced cost and safety. |
| `/review-branch-quick` | Sonnet | Sonnet | none | You have *consciously* decided the branch is trivial and low-stakes (doc tweak, config bump, throwaway experiment). |
| `/review-branch-full` | **Opus** | Opus | Opus (always) | The branch touches the most critical paths (payments, auth, data migrations) and you want zero compromise. |

Each command pins its orchestrator model via `model:` frontmatter — you never switch models manually. In every tier the expensive Opus judgment is spent where it catches bugs: reviewing the code and verifying the fixes.

$ARGUMENTS

## Step 1: Understand the scope

1. Identify the current branch and its base (main/master)
2. Review all commits on this branch since it diverged: `git log main..HEAD --oneline`
3. Get the full diff stat: `git diff main..HEAD --stat`
4. Capture the git SHAs you'll need:
   ```bash
   BASE_SHA=$(git merge-base main HEAD)
   HEAD_SHA=$(git rev-parse HEAD)
   ```
5. Read every changed file to build a summary of what was done and why

## Step 2: Dispatch the code-reviewer subagent

**Do NOT review the code yourself.** Dispatch a dedicated `superpowers:code-reviewer` subagent to perform the structured review. The subagent is specifically built for thorough, line-by-line analysis with severity categorization — it will catch things you would miss in a manual pass.

Use the Agent tool with `subagent_type: "superpowers:code-reviewer"` and **`model: opus`** — the reviewer's judgment is where issues get caught, so it runs on Opus even though you, the orchestrator, run on Sonnet. Provide:

- **What was implemented** — summarize the branch work from Step 1
- **Plan/requirements** — what the work was supposed to accomplish (check commit messages, PR descriptions, TODO.md, any spec files)
- **BASE_SHA and HEAD_SHA** — the git range to review
- **Description** — brief summary for the reviewer's context

Tell the reviewer to check ALL of these categories thoroughly:
- Correctness: logic errors, off-by-one, broken edge cases
- Reliability: error handling gaps, race conditions, missing validation
- Security: injection risks, exposed secrets, unsafe defaults
- Style & consistency: naming, code style, patterns that don't match the codebase
- Dead code: unused imports, unreachable branches, commented-out blocks
- Type safety: incorrect or missing types, unsafe casts
- Encoding & escaping: HTML entities, URL encoding, string escaping issues
- Accessibility: missing ARIA attributes, semantic HTML issues (if applicable)
- Performance: unnecessary loops, missing early returns, N+1 patterns

If the branch touches multiple independent subsystems (e.g., backend API + frontend UI + database migrations), dispatch **parallel code-reviewer subagents** — one per subsystem — so each gets focused attention. Every reviewer subagent runs on `model: opus`.

## Step 3: Act on review results

When the reviewer returns findings:

### Fix everything you can
Work through every Critical and Important issue. Fix them directly — do not just acknowledge them. Then work through Minor issues too. The goal is to resolve as many findings as possible, not to triage them into a backlog.

### Document what you cannot fix
For anything that genuinely requires human judgment (business logic decisions, UX tradeoffs, architectural questions):

- Capture it clearly in the appropriate project doc (TODO.md, roadmap, or similar)
- Include: the file:line reference, what the issue is, why it needs human review, and the reviewer's suggested fix
- Include enough context that someone encountering it weeks later will understand what needs to be done

### Cross-reference everything
If the branch added any new spec files, design docs, or plans, make sure they are referenced from the main project docs (README, TODO, etc.) so they are discoverable.

## Step 4: Verify the applied fixes

This step is the safety gate — it runs on every `/review-branch` review.

Once every fix from Step 3 is applied, commit them, then dispatch a fresh `superpowers:code-reviewer` subagent with **`model: opus`** to review **only that fix commit's diff** — the fixes themselves, not the original branch work. Instruct it to confirm the fixes are correct, complete, and introduced no regressions or new issues.

If this pass surfaces anything, fix it and re-verify. An independent Opus pass over the fixes is what makes a Sonnet-orchestrated review safe — do not skip it.

## Step 5: Version and doc consistency

Make sure all version references across the project are consistent and accurate:
- Main source file header/constant
- README.md, package.json, package-lock.json, or equivalent
- CHANGELOG.md (should have an entry for the current version's work)
- Any other files that declare a version number

If versions are out of sync, align them to the correct current version. If work was done that warrants a version bump and none has been applied yet, bump appropriately using semantic versioning.

Update project documentation (README, CHANGELOG, etc.) to reflect the current state of the codebase.

## Step 6: Commit and push

1. Stage and commit all changes with a clear message describing the review cleanup
2. Verify nothing is left uncommitted or unstaged: `git status`
3. Push to the current branch

Do NOT merge to main. Leave the branch ready for the user to run `/finish` or review themselves.

## Calibration

If the code-reviewer subagent returns fewer than ~10 findings on a branch with meaningful work, something went wrong. Consider:
- Was the git range correct? (BASE_SHA..HEAD_SHA should cover all branch commits)
- Did the reviewer get enough context about what was implemented?
- Were all changed files included in the diff?

Re-dispatch with corrected context if the review seems too shallow.
