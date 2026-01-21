# Skills Interface Contract: Speckit Gates

**Feature Branch**: `001-speckit-gates-skills`
**Date**: 2026-01-21

## Overview

This document defines the interface contract for speckit-gates skills. Since these are AI agent skills (not REST APIs), the contract describes the SKILL.md structure, invocation patterns, and output formats.

## Skill Registry

| Skill Name | Type | Trigger | Output Entity |
|------------|------|---------|---------------|
| planning-validate | Automatic | After `/speckit.plan` | QualityAssessment |
| implementation-verify | Automatic | After `/speckit.implement` | FulfillmentReport |
| docs-sync | Automatic | After `/speckit.implement` | DocsSyncResult |
| progress-report | Manual | User request | ProgressDashboard |
| release-check | Manual | User request | ReleaseChecklist |

## SKILL.md Interface Specifications

### 1. planning-validate

```yaml
---
name: planning-validate
description: >
  Validates planning artifacts (spec.md, plan.md, data-model.md) for quality,
  completeness, and consistency. Always run after /speckit.plan completes.
version: 1.0.0
compatibility: Requires spec kit with check-prerequisites.sh
metadata:
  author: drillan
  category: quality-gate
---
```

**Inputs** (read from filesystem):
- `spec.md` - Feature specification (required)
- `plan.md` - Implementation plan (required)
- `data-model.md` - Data model definitions (optional)
- `contracts/` - API contracts directory (optional)
- `constitution.md` - Project constitution (optional, skip checks if missing)

**Output**: QualityAssessment (markdown format to stdout)

**Exit Codes**:
- 0: GREEN status (all checks pass)
- 1: YELLOW status (warnings present)
- 2: RED status (blockers present)
- 3: Error (required files missing)

### 2. implementation-verify

```yaml
---
name: implementation-verify
description: >
  Verifies implementation against specifications by checking requirement
  fulfillment, task completion, and contract implementation.
  Always run after /speckit.implement completes.
version: 1.0.0
compatibility: Requires spec kit with check-prerequisites.sh, tasks.md must exist
metadata:
  author: drillan
  category: quality-gate
---
```

**Inputs** (read from filesystem):
- `spec.md` - Feature specification (required)
- `tasks.md` - Task list (required)
- `contracts/` - API contracts (optional)
- Source code files (for verification)

**Output**: FulfillmentReport (markdown format to stdout)

**Exit Codes**:
- 0: 100% fulfillment
- 1: Partial fulfillment (>80%)
- 2: Low fulfillment (<80%)
- 3: Error (required files missing)

### 3. docs-sync

```yaml
---
name: docs-sync
description: >
  Synchronizes documentation (README.md, CHANGELOG.md, API docs) with
  implementation. Preserves user content outside speckit markers.
  Always run after /speckit.implement completes.
version: 1.0.0
compatibility: Requires spec kit artifacts
metadata:
  author: drillan
  category: automation
---
```

**Inputs** (read from filesystem):
- `spec.md` - Feature specification
- `tasks.md` - Task list
- `README.md` - Project readme (creates if missing)
- `CHANGELOG.md` - Change log (creates if missing)

**Output**: DocsSyncResult (markdown format to stdout)

**Exit Codes**:
- 0: All updates successful
- 1: Some updates failed
- 3: Error (required files missing)

**Marker Format**:
```markdown
<!-- speckit:start:section-name -->
Auto-generated content here
<!-- speckit:end:section-name -->
```

### 4. progress-report

```yaml
---
name: progress-report
description: >
  Displays progress dashboard showing phase completion, blocked tasks,
  and remaining work estimate. Run anytime to check progress.
version: 1.0.0
compatibility: Requires tasks.md
metadata:
  author: drillan
  category: reporting
---
```

**Inputs** (read from filesystem):
- `tasks.md` - Task list (required)
- Source files (for potentially-complete detection)

**Output**: ProgressDashboard (markdown format to stdout)

**Exit Codes**:
- 0: Success
- 3: Error (tasks.md missing)

### 5. release-check

```yaml
---
name: release-check
description: >
  Validates all artifacts are complete and consistent for release.
  Run before creating a release to ensure nothing is missing.
version: 1.0.0
compatibility: Requires spec kit artifacts
metadata:
  author: drillan
  category: quality-gate
---
```

**Inputs** (read from filesystem):
- `spec.md` - Feature specification
- `plan.md` - Implementation plan
- `tasks.md` - Task list
- `README.md` - Project readme
- `CHANGELOG.md` - Change log
- `package.json` - Package manifest (optional)
- API documentation files (optional)

**Output**: ReleaseChecklist (markdown format to stdout)

**Exit Codes**:
- 0: Ready to release
- 1: Not ready (checks failed)
- 3: Error (required files missing)

## Common Patterns

### Path Resolution

All skills use spec kit's `check-prerequisites.sh --json` for path resolution:

```bash
# Get paths
eval "$(check-prerequisites.sh --paths-only)"

# Access paths
echo "$FEATURE_SPEC"    # spec.md path
echo "$IMPL_PLAN"       # plan.md path
echo "$TASKS"           # tasks.md path
echo "$FEATURE_DIR"     # Feature directory
```

### Error Handling

All skills follow consistent error handling:

1. **Missing required artifact**: Exit code 3, output guidance on what's missing
2. **Validation warnings**: Continue execution, include in output
3. **Validation errors**: Continue execution but report as blockers
4. **Unexpected errors**: Exit code 3 with error message

### Output Format

All skills output markdown to stdout for display in terminal:

```markdown
## [Skill Name]: [Feature Branch]

**Status**: [Status indicator]
**Timestamp**: [ISO 8601]

### [Section 1]

[Content]

### [Section 2]

[Content]
```

## Invocation Examples

### Manual invocation

```bash
# Run progress report
npx skills run progress-report

# Run release check
npx skills run release-check
```

### Automatic invocation

AI agents recognize "Always run after..." pattern and invoke automatically:

```
User: /speckit.plan
Agent: [executes /speckit.plan]
Agent: [recognizes planning-validate should run]
Agent: [executes planning-validate]
Agent: [displays QualityAssessment output]
```
