---
name: subphase-verification-docs
description: >-
  Executes the end-of-subphase verification checklist, updates PROGRESS_TRACKER.md, and appends
  verifiable completion evidence to CHANGELOG.md and TODO.md.
---

# Subphase Verification & Documentation Chronicler Skill

Use this skill at the start and conclusion of every subphase to enforce the one-subphase-at-a-time governance protocol.

## End-of-Subphase Protocol

1. Verify all deliverables and acceptance criteria defined in `docs/ROADMAP.md` for the active subphase.
2. Collect concrete completion evidence (test counts, coverage percentage, analyzer output, artifact paths).
3. Update `docs/PROGRESS_TRACKER.md` status from `IN_PROGRESS` to `VERIFIED`.
4. **Append** (never overwrite) a timestamped completion block to `CHANGELOG.md`.
5. **Append** (never overwrite) a verification log entry to `TODO.md`.
6. Stop execution and request explicit user confirmation before starting the next subphase.
