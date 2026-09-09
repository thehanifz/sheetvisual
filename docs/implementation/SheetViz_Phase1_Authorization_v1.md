# SheetViz — Explicit Phase 1 Authorization

**Authorization ID:** AUTH-P1-001
**Date:** 9 September 2026
**Status:** AUTHORIZED
**Owner / Authorizer:** Senior Product Manager (SheetViz Architecture Governance)

---

## 1. Authorization Statement

I explicitly authorize **Implementation Phase 1 — Repository + Infrastructure Foundation** under the terms of this authorization record. This authorization is scope-bound to Phase 1 only and does not authorize Phase 2–13 or any work outside the defined scope.

---

## 2. Scope — Phase 1 Only

**Phase 1 — Repository + Infrastructure Foundation**

| Allowed work | Description |
|---|---|
| Repository structure | Monorepo layout (backend/worker/frontend/shared/infra/docs), branch protections, CODEOWNERS, PR/issue templates with traceability fields |
| Local/dev environment | Reproducible stack (PostgreSQL, Redis, API, worker test environment), configuration validation, no production secrets |
| CI skeleton | Lint/format, dependency/secret scan, basic test matrix, migration validation stub, API contract diff stub, IaC/security review stub |
| IaC skeleton | Environment definitions (local/dev/staging/production placeholders), database/redis/observability/ci config stubs, no secret values committed |
| Config validation | Typed configuration bootstrap, environment separation, secret injection pattern (no secrets in repo/history/build artifact) |
| Foundational tests | Lint, unit stubs, repository/CI integration stubs, no business-domain implementation yet |
| Traceability setup | Traceability matrix initialized with planned Trace IDs; PR/issue template enforces traceability linkage |

**Explicit exclusions:**

- Phase 2–13 are **NOT** authorized by this record.
- Business domain implementation (document/row/column/pivot/chart lifecycle, sync, entitlement, Google integration, payment, frontend features) is out of scope.
- Production secrets, production deployment, or production-like data are out of scope.
- Schema migration beyond stub/validation (no tenant table/RLS/audit privilege enforcement yet).
- Any work that requires open implementation decisions (OID-01/02/03/etc.) to be finalized before execution must defer until those decisions are approved.

---

## 3. Applicable Trace IDs

This authorization covers foundational Trace IDs that enable later implementation but do not yet implement business invariants. Implementation must link to these Trace IDs and mark status appropriately (`Planned → In Progress → Implemented → Verified → Accepted` per Master Plan v1.0).

| Trace ID | Scope relevance | Initial status |
|---|---|---|
| REPO-STRUCT-01 | Monorepo layout, ownership boundaries | Planned |
| CI-SKELETON-01 | CI pipeline skeleton, lint/secret scan/test stubs | Planned |
| CONFIG-VALID-01 | Typed configuration bootstrap, environment separation | Planned |
| TRACE-SETUP-01 | Traceability matrix + PR/issue template enforcement | Planned |
| LOCAL-STACK-01 | Reproducible local/dev stack (PostgreSQL/Redis/API/worker) | Planned |
| SEC-SCAN-01 | Secret/dependency scanning baseline | Planned |

Business/domain/security invariant Trace IDs (ARCH-*, SYNC-*, META-*, API-*, ENT-*, SEC-*) remain `Planned` and will be addressed in later phases per Master Plan dependency order.

---

## 4. Expected Exit Evidence — Phase 1

Phase 1 will be considered complete and ready for Phase Review/CLOSED only when the following evidence is available and verified:

### Repository/branch evidence

- [ ] Monorepo structure exists with backend/worker/frontend/shared/infra/docs directories.
- [ ] Branch protections configured (protected main branch, required review, required status checks, no bypass without approval).
- [ ] CODEOWNERS assigned for critical paths (backend, worker, frontend, infra, docs/architecture, docs/implementation).
- [ ] PR and issue templates include traceability fields (Trace ID, baseline reference, change classification).

### Infrastructure/configuration evidence

- [ ] Local/dev environment reproducible (documented setup, one-command or scripted bootstrap for PostgreSQL + Redis + API + worker test environment).
- [ ] IaC skeleton present for environments (local/dev/staging/production placeholders) with no secret values committed.
- [ ] Configuration bootstrap validates required environment variables, fails safely on missing config, and separates environments.
- [ ] No production secret, token, credential, signing key, or private endpoint appears in repository/history/build artifact (verified by secret scan).

