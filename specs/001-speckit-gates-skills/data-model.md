# Data Model: Speckit Gates Quality Gate Skills Package

**Feature Branch**: `001-speckit-gates-skills`
**Date**: 2026-01-21

## Overview

This document defines the data structures used by the speckit-gates quality gate skills. Since this is a file-based skills package (no database), entities represent the structured output formats of each skill.

## Entities

### 1. Quality Assessment

**Description**: Output of validation skills (planning-validate, release-check)

**Used by**: planning-validate, release-check

```typescript
interface QualityAssessment {
  // Metadata
  skillName: string;           // e.g., "planning-validate"
  timestamp: string;           // ISO 8601 format
  featureBranch: string;       // e.g., "001-speckit-gates-skills"

  // Assessment result
  status: "GREEN" | "YELLOW" | "RED";

  // Detailed findings
  findings: Finding[];

  // Blockers (items that must be resolved for GREEN status)
  blockers: Blocker[];

  // Recommendations (optional improvements)
  recommendations: string[];
}

interface Finding {
  category: string;            // e.g., "spec-completeness", "consistency"
  artifact: string;            // e.g., "spec.md", "data-model.md"
  severity: "info" | "warning" | "error";
  message: string;
  lineNumber?: number;         // Optional line reference
}

interface Blocker {
  id: string;                  // e.g., "BLK-001"
  description: string;
  artifact: string;
  suggestedAction: string;
}
```

**Validation Rules**:
- `status` must be one of: GREEN, YELLOW, RED
- `blockers` must be non-empty when `status` is RED
- `findings` with severity "error" contribute to RED status
- `findings` with severity "warning" contribute to YELLOW status

### 2. Fulfillment Report

**Description**: Output of implementation-verify skill showing requirement coverage

**Used by**: implementation-verify

```typescript
interface FulfillmentReport {
  // Metadata
  skillName: "implementation-verify";
  timestamp: string;
  featureBranch: string;

  // Coverage metrics
  frCoverage: {
    total: number;             // Total FR-XXX requirements
    implemented: number;       // Verified as implemented
    percentage: number;        // (implemented / total) * 100
  };

  taskCoverage: {
    total: number;             // Total tasks in tasks.md
    completed: number;         // Tasks marked complete
    percentage: number;
  };

  contractCoverage?: {         // Optional if contracts exist
    total: number;             // Total contract endpoints
    implemented: number;
    percentage: number;
  };

  // Unimplemented items
  unimplementedRequirements: UnimplementedItem[];

  // Recommended actions
  recommendedActions: string[];
}

interface UnimplementedItem {
  requirementId: string;       // e.g., "FR-015"
  description: string;         // Requirement text
  relatedTasks?: string[];     // Task IDs that should address this
}
```

**Validation Rules**:
- `percentage` must be 0-100
- `unimplementedRequirements` should contain items where implementation not verified

### 3. Document Update

**Description**: Result of a docs-sync operation on a single file

**Used by**: docs-sync

```typescript
interface DocumentUpdate {
  filePath: string;            // e.g., "README.md"
  status: "created" | "updated" | "unchanged" | "error";

  sectionsModified: SectionChange[];

  diffSummary: {
    linesAdded: number;
    linesRemoved: number;
    linesChanged: number;
  };

  error?: string;              // Error message if status is "error"
}

interface SectionChange {
  sectionName: string;         // e.g., "usage", "installation"
  markerStart: string;         // e.g., "<!-- speckit:start:usage -->"
  markerEnd: string;           // e.g., "<!-- speckit:end:usage -->"
  action: "created" | "updated" | "preserved";
}
```

**Aggregate output**:
```typescript
interface DocsSyncResult {
  skillName: "docs-sync";
  timestamp: string;
  featureBranch: string;

  updates: DocumentUpdate[];

  summary: {
    filesCreated: number;
    filesUpdated: number;
    filesUnchanged: number;
    errors: number;
  };
}
```

**Validation Rules**:
- User content outside speckit markers must be preserved
- `status: "error"` requires `error` field to be set

### 4. Progress Dashboard

**Description**: Output of progress-report skill showing workflow status

**Used by**: progress-report

