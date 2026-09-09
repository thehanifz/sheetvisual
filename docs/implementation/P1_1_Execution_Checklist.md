# P1.1 Repository Foundation — Execution Checklist

**Authorization:** AUTH-P1-001  
**Trace ID:** REPO-STRUCT-01  
**Status:** `Planned → In Progress → Implemented → Verified`

---

## Step 1: Create GitHub Repository

- [ ] Login ke GitHub sebagai `thehanifz`.
- [ ] Buat repository baru: **`sheetvisual`** (public/private sesuai preferensi).
- [ ] Jangan initialize dengan README/.gitignore/license.
- [ ] Catat repository URL: `https://github.com/thehanifz/sheetvisual.git`

**Evidence:** Screenshot repository baru (empty state).

---

## Step 2: Prepare Local Repository Structure

Struktur yang harus ada (artefak sudah dibuat):

```
sheetvisual/
├── README.md
├── CODEOWNERS          (bukan CODEOWNERS.txt)
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── ISSUE_TEMPLATE.md
├── backend/
│   └── .gitkeep
├── worker/
│   └── .gitkeep
├── frontend/
│   └── .gitkeep
├── shared/
│   └── .gitkeep
├── infra/
│   └── .gitkeep
└── docs/
    ├── architecture/
    │   └── .gitkeep
    └── implementation/
        └── .gitkeep
```

**Evidence:** `tree` output atau screenshot struktur direktori lokal.

---

## Step 3: Git Init, Commit, Push

```bash
cd sheetvisual  # root direktori struktur

git init
git remote add origin https://github.com/thehanifz/sheetvisual.git

git add .
git commit -m "P1.1: Repository foundation (REPO-STRUCT-01) — Initial structure, CODEOWNERS, PR/issue templates

Trace ID: REPO-STRUCT-01
Authorization: AUTH-P1-001
Baseline: Architecture Part 1–6 FINAL / APPROVED, Master Plan v1.0 FINAL / APPROVED

Deliverables:
- Monorepo structure (backend/worker/frontend/shared/infra/docs)
- CODEOWNERS (@thehanifz for all critical paths)
- PR template (Trace ID, baseline reference, change classification)
- Issue template (Trace ID, type, baseline reference)
- README.md (Phase 1 status, governance overview)

Scope: Phase 1 only. No Phase 2–13 work (database schema/RLS, auth, domain, Google, _Meta, sync, entitlement, API business, frontend, production)."

git branch -M main
git push -u origin main
```

**Evidence:**
- [ ] Initial commit hash (`git rev-parse HEAD`)
- [ ] Push output (success message)
- [ ] GitHub repository main branch view (screenshot)

---

## Step 4: Configure Branch Protection (Manual di GitHub)

1. Buka repository `thehanifz/sheetvisual` di GitHub.
2. Settings → Branches → Add rule.
3. Branch name pattern: `main`
4. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (1 approver minimum)
   - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ✅ Restrict who can push to matching branches (optional: only `thehanifz`)
   - ⏳ Require status checks to pass before merging (akan diaktifkan setelah P1.5 CI foundation selesai)
5. Save changes.

**Evidence:** Screenshot branch protection rule (Settings → Branches → rule untuk `main`).

---

## Step 5: Verify GitHub Recognition

- [ ] `CODEOWNERS` file terlihat di GitHub (bukan `CODEOWNERS.txt`).
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` dan `.github/ISSUE_TEMPLATE.md` terlihat di repository.
- [ ] `README.md` tampil di homepage repository.
- [ ] Struktur direktori (`backend/`, `worker/`, `frontend/`, `shared/`, `infra/`, `docs/`) terlihat di GitHub.

**Evidence:** Screenshot GitHub repository showing correct file names and structure.

---

## Step 6: Update Traceability Matrix

Update `docs/implementation/traceability-matrix.md` (akan dibuat di P1.2) dengan:

| Field | Value |
|---|---|
| Trace ID | REPO-STRUCT-01 |
| Implementation ID | Commit hash: `<hash>`, PR template: `.github/PULL_REQUEST_TEMPLATE.md`, Issue template: `.github/ISSUE_TEMPLATE.md`, CODEOWNERS: `/CODEOWNERS` |
| Status | `Planned → Implemented` (setelah push), `→ Verified` (setelah branch protection verified) |
| Evidence links | GitHub repository URL, branch protection screenshot, commit history link |

---

## Step 7: P1.1 Completion Criteria

P1.1 dapat dianggap **COMPLETE** dan siap untuk **P1.2 + P1.3** ketika:

- [ ] Repository GitHub `thehanifz/sheetvisual` ada dan accessible.
- [ ] Initial commit pushed ke `main` branch.
- [ ] `CODEOWNERS` file recognized by GitHub (bukan `.txt`).
- [ ] PR/issue templates visible di GitHub.
- [ ] Branch protection rule aktif (minimal PR required, 1 approver).
- [ ] Evidence terkumpul (commit hash, screenshots, repository URL).
- [ ] Traceability matrix updated dengan implementation ID dan evidence links.

---

## Next Workstream

Setelah P1.1 COMPLETE:

- **P1.2 Traceability Foundation** (TRACE-SETUP-01) — buat traceability matrix file, CI Trace ID check script stub.
- **P1.3 Configuration Foundation** (CONFIG-VALID-01) — typed config bootstrap, environment separation, validation command.

Kedua workstream dapat berjalan **paralel** setelah P1.1 selesai.

---

**Owner:** @thehanifz  
**Last updated:** 9 September 2026  
**Status:** Ready for execution