# SheetViz

**Repository:** thehanifz/sheetvisual  
**Primary branch:** `main`  
**Owner:** thehanifz  
**Current phase:** Phase 1 — Repository + Infrastructure Foundation (UNLOCKED via AUTH-P1-001)

---

## Purpose

SheetViz adalah aplikasi visualisasi data berbasis Google Sheets dengan entitlement management, sync engine, dan security model yang terkunci melalui Architecture Specification Part 1–6.

Repository ini berisi seluruh kode backend (FastAPI), worker (Celery), frontend (PWA), shared artifacts, infrastructure configuration, dan dokumentasi architecture/implementation.

---

## Phase 1 Status

**Authorization:** AUTH-P1-001 (Phase 1 UNLOCKED, Phase 2–13 LOCKED)

**Scope Phase 1:**

- ✅ Repository structure & ownership (REPO-STRUCT-01)
- ⏳ Traceability foundation (TRACE-SETUP-01)
- ⏳ Configuration foundation (CONFIG-VALID-01)
- ⏳ Local infrastructure (LOCAL-STACK-01)
- ⏳ CI foundation (CI-SKELETON-01)
- ⏳ Security baseline (SEC-SCAN-01)

**Out of scope (Phase 1):** database schema production, RLS enforcement, auth/tenant implementation, domain lifecycle, Google integration, `_Meta` engine, sync engine, entitlement engine, API business implementation, frontend application, production deployment.

---

## Local Development (Phase 1 placeholder)

Local stack (PostgreSQL + Redis + API + worker) akan di-setup di Phase 1.4. Untuk saat ini, repository structure dan governance sedang dibangun.

---

## Governance

- **Architecture baseline:** Part 1–6 FINAL / APPROVED (immutable tanpa controlled revision).
- **Implementation Master Plan:** v1.0 FINAL / APPROVED.
- **Traceability:** setiap PR/issue wajib menyertakan Trace ID dan baseline reference.
- **Branch protection:** `main` branch protected dengan required PR review dan status checks (akan diaktifkan setelah CI foundation selesai).
- **Security:** secret/dependency scanning akan diwajibkan setelah security baseline selesai.

---

## Traceability

Lihat `docs/implementation/traceability-matrix.md` untuk mapping Trace ID → implementation evidence.

---

## Authorization

**AUTH-P1-001:** Phase 1 UNLOCKED. Phase 2–13 tetap LOCKED dan memerlukan explicit authorization terpisah.

---

**Last updated:** 9 September 2026  
**Phase:** 1 — Repository Foundation (P1.1)