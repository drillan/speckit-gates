#!/usr/bin/env bash
#
# build.sh - Bundle shared utilities into skill scripts
#
# This script embeds shared utilities (path-resolver.sh, output-format.sh,
# error-handler.sh) directly into each skill script, making them standalone
# and eliminating the need for shared/ directory at runtime.
#
# Usage:
#   ./scripts/build.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_DIR="$REPO_ROOT/skills/shared"
SKILLS_DIR="$REPO_ROOT/skills"

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

# Extract content from a shared utility file, skipping shebang and set -euo pipefail
extract_utility_content() {
    local file="$1"
    local in_header=true

    while IFS= read -r line; do
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
        echo "$line"
    done < "$file"
}

# Bundle a single skill script
bundle_skill() {
    local skill_script="$1"
    local skill_name
    skill_name=$(basename "$(dirname "$(dirname "$skill_script")")")

    log_info "Bundling $skill_name..."

    # Read the original script
    local original_content
    original_content=$(cat "$skill_script")

    # Check if already bundled
    if echo "$original_content" | grep -q "EMBEDDED UTILITIES"; then
        log_warn "  Already bundled, rebuilding..."
    fi

    # Create the bundled content
    local temp_file
    temp_file=$(mktemp)

    # Extract header (shebang and initial comments)
    local in_header=true
    local header=""
    local body=""
    local skip_source_block=false

    while IFS= read -r line; do
        # Detect source block start
        if [[ "$line" =~ ^SCRIPT_DIR= ]] || [[ "$line" =~ ^SHARED_DIR= ]]; then
            skip_source_block=true
            continue
        fi

        # Skip source statements
        if [[ "$line" =~ ^source.*shared ]]; then
            skip_source_block=false
            continue
        fi

        # Skip lines in source block
        if $skip_source_block; then
            continue
        fi

        # Skip embedded utilities block if rebuilding
        if [[ "$line" =~ "# ============================================================================" ]]; then
            if [[ "$line" =~ "EMBEDDED UTILITIES" ]] || echo "$original_content" | grep -q "EMBEDDED UTILITIES"; then
                # Skip until end marker
                while IFS= read -r skip_line; do
                    if [[ "$skip_line" =~ "END EMBEDDED UTILITIES" ]]; then
                        read -r skip_line  # Skip the closing ========= line
                        break
                    fi
                done
                continue
            fi
        fi

        # Separate header from body
        if $in_header; then
            if [[ "$line" =~ ^#!/ ]] || [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
                header+="$line"$'\n'
            else
                in_header=false
                body+="$line"$'\n'
            fi
        else
            body+="$line"$'\n'
        fi
    done <<< "$original_content"

    # Remove set -euo pipefail from body (will be after header)
    body=$(echo "$body" | sed '/^set -euo pipefail$/d')

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

    # Replace original with bundled version
    mv "$temp_file" "$skill_script"
    chmod +x "$skill_script"

    log_info "  Done: $skill_script"
}

# Main
main() {
    log_info "Starting build process..."
    log_info "Repository root: $REPO_ROOT"
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

    # Find all skill scripts
    local skill_scripts=(
        "$SKILLS_DIR/planning-validate/scripts/validate.sh"
        "$SKILLS_DIR/implementation-verify/scripts/verify.sh"
        "$SKILLS_DIR/docs-sync/scripts/sync.sh"
        "$SKILLS_DIR/progress-report/scripts/report.sh"
        "$SKILLS_DIR/release-check/scripts/check.sh"
    )

    for script in "${skill_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            bundle_skill "$script"
        else
            log_warn "Script not found: $script"
        fi
    done

    echo ""
    log_info "Build complete!"
    log_info "Run 'scripts/test-bundled.sh' to verify syntax."
}

main "$@"
