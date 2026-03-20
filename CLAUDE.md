# Project Guide

## Ralph Loop — Automated Plan Execution

This project uses **Ralph**, an automated orchestrator that implements chunked plans via Claude CLI.

| Resource | Path | Purpose |
|---|---|---|
| **Run a spec** | `scripts/ralph-runner.sh` | Execute a spec with implement → review → fix loop |
| **Create a spec** | `/ralph-spec` command | Claude command to generate properly structured specs |
| **Example specs** | `docs/archive/plan-*.md` | Completed specs showing the expected format |

```bash
# Create a Ralph spec (in Claude Code)
/ralph-spec

# Preview execution
bash scripts/ralph-runner.sh docs/plan-my-feature.md --dry-run

# Execute (auto-resumes if interrupted — just re-run the same command)
bash scripts/ralph-runner.sh docs/plan-my-feature.md

# Re-run review for a specific chunk
bash scripts/ralph-runner.sh docs/plan-my-feature.md --review-only 2
```

The Ralph loop uses Sonnet for implementation and Opus for review by default. Press Ctrl+C to abort gracefully (progress is saved). See `scripts/ralph-runner.sh --help` for all options.
