# Tasks: Speckit Gates Quality Gate Skills Package

**Input**: Design documents from `/specs/001-speckit-gates-skills/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Not requested - no test tasks included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Skills package**: `skills/[skill-name]/` at repository root
- Each skill has `SKILL.md` and `scripts/` subdirectory
- Documentation at root: `README.md`, `CHANGELOG.md`, `LICENSE`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create skills package directory structure per plan.md in skills/
- [X] T002 [P] Create package documentation file README.md at repository root
- [X] T003 [P] Create CHANGELOG.md at repository root following Keep a Changelog format
- [X] T004 [P] Create LICENSE file at repository root

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY skill can be fully implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Create shared path resolution helper script in skills/shared/path-resolver.sh using check-prerequisites.sh --json
- [X] T006 [P] Create shared output formatting utilities in skills/shared/output-format.sh for GREEN/YELLOW/RED status display
- [X] T007 [P] Create shared error handling utilities in skills/shared/error-handler.sh for consistent exit codes and error messages

**Checkpoint**: Foundation ready - skill implementation can now begin in parallel

---

## Phase 3: User Story 1 - Planning Quality Validation (Priority: P1) 🎯 MVP

**Goal**: Automatic validation of planning artifacts after `/speckit.plan` to catch specification gaps before task generation

**Independent Test**: Run planning-validate after `/speckit.plan` completes and verify GREEN/YELLOW/RED quality assessment with specific blockers list

### Implementation for User Story 1

- [X] T008 [P] [US1] Create SKILL.md frontmatter and description for planning-validate in skills/planning-validate/SKILL.md
- [X] T009 [US1] Implement spec.md completeness checker in skills/planning-validate/scripts/validate.sh (FR-002)
- [X] T010 [US1] Implement plan.md executability checker in skills/planning-validate/scripts/validate.sh (FR-003)
- [X] T011 [US1] Implement data-model.md consistency checker in skills/planning-validate/scripts/validate.sh (FR-004)
- [X] T012 [US1] Implement contract coverage checker in skills/planning-validate/scripts/validate.sh (FR-005)
- [X] T013 [US1] Implement constitution.md compliance checker with graceful skip in skills/planning-validate/scripts/validate.sh (FR-006, FR-041)
- [X] T014 [US1] Implement GREEN/YELLOW/RED quality judgment logic in skills/planning-validate/scripts/validate.sh (FR-007, FR-008)
- [X] T015 [US1] Implement QualityAssessment output formatting in skills/planning-validate/scripts/validate.sh per data-model.md
- [X] T016 [US1] Add error handling for missing required artifacts in skills/planning-validate/scripts/validate.sh (FR-038, FR-039)

**Checkpoint**: At this point, planning-validate skill should be fully functional and testable independently

---

## Phase 4: User Story 2 - Implementation Verification (Priority: P1)

**Goal**: Automatic verification of code against specifications after `/speckit.implement` to confirm all requirements are satisfied

**Independent Test**: Run implementation-verify after `/speckit.implement` completes and verify fulfillment report with coverage metrics

### Implementation for User Story 2

- [X] T017 [P] [US2] Create SKILL.md frontmatter and description for implementation-verify in skills/implementation-verify/SKILL.md
- [X] T018 [US2] Implement FR requirement fulfillment calculator in skills/implementation-verify/scripts/verify.sh (FR-010)
- [X] T019 [US2] Implement task completion rate calculator from tasks.md in skills/implementation-verify/scripts/verify.sh (FR-011)
- [X] T020 [US2] Implement contract implementation verifier in skills/implementation-verify/scripts/verify.sh (FR-012)
- [X] T021 [US2] Implement test coverage alignment assessor in skills/implementation-verify/scripts/verify.sh (FR-013)
- [X] T022 [US2] Implement unimplemented requirements list generator in skills/implementation-verify/scripts/verify.sh (FR-014)
- [X] T023 [US2] Implement recommended actions generator in skills/implementation-verify/scripts/verify.sh (FR-015)
- [X] T024 [US2] Implement FulfillmentReport output formatting in skills/implementation-verify/scripts/verify.sh per data-model.md
- [X] T025 [US2] Add error handling for missing required artifacts in skills/implementation-verify/scripts/verify.sh (FR-038, FR-039)

**Checkpoint**: At this point, implementation-verify skill should be fully functional and testable independently

---

## Phase 5: User Story 3 - Document Synchronization (Priority: P2)

**Goal**: Automatic documentation updates after implementation completes to keep README.md, CHANGELOG.md, and API docs synchronized

**Independent Test**: Complete `/speckit.implement` and verify appropriate documentation sections were updated with user content preserved

### Implementation for User Story 3

- [X] T026 [P] [US3] Create SKILL.md frontmatter and description for docs-sync in skills/docs-sync/SKILL.md
- [X] T027 [US3] Implement README.md Usage section updater with speckit markers in skills/docs-sync/scripts/sync.sh (FR-017, FR-020)
- [X] T028 [US3] Implement CHANGELOG.md entry creator/updater in skills/docs-sync/scripts/sync.sh (FR-018)
- [X] T029 [US3] Implement API documentation updater in skills/docs-sync/scripts/sync.sh (FR-019)
- [X] T030 [US3] Implement user content preservation logic using marker detection in skills/docs-sync/scripts/sync.sh (FR-020, FR-040)
- [X] T031 [US3] Implement file update list and diff summary generator in skills/docs-sync/scripts/sync.sh (FR-021)
- [X] T032 [US3] Implement DocsSyncResult output formatting in skills/docs-sync/scripts/sync.sh per data-model.md
- [X] T033 [US3] Add error handling for missing required artifacts in skills/docs-sync/scripts/sync.sh (FR-038)

**Checkpoint**: At this point, docs-sync skill should be fully functional and testable independently

---

## Phase 6: User Story 4 - Progress Reporting (Priority: P2)

**Goal**: Dashboard view of current progress with completion status, blockers, and remaining work estimate

**Independent Test**: Run progress-report at any time and receive formatted dashboard with completion metrics

### Implementation for User Story 4

- [X] T034 [P] [US4] Create SKILL.md frontmatter and description for progress-report in skills/progress-report/SKILL.md
- [X] T035 [US4] Implement tasks.md parser and per-phase completion calculator in skills/progress-report/scripts/report.sh (FR-028)
- [X] T036 [US4] Implement blocked task identifier and highlighter in skills/progress-report/scripts/report.sh (FR-029)
- [X] T037 [US4] Implement remaining work estimator in skills/progress-report/scripts/report.sh (FR-030)
- [X] T038 [US4] Implement potentially-complete task detector based on file existence in skills/progress-report/scripts/report.sh (FR-031a)
- [X] T039 [US4] Implement ProgressDashboard output formatting in skills/progress-report/scripts/report.sh (FR-031, data-model.md)
- [X] T040 [US4] Add error handling for missing tasks.md in skills/progress-report/scripts/report.sh (FR-038)

**Checkpoint**: At this point, progress-report skill should be fully functional and testable independently

---

## Phase 7: User Story 5 - Release Readiness Check (Priority: P3)

**Goal**: Comprehensive pre-release validation to ensure all artifacts are complete and consistent

**Independent Test**: Run release-check manually and receive comprehensive release readiness checklist

### Implementation for User Story 5

- [X] T041 [P] [US5] Create SKILL.md frontmatter and description for release-check in skills/release-check/SKILL.md
- [X] T042 [US5] Implement spec kit artifact existence and completeness validator in skills/release-check/scripts/check.sh (FR-022)
- [X] T043 [US5] Implement README.md section validator in skills/release-check/scripts/check.sh (FR-023)
- [X] T044 [US5] Implement CHANGELOG.md version entry validator in skills/release-check/scripts/check.sh (FR-024)
- [X] T045 [US5] Implement API documentation completeness checker in skills/release-check/scripts/check.sh (FR-025)
- [X] T046 [US5] Implement version consistency checker across package.json and CHANGELOG in skills/release-check/scripts/check.sh (FR-026)
- [X] T047 [US5] Implement release readiness checklist generator with pass/fail items in skills/release-check/scripts/check.sh (FR-027)
- [X] T048 [US5] Implement ReleaseChecklist output formatting in skills/release-check/scripts/check.sh per data-model.md
- [X] T049 [US5] Add error handling for missing required artifacts in skills/release-check/scripts/check.sh (FR-038)

**Checkpoint**: At this point, release-check skill should be fully functional and testable independently

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect all skills and final validation

- [X] T050 Ensure all SKILL.md files conform to Agent Skills specification (FR-032, FR-033)
- [X] T051 [P] Verify automatic skills include "Always run after..." pattern in descriptions (FR-034)
- [X] T052 [P] Verify all skills work alongside existing /speckit.analyze (FR-036)
- [X] T053 Validate skills-ref validate passes for all 5 skills
- [X] T054 Run quickstart.md scenarios for end-to-end validation
- [X] T055 Update README.md with installation instructions for npx skills add drillan/speckit-gates (FR-037)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 and US2 are both P1 and can proceed in parallel
  - US3 and US4 are both P2 and can proceed in parallel after US1/US2
  - US5 is P3 and can proceed after US3/US4
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - No dependencies on US1/US2
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - No dependencies on US1/US2/US3
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - No dependencies on other stories

### Within Each User Story

- SKILL.md creation first
- Script implementation in logical order (validation logic → output formatting → error handling)
- Story complete before moving to lower priority

### Parallel Opportunities

- T002, T003, T004 can run in parallel (different files)
- T005, T006, T007 - T006 and T007 can run in parallel; T005 should complete first as others may use it
- US1 (T008-T016) and US2 (T017-T025) can run in parallel with different developers
- US3 (T026-T033) and US4 (T034-T040) can run in parallel with different developers
- T050, T051, T052 can run in parallel (different validation scopes)

---

## Parallel Example: Phase 1 Setup

```bash
# Launch all setup tasks together:
Task: "Create package documentation file README.md at repository root"
Task: "Create CHANGELOG.md at repository root following Keep a Changelog format"
Task: "Create LICENSE file at repository root"
```

---

## Parallel Example: User Story 1 & 2

```bash
# Developer A - User Story 1 (planning-validate):
Task: "Create SKILL.md frontmatter and description for planning-validate in skills/planning-validate/SKILL.md"
# ... followed by T009-T016 sequentially

# Developer B - User Story 2 (implementation-verify):
Task: "Create SKILL.md frontmatter and description for implementation-verify in skills/implementation-verify/SKILL.md"
# ... followed by T018-T025 sequentially
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T007)
3. Complete Phase 3: User Story 1 - planning-validate (T008-T016)
4. **STOP and VALIDATE**: Test planning-validate independently with `/speckit.plan`
5. Deploy/demo if ready - developers can validate their planning phase

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (planning-validate) → Test independently → Deploy (MVP!)
3. Add User Story 2 (implementation-verify) → Test independently → Deploy
4. Add User Story 3 (docs-sync) → Test independently → Deploy
5. Add User Story 4 (progress-report) → Test independently → Deploy
6. Add User Story 5 (release-check) → Test independently → Deploy
7. Each skill adds value without breaking previous skills

### Suggested MVP Scope

**MVP = User Story 1 (planning-validate)** - This provides immediate value by validating planning artifacts, catching issues early in the workflow.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each skill should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate skill independently
- All output is markdown format to stdout as per contracts/skills-interface.md
- Exit codes follow contracts/skills-interface.md specification
