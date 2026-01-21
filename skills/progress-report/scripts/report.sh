#!/usr/bin/env bash
#
# report.sh - Progress reporting script
#
# Displays progress dashboard showing phase completion, blocked tasks,
# and remaining work estimate.
#

set -euo pipefail

# Get script directory and source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/shared"

source "$SHARED_DIR/path-resolver.sh"
source "$SHARED_DIR/output-format.sh"
source "$SHARED_DIR/error-handler.sh"

# Initialize
reset_errors
setup_error_trap

# Metrics storage
declare -i TOTAL_TASKS=0
declare -i COMPLETED_TASKS=0

declare -a PHASES=()
declare -a PHASE_TOTALS=()
declare -a PHASE_COMPLETED=()
declare -a BLOCKED_TASKS=()
declare -a POTENTIALLY_COMPLETE=()

# Parse phases from tasks.md (FR-028)
parse_phases() {
    if [[ ! -f "$TASKS_FILE" ]]; then
        return
    fi

    local content
    content=$(cat "$TASKS_FILE")

    local current_phase=""
    local phase_total=0
    local phase_done=0

    while IFS= read -r line; do
        # Detect phase headers
        if [[ "$line" =~ ^##\ Phase\ ([0-9]+):\ (.+)$ ]] || [[ "$line" =~ ^##\ Phase\ ([0-9]+)\ (.+)$ ]]; then
            # Save previous phase if exists
            if [[ -n "$current_phase" ]]; then
                PHASES+=("$current_phase")
                PHASE_TOTALS+=("$phase_total")
                PHASE_COMPLETED+=("$phase_done")
            fi
            current_phase="${BASH_REMATCH[2]}"
            phase_total=0
            phase_done=0
        fi

        # Count tasks (match "- [ ]" or "- [X]" or "- [x]" with optional leading whitespace)
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\[([Xx[:space:]])\] ]]; then
            ((phase_total++)) || true
            ((TOTAL_TASKS++)) || true

            if [[ "${BASH_REMATCH[1]}" =~ [Xx] ]]; then
                ((phase_done++)) || true
                ((COMPLETED_TASKS++)) || true
            fi
        fi
    done <<< "$content"

    # Save last phase
    if [[ -n "$current_phase" ]]; then
        PHASES+=("$current_phase")
        PHASE_TOTALS+=("$phase_total")
        PHASE_COMPLETED+=("$phase_done")
    fi
}

# Identify blocked tasks (FR-029)
find_blocked_tasks() {
    if [[ ! -f "$TASKS_FILE" ]]; then
        return
    fi

    local content
    content=$(cat "$TASKS_FILE")

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\[[[:space:]]\] ]]; then
            # Check if task mentions "blocked" or "waiting"
            if echo "$line" | grep -qiE '(blocked|waiting|depends on)'; then
                local task_desc
                task_desc=$(echo "$line" | sed 's/^\s*-\s*\[ \]\s*//')
                BLOCKED_TASKS+=("$task_desc")
            fi
        fi
    done <<< "$content"
}

# Detect potentially complete tasks (FR-031a)
find_potentially_complete() {
    if [[ ! -f "$TASKS_FILE" ]]; then
        return
    fi

    local content
    content=$(cat "$TASKS_FILE")

    while IFS= read -r line; do
        # Only check incomplete tasks
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\[[[:space:]]\] ]]; then
            # Extract file path from task description
            local file_path
            file_path=$(echo "$line" | grep -oE 'skills/[a-zA-Z0-9/_.-]+\.(sh|md)' | head -1 || true)

            if [[ -n "$file_path" ]]; then
                local full_path="$REPO_ROOT/$file_path"
                if [[ -f "$full_path" ]]; then
                    local task_id
                    task_id=$(echo "$line" | grep -oE 'T[0-9]+' | head -1 || echo "Task")
                    POTENTIALLY_COMPLETE+=("$task_id: File $file_path exists")
                fi
            fi
        fi
    done <<< "$content"
}

# Print progress bar
print_progress_bar_inline() {
    local completed="$1"
    local total="$2"
    local width=10

    if [[ "$total" -eq 0 ]]; then
        echo "[----------] 0%"
        return
    fi

    local percentage=$((completed * 100 / total))
    local filled=$((completed * width / total))
    local empty=$((width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=0; i<empty; i++)); do bar+="-"; done

    echo "[$bar] $percentage%"
}

# Output dashboard (FR-031)
output_dashboard() {
    local feature_branch
    feature_branch=$(get_feature_branch)
    local timestamp
    timestamp=$(get_timestamp)

    echo "## Progress Dashboard: progress-report"
    echo ""
    echo "**Branch**: $feature_branch"
    echo "**Timestamp**: $timestamp"
    echo ""

    # Overall progress
    print_section "Overall Progress"
    local overall_bar
    overall_bar=$(print_progress_bar "$COMPLETED_TASKS" "$TOTAL_TASKS")
    echo "$overall_bar"
    echo ""

    # Phase breakdown
    if [[ "${#PHASES[@]}" -gt 0 ]]; then
        print_section "Phase Breakdown"
        echo "| Phase | Progress | Completed | Total |"
        echo "|-------|----------|-----------|-------|"

        for i in "${!PHASES[@]}"; do
            local phase="${PHASES[$i]}"
            local total="${PHASE_TOTALS[$i]}"
            local done="${PHASE_COMPLETED[$i]}"
            local bar
            bar=$(print_progress_bar_inline "$done" "$total")
            echo "| $phase | $bar | $done | $total |"
        done
        echo ""
    fi

    # Blocked tasks
    print_section "Blocked Tasks"
    if [[ "${#BLOCKED_TASKS[@]}" -gt 0 ]]; then
        for task in "${BLOCKED_TASKS[@]}"; do
            echo "- $task"
        done
    else
        echo "None"
    fi
    echo ""

    # Potentially complete tasks
    if [[ "${#POTENTIALLY_COMPLETE[@]}" -gt 0 ]]; then
        print_section "Potentially Complete (files exist but task not marked)"
        for task in "${POTENTIALLY_COMPLETE[@]}"; do
            echo "- $task"
        done
        echo ""
    fi

    # Remaining work estimate (FR-030)
    print_section "Remaining Work"
    local incomplete=$((TOTAL_TASKS - COMPLETED_TASKS))
    echo "- Incomplete tasks: $incomplete"
    echo "- Blocked tasks: ${#BLOCKED_TASKS[@]}"
    echo ""
}

# Main execution
main() {
    # Resolve paths
    if ! resolve_paths; then
        exit_unexpected_error "Failed to resolve paths" "Ensure you are in a spec kit project"
    fi

    # Check for required files (FR-038)
    if [[ ! -f "$TASKS_FILE" ]]; then
        exit_missing_file "$TASKS_FILE" "tasks.md"
    fi

    # Run all analyses
    parse_phases
    find_blocked_tasks
    find_potentially_complete

    # Output dashboard
    output_dashboard

    exit 0
}

main "$@"
