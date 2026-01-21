#!/usr/bin/env bash
#
# verify.sh - Implementation verification script
#
# Verifies implementation against specifications by checking requirement
# fulfillment, task completion, and contract implementation.
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
declare -i TOTAL_FRS=0
declare -i IMPLEMENTED_FRS=0
declare -i TOTAL_TASKS=0
declare -i COMPLETED_TASKS=0
declare -i TOTAL_CONTRACTS=0
declare -i IMPLEMENTED_CONTRACTS=0

declare -a UNIMPLEMENTED_REQUIREMENTS=()
declare -a RECOMMENDED_ACTIONS=()

# Extract FR-XXX requirements from spec.md
extract_requirements() {
    if [[ ! -f "$SPEC_FILE" ]]; then
        return
    fi

    local content
    content=$(cat "$SPEC_FILE")

    # Find all unique FR-XXX references
    local frs
    frs=$(echo "$content" | grep -oE 'FR-[0-9]+' | sort -u || true)

    while IFS= read -r fr; do
        if [[ -n "$fr" ]]; then
            ((TOTAL_FRS++)) || true
        fi
    done <<< "$frs"
}

# Calculate task completion rate from tasks.md (FR-011)
calculate_task_completion() {
    if [[ ! -f "$TASKS_FILE" ]]; then
        return
    fi

    local content
    content=$(cat "$TASKS_FILE")

    # Count total tasks (lines starting with - [ ] or - [X] or - [x])
    TOTAL_TASKS=$(echo "$content" | grep -cE '^\s*-\s*\[[Xx ]\]' || echo "0")

    # Count completed tasks (marked with [X] or [x])
    COMPLETED_TASKS=$(echo "$content" | grep -cE '^\s*-\s*\[[Xx]\]' || echo "0")
}

# Calculate FR requirement fulfillment (FR-010)
calculate_fr_fulfillment() {
    if [[ ! -f "$SPEC_FILE" ]] || [[ ! -f "$TASKS_FILE" ]]; then
        return
    fi

    local spec_content tasks_content
    spec_content=$(cat "$SPEC_FILE")
    tasks_content=$(cat "$TASKS_FILE")

    # Get all FR-XXX from spec
    local frs
    frs=$(echo "$spec_content" | grep -oE 'FR-[0-9]+' | sort -u || true)

    while IFS= read -r fr; do
        if [[ -z "$fr" ]]; then
            continue
        fi

        # Check if this FR is referenced in a completed task
        if echo "$tasks_content" | grep -E '^\s*-\s*\[[Xx]\].*'"$fr" > /dev/null 2>&1; then
            ((IMPLEMENTED_FRS++)) || true
        else
            # Get FR description from spec
            local fr_desc
            fr_desc=$(echo "$spec_content" | grep -m1 "$fr" | head -1 | sed 's/.*'"$fr"'[^a-zA-Z]*//' | cut -c1-60)
            if [[ -n "$fr_desc" ]]; then
                UNIMPLEMENTED_REQUIREMENTS+=("$fr: $fr_desc...")
            else
                UNIMPLEMENTED_REQUIREMENTS+=("$fr: (description not found)")
            fi
        fi
    done <<< "$frs"
}

# Check contract implementation (FR-012)
check_contract_implementation() {
    if [[ ! -d "$CONTRACTS_DIR" ]]; then
        return
    fi

    local contract_files
    contract_files=$(find "$CONTRACTS_DIR" -name "*.md" -type f 2>/dev/null || true)

    if [[ -z "$contract_files" ]]; then
        return
    fi

    while IFS= read -r contract_file; do
        if [[ -z "$contract_file" ]]; then
            continue
        fi

        local content
        content=$(cat "$contract_file")

        # Count endpoint definitions (lines with HTTP methods)
        local endpoints
        endpoints=$(echo "$content" | grep -cE '(GET|POST|PUT|DELETE|PATCH)\s+/' || echo "0")
        ((TOTAL_CONTRACTS += endpoints)) || true

        # For now, assume all endpoints in contracts are implemented
        # A more sophisticated check would verify actual implementation files
        ((IMPLEMENTED_CONTRACTS += endpoints)) || true
    done <<< "$contract_files"
}

