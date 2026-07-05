---
name: sync-projects
description: Sync shared standards, commands, and scripts to all configured projects
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Sync Shared AI Docs to Projects

You are running the shared-ai-docs sync workflow. This distributes the latest shared standards, Claude commands, scripts, and supplements from the shared-ai-docs repo to all configured target projects.

The bash script (`bin/sync-to-repos.sh`) handles mechanical file-copying and hash tracking. **You** handle the intelligent parts: safe branch management, conflict resolution, and smart-merging of locally customized files.

## Locating the Shared AI Docs Repo

The path to the shared-ai-docs repo is defined in the user's **global CLAUDE.md** (`~/.claude/CLAUDE.md`) under the "Shared AI Docs" section. Read that path from your context — it is always loaded automatically. Do NOT hardcode the path.

If you cannot find the path in your context, ask the user.

## Configuration

Target repos are defined in `bin/sync-config.json` inside the shared-ai-docs repo. Read it first to get the list of projects. Each entry has:
- `path`: absolute path to the target repo
- `content`: what to sync (`["all"]` or subset of `["docs", "commands", "scripts"]`)
- `supplements`: framework-specific additions (e.g., `["wordpress"]`)

If the user provides specific project paths as arguments, sync only those. Otherwise sync all configured repos.

$ARGUMENTS

## Workflow for Each Project

Process each project one at a time, reporting progress as you go.

### Step 0: Check if Repo is Busy

Before touching anything, determine if the repo has active work in progress. A repo is **busy** if ANY of these are true:

1. **Non-default branch**: `git branch --show-current` returns something other than main/master — indicates active feature work
2. **Uncommitted changes**: `git status --porcelain` returns output — indicates work-in-progress (unstaged changes, staged changes, or untracked files)
3. **Active processes**: Check if `claude` or `node` processes are running with their working directory inside this repo (use `pgrep` + `lsof` on macOS, skip gracefully if tools unavailable)

If the repo is busy:
- Log which signals were detected and why the repo is being skipped
- **Do NOT stash, switch branches, or attempt to work around the busy state**
- **Skip the repo entirely** — do not proceed to Step 1 or any subsequent steps
- Note the repo and reasons for the final summary report
- Move on to the next project

### Step 1: Safe Branch Checkout

1. `cd` to the project directory
2. Check the current branch with `git branch --show-current`
3. If NOT on the default branch (main/master):
   - Note which branch is currently checked out (you may need to mention this to the user)
   - Check for uncommitted changes with `git status`
   - If there are uncommitted changes, **stash them** with `git stash push -m "sync-projects auto-stash before sync"`
   - Checkout the default branch: `git checkout main` (or `master`)
4. If already on the default branch, proceed

### Step 2: Fetch and Pull Latest

1. `git fetch origin --prune`
2. `git pull`
3. **If pull fails due to merge conflicts:**
   - Read the conflicted files
   - Resolve conflicts intelligently based on the content
   - Stage resolved files and complete the merge
   - If you cannot resolve confidently, report to the user and skip this project

### Step 3: Run the Sync Script (File Copy Only)

Run the sync script for just this repo, **without** commit-push (you'll handle that after smart-merging):

```bash
bash <SHARED_AI_DOCS_PATH>/bin/sync-to-repos.sh --repo /path/to/project
```

Replace `<SHARED_AI_DOCS_PATH>` with the actual path from the global CLAUDE.md. Do NOT use `--commit-push` or `--fetch` flags — you already handled fetch in Step 2, and you will commit manually after reviewing flagged files.

Capture and review the output. Look for:
- **"new"** files — these are fine, no review needed
- **"copy"** files — updated cleanly, no review needed
- **"FLAG"** files — locally modified, need your attention (Step 4)

### Step 4: Smart-Merge Flagged Files

For each flagged file:

1. Read the **shared source version** from the shared-ai-docs repo (`shared/` directory)
2. Read the **local version** in the target project
3. Compare them and determine what changed:
   - **Shared source has new content** that the local version doesn't have → merge the new content into the local file, preserving local customizations
   - **Local version has project-specific customizations** (extra sections, modified content) → keep those customizations, but integrate any new or updated shared content around them
   - **Both changed the same section** → use your judgment to merge, preferring to keep both sets of changes where possible
4. Write the merged result to the target project
5. After merging, re-run the sync script with `--force --repo /path/to/project` to update the manifest hash for that file

**Merging principles:**
- Local customizations are valuable — never silently discard them
- Shared updates (new sections, updated guidance, fixed typos) should flow through
- If a local file has added project-specific sections, keep them even if they don't exist in the shared source
- If unsure whether a local change is intentional customization or just stale, ask the user

### Step 5: Commit and Push

1. Stage all synced and merged files: `git add docs/shared-standards/ .claude/commands/ scripts/ .shared-ai-docs-manifest.json`
2. Commit with message: `chore: sync shared-ai-docs`
3. `git push origin` (to the default branch)
4. If push fails, report to the user

### Step 6: Prune Merged Branches

1. List branches fully merged into the default branch: `git branch --merged`
2. Delete each merged branch (excluding main/master and the current branch): `git branch -d <branch>`
3. Prune stale remote tracking refs: `git remote prune origin`
4. Report what was pruned

### Step 7: Restore Previous State (if applicable)

If you stashed changes or switched away from a feature branch in Step 1:
- Do NOT switch back — the user may want to stay on main
- But DO mention: "Note: [project] was on branch `feature/xyz` with stashed changes. Run `git checkout feature/xyz && git stash pop` to resume."

## Reporting

After all projects are processed, give a summary:
- How many projects synced successfully
- Any projects skipped as **busy** (list each with the reasons: non-default branch, uncommitted changes, active processes)
- Any other projects skipped and why (directory not found, etc.)
- Any flagged files that were smart-merged (briefly describe what changed)
- Any branches pruned
- Any projects that need user attention (conflicts, push failures, stashed work)