### Test/verification evidence

- [ ] CI pipeline runs lint/format, dependency scan, secret scan, basic test matrix stub, and passes on PR.
- [ ] Migration validation stub exists (Alembic configured, migration directory present, no destructive migration yet).
- [ ] API contract diff stub exists (shared/api-contract directory, baseline fixture placeholder).
- [ ] IaC/security review stub exists (infra directory, security checklist stub).
- [ ] Foundational unit/integration stubs pass (configuration validation, repository structure sanity checks).

### Security/control evidence mandated by Phase 1

- [ ] Secret scanning enabled and passing (no secret in repo/history/build artifact).
- [ ] Branch protection prevents direct push to protected branch without review/approval.
- [ ] Traceability template enforced (PR without Trace ID/baseline reference cannot merge).
- [ ] No business-domain code or tenant data access implemented yet (scope boundary respected).

### Traceability evidence

- [ ] Traceability matrix updated with Implementation IDs (repository path/PR/commit) for all scoped Trace IDs.
- [ ] Scoped Trace IDs advanced to `Implemented` with linked evidence; at least foundational subset advanced to `Verified` with passing CI/test evidence.
- [ ] Phase 1 review record created, listing evidence, approvers, and decision (CLOSED or remediation required).

---

## 5. Applicable Baseline

This authorization is granted under the following locked baseline:

- **Architecture Specification Part 1–6:** FINAL / APPROVED (immutable; changes require controlled revision).
- **Implementation Master Plan & Traceability v1.0:** FINAL / APPROVED (governs dependency order, non-negotiable rules, traceability lifecycle, phase DoD, change-control procedure).

No work under this authorization may violate or silently alter baseline contracts. Any ambiguity/conflict must follow Change-Control Procedure (Master Plan Section 21).

---

## 6. Explicit Exclusions

- **Phase 2–13 are NOT authorized.** This record does not permit database schema/RLS/audit privilege enforcement (Phase 2), auth/tenant boundary implementation (Phase 3), domain lifecycle (Phase 4), Google integration (Phase 5), `_Meta` engine (Phase 6), sync engine (Phase 7), entitlement (Phase 8), API completion (Phase 9), frontend application (Phase 10), integration/concurrency/security testing (Phase 11), staging (Phase 12), or production readiness (Phase 13).
- **Open implementation decisions (OID-01/02/03/etc.)** remain open; Phase 1 work must not depend on finalizing these decisions and must isolate/defer any adapter that requires them.
- **Production deployment** is not authorized; Phase 1 is foundation-only in local/dev/CI context.

---

## 7. Authorization Validity & Governance

- This authorization is **scope-bound, time-bound to Phase 1, and evidence-gated**. It does not auto-renew to later phases.
- Phase 1 must follow Master Plan v1.0 governance: traceability linkage, non-negotiable rules, change-control procedure, and Phase DoD (evidence before closure).
- Upon Phase 1 completion, a **Phase Review** must record decision (CLOSED or remediation) and evidence. Only after Phase 1 CLOSED can a separate explicit authorization for Phase 2 be considered.
- If architecture conflict, security issue, or baseline ambiguity is discovered during Phase 1, the work on the affected scope must stop and follow Change-Control Procedure before continuing.

---

## 8. Authorization Record

**Authorization ID:** AUTH-P1-001
**Status:** AUTHORIZED
**Authorized by:** Senior Product Manager (SheetViz Architecture Governance)
**Date authorized:** 9 September 2026
**Scope:** Phase 1 — Repository + Infrastructure Foundation only
**Baseline:** Architecture Part 1–6 FINAL / APPROVED; Master Plan v1.0 FINAL / APPROVED
**Exclusions:** Phase 2–13 NOT authorized; production deployment NOT authorized; open decisions NOT required to be finalized for Phase 1 foundation work

---

**Effect:** Implementation Phase 1 is now **UNLOCKED** for execution under Master Plan v1.0 governance. This authorization does not imply "immediate coding"; implementation must still follow `Understand → Analyze → Plan → Confirm → Implement` sequence and debugging governance (`Diagnose → Hypothesize → Verify → Confirm → Patch`) where applicable.