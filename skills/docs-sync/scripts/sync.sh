#!/usr/bin/env bash
#
# sync.sh - Documentation synchronization script
#
# Synchronizes README.md, CHANGELOG.md, and API docs with implementation.
# Preserves user content outside speckit markers.
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

# Results storage
declare -i FILES_CREATED=0
declare -i FILES_UPDATED=0
declare -i FILES_UNCHANGED=0
declare -i FILES_ERROR=0
declare -i LINES_ADDED=0
declare -i LINES_REMOVED=0

declare -a UPDATES=()
declare -a ERRORS_LIST=()

# Add an update record
add_update() {
    local file="$1"
    local status="$2"
    local sections="$3"
    UPDATES+=("$file|$status|$sections")
}

# Add an error record
add_error() {
    local file="$1"
    local message="$2"
    ERRORS_LIST+=("$file: $message")
}

# Extract feature summary from spec.md
get_feature_summary() {
    if [[ ! -f "$SPEC_FILE" ]]; then
        echo "Feature documentation"
        return
    fi

    local content
    content=$(cat "$SPEC_FILE")

    # Try to find summary section content
    local summary
    summary=$(echo "$content" | sed -n '/^##\s*Summary/,/^##/p' | head -10 | tail -n +2 | grep -v '^##' || true)

    if [[ -n "$summary" ]]; then
        echo "$summary" | head -3
    else
        # Fall back to first paragraph after title
        echo "$content" | sed -n '1,/^$/p' | tail -n +2 | head -3
    fi
}

# Extract completed tasks from tasks.md
get_completed_tasks() {
    if [[ ! -f "$TASKS_FILE" ]]; then
        return
    fi

    local content
    content=$(cat "$TASKS_FILE")

    # Get completed tasks
    echo "$content" | grep -E '^\s*-\s*\[[Xx]\]' | sed 's/^\s*-\s*\[[Xx]\]\s*/- /' | head -20
}

# Update a section in a file using markers (FR-020)
update_section() {
    local file="$1"
    local section="$2"
    local content="$3"

    local start_marker="<!-- speckit:start:$section -->"
    local end_marker="<!-- speckit:end:$section -->"

    if [[ ! -f "$file" ]]; then
        # File doesn't exist, create with markers
        {
            echo "$start_marker"
            echo "$content"
            echo "$end_marker"
        } > "$file"
        return 0
    fi

    local file_content
    file_content=$(cat "$file")

    if echo "$file_content" | grep -qF "$start_marker"; then
        # Markers exist, replace content between them
        local temp_file
        temp_file=$(mktemp)

        local in_section=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == *"$start_marker"* ]]; then
                echo "$line"
                echo "$content"
                in_section=1
            elif [[ "$line" == *"$end_marker"* ]]; then
                echo "$line"
                in_section=0
            elif [[ "$in_section" -eq 0 ]]; then
                echo "$line"
            fi
        done < "$file" > "$temp_file"

        mv "$temp_file" "$file"
    else
        # No markers, append at end
        {
            echo ""
            echo "$start_marker"
            echo "$content"
            echo "$end_marker"
        } >> "$file"
    fi

    return 0
}

# Update README.md usage section (FR-017)
update_readme() {
    local readme_file="$REPO_ROOT/README.md"

    if [[ ! -f "$readme_file" ]]; then
        add_update "README.md" "skipped" "file not found"
        return
    fi

    local original_lines
    original_lines=$(wc -l < "$readme_file")

    # Generate usage content from spec
    local usage_content=""
    if [[ -f "$SPEC_FILE" ]]; then
        local feature_branch
        feature_branch=$(get_feature_branch)
        usage_content="## Usage

This section is auto-generated from spec kit artifacts.

See the [specification](./specs/$feature_branch/spec.md) for detailed requirements."
    fi

    if [[ -n "$usage_content" ]]; then
        if update_section "$readme_file" "usage" "$usage_content"; then
            local new_lines
            new_lines=$(wc -l < "$readme_file")
            local diff=$((new_lines - original_lines))
            if [[ "$diff" -gt 0 ]]; then
                ((LINES_ADDED += diff)) || true
            elif [[ "$diff" -lt 0 ]]; then
                ((LINES_REMOVED += (-diff))) || true
            fi

            if [[ "$diff" -ne 0 ]]; then
                ((FILES_UPDATED++)) || true
                add_update "README.md" "updated" "usage"
            else
                ((FILES_UNCHANGED++)) || true
                add_update "README.md" "unchanged" ""
            fi
        else
            ((FILES_ERROR++)) || true
            add_error "README.md" "Failed to update usage section"
        fi
    else
        ((FILES_UNCHANGED++)) || true
        add_update "README.md" "unchanged" "no content to sync"
    fi
}

