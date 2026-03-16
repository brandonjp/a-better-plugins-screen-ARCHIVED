#!/usr/bin/env bash
# =============================================================================
# Ralph — Plan Orchestrator (v2.0)
# =============================================================================
#
# Generic implement → review → fix loop for any chunked plan document.
# Parses chunk headers from the plan file automatically.
# Auto-resumes from where it left off — just re-run the same command.
#
# Expected plan format:
#   ## Chunk 1: Title Here (optional details)
#   - [ ] Step one
#   - [ ] Step two
#   ### ✅ Review Checkpoint — Chunk 1
#   - [ ] Verify step one
#
# Usage:
#   bash scripts/run-ralph.sh <plan-file>
#   bash scripts/run-ralph.sh <plan-file> --dry-run
#   bash scripts/run-ralph.sh <plan-file> --review-only 2
#   bash scripts/run-ralph.sh <plan-file> --branch feature/my-branch
#   bash scripts/run-ralph.sh <plan-file> --impl-model haiku --review-model sonnet
#   bash scripts/run-ralph.sh <plan-file> --reset
#
# Resume: Just re-run the exact same command. Ralph tracks progress
#         automatically and picks up where it left off.
#
# =============================================================================
set -euo pipefail
# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
log_info()    { echo -e "${BLUE}▸${RESET} $*"; }
log_success() { echo -e "${GREEN}✔${RESET} $*"; }
log_warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
log_error()   { echo -e "${RED}✘${RESET} $*"; }
log_step()    { echo -e "\n${BOLD}${MAGENTA}━━━ $* ━━━${RESET}\n"; }
# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
IMPL_MODEL="sonnet"
REVIEW_MODEL="opus"
MAX_FIX_RETRIES=2
REVIEW_ONLY=0
DRY_RUN=false
FEATURE_BRANCH=""
DO_RESET=false
START_FROM=0
# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --start-from)
            START_FROM="$2"
            shift 2
            ;;
        --review-only)
            REVIEW_ONLY="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --branch)
            FEATURE_BRANCH="$2"
            shift 2
            ;;
        --impl-model)
            IMPL_MODEL="$2"
            shift 2
            ;;
        --review-model)
            REVIEW_MODEL="$2"
            shift 2
            ;;
        --max-retries)
            MAX_FIX_RETRIES="$2"
            shift 2
            ;;
        --reset)
            DO_RESET=true
            shift
            ;;
        -h|--help)
            cat <<'HELPEOF'
Usage: run-ralph.sh <plan-file> [OPTIONS]
Arguments:
  <plan-file>           Path to a markdown plan with "## Chunk N: Title" headers
Options:
  --branch NAME         Feature branch name (default: derived from plan filename)
  --start-from N        Force start at chunk N (overrides saved progress)
  --review-only N       Re-run just the review for chunk N
  --impl-model MODEL    Model for implementation (default: sonnet)
  --review-model MODEL  Model for review (default: opus)
  --max-retries N       Max fix attempts per chunk (default: 2)
  --dry-run             Show what would execute without running
  --reset               Clear saved progress and start from the beginning
  -h, --help            Show this help
Resume:
  Ralph auto-saves progress after each chunk. To resume after an
  interruption, just re-run the exact same command — it picks up
  where it left off automatically. No need to specify --start-from.
Plan file format:
  The plan must use "## Chunk N: Title" headers for each chunk, and
  "### ✅ Review Checkpoint — Chunk N" headers for review checklists.
  Steps should use "- [ ]" checkboxes.
