# Install Ralph — Plan Orchestrator v3.0

> **Deployment guide.** Use this in any project to install or upgrade Ralph.
> Copy the two companion files (`ralph-runner.sh` and `ralph-spec.md`) into the
> project, then follow the steps below.
>
> **Last updated:** 2026-03-20

---

## 1. Install Files

Copy the two companion files into the project:

```bash
# Create directories if needed
mkdir -p scripts .claude/commands

# Copy the script and make it executable
cp ralph-runner.sh scripts/ralph-runner.sh
chmod +x scripts/ralph-runner.sh

# Copy the spec guide
cp ralph-spec.md .claude/commands/ralph-spec.md
```

If the companion files are not local, copy them from a project that has them
(e.g. from a repo that already has Ralph installed).

---

## 2. Remove Previous Versions

Delete ALL of the following if they exist:

```bash
# Old script names
rm -f scripts/run-ralph.sh
rm -f scripts/run-plan.sh
rm -f scripts/run-script.sh
rm -f scripts/run-all.sh
rm -f scripts/run-all-plans.sh

# Old command names
rm -f .claude/commands/ralph-plan.md
rm -f .claude/commands/ralph-loop.md

# Old deploy guide (replaced by this document)
rm -f docs/archive/deploy-ralph.md
rm -f docs/deploy-ralph.md

# Stale state files from old versions
find docs/ -name "*.run-plan-state" -delete 2>/dev/null || true
```

---

## 3. Git Tracking — Plan & State Files

Ralph's plan files (`docs/plan-*.md`) and state files (`*.ralph-state`) **MUST be
committed to the repository**. This is critical for resumability — if Ralph is
interrupted mid-cycle (crash, timeout, Ctrl+C), any developer or Claude session
can pick up exactly where it left off by re-running the same command.

**Check `.gitignore`** and remove any lines that ignore these files:

```
# REMOVE these lines if present in .gitignore:
*.ralph-state
docs/plan-*.md
```

Ralph automatically cleans up when a plan finishes:
- Deletes the `.ralph-state` file (no longer needed)
- Moves the completed plan to `docs/archive/`

So these files only exist in the repo while work is actively in progress.

---

## 4. Update CLAUDE.md

Add or update the Ralph section in your project's `CLAUDE.md`:

```markdown
## Ralph Loop — Automated Plan Execution

This project uses **Ralph**, an automated orchestrator that implements chunked plans via Claude CLI.

| Resource | Path | Purpose |
|---|---|---|
| **Run a spec** | `scripts/ralph-runner.sh` | Execute a spec with implement → review → fix loop |
| **Create a spec** | `/ralph-spec` command | Claude command to generate properly structured specs |
| **Example specs** | `docs/archive/plan-*.md` | Completed specs showing the expected format |

\```bash
# Create a Ralph spec (in Claude Code)
/ralph-spec

# Preview execution
bash scripts/ralph-runner.sh docs/plan-my-feature.md --dry-run

# Execute (auto-resumes if interrupted — just re-run the same command)
bash scripts/ralph-runner.sh docs/plan-my-feature.md

# Re-run review for a specific chunk
bash scripts/ralph-runner.sh docs/plan-my-feature.md --review-only 2
\```

The Ralph loop uses Sonnet for implementation and Opus for review by default. Press Ctrl+C to abort gracefully (progress is saved). See `scripts/ralph-runner.sh --help` for all options.
```

---

## 5. Verify Installation

Run these checks to confirm everything is set up correctly:

```bash
# Script exists and is executable
ls -la scripts/ralph-runner.sh

# Command file exists
cat .claude/commands/ralph-spec.md | head -1
# Should show: # /ralph-spec — Write a Ralph Implementation Spec

# Old files are gone
ls scripts/run-ralph.sh 2>/dev/null && echo "FAIL: old script still exists" || echo "OK"
ls scripts/run-plan.sh 2>/dev/null && echo "FAIL: old script still exists" || echo "OK"
ls .claude/commands/ralph-plan.md 2>/dev/null && echo "FAIL: old command still exists" || echo "OK"

# State files are NOT gitignored
echo "test" > /tmp/test.ralph-state
# Verify *.ralph-state is not in .gitignore
grep -n "ralph-state" .gitignore && echo "FAIL: remove ralph-state from .gitignore" || echo "OK"
```

---

## What's New in v3.0

- **Renamed** from `run-ralph.sh` → `ralph-runner.sh` for consistent `ralph-*` naming
- **Timing** — shows elapsed time per chunk and total run duration
- **Ctrl+C handling** — graceful abort with progress saved; resume by re-running
- **Auto-archive** — completed plans move to `docs/archive/`, state files cleaned up
- **State files tracked in git** — enables cross-session and cross-developer resumability

Do NOT modify the contents of either installed file. Just install, clean up, and verify.
