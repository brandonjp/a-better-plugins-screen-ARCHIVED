#!/usr/bin/env bash
# =============================================================================
# Ralph — Plan Orchestrator (v4.17)
# =============================================================================
#
# Generic implement → review → fix loop for any chunked plan document.
# Parses chunk headers from the plan file automatically.
# Supports multiple plan files — processes sequentially on a shared branch.
# Auto-resumes from where it left off — just re-run the same command.
#
# Expected plan format (accepts "Chunk" or "Task"):
#   ## Chunk 1: Title Here (optional details)
#   ## Task 1: Title Here (also works)
#   - [ ] Step one
#   - [ ] Step two
#   ### ✅ Review Checkpoint — Chunk 1
#   - [ ] Verify step one
#
# Usage:
#   bash scripts/ralph-runner.sh <plan-file> [<plan-file2> ...]
#   bash scripts/ralph-runner.sh docs/plan-a.md docs/plan-b.md docs/plan-c.md
#   bash scripts/ralph-runner.sh <plan-file> --dry-run
#   bash scripts/ralph-runner.sh <plan-file> --review-only 2
#   bash scripts/ralph-runner.sh <plan-file> --branch feature/my-branch
#   bash scripts/ralph-runner.sh <plan-file> --impl-model haiku --review-model sonnet
#   bash scripts/ralph-runner.sh <plan-file> --reset
#
# Resume: Just re-run the exact same command. Ralph tracks progress
#         automatically and picks up where it left off.
#
# Output: every log line is prefixed with a progress tag — [P2/3 C5/6],
#         [P1/1 C5/6] on single-plan runs — so mid-chunk output is always
#         attributable. ralph-queue.sh exports RALPH_TAG_SCOPE ("J2/5 repo")
#         to extend the tag with queue-job context.
#
# =============================================================================

set -euo pipefail

# Bash 4+ required (associative arrays: `declare -A CHUNK_TITLES`). Stock
# macOS ships bash 3.2, where `declare -A` fails obscurely mid-run.
if (( BASH_VERSINFO[0] < 4 )); then
    echo "ERROR: ralph-runner.sh needs bash >= 4 (this is bash ${BASH_VERSION})." >&2
    echo "       Stock macOS bash is 3.2 — install a newer one (brew install bash)" >&2
    echo "       and run:  /opt/homebrew/bin/bash scripts/ralph-runner.sh …" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

timestamp()   { date +%H:%M:%S; }
log_info()    { echo -e "${DIM}$(timestamp)${RESET} ${RALPH_TAG}${BLUE}▸${RESET} $*"; }
log_success() { echo -e "${DIM}$(timestamp)${RESET} ${RALPH_TAG}${GREEN}✔${RESET} $*"; }
log_warn()    { echo -e "${DIM}$(timestamp)${RESET} ${RALPH_TAG}${YELLOW}⚠${RESET} $*"; }
log_error()   { echo -e "${DIM}$(timestamp)${RESET} ${RALPH_TAG}${RED}✘${RESET} $*"; }
log_step()    { echo -e "\n${DIM}$(timestamp)${RESET} ${RALPH_TAG}${BOLD}${MAGENTA}━━━ $* ━━━${RESET}\n"; }

# ---------------------------------------------------------------------------
# Progress tag — every log line carries where the run currently is, so a
# screenful of chunk output stays identifiable without scrolling back to the
# last banner: "[P2/3 C5/6]". The plan part is always present — "[P1/1 C5/6]"
# on single-plan runs — so tags keep a constant shape and scan easily.
# An enclosing orchestrator (ralph-queue.sh) can export RALPH_TAG_SCOPE
# (e.g. "J2/5 my-repo") and it is folded in ahead of the plan/chunk parts:
# "[J2/5 my-repo P1/2 C5/6]".
# ---------------------------------------------------------------------------
TAG_PLAN=""    # "P2/3" while running plan 2 of 3 ("P1/1" on single-plan runs)
TAG_CHUNK=""   # "C5/6" while chunk 5 of 6 is being processed

update_progress_tag() {
    local parts="" part
    for part in "${RALPH_TAG_SCOPE:-}" "$TAG_PLAN" "$TAG_CHUNK"; do
        [[ -n "$part" ]] && parts="${parts:+${parts} }${part}"
    done
    if [[ -n "$parts" ]]; then
        RALPH_TAG="${CYAN}[${parts}]${RESET} "
    else
        RALPH_TAG=""
    fi
}
update_progress_tag

# ---------------------------------------------------------------------------
# Timing helpers
# ---------------------------------------------------------------------------
RALPH_START_TIME=$(date +%s)

format_duration() {
    local seconds="$1"
    local hrs=$(( seconds / 3600 ))
    local mins=$(( (seconds % 3600) / 60 ))
    local secs=$(( seconds % 60 ))
    if (( hrs > 0 )); then
        printf "%dh %dm %ds" "$hrs" "$mins" "$secs"
    elif (( mins > 0 )); then
        printf "%dm %ds" "$mins" "$secs"
    else
        printf "%ds" "$secs"
    fi
}

elapsed_since_start() {
    local now
    now=$(date +%s)
    format_duration $(( now - RALPH_START_TIME ))
}

# ---------------------------------------------------------------------------
# Graceful Ctrl+C handling
# ---------------------------------------------------------------------------
CLAUDE_PID=""

