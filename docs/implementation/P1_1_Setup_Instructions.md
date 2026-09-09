# P1.1 Repository Foundation — Setup Instructions

**Authorization:** AUTH-P1-001  
**Trace ID:** REPO-STRUCT-01  
**Status:** `Planned → In Progress` (ready for implementation)

---

## Prerequisite Decisions (Fulfilled)

| Item | Decision |
|---|---|
| Repository provider | GitHub |
| Repository URL/path | thehanifz/sheetvisual.git |
| Primary protected branch | `main` |
| Initial owner roles | thehanifz (Backend, Worker, Frontend, Infra, Security, Architecture/Implementation Docs) |

---

## Step 1: Create GitHub Repository

1. Login ke GitHub sebagai `thehanifz`.
2. Buat repository baru: **`sheetvisual`** (public atau private sesuai preferensi).
3. Jangan initialize dengan README/.gitignore/license (kita akan push artefak lokal).
4. Catat repository URL: `https://github.com/thehanifz/sheetvisual.git`

---

## Step 2: Extract Artefak Lokal

Artefak P1.1 sudah dibuat dalam file `P1_1_RepositoryFoundation_Artifacts.zip`. Ekstrak ke direktori lokal, kemudian:

```bash
cd sheetvisual  # root direktori artefak
git init
git remote add origin https://github.com/thehanifz/sheetvisual.git
git add .
git commit -m "P1.1: Repository foundation (REPO-STRUCT-01) — Initial structure, CODEOWNERS, PR/issue templates"
git branch -M main
git push -u origin main
```

---

## Step 3: Configure Branch Protection (Manual di GitHub)

Karena GitHub API tidak tersedia untuk automation langsung, lakukan manual:

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

---

## Step 4: Verify & Collect Evidence

**Required evidence untuk REPO-STRUCT-01:**

- [ ] Repository URL: `https://github.com/thehanifz/sheetvisual`
- [ ] Screenshot branch protection rule (Settings → Branches → rule untuk `main`)
- [ ] `CODEOWNERS` file content (commit history)
- [ ] PR template content (`.github/PULL_REQUEST_TEMPLATE.md`)
- [ ] Issue template content (`.github/ISSUE_TEMPLATE.md`)
- [ ] Initial commit hash (repository foundation commit)

**Traceability update:**

- Update `docs/implementation/traceability-matrix.md` (akan dibuat di P1.2) dengan:
  - Trace ID: REPO-STRUCT-01
  - Implementation ID: commit hash, PR/issue template paths
  - Status: `In Progress → Implemented` (setelah push)
  - Verification evidence: link screenshot branch protection, commit history

---

## Step 5: Next Workstream

Setelah P1.1 selesai dan evidence terkumpul:

- **P1.2 Traceability Foundation** (TRACE-SETUP-01) — dapat mulai paralel dengan P1.3.
- **P1.3 Configuration Foundation** (CONFIG-VALID-01) — dapat mulai paralel dengan P1.2.

Lanjutkan sesuai mandatory sequence: `P1.1 → (P1.2 + P1.3) → P1.4 → P1.5 → P1.6`.

---

## Governance Reminder

- **Scope:** Phase 1 only. Jangan mulai database schema/RLS, auth, domain, Google, _Meta, sync, entitlement, API business, frontend, production.
- **Traceability:** setiap commit/PR harus linked ke Trace ID.
- **Security:** jangan commit secret/credential. Gunakan environment variable/secret manager.
- **Authorization:** AUTH-P1-001 hanya membuka Phase 1. Phase 2–13 tetap LOCKED.

---

**Owner:** @thehanifz  
**Last updated:** 9 September 2026  
**Status:** Ready for execution