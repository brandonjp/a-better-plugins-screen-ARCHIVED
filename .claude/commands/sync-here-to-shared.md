---
name: sync-here-to-shared
description: Promote recent local changes to Claude commands or shared-standards docs UP to the shared-ai-docs repo
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Sync This Project's Changes UP to Shared AI Docs

The user wants recent updates made in THIS project's `.claude/commands/` and/or `docs/shared-standards/` to be reflected in the shared-ai-docs repo, so they can later be distributed to other projects via `/sync-shared-to-all`.

## Step 0 — Locate the shared-ai-docs repo

The path is in the user's global CLAUDE.md (`~/.claude/CLAUDE.md`) under "Shared AI Docs". Read it from your context. If not present, ask the user.

## Step 1 — Identify candidate files

Compare these directories in the current project against their counterparts in `shared/` of the shared-ai-docs repo:

- `.claude/commands/*.md`  ↔  `shared/.claude/commands/*.md`
- `docs/shared-standards/*.md`  ↔  `shared/docs/shared-standards/*.md`

For each file in the local project:
- **New locally** (no match in shared) → candidate to add
- **Differs from shared** → candidate to update
- **Identical** → skip

Use the project's `.shared-ai-docs-manifest.json` (if present) to distinguish files that came from shared vs. files born locally.

If `$ARGUMENTS` names specific files or globs, restrict to those. Otherwise consider all candidates.

## Step 2 — Show the user the candidate list

Present a short table or list:

- ✏️ **Updated locally**: list each file with a one-line summary of what changed (run `diff` against shared)
- 🆕 **New locally**: list each file with a one-line description of its purpose (read the frontmatter)

For each candidate, FLAG anything that looks project-specific (hardcoded paths, project name references, framework specifics that don't generalize). Do NOT auto-scrub — just call them out so the user can decide.

Then ask:

> **Which of these should I promote to the shared repo?** (Type `all`, a list of filenames, or `none`)

Wait for the user's answer.

## Step 3 — Create a branch and copy files in shared-ai-docs

In the shared-ai-docs repo:

1. Verify it's clean: `git -C <shared-path> status --porcelain`. If dirty, ask the user how to proceed (stash, abort, or commit-then-continue).
2. Switch to main and pull: `git -C <shared-path> checkout main && git -C <shared-path> pull --ff-only`.
3. Create a branch: `git -C <shared-path> checkout -b promote/<source-project>-<YYYY-MM-DD>` (use today's date from your context).
4. Copy each selected file to its corresponding `shared/...` path. Preserve filenames.
5. `git -C <shared-path> add` the copied files and commit:

```
chore(promote): bring in updates from <source-project>

- <file1>: <one-line summary>
- <file2>: <one-line summary>
```

6. Push the branch: `git -C <shared-path> push -u origin promote/<source-project>-<YYYY-MM-DD>`.

## Step 4 — Open a PR

Use `gh pr create` from inside the shared-ai-docs repo. Title: `Promote updates from <source-project>`. Body:

```
Files promoted from <source-project> at <absolute-path>.

## Files
- <file1> — <what changed>
- <file2> — <what changed>

## ⚠️ Project-specific content to review
<list any flagged items from Step 2, or "None spotted">

## Next step
After merge, run /sync-shared-to-all from the shared-ai-docs repo to distribute.
```

Return the PR URL to the user. Copy it to the clipboard with `pbcopy`.

## Notes

- Never push directly to `main` of shared-ai-docs — always go through a PR.
- Do not modify the source project's files; this command only reads from here and writes to the shared repo.
- If anything is ambiguous, ask the user inline rather than guessing.
