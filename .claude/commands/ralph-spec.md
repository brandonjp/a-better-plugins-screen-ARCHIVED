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

### ONE spec file. Always.
- Every spec MUST be a single `.md` file. Never split work across multiple files (no `plan-2a.md`, `plan-2b.md`, etc.).
- If the work is large, use more chunks within one file. Ralph handles up to ~15 chunks fine.
- If the user asks for something that seems like it needs multiple specs, put it all in one file with clear chunk boundaries.

### Never create wrapper scripts.
- `ralph-runner.sh` is the only orchestrator. Never create secondary shell scripts like `run-all.sh`, `execute-plans.sh`, `orchestrate.sh`, etc.
- All work goes in one spec file, run by one script.

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
- A chunk with more than ~8 files or ~15 steps is too large. Split it.
- A chunk with only 1-2 trivial steps is too small. Merge it with an adjacent chunk.

### The user just re-runs the same command.
- Ralph auto-resumes from where it left off. The user never needs to know which chunk failed.
- Never instruct the user to pass `--start-from`. That flag exists only as a manual override.
- The correct instruction is always: "Just run the same command again."

### Plan files and state files MUST be committed.
- Plan files (`docs/plan-*.md`) and state files (`*.ralph-state`) must be tracked in git.
- These files MUST NOT be listed in `.gitignore`. If they are, remove the ignore rule.
- Committing state files allows other developers or Claude sessions to resume from where the plan left off if Ralph is interrupted mid-cycle.
- When all chunks pass, Ralph automatically cleans up: removes the state file and archives the plan to `docs/archive/`.

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

**Testing:** [Command to verify after each chunk, e.g., `npm test`, `python -m pytest tests/ -v`, `composer test`]

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

### What NOT to Include
- Do NOT include setup/environment steps (the developer has already set up).
- Do NOT include PR creation or branch merging — Ralph handles the branch.
- Do NOT include "read the codebase" steps — the implementation prompt already handles this.
- Do NOT combine unrelated work in a single chunk.
- Do NOT include steps that invoke `/ralph-spec`, `/ralph-plan`, `claude`, or any other AI command.
- Do NOT split work across multiple spec files.
- Do NOT create wrapper scripts or orchestration scripts of any kind.

## 5. Validate the Spec

Before presenting the spec, run through ALL of these checks. Fix any issues before showing it to the human.

### Structural Checks
1. **Single file** — Is everything in ONE spec file? (If not, merge.)
2. **Chunk count** — Is 3-15 reasonable for this scope of work?
3. **No meta-planning** — Does every step describe a direct action? (No steps that invoke AI commands.)
4. **No wrapper scripts** — Does the spec avoid creating any `.sh` files for orchestration?

### Per-Chunk Checks
For each chunk, verify:
5. **Right-sized** — Could Sonnet implement this in one session? (≤~8 files, ≤~15 steps)
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

# Re-run just the review for a specific chunk
bash scripts/ralph-runner.sh docs/plan-<n>.md --review-only 2

# Start completely fresh (clears all progress)
bash scripts/ralph-runner.sh docs/plan-<n>.md --reset

# Use different models
bash scripts/ralph-runner.sh docs/plan-<n>.md --impl-model haiku --review-model sonnet

# Use a custom branch name
bash scripts/ralph-runner.sh docs/plan-<n>.md --branch feature/my-branch
```

**Post-completion:** When all chunks pass, Ralph automatically:
1. Deletes the `.ralph-state` file (no longer needed)
2. Moves the plan to `docs/archive/` (keeps `docs/` clean)

The `.ralph-state` file IS tracked in git while work is in progress — this allows
other developers or Claude sessions to resume from where the plan left off.