cleanup() {
    # Kill the claude/timeout process first so the pipeline exits immediately
    if [[ -n "$CLAUDE_PID" ]] && kill -0 "$CLAUDE_PID" 2>/dev/null; then
        kill -TERM "$CLAUDE_PID" 2>/dev/null
        wait "$CLAUDE_PID" 2>/dev/null || true
    fi
    CLAUDE_PID=""
    stop_heartbeat 2>/dev/null || true
    echo ""
    log_warn "Interrupted (Ctrl+C). Progress has been saved."
    log_info "Elapsed: $(elapsed_since_start)"
    log_info "Resume by re-running the same command."
    exit 130
}
trap cleanup SIGINT SIGTERM

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
IMPL_MODEL="sonnet"
REVIEW_MODEL="opus"
IMPL_MODEL_CLI=false    # true when --impl-model was passed (CLI beats plan-declared model)
REVIEW_MODEL_CLI=false  # true when --review-model was passed
MAX_FIX_RETRIES=2
MAX_TRANSIENT_RETRIES=2   # Auto-retries on transient Claude API/network errors
LIMIT_WAIT_MIN=20     # Minutes to wait when a Claude usage/plan limit is hit
CHUNK_TIMEOUT="45m"   # Max time per claude call
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
            IMPL_MODEL_CLI=true
            shift 2
            ;;
        --review-model)
            REVIEW_MODEL="$2"
            REVIEW_MODEL_CLI=true
            shift 2
            ;;
        --max-retries)
            MAX_FIX_RETRIES="$2"
            shift 2
            ;;
        --chunk-timeout)
            CHUNK_TIMEOUT="$2"
            shift 2
            ;;
        --limit-wait)
            LIMIT_WAIT_MIN="$2"
            shift 2
            ;;
        --reset)
            DO_RESET=true
            shift
            ;;
        -h|--help)
            cat <<'HELPEOF'
Usage: ralph-runner.sh <plan-file> [<plan-file2> ...] [OPTIONS]

Arguments:
  <plan-file>           Path(s) to markdown plan(s) with "## Chunk N:" or "## Task N:" headers
                        Multiple plan files are processed sequentially on a shared branch

Options:
  --branch NAME         Feature branch name (default: derived from plan filename)
                        With multiple plans: all share this branch if specified,
                        otherwise a shared branch is derived from plan filenames
  --start-from N        Force start at chunk N (single plan only)
  --review-only N       Re-run just the review for chunk N (single plan only)
  --impl-model MODEL    Model for implementation (default: sonnet). A plan doc
                        may declare its own via an "**Impl-Model:** `opus`"
                        line; the CLI flag wins over the plan's declaration
  --review-model MODEL  Model for review (default: opus). Plan docs may
                        declare "**Review-Model:** `MODEL`"; CLI flag wins
  --max-retries N       Max fix attempts per chunk (default: 2)
  --chunk-timeout DUR   Max time per claude call, e.g. 30m, 1h (default: 45m)
  --limit-wait MIN      Minutes to wait when a Claude usage/plan limit is hit,
                        then retry — repeats until the limit lifts (default: 20)
  --dry-run             Show what would execute without running
  --reset               Clear saved progress and start from the beginning
  -h, --help            Show this help

Multi-plan:
  Pass multiple plan files to process them sequentially on a shared
  branch. Each plan builds on the previous plan's output, so changes
  accumulate. The shared branch is derived from plan filenames unless
  overridden with --branch.

  Example:
    bash scripts/ralph-runner.sh docs/plan-a.md docs/plan-b.md docs/plan-c.md

Resume:
  Ralph auto-saves progress after each chunk. To resume after an
  interruption, just re-run the exact same command — it picks up
  where it left off automatically. No need to specify --start-from.

Abort:
  Press Ctrl+C at any time to abort gracefully. Progress is saved
  automatically — just re-run the same command to resume.

Plan file format:
  The plan must use "## Chunk N: Title" or "## Task N: Title" headers, and
  "### ✅ Review Checkpoint — Chunk N" headers for review checklists.
  Steps should use "- [ ]" checkboxes.
  Optional header fields (backticks optional; CLI flags win over all three):
    **Branch:** `feature/name`     branch for the run
    **Impl-Model:** `opus`         implementation model for this plan
    **Review-Model:** `opus`       review model for this plan
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

# ---------------------------------------------------------------------------
# Plan file collection and validation
# ---------------------------------------------------------------------------
PLAN_FILES=("${POSITIONAL_ARGS[@]}")

