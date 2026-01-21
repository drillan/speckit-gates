#!/usr/bin/env bash
#
# output-format.sh - Shared output formatting utilities for speckit-gates skills
#
# Usage:
#   source output-format.sh
#   print_status GREEN "All checks passed"
#

# Colors for terminal output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_GRAY='\033[0;90m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_NC='\033[0m' # No Color

# Status emoji
readonly STATUS_GREEN="GREEN"
readonly STATUS_YELLOW="YELLOW"
readonly STATUS_RED="RED"

# Print a header section
print_header() {
    local skill_name="$1"
    local feature_branch="$2"
    local status="$3"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local status_display
    case "$status" in
        GREEN)  status_display="GREEN" ;;
        YELLOW) status_display="YELLOW" ;;
        RED)    status_display="RED" ;;
        *)      status_display="$status" ;;
    esac

    echo "## Quality Assessment: $skill_name"
    echo ""
    echo "**Status**: $status_display"
    echo "**Branch**: $feature_branch"
    echo "**Timestamp**: $timestamp"
    echo ""
}

# Print a section title
print_section() {
    local title="$1"
    echo "### $title"
    echo ""
}

# Print a finding entry
print_finding() {
    local severity="$1"
    local artifact="$2"
    local message="$3"

    local severity_display
    case "$severity" in
        error)   severity_display="error" ;;
        warning) severity_display="warning" ;;
        info)    severity_display="info" ;;
        *)       severity_display="$severity" ;;
    esac

    echo "| $severity_display | $artifact | $message |"
}

# Print findings table header
print_findings_header() {
    echo "| Severity | Artifact | Message |"
    echo "|----------|----------|---------|"
}

# Print a blocker entry
print_blocker() {
    local id="$1"
    local description="$2"
    local action="$3"

    echo "- **$id**: $description"
    echo "  - Suggested action: $action"
}

# Print a recommendation
print_recommendation() {
    local message="$1"
    echo "- $message"
}

# Print a check item (for release-check)
print_check_item() {
    local status="$1"
    local name="$2"
    local details="${3:-}"

    local icon
    case "$status" in
        pass) icon="[PASS]" ;;
        fail) icon="[FAIL]" ;;
        skip) icon="[SKIP]" ;;
        *)    icon="[ ? ]" ;;
    esac

    if [[ -n "$details" ]]; then
        echo "| $icon | $name | $details |"
    else
        echo "| $icon | $name | |"
    fi
}

# Print check items table header
print_check_table_header() {
    echo "| Status | Check | Details |"
    echo "|--------|-------|---------|"
}

# Print a progress bar (for progress-report)
print_progress_bar() {
    local completed="$1"
    local total="$2"
    local width="${3:-20}"

    if [[ "$total" -eq 0 ]]; then
        echo "[--------------------] 0%"
        return
    fi

    local percentage=$((completed * 100 / total))
    local filled=$((completed * width / total))
    local empty=$((width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=0; i<empty; i++)); do bar+="-"; done

    echo "[$bar] $percentage% ($completed/$total)"
}

# Print a summary line
print_summary() {
    local label="$1"
    local value="$2"
    echo "**$label**: $value"
}

# Print coverage metrics
print_coverage() {
    local label="$1"
    local implemented="$2"
    local total="$3"

    if [[ "$total" -eq 0 ]]; then
        echo "- **$label**: N/A (no items)"
        return
    fi

    local percentage=$((implemented * 100 / total))
    echo "- **$label**: $implemented/$total ($percentage%)"
}

# Print a table row
print_table_row() {
    local columns=("$@")
    local row="|"
    for col in "${columns[@]}"; do
        row+=" $col |"
    done
    echo "$row"
}

# Print an error message to stderr
print_error() {
    local message="$1"
    echo -e "${COLOR_RED}Error: $message${COLOR_NC}" >&2
}

# Print a warning message to stderr
print_warning() {
    local message="$1"
    echo -e "${COLOR_YELLOW}Warning: $message${COLOR_NC}" >&2
}

# Print an info message
print_info() {
    local message="$1"
    echo -e "${COLOR_BLUE}Info: $message${COLOR_NC}"
}
