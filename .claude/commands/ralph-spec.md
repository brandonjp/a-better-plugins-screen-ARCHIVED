---
name: ralph-spec
description: Write a structured implementation spec for the Ralph orchestrator
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# /ralph-spec — Write a Ralph Implementation Spec

You are writing a structured implementation spec for use with the **Ralph orchestrator** (`scripts/ralph-runner.sh`). Ralph automates an implement → review → fix loop using the Claude CLI, where a fast model (Sonnet) implements each chunk and a stronger model (Opus) reviews it.

**Your job is to produce a spec document. You do NOT execute the plan.**

---

## CRITICAL RULES — Read These First

These are absolute rules. Violating any of them produces a broken, unusable spec.

### STOP after writing the spec file.
- Your job ends when the spec `.md` file is written and validated.
- Do NOT execute the spec. Do NOT run `ralph-runner.sh`. Do NOT spawn subagents to implement chunks.
- Do NOT offer to "go ahead and implement this." Write the document and stop.
- The human will run the spec themselves using `ralph-runner.sh`.

### Spec file sizing — one feature per file, but SPLIT large features into numbered sub-plans.
**Why this matters (token cost):** the runner re-reads the ENTIRE plan file in every chunk's
implement AND review session (each phase prompt in `ralph-runner.sh` says "Read the plan file").
So one big file is re-ingested ~2× per chunk — a 12-chunk file ≈ **24 full re-reads**. Size files to
keep that cost down.

- **Default: one focused feature → one file**, for small/medium features (**≤ ~6 chunks**). Never
  combine *unrelated* features into one giant spec.
- **Split a LARGE single feature into multiple NUMBERED sub-plan files** once it would exceed
  **~6–8 chunks**: `plan-<feature>-1-<part>.md`, `-2-<part>.md`, `-3-<part>.md`, run **sequentially on
  one shared branch**. Each sub-plan stays small, so each session re-reads only its part. This is NOT
  the forbidden "part1/part2" fragmentation — split along **dependency boundaries** (e.g. foundation →
  components → assembly) and number files so the run order is obvious from the filenames.
- **Every sub-plan after the first MUST open with a prerequisite gate.** Its Chunk 1, Step 1 verifies
  the prior sub-plans' outputs exist (`test -f …`, grep for expected exports/tokens) and **HALTS** with
  instructions if not — so an out-of-order run can never silently redo or break earlier work. State the
  dependency explicitly at the top of the file too ("⛔ PREREQUISITE — File N must be complete first").
- **Independent features always get separate files** regardless of size.
- **Declare the branch in every plan doc** via a `**Branch:** \`feature/<feature>\`` line (all
  sub-plans of one feature declare the SAME branch). The runner reads this field and uses it, so the
  user need not pass `--branch`. **Emit ONE ready-to-copy command** listing all files in order; include
  `--branch feature/<feature>` as a belt-and-suspenders override (also covers older runner copies not
  yet synced with the `**Branch:**`-parsing fix). Example:
  `bash scripts/ralph-runner.sh plan-x-1-foo.md plan-x-2-bar.md plan-x-3-baz.md --branch feature/x`
- **Declare models in the plan doc when the defaults are wrong for the work** (runner ≥ v4.17):
  optional `**Impl-Model:** \`opus\`` and `**Review-Model:** \`<model>\`` lines next to `**Branch:**`.
  Resolution is CLI flag > plan field > default (sonnet impl / opus review), re-resolved per plan in
  multi-plan runs. Use `**Impl-Model:** \`opus\`` when implementation quality is the whole deliverable
  (e.g. prose-heavy standards docs with no tests to catch a weak draft); omit both lines for normal
  code work — the sonnet-implements/opus-reviews default is the point of Ralph.

### Never create wrapper scripts.
- `ralph-runner.sh` is the only orchestrator. Never create secondary shell scripts like `run-all.sh`, `execute-plans.sh`, `orchestrate.sh`, etc.
- A feature's work goes in its spec file(s) — one file, or numbered sub-plans for a large feature (see sizing rule above) — run by `ralph-runner.sh`, never a wrapper script.

### NO meta-planning.
- Never write a spec step that invokes `/ralph-spec`, `/ralph-plan`, `claude`, or any AI command to "generate the real plan later."
- Every step in the spec must be a direct, concrete action: create a file, edit a function, run a command.
- The spec IS the implementation guide. There is no second pass.

### NO stubs, placeholders, or deferred implementation.
- Every chunk must produce real, working, complete code.
- Never write steps like "add placeholder for future implementation", "stub out the interface", "raise NotImplementedError", or "TODO: implement later."
- If a function is referenced in a step, the step must include or describe the full implementation.
- If something can't be fully implemented yet because it depends on a later chunk, restructure the chunks so dependencies come first.

### NO forward dependencies.
- Chunk N must NEVER depend on code that will be written in Chunk N+1 or later.
- Each chunk must leave the project in a fully working, testable state.
- If you find yourself writing "this will be connected in Chunk 5" — stop. Restructure.

### Chunks must be right-sized for Sonnet.
- Each chunk should be implementable in a single Claude session (~5-20 minutes of work).
- Each chunk should touch **1-3 files**. If a task spans more files, split it into multiple chunks.
- A chunk with more than ~3 files or ~10 steps is too large. Split it.
- A chunk with only 1-2 trivial steps is too small. Merge it with an adjacent chunk.

### The user just re-runs the same command.
- Ralph auto-resumes from where it left off. The user never needs to know which chunk failed.
- Never instruct the user to pass `--start-from`. That flag exists only as a manual override.
- The correct instruction is always: "Just run the same command again."

### Plan and state files are runner-owned. Do NOT touch them in chunk steps.
- Plan files (`docs/plan-*.md`) and state files (`*.ralph-state`) must be tracked in git and MUST NOT be listed in `.gitignore`.
- **The runner commits the state file automatically** after every phase transition (`mark_chunk_done`, `save_phase`) so progress survives any interruption or destructive operation.
- **The runner archives the plan automatically** when all chunks pass — it `git mv`s the plan to `docs/archive/`, removes the state file, and commits both in one cleanup commit.
- **Chunk steps must never `git mv`, `git rm`, edit, or commit the plan file, the state file, or anything under `docs/archive/`.** These are runner-owned. The only allowed edit to the plan file is marking step checkboxes from `- [ ]` to `- [x]` for steps under the current chunk.
- **Do not write spec steps that "commit the state file" or "move the plan to archive".** The runner handles both. If you write such steps, the runner's own auto-commit will collide with them.
- **Review checkpoints must not flag plan/state/archive files as "git status clean" violations.** Only files inside the chunk's actual scope should count. The runner's auto-commits between phases mean those files may legitimately be dirty when the review runs.

---

## 0. Evaluate: Spec or Inline?

Before writing a spec, assess whether the Ralph orchestrator is actually the right tool:

**Use `ralph-runner.sh` (write a spec) when:**
- The work has 4+ logical chunks
- Multiple files across different areas of the codebase
- Work benefits from Sonnet implementing + Opus reviewing
- The human isn't currently in an Opus session (or wants to walk away)

**Just implement inline when:**
- The work is ≤3 small chunks AND you're already in an Opus session
- The overhead of writing a spec + running the orchestrator exceeds just doing it
- All chunks are trivially Sonnet-level (no Opus review needed)

If inline is clearly more efficient, tell the human: *"This is only N small tasks — it's cheaper for me to implement these directly rather than writing a spec for the orchestrator. Want me to just do it?"* Then let them decide. If they want the spec, write the spec.

---

## 1. Understand the Project

Before writing the spec, read these files:

- `CLAUDE.md` — Project conventions, architecture, key patterns
- `README.md` — Project overview
- Any existing specs in `docs/archive/plan-*.md` for format reference
- `scripts/ralph-runner.sh` — Understand how Ralph parses and executes specs

## 2. Gather Requirements

Ask the human (or use provided context) to understand:

- **What** feature, fix, or refactor is being planned
- **Which files** will be touched
- **What tests** exist or need to be created
- **What verification** steps confirm correctness (commands, assertions, imports)

## 3. Write the Spec

Create a new file at `docs/plan-<descriptive-name>.md` following this exact format:

### Spec File Structure

```markdown
# Spec Title — Clear Description of the Work

Brief 1-2 sentence description of what this spec accomplishes and why.

**Branch:** `feature/<descriptive-name>`

**Critical rule:** [State any invariant that must never be broken, e.g., "Existing tests must continue to pass"]

**Testing:** [Exact command to run tests — check CLAUDE.md's Testing section for the correct command. If tests run inside Docker, include the full Docker command here so the implementing agent doesn't have to guess.]

**Project context:** Read `CLAUDE.md` in the repo root for full project conventions.

---

## Chunk 1: Short Title (`file1.ext`, `file2.ext`)

Brief description of what this chunk accomplishes.

- [ ] Step 1: specific, precise instruction
- [ ] Step 2: specific instruction with exact code if needed
- [ ] Step 3: ...
- [ ] Run tests / verification command
- [ ] Commit: `git add -A && git commit -m "type: description"`

### ✅ Review Checkpoint — Chunk 1
- [ ] Verify condition A (with specific command to run)
- [ ] Verify condition B
- [ ] No stubs, TODOs, NotImplementedError, or placeholder code
- [ ] No changes outside the scope of this chunk
- [ ] Tests pass: `<test command>`
- [ ] Git status is clean

---

## Chunk 2: Short Title (`file3.ext`)

...same pattern...
```

## 4. Spec Writing Rules

Follow these rules strictly:

### Chunk Design
- **3-9 chunks** is ideal for most work. Up to ~15 is acceptable for large features. Fewer than 3 means the chunks are too large. More than 15 means reconsider scope.
- Each chunk should touch **1-3 files max**. When a task applies the same change to many files (e.g., narrowing exceptions in 5 modules), split it into multiple chunks of 2-3 files each. Chunks that stay within 1-3 files consistently finish in under 15 minutes; chunks touching 4+ files risk session timeouts and looping behavior.
- Each chunk should be **independently committable** — it must leave the project in a working state.
- Each chunk should take **5-20 minutes** for Sonnet to implement. If it would take longer, split it.
- List the **key files** being modified in the chunk header.
- Keep chunks **focused** — one logical unit of work per chunk.
- **Dependencies flow forward only** — Chunk 3 can use code from Chunks 1-2, never from Chunk 4+.

### Step Precision
- Steps must be **exact and unambiguous** — the implementing model follows them literally.
- When adding code, include the **exact code** or precise description of what to add.
- When modifying code, reference **exact function/class names** and describe the change.
- Include **file paths** for every file being modified.
- Never say "refactor as needed" or "improve where appropriate" — be specific.
- Never say "stub out" or "add placeholder" — include real, complete implementation.

### Review Checkpoints
- Every chunk MUST have a `### ✅ Review Checkpoint — Chunk N` section.
- Each checkpoint item must be **mechanically verifiable** — a command to run, a file to check, a pattern to grep for.
- Always include these standard checks:
  - "Tests pass: `<test command>`"
  - "Git status is clean"
  - "No changes outside scope of this chunk"
  - "No stubs, TODOs, `pass` placeholders, or `NotImplementedError` in new code"
- Include **import verification** when new functions/classes are added.
- Include **specific grep or test commands** the reviewer should run.

### Commit Messages
- Use conventional commit format: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`
- Each chunk should specify its commit message.

### Docker-Based Testing
If the project runs tests inside Docker (check CLAUDE.md), the spec's `**Testing:**` line should
note this so the implementing agent understands. Ralph's `--test-cmd` flag injects the exact
command into the agent prompt, but the spec should still reference the correct command in its
review checkpoints (e.g., the Docker command, not bare `python -m pytest`).

### What NOT to Include
- Do NOT include setup/environment steps (the developer has already set up).
- Do NOT include PR creation or branch merging — Ralph handles the branch.
- Do NOT include "read the codebase" steps — the implementation prompt already handles this.
- Do NOT combine unrelated work in a single chunk.
- Do NOT include steps that invoke `/ralph-spec`, `/ralph-plan`, `claude`, or any other AI command.
- For a LARGE single feature (>~6–8 chunks), DO split it into numbered sub-plan files on a shared branch with prerequisite gates (see the sizing rule). Do NOT cram it into one ~15-chunk file — that re-ingests the whole plan ~24×. Do NOT fragment a *small* feature, and do NOT combine *unrelated* features into one file.
- Do NOT create wrapper scripts or orchestration scripts of any kind.

## 5. Validate the Spec

Before presenting the spec, run through ALL of these checks. Fix any issues before showing it to the human.

### Structural Checks
1. **Right file sizing** — Small/medium feature → one file. LARGE feature (>~6–8 chunks) → numbered sub-plan files on a shared branch, each (after the first) opening with a prerequisite gate, with one `--branch`-bearing run command. Unrelated features → separate files. (See the sizing rule in the critical rules.)
2. **Chunk count per file** — Is each file ~3–8 chunks? If one file would run long, split the feature into numbered sub-plans rather than packing ~15 chunks into one.
3. **No meta-planning** — Does every step describe a direct action? (No steps that invoke AI commands.)
4. **No wrapper scripts** — Does the spec avoid creating any `.sh` files for orchestration?

### Per-Chunk Checks
For each chunk, verify:
5. **Right-sized** — Could Sonnet implement this in one session? (≤3 files, ≤~10 steps)
6. **Self-contained** — Does this chunk compile/run/pass tests on its own?
7. **No forward deps** — Does this chunk depend only on previous chunks, never later ones?
8. **No stubs** — Does every step produce real, complete code?
9. **Has review checkpoint** — Is there a `### ✅ Review Checkpoint` section?
10. **Mechanically verifiable** — Can every review item be checked with a command?

### Ordering Checks
11. **Dependency order** — If Chunk 5 uses a function from Chunk 3, is Chunk 3 earlier? Walk through the dependency chain.
12. **Test progression** — Do test commands succeed after each chunk, not just at the end?

### If Validation Fails
- If a chunk is too large → split it into smaller chunks
- If there are forward dependencies → reorder chunks so dependencies come first
- If there are stubs → replace them with full implementations or move the dependency earlier
- If review items aren't mechanically verifiable → add specific commands/greps

## 6. Show Usage Instructions

After the spec, provide these instructions:

```bash
# Preview what will run
bash scripts/ralph-runner.sh docs/plan-<n>.md --dry-run

# Execute the spec (or resume if interrupted — just re-run this same command)
bash scripts/ralph-runner.sh docs/plan-<n>.md

# Run multiple independent spec files sequentially
bash scripts/ralph-runner.sh docs/plan-a.md docs/plan-b.md docs/plan-c.md

# Re-run just the review for a specific chunk
bash scripts/ralph-runner.sh docs/plan-<n>.md --review-only 2

# Start completely fresh (clears all progress)
bash scripts/ralph-runner.sh docs/plan-<n>.md --reset

# Use different models
bash scripts/ralph-runner.sh docs/plan-<n>.md --impl-model haiku --review-model sonnet

# Use a custom branch name
bash scripts/ralph-runner.sh docs/plan-<n>.md --branch feature/my-branch

# Adjust per-chunk timeout (default: 45m) — kills stuck agents
bash scripts/ralph-runner.sh docs/plan-<n>.md --chunk-timeout 30m
```

**When you generated multiple spec files**, always include a ready-to-copy command with the real filenames so the user can run them all sequentially:

```bash
# Run all specs sequentially
bash scripts/ralph-runner.sh docs/plan-foo.md docs/plan-bar.md docs/plan-baz.md
```

**ALWAYS also give the queue-file version of the run command.** Every time you hand the user a ready-to-copy `ralph-runner.sh` command (single plan or multi-file), ALSO provide the same job as a machine-level queue snippet for `ralph-queue.sh` (shared-ai-docs `bin/ralph-queue.sh`), so they can paste it straight into their current queue file and batch it with other projects' loops (e.g. overnight, sharing one Claude plan-limit budget). The snippet is TWO lines — a `#` comment header identifying the project + task (same style as the new-session handoff-prompt heading; `ralph-queue.sh` skips `#` lines) followed by the job line:

```
# <repo-name> - Ralph: <specific task description>
<absolute-repo-dir> ::: <ralph command>
```

Use the repo's REAL absolute path and the real plan filenames/branch — e.g.:

```
# my-repo - Ralph: dove SVG recoloring + queryId hardening
/Users/brandonjp/path/to/my-repo ::: bash scripts/ralph-runner.sh docs/plan-foo.md docs/plan-bar.md --branch feature/foo
```

Label the two clearly ("run it directly" vs "or as a ralph-queue job"), and copy the queue snippet (both lines) to the clipboard per the clipboard rule. This applies to ANY session that hands over a ralph plan run command, not just this command's output.

**Post-completion:** When all chunks pass, Ralph automatically:
1. Deletes the `.ralph-state` file (no longer needed)
2. Moves the plan to `docs/archive/` (keeps `docs/` clean)
3. **Commits the move + deletion** as `chore(ralph): archive completed plan <name>`

**During the run:** Ralph also auto-commits the state file after every phase transition (e.g., `chore(ralph): plan-foo chunk 3 done`). This means the state file is always tracked in git and progress is durable against any subsequent destructive operation. Other developers or Claude sessions can resume from where the plan left off by re-running the same command.

Because of this, **chunk steps must never include `git add`/`git commit`/`git mv` operations on the plan file or state file** — the runner owns those files. See the "Plan and state files are runner-owned" rule above.
