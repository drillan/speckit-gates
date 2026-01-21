#!/usr/bin/env bash
#
# check.sh - Release readiness check script
#
# Validates all artifacts are complete and consistent for release.
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

# Check results storage
declare -a ARTIFACT_CHECKS=()
declare -a DOC_CHECKS=()
declare -a VERSION_CHECKS=()
declare -a API_CHECKS=()

declare -i PASS_COUNT=0
declare -i FAIL_COUNT=0
declare -i SKIP_COUNT=0

# Version info
PACKAGE_VERSION=""
CHANGELOG_VERSION=""
VERSIONS_CONSISTENT=true

# Add a check result
add_check() {
    local category="$1"
    local status="$2"
    local name="$3"
    local details="${4:-}"

    case "$status" in
        pass) ((PASS_COUNT++)) || true ;;
        fail) ((FAIL_COUNT++)) || true ;;
        skip) ((SKIP_COUNT++)) || true ;;
    esac

    local entry="$status|$name|$details"
    case "$category" in
        artifacts) ARTIFACT_CHECKS+=("$entry") ;;
        documentation) DOC_CHECKS+=("$entry") ;;
        versioning) VERSION_CHECKS+=("$entry") ;;
        api) API_CHECKS+=("$entry") ;;
    esac
}

# Check spec kit artifacts (FR-022)
check_artifacts() {
    # spec.md
    if [[ -f "$SPEC_FILE" ]]; then
        add_check "artifacts" "pass" "spec.md exists"
    else
        add_check "artifacts" "fail" "spec.md exists" "File not found"
    fi

    # plan.md
    if [[ -f "$PLAN_FILE" ]]; then
        add_check "artifacts" "pass" "plan.md exists"
    else
        add_check "artifacts" "fail" "plan.md exists" "File not found"
    fi

    # tasks.md
    if [[ -f "$TASKS_FILE" ]]; then
        add_check "artifacts" "pass" "tasks.md exists"

        # Check if all tasks are complete
        local total_tasks completed_tasks
        total_tasks=$(grep -cE '^\s*-\s*\[[Xx ]\]' "$TASKS_FILE" || echo "0")
        completed_tasks=$(grep -cE '^\s*-\s*\[[Xx]\]' "$TASKS_FILE" || echo "0")

        if [[ "$total_tasks" -eq "$completed_tasks" ]]; then
            add_check "artifacts" "pass" "All tasks complete" "$completed_tasks/$total_tasks"
        else
            local remaining=$((total_tasks - completed_tasks))
            add_check "artifacts" "fail" "All tasks complete" "$remaining tasks remaining"
        fi
    else
        add_check "artifacts" "fail" "tasks.md exists" "File not found"
    fi
}

# Check README.md sections (FR-023)
check_readme() {
    local readme_file="$REPO_ROOT/README.md"

    if [[ ! -f "$readme_file" ]]; then
        add_check "documentation" "fail" "README.md exists" "File not found"
        return
    fi

    add_check "documentation" "pass" "README.md exists"

    local content
    content=$(cat "$readme_file")

    # Check for usage section
    if echo "$content" | grep -qiE '^##?\s*(Usage|Quick Start|Getting Started)'; then
        add_check "documentation" "pass" "README.md has usage section"
    else
        add_check "documentation" "fail" "README.md has usage section" "No Usage section found"
    fi

    # Check for installation section
    if echo "$content" | grep -qiE '^##?\s*Installation'; then
        add_check "documentation" "pass" "README.md has installation section"
    else
        add_check "documentation" "skip" "README.md has installation section" "Optional"
    fi
}

