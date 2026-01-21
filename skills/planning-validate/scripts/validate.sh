#!/usr/bin/env bash
#
# validate.sh - Planning artifacts validation script
#
# Validates spec.md, plan.md, data-model.md, and contracts/ for quality,
# completeness, and consistency.
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

# Findings storage
declare -a FINDINGS=()
declare -a BLOCKERS=()
declare -a RECOMMENDATIONS=()

# Add a finding
add_finding() {
    local severity="$1"
    local artifact="$2"
    local message="$3"
    FINDINGS+=("$severity|$artifact|$message")

    if [[ "$severity" == "error" ]]; then
        record_error "$artifact: $message"
    elif [[ "$severity" == "warning" ]]; then
        record_warning "$artifact: $message"
    fi
}

# Add a blocker
add_blocker() {
    local id="$1"
    local description="$2"
    local action="$3"
    BLOCKERS+=("$id|$description|$action")
}

# Add a recommendation
add_recommendation() {
    local message="$1"
    RECOMMENDATIONS+=("$message")
}

# Check spec.md completeness (FR-002)
check_spec_completeness() {
    if [[ ! -f "$SPEC_FILE" ]]; then
        add_finding "error" "spec.md" "File not found"
        add_blocker "BLK-001" "spec.md is missing" "Run /speckit.specify to create specification"
        return
    fi

    local content
    content=$(cat "$SPEC_FILE")

    # Check for Summary/Overview section
    if ! echo "$content" | grep -qiE '^##?\s*(Summary|Overview)'; then
        add_finding "warning" "spec.md" "Missing Summary/Overview section"
        add_recommendation "Add a Summary section to spec.md"
    else
        add_finding "info" "spec.md" "Summary section present"
    fi

    # Check for User Stories section
    if ! echo "$content" | grep -qiE '^##?\s*User Stor(y|ies)'; then
        add_finding "error" "spec.md" "Missing User Stories section"
        add_blocker "BLK-002" "spec.md lacks User Stories" "Add User Stories section with at least one story"
    else
        # Check for at least one user story
        local story_count
        story_count=$(echo "$content" | grep -cE '^\s*-\s*(As a|As an)' || echo "0")
        if [[ "$story_count" -eq 0 ]]; then
            story_count=$(echo "$content" | grep -cE '^###\s+US[0-9]+' || echo "0")
        fi
        if [[ "$story_count" -eq 0 ]]; then
            add_finding "warning" "spec.md" "User Stories section exists but no stories found"
        else
            add_finding "info" "spec.md" "Found $story_count user stor(y|ies)"
        fi
    fi

    # Check for Functional Requirements section
    if ! echo "$content" | grep -qiE '^##?\s*Functional Requirements'; then
        add_finding "error" "spec.md" "Missing Functional Requirements section"
        add_blocker "BLK-003" "spec.md lacks Functional Requirements" "Add Functional Requirements section with FR-XXX items"
    else
        # Check for FR-XXX items
        local fr_count
        fr_count=$(echo "$content" | grep -cE 'FR-[0-9]+' || echo "0")
        if [[ "$fr_count" -eq 0 ]]; then
            add_finding "warning" "spec.md" "Functional Requirements section has no FR-XXX items"
        else
            add_finding "info" "spec.md" "Found $fr_count functional requirement references"
        fi
    fi

    # Check for Success Criteria section
    if ! echo "$content" | grep -qiE '^##?\s*Success Criteria'; then
        add_finding "warning" "spec.md" "Missing Success Criteria section"
        add_recommendation "Add Success Criteria section with measurable outcomes"
    else
        add_finding "info" "spec.md" "Success Criteria section present"
    fi
}

# Check plan.md executability (FR-003)
check_plan_executability() {
    if [[ ! -f "$PLAN_FILE" ]]; then
        add_finding "error" "plan.md" "File not found"
        add_blocker "BLK-004" "plan.md is missing" "Run /speckit.plan to create implementation plan"
        return
    fi

    local content
    content=$(cat "$PLAN_FILE")

    # Check for Technical Context section
    if ! echo "$content" | grep -qiE '^##?\s*Technical Context'; then
        add_finding "error" "plan.md" "Missing Technical Context section"
        add_blocker "BLK-005" "plan.md lacks Technical Context" "Ensure /speckit.plan completes successfully"
    else
        add_finding "info" "plan.md" "Technical Context section present"
    fi

    # Check for Project Structure section
    if ! echo "$content" | grep -qiE '^##?\s*Project Structure'; then
        add_finding "warning" "plan.md" "Missing Project Structure section"
        add_recommendation "Add Project Structure section showing file organization"
    else
        add_finding "info" "plan.md" "Project Structure section present"
    fi

    # Check for Constitution Check section
    if echo "$content" | grep -qiE '^##?\s*Constitution Check'; then
        add_finding "info" "plan.md" "Constitution Check section present"

        # Check for Gate Result
        if echo "$content" | grep -qE 'Gate Result.*PASS'; then
            add_finding "info" "plan.md" "Constitution gate passed"
        elif echo "$content" | grep -qE 'Gate Result.*FAIL'; then
            add_finding "error" "plan.md" "Constitution gate failed"
            add_blocker "BLK-006" "Constitution check failed in plan.md" "Review and fix constitution violations"
        fi
    fi
}

