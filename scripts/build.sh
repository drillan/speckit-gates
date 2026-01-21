#!/usr/bin/env bash
#
# build.sh - Bundle shared utilities into skill scripts
#
# This script embeds shared utilities (path-resolver.sh, output-format.sh,
# error-handler.sh) directly into each skill script, making them standalone
# and eliminating the need for shared/ directory at runtime.
#
# Architecture:
#   - skills/       : Source scripts with source statements (unchanged)
#   - .claude/skills/: Bundled scripts with embedded utilities (generated)
#
# Usage:
#   ./scripts/build.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_DIR="$REPO_ROOT/skills/shared"
SOURCE_SKILLS_DIR="$REPO_ROOT/skills"
OUTPUT_SKILLS_DIR="$REPO_ROOT/.claude/skills"

# Colors for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_NC='\033[0m'

log_info() {
    echo -e "${COLOR_GREEN}[INFO]${COLOR_NC} $1"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1" >&2
}

# Track which variables have been declared to avoid duplicates
declare -A DECLARED_VARS=()

# Extract content from a shared utility file, skipping shebang and set -euo pipefail
# Also handles duplicate readonly declarations using guard patterns
extract_utility_content() {
    local file="$1"
    local in_header=true

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip shebang
        if [[ "$line" =~ ^#!/ ]]; then
            continue
        fi
        # Skip set -euo pipefail (already in main script)
        if [[ "$line" =~ ^set\ -euo\ pipefail ]]; then
            continue
        fi
        # Skip empty lines at the start
        if $in_header && [[ -z "$line" ]]; then
            continue
        fi
        in_header=false

        # Handle readonly declarations - use guard pattern to avoid duplicates
        if [[ "$line" =~ ^readonly\ ([A-Z_]+)= ]]; then
            local var_name="${BASH_REMATCH[1]}"
            if [[ -n "${DECLARED_VARS[$var_name]:-}" ]]; then
                # Variable already declared, skip this line
                continue
            fi
            DECLARED_VARS[$var_name]=1
        fi

        echo "$line"
    done < "$file"
}

# Bundle a single skill script
# Reads from SOURCE_SKILLS_DIR, writes to OUTPUT_SKILLS_DIR
bundle_skill() {
    local skill_name="$1"
    local source_script="$SOURCE_SKILLS_DIR/$skill_name/scripts/"*.sh
    local output_dir="$OUTPUT_SKILLS_DIR/$skill_name/scripts"

    # Expand glob
    source_script=$(echo $source_script)

    if [[ ! -f "$source_script" ]]; then
        log_error "Source script not found: $source_script"
        return 1
    fi

    local script_basename
    script_basename=$(basename "$source_script")
    local output_script="$output_dir/$script_basename"

    log_info "Bundling $skill_name..."
    log_info "  Source: $source_script"
    log_info "  Output: $output_script"

    # Reset declared variables tracker for each skill
    DECLARED_VARS=()

    # Create output directory
    mkdir -p "$output_dir"

    # Create temp file
    local temp_file
    temp_file=$(mktemp) || {
        log_error "Failed to create temp file"
        return 1
    }

    # Read source script content
    local source_content
    source_content=$(cat "$source_script")

    # Extract header (shebang and initial comments before set -euo pipefail or code)
    local header=""
    local body=""
    local in_header=true
    local skip_source_block=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip source block (SCRIPT_DIR, SHARED_DIR, source statements)
        if [[ "$line" =~ ^SCRIPT_DIR= ]] || [[ "$line" =~ ^SHARED_DIR= ]]; then
            skip_source_block=true
            continue
        fi

        # End of source block after last source statement
        if $skip_source_block && [[ "$line" =~ ^source ]]; then
            continue
        fi

        # Empty line after source statements ends the source block
        if $skip_source_block && [[ -z "$line" ]]; then
            skip_source_block=false
            continue
        fi

        # If still in source block but not a source line, end the block
        if $skip_source_block && [[ ! "$line" =~ ^source ]]; then
            skip_source_block=false
            # Don't continue - process this line
        fi

        # Separate header from body
        if $in_header; then
            if [[ "$line" =~ ^#!/ ]] || [[ "$line" =~ ^#\  ]] || [[ "$line" =~ ^#$ ]] || [[ -z "$line" ]]; then
                header+="$line"$'\n'
            elif [[ "$line" =~ ^set\ -euo\ pipefail ]]; then
                # Skip set -euo pipefail from header, will add it later
                in_header=false
            else
                in_header=false
                body+="$line"$'\n'
            fi
        else
            body+="$line"$'\n'
        fi
    done <<< "$source_content"

    # Write bundled file
    {
        # Write header (shebang and comments)
        printf "%s" "$header"

        # Add set -euo pipefail
        echo "set -euo pipefail"
        echo ""

        # Embedded utilities marker
        echo "# ============================================================================"
        echo "# EMBEDDED UTILITIES - DO NOT EDIT (regenerate with scripts/build.sh)"
        echo "# ============================================================================"
        echo ""

        # Embed path-resolver.sh
        echo "# --- path-resolver.sh ---"
        extract_utility_content "$SHARED_DIR/path-resolver.sh"
        echo ""

        # Embed output-format.sh
        echo "# --- output-format.sh ---"
        extract_utility_content "$SHARED_DIR/output-format.sh"
        echo ""

        # Embed error-handler.sh
        echo "# --- error-handler.sh ---"
        extract_utility_content "$SHARED_DIR/error-handler.sh"
        echo ""

        echo "# ============================================================================"
        echo "# END EMBEDDED UTILITIES"
        echo "# ============================================================================"
        echo ""

        # Write the rest of the script body
        printf "%s" "$body"
    } > "$temp_file"

    # Validate the bundled file has content
    if [[ ! -s "$temp_file" ]]; then
        log_error "Bundling failed: output file is empty for $skill_name"
        rm -f "$temp_file"
        return 1
    fi

    # Validate the bundled file has valid bash syntax
    if ! bash -n "$temp_file" 2>/dev/null; then
        log_error "Bundling produced invalid bash syntax for $skill_name"
        log_error "Temp file: $temp_file (not deleted for debugging)"
        return 1
    fi

    # Verify the bundled file contains a main function
    if ! grep -q "^main()" "$temp_file" && ! grep -q "^main ()" "$temp_file"; then
        log_error "Bundling failed: no main() function found in $skill_name"
        log_error "Temp file: $temp_file (not deleted for debugging)"
        return 1
    fi

    # Move to output location
    mv "$temp_file" "$output_script"
    chmod +x "$output_script"

    log_info "  Done: $output_script"
    return 0
}

# Copy SKILL.md files to output directory
copy_skill_manifest() {
    local skill_name="$1"
    local source_manifest="$SOURCE_SKILLS_DIR/$skill_name/SKILL.md"
    local output_dir="$OUTPUT_SKILLS_DIR/$skill_name"

    if [[ -f "$source_manifest" ]]; then
        mkdir -p "$output_dir"
        cp "$source_manifest" "$output_dir/SKILL.md"
        log_info "  Copied SKILL.md"
    else
        log_warn "  No SKILL.md found"
    fi
}

# Main
main() {
    log_info "Starting build process..."
    log_info "Repository root: $REPO_ROOT"
    log_info "Source: $SOURCE_SKILLS_DIR"
    log_info "Output: $OUTPUT_SKILLS_DIR"
    echo ""

    # Verify shared files exist
    local shared_files=(
        "$SHARED_DIR/path-resolver.sh"
        "$SHARED_DIR/output-format.sh"
        "$SHARED_DIR/error-handler.sh"
    )

    for file in "${shared_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Missing shared utility: $file"
            exit 1
        fi
    done

    # Create output directory
    mkdir -p "$OUTPUT_SKILLS_DIR"

    # List of skills to bundle
    local skills=(
        "planning-validate"
        "implementation-verify"
        "docs-sync"
        "progress-report"
        "release-check"
    )

    local failed=0
    for skill in "${skills[@]}"; do
        if ! bundle_skill "$skill"; then
            ((failed++)) || true
        fi
        copy_skill_manifest "$skill"
        echo ""
    done

    if [[ "$failed" -gt 0 ]]; then
        log_error "Build failed: $failed skill(s) failed to bundle"
        exit 1
    fi

    log_info "Build complete!"
    log_info "Run 'scripts/test-bundled.sh' to verify syntax."
}

main "$@"
