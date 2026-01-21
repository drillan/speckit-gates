<!--
  Sync Impact Report
  ==================
  Version change: N/A (initial) → 1.0.0

  Added Principles:
  - I. English-First Communication
  - II. Agent Skills Specification Compliance
  - III. Spec Kit Compatibility

  Added Sections:
  - Core Principles (3 principles)
  - Quality Standards
  - Development Workflow
  - Governance

  Removed Sections: None (initial creation)

  Templates Status:
  - .specify/templates/plan-template.md: ✅ Compatible (Constitution Check section exists)
  - .specify/templates/spec-template.md: ✅ Compatible (no constitution-specific requirements)
  - .specify/templates/tasks-template.md: ✅ Compatible (no constitution-specific requirements)

  Follow-up TODOs: None
-->

# Speckit Gates Constitution

## Core Principles

### I. English-First Communication

All project artifacts and communications MUST be written in English to ensure global accessibility and consistency.

**Requirements**:
- All generated files (SKILL.md, README.md, CHANGELOG.md) MUST be written in English
- Git commit messages MUST be written in English
- Code comments MUST be written in English
- Error messages and user-facing output MUST be in English

**Rationale**: English is the lingua franca of software development. Consistent language usage reduces friction for contributors and users worldwide, and ensures compatibility with automated tools and AI agents.

### II. Agent Skills Specification Compliance

All skills MUST conform to the Agent Skills specification to ensure interoperability across AI coding agents.

**Requirements**:
- All skills MUST conform to agentskills.io/specification
- SKILL.md frontmatter MUST include required fields: `name`, `description`, `version`
- Automatic skills MUST include "Always run after..." pattern in description field

**Rationale**: Adherence to the Agent Skills specification ensures that skills work consistently across different AI coding agents (Claude Code, Cursor, Copilot, etc.) and can be discovered and invoked through standard mechanisms.

### III. Spec Kit Compatibility

Skills MUST integrate seamlessly with the spec kit ecosystem without conflicts.

**Requirements**:
- Skills MUST use spec kit's standard path resolution via `check-prerequisites.sh --json`
- Skills MUST NOT conflict with existing `/speckit.*` commands
- Skills MUST complement (not replace) existing spec kit functionality like `/speckit.analyze`

**Rationale**: Speckit Gates extends the spec kit workflow. Maintaining compatibility ensures users can adopt quality gates without disrupting their existing development practices.

## Quality Standards

**Code Quality**:
- All code MUST follow language-specific best practices and conventions
- All public interfaces MUST be documented
- Error handling MUST be explicit and informative

**Documentation Quality**:
- README.md MUST include installation, usage, and contribution guidelines
- CHANGELOG.md MUST follow Keep a Changelog format
- Each SKILL.md MUST be self-contained and actionable

## Development Workflow

**Version Control**:
- Commits MUST be atomic and focused on a single logical change
- Commit messages MUST follow conventional commit format when applicable
- Feature branches MUST be based on the main branch

**Release Process**:
- Releases MUST follow semantic versioning (MAJOR.MINOR.PATCH)
- Each release MUST update CHANGELOG.md
- Package MUST be installable via `npx skills add drillan/speckit-gates`

## Governance

**Constitution Authority**:
- This constitution supersedes conflicting practices or conventions
- All PRs and code reviews MUST verify compliance with these principles
- Violations MUST be documented and justified in Complexity Tracking sections

**Amendment Process**:
- Amendments require documentation of rationale and impact assessment
- Version increments follow semantic versioning:
  - MAJOR: Backward-incompatible principle changes or removals
  - MINOR: New principles or materially expanded guidance
  - PATCH: Clarifications, wording improvements, typo fixes
- All amendments MUST update the Last Amended date

**Compliance Review**:
- Planning phase (`/speckit.plan`) MUST include Constitution Check
- Implementation verification MUST validate principle adherence
- Release checks MUST confirm all artifacts meet constitution requirements

**Version**: 1.0.0 | **Ratified**: 2026-01-21 | **Last Amended**: 2026-01-21