# Update CHANGELOG.md (FR-018)
update_changelog() {
    local changelog_file="$REPO_ROOT/CHANGELOG.md"

    if [[ ! -f "$changelog_file" ]]; then
        add_update "CHANGELOG.md" "skipped" "file not found"
        return
    fi

    local original_lines
    original_lines=$(wc -l < "$changelog_file")

    # Generate unreleased content from completed tasks
    local completed_tasks
    completed_tasks=$(get_completed_tasks)

    if [[ -n "$completed_tasks" ]]; then
        local unreleased_content="### Added

$completed_tasks"

        if update_section "$changelog_file" "unreleased" "$unreleased_content"; then
            local new_lines
            new_lines=$(wc -l < "$changelog_file")
            local diff=$((new_lines - original_lines))
            if [[ "$diff" -gt 0 ]]; then
                ((LINES_ADDED += diff)) || true
            elif [[ "$diff" -lt 0 ]]; then
                ((LINES_REMOVED += (-diff))) || true
            fi

            if [[ "$diff" -ne 0 ]]; then
                ((FILES_UPDATED++)) || true
                add_update "CHANGELOG.md" "updated" "unreleased"
            else
                ((FILES_UNCHANGED++)) || true
                add_update "CHANGELOG.md" "unchanged" ""
            fi
        else
            ((FILES_ERROR++)) || true
            add_error "CHANGELOG.md" "Failed to update unreleased section"
        fi
    else
        ((FILES_UNCHANGED++)) || true
        add_update "CHANGELOG.md" "unchanged" "no completed tasks"
    fi
}

# Update API documentation (FR-019)
update_api_docs() {
    if [[ ! -d "$CONTRACTS_DIR" ]]; then
        return
    fi

    local api_docs_file="$REPO_ROOT/docs/api.md"

    # Check if docs directory exists
    if [[ ! -d "$REPO_ROOT/docs" ]]; then
        return
    fi

    if [[ ! -f "$api_docs_file" ]]; then
        return
    fi

    local original_lines
    original_lines=$(wc -l < "$api_docs_file")

    # Generate API content from contracts
    local api_content="## API Reference

Auto-generated from contract specifications.

See [contracts/](./specs/$(get_feature_branch)/contracts/) for detailed API contracts."

    if update_section "$api_docs_file" "api" "$api_content"; then
        local new_lines
        new_lines=$(wc -l < "$api_docs_file")
        local diff=$((new_lines - original_lines))
        if [[ "$diff" -gt 0 ]]; then
            ((LINES_ADDED += diff)) || true
        elif [[ "$diff" -lt 0 ]]; then
            ((LINES_REMOVED += (-diff))) || true
        fi

        if [[ "$diff" -ne 0 ]]; then
            ((FILES_UPDATED++)) || true
            add_update "docs/api.md" "updated" "api"
        else
            ((FILES_UNCHANGED++)) || true
            add_update "docs/api.md" "unchanged" ""
        fi
    else
        ((FILES_ERROR++)) || true
        add_error "docs/api.md" "Failed to update api section"
    fi
}

# Output results (FR-021)
output_results() {
    local feature_branch
    feature_branch=$(get_feature_branch)
    local timestamp
    timestamp=$(get_timestamp)

    echo "## DocsSyncResult: docs-sync"
    echo ""
    echo "**Branch**: $feature_branch"
    echo "**Timestamp**: $timestamp"
    echo ""

    # Summary
    print_section "Summary"
    echo "- Files created: $FILES_CREATED"
    echo "- Files updated: $FILES_UPDATED"
    echo "- Files unchanged: $FILES_UNCHANGED"
    echo "- Errors: $FILES_ERROR"
    echo ""

    # Diff summary
    if [[ "$LINES_ADDED" -gt 0 ]] || [[ "$LINES_REMOVED" -gt 0 ]]; then
        print_section "Diff Summary"
        echo "- Lines added: $LINES_ADDED"
        echo "- Lines removed: $LINES_REMOVED"
        echo ""
    fi

    # Updates
    if [[ "${#UPDATES[@]}" -gt 0 ]]; then
        print_section "File Updates"
        echo "| File | Status | Sections Modified |"
        echo "|------|--------|-------------------|"
        for update in "${UPDATES[@]}"; do
            IFS='|' read -r file status sections <<< "$update"
            echo "| $file | $status | $sections |"
        done
        echo ""
    fi

    # Errors
    if [[ "${#ERRORS_LIST[@]}" -gt 0 ]]; then
        print_section "Errors"
        for error in "${ERRORS_LIST[@]}"; do
            echo "- $error"
        done
        echo ""
    fi
}

# Main execution
main() {
    # Resolve paths
    if ! resolve_paths; then
        exit_unexpected_error "Failed to resolve paths" "Ensure you are in a spec kit project"
    fi

    # Check for required files (FR-038)
    # docs-sync can work with partial files, so we just warn

    # Run all sync operations
    update_readme
    update_changelog
    update_api_docs

    # Output results
    output_results

    # Determine exit code
    if [[ "$FILES_ERROR" -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