if [[ ${#PLAN_FILES[@]} -lt 1 ]]; then
    log_error "Missing required argument: <plan-file>"
    echo "Usage: $0 <plan-file> [<plan-file2> ...] [OPTIONS]"
    echo "Run '$0 --help' for details."
    exit 1
fi

# Flags that only work with a single plan file
if [[ ${#PLAN_FILES[@]} -gt 1 ]]; then
    if [[ "$REVIEW_ONLY" -gt 0 ]]; then
        log_error "--review-only is not supported with multiple plan files"
        exit 1
    fi
    if [[ "$START_FROM" -gt 0 ]]; then
        log_error "--start-from is not supported with multiple plan files"
        exit 1
    fi
fi

# Save --branch value for multi-plan use (empty = derive shared branch)
SHARED_BRANCH="$FEATURE_BRANCH"

# Snapshot model defaults so per-plan "**Impl-Model:**"/"**Review-Model:**"
# declarations reset cleanly between plans in a multi-plan run.
IMPL_MODEL_DEFAULT="$IMPL_MODEL"
REVIEW_MODEL_DEFAULT="$REVIEW_MODEL"

# Resolve and validate all plan file paths upfront
declare -a RESOLVED_PLAN_FILES=()
for _pf in "${PLAN_FILES[@]}"; do
    [[ "$_pf" = /* ]] || _pf="$(pwd)/$_pf"
    if [[ ! -f "$_pf" ]]; then
        # Check archive location (completed plans get moved there)
        _archive_candidate="$(dirname "$_pf")/archive/$(basename "$_pf")"
        if [[ -f "$_archive_candidate" ]]; then
            log_info "Plan already archived: $(basename "$_pf") — using archived copy"
            _pf="$_archive_candidate"
        else
            log_error "Plan file not found: $_pf"
            log_error "  (also checked: $_archive_candidate)"
            exit 1
        fi
    fi
    RESOLVED_PLAN_FILES+=("$_pf")
done

PLANS_TOTAL=${#RESOLVED_PLAN_FILES[@]}

# Detect repo root from git
REPO_DIR=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$REPO_DIR" ]]; then
    log_error "Not inside a git repository. Run this from within your project."
    exit 1
fi

PROJECT_NAME=$(basename "$REPO_DIR")

# Declare chunk tracking arrays (reset per plan in the main loop)
declare -a CHUNK_NUMS=()
declare -A CHUNK_TITLES=()
PLAN_FILE=""
STATE_FILE=""
TOTAL_CHUNKS=0
PLAN_TITLE=""
# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
chunk_title() {
    local n="$1"
    echo "${CHUNK_TITLES[$n]:-Chunk $n}"
}

# Parse an explicit "**<Field>:** `value`" line from a plan doc (the backticks
# and surrounding markdown are optional). Prints the value, or nothing if the
# plan doesn't declare that field. Used for **Branch:**, **Impl-Model:**, and
# **Review-Model:** so a plan can own its run configuration and the user need
# not pass flags.
parse_plan_field() {
    local pf="$1" field="$2"
    [[ -f "$pf" ]] || return 0
    sed -n -E "s/^[[:space:]]*\*\*${field}:\*\*[[:space:]]*\`?([^\`[:space:]]+)\`?.*/\1/p" "$pf" | head -1
}

# Back-compat wrapper: branch parsing predates the generic field parser.
parse_plan_branch() {
    parse_plan_field "$1" "Branch"
}

# Derive a concise shared branch name from multiple plan filenames. Strips the
# leading "plan-" and ".md", finds the longest common leading token run (tokens
# split on "-"), then appends the first distinguishing token of the first and
# last plan as a range. Examples:
#   plan-v2-m0-scaffold.md … plan-v2-m5-enrichment.md  -> feature/v2-m0-m5
#   plan-m0-scaffold.md     … plan-m5-enrichment.md     -> feature/m0-m5
#   plan-v2-m1-detection.md (single)                    -> feature/v2-m1-detection
# Beats the old first-token-per-file join (which produced names like
# feature/plans-v2-v2-v2-v2-v2-v2 when every plan shared a "v2" prefix).
derive_shared_branch() {
    local -a stems=()
    local pf base
    for pf in "$@"; do
        base="$(basename "$pf" .md)"
        stems+=("${base#plan-}")
    done

    if [[ ${#stems[@]} -eq 1 ]]; then
        echo "feature/${stems[0]}"
        return
    fi

    # Longest common leading token run across all stems.
    local -a ftoks
    IFS='-' read -ra ftoks <<< "${stems[0]}"
    local prefix_len=${#ftoks[@]} s
    for s in "${stems[@]}"; do
        local -a stoks
        IFS='-' read -ra stoks <<< "$s"
        local i=0
        while (( i < prefix_len && i < ${#stoks[@]} )) && [[ "${ftoks[i]}" == "${stoks[i]}" ]]; do
            i=$(( i + 1 ))
        done
        prefix_len=$i
        (( prefix_len == 0 )) && break
    done

    # Reassemble the common prefix + first/last distinguishing tokens as a range.
    local prefix="" j
    for (( j=0; j<prefix_len; j++ )); do
        prefix="${prefix:+${prefix}-}${ftoks[j]}"
    done

    local -a ltoks
    IFS='-' read -ra ltoks <<< "${stems[${#stems[@]}-1]}"
    local first_d="${ftoks[prefix_len]:-}"
    local last_d="${ltoks[prefix_len]:-}"

    local range=""
    if [[ -n "$first_d" && -n "$last_d" && "$first_d" != "$last_d" ]]; then
        range="${first_d}-${last_d}"
    elif [[ -n "$first_d" ]]; then
        range="$first_d"
    fi

    local name="$prefix"
    [[ -n "$range" ]] && name="${name:+${name}-}${range}"
    [[ -z "$name" ]] && name="plans"
    echo "feature/${name}"
}

# ---------------------------------------------------------------------------
# Safety checks
# ---------------------------------------------------------------------------
if ! command -v claude &>/dev/null; then
    log_error "claude CLI not found. Install it first."
    exit 1
fi

# We need GNU `timeout` for the `-k` (kill-after) flag used to hard-stop a wedged
# agent. macOS has no base `timeout`; coreutils installs it as `gtimeout`. Prefer
# `timeout` when present, fall back to `gtimeout`, and fail loudly if neither.
if command -v timeout &>/dev/null; then
    TIMEOUT_CMD="timeout"
elif command -v gtimeout &>/dev/null; then
    TIMEOUT_CMD="gtimeout"
else
    log_error "Neither 'timeout' nor 'gtimeout' found. Install GNU coreutils (macOS: brew install coreutils)."
    exit 1
fi

# ---------------------------------------------------------------------------
# State management — tracks per-chunk completion
# ---------------------------------------------------------------------------
reset_state() {
    rm -f "$STATE_FILE"
    log_info "Progress reset. Will start from Chunk ${CHUNK_NUMS[0]}."
}

# Commit the state file immediately so progress survives any later
# destructive operation (out-of-scope cleanup, git stash, rm, etc.).
# Plan/state files are runner-owned — chunk work must never mutate them.
commit_state_file() {
    local message="$1"
    [[ -f "$STATE_FILE" ]] || return 0
    git add "$STATE_FILE" 2>/dev/null || return 0
    if ! git diff --cached --quiet -- "$STATE_FILE" 2>/dev/null; then
        git commit --quiet -m "chore(ralph): ${message}" -- "$STATE_FILE" 2>/dev/null || true
    fi
}

mark_chunk_done() {
    local chunk_num="$1"
    if [[ -f "$STATE_FILE" ]]; then
        grep -v "^PHASE:${chunk_num}:" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
    echo "DONE:${chunk_num}" >> "$STATE_FILE"
    commit_state_file "$(basename "$PLAN_FILE" .md) chunk ${chunk_num} done"
}

mark_chunk_skipped() {
    local chunk_num="$1"
    if [[ -f "$STATE_FILE" ]]; then
        grep -v "^PHASE:${chunk_num}:" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
    echo "SKIPPED:${chunk_num}" >> "$STATE_FILE"
    commit_state_file "$(basename "$PLAN_FILE" .md) chunk ${chunk_num} skipped"
}

save_phase() {
    local chunk_num="$1"
    local phase="$2"
    if [[ -f "$STATE_FILE" ]]; then
        grep -v "^PHASE:" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
    echo "PHASE:${chunk_num}:${phase}" >> "$STATE_FILE"
    commit_state_file "$(basename "$PLAN_FILE" .md) chunk ${chunk_num} → ${phase}"
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
        local count
        count=$(grep -c "^DONE:" "$STATE_FILE" 2>/dev/null) || true
        echo "${count:-0}"
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
# User intervention
# ---------------------------------------------------------------------------
prompt_action() {
    local context="$1"
    echo -e "${YELLOW}${BOLD}${context}${RESET}" >&2
    # Unattended run (stdin is not a TTY — e.g. under ralph-queue or cron):
    # there is no keyboard to answer r/s/q. Abort with saved progress instead
    # of blocking forever or dying on read-at-EOF under `set -e`.
    if [[ ! -t 0 ]]; then
        echo -e "  ${DIM}(non-interactive — aborting so a supervisor can retry/resume)${RESET}" >&2
        echo "abort"
        return
    fi
    echo -e "  ${BOLD}r${RESET})etry  ${BOLD}s${RESET})kip  ${BOLD}q${RESET})uit" >&2
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
# Heartbeat — prints elapsed time every 60s so you know it's alive
# ---------------------------------------------------------------------------
HEARTBEAT_PID=""

start_heartbeat() {
    local start_ts="$1"
    (
        while true; do
            sleep 60
            local elapsed=$(( $(date +%s) - start_ts ))
            echo -e "${DIM}$(timestamp)${RESET} ${RALPH_TAG}${DIM}⏱ still running… $(format_duration $elapsed)${RESET}" >&2
        done
    ) &
    HEARTBEAT_PID=$!
}

stop_heartbeat() {
    if [[ -n "$HEARTBEAT_PID" ]] && kill -0 "$HEARTBEAT_PID" 2>/dev/null; then
        kill "$HEARTBEAT_PID" 2>/dev/null
        wait "$HEARTBEAT_PID" 2>/dev/null || true
    fi
    HEARTBEAT_PID=""
}
# ---------------------------------------------------------------------------
# Claude CLI wrapper
# ---------------------------------------------------------------------------
run_claude() {
    local model="$1"
    local prompt="$2"
    local output_file
    output_file=$(mktemp)

    local overall_start
    overall_start=$(date +%s)

    local attempt=0
    local limit_waits=0
    local exit_code=0
    while :; do
        local phase_start
        phase_start=$(date +%s)
        if (( attempt > 0 )); then
            log_info "Running claude --model ${model}... (retry ${attempt}/${MAX_TRANSIENT_RETRIES})"
        else
            log_info "Running claude --model ${model}..."
        fi

        start_heartbeat "$phase_start"

        set +e
        # -k 30s: if Claude ignores SIGTERM at the timeout (e.g. wedged on a
        # stalled stream), SIGKILL it 30s later so a stuck agent can't blow past
        # the chunk budget the way a bare `timeout` lets it.
        # Redirect order matters: send stdout to the tee first, THEN point stderr
        # at it (`2>&1` last). Otherwise stderr keeps the terminal's fd and the
        # transient-error grep below — which reads $output_file — never sees the
        # API/network error messages Claude writes to stderr.
        $TIMEOUT_CMD -k 30s "$CHUNK_TIMEOUT" claude --model "$model" -p --dangerously-skip-permissions "$prompt" > >(tee "$output_file") 2>&1 &
        CLAUDE_PID=$!
        wait "$CLAUDE_PID"
        exit_code=$?
        CLAUDE_PID=""
        set -e

        stop_heartbeat

        if [[ "$exit_code" -eq 124 ]]; then
            log_error "Claude timed out after ${CHUNK_TIMEOUT} — agent did not finish. Use --chunk-timeout to adjust."
            LAST_OUTPUT_FILE="$output_file"
            return 1
        fi

        # 137 = 128 + SIGKILL(9): the `-k 30s` hard-kill fired because the agent
        # ignored SIGTERM at the timeout. Distinct from a soft timeout (124) and
        # not a transient API error, so surface it plainly instead of letting it
        # fall through to the retry/break path with a generic failure.
        if [[ "$exit_code" -eq 137 ]]; then
            log_error "Claude was hard-killed (SIGKILL) 30s after the ${CHUNK_TIMEOUT} timeout — agent was wedged. Use --chunk-timeout to adjust."
            LAST_OUTPUT_FILE="$output_file"
            return 1
        fi

        # Usage/plan-limit errors ("Claude usage limit reached — resets at …",
        # "You've hit your session limit · resets 7:40am"): not transient and
        # not the agent's fault — the plan quota is simply exhausted. Wait
        # LIMIT_WAIT_MIN minutes and retry, indefinitely (a weekly limit can
        # block for hours; ralph should outlast it). Checked BEFORE the
        # transient grep and does NOT consume transient retries. The regex
        # tolerates a qualifier after "hit your" and punctuation (e.g. "·")
        # between "limit" and "resets" — CLI phrasing keeps drifting.
        if [[ "$exit_code" -ne 0 ]] \
           && grep -qiE "usage limit reached|limit will reset|limit[^a-zA-Z]{0,6}resets|session limit|5.hour limit|weekly limit|out of (extra )?usage|hit your ([a-z]+ )?limit|upgrade to continue" "$output_file"; then
            limit_waits=$(( limit_waits + 1 ))
            log_warn "Claude usage limit hit (exit ${exit_code}). Waiting ${LIMIT_WAIT_MIN}m before retrying (wait #${limit_waits})…"
            log_info "Next attempt at: $(date -v +"${LIMIT_WAIT_MIN}"M +%H:%M 2>/dev/null || date -d "+${LIMIT_WAIT_MIN} minutes" +%H:%M)"
            sleep $(( LIMIT_WAIT_MIN * 60 ))
            continue
        fi

        # Auto-retry transient Claude API/network failures (idle stream, overload,
        # 5xx, dropped connections). These aren't the agent's fault and a fresh
        # call usually succeeds. A normal completion exits 0 and skips this.
        if [[ "$exit_code" -ne 0 ]] && (( attempt < MAX_TRANSIENT_RETRIES )) \
           && grep -qiE "stream idle timeout|api error|overloaded|rate.?limit|internal server error|connection (error|reset|closed)|ETIMEDOUT|ECONNRESET|ENOTFOUND|503|529" "$output_file"; then
            attempt=$(( attempt + 1 ))
            log_warn "Transient Claude API error (exit ${exit_code}). Auto-retrying ${attempt}/${MAX_TRANSIENT_RETRIES} in 15s…"
            sleep 15
            continue
        fi

        break
    done

    local phase_elapsed=$(( $(date +%s) - overall_start ))
    log_info "Claude call completed in $(format_duration $phase_elapsed)"

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

PLAN AND STATE FILES ARE RUNNER-OWNED — DO NOT TOUCH:
- Never \`git mv\`, \`git rm\`, edit, or commit the plan file (${PLAN_FILE}) or its \`.ralph-state\` sibling
- Never move plan files to or from \`docs/archive/\` — the runner does this automatically when the plan completes
- The ONLY edit you may make to the plan file is marking step checkboxes from \`- [ ]\` to \`- [x]\` for steps under YOUR chunk
- If git status shows the plan or state file as dirty/untracked from a previous run, leave them alone — the runner will reconcile them
- If you accidentally end up with other dirty files outside your chunk's scope, use \`git restore <file>\` or \`git stash -- <file>\` — never commit them to "clean up"

PLAN FILE: ${PLAN_FILE}

Read the plan file now. Find the section headed "## Chunk ${chunk_num}:" or "## Task ${chunk_num}:" and execute every step listed under it.
Stop when you reach the review checkpoint section (headed "### ✅ Review Checkpoint — Chunk ${chunk_num}" or similar).

BEFORE COMMITTING — Mandatory verification:
1. Grep all new imports to confirm the target symbols exist
2. Run any relevant import checks to verify no import errors
3. Run the project's test suite to verify no test regressions
4. Only then create the commit

AFTER COMMITTING — Your work is done:
- Do NOT re-run the test suite after committing. The review pass will handle verification.
- Do NOT run additional verification commands, linting, or checks after the commit.
- Do NOT summarize, reflect on, or re-examine your work after committing.
- Once the commit is created, EXIT IMMEDIATELY. Your chunk is complete.

Make sure you are on the feature branch: ${FEATURE_BRANCH}
If it doesn't exist yet, create it from main: git checkout -b ${FEATURE_BRANCH}
PROMPT_EOF
    )

    if ! run_claude "$IMPL_MODEL" "$prompt"; then
        log_error "Claude CLI failed during implementation of Chunk ${chunk_num}"
        rm -f "$LAST_OUTPUT_FILE"
        return 1
    fi
    rm -f "$LAST_OUTPUT_FILE"
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

Read the plan file. Find the review checkpoint for chunk/task ${chunk_num} (headed "### ✅ Review Checkpoint — Chunk ${chunk_num}" or similar) and verify EVERY checklist item:
- For each item, actually run the command or check the file
- Check that all step checkboxes under the chunk/task ${chunk_num} section are marked "- [x]"
- Run mechanical verification: cross-reference all new imports, confirm targets exist, run tests

ADDITIONAL CHECKS:
- Verify no unintended changes outside Chunk ${chunk_num} scope
- Run the project's test suite (all tests must pass)
- Run: git diff --stat to see what files were changed
- If Chunk ${chunk_num} adds new functions, verify they are importable
- Verify no code is stubbed, placeholder, or incomplete (e.g., "pass", "TODO", "NotImplementedError")

PLAN AND STATE FILES ARE RUNNER-OWNED:
- The plan file (${PLAN_FILE}) and its \`.ralph-state\` sibling are managed by the runner
- For the "git status clean" check: IGNORE any dirty state in plan files, state files, or files under \`docs/archive/\` — the runner commits those itself between phases
- Only flag dirty files that are inside the chunk's actual scope as a "git status clean" failure
- Do NOT recommend that the implementer \`git mv\`, \`git rm\`, or commit plan/state/archive files as a fix

At the end of your output, write EXACTLY one of these lines:
  REVIEW PASSED — all items verified
  REVIEW FAILED — <brief summary of what failed>

A single failure means the overall result is REVIEW FAILED.
PROMPT_EOF
    )

    # Capture run_claude's exit instead of aborting under `set -e`: the
    # PASSED/FAILED grep below is the source of truth for the VERDICT, but a
    # CLI failure with no verdict at all is an INFRASTRUCTURE failure — the
    # review never happened, and it must not be classified as REVIEW FAILED
    # (which would burn fix-loop attempts on a problem no fix pass can repair).
    #
    # Returns: 0 = PASSED · 1 = FAILED (or unclear) verdict · 2 = infra failure.
    local claude_status=0
    run_claude "$REVIEW_MODEL" "$prompt" || claude_status=$?

    if grep -qi "REVIEW PASSED" "$LAST_OUTPUT_FILE"; then
        rm -f "$LAST_OUTPUT_FILE"
        log_success "Review PASSED for Chunk ${chunk_num}"
        return 0
    elif grep -qi "REVIEW FAILED" "$LAST_OUTPUT_FILE"; then
        rm -f "$LAST_OUTPUT_FILE"
        log_error "Review FAILED for Chunk ${chunk_num}"
        return 1
    elif [[ "$claude_status" -ne 0 ]]; then
        rm -f "$LAST_OUTPUT_FILE"
        log_error "Review CLI call failed (exit ${claude_status}) with no verdict — infrastructure failure, not a review result."
        return 2
    else
        rm -f "$LAST_OUTPUT_FILE"
        log_warn "Review output unclear (no PASSED/FAILED keyword). Treating as FAILED."
        return 1
    fi
}

# run_review_guarded <chunk_num> — run_review, but an infrastructure failure
# (exit 2) prompts retry/skip/quit instead of counting as a FAILED verdict.
# Returns: 0 = PASSED · 1 = FAILED verdict · 3 = operator chose skip.
run_review_guarded() {
    local chunk_num="$1"
    local review_status action

    while :; do
        review_status=0
        run_review "$chunk_num" || review_status=$?

        if [[ "$review_status" -ne 2 ]]; then
            return "$review_status"
        fi

        action=$(prompt_action "Review CLI call failed for Chunk ${chunk_num} (infrastructure — no verdict). What do you want to do?")
        case "$action" in
            retry) continue ;;
            skip)  return 3 ;;
            quit)  log_info "Exiting. Elapsed: $(elapsed_since_start). Re-run the same command to resume."; exit 0 ;;
        esac
    done
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
2. Find the review checkpoint for chunk/task ${chunk_num}
3. Run EACH check from the checkpoint to identify what's failing
4. Fix each failing item — implement real, complete code (no stubs, no TODOs)
5. Run the project's test suite to verify all tests pass
6. Commit with message: "fix: address review failures for chunk ${chunk_num}"

Focus ONLY on making the review pass. Do NOT refactor, add features, or make improvements.
Do NOT modify code outside Chunk ${chunk_num} scope.
Do NOT invoke any slash commands, create new plan files, or spawn subagents.
Do NOT create wrapper scripts or additional shell scripts.

PLAN AND STATE FILES ARE RUNNER-OWNED — DO NOT TOUCH THEM TO "FIX" GIT STATUS:
- The plan file (${PLAN_FILE}), its \`.ralph-state\` sibling, and anything under \`docs/archive/\` are managed by the runner — never \`git mv\`, \`git rm\`, edit, or commit them
- If the review's "git status clean" check failed because of a dirty plan/state/archive file, that is NOT your problem to fix — the runner reconciles those between phases. Leave them alone and address only the in-scope failures.
- If git status shows other dirty files outside your chunk's scope, run \`git restore <file>\` or \`git stash -- <file>\` — NEVER commit them, NEVER move them to archive, NEVER delete them
- The only edit you may make to the plan file is marking step checkboxes from \`- [ ]\` to \`- [x]\` for steps under Chunk ${chunk_num}

AFTER COMMITTING — Your work is done:
- Do NOT re-run the test suite after committing. The review pass will handle verification.
- Do NOT run additional verification commands, linting, or checks after the commit.
- Once the commit is created, EXIT IMMEDIATELY. Your fix is complete.

Make sure you are on branch: ${FEATURE_BRANCH}
PROMPT_EOF
    )

    if ! run_claude "$IMPL_MODEL" "$prompt"; then
        log_error "Claude CLI failed during fix of Chunk ${chunk_num} (attempt ${attempt})"
        rm -f "$LAST_OUTPUT_FILE"
        return 1
    fi
    rm -f "$LAST_OUTPUT_FILE"
}

# ---------------------------------------------------------------------------
# Process one chunk: implement → review → (fix + re-review if needed)
# ---------------------------------------------------------------------------
process_chunk() {
    local chunk_num="$1"
    local title
    title=$(chunk_title "$chunk_num")
    local chunk_start
    chunk_start=$(date +%s)

    TAG_CHUNK="C${chunk_num}/${TOTAL_CHUNKS}"
    update_progress_tag

    log_step "Processing Chunk ${chunk_num}/${TOTAL_CHUNKS}: ${title}"

    # Implementation
    if ! run_implement "$chunk_num"; then
        log_error "Implementation failed for Chunk ${chunk_num}"
        local action
        action=$(prompt_action "Implementation failed. What do you want to do?")
        case "$action" in
            retry) process_chunk "$chunk_num"; return $? ;;
            skip)  log_warn "Skipping Chunk ${chunk_num}. Manual intervention needed later."; mark_chunk_skipped "$chunk_num"; return 0 ;;
            quit)  log_info "Exiting. Elapsed: $(elapsed_since_start). Re-run the same command to resume."; exit 0 ;;
            abort) log_error "Unattended run: implementation failed for Chunk ${chunk_num}. Exiting (progress saved) so a supervisor can retry."; exit 2 ;;
        esac
    fi

    # Review (guarded: an infra failure of the review CLI prompts retry/skip/
    # quit instead of burning fix-loop attempts as a fake FAILED verdict).
    local review_status=0
    run_review_guarded "$chunk_num" || review_status=$?

    if [[ "$review_status" -eq 3 ]]; then
        log_warn "Skipping Chunk ${chunk_num}. Manual intervention needed later."
        mark_chunk_skipped "$chunk_num"
        return 0
    fi

    if [[ "$review_status" -eq 0 ]]; then
        mark_chunk_done "$chunk_num"
        local chunk_elapsed=$(( $(date +%s) - chunk_start ))
        log_success "Chunk ${chunk_num} complete! ($(format_duration $chunk_elapsed))"
        return 0
    fi

    # Fix + re-review loop
    local attempt=1
    while (( attempt <= MAX_FIX_RETRIES )); do
        log_warn "Review failed. Running fix attempt ${attempt}/${MAX_FIX_RETRIES}..."
        if ! run_fix "$chunk_num" "$attempt"; then
            log_warn "Fix attempt ${attempt} failed. Skipping to next attempt."
            (( attempt++ ))
            continue
        fi

        review_status=0
        run_review_guarded "$chunk_num" || review_status=$?

        if [[ "$review_status" -eq 3 ]]; then
            log_warn "Skipping Chunk ${chunk_num}. Manual intervention needed later."
            mark_chunk_skipped "$chunk_num"
            return 0
        fi

        if [[ "$review_status" -eq 0 ]]; then
            mark_chunk_done "$chunk_num"
            local chunk_elapsed=$(( $(date +%s) - chunk_start ))
            log_success "Chunk ${chunk_num} complete after ${attempt} fix(es)! ($(format_duration $chunk_elapsed))"
            return 0
        fi

        (( attempt++ ))
    done

    # Max retries exhausted
    local chunk_elapsed=$(( $(date +%s) - chunk_start ))
    log_error "Chunk ${chunk_num} failed after ${MAX_FIX_RETRIES} fix attempts. ($(format_duration $chunk_elapsed))"
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
            log_info "Exiting. Elapsed: $(elapsed_since_start). Just re-run the same command to resume."
            exit 0
            ;;
        abort)
            log_error "Unattended run: Chunk ${chunk_num} review still failing after ${MAX_FIX_RETRIES} fix attempts. Exiting (progress saved) so a supervisor can retry."
            exit 2
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Archive plan file and clean up state
# ---------------------------------------------------------------------------
archive_plan() {
    local archive_dir plan_basename
    archive_dir="$(dirname "$PLAN_FILE")/archive"
    plan_basename="$(basename "$PLAN_FILE")"

    if [[ -f "$STATE_FILE" ]]; then
        rm -f "$STATE_FILE"
        log_info "Removed state file: $(basename "$STATE_FILE")"
    fi

    # Skip move if already in an archive directory, but still commit
    # the state-file deletion so nothing lingers in the working tree.
    if [[ "$(basename "$(dirname "$PLAN_FILE")")" == "archive" ]]; then
        log_info "Plan already archived: ${plan_basename}"
        git add -A -- "$STATE_FILE" 2>/dev/null || true
        if ! git diff --cached --quiet 2>/dev/null; then
            git commit --quiet -m "chore(ralph): clean up state for archived ${plan_basename}" 2>/dev/null || true
        fi
        return 0
    fi

    if [[ -f "$PLAN_FILE" ]]; then
        mkdir -p "$archive_dir"
        mv "$PLAN_FILE" "${archive_dir}/${plan_basename}"
        log_info "Archived plan to: $(basename "$archive_dir")/${plan_basename}"
        git add -A -- "$STATE_FILE" "${archive_dir}/${plan_basename}" "$PLAN_FILE" 2>/dev/null || true
        if ! git diff --cached --quiet 2>/dev/null; then
            if git commit --quiet -m "chore(ralph): archive completed plan ${plan_basename}" 2>/dev/null; then
                log_info "Committed archive of ${plan_basename}"
            else
                log_warn "Failed to commit archive of ${plan_basename} — please commit manually"
            fi
        fi
    fi
}

# ---------------------------------------------------------------------------
# Execute one plan: display → process chunks → summary → archive
# ---------------------------------------------------------------------------
execute_plan() {
    # Already-completed plans live in docs/archive/. Re-running the same
    # command would otherwise rebuild empty state and re-process every chunk
    # (the .ralph-state completion record is deleted on archive), wastefully
    # re-driving sonnet+opus over work that's already merged. Skip fast.
    # Escape hatch: pass the archive path directly with --reset to force a re-run.
    if $PLAN_ALREADY_ARCHIVED && ! $DO_RESET \
       && [[ "$START_FROM" -eq 0 && "$REVIEW_ONLY" -eq 0 ]]; then
        log_success "Already completed and archived — skipping: ${PLAN_TITLE}"
        # Tidy any stale state file a previous buggy resume may have left behind.
        if ! $DRY_RUN && [[ -f "$STATE_FILE" ]]; then
            rm -f "$STATE_FILE"
            # Scope the staged-diff check and commit to the state file so an
            # unrelated staged change in the user's tree can't get swept into
            # this housekeeping commit (mirrors commit_state_file).
            git add -A -- "$STATE_FILE" 2>/dev/null || true
            git diff --cached --quiet -- "$STATE_FILE" 2>/dev/null \
                || git commit --quiet -m "chore(ralph): clean up stale state for archived $(basename "$PLAN_FILE")" -- "$STATE_FILE" 2>/dev/null || true
        fi
        return 0
    fi

    # Display plan info
    log_info "Plan: ${PLAN_TITLE}"
    log_info "File: ${PLAN_FILE}"
    log_info "Branch: ${FEATURE_BRANCH}"
    log_info "Models: impl=${IMPL_MODEL}, review=${REVIEW_MODEL}"
    log_info "Chunk timeout: ${CHUNK_TIMEOUT}"
    log_info "Chunks: ${TOTAL_CHUNKS}"

    # Show chunk status
    local completed
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
        TAG_CHUNK="C${REVIEW_ONLY}/${TOTAL_CHUNKS}"
        update_progress_tag
        log_info "Review-only mode for Chunk ${REVIEW_ONLY}"
        local review_status=0
        run_review "$REVIEW_ONLY" || review_status=$?
        case "$review_status" in
            0) log_success "Review passed!" ;;
            2) log_error "Review CLI call failed (infrastructure — no verdict). Re-run when the CLI/network recovers."; return 2 ;;
            *) log_error "Review failed."; return 1 ;;
        esac
        return 0
    fi

    # Determine starting chunk
    local start
    if [[ "$START_FROM" -gt 0 ]]; then
        start="$START_FROM"
        log_info "Starting from Chunk ${start} (--start-from override)"
    else
        start=$(find_next_chunk)
        if [[ -z "$start" ]]; then
            log_success "All chunks are already complete! Nothing to do."
            archive_plan
            return 0
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
        return 0
    fi

    # Ensure feature branch exists
    local current_branch
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

    # Per-plan summary
    local skipped_count=0
    for num in "${CHUNK_NUMS[@]}"; do
        if is_chunk_skipped "$num"; then
            (( ++skipped_count ))
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

    # Archive if all chunks completed
    if [[ "$skipped_count" -eq 0 ]]; then
        archive_plan
    fi

    return 0
}
# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
cd "$REPO_DIR"

echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║  Ralph Orchestrator v4.17                                ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}\n"

log_info "Date: $(date +%Y-%m-%d)"
log_info "Repo: ${REPO_DIR}"
if [[ "$PLANS_TOTAL" -gt 1 ]]; then
    log_info "Plans: ${PLANS_TOTAL} plan files queued"
fi
log_info "Models: impl=${IMPL_MODEL}, review=${REVIEW_MODEL}"
log_info "Chunk timeout: ${CHUNK_TIMEOUT} (override with --chunk-timeout)"
log_info "Abort: Ctrl+C to stop gracefully (progress is saved)"

# ---------------------------------------------------------------------------
# Derive shared branch for multi-plan mode
# ---------------------------------------------------------------------------
if [[ "$PLANS_TOTAL" -gt 1 && -z "$SHARED_BRANCH" ]]; then
    # Prefer an explicit "**Branch:**" declared in the first plan doc — sub-plans
    # of one feature should all declare the same shared branch.
    SHARED_BRANCH="$(parse_plan_branch "${RESOLVED_PLAN_FILES[0]}")"
    if [[ -n "$SHARED_BRANCH" ]]; then
        log_info "Shared branch from plan doc: ${SHARED_BRANCH}"
    else
        # Fall back to a concise name derived from the plan filenames.
        SHARED_BRANCH="$(derive_shared_branch "${RESOLVED_PLAN_FILES[@]}")"
        log_info "Shared branch derived from plan filenames: ${SHARED_BRANCH}"
    fi
fi

# Multi-plan tracking
declare -a PLAN_RESULTS=()
declare -a PLAN_NAMES=()
PLAN_INDEX=0

for _plan_file in "${RESOLVED_PLAN_FILES[@]}"; do
    (( ++PLAN_INDEX ))

    TAG_PLAN="P${PLAN_INDEX}/${PLANS_TOTAL}"
    TAG_CHUNK=""
    update_progress_tag

    # --- Per-plan setup: reset globals ---
    PLAN_FILE="$_plan_file"
    STATE_FILE="${PLAN_FILE}.ralph-state"

    # A plan whose file currently lives in docs/archive/ has already been
    # completed — archiving is the completion marker. Resolution earlier falls
    # back to the archived copy when the original docs/ path is gone, so this
    # catches "re-ran the same command after a milestone finished."
    PLAN_ALREADY_ARCHIVED=false
    if [[ "$(basename "$(dirname "$PLAN_FILE")")" == "archive" ]]; then
        PLAN_ALREADY_ARCHIVED=true
    fi

    CHUNK_NUMS=()
    unset CHUNK_TITLES 2>/dev/null || true
    declare -A CHUNK_TITLES

    while IFS= read -r line; do
        if [[ "$line" =~ ^##\ (Chunk|Task)\ ([0-9]+):\ (.+)$ ]]; then
            num="${BASH_REMATCH[2]}"
            title="${BASH_REMATCH[3]}"
            title="${title%% \(*}"
            CHUNK_NUMS+=("$num")
            CHUNK_TITLES[$num]="$title"
        fi
    done < "$PLAN_FILE"

    TOTAL_CHUNKS=${#CHUNK_NUMS[@]}

    if [[ "$TOTAL_CHUNKS" -eq 0 ]]; then
        log_error "No chunks found in: $(basename "$PLAN_FILE")"
        PLAN_RESULTS+=("FAILED")
        PLAN_NAMES+=("$(basename "$PLAN_FILE" .md)")
        continue
    fi

    # Derive feature branch: shared (multi-plan) > explicit "**Branch:**" in the
    # plan doc > derived from the filename (legacy default).
    if [[ -n "$SHARED_BRANCH" ]]; then
        FEATURE_BRANCH="$SHARED_BRANCH"
    else
        FEATURE_BRANCH="$(parse_plan_branch "$PLAN_FILE")"
        if [[ -n "$FEATURE_BRANCH" ]]; then
            log_info "Branch from plan doc: ${FEATURE_BRANCH}"
        else
            plan_basename=$(basename "$PLAN_FILE" .md)
            plan_basename="${plan_basename#plan-}"
            FEATURE_BRANCH="feature/${plan_basename}"
        fi
    fi

    # Per-plan model overrides: CLI flag > "**Impl-Model:**" / "**Review-Model:**"
    # declared in the plan doc > default. Lets a plan that needs a stronger
    # implementer (e.g. prose-heavy docs work) declare it itself, so the run
    # command needs no model flags. Re-resolved for every plan in a multi-plan
    # run so one plan's declaration never bleeds into the next.
    if ! $IMPL_MODEL_CLI; then
        _plan_model="$(parse_plan_field "$PLAN_FILE" "Impl-Model")"
        if [[ -n "$_plan_model" ]]; then
            IMPL_MODEL="$_plan_model"
            log_info "Impl model from plan doc: ${IMPL_MODEL}"
        else
            IMPL_MODEL="$IMPL_MODEL_DEFAULT"
        fi
    fi
    if ! $REVIEW_MODEL_CLI; then
        _plan_model="$(parse_plan_field "$PLAN_FILE" "Review-Model")"
        if [[ -n "$_plan_model" ]]; then
            REVIEW_MODEL="$_plan_model"
            log_info "Review model from plan doc: ${REVIEW_MODEL}"
        else
            REVIEW_MODEL="$REVIEW_MODEL_DEFAULT"
        fi
    fi

    PLAN_TITLE=$(grep -m1 '^# ' "$PLAN_FILE" | sed 's/^# //' || basename "$PLAN_FILE" .md)
    PLAN_NAMES+=("$PLAN_TITLE")

    # Handle --reset for this plan
    if $DO_RESET; then
        reset_state
    fi

    # --- Plan header (multi-plan only) ---
    if [[ "$PLANS_TOTAL" -gt 1 ]]; then
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${BOLD}${CYAN}  Plan ${PLAN_INDEX}/${PLANS_TOTAL}: ${PLAN_TITLE}${RESET}"
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
    fi

    # --- Execute ---
    if execute_plan; then
        _plan_ok=true
    else
        _plan_ok=false
    fi

    TAG_CHUNK=""
    update_progress_tag

    if $_plan_ok; then
        PLAN_RESULTS+=("DONE")
        if [[ "$PLANS_TOTAL" -gt 1 ]]; then
            log_success "Plan ${PLAN_INDEX}/${PLANS_TOTAL} complete: ${PLAN_TITLE}"
        fi
    else
        PLAN_RESULTS+=("FAILED")
        log_error "Plan failed: ${PLAN_TITLE}"
    fi
done

TAG_PLAN=""; TAG_CHUNK=""
update_progress_tag

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------
echo ""
if [[ "$PLANS_TOTAL" -gt 1 ]]; then
    log_success "All plans processed!"
else
    log_success "Plan execution complete!"
fi
log_info "Total elapsed: $(elapsed_since_start)"
echo ""

if [[ "$PLANS_TOTAL" -gt 1 ]]; then
    echo -e "${BOLD}Pipeline Summary:${RESET}"
    for i in "${!PLAN_NAMES[@]}"; do
        _result="${PLAN_RESULTS[$i]}"
        _name="${PLAN_NAMES[$i]}"
        if [[ "$_result" == "DONE" ]]; then
            echo -e "  ${GREEN}✔${RESET} ${_name}"
        else
            echo -e "  ${RED}✘${RESET} ${_name}"
        fi
    done
    echo ""
fi

echo -e "${BOLD}Next steps:${RESET}"
echo "  1. Review the branch: git log --oneline main..HEAD"
echo "  2. Run a manual test"
echo "  3. Create PR: gh pr create"
echo ""
