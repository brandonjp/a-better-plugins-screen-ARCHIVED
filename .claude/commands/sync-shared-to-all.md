---
name: sync-shared-to-all
description: Distribute the latest shared-ai-docs content DOWN to ALL configured projects (or a fuzzy-matched subset)
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Sync Shared AI Docs DOWN to All Projects

Distribute the latest shared standards, Claude commands, scripts, and supplements from the shared-ai-docs repo to all configured target projects.

This command delegates to the canonical workflow that lives in the shared-ai-docs repo itself. From any project, the steps are:

## Step 0 — Locate the shared-ai-docs repo

The path is in the user's global CLAUDE.md (`~/.claude/CLAUDE.md`) under "Shared AI Docs". Read it from your context. If not present, ask the user.

## Step 1 — Run the canonical workflow

`cd` into the shared-ai-docs repo and follow the `/sync-all` command defined there:

```
<shared-path>/.claude/commands/sync-all.md
```

Read that file and execute its instructions. It handles:

- Reading `bin/sync-config.json`
- Optional fuzzy-matching of `$ARGUMENTS` against project names
- Phase-1 dry-run with confirmation
- Phase-2 sync with smart-merge of locally modified files
- Per-project commit and push
- Busy-repo detection and reporting

Pass `$ARGUMENTS` through unchanged so the user can target specific projects (e.g., `/sync-shared-to-all matchasights worktapes`).

## Note

This command exists in every project as a convenience entry point. The actual logic lives in `<shared-path>/.claude/commands/sync-all.md` and is the single source of truth.
