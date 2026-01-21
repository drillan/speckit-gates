# Implementation Plan: Speckit Gates Quality Gate Skills Package

**Branch**: `001-speckit-gates-skills` | **Date**: 2026-01-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-speckit-gates-skills/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

A quality gate skills package for the spec kit workflow that provides automated validation at key phases: planning-validate (after `/speckit.plan`), implementation-verify (after `/speckit.implement`), docs-sync (automatic documentation updates), progress-report (dashboard view), and release-check (pre-release validation). All skills conform to Agent Skills specification (agentskills.io) using SKILL.md format with YAML frontmatter.

## Technical Context

**Language/Version**: Markdown (SKILL.md format), Bash scripts (for execution)
**Primary Dependencies**: Agent Skills specification (agentskills.io/specification), spec kit ecosystem
**Storage**: N/A (file-based artifact reading only)
**Testing**: Manual validation via `skills-ref validate`, integration testing with spec kit workflow
**Target Platform**: Cross-platform (any AI coding agent: Claude Code, Cursor, Copilot, etc.)
**Project Type**: single (skills package with SKILL.md files and supporting scripts)
**Performance Goals**: Release readiness checks complete in under 30 seconds (SC-004)
**Constraints**: Skills must work without external automation (GitHub Actions, hooks) - rely on AI agent recognition of "Always run after..." patterns
**Scale/Scope**: 5 skills (planning-validate, implementation-verify, docs-sync, progress-report, release-check)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check (Phase 0 Gate)

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| **I. English-First Communication** | All SKILL.md, README.md, CHANGELOG.md in English | ✅ PASS | Plan commits to English-only artifacts |
| **I. English-First Communication** | Git commit messages in English | ✅ PASS | Will follow convention |
| **I. English-First Communication** | Code comments and error messages in English | ✅ PASS | All scripts and outputs in English |
| **II. Agent Skills Specification Compliance** | Conform to agentskills.io/specification | ✅ PASS | FR-032, FR-033 require this |
| **II. Agent Skills Specification Compliance** | SKILL.md frontmatter: name, description, version | ✅ PASS | FR-033 specifies these fields |
| **II. Agent Skills Specification Compliance** | Automatic skills use "Always run after..." pattern | ✅ PASS | FR-034 requires this for planning-validate, implementation-verify, docs-sync |
| **III. Spec Kit Compatibility** | Use check-prerequisites.sh --json for path resolution | ✅ PASS | FR-035 requires this |
| **III. Spec Kit Compatibility** | No conflict with existing /speckit.* commands | ✅ PASS | Skills complement, not replace |
| **III. Spec Kit Compatibility** | Complement /speckit.analyze functionality | ✅ PASS | FR-036 ensures this |

**Gate Result**: ✅ PASS - All constitution principles satisfied. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
skills/
├── planning-validate/
│   ├── SKILL.md                 # Main skill definition
│   └── scripts/
│       └── validate.sh          # Validation logic
├── implementation-verify/
│   ├── SKILL.md
│   └── scripts/
│       └── verify.sh
├── docs-sync/
│   ├── SKILL.md
│   └── scripts/
│       └── sync.sh
├── progress-report/
│   ├── SKILL.md
│   └── scripts/
│       └── report.sh
└── release-check/
    ├── SKILL.md
    └── scripts/
        └── check.sh

README.md                        # Package documentation
CHANGELOG.md                     # Version history
LICENSE                          # License file
```

**Structure Decision**: Skills package structure following Agent Skills specification. Each skill in its own directory with SKILL.md and supporting scripts. No src/ or tests/ directories as this is a skills package, not a traditional codebase.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. All constitution principles satisfied.

## Post-Design Constitution Check (Phase 1 Gate)

| Principle | Requirement | Status | Design Evidence |
|-----------|-------------|--------|-----------------|
| **I. English-First Communication** | All SKILL.md in English | ✅ PASS | contracts/skills-interface.md shows English SKILL.md examples |
| **I. English-First Communication** | README.md, CHANGELOG.md in English | ✅ PASS | quickstart.md references English documentation |
| **I. English-First Communication** | Error messages in English | ✅ PASS | data-model.md defines English output formats |
| **II. Agent Skills Specification** | SKILL.md frontmatter format | ✅ PASS | contracts/skills-interface.md defines valid frontmatter |
| **II. Agent Skills Specification** | "Always run after..." pattern | ✅ PASS | 3 automatic skills use pattern (see contracts) |
| **II. Agent Skills Specification** | Valid name format | ✅ PASS | All names lowercase with hyphens |
| **III. Spec Kit Compatibility** | check-prerequisites.sh usage | ✅ PASS | contracts/skills-interface.md documents path resolution |
| **III. Spec Kit Compatibility** | No /speckit.* conflicts | ✅ PASS | Skills are separate from spec kit commands |
| **Quality Standards** | CHANGELOG follows Keep a Changelog | ✅ PASS | Will follow format per constitution |
| **Quality Standards** | SKILL.md self-contained | ✅ PASS | Each skill has own SKILL.md |

**Gate Result**: ✅ PASS - Design artifacts comply with constitution. Ready for task generation.
