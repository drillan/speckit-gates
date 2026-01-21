#!/usr/bin/env bash
#
# test-bundled.sh - Verify bundled skill scripts have valid syntax
#
# Tests the bundled scripts in skills/ directory.
#
# Usage:
#   ./scripts/test-bundled.sh
#
# Exit Codes:
#   0 - All bundled scripts pass syntax check
#   1 - One or more scripts have syntax errors
#   2 - Scripts not found (run build.sh first)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
BUNDLED_SKILLS_DIR="$REPO_ROOT/skills"

# Colors for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_NC='\033[0m'

log_pass() {
    echo -e "${COLOR_GREEN}[PASS]${COLOR_NC} $1"
}

log_fail() {
    echo -e "${COLOR_RED}[FAIL]${COLOR_NC} $1"
}

log_info() {
    echo -e "${COLOR_YELLOW}[INFO]${COLOR_NC} $1"
}

# Test a single script
test_script() {
    local script="$1"
    local name
    name=$(basename "$(dirname "$(dirname "$script")")")/$(basename "$script")

    if bash -n "$script" 2>/dev/null; then
        log_pass "$name"
        return 0
    else
        log_fail "$name"
        echo "  Syntax errors:"
        bash -n "$script" 2>&1 | sed 's/^/    /'
        return 1
    fi
}

# Check if embedded utilities marker exists
check_embedded() {
    local script="$1"
    local name
    name=$(basename "$(dirname "$(dirname "$script")")")/$(basename "$script")

    if grep -q "EMBEDDED UTILITIES" "$script"; then
        return 0
    else
        log_info "$name: Not bundled (still uses source)"
        return 1
    fi
}

# Main
main() {
    echo "Testing bundled skill scripts in skills/..."
    echo ""

    # Check if bundled directory exists
    if [[ ! -d "$BUNDLED_SKILLS_DIR" ]]; then
        log_fail "Bundled skills directory not found: $BUNDLED_SKILLS_DIR"
        echo ""
        echo "Run 'scripts/build.sh' first to generate bundled scripts."
        exit 2
    fi

    local skill_scripts=(
        "$BUNDLED_SKILLS_DIR/planning-validate/scripts/validate.sh"
        "$BUNDLED_SKILLS_DIR/implementation-verify/scripts/verify.sh"
        "$BUNDLED_SKILLS_DIR/docs-sync/scripts/sync.sh"
        "$BUNDLED_SKILLS_DIR/progress-report/scripts/report.sh"
        "$BUNDLED_SKILLS_DIR/release-check/scripts/check.sh"
    )

    local pass_count=0
    local fail_count=0
    local missing_count=0

    for script in "${skill_scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            log_fail "$(basename "$script"): File not found"
            ((missing_count++)) || true
            continue
        fi

        if ! check_embedded "$script"; then
            log_fail "$(basename "$script"): Not properly bundled"
            ((fail_count++)) || true
            continue
        fi

        if test_script "$script"; then
            ((pass_count++)) || true
        else
            ((fail_count++)) || true
        fi
    done

    echo ""
    echo "========================================="
    echo "Results: $pass_count passed, $fail_count failed, $missing_count missing"
    echo "========================================="

    if [[ "$fail_count" -gt 0 ]]; then
        exit 1
    fi

    if [[ "$missing_count" -gt 0 ]]; then
        echo ""
        echo "Note: Some scripts are missing. Run 'scripts/build.sh' to regenerate."
        exit 2
    fi

    echo ""
    log_pass "All bundled scripts have valid syntax!"
}

main "$@"
