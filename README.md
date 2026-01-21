# speckit-gates

This skill package extends [spec-kit](https://github.com/github/spec-kit) with automated quality gates.

## Overview

speckit-gates provides automated validation at key phases of the spec kit workflow:

| Skill | Type | Triggers After | Purpose |
|-------|------|---------------|---------|
| `planning-validate` | Automatic | `/speckit.plan` | Validates planning artifacts |
| `implementation-verify` | Automatic | `/speckit.implement` | Verifies implementation coverage |
| `docs-sync` | Automatic | `/speckit.implement` | Synchronizes documentation |
| `progress-report` | Manual | User request | Shows progress dashboard |
| `release-check` | Manual | User request | Pre-release validation |

## Installation

```bash
npx skills add drillan/speckit-gates
```

## Quick Start

After installation, automatic skills will run when their trigger commands complete:

```bash
# Planning phase - planning-validate runs automatically
/speckit.plan

# Implementation phase - implementation-verify and docs-sync run automatically
/speckit.implement
```

Manual skills can be invoked anytime:

```bash
# Check progress
npx skills run progress-report

# Pre-release validation
npx skills run release-check
```

## Quality Status Indicators

| Status | Meaning | Action |
|--------|---------|--------|
| GREEN | All checks pass | Proceed to next phase |
| YELLOW | Warnings present | Review warnings, proceed with caution |
| RED | Blockers found | Resolve blockers before proceeding |

## Requirements

- Spec kit installed and configured
- AI coding agent (Claude Code, Cursor, Copilot, etc.)

## License

MIT
