#!/usr/bin/env bash
#
# path-resolver.sh - Shared path resolution utilities for speckit-gates skills
#
# Usage:
#   source path-resolver.sh
#   resolve_paths  # Sets FEATURE_DIR, SPEC_FILE, PLAN_FILE, etc.
#

set -euo pipefail

# Colors for output (using COLOR_* naming convention)
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_NC='\033[0m' # No Color

# Find the repository root by looking for .git or .specify
find_repo_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]] || [[ -d "$dir/.specify" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Resolve all paths using check-prerequisites.sh
resolve_paths() {
    local repo_root
    repo_root="$(find_repo_root)" || {
        echo -e "${COLOR_RED}Error: Could not find repository root${COLOR_NC}" >&2
        return 1
    }

    local prereq_script="$repo_root/.specify/scripts/bash/check-prerequisites.sh"

    if [[ ! -f "$prereq_script" ]]; then
        echo -e "${COLOR_RED}Error: check-prerequisites.sh not found at $prereq_script${COLOR_NC}" >&2
        return 1
    fi

    # Run check-prerequisites.sh --json and parse output
    local json_output
    json_output=$("$prereq_script" --json 2>/dev/null) || {
        echo -e "${COLOR_RED}Error: Failed to run check-prerequisites.sh${COLOR_NC}" >&2
        return 1
    }

    # Extract FEATURE_DIR from JSON
    FEATURE_DIR=$(echo "$json_output" | grep -o '"FEATURE_DIR":"[^"]*"' | cut -d'"' -f4)

    if [[ -z "$FEATURE_DIR" ]]; then
        echo -e "${COLOR_RED}Error: Could not determine FEATURE_DIR${COLOR_NC}" >&2
        return 1
    fi

    # Set standard paths
    REPO_ROOT="$repo_root"
    SPEC_FILE="$FEATURE_DIR/spec.md"
    PLAN_FILE="$FEATURE_DIR/plan.md"
    TASKS_FILE="$FEATURE_DIR/tasks.md"
    DATA_MODEL_FILE="$FEATURE_DIR/data-model.md"
    RESEARCH_FILE="$FEATURE_DIR/research.md"
    QUICKSTART_FILE="$FEATURE_DIR/quickstart.md"
    CONTRACTS_DIR="$FEATURE_DIR/contracts"
    CONSTITUTION_FILE="$repo_root/constitution.md"

    # Export for subshells
    export REPO_ROOT FEATURE_DIR SPEC_FILE PLAN_FILE TASKS_FILE
    export DATA_MODEL_FILE RESEARCH_FILE QUICKSTART_FILE CONTRACTS_DIR
    export CONSTITUTION_FILE

    return 0
}

# Check if a required file exists
require_file() {
    local file="$1"
    local name="${2:-$file}"

    if [[ ! -f "$file" ]]; then
        echo -e "${COLOR_RED}Error: Required file missing: $name${COLOR_NC}" >&2
        echo "Path: $file" >&2
        return 1
    fi
    return 0
}

# Check if an optional file exists (returns success either way)
check_optional_file() {
    local file="$1"
    [[ -f "$file" ]]
}

# Get the feature branch name from FEATURE_DIR
get_feature_branch() {
    if [[ -n "${FEATURE_DIR:-}" ]]; then
        basename "$FEATURE_DIR"
    else
        echo "unknown"
    fi
}

# Get current timestamp in ISO 8601 format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}
