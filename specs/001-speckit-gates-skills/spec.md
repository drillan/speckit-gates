# Feature Specification: Speckit Gates Quality Gate Skills Package

**Feature Branch**: `001-speckit-gates-skills`
**Created**: 2026-01-21
**Status**: Draft
**Input**: User description: "speckit-gates quality gate skills package for spec kit workflow"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Planning Quality Validation (Priority: P1)

As a developer using spec kit, I want automatic validation of my planning artifacts after running `/speckit.plan`, so that I can catch specification gaps and inconsistencies before generating tasks, preventing costly rework.

**Why this priority**: This is the first quality gate in the workflow. Poor planning artifacts lead to poor tasks and wasted implementation effort. Catching issues early provides the highest ROI.

**Independent Test**: Can be fully tested by running the planning-validate skill after `/speckit.plan` completes and receiving a quality assessment report with GREEN/YELLOW/RED judgment.

**Acceptance Scenarios**:

1. **Given** a completed `/speckit.plan` with spec.md, plan.md, and data-model.md, **When** planning-validate runs automatically, **Then** I receive a quality assessment with GREEN/YELLOW/RED status and specific blockers list
2. **Given** a plan with missing sections in spec.md, **When** planning-validate executes, **Then** I receive YELLOW or RED status with specific recommendations for what needs improvement
3. **Given** inconsistent data-model.md that doesn't align with spec.md, **When** planning-validate executes, **Then** I receive a RED status with detailed inconsistency report
4. **Given** a GREEN validated plan, **When** I proceed to `/speckit.tasks`, **Then** task generation has all information needed without further clarification

---

### User Story 2 - Implementation Verification (Priority: P1)

As a developer, I want automatic verification of my code against specifications after running `/speckit.implement`, so that I can confirm all requirements are satisfied and identify any gaps before considering the feature complete.

**Why this priority**: This is the final quality gate ensuring delivery matches specifications. Without this, features may ship incomplete or inconsistent with requirements.

**Independent Test**: Can be fully tested by running implementation-verify after `/speckit.implement` completes and receiving a requirements fulfillment report with specific coverage metrics.

**Acceptance Scenarios**:

1. **Given** a completed implementation, **When** implementation-verify runs automatically, **Then** I receive a fulfillment rate report showing FR requirement coverage percentage
2. **Given** incomplete implementation with unfulfilled requirements, **When** implementation-verify runs, **Then** I receive a list of unimplemented items with specific requirement IDs
3. **Given** all functional requirements satisfied, **When** implementation-verify runs, **Then** I receive recommended actions for final review and testing

---

### User Story 3 - Document Synchronization (Priority: P2)

As a developer, I want automatic documentation updates after implementation completes, so that my README.md, CHANGELOG.md, and API documentation stay synchronized with the codebase without manual effort.

**Why this priority**: Documentation drift is a common pain point. Automating this prevents documentation debt accumulation but is less critical than quality gates that prevent implementation errors.

**Independent Test**: Can be fully tested by completing `/speckit.implement` and verifying the appropriate documentation sections were updated automatically.

**Acceptance Scenarios**:

1. **Given** completion of `/speckit.implement`, **When** docs-sync runs, **Then** README.md Usage section, CHANGELOG.md, and API documentation are updated
2. **Given** docs-sync completes, **When** I review the output, **Then** I see a list of updated files and a diff summary
3. **Given** existing user content in README.md outside speckit markers, **When** docs-sync runs, **Then** user content is preserved unchanged

---

### User Story 4 - Progress Reporting (Priority: P2)

As a developer or project manager, I want to view current progress in a dashboard format, so that I can understand completion status, identify blockers, and estimate remaining work.

**Why this priority**: Progress visibility is valuable for planning and communication but doesn't directly prevent errors or rework like the quality gates do.

**Independent Test**: Can be fully tested by running progress-report at any time and receiving a formatted dashboard with completion metrics.

**Acceptance Scenarios**:

1. **Given** a tasks.md with mixed task statuses, **When** I run progress-report, **Then** I see phase-by-phase completion percentages
2. **Given** blocked tasks in tasks.md, **When** I run progress-report, **Then** blocker tasks are highlighted with their blocking reasons
3. **Given** partial completion, **When** I run progress-report, **Then** I see estimated remaining work based on incomplete tasks

---

### User Story 5 - Release Readiness Check (Priority: P3)

As a developer preparing a release, I want to validate all artifacts are complete and consistent, so that I can ship with confidence that nothing is missing.

**Why this priority**: This is a pre-release validation that aggregates previous checks. Lower priority because it's a manual checkpoint rather than a workflow-integrated gate.

**Independent Test**: Can be fully tested by running release-check manually and receiving a comprehensive release readiness checklist.

**Acceptance Scenarios**:

1. **Given** all spec kit artifacts exist, **When** I run release-check, **Then** I receive a checklist covering spec.md, plan.md, tasks.md, README, CHANGELOG, and API docs
2. **Given** version mismatch between package.json and CHANGELOG, **When** I run release-check, **Then** the version inconsistency is flagged
3. **Given** all checks pass, **When** I run release-check, **Then** I receive a "Ready to Release" confirmation

---

### Edge Cases

- What happens when spec kit artifacts don't exist yet? Skills should fail gracefully with clear guidance on which artifacts are missing.
- What happens when a skill is invoked out of sequence (e.g., implementation-verify before /speckit.implement)? Return clear error indicating prerequisite phase not completed.
- How does the system handle partial documentation files (e.g., README exists but missing expected sections)? Create missing sections or append to existing structure without destroying user content.
- What happens when constitution.md doesn't exist for constitution compliance checks? Skip constitution checks gracefully and report that constitution validation was skipped.

## Requirements *(mandatory)*

### Functional Requirements

#### Planning Validation (planning-validate)
- **FR-001**: System MUST automatically invoke planning-validate after `/speckit.plan` completes
- **FR-002**: System MUST evaluate spec.md for completeness (all mandatory sections present)
- **FR-003**: System MUST evaluate plan.md for executability (actionable steps, clear dependencies)
- **FR-004**: System MUST evaluate data-model.md consistency with spec.md entities
- **FR-005**: System MUST check for contract coverage if contracts are defined
- **FR-006**: System MUST verify constitution.md compliance if constitution exists (verification scope: artifact language, SKILL.md structure; detailed checks defined in plan.md)
- **FR-007**: System MUST produce GREEN/YELLOW/RED quality judgment
- **FR-008**: System MUST list specific blockers for non-GREEN judgments

#### Implementation Verification (implementation-verify)
- **FR-009**: System MUST automatically invoke implementation-verify after `/speckit.implement` completes
- **FR-010**: System MUST calculate FR requirement fulfillment rate as a percentage
- **FR-011**: System MUST calculate task completion rate from tasks.md
- **FR-012**: System MUST verify contract implementation if contracts exist
- **FR-013**: System MUST assess test coverage alignment with requirements
- **FR-014**: System MUST produce list of unimplemented requirements with IDs
- **FR-015**: System MUST provide recommended actions for any gaps

#### Document Synchronization (docs-sync)
- **FR-016**: System MUST automatically invoke docs-sync after `/speckit.implement` completes
- **FR-017**: System MUST update README.md Usage section
- **FR-018**: System MUST update or create CHANGELOG.md entry
- **FR-019**: System MUST update API documentation if APIs exist
- **FR-020**: System MUST preserve existing user content by using clearly marked section boundaries (e.g., `<!-- speckit:start -->` / `<!-- speckit:end -->` markers)
- **FR-021**: System MUST output list of updated files with diff summary

#### Release Check (release-check)
- **FR-022**: System MUST validate all spec kit artifacts exist and are complete
- **FR-023**: System MUST validate README.md contains expected sections
- **FR-024**: System MUST validate CHANGELOG.md has entry for current version
- **FR-025**: System MUST validate API documentation completeness if APIs exist
- **FR-026**: System MUST check version consistency across package.json, CHANGELOG, and other version references
- **FR-027**: System MUST produce release readiness checklist with pass/fail items

#### Progress Report (progress-report)
- **FR-028**: System MUST parse tasks.md and calculate per-phase completion rates
- **FR-029**: System MUST identify and highlight blocked tasks
- **FR-030**: System MUST estimate remaining work based on incomplete tasks
- **FR-031**: System MUST output dashboard-formatted progress view
- **FR-031a**: System MUST identify tasks potentially completed but unmarked (based on file existence or code analysis)

#### General Requirements
- **FR-032**: All skills MUST conform to Agent Skills specification (agentskills.io/specification)
- **FR-033**: Each skill MUST be defined in a SKILL.md file with Agent Skills frontmatter (name, description, version fields)
- **FR-034**: Automatic skills MUST include "Always run after..." in description field
- **FR-035**: System MUST use spec kit's check-prerequisites.sh --json for path resolution
- **FR-036**: All skills MUST work alongside existing /speckit.analyze (complementary, not conflicting)
- **FR-037**: Package MUST be installable via `npx skills add owner/speckit-gates` (published via GitHub repository)

#### Error Handling Requirements
- **FR-038**: Skills MUST fail gracefully with clear guidance when required spec kit artifacts are missing
- **FR-039**: Skills MUST return clear error when invoked before prerequisite phase is completed
- **FR-040**: docs-sync MUST create missing documentation sections without destroying existing user content
- **FR-041**: planning-validate MUST skip constitution checks gracefully when constitution.md does not exist and report that validation was skipped

### Key Entities

- **Quality Assessment**: Represents the output of a validation skill, including status (GREEN/YELLOW/RED), findings list, blockers, and recommendations
- **Fulfillment Report**: Represents implementation verification output, including requirement coverage percentages, unimplemented items, and recommended actions
- **Document Update**: Represents a docs-sync operation result, including target file, sections modified, and diff summary
- **Progress Dashboard**: Represents progress-report output, including per-phase metrics, blocker list, and remaining work estimate
- **Release Checklist**: Represents release-check output, including checklist items with pass/fail status and overall readiness judgment

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: planning-validate produces actionable findings for 100% of incomplete or inconsistent specs (no false negatives for missing mandatory sections or entity mismatches)
- **SC-002**: Implementation verification catches at least 90% of requirement gaps before manual review
- **SC-003**: Documentation stays current with codebase - no more than 1 business day of documentation drift after any spec kit phase
- **SC-004**: Release readiness checks complete in under 30 seconds
- **SC-005**: Progress reports provide completion percentage accurate to within 5% of actual completion
- **SC-006**: Quality gate skills execute without requiring additional file reads beyond spec kit artifacts
- **SC-007**: All 5 skills successfully install via `npx skills add speckit-gates` on first attempt
- **SC-008**: 95% of spec kit users can understand and act on skill outputs without additional documentation

## Assumptions

- Spec kit is already installed and functional in the user's project
- The project follows standard spec kit conventions (specs/ directory structure, standard artifact names)
- Users have Node.js/npm installed for skills.sh package installation
- AI coding agents (Claude Code, Cursor, Copilot) can invoke skills via standard Agent Skills protocol
- README.md and CHANGELOG.md follow common markdown conventions (Keep a Changelog for CHANGELOG)
- The project uses semantic versioning for release management
- Automatic triggering relies on AI coding agents recognizing "Always run after..." patterns in SKILL.md descriptions
- No external automation system (GitHub Actions, hooks) is required for skill invocation

## Clarifications

### Session 2026-01-21

- Q: FR-039の公開方法が曖昧（skills.shへの公開方法がGitHubリポジトリ経由か不明） → A: GitHub経由の公開を明記（`npx skills add owner/speckit-gates`形式）
- Q: FR-035のSKILL.md形式にAgent Skillsフロントマター構造への言及がない → A: 必須フロントマターフィールド（name, description, version）を明記
- Q: 自動発動の技術的手段が不明確（FR-001, FR-009, FR-016） → A: Assumptionsセクションに「AIエージェントがSKILL.mdのdescriptionパターンを認識」「外部自動化システム不要」を追加
- Q: SC-006のパフォーマンス基準がAIエージェント依存で制御不能 → A: 「spec kit成果物以外の追加ファイル読み込み不要」に変更
- Q: FR-022の「preserve existing user content」の範囲が不明確 → A: セクションマーカー方式（`<!-- speckit:start/end -->`）を明記
- Q: FR-017, FR-018（specify/plan後のREADME更新）は過剰でスコープ外とすべきか → A: docs-syncをimplement後のみに限定し、旧FR-017/FR-018を削除。FRを再番号付け
- Q: progress-reportに未マークだが完了済み可能性のあるタスク検出機能を追加すべきか → A: FR-031aとして追加「System MUST identify tasks potentially completed but unmarked (based on file existence or code analysis)」
- Q: Edge Cases(L91-96)で特定された4つのケースに対応するFRが存在しない → A: Error Handling Requirementsセクション追加（FR-038〜FR-041）
- Q: SC-001「reducing task-phase rework by at least 50%」は測定困難 → A: 「planning-validate produces actionable findings for 100% of incomplete or inconsistent specs」に変更
- Q: FR-006のConstitution準拠チェック範囲が不明確 → A: 検証スコープを明記（artifact言語、SKILL.md構造）、詳細はplan.mdで定義