```typescript
interface ProgressDashboard {
  skillName: "progress-report";
  timestamp: string;
  featureBranch: string;

  // Per-phase breakdown
  phases: PhaseProgress[];

  // Overall metrics
  overall: {
    totalTasks: number;
    completedTasks: number;
    percentage: number;
  };

  // Blocked items
  blockedTasks: BlockedTask[];

  // Potentially complete (FR-031a)
  potentiallyComplete: PotentiallyCompleteTask[];

  // Remaining work estimate
  remainingEstimate: {
    incompleteTasks: number;
    blockedTasks: number;
  };
}

interface PhaseProgress {
  phaseName: string;           // e.g., "Phase 1: Core Implementation"
  totalTasks: number;
  completedTasks: number;
  percentage: number;
}

interface BlockedTask {
  taskId: string;
  taskDescription: string;
  blockingReason: string;
}

interface PotentiallyCompleteTask {
  taskId: string;
  taskDescription: string;
  evidence: string;            // Why we think it's complete (file exists, etc.)
}
```

**Validation Rules**:
- Phases should match structure in tasks.md
- `potentiallyComplete` items should have verifiable `evidence`

### 5. Release Checklist

**Description**: Output of release-check skill for pre-release validation

**Used by**: release-check

```typescript
interface ReleaseChecklist {
  skillName: "release-check";
  timestamp: string;
  featureBranch: string;

  // Overall readiness
  isReady: boolean;

  // Individual check items
  checkItems: CheckItem[];

  // Version consistency
  versionInfo: {
    packageJson?: string;      // Version from package.json
    changelog?: string;        // Latest version in CHANGELOG.md
    isConsistent: boolean;
  };
}

interface CheckItem {
  category: "artifacts" | "documentation" | "versioning" | "api";
  name: string;                // e.g., "spec.md exists"
  status: "pass" | "fail" | "skip";
  details?: string;            // Additional context
}
```

**Validation Rules**:
- `isReady` should be true only when all required checks pass
- `status: "skip"` for optional checks that don't apply (e.g., API docs when no API)

## Entity Relationships

```
┌─────────────────────┐
│  QualityAssessment  │──── Used by planning-validate, release-check
└─────────────────────┘
         │
         │ validates
         ▼
┌─────────────────────┐     ┌─────────────────────┐
│     spec.md         │────▶│    plan.md          │
│   (spec artifacts)  │     │  (plan artifacts)   │
└─────────────────────┘     └─────────────────────┘
         │                           │
         │                           │
         ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│  FulfillmentReport  │◀────│     tasks.md        │
│  (impl-verify out)  │     │  (task tracking)    │
└─────────────────────┘     └─────────────────────┘
         │                           │
         │                           │
         ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│   DocsSyncResult    │────▶│  ProgressDashboard  │
│  (docs-sync out)    │     │ (progress-report)   │
└─────────────────────┘     └─────────────────────┘
         │                           │
         └───────────┬───────────────┘
                     │
                     ▼
           ┌─────────────────────┐
           │  ReleaseChecklist   │
           │  (release-check)    │
           └─────────────────────┘
```

## State Transitions

### Quality Assessment Status

```
            ┌─────────────────────────────────────┐
            │                                     │
            ▼                                     │
    ┌──────────────┐   blockers resolved   ┌──────────────┐
    │     RED      │──────────────────────▶│    YELLOW    │
    │  (blocked)   │                       │  (warnings)  │
    └──────────────┘                       └──────────────┘
            │                                     │
            │ all blockers                        │ all warnings
            │ resolved                            │ addressed
            │                                     │
            │          ┌──────────────┐           │
            └─────────▶│    GREEN     │◀──────────┘
                       │   (ready)    │
                       └──────────────┘
```

## Output Formats

All entities are rendered as markdown for human readability in the terminal. The TypeScript interfaces above represent the logical structure; actual output is formatted markdown.

Example rendering for QualityAssessment:
```markdown
## Quality Assessment: planning-validate

**Status**: 🟡 YELLOW
**Branch**: 001-speckit-gates-skills
**Timestamp**: 2026-01-21T10:30:00Z

### Findings

| Severity | Artifact | Message |
|----------|----------|---------|
| warning | spec.md | User Story 3 missing acceptance scenarios |
| info | plan.md | Technical context complete |

### Blockers

None

### Recommendations

- Consider adding more specific acceptance criteria to User Story 3
```
