#!/bin/bash
# Claude Code Implementation Loop
# Runs Claude Code to implement tasks defined in config file
# Each task iterates until completion (<promise>DONE</promise>) or max iterations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/.github/claude-implementation-config.yaml"
LOG_DIR="${REPO_ROOT}/logs/claude-implement"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
MAX_ITERATIONS=20
TASK_FILTER=""
AUTO_COMMIT=true
DRY_RUN=false

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Run Claude Code to implement tasks from config file.

Options:
    -t, --task TASK       Run only specific task (by name)
    -i, --iterations N    Maximum iterations per task (default: 20)
    -n, --no-commit       Don't commit changes automatically
    -d, --dry-run         Show what would be done without running Claude
    -c, --config FILE     Use alternate config file
    -h, --help            Show this help message

Examples:
    $(basename "$0")                          # Run all enabled tasks
    $(basename "$0") -t argo-rollouts         # Run only argo-rollouts task
    $(basename "$0") -i 10 -t terraform       # Run terraform with max 10 iterations
    $(basename "$0") --dry-run                # Preview what would run

Config file: $CONFIG_FILE
EOF
    exit 0
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

check_dependencies() {
    local missing=()

    if ! command -v claude &> /dev/null; then
        missing+=("claude (npm install -g @anthropic-ai/claude-code)")
    fi

    if ! command -v yq &> /dev/null; then
        missing+=("yq (https://github.com/mikefarah/yq)")
    fi

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi

    if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        log_error "ANTHROPIC_API_KEY environment variable not set"
        exit 1
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies:"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--task)
                TASK_FILTER="$2"
                shift 2
                ;;
            -i|--iterations)
                MAX_ITERATIONS="$2"
                shift 2
                ;;
            -n|--no-commit)
                AUTO_COMMIT=false
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

read_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config file not found: $CONFIG_FILE"
        exit 1
    fi

    # Check if enabled
    local enabled
    enabled=$(yq '.enabled' "$CONFIG_FILE")
    if [[ "$enabled" != "true" ]]; then
        log_warn "Implementation is disabled in config (enabled: false)"
        exit 0
    fi

    # Get tasks
    if [[ -n "$TASK_FILTER" ]]; then
        TASKS_JSON=$(yq -o=json ".tasks | map(select(.enabled == true and .name == \"$TASK_FILTER\"))" "$CONFIG_FILE")
    else
        TASKS_JSON=$(yq -o=json '.tasks | map(select(.enabled == true))' "$CONFIG_FILE")
    fi

    TASK_COUNT=$(echo "$TASKS_JSON" | jq 'length')

    if [[ "$TASK_COUNT" -eq 0 ]]; then
        log_warn "No enabled tasks found"
        if [[ -n "$TASK_FILTER" ]]; then
            log_info "Task '$TASK_FILTER' may not exist or is disabled"
        fi
        exit 0
    fi

    log_info "Found $TASK_COUNT enabled task(s)"
}

run_task() {
    local task_name="$1"
    local task_prompt="$2"
    local task_log_dir="${LOG_DIR}/${task_name}"

    mkdir -p "$task_log_dir"

    echo ""
    echo "=========================================="
    echo -e "${BLUE}Task: ${task_name}${NC}"
    echo "=========================================="

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would run task with prompt:"
        echo "$task_prompt" | head -20
        echo "..."
        return 0
    fi

    local task_completed=false

    for iter in $(seq 1 "$MAX_ITERATIONS"); do
        echo ""
        log_info "--- Iteration $iter of $MAX_ITERATIONS ---"

        local log_file="${task_log_dir}/iter${iter}.log"

        # Build the full prompt with context
        local full_prompt="You are implementing a task for a Kubernetes DevSecOps platform.

TASK: $task_name

ITERATION: $iter of $MAX_ITERATIONS

INSTRUCTIONS:
$task_prompt

IMPORTANT RULES:
1. Make changes to files as needed to complete the task
2. When the task is fully complete, output exactly: <promise>DONE</promise>
3. If the task is NOT complete, describe what still needs to be done
4. Check your work before claiming completion
5. Follow the project conventions in CLAUDE.md

Begin implementation:"

        # Run Claude Code
        echo "$full_prompt" | claude --dangerously-skip-permissions \
            --print \
            --output-format text \
            2>&1 | tee "$log_file" || true

        # Check for completion
        if grep -q "<promise>DONE</promise>" "$log_file"; then
            echo ""
            log_success "Task $task_name completed at iteration $iter!"
            task_completed=true

            if [[ "$AUTO_COMMIT" == "true" ]]; then
                commit_changes "$task_name" "$iter"
            fi
            break
        fi

        log_info "Task not yet complete, continuing..."
    done

    if [[ "$task_completed" == "false" ]]; then
        echo ""
        log_warn "Task $task_name did not complete within $MAX_ITERATIONS iterations"
        log_info "Logs available at: $task_log_dir"

        if [[ "$AUTO_COMMIT" == "true" ]]; then
            create_wip_branch "$task_name"
        fi
        return 1
    fi

    return 0
}

commit_changes() {
    local task_name="$1"
    local iterations="$2"

    cd "$REPO_ROOT"
    git add -A

    if ! git diff --staged --quiet; then
        git commit -m "feat($task_name): implementation by Claude Code

Completed in $iterations iteration(s)"
        log_success "Changes committed"
    else
        log_info "No changes to commit"
    fi
}

create_wip_branch() {
    local task_name="$1"
    local branch="claude/${task_name}-$(date +%Y%m%d-%H%M%S)"

    cd "$REPO_ROOT"
    git add -A

    if ! git diff --staged --quiet; then
        git checkout -b "$branch"
        git commit -m "wip($task_name): partial implementation by Claude Code

Status: incomplete after $MAX_ITERATIONS iterations"
        log_info "Created WIP branch: $branch"
        git checkout -
    fi
}

main() {
    parse_args "$@"

    log_info "Claude Code Implementation Loop"
    log_info "Config: $CONFIG_FILE"
    log_info "Max iterations: $MAX_ITERATIONS"

    check_dependencies
    read_config

    mkdir -p "$LOG_DIR"

    local completed=0
    local failed=0

    for i in $(seq 0 $((TASK_COUNT - 1))); do
        local task_name
        local task_prompt
        task_name=$(echo "$TASKS_JSON" | jq -r ".[$i].name")
        task_prompt=$(echo "$TASKS_JSON" | jq -r ".[$i].prompt")

        if run_task "$task_name" "$task_prompt"; then
            ((completed++)) || true
        else
            ((failed++)) || true
        fi
    done

    echo ""
    echo "=========================================="
    log_info "Summary: $completed completed, $failed incomplete"
    echo "=========================================="

    if [[ "$failed" -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
