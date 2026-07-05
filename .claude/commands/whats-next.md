---
name: whats-next
description: Review what's planned, pick a task, then generate a prompt or execute it here
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# What's Next — Review Priorities & Pick a Task

You are helping the user review what's planned for this project and decide what to work on next.

**Assume all open PRs and branches have been merged** unless the human says otherwise.

$ARGUMENTS

---

## Step 1: Research Current State

Read these files to understand what's been done and what's planned:

- `NEXT.md` — Current priority and recently completed work
- `CLAUDE.md` — Project conventions, architecture, key files
- `TODO.md` — Outstanding tasks and known issues
- `docs/ROADMAP.md` — Overall project roadmap and phase status
- `CHANGELOG.md` — Recent version history
- Any plan or spec documents referenced in the above

Also check:
- `git log --oneline -15` — Recent commits to understand what just shipped
- `git branch` — Any open feature branches that suggest in-progress work

Not all of these files will exist in every project. Work with whatever is available.

## Step 2: Present the Overview

Organize what you found into a clear summary:

### Recently Completed
What shipped recently (from git log, CHANGELOG, NEXT.md). Keep it brief — just enough context so the user knows where things stand.

### Ready to Work On
Tasks that are clearly defined and ready to start. Number each one. Include:
- A short description of the task
- Where it came from (TODO, roadmap, NEXT, etc.)
- Your assessment of scope (small fix, medium feature, large effort)
- Recommended model (Sonnet for well-defined/mechanical work, Opus for architectural/ambiguous work)

### Needs Attention
Anything that isn't a clear task but should be on the user's radar:
- Deferred items or technical debt
- Open questions that need human decisions
- Dependencies or blockers

### Then STOP and wait for the user.

Do NOT auto-pick a task. Do NOT generate a prompt yet. Ask the user which task they'd like to tackle, or if they want to describe something different.

## Step 3: Act on the User's Choice

The user will respond in one of these ways:

### "Generate a prompt for [task]"
The user wants a self-contained prompt to paste into a different session. Generate it following the format below, wrapped in a code fence using at least 6 backticks so it's easy to copy.

### "Do [task] here" / "Let's do [task]"
The user wants to execute the work in this session. Read all relevant project files (CLAUDE.md, dev guides, architecture docs) to load context, then begin implementation directly. Follow project coding standards and conventions.

### Something else
The user may refine, combine, or describe a completely different task. Adapt accordingly and ask whether they want a prompt generated or want to work on it here.

---

## Prompt Generation Format

When generating a prompt for another session:

### Title (first line)

```
# [repo-name] - [Task Type]: [specific task description]
```

- Use the actual repository/folder name
- Task type: `Feature`, `Fix`, `Refactor`, `Test`, `Docs`, `Config`, `Setup`, or another short noun
- Be specific — never use generic descriptions like "continue development"

Examples:
- `# booklink-fyi - Feature: add book cover image caching layer`
- `# booklink-fyi - Fix: resolve OpenLibrary API rate limit handling`

### Model directive (second line)

```
> **⮕ SONNET**
```
or
```
> **⮕ OPUS**
```

### Remaining prompt content

1. **Today's date**

2. **Task description** — what to build, why, and how it fits into the project

3. **Concrete acceptance criteria** — specific, verifiable outcomes that define "done"

4. **Key project files to read first**, by exact path:
   - `CLAUDE.md` — Project conventions and architecture
   - `NEXT.md` — Current priority (confirm alignment)
   - `.claude/commands/` — Available commands and dev standards
   - `docs/ROADMAP.md` — Phase context
   - Any specs or plan documents relevant to the task

5. **Technical context the next session needs:**
   - Key architectural decisions already made
   - Relevant file paths and module locations
   - Patterns and conventions in use
   - API contracts or interfaces to implement against
   - Gotchas or constraints discovered in previous sessions

6. **Standard closing instructions:**
   - Read `CLAUDE.md` and `NEXT.md` first and confirm alignment with the task
   - Follow all project coding standards and commit conventions
   - Work autonomously — only ask questions on genuine blockers where project docs don't provide the answer
   - Do NOT create pull requests, merge branches, or use the `gh` CLI — the human handles all of that
   - When finished, invoke `/session-close` (edit flags at the bottom before sending if needed)

### Output format

Wrap the entire prompt in a code fence using at least 6 backticks. The entire prompt must be copyable in one clean selection.

Do NOT include a flags section in the generated prompt. Flags are edited at the point of use on `/session-close`, not pre-set in the task prompt.
