# Antigravity Workspace Instructions — Universal QR Ecosystem

Refer to and enforce all rules in [AGENTS.md](./AGENTS.md), [.agents/rules/security-rbac-contract.md](./.agents/rules/security-rbac-contract.md), and [.agents/rules/quality-gates-contract.md](./.agents/rules/quality-gates-contract.md).

## Mandatory Pre-Flight & Post-Flight Checklist for Every Subphase

1. **Pre-Flight**:
   - Verify the active subphase in [docs/PROGRESS_TRACKER.md](./docs/PROGRESS_TRACKER.md).
   - Confirm all prerequisite subphases are marked `VERIFIED`.
   - Mark the current subphase as `IN_PROGRESS` in `docs/PROGRESS_TRACKER.md` and append a start entry to `TODO.md`.
2. **Implementation & Multi-Agent Delegation**:
   - Coordinate specialized subagents (`architect-agent`, `frontend-agent`, `backend-agent`, `security-agent`, `testing-agent`, `devops-agent`, `uiux-agent`, `performance-agent`, `docs-agent`) and workspace skills in `.agents/skills/`.
3. **Verification Gate**:
   - Run static analysis, automated tests, coverage checks, and architectural isolation checks.
   - Verify zero placeholder code and zero dead UI elements.
4. **Post-Flight & Confirmation Pause**:
   - Append completion evidence to `CHANGELOG.md` and `TODO.md`.
   - Update `docs/PROGRESS_TRACKER.md` to `VERIFIED` with test metrics and evidence links.
   - Stop and request explicit user confirmation before beginning the next subphase.
