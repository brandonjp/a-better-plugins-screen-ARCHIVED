---
name: finish
description: Finalize branch work — update docs, verify versions, merge to main, push, prune branches
model: sonnet
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Finish — Merge to Main & Ship

You are finalizing the current branch and shipping it to main. This is the last step before the work is considered released.

$ARGUMENTS

## Step 1: Pre-merge checklist

1. Identify the current branch and confirm it is NOT already main/master
2. Check for uncommitted or unstaged changes: `git status`
   - If anything is uncommitted, review it and commit with an appropriate message
3. Verify all version references across the project are consistent and accurate:
   - Main source file header/constant
   - README.md, package.json, package-lock.json, or equivalent
   - CHANGELOG.md (should have an entry for the current version's work)
   - Any other files that declare a version number
   - If versions are out of sync, fix them now and commit
4. Verify project docs (README, CHANGELOG, TODO, etc.) reflect the current state of the codebase
   - If anything is stale or missing, update it now and commit

## Step 2: Surface deferred work

Scan for anything that was deferred, left incomplete, or needs follow-up:

- TODO/FIXME/HACK comments in changed files
- Partially implemented features
- Known issues discovered during development

Make sure each item is captured in the appropriate project doc (TODO.md, roadmap, or similar) with enough context to be actionable later. If new spec files, design docs, or plans were added, ensure they are cross-referenced from main project docs for discoverability.

## Step 3: Merge to main

**Prefer `gh pr merge` when possible** so the PR is marked as "Merged" (purple badge) for recordkeeping — not "Closed" with dangling commits. Only fall back to a local merge when `gh` isn't available or there's no PR.

### Decision tree (do this in order, one attempt each — do NOT loop on failures)

1. Is `gh` installed and authenticated? Run `gh auth status` once.
   - If command missing OR auth fails → skip straight to **Fallback: local merge**. Do NOT try to install, re-auth, or retry `gh`.
2. Is there an open, non-draft PR for the current branch? Run `gh pr view --json number,state,isDraft`.
   - Yes → use **Preferred: `gh pr merge`**
   - No / draft / closed / command errors → use **Fallback: local merge**

### Preferred: `gh pr merge`

1. Ensure the branch is pushed: `git push`
2. Compose a merge commit message (same care as a local `git merge -m`): a concise subject line summarizing the branch, plus a body listing the key changes / version bumps / linked issues.
3. Merge via GitHub with an explicit commit message:
   ```bash
   gh pr merge --merge --delete-branch \
     --subject "Merge <branch> — <one-line summary>" \
     --body "$(cat <<'EOF'
   <multi-line body: version highlights, bullet list of changes, Closes #N, etc.>
   EOF
   )"
   ```
   - Run from the feature branch so `gh` infers the PR automatically
   - `--subject` / `--body` give you the same control over the merge commit as a local `git merge -m` — use them; don't accept GitHub's default "Merge pull request #N" message when the PR covers meaningful work
   - Use `--squash` instead of `--merge` only if the project explicitly prefers squash merges (subject/body still apply)
   - `--delete-branch` deletes the remote branch as part of the merge
4. Update local main: `git checkout main && git pull`
5. If `gh pr merge` fails (required checks, branch protection, network) → report the exact error to the user and ask how to proceed. Do NOT silently retry, loop, or switch to local merge without confirmation.

### Fallback: local merge

Use this when `gh` isn't available (e.g., Claude Code web) or there's no PR:

1. Switch to main: `git checkout main`
2. Pull latest: `git pull`
3. Merge the feature branch: `git merge --no-ff <branch-name>`
4. Resolve any conflicts carefully — preserve the intent of both sides
5. Push main to remote: `git push`
6. If there was an open PR, GitHub will mark it as "Closed" (not "Merged") once the commits land — tell the user so they know why the PR badge looks that way

## Step 4: Prune stale branches

If you used **Preferred: `gh pr merge --delete-branch`**, the remote feature branch is already gone. You still need to clean up locally.

1. List branches fully merged into main: `git branch --merged`
2. Delete each merged branch locally (excluding main/master): `git branch -d <branch>`
3. If you used the **Fallback: local merge** path, also delete the remote branch: `git push origin --delete <branch>`
4. Prune stale remote tracking refs: `git remote prune origin`

**Only delete branches you are certain are fully merged.** If in doubt, skip and report to the user.

## Step 5: Final verification

1. Confirm you are on main with a clean working tree
2. Confirm the remote is up to date
3. Summarize what was merged, any doc updates made, and any branches pruned
