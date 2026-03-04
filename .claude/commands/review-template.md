---

# Review & Plan Instructions

You are a senior developer performing a code review and planning the next development task. You are working in a **separate session** from the one that wrote this code — you have fresh eyes and no prior assumptions.

**Before starting, read the `[flags]` section at the bottom of this prompt.** Flags override default behavior for specific sections.

The Session Handoff Summary above is your primary context. Read it fully before doing anything else, then follow every section below in order.

---

> **⚠️ BRANCH MANAGEMENT — READ THIS FIRST**
>
> You are on a new branch (**B2**) that Claude Code auto-created from main. This is correct and expected.
>
> The implementation work you need to review lives on a different branch (**B1**), listed in the Session Handoff Summary above. B1 was pushed by the previous session.
>
> **Do this now:**
> 1. `git fetch origin`
> 2. `git merge origin/B1` (where B1 is the exact branch name from the summary)
> 3. Confirm the merge succeeded — B2 now contains all of B1's implementation work
> 4. All your review work (fixes, doc updates, commits) happens on B2
> 5. When you push, you push B2
>
> **Do NOT** attempt to check out, push to, or delete B1. You don't have permission to push other branches. The human will clean up B1 after merging the PR.
>
> At the end of your review report, remind the human: "After merging the PR, delete branch B1 (`[exact branch name]`) from remote."

---

## 1. Orient Yourself

- Read the Session Handoff Summary above completely
- **Complete the branch management steps above.** Confirm you merged B1 into your branch. State your branch name and the B1 branch name.
- Read the project's dev guide if one exists (path should be in the summary)
- Read NEXT.md or equivalent planning doc if one exists
- Skim the README for project context
- Run `git diff [base-branch]` to see the full diff
- Run `git log --oneline [base-branch]..HEAD` to see commits

Confirm you've done all of this before proceeding.

## 1b. Bootstrap Command Files

Check if both of these files exist in this repo:
- `.claude/commands/session-close.md`
- `.claude/commands/review-template.md`

- **If both exist:** skip this step.
- **If either is missing:** Note it in your review report under **Missing Workflow Files**. At the end of your session, alert the human: "⚠️ Missing session workflow files in `.claude/commands/`. Run the bootstrap prompt to install them." Do not attempt to generate these files from memory — the human will provide the canonical versions.

## 2. Code Review

Review every changed file against the full diff. Evaluate each of the following and report your findings honestly — if everything is fine, say so. Do not invent issues to seem thorough.

### Correctness
- Does the implementation match the stated session goals?
- Are there logic errors, off-by-one errors, race conditions, or unhandled edge cases?
- Are error paths handled correctly — do they fail gracefully or will they cascade?
- Are database queries correct (joins, conditions, null handling)?

### Architecture & Design
- Do the changes fit the project's existing patterns and conventions?
- Are there new abstractions that add complexity without sufficient value?
- Is responsibility properly separated, or are there functions/classes doing too much?
- Will this implementation cause problems at scale or create tech debt?
- Are there simpler approaches that were missed?

### Security
- Input validation — is all user input sanitized before use?
- Authentication/authorization — are new endpoints or features properly protected?
- Data exposure — do API responses or error messages leak sensitive information?
- Injection vectors — SQL, XSS, command injection, path traversal?
- Secrets management — anything hardcoded that should be in environment variables?

### Maintainability
- Is the code readable by someone encountering it for the first time?
- Are names clear and consistent with project conventions?
- Is there dead code, unnecessary complexity, or premature abstraction?
- Are new TODO comments tracked in TODO.md?
- Will future developers understand *why* decisions were made (not just *what*)?

### Performance
- N+1 queries or unnecessary database round-trips?
- Missing indexes for new query patterns?
- Unnecessary re-renders or re-computations in frontend code?
- Blocking operations that should be async?
- Large payloads or responses that should be paginated?

### Configurability
- Magic numbers that should be constants or config values?
- Environment-specific values hardcoded instead of using env vars?
- Behavior that should be configurable but is baked into logic?

### Standards Compliance
- Does the code follow the project's dev guide standards?
- Is formatting consistent with the rest of the codebase?
- Do commit messages follow project conventions?

## 3. Review Verdict

Provide a clear verdict:

- **✅ Ship it** — No issues found, or only trivial nitpicks that don't warrant changes
- **⚠️ Ship with notes** — Minor issues noted below that should be addressed soon but don't block merging. List them.
- **🔧 Needs fixes** — Issues found that should be fixed before merging. List each issue with the file, line/area, what's wrong, and what the fix should be. Then make the fixes yourself and commit them **on your current working branch** with a message like `fix: [description] (review fixes)`. Do NOT create a new branch for fixes. Re-run the relevant section of review to confirm.

If you made fixes, push your working branch to origin (unless `push: no` flag is set).

## 4. Documentation Verification

Verify the implementation session's documentation work:

- Are CHANGELOG entries accurate and complete for the work done?
- Does the README reflect the current state of the project?
- Are version numbers consistent across all files?
- Do any docs reference removed features, outdated paths, or contain contradictions?

If anything was missed or incorrect, fix it now, commit on your working branch, and note it in your report.

## 5. Final Push

- Confirm which branch you're on (B2) and that it contains B1's work plus any review fixes
- Push your branch to origin (unless `push: no` flag is set)
- Do **NOT** attempt to check out, push, or delete any other branch
- Do **NOT** create a pull request
- Do **NOT** merge any branches into main
- Do **NOT** use the `gh` CLI for anything
- The human handles all PR creation, review, merging, and branch cleanup

> **⚠️ REMINDER TO HUMAN:** After merging the PR, delete B1 from remote. The review report below lists the exact branch name.

## 6. Review Report

Output a structured report:

```
### Code Review Report

**Reviewer model:** Opus
**Date:** [today's date]
**Review branch (B2):** [your branch name]
**Implementation branch (B1):** [branch from handoff summary]
**PR target:** main ← [your branch name]
**Verdict:** [✅ Ship it | ⚠️ Ship with notes | 🔧 Needs fixes]

**Summary:**
[2-3 sentence overall assessment of the work quality]

**Issues Found:**
[Numbered list of issues with severity, file, and description — or "None"]

**Fixes Applied:**
[List of changes made during review — or "None"]

**Documentation Issues:**
[Any doc problems found and fixed — or "None"]

**Positive Notes:**
[What was done well — be specific]

**Missing Workflow Files:**
[List any missing .claude/commands/ files — or "All present"]

**🧹 After merging the PR, delete B1 from remote:**
`git push origin --delete [B1 branch name]`
```

## 7. Plan Next Task

Determine the single highest-priority **development task** to tackle next. Use these inputs:
- NEXT.md or equivalent planning doc
- ROADMAP.md if it exists
- TODO.md if it exists
- Any incomplete or deferred items from the session summary
- Issues discovered during your review
- Your own assessment of what the project needs most

The task must be **implementation work** — building, fixing, refactoring, testing. Never recommend "create a PR," "merge to main," or any git workflow step as the next task.

### Model Recommendation

Assess the upcoming task and recommend which model should execute it:

**Recommend Sonnet when:**
- The task follows existing patterns in the codebase
- Requirements are clearly defined with little ambiguity
- It's primarily adding a feature with a known shape (new endpoint, new component, etc.)
- The work is mechanical — migrations, test writing, refactoring to a known pattern
- The task scope is narrow and well-bounded

**Recommend Opus when:**
- The task requires significant architectural decisions
- Multiple valid approaches exist and the tradeoffs are non-obvious
- The task involves debugging a subtle or hard-to-reproduce issue
- New subsystems or patterns need to be designed from scratch
- The task involves complex integrations or data flows
- Requirements are ambiguous and the AI will need to make judgment calls

## 8. Generate Next Session Prompt

Generate a **complete, self-contained prompt** for the next development session. This prompt must work with zero additional context — the new session has no memory of either this review or the implementation session.

### Title Format (Critical)

The **very first line** must follow this exact format:

```
# [repo-name] - [Task Type]: [specific task description]
```

Rules:
- Must start with `# ` (single hash, space)
- Use the **actual repository/folder name** (same repo name from the handoff summary)
- Then ` - ` (space, dash, space)
- Then a **task type** — use one of: `Feature`, `Fix`, `Refactor`, `Test`, `Docs`, `Config`, `Setup`, or another short descriptive noun if none fit
- Then `: ` (colon, space)
- Then a specific description of the work to be done

Examples:
- `# matchasights-tool - Feature: implement product comparison engine with weighted scoring`
- `# dot-pics - Fix: resolve race condition in concurrent image uploads`
- `# seesee - Refactor: extract webhook handlers into dedicated service classes`
- `# commonprayer-app - Config: Umami dashboard configuration and setup script`

Never use generic descriptions:
- `# myapp - Feature: continue development`
- `# myapp - Feature: various improvements`
- `# myapp - Feature: next steps`

### Model and Session Guidance

The **second line** must be a clear, standalone model directive — nothing else:

```
> **⮕ SONNET**
```

or

```
> **⮕ OPUS**
```

This is the only thing the human reads before copy-pasting. No extra instructions, no reasoning text on this line. Put the reasoning in the task description body if needed.

### Remaining Prompt Content

After the title and model line, the prompt must include:

1. **Today's date**

2. **Task description** — what to build, why, and how it fits into the project

3. **Concrete acceptance criteria** — specific, verifiable outcomes that define "done"

4. **Key project files to read first**, by exact path:
   - Dev guide / coding standards
   - Commit conventions
   - NEXT.md or planning doc
   - Architecture docs or specs relevant to the task
   - README.md

5. **Technical context the next session needs:**
   - Key architectural decisions already made
   - Relevant file paths and module locations
   - Database schema context if applicable
   - API contracts or interfaces to implement against
   - Gotchas or constraints discovered in this or previous sessions

6. **Standard closing instructions:**
   - Read and verify NEXT.md before starting work
   - Follow all project coding standards and commit conventions found in project docs
   - Work autonomously — only ask questions on genuine blockers where project docs don't provide the answer
   - Do NOT create pull requests, merge branches, or use the `gh` CLI — the human handles all of that
   - When finished, invoke `/session-close` (edit flags at the bottom before sending if needed)

7. **Wrap the entire prompt in a code fence using at least 6 backticks** so inner code blocks don't break formatting. The entire prompt must be copyable in one clean selection.

Note: Do NOT include a flags section in the next-session prompt. Flags are edited at the point of use — on `/session-close` and on the review prompt — not pre-set in the task prompt.

---

## [flags]

Edit these before sending. Defaults are shown.

```
rebase: no
tests: no
push: yes
```
