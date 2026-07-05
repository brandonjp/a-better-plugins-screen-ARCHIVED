---
name: check-shared-docs
description: Report whether this project's synced shared-ai-docs files are up to date (read-only — changes nothing)
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Check for Shared Docs Updates (Read-Only)

Report whether this project's copies of the shared standards, Claude commands, and scripts are current with the shared-ai-docs source repo. **This command changes nothing in this project** — it only reports. To actually pull updates, use `/sync-shared-to-here`.

Trigger phrases (any wording of these means run this command): "check for shared docs updates", "are the shared docs current?", "before you begin, check if any shared-ai-docs need updates", "is this project synced?".

## Step 0 — Locate the shared-ai-docs repo

The path is in the user's global CLAUDE.md (`~/.claude/CLAUDE.md`) under "Shared AI Docs". Read it from your context. If not present, ask the user.

If this project has no `.shared-ai-docs-manifest.json` at its root, it has never been synced — report that and stop (suggest `/sync-add-this-project` from the shared-ai-docs repo if the user wants it registered).

## Step 1 — Freshen the source repo (touches only shared-ai-docs, never this project)

```bash
git -C <shared-path> fetch origin --prune && git -C <shared-path> pull --ff-only 2>&1 | tail -1
```

If the pull fails (e.g. the shared repo is mid-work on a branch), note it and continue with whatever state is on disk — a stale source check is still better than none, but say so in the report.

## Step 2 — Dry-run the sync for THIS repo only

```bash
bash <shared-path>/bin/sync-to-repos.sh --dry-run --repo "$(pwd)" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
```

**Always pipe through `sed` to strip ANSI codes** — without it, parsing the output silently returns nothing.

## Step 3 — Report (and stop)

Summarize in a few lines:

- **Up to date** — say so, include the manifest's `synced_at` date, done.
- **Updates available** — list the files the dry run would copy (new or changed upstream, unmodified here — safe to pull).
- **FLAG'd files** — locally customized files that also changed upstream; these need a smart merge, not an overwrite. Name them explicitly.

End with: run `/sync-shared-to-here` (or just say "update them") to apply. Do NOT apply anything in this command — even if the user seems likely to want it — because "check" was the entire request. If the user then confirms, switch to the `/sync-shared-to-here` workflow.
