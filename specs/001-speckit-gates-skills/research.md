# Research: Speckit Gates Quality Gate Skills Package

**Feature Branch**: `001-speckit-gates-skills`
**Date**: 2026-01-21

## Research Tasks

### 1. Agent Skills Specification Structure

**Decision**: Use SKILL.md format with YAML frontmatter as defined by agentskills.io/specification

**Rationale**:
- The Agent Skills specification provides a standardized way for AI coding agents to discover and invoke skills
- SKILL.md uses progressive disclosure: metadata (~100 tokens) at startup, instructions (<5000 tokens) on activation
- Required frontmatter fields: `name`, `description`, `version`
- Optional fields: `license`, `compatibility`, `metadata`, `allowed-tools`

**Alternatives considered**:
- JSON configuration files: Rejected because Agent Skills spec mandates SKILL.md format
- Custom YAML format: Rejected because it would break compatibility with AI agents

**Key constraints discovered**:
- `name` field: 1-64 chars, lowercase/digits/hyphens only, no leading/trailing hyphens, no consecutive hyphens
- `description` field: 1-1024 chars, should explain what skill does AND when to use it
- Main SKILL.md should be under 500 lines; use references/ for detailed documentation

### 2. Automatic Skill Invocation Pattern

**Decision**: Use "Always run after..." pattern in description field for automatic skills

**Rationale**:
- AI coding agents (Claude Code, Cursor, Copilot) recognize this pattern to trigger automatic execution
- No external automation (GitHub Actions, hooks) required
- Pattern matches FR-034 requirement

**Implementation**:
```yaml
---
name: planning-validate
description: Validates planning artifacts for quality and consistency. Always run after /speckit.plan completes.
version: 1.0.0
---
```

**Alternatives considered**:
- GitHub Actions hooks: Rejected per FR-001 assumption that external automation not required
- Pre-commit hooks: Rejected because it wouldn't work for non-git workflows

### 3. Spec Kit Path Resolution Integration

**Decision**: Use `check-prerequisites.sh --json` for all path resolution

**Rationale**:
- Consistent with spec kit ecosystem (FR-035)
- Handles branch detection, feature directory lookup, and artifact path resolution
- Supports both git and non-git environments
- Returns structured JSON: `{"FEATURE_DIR":"...", "AVAILABLE_DOCS":[...]}`

**Key paths available**:
- `FEATURE_SPEC`: spec.md path
- `IMPL_PLAN`: plan.md path
- `TASKS`: tasks.md path
- `RESEARCH`: research.md path
- `DATA_MODEL`: data-model.md path
- `QUICKSTART`: quickstart.md path
- `CONTRACTS_DIR`: contracts/ directory path

**Alternatives considered**:
- Direct file path construction: Rejected because it duplicates spec kit logic and may diverge
- Environment variables only: Rejected because check-prerequisites.sh handles edge cases

### 4. Quality Assessment Output Format

**Decision**: Use GREEN/YELLOW/RED status with structured blockers list

**Rationale**:
- Clear, actionable feedback for developers (FR-007, FR-008)
- Three-tier system allows nuanced feedback:
  - GREEN: All checks pass, proceed to next phase
  - YELLOW: Minor issues, can proceed with warnings
  - RED: Critical blockers, must resolve before proceeding

**Output structure**:
```markdown
## Quality Assessment: [SKILL NAME]

**Status**: 🟢 GREEN | 🟡 YELLOW | 🔴 RED

### Findings

- [Finding 1]
- [Finding 2]

### Blockers (if RED/YELLOW)

- [ ] [Blocker 1 - specific action needed]
- [ ] [Blocker 2 - specific action needed]

### Recommendations

- [Recommendation 1]
```

**Alternatives considered**:
- Numeric score (0-100): Rejected because it's harder to interpret and action on
- Pass/Fail binary: Rejected because it loses nuance for minor issues

### 5. Document Marker Strategy for docs-sync

**Decision**: Use HTML comments `<!-- speckit:start -->` / `<!-- speckit:end -->` for section boundaries

**Rationale**:
- Invisible in rendered markdown
- Clearly delineates auto-generated vs user content (FR-020)
- Standard pattern used by many documentation generators

**Implementation**:
```markdown
# My Project

Custom introduction here (preserved by docs-sync)

<!-- speckit:start:usage -->
## Usage

Auto-generated usage section from spec kit artifacts.
<!-- speckit:end:usage -->

Custom notes here (preserved by docs-sync)
```

**Alternatives considered**:
- YAML frontmatter regions: Rejected because it's non-standard for markdown body
- JSON comments: Not valid in markdown
- Special character markers (e.g., `===SPECKIT===`): Rejected because visible in rendered markdown

### 6. Skills Package Directory Structure

**Decision**: Single directory per skill with SKILL.md and optional scripts/references

**Rationale**:
- Matches Agent Skills specification recommended structure
- Allows progressive disclosure of information
- Supports complex skills that need helper scripts

**Structure**:
```
speckit-gates/
├── skills/
│   ├── planning-validate/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── validate.sh
│   ├── implementation-verify/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── verify.sh
│   ├── docs-sync/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── sync.sh
│   ├── progress-report/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── report.sh
│   └── release-check/
│       ├── SKILL.md
│       └── scripts/
│           └── check.sh
├── README.md
├── CHANGELOG.md
└── LICENSE
```

**Alternatives considered**:
- All skills in single SKILL.md: Rejected because it violates skill discovery pattern
- Flat structure without subdirectories: Rejected because scripts would clutter root

### 7. Installation via npx skills add

**Decision**: Publish via GitHub repository at `drillan/speckit-gates`

**Rationale**:
- Matches FR-037 requirement for `npx skills add owner/speckit-gates`
- Constitution specifies `npx skills add drillan/speckit-gates`
- GitHub-based installation is standard for Agent Skills packages

**Validation**:
- Use `skills-ref validate ./my-skill` to validate each skill before publishing
- Ensure all SKILL.md files pass frontmatter validation

**Alternatives considered**:
- NPM package publication: Not required by Agent Skills spec
- Direct download: Less discoverable and harder to version

## Summary of Key Decisions

| Area | Decision | Reference |
|------|----------|-----------|
| Skill format | SKILL.md with YAML frontmatter | agentskills.io/specification |
| Auto-invocation | "Always run after..." description pattern | FR-034 |
| Path resolution | check-prerequisites.sh --json | FR-035 |
| Quality status | GREEN/YELLOW/RED with blockers list | FR-007, FR-008 |
| Doc markers | `<!-- speckit:start/end -->` HTML comments | FR-020 |
| Package structure | Per-skill directories under skills/ | Agent Skills spec |
| Installation | GitHub repo `drillan/speckit-gates` | Constitution, FR-037 |
