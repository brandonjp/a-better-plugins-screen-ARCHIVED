---
name: sync-shared-to-here
description: Pull the latest shared-ai-docs content DOWN into THIS project only (no other projects touched)
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Sync Shared AI Docs DOWN to This Project Only

Pull the latest shared standards, Claude commands, and scripts from the shared-ai-docs repo into the current project. Do not touch any other projects.

## Step 0 — Locate the shared-ai-docs repo

The path is in the user's global CLAUDE.md (`~/.claude/CLAUDE.md`) under "Shared AI Docs". Read it from your context. If not present, ask the user.

## Step 1 — Update the shared repo first

In the shared-ai-docs repo:

```bash
git -C <shared-path> fetch origin --prune
git -C <shared-path> checkout main
git -C <shared-path> pull --ff-only
```

If pull fails, report and stop.

## Step 2 — Dry-run the sync for THIS repo only

Run from the shared-ai-docs repo (the script handles busy-detection internally):

```bash
bash <shared-path>/bin/sync-to-repos.sh --dry-run --repo "$(pwd)" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
```

**Always pipe through `sed` to strip ANSI codes** — without it, parsing the output silently returns nothing.

Show the user the planned changes (new / copy / FLAG counts and filenames). If the script reports the repo as busy, show the reasons and stop.

## Step 3 — Confirm and run

Ask:

> **Proceed with these changes?** (yes / no)

If yes, run without `--dry-run`:

```bash
bash <shared-path>/bin/sync-to-repos.sh --repo "$(pwd)" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
```

## Step 4 — Smart-merge any FLAG'd files

**Model gate:** smart merges are Opus-tier work — a botched merge rewrites this project's operating instructions. If you are NOT running as Opus or a stronger tier (your system prompt states your model), do NOT merge: leave every FLAG'd file untouched (safe — it keeps its local content and re-FLAGs next sync), finish Step 5 for the files the script handled, then list the deferred FLAGs and give the user a ready-to-paste prompt (per "Prompts for New Sessions", `> **⮕ OPUS**`) to do just the merges.

For each `FLAG` file (locally modified, differs from incoming shared version):

1. Read the shared source from `<shared-path>/shared/...`
2. Read the local version
3. Merge: keep local customizations, integrate shared updates
4. Write the result
5. Re-run `bash <shared-path>/bin/sync-to-repos.sh --overwrite-file <rel-path> --repo "$(pwd)"` to refresh the manifest hash for that file (overwrites ONLY that one file; use `--overwrite-local-edits` if you deliberately want every flagged file overwritten)

If unsure whether a local change is intentional, ask the user.

## Step 5 — Commit

Stage and commit in this project:

```bash
git add docs/shared-standards/ .claude/commands/ scripts/ .shared-ai-docs-manifest.json
git commit -m "chore: sync shared-ai-docs"
```

Do not push unless the user asks.
