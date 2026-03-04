# Session Close — Wrap & Summarize

You are finishing a development session. Complete every section below in order. If a section doesn't apply, explicitly state why. Do not skip sections silently.

**Before starting, read the `[flags]` section at the bottom of this prompt.** Flags override default behavior for specific sections.

**IMPORTANT: Your job is the mechanical close-out only.** You are preparing a clean handoff for a separate code review. Do not critique your own architectural decisions, do not refactor beyond fixing obvious bugs, and do not second-guess implementation choices — that's the reviewer's job.

---

## 1. Git Rebase

*(Skip if `rebase: no` — state that you skipped it)*

- Identify the default branch (`main` or `master`)
- Fetch latest and rebase your current working branch onto it
- If conflicts arise that require design decisions, stop and explain — do not resolve them with assumptions
- Confirm rebase succeeded with a clean state

## 2. Self-Check (Mechanical Only)

Review every file changed in this session (`git diff` against the base branch). Check for and fix only the following:

- **Leftover debug code** — Remove any `console.log`, `var_dump`, `print`, `dd()`, debug comments, or temporary test values
- **Commented-out code blocks** — Remove them. If the code might be needed later, it belongs in version control history, not in comments
- **Incomplete implementations** — Any function stubs, placeholder returns, or `// TODO: implement` that were supposed to be finished this session
- **Hardcoded secrets or credentials** — API keys, passwords, tokens, connection strings that should be in env vars
- **Obvious syntax or runtime errors** — Missing imports, typos in variable names, unclosed brackets

Do **not** refactor, restructure, or "improve" working code during this step. Fix only clear mistakes.

## 3. Documentation & Version Updates

*(Skip if `docs: no` — state that you skipped it)*

Update **all** project documentation to reflect this session's work:

- **CHANGELOG.md** — Add entry under the appropriate version heading using the project's existing format (or Keep a Changelog style if none exists)
- **README.md** — Update if this session changed features, setup steps, API surface, or usage
- **ROADMAP.md** — Mark completed items, update in-progress status
- **TODO.md** — Remove completed items, add any newly discovered items
- **Any other project docs** affected by this session's changes

**Version bump:**
- Determine the semver increment: **patch** (bug fixes), **minor** (new features, non-breaking), **major** (breaking changes)
- Search the entire codebase for the current version string and bump it **everywhere** it appears (package.json, plugin headers, constants, doc references, etc.)
- Verify dates are current in all docs

If any standard doc files don't exist in this project, note their absence — do not create them unless the project's dev guide says to.

## 4. Testing

*(Skip if `tests: no` — state that you skipped it)*

- Run the project's test suite if one exists and report results
- If this session added or modified **critical functionality** (auth, data integrity, APIs, core business logic, payments, migrations) and no tests cover it, write tests now
- Do not write tests for trivial getters/setters, simple UI components, or unchanged code

## 5. Commit & Push

- Stage all changes
- Write a clear commit message following project conventions (check `.claude/commands/` for a commit guide if one exists)
- **Push to origin** (unless `push: no` flag is set)
- Note the exact branch name that was pushed — the reviewer will need it

### Hard Stop — Git Workflow Boundary
- Do **NOT** create a pull request
- Do **NOT** merge any branches
- Do **NOT** use the `gh` CLI for anything
- The human handles all PR creation, review, and merging

## 6. Generate Complete Review Prompt

Your final output is a **single, complete prompt** that the human will paste into a new chat session. It contains two parts assembled together.

### Part 1: Session Handoff Summary (you generate this)

The **very first line** must follow this exact format:

```
# [repo-name] - Review: [specific feature/area worked on]
```

Rules:
- Must start with `# ` (single hash, space)
- Use the **actual repository/folder name** (e.g., `matchasights-tool`, not "MatchaSights Tool")
- Then ` - Review: ` (exactly this, with spaces and colon)
- Then a specific description of the work — not the branch name, not a generic label

Examples:
- `# matchasights-tool - Review: activity and operations logging`
- `# dot-pics - Review: image upload pipeline and S3 integration`
- `# seesee - Review: Stripe webhook receiver endpoint`
- `# commonprayer-app - Review: Umami dashboard configuration and setup script (Phase 2C)`

The **second line** must be a clear, standalone model directive — nothing else:

```
> **⮕ OPUS**
```

This is the only thing the human reads before copy-pasting. No extra instructions, no explanations.

After the title and model instruction, include:

```
## Session Handoff Summary

**Date:** [today's date]
**Branch:** [exact branch name as pushed to origin]
**Base branch:** [main or master]
**Version:** [previous version] → [new version]

### Session Goals
[Restate the original task/goals that started this session — copy from the initial prompt if possible]

### What Was Built / Changed
[Concise but thorough description of what was implemented. Include key decisions made and why]

### Files Changed
[List every file modified with a one-line reason]
- `path/to/file.ext` — [reason]

### Documentation Updated
- [List each doc and what changed, or note which standard docs don't exist in this project]

### Tests
- [Tests added, tests run, results — or "No test suite exists" / "N/A"]

### Incomplete or Deferred Items
- [Anything from the original goals that wasn't finished, and why]
- [New issues discovered during implementation]
- [Known limitations of what was built]

### Key Context for Reviewer
[Anything the reviewer should know to evaluate the work — non-obvious design decisions, tradeoffs made, areas you're least confident about, dependencies between changed files]

### Relevant Project Files
[Paths to files the reviewer should read for context]
- Dev guide: [path or "none"]
- Commit guide: [path or "none"]
- NEXT.md: [path or "none"]
- Architecture docs: [paths or "none"]

### Diff Stats
[Output of `git diff --stat` against base branch]
```

### Part 2: Review & Plan Instructions (copy verbatim from file)

Read the file `.claude/commands/review-template.md` and append its **entire contents verbatim** after the Session Handoff Summary. Do not modify, summarize, or reinterpret any of it.

If `.claude/commands/review-template.md` does not exist, alert the human: "⚠️ Missing `.claude/commands/review-template.md` — the review instructions could not be appended. Run the bootstrap to install it."

### Output Format

Wrap the **entire output** (Part 1 + Part 2 combined) in a single code fence using **at least 6 backticks**. The human must be able to copy the whole thing in one selection and paste it directly into a new Opus chat session.

---

## [flags]

Edit these before sending. Defaults are shown.

```
rebase: yes
tests: yes
docs: yes
push: yes
```
