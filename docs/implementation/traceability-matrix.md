# SheetViz — Traceability Matrix

**Baseline:** Architecture Part 1–6 FINAL / APPROVED; Implementation Master Plan v1.0 FINAL / APPROVED  
**Phase:** Phase 1 — Repository + Infrastructure Foundation  
**Last updated:** 9 September 2026

## Status lifecycle

```text
Planned → In Progress → Implemented → Verified → Accepted
```

- `Implemented` ≠ `Verified`.
- `Verified` requires linked and reviewed evidence.
- `Accepted` requires formal phase/release acceptance.
- A failed regression or invariant may return a Trace ID to `In Progress` or `Implemented`.

## Phase 1 Trace IDs

| Trace ID | Requirement | Baseline anchor | Planned artifact/module | Required evidence | Status | Implementation ID | Notes |
|---|---|---|---|---|---|---|---|
| REPO-STRUCT-01 | Monorepo structure, ownership, PR/issue governance | AUTH-P1-001 §2/4; Phase 1 Plan §3 P1.1 | Root structure, `CODEOWNERS`, `.github` templates | Repository structure, commit, GitHub verification, branch protection status | Implemented | Commit `e06f4e2` | Branch protection deferred; must be closed before Phase 1 Review or explicitly accepted as residual risk |
| TRACE-SETUP-01 | Versioned traceability matrix and PR Trace ID validation capability | Master Plan §17; Phase 1 Plan §3 P1.2 | `docs/implementation/traceability-matrix.md`, `.github/workflows/validate-traceability.yml`, `scripts/validate_traceability_pr.sh` | Matrix present; validation script test; CI workflow run when P1.5 is active | In Progress | — | P1.2 |
| CONFIG-VALID-01 | Typed, environment-separated, fail-fast configuration bootstrap | Master Plan §5/§9; Phase 1 Plan §3 P1.3 | `backend/app/config/*`, `.env.example`, configuration docs, config tests | Config validation test; missing/invalid config failure test; docs review | In Progress | — | P1.3 |
| LOCAL-STACK-01 | Reproducible local/dev PostgreSQL, Redis, API, worker test stack | Master Plan §4/§7; Phase 1 Plan §3 P1.4 | Compose/scripts, health checks, README | Reproducible stack log and health responses | Planned | — | Begins only after P1.2 + P1.3 are Verified |
| CI-SKELETON-01 | CI framework capability | Master Plan §7; Phase 1 Plan §3 P1.5 | CI workflow, lint/test/config/migration/API/IaC stubs | CI run showing jobs execute/report | Planned | — | Begins after P1.4 Verified |
| SEC-SCAN-01 | Enforced security scanning baseline | Master Plan §14/§17; Phase 1 Plan §3 P1.6 | Secret/dependency policies, required CI checks, remediation docs | History scan, dependency threshold, branch-rule evidence | Planned | — | Begins only after P1.5 Verified |

## Operating Rules

1. Every implementation PR must state one or more Trace IDs, a baseline reference, and a change classification.
2. `requires-change-control` must not merge without an approved Architecture Impact Analysis and controlled revision where required.
3. Trace status updates require a linked implementation ID and evidence reference. Self-attestation is insufficient for `Verified`.
4. Phase closure requires all scoped requirements to meet the Master Plan evidence gate; code completion alone is insufficient.
5. This matrix is versioned in the repository. It is the implementation-facing traceability source; architecture Part 1–6 remain the authoritative requirement baseline.