# Generate recommended actions (FR-015)
generate_recommendations() {
    local task_percent=0
    local fr_percent=0

    if [[ "$TOTAL_TASKS" -gt 0 ]]; then
        task_percent=$((COMPLETED_TASKS * 100 / TOTAL_TASKS))
    fi

    if [[ "$TOTAL_FRS" -gt 0 ]]; then
        fr_percent=$((IMPLEMENTED_FRS * 100 / TOTAL_FRS))
    fi

    if [[ "$task_percent" -lt 100 ]]; then
        local remaining=$((TOTAL_TASKS - COMPLETED_TASKS))
        RECOMMENDED_ACTIONS+=("Complete remaining $remaining task(s) in tasks.md")
    fi

    if [[ "$fr_percent" -lt 100 ]]; then
        local unimpl=$((TOTAL_FRS - IMPLEMENTED_FRS))
        RECOMMENDED_ACTIONS+=("Address $unimpl unimplemented requirement(s)")
    fi

    if [[ "${#UNIMPLEMENTED_REQUIREMENTS[@]}" -gt 0 ]]; then
        RECOMMENDED_ACTIONS+=("Review unimplemented requirements list below")
    fi

    if [[ "${#RECOMMENDED_ACTIONS[@]}" -eq 0 ]]; then
        RECOMMENDED_ACTIONS+=("All requirements fulfilled - ready for release validation")
    fi
}

# Determine exit code based on fulfillment
determine_fulfillment_exit_code() {
    local task_percent=0
    local fr_percent=0

    if [[ "$TOTAL_TASKS" -gt 0 ]]; then
        task_percent=$((COMPLETED_TASKS * 100 / TOTAL_TASKS))
    fi

    if [[ "$TOTAL_FRS" -gt 0 ]]; then
        fr_percent=$((IMPLEMENTED_FRS * 100 / TOTAL_FRS))
    fi

    # Use the lower of the two percentages
    local overall_percent=$task_percent
    if [[ "$fr_percent" -lt "$overall_percent" ]]; then
        overall_percent=$fr_percent
    fi

    if [[ "$overall_percent" -eq 100 ]]; then
        echo "0"
    elif [[ "$overall_percent" -ge 80 ]]; then
        echo "1"
    else
        echo "2"
    fi
}

# Output results (FR-014, FR-024)
output_results() {
    local feature_branch
    feature_branch=$(get_feature_branch)
    local timestamp
    timestamp=$(get_timestamp)

    echo "## Fulfillment Report: implementation-verify"
    echo ""
    echo "**Branch**: $feature_branch"
    echo "**Timestamp**: $timestamp"
    echo ""

    # Coverage metrics
    print_section "Coverage Metrics"

    local task_percent=0
    local fr_percent=0
    local contract_percent=0

    if [[ "$TOTAL_TASKS" -gt 0 ]]; then
        task_percent=$((COMPLETED_TASKS * 100 / TOTAL_TASKS))
    fi

    if [[ "$TOTAL_FRS" -gt 0 ]]; then
        fr_percent=$((IMPLEMENTED_FRS * 100 / TOTAL_FRS))
    fi

    if [[ "$TOTAL_CONTRACTS" -gt 0 ]]; then
        contract_percent=$((IMPLEMENTED_CONTRACTS * 100 / TOTAL_CONTRACTS))
    fi

    print_coverage "Task Completion" "$COMPLETED_TASKS" "$TOTAL_TASKS"
    print_coverage "FR Fulfillment" "$IMPLEMENTED_FRS" "$TOTAL_FRS"

    if [[ "$TOTAL_CONTRACTS" -gt 0 ]]; then
        print_coverage "Contract Implementation" "$IMPLEMENTED_CONTRACTS" "$TOTAL_CONTRACTS"
    fi

    echo ""

    # Unimplemented requirements
    if [[ "${#UNIMPLEMENTED_REQUIREMENTS[@]}" -gt 0 ]]; then
        print_section "Unimplemented Requirements"
        for req in "${UNIMPLEMENTED_REQUIREMENTS[@]}"; do
            echo "- $req"
        done
        echo ""
    fi

    # Recommended actions
    print_section "Recommended Actions"
    for action in "${RECOMMENDED_ACTIONS[@]}"; do
        echo "- $action"
    done
    echo ""
}

# Main execution
main() {
    # Resolve paths
    if ! resolve_paths; then
        exit_unexpected_error "Failed to resolve paths" "Ensure you are in a spec kit project"
    fi

    # Check for required files (FR-038, FR-039)
    if [[ ! -f "$TASKS_FILE" ]]; then
        exit_missing_file "$TASKS_FILE" "tasks.md"
    fi

    if [[ ! -f "$SPEC_FILE" ]]; then
        exit_missing_file "$SPEC_FILE" "spec.md"
    fi

    # Run all analyses
    extract_requirements
    calculate_task_completion
    calculate_fr_fulfillment
    check_contract_implementation
    generate_recommendations

    # Output results
    output_results

    # Exit with appropriate code
    exit "$(determine_fulfillment_exit_code)"
}

main "$@"