# Check CHANGELOG.md (FR-024)
check_changelog() {
    local changelog_file="$REPO_ROOT/CHANGELOG.md"

    if [[ ! -f "$changelog_file" ]]; then
        add_check "documentation" "fail" "CHANGELOG.md exists" "File not found"
        return
    fi

    add_check "documentation" "pass" "CHANGELOG.md exists"

    local content
    content=$(cat "$changelog_file")

    # Check for unreleased section
    if echo "$content" | grep -qiE '^\[?Unreleased\]?'; then
        add_check "documentation" "pass" "CHANGELOG.md has Unreleased section"
    else
        add_check "documentation" "skip" "CHANGELOG.md has Unreleased section" "May be released"
    fi

    # Extract latest version from CHANGELOG
    CHANGELOG_VERSION=$(echo "$content" | grep -oE '^\[?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | tr -d '[]' || true)
}

# Check version consistency (FR-026)
check_versions() {
    local package_file="$REPO_ROOT/package.json"

    # Get package.json version if exists
    if [[ -f "$package_file" ]]; then
        PACKAGE_VERSION=$(grep -oE '"version"\s*:\s*"[0-9]+\.[0-9]+\.[0-9]+"' "$package_file" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
        if [[ -n "$PACKAGE_VERSION" ]]; then
            add_check "versioning" "pass" "package.json version" "$PACKAGE_VERSION"
        else
            add_check "versioning" "skip" "package.json version" "No version field"
        fi
    else
        add_check "versioning" "skip" "package.json exists" "Not a Node.js project"
    fi

    # Check CHANGELOG version
    if [[ -n "$CHANGELOG_VERSION" ]]; then
        add_check "versioning" "pass" "CHANGELOG.md version" "$CHANGELOG_VERSION"
    else
        add_check "versioning" "skip" "CHANGELOG.md version" "No version found"
    fi

    # Check consistency
    if [[ -n "$PACKAGE_VERSION" ]] && [[ -n "$CHANGELOG_VERSION" ]]; then
        if [[ "$PACKAGE_VERSION" == "$CHANGELOG_VERSION" ]]; then
            add_check "versioning" "pass" "Version consistency" "Both $PACKAGE_VERSION"
            VERSIONS_CONSISTENT=true
        else
            add_check "versioning" "fail" "Version consistency" "package.json: $PACKAGE_VERSION, CHANGELOG: $CHANGELOG_VERSION"
            VERSIONS_CONSISTENT=false
        fi
    else
        add_check "versioning" "skip" "Version consistency" "Not enough versions to compare"
    fi
}

# Check API documentation (FR-025)
check_api_docs() {
    if [[ ! -d "$CONTRACTS_DIR" ]]; then
        add_check "api" "skip" "API contracts" "No contracts/ directory"
        return
    fi

    local contract_count
    contract_count=$(find "$CONTRACTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l)

    if [[ "$contract_count" -eq 0 ]]; then
        add_check "api" "skip" "API contracts" "No contract files"
        return
    fi

    add_check "api" "pass" "API contracts exist" "$contract_count file(s)"

    # Check for API documentation
    local api_docs_file="$REPO_ROOT/docs/api.md"
    if [[ -f "$api_docs_file" ]]; then
        add_check "api" "pass" "API documentation exists"
    else
        add_check "api" "skip" "API documentation" "docs/api.md not found"
    fi
}

# Print check category
print_check_category() {
    local title="$1"
    shift
    local checks=("$@")

    if [[ "${#checks[@]}" -eq 0 ]]; then
        return
    fi

    echo "### $title"
    echo ""
    print_check_table_header

    for check in "${checks[@]}"; do
        IFS='|' read -r status name details <<< "$check"
        print_check_item "$status" "$name" "$details"
    done
    echo ""
}

# Output checklist (FR-027)
output_checklist() {
    local feature_branch
    feature_branch=$(get_feature_branch)
    local timestamp
    timestamp=$(get_timestamp)

    local is_ready="Not Ready"
    if [[ "$FAIL_COUNT" -eq 0 ]]; then
        is_ready="Ready to Release"
    fi

    echo "## Release Checklist: release-check"
    echo ""
    echo "**Status**: $is_ready"
    echo "**Branch**: $feature_branch"
    echo "**Timestamp**: $timestamp"
    echo ""

    # Summary
    print_section "Summary"
    echo "- Passed: $PASS_COUNT"
    echo "- Failed: $FAIL_COUNT"
    echo "- Skipped: $SKIP_COUNT"
    echo ""

    # Print check categories
    print_check_category "Artifacts" "${ARTIFACT_CHECKS[@]}"
    print_check_category "Documentation" "${DOC_CHECKS[@]}"
    print_check_category "Versioning" "${VERSION_CHECKS[@]}"
    print_check_category "API" "${API_CHECKS[@]}"

    # Version info
    if [[ -n "$PACKAGE_VERSION" ]] || [[ -n "$CHANGELOG_VERSION" ]]; then
        print_section "Version Information"
        if [[ -n "$PACKAGE_VERSION" ]]; then
            echo "- package.json: $PACKAGE_VERSION"
        fi
        if [[ -n "$CHANGELOG_VERSION" ]]; then
            echo "- CHANGELOG.md: $CHANGELOG_VERSION"
        fi
        echo "- Consistent: $VERSIONS_CONSISTENT"
        echo ""
    fi
}

# Main execution
main() {
    # Resolve paths
    if ! resolve_paths; then
        exit_unexpected_error "Failed to resolve paths" "Ensure you are in a spec kit project"
    fi

    # Run all checks
    check_artifacts
    check_readme
    check_changelog
    check_versions
    check_api_docs

    # Output checklist
    output_checklist

    # Exit with appropriate code
    if [[ "$FAIL_COUNT" -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
