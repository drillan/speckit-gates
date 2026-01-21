# Quickstart: Speckit Gates Implementation

**Feature Branch**: `001-speckit-gates-skills`
**Date**: 2026-01-21

## Prerequisites

- Node.js 18+ (for npx skills command)
- Spec kit installed and configured in your project
- AI coding agent (Claude Code, Cursor, Copilot, etc.)

## Quick Setup

### 1. Install speckit-gates

```bash
npx skills add drillan/speckit-gates
```

This installs all 5 quality gate skills:
- `planning-validate` - Validates planning artifacts
- `implementation-verify` - Verifies implementation coverage
- `docs-sync` - Synchronizes documentation
- `progress-report` - Shows progress dashboard
- `release-check` - Pre-release validation

### 2. Verify Installation

```bash
npx skills list
```

You should see:
```
Available skills:
  planning-validate      Validates planning artifacts... (auto)
  implementation-verify  Verifies implementation... (auto)
  docs-sync             Synchronizes documentation... (auto)
  progress-report       Displays progress dashboard
  release-check         Validates release readiness
```

## Usage

### Automatic Skills

These skills run automatically when AI agents detect the trigger pattern:

| Skill | Triggers After |
|-------|---------------|
| planning-validate | `/speckit.plan` |
| implementation-verify | `/speckit.implement` |
| docs-sync | `/speckit.implement` |

**Example workflow**:
```
User: /speckit.plan

Agent: [executes planning workflow]
Agent: Planning complete. Running quality validation...
Agent: [displays planning-validate output]

## Quality Assessment: planning-validate

**Status**: 🟢 GREEN
**Branch**: 001-my-feature

### Findings
- spec.md: All mandatory sections present
- plan.md: Technical context complete
- data-model.md: Entities consistent with spec

### Recommendations
- Consider adding edge case scenarios
```

### Manual Skills

Run these skills anytime:

```bash
# Check current progress
npx skills run progress-report

# Validate release readiness
npx skills run release-check
```

Or via AI agent:
```
User: Run progress report
Agent: [executes progress-report skill]
```

## Understanding Output

### Quality Status Indicators

| Status | Meaning | Action |
|--------|---------|--------|
| 🟢 GREEN | All checks pass | Proceed to next phase |
| 🟡 YELLOW | Warnings present | Review warnings, proceed with caution |
| 🔴 RED | Blockers found | Resolve blockers before proceeding |

### Blockers vs Warnings

**Blockers** (RED status):
- Missing mandatory sections in spec.md
- Inconsistent data models
- Constitution violations

**Warnings** (YELLOW status):
- Missing optional documentation
- Incomplete edge cases
- Style recommendations

## Configuration

### Document Markers

docs-sync uses HTML comment markers to preserve your content:

```markdown
# My Project

Your custom intro here (preserved)

<!-- speckit:start:usage -->
## Usage

Auto-generated from spec kit artifacts.
<!-- speckit:end:usage -->

Your custom notes here (preserved)
```

### Skipping Constitution Checks

If your project doesn't have a constitution.md, planning-validate will:
1. Skip constitution compliance checks
2. Report that constitution validation was skipped
3. Continue with other validations

## Common Workflows

### Planning Phase

```bash
# 1. Create feature spec
/speckit.specify "My new feature"

# 2. Run planning (triggers planning-validate)
/speckit.plan

# 3. If RED status, fix issues and re-run
# 4. If GREEN, proceed to tasks
/speckit.tasks
```

### Implementation Phase

```bash
# 1. Implement tasks
/speckit.implement

# 2. Auto-runs: implementation-verify + docs-sync
# 3. Review fulfillment report
# 4. Fix any gaps
```

### Release Phase

```bash
# 1. Check progress anytime
npx skills run progress-report

# 2. Pre-release validation
npx skills run release-check

# 3. If all checks pass, create release
```

## Troubleshooting

### "Required files missing" error

Ensure you've run the prerequisite spec kit commands:
```bash
# For planning-validate
/speckit.specify "..."
/speckit.plan

# For implementation-verify
/speckit.tasks
/speckit.implement
```

### Skills not auto-triggering

AI agents detect "Always run after..." in skill descriptions. If not triggering:
1. Verify skill installation: `npx skills list`
2. Manually invoke: `npx skills run planning-validate`
3. Report issue to your AI agent's support

### Output not displaying

Skills output to stdout in markdown format. Ensure your terminal supports:
- UTF-8 encoding (for emoji status indicators)
- Markdown rendering (optional, for formatted display)

## Next Steps

1. Read the [full specification](./spec.md) for detailed requirements
2. Check [data-model.md](./data-model.md) for output structure details
3. Review [contracts/skills-interface.md](./contracts/skills-interface.md) for API details
