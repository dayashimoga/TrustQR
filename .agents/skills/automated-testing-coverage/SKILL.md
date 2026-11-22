---
name: automated-testing-coverage
description: >-
  Executes unit, widget, integration, security, and cross-platform automated test suites and verifies
  the mandatory >=95% line coverage quality gate.
---

# Automated Testing & >=95% Coverage Enforcement Skill

Use this skill during every subphase verification gate to run tests and calculate exact line coverage from LCOV output.

## Execution & Coverage Gate Procedure

1. Run static analysis:
   `dart analyze --fatal-infos --fatal-warnings`
2. Run test suite with coverage enabled:
   - For Dart packages/services: `dart test --coverage=coverage && dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib`
   - For Flutter packages/apps: `flutter test --coverage`
3. Parse `coverage/lcov.info` (`LF:` total lines found, `LH:` total lines hit) and verify:
   - `100%` of tests pass (`0` failures).
   - `(LH / LF) * 100 >= 95.0%`.
4. Record the exact test count and coverage percentage in `docs/PROGRESS_TRACKER.md` and `CHANGELOG.md`.