# Check data-model.md consistency (FR-004)
check_data_model_consistency() {
    if [[ ! -f "$DATA_MODEL_FILE" ]]; then
        add_finding "info" "data-model.md" "File not present (optional)"
        return
    fi

    local content
    content=$(cat "$DATA_MODEL_FILE")

    # Check for Entities section
    if ! echo "$content" | grep -qiE '^##?\s*Entities'; then
        add_finding "warning" "data-model.md" "Missing Entities section"
        add_recommendation "Add Entities section defining data structures"
    else
        add_finding "info" "data-model.md" "Entities section present"
    fi

    # Check for at least one entity (interface or type definition)
    local entity_count
    entity_count=$(echo "$content" | grep -cE '^###\s+[0-9]+\.\s+' || echo "0")
    if [[ "$entity_count" -eq 0 ]]; then
        entity_count=$(echo "$content" | grep -cE 'interface\s+\w+' || echo "0")
    fi

    if [[ "$entity_count" -eq 0 ]]; then
        add_finding "warning" "data-model.md" "No entities defined"
    else
        add_finding "info" "data-model.md" "Found $entity_count entit(y|ies) defined"
    fi
}

# Check contract coverage (FR-005)
check_contract_coverage() {
    if [[ ! -d "$CONTRACTS_DIR" ]]; then
        add_finding "info" "contracts/" "Directory not present (optional)"
        return
    fi

    local contract_count
    contract_count=$(find "$CONTRACTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l)

    if [[ "$contract_count" -eq 0 ]]; then
        add_finding "warning" "contracts/" "Directory exists but no contract files found"
        add_recommendation "Add contract files to contracts/ directory"
    else
        add_finding "info" "contracts/" "Found $contract_count contract file(s)"
    fi
}

# Check constitution compliance (FR-006, FR-041)
check_constitution_compliance() {
    if [[ ! -f "$CONSTITUTION_FILE" ]]; then
        add_finding "info" "constitution.md" "File not present - skipping constitution checks"
        add_recommendation "Consider creating a constitution.md for project-wide standards"
        return
    fi

    add_finding "info" "constitution.md" "Constitution file present"

    # Check if plan.md references constitution principles
    if [[ -f "$PLAN_FILE" ]]; then
        local plan_content
        plan_content=$(cat "$PLAN_FILE")

        if echo "$plan_content" | grep -qiE 'constitution'; then
            add_finding "info" "plan.md" "References constitution principles"
        else
            add_finding "warning" "plan.md" "Does not explicitly reference constitution"
            add_recommendation "Ensure plan.md includes Constitution Check section"
        fi
    fi
}

# Output results
output_results() {
    local status
    status=$(determine_status)
    local feature_branch
    feature_branch=$(get_feature_branch)

    print_header "planning-validate" "$feature_branch" "$status"

    # Print findings
    if [[ ${#FINDINGS[@]} -gt 0 ]]; then
        print_section "Findings"
        print_findings_header
        for finding in "${FINDINGS[@]}"; do
            IFS='|' read -r severity artifact message <<< "$finding"
            print_finding "$severity" "$artifact" "$message"
        done
        echo ""
    fi

    # Print blockers
    if [[ ${#BLOCKERS[@]} -gt 0 ]]; then
        print_section "Blockers"
        for blocker in "${BLOCKERS[@]}"; do
            IFS='|' read -r id description action <<< "$blocker"
            print_blocker "$id" "$description" "$action"
        done
        echo ""
    else
        print_section "Blockers"
        echo "None"
        echo ""
    fi

    # Print recommendations
    if [[ ${#RECOMMENDATIONS[@]} -gt 0 ]]; then
        print_section "Recommendations"
        for rec in "${RECOMMENDATIONS[@]}"; do
            print_recommendation "$rec"
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

    # Check for required files (FR-038, FR-039)
    if [[ ! -f "$SPEC_FILE" ]] && [[ ! -f "$PLAN_FILE" ]]; then
        exit_missing_file "$SPEC_FILE" "spec.md (and plan.md also missing)"
    fi

    # Run all checks
    check_spec_completeness
    check_plan_executability
    check_data_model_consistency
    check_contract_coverage
    check_constitution_compliance

    # Output results
    output_results

    # Exit with appropriate code
    exit "$(determine_exit_code)"
}

main "$@"
