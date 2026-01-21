#!/usr/bin/env bash
#
# error-handler.sh - Shared error handling utilities for speckit-gates skills
#
# Exit Codes:
#   0 - Success (GREEN status for validation skills)
#   1 - Warnings present (YELLOW status) or partial success
#   2 - Errors present (RED status) or low fulfillment
#   3 - Fatal error (missing required files, unexpected errors)
#

# Exit codes as constants
readonly EXIT_SUCCESS=0
readonly EXIT_WARNING=1
readonly EXIT_ERROR=2
readonly EXIT_FATAL=3

# Global error tracking
declare -g ERROR_COUNT=0
declare -g WARNING_COUNT=0
declare -g ERRORS=()
declare -g WARNINGS=()

# Reset error state
reset_errors() {
    ERROR_COUNT=0
    WARNING_COUNT=0
    ERRORS=()
    WARNINGS=()
}

# Record an error
record_error() {
    local message="$1"
    ERRORS+=("$message")
    ((ERROR_COUNT++)) || true
}

# Record a warning
record_warning() {
    local message="$1"
    WARNINGS+=("$message")
    ((WARNING_COUNT++)) || true
}

# Get error count
get_error_count() {
    echo "$ERROR_COUNT"
}

# Get warning count
get_warning_count() {
    echo "$WARNING_COUNT"
}

# Determine exit code based on error/warning counts
determine_exit_code() {
    if [[ "$ERROR_COUNT" -gt 0 ]]; then
        echo "$EXIT_ERROR"
    elif [[ "$WARNING_COUNT" -gt 0 ]]; then
        echo "$EXIT_WARNING"
    else
        echo "$EXIT_SUCCESS"
    fi
}

# Determine status based on error/warning counts
determine_status() {
    if [[ "$ERROR_COUNT" -gt 0 ]]; then
        echo "RED"
    elif [[ "$WARNING_COUNT" -gt 0 ]]; then
        echo "YELLOW"
    else
        echo "GREEN"
    fi
}

# Exit with error for missing required file
exit_missing_file() {
    local file="$1"
    local name="${2:-$file}"

    echo ""
    echo "## Error: Required File Missing"
    echo ""
    echo "**File**: $name"
    echo "**Path**: $file"
    echo ""
    echo "### Suggested Actions"
    echo ""
    echo "1. Ensure you have run the prerequisite spec kit commands"
    echo "2. Check that you are in the correct feature directory"
    echo "3. Verify the file exists at the expected path"
    echo ""

    exit "$EXIT_FATAL"
}

# Exit with error for unexpected error
exit_unexpected_error() {
    local message="$1"
    local details="${2:-}"

    echo ""
    echo "## Error: Unexpected Error"
    echo ""
    echo "**Message**: $message"
    if [[ -n "$details" ]]; then
        echo "**Details**: $details"
    fi
    echo ""
    echo "### Suggested Actions"
    echo ""
    echo "1. Check the error message for hints"
    echo "2. Verify your environment is correctly configured"
    echo "3. Report the issue if the problem persists"
    echo ""

    exit "$EXIT_FATAL"
}

# Print all recorded errors
print_errors() {
    if [[ "${#ERRORS[@]}" -eq 0 ]]; then
        return
    fi

    echo "### Errors"
    echo ""
    for error in "${ERRORS[@]}"; do
        echo "- $error"
    done
    echo ""
}

# Print all recorded warnings
print_warnings() {
    if [[ "${#WARNINGS[@]}" -eq 0 ]]; then
        return
    fi

    echo "### Warnings"
    echo ""
    for warning in "${WARNINGS[@]}"; do
        echo "- $warning"
    done
    echo ""
}

# Trap handler for unexpected script termination
handle_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]] && [[ $exit_code -ne "$EXIT_WARNING" ]] && [[ $exit_code -ne "$EXIT_ERROR" ]]; then
        echo ""
        echo "## Skill Terminated Unexpectedly"
        echo ""
        echo "Exit code: $exit_code"
        echo ""
    fi
}

# Set up exit trap
setup_error_trap() {
    trap handle_exit EXIT
}

# Validate that a command exists
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        exit_unexpected_error "Required command not found: $cmd" "Please install $cmd and try again."
    fi
}