HELPEOF
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1 (use -h for help)"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done
# Plan file is the first positional argument
if [[ ${#POSITIONAL_ARGS[@]} -lt 1 ]]; then
    log_error "Missing required argument: <plan-file>"
    echo "Usage: $0 <plan-file> [OPTIONS]"
    echo "Run '$0 --help' for details."
    exit 1
fi
PLAN_FILE="${POSITIONAL_ARGS[0]}"
# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
if [[ ! "$PLAN_FILE" = /* ]]; then
    PLAN_FILE="$(pwd)/$PLAN_FILE"
fi
if [[ ! -f "$PLAN_FILE" ]]; then
    log_error "Plan file not found: $PLAN_FILE"
    exit 1
fi
# Detect repo root from git
REPO_DIR=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$REPO_DIR" ]]; then
    log_error "Not inside a git repository. Run this from within your project."
    exit 1
fi
PROJECT_NAME=$(basename "$REPO_DIR")
# State file lives next to the plan file
STATE_FILE="${PLAN_FILE}.ralph-state"
# ---------------------------------------------------------------------------
# Parse chunks from plan file
# ---------------------------------------------------------------------------
declare -a CHUNK_NUMS=()
declare -A CHUNK_TITLES=()
while IFS= read -r line; do
    if [[ "$line" =~ ^##\ Chunk\ ([0-9]+):\ (.+)$ ]]; then
        num="${BASH_REMATCH[1]}"
        title="${BASH_REMATCH[2]}"
        title="${title%% \(*}"
        CHUNK_NUMS+=("$num")
        CHUNK_TITLES[$num]="$title"
    fi
done < "$PLAN_FILE"
TOTAL_CHUNKS=${#CHUNK_NUMS[@]}
if [[ "$TOTAL_CHUNKS" -eq 0 ]]; then
    log_error "No chunks found in plan file. Expected headers like: ## Chunk 1: Title"
    exit 1
fi
# ---------------------------------------------------------------------------
# Derive feature branch from plan filename if not specified
# ---------------------------------------------------------------------------
if [[ -z "$FEATURE_BRANCH" ]]; then
    plan_basename=$(basename "$PLAN_FILE" .md)
    plan_basename="${plan_basename#plan-}"
    FEATURE_BRANCH="feature/${plan_basename}"
fi
# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
chunk_title() {
    local n="$1"
    echo "${CHUNK_TITLES[$n]:-Chunk $n}"
}
# ---------------------------------------------------------------------------
# Safety checks
# ---------------------------------------------------------------------------
if ! command -v claude &>/dev/null; then
    log_error "claude CLI not found. Install it first."
    exit 1
fi
# ---------------------------------------------------------------------------
# State management — tracks per-chunk completion
# ---------------------------------------------------------------------------
# State file format: one line per completed/skipped chunk
#   DONE:<chunk_num>
#   SKIPPED:<chunk_num>
#   PHASE:<chunk_num>:<phase>   (current in-progress chunk)
reset_state() {
    rm -f "$STATE_FILE"
    log_info "Progress reset. Will start from Chunk ${CHUNK_NUMS[0]}."
}
mark_chunk_done() {
    local chunk_num="$1"
    if [[ -f "$STATE_FILE" ]]; then
        grep -v "^PHASE:${chunk_num}:" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
    echo "DONE:${chunk_num}" >> "$STATE_FILE"
}
mark_chunk_skipped() {
    local chunk_num="$1"
    if [[ -f "$STATE_FILE" ]]; then
        grep -v "^PHASE:${chunk_num}:" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
    echo "SKIPPED:${chunk_num}" >> "$STATE_FILE"
}
save_phase() {
    local chunk_num="$1"
    local phase="$2"
    if [[ -f "$STATE_FILE" ]]; then
        grep -v "^PHASE:" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
    echo "PHASE:${chunk_num}:${phase}" >> "$STATE_FILE"
}
is_chunk_done() {
    local chunk_num="$1"
    [[ -f "$STATE_FILE" ]] && grep -q "^DONE:${chunk_num}$" "$STATE_FILE"
}
is_chunk_skipped() {
    local chunk_num="$1"
    [[ -f "$STATE_FILE" ]] && grep -q "^SKIPPED:${chunk_num}$" "$STATE_FILE"
}
get_completed_count() {
    if [[ -f "$STATE_FILE" ]]; then
        grep -c "^DONE:" "$STATE_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}
find_next_chunk() {
    for num in "${CHUNK_NUMS[@]}"; do
        if ! is_chunk_done "$num" && ! is_chunk_skipped "$num"; then
            echo "$num"
            return
        fi
    done
    echo ""
}
# ---------------------------------------------------------------------------
# Handle --reset
# ---------------------------------------------------------------------------
if $DO_RESET; then
    reset_state
fi
# ---------------------------------------------------------------------------
# User intervention
# ---------------------------------------------------------------------------
prompt_action() {
    local context="$1"
    echo -e "${YELLOW}${BOLD}${context}${RESET}"
    echo -e "  ${BOLD}r${RESET})etry  ${BOLD}s${RESET})kip  ${BOLD}q${RESET})uit"
    while true; do
        read -rp "Choice [r/s/q]: " choice
        case "$choice" in
            r|R) echo "retry"; return ;;
            s|S) echo "skip";  return ;;
            q|Q) echo "quit";  return ;;
        esac
    done
}
# ---------------------------------------------------------------------------
# Claude CLI wrapper
# ---------------------------------------------------------------------------
run_claude() {
    local model="$1"
    local prompt="$2"
    local output_file
    output_file=$(mktemp)
    log_info "Running claude --model ${model}..."
    set +e
    claude --model "$model" -p --dangerously-skip-permissions "$prompt" 2>&1 | tee "$output_file"
    local exit_code=${PIPESTATUS[0]}
    set -e
    LAST_OUTPUT_FILE="$output_file"
    return "$exit_code"
}
# ---------------------------------------------------------------------------
# Implementation pass
# ---------------------------------------------------------------------------
run_implement() {
    local chunk_num="$1"
    local title
    title=$(chunk_title "$chunk_num")
    log_step "IMPLEMENT Chunk ${chunk_num}: ${title}"
    save_phase "$chunk_num" "implement"
    local prompt
    prompt=$(cat <<PROMPT_EOF
You are implementing a feature for the ${PROJECT_NAME} project. Work in the repo at: ${REPO_DIR}
IMPORTANT RULES:
- Read the plan file carefully and execute ONLY Chunk ${chunk_num} tasks
- Follow each step EXACTLY as written — the plan contains precise instructions
- Mark checkboxes from "- [ ]" to "- [x]" in the plan file as you complete each step
- Do NOT modify code outside the scope of Chunk ${chunk_num}
- Do NOT refactor, add comments, or make improvements beyond what's specified
- Do NOT invoke any slash commands, create new plan files, or spawn subagents
- Do NOT create wrapper scripts or additional shell scripts
- Create commits as specified in the plan (one commit per chunk)
- Before committing: run quality checks, verify imports work, run tests
PLAN FILE: ${PLAN_FILE}
Read the plan file now. Find "## Chunk ${chunk_num}:" and execute every step listed under it.
Stop when you reach the "### ✅ Review Checkpoint — Chunk ${chunk_num}" section.
BEFORE COMMITTING — Mandatory verification:
1. Grep all new imports to confirm the target symbols exist
2. Run any relevant import checks to verify no import errors
3. Run the project's test suite to verify no test regressions
4. Only then create the commit
Make sure you are on the feature branch: ${FEATURE_BRANCH}
If it doesn't exist yet, create it from main: git checkout -b ${FEATURE_BRANCH}
PROMPT_EOF
    )
    run_claude "$IMPL_MODEL" "$prompt"
}
# ---------------------------------------------------------------------------
# Review pass
# ---------------------------------------------------------------------------
run_review() {
    local chunk_num="$1"
    local title
    title=$(chunk_title "$chunk_num")
    log_step "REVIEW Chunk ${chunk_num}: ${title}"
    save_phase "$chunk_num" "review"
    local prompt
    prompt=$(cat <<PROMPT_EOF
You are reviewing an implementation for the ${PROJECT_NAME} project at: ${REPO_DIR}
Your job is to verify that Chunk ${chunk_num} was implemented correctly.
PLAN FILE: ${PLAN_FILE}
Read the plan file. Find "### ✅ Review Checkpoint — Chunk ${chunk_num}" and verify EVERY checklist item:
- For each item, actually run the command or check the file
- Check that all step checkboxes under "## Chunk ${chunk_num}:" are marked "- [x]"
- Run mechanical verification: cross-reference all new imports, confirm targets exist, run tests
ADDITIONAL CHECKS:
- Verify no unintended changes outside Chunk ${chunk_num} scope
- Run the project's test suite (all tests must pass)
- Run: git diff --stat to see what files were changed
- If Chunk ${chunk_num} adds new functions, verify they are importable
- Verify no code is stubbed, placeholder, or incomplete (e.g., "pass", "TODO", "NotImplementedError")
At the end of your output, write EXACTLY one of these lines:
  REVIEW PASSED — all items verified
  REVIEW FAILED — <brief summary of what failed>
A single failure means the overall result is REVIEW FAILED.
PROMPT_EOF
    )
    local output_file
    output_file=$(mktemp)
    set +e
    claude --model "$REVIEW_MODEL" -p --dangerously-skip-permissions "$prompt" 2>&1 | tee "$output_file"
    local exit_code=${PIPESTATUS[0]}
    set -e
    if grep -qi "REVIEW PASSED" "$output_file"; then
        rm -f "$output_file"
        log_success "Review PASSED for Chunk ${chunk_num}"
        return 0
    elif grep -qi "REVIEW FAILED" "$output_file"; then
        rm -f "$output_file"
        log_error "Review FAILED for Chunk ${chunk_num}"
        return 1
    else
        rm -f "$output_file"
        log_warn "Review output unclear (no PASSED/FAILED keyword). Treating as FAILED."
        return 1
    fi
}
# ---------------------------------------------------------------------------
# Fix pass (after review failure)
# ---------------------------------------------------------------------------
run_fix() {
    local chunk_num="$1"
    local attempt="$2"
    log_step "FIX Chunk ${chunk_num} (attempt ${attempt})"
    save_phase "$chunk_num" "fix-${attempt}"
    local prompt
    prompt=$(cat <<PROMPT_EOF
You are fixing review failures for the ${PROJECT_NAME} project at: ${REPO_DIR}
The review for Chunk ${chunk_num} FAILED. Your job:
1. Read the plan file at: ${PLAN_FILE}
2. Find "### ✅ Review Checkpoint — Chunk ${chunk_num}"
3. Run EACH check from the checkpoint to identify what's failing
4. Fix each failing item — implement real, complete code (no stubs, no TODOs)
5. Run the project's test suite to verify all tests pass
6. Commit with message: "fix: address review failures for chunk ${chunk_num}"
Focus ONLY on making the review pass. Do NOT refactor, add features, or make improvements.
Do NOT modify code outside Chunk ${chunk_num} scope.
Do NOT invoke any slash commands, create new plan files, or spawn subagents.
Do NOT create wrapper scripts or additional shell scripts.
Make sure you are on branch: ${FEATURE_BRANCH}
PROMPT_EOF
    )
    run_claude "$IMPL_MODEL" "$prompt"
}
# ---------------------------------------------------------------------------
# Process one chunk: implement → review → (fix + re-review if needed)
# ---------------------------------------------------------------------------
process_chunk() {
    local chunk_num="$1"
    local title
    title=$(chunk_title "$chunk_num")
    log_step "Processing Chunk ${chunk_num}/${TOTAL_CHUNKS}: ${title}"
    # Implementation
    run_implement "$chunk_num"
    # Review
    if run_review "$chunk_num"; then
        mark_chunk_done "$chunk_num"
        log_success "Chunk ${chunk_num} complete!"
        return 0
    fi
    # Fix + re-review loop
    local attempt=1
    while (( attempt <= MAX_FIX_RETRIES )); do
        log_warn "Review failed. Running fix attempt ${attempt}/${MAX_FIX_RETRIES}..."
        run_fix "$chunk_num" "$attempt"
        if run_review "$chunk_num"; then
            mark_chunk_done "$chunk_num"
            log_success "Chunk ${chunk_num} complete after ${attempt} fix(es)!"
            return 0
        fi
        (( attempt++ ))
    done
    # Max retries exhausted
    log_error "Chunk ${chunk_num} failed after ${MAX_FIX_RETRIES} fix attempts."
    local action
    action=$(prompt_action "Chunk ${chunk_num} review still failing. What do you want to do?")
    case "$action" in
        retry)
            process_chunk "$chunk_num"
            ;;
        skip)
            log_warn "Skipping Chunk ${chunk_num}. Manual intervention needed later."
            mark_chunk_skipped "$chunk_num"
            ;;
        quit)
            log_info "Exiting. Just re-run the same command to resume."
            exit 0
            ;;
    esac
}
# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
cd "$REPO_DIR"
# Extract plan title from first H1 header, fallback to filename
PLAN_TITLE=$(grep -m1 '^# ' "$PLAN_FILE" | sed 's/^# //' || basename "$PLAN_FILE" .md)
echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║  Ralph Orchestrator v2.0                                 ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}\n"
log_info "Plan: ${PLAN_TITLE}"
log_info "File: ${PLAN_FILE}"
log_info "Repo: ${REPO_DIR}"
log_info "Branch: ${FEATURE_BRANCH}"
log_info "Models: impl=${IMPL_MODEL}, review=${REVIEW_MODEL}"
log_info "Chunks: ${TOTAL_CHUNKS}"
# Show chunk status
completed=$(get_completed_count)
echo ""
for num in "${CHUNK_NUMS[@]}"; do
    if is_chunk_done "$num"; then
        echo -e "  ${GREEN}✔${RESET} ${DIM}Chunk ${num}:${RESET} ${DIM}${CHUNK_TITLES[$num]}${RESET} ${GREEN}(done)${RESET}"
    elif is_chunk_skipped "$num"; then
        echo -e "  ${YELLOW}⊘${RESET} ${DIM}Chunk ${num}:${RESET} ${DIM}${CHUNK_TITLES[$num]}${RESET} ${YELLOW}(skipped)${RESET}"
    else
        echo -e "  ${BLUE}○${RESET} Chunk ${num}: ${CHUNK_TITLES[$num]}"
    fi
done
echo ""
if [[ "$completed" -gt 0 ]]; then
    log_info "Progress: ${completed}/${TOTAL_CHUNKS} chunks completed"
fi
# Review-only mode
if [[ "$REVIEW_ONLY" -gt 0 ]]; then
    log_info "Review-only mode for Chunk ${REVIEW_ONLY}"
    if run_review "$REVIEW_ONLY"; then
        log_success "Review passed!"
    else
        log_error "Review failed."
        exit 1
    fi
    exit 0
fi
# Determine starting chunk
if [[ "$START_FROM" -gt 0 ]]; then
    start="$START_FROM"
    log_info "Starting from Chunk ${start} (--start-from override)"
else
    start=$(find_next_chunk)
    if [[ -z "$start" ]]; then
        log_success "All chunks are already complete! Nothing to do."
        echo -e "\n${BOLD}If you want to re-run:${RESET}"
        echo "  bash $0 ${PLAN_FILE} --reset"
        exit 0
    fi
    if [[ "$completed" -gt 0 ]]; then
        log_info "Auto-resuming at Chunk ${start}"
    fi
fi
# Dry run
if $DRY_RUN; then
    log_info "DRY RUN — would process these chunks:"
    for num in "${CHUNK_NUMS[@]}"; do
        if [[ "$num" -ge "$start" ]] && ! is_chunk_done "$num" && ! is_chunk_skipped "$num"; then
            echo "  Chunk ${num}: $(chunk_title "$num")"
        fi
    done
    exit 0
fi
# Ensure feature branch exists
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "$FEATURE_BRANCH" ]]; then
    if git show-ref --verify --quiet "refs/heads/${FEATURE_BRANCH}"; then
        log_info "Switching to existing branch: ${FEATURE_BRANCH}"
        git checkout "$FEATURE_BRANCH"
    else
        log_info "Creating feature branch: ${FEATURE_BRANCH}"
        git checkout -b "$FEATURE_BRANCH"
    fi
fi
# Process chunks
for num in "${CHUNK_NUMS[@]}"; do
    if [[ "$num" -ge "$start" ]] && ! is_chunk_done "$num" && ! is_chunk_skipped "$num"; then
        process_chunk "$num"
        echo ""
    fi
done
# Summary
echo ""
log_success "Plan execution complete!"
echo ""
skipped_count=0
for num in "${CHUNK_NUMS[@]}"; do
    if is_chunk_skipped "$num"; then
        (( skipped_count++ ))
    fi
done
if [[ "$skipped_count" -gt 0 ]]; then
    log_warn "${skipped_count} chunk(s) were skipped and need manual attention:"
    for num in "${CHUNK_NUMS[@]}"; do
        if is_chunk_skipped "$num"; then
            echo "  - Chunk ${num}: $(chunk_title "$num")"
        fi
    done
    echo ""
fi
echo -e "${BOLD}Next steps:${RESET}"
echo "  1. Review the branch: git log --oneline main..HEAD"
echo "  2. Run a manual test"
echo "  3. Create PR: gh pr create"
echo ""
