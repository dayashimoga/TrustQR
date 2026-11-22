# Engineering Quality Gates & Execution Governance Contract

## 1. Zero-Placeholder & Zero-Dead-UI Policy
- Every function, class, API handler, and UI widget committed in a subphase must be genuinely implemented and wired end-to-end.
- Stub callbacks such as `onPressed: () {}` or fake hardcoded metric arrays presented as live analytics are strictly prohibited.

## 2. Automated Verification Thresholds
- **Static Analysis**: `dart analyze --fatal-infos --fatal-warnings` must return exit code `0`.
- **Unit, Widget & Integration Tests**: 100% of test suites must pass.
- **Code Coverage**: Maintain `>= 95%` line coverage across testable packages and services, verified via `lcov.info` parsing scripts.

## 3. Documentation & Append-Only Ledger Policy
- `CHANGELOG.md` and `TODO.md` must only be updated by appending new sections or status lines—never by deleting or rewriting historical entries.
- `docs/PROGRESS_TRACKER.md` must be updated at the start and end of every subphase with verifiable evidence (command outputs, coverage percentages, artifact paths).
