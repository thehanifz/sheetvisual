# PRD: SheetViz — Visualisasi & Dashboard Google Sheets

**Versi Dokumen:** 1.4 (Architecture Freeze)
**Tanggal:** 9 September 2026
**Product Owner:** Hanif Firdaus
**Status:** FROZEN — siap diturunkan ke Architecture Specification

**Changelog v1.4:** Menutup 2 gap P0 terakhir dari review arsitektur ketiga — (1) stable `row_id` sebagai identitas baris immutable, menggantikan ketergantungan pada `row_index` yang mutable; (2) model fingerprint diperjelas menjadi tiga keadaan (`last_synced_fingerprint`/baseline, `local_fingerprint`, `remote_fingerprint`) dengan tabel kebenaran conflict eksplisit, menggantikan `row_fingerprint` tunggal yang merangkap sebagai `source_version`. Menutup 2 gap P1: klarifikasi bahwa `revisionId` hanya berfungsi sebagai spreadsheet change detector (bukan row-change detector), dan pemisahan tegas antara Data Recovery (dari Google Sheets) vs Application-State Recovery (dari backup PostgreSQL). Perbaikan tambahan: version guard diperketat dari `>=` menjadi `==` dengan state anomali eksplisit, catatan idempotency sync operation, dan penyempitan jaminan Fase 1 untuk column mapping (rename murni tanpa perubahan posisi struktural). **Tidak ada fitur baru ditambahkan** — dokumen ini menutup siklus revisi PRD dan siap diturunkan ke Architecture Specification.

---

## 1. Overview & Executive Summary

SheetViz adalah aplikasi web (PWA) yang memungkinkan siapa pun—terutama pengguna awam yang tidak familiar dengan fitur lanjutan Google Sheets—untuk membuat **pivot table custom** dan **chart interaktif** dari data Google Sheets mereka sendiri, tanpa perlu memahami formula atau fitur chart bawaan Sheets yang rumit.

Pengguna login dengan akun Google (satu kali login untuk seluruh akses: autentikasi + Sheets + Drive), lalu membuat/menghubungkan sheet, membangun pivot table, dan menjadikan hasil pivot sebagai sumber chart. Input data dua arah dijamin konsisten lewat sync state machine dengan identitas baris dan kolom yang sepenuhnya stabil (`row_id` dan `column_id`, keduanya immutable), version sequence yang ketat, dan model conflict detection tiga-keadaan (baseline/local/remote).

Arsitektur inti: **Google Sheets adalah canonical source of truth untuk data user** (baris, kolom, mapping), **PostgreSQL adalah materialized cache untuk data tersebut** sekaligus **satu-satunya sumber untuk application state** (billing, pivot config, chart config, share links, audit log) yang tidak punya representasi di Google Sheets sama sekali.

## 2. Problem Statement

Google Sheets sangat powerful, tapi mayoritas pengguna awam kesulitan memanfaatkan fitur pivot table dan chart karena kurva belajarnya cukup tinggi. SheetViz menjembatani gap ini dengan lapisan visualisasi yang disederhanakan di atas Google Sheets—data tetap "milik" user, tapi pengalaman membangun dashboard jauh lebih intuitif.

## 3. Goals & Success Metrics (KPI/OKR)

**Goals:**
- Menyediakan tools visualisasi data yang mudah dipakai pengguna non-teknis.
- Membangun model monetisasi lewat subscription/entitlement yang jelas dan adil secara UX.
- Menjamin integritas data lintas Google Sheets dan aplikasi meski terjadi edit bersamaan, insert baris, atau rename kolom.

**Success Metrics (target awal, 100 user pertama):**

| Metrik | Target v1 |
|---|---|
| Jumlah user aktif terdaftar | 100 user (batas testing OAuth) |
| Conversion rate free-to-paid | ≥5% user upgrade dalam 30 hari |
| Retention (30 hari) | ≥40% user kembali membuat/mengedit chart |
| Waktu rata-rata membuat 1 chart pertama | <5 menit sejak connect sheet |
| Tingkat kegagalan sync 2 arah | <2% dari total sync attempt |
| False-positive conflict rate | <1% (diverifikasi via model fingerprint baseline/local/remote) |
| Insiden identitas baris salah setelah insert row manual | 0 (diverifikasi via `row_id` immutable, bukan `row_index`) |
| Insiden data hilang/tertimpa akibat konflik atau race condition | 0 (zero-tolerance) |
| Uptime sistem | ≥99% (di luar maintenance terjadwal) |

## 4. Target Users & Personas

**Persona 1 — "Rina, Pemilik UMKM"** — butuh dashboard sederhana untuk performa penjualan bulanan tanpa belajar rumus.
**Persona 2 — "Budi, Staff Operasional"** — butuh input data dari HP di lapangan, PWA jadi krusial sebelum monetisasi.
**Persona 3 — "Admin Sistem (Hanif)"** — kelola harga, entitlement, monitoring, transaksi.

## 5. Scope (In-Scope / Out-of-Scope)

**In-Scope (keseluruhan v1, lintas fase):**
- Login Google OAuth tunggal.
- Connect sheet (baru/existing) dengan struktur kolom dinamis, `column_id` stabil dengan mapping eksplisit di `_Meta`.
- **Identitas baris stabil (`row_id`)**, tidak bergantung pada posisi/`row_index` yang mutable saat terjadi insert baris manual di Sheets.
- Pivot builder + chart builder dengan validasi dependency bertingkat (structural/semantic/cosmetic).
- Sync dua arah dengan state machine formal: version sequence per row (guard ketat `==`), conflict detection berbasis model fingerprint tiga-keadaan (baseline/local/remote).
- Fase 1 sync dibatasi operasi INSERT & UPDATE saja — DELETE, MOVE ROW, dan COLUMN ALTERATION ditunda ke Fase 2.
- **Jaminan column mapping Fase 1 dipersempit**: hanya rename murni tanpa perubahan posisi struktural; insert/delete/reorder kolom yang menciptakan ambiguitas otomatis masuk `SCHEMA_MAPPING_REQUIRED`.
- Share link view-only dengan token aman.
- Export chart ke PNG.
- PWA responsif dengan offline read-only cache, divalidasi sebelum billing (Fase 3).
- Model subscription/entitlement/transaction dengan aturan allocation LIFO + notifikasi override manual H-3.
- Payment Tripay/Midtrans dengan webhook verification + idempotency key.
- Admin panel lengkap.
- Data size boundary eksplisit dengan representative workload.
- **Dua jalur recovery terpisah**: Data Recovery (rebuild dari Google Sheets) dan Application-State Recovery (restore dari backup PostgreSQL).

**Out-of-Scope (v2/v3):**
- DELETE/MOVE ROW/COLUMN ALTERATION dalam sync dua arah.
- Resolusi ambiguitas column/row mapping otomatis untuk kasus kompleks (insert-di-tengah, reorder masif) — tetap manual via `SCHEMA_MAPPING_REQUIRED` di v1.
- Multi-editor real-time, share dengan akses edit.
- Export PDF/Excel/CSV, calculated field pivot, penulisan pivot balik ke Sheets.
- Offline editing (mutation queue lokal).
- Notifikasi aktif, multi-source data, white-labeling/API publik.
- Auto Insight/Auto Dashboard (kandidat kuat v2).
- Delta strategy untuk deteksi row berubah (v1 pakai full comparison saat polling; delta strategy dipertimbangkan v2 jika diperlukan).
- Verifikasi OAuth resmi, pricing berbasis resource consumption granular.
- Observability eksternal (Prometheus/Grafana) — cukup PostgreSQL + application log untuk 100 user.

## 6. User Stories & Use Cases

**US-1: Login & Onboarding** — sesuai v1.3, status `AUTH_REQUIRED` saat token di-revoke.

**US-2: Menghubungkan Sumber Data**
*Acceptance Criteria:*
- Saat connect, sistem membaca header dan men-generate `column_id` per kolom, serta men-generate `row_id` per baris data yang sudah ada, lalu menuliskan kedua mapping ini ke tab `_Meta`.
- Jika `_Meta` tidak ditemukan/rusak saat reconnect, status dokumen menjadi `SCHEMA_MAPPING_REQUIRED` untuk kolom **dan** baris — sistem meminta user mengonfirmasi ulang pemetaan secara eksplisit.

**US-3: Mendefinisikan Struktur Data dengan Identitas Kolom Stabil**
*Acceptance Criteria:*
- Rename dari aplikasi: `column_id` tetap, `_Meta` ikut disinkronkan.
- Rename langsung di Sheets (posisi kolom tidak berubah, hanya nama header): `column_id` dipertahankan.
- **Jaminan Fase 1 dipersempit**: mapping otomatis hanya berlaku untuk rename murni tanpa perubahan posisi. Jika terjadi insert/delete/reorder kolom yang membuat perbandingan posisi ambigu (misal kolom baru disisipkan di tengah), sistem **tidak menebak** — seluruh dokumen masuk status `SCHEMA_MAPPING_REQUIRED`, meminta konfirmasi manual user.
- Jika kolom dihapus dengan jelas (posisi hilang tanpa ambiguitas), `document_columns.is_deleted = true`, pivot/chart terkait mendapat status `invalid_reference`.

**US-3B: Identitas Baris Stabil Terhadap Insert Manual (Baru)**
Sebagai pengguna, saya ingin baris data saya tetap "dikenali" oleh aplikasi meskipun saya menyisipkan baris baru di Google Sheets, tanpa merusak riwayat sync atau conflict detection baris yang sudah ada.
*Acceptance Criteria:*
- Setiap baris memiliki `row_id` (UUID, immutable), terpisah dari `row_index` (posisi saat ini, mutable).
- Mapping `row_id ↔ row_index` tersimpan di `_Meta` (atau mekanisme setara), diperbarui setiap kali polling mendeteksi pergeseran posisi.
- Ketika user menyisipkan baris baru di Sheets (menggeser posisi baris-baris di bawahnya), sistem mendeteksi pergeseran melalui perbandingan konten+urutan relatif, memperbarui `row_index` baris yang bergeser tanpa mengubah `row_id`-nya, dan memberi `row_id` baru khusus untuk baris yang benar-benar baru.
- Seluruh mekanisme `mutation_version`, fingerprint, dan `sync_staging` merujuk `row_id`, bukan `row_index`.

**US-4: Membuat Pivot Table Custom** — sesuai v1.3, merujuk `column_id`.

**US-5: Membuat & Mengustomisasi Chart dengan Validasi Bertingkat** — sesuai v1.3 (structural/semantic/cosmetic).

**US-6: Input Data & Sync Satu Arah Terbatas (Fase 1) — Version Guard Diperketat**
*Acceptance Criteria:*
- Setiap perubahan pada baris (merujuk `row_id`) mendapat `mutation_version` (auto-increment per row).
- Worker mengevaluasi job dengan aturan ketat:
  - `job.mutation_version < current_version` → **STALE** → job di-drop, dicatat log, tidak di-retry.
  - `job.mutation_version == current_version` → **VALID** → dieksekusi.
  - `job.mutation_version > current_version` → **VERSION_ANOMALY** → job **dihentikan**, tidak dieksekusi diam-diam, dieskalasi untuk investigasi (kondisi ini seharusnya tidak terjadi dalam alur normal).
- Fase 1 hanya mendukung operasi **INSERT** dan **UPDATE**.
- Setiap sync operation memiliki `sync_operation_id` (idempotency key) untuk mencegah double-write jika worker gagal menerima konfirmasi sukses dari Google API akibat timeout jaringan.

**US-7: Deteksi Perubahan Manual & Resolusi Konflik dengan Model Fingerprint Tiga-Keadaan (Fase 2)**
Sebagai pengguna, saya ingin sistem membedakan dengan tepat apakah yang berubah hanya di aplikasi, hanya di Sheets, atau keduanya, sebelum memutuskan ada konflik atau tidak.
*Acceptance Criteria:*
- Setiap baris (per `row_id`) menyimpan tiga nilai fingerprint: `last_synced_fingerprint` (baseline saat terakhir kedua sisi selaras), `local_fingerprint` (kondisi data di PostgreSQL saat ini), `remote_fingerprint` (kondisi data di Sheets saat polling terakhir).
- **Tabel kebenaran resolusi:**

| baseline vs local | baseline vs remote | Kesimpulan | Aksi |
|---|---|---|---|
| Sama | Sama | Tidak ada perubahan | Tidak ada aksi |
| Berbeda | Sama | Hanya local berubah | Push local ke Sheets |
| Sama | Berbeda | Hanya remote berubah | Tarik remote ke cache |
| Berbeda | Berbeda | Kedua sisi berubah | **CONFLICT** → `SHEETS_WINS` → `CACHE_REFRESH`, `last_synced_fingerprint` diperbarui ke `remote_fingerprint` |

- **`revisionId` spreadsheet berfungsi murni sebagai pemicu ("ada sesuatu yang berubah, mulai proses pengecekan")**, bukan sebagai sumber informasi baris mana yang berubah — Google Sheets API tidak menyediakan event granular per baris, sehingga sistem melakukan full comparison fingerprint seluruh baris yang relevan setiap kali `revisionId` berubah (dibatasi oleh polling adaptif untuk menjaga beban quota).

**US-8: Share Link View-Only** — sesuai v1.3.

**US-9: Export Chart ke PNG** — sesuai v1.3.

**US-10: Upgrade Kapasitas dengan Allocation yang Adil** — sesuai v1.3 (LIFO default + H-3 override).

**US-11: Admin — Kelola Sistem** — sesuai v1.3.

## 7. Functional Requirements

| ID | Requirement | Prioritas |
|---|---|---|
| FR-1 | Login Google OAuth dengan scope Sheets, Drive, profil dalam satu alur consent | Must |
| FR-2 | Membuat file Google Sheets baru (tab "Raw Data" + "_Meta") via Drive API | Must |
| FR-3 | Membaca & memvalidasi akses sheet; generate `column_id` **dan** `row_id`, tulis mapping ke `_Meta` | Must |
| FR-4 | Mempertahankan `column_id` stabil untuk rename murni tanpa perubahan posisi struktural | Must |
| FR-5 | **Mempertahankan `row_id` stabil terhadap insert baris manual di Sheets, tidak bergantung pada `row_index`** | Must |
| FR-6 | Status `SCHEMA_MAPPING_REQUIRED` jika `_Meta` hilang/rusak, atau jika perubahan posisi kolom/baris menciptakan ambiguitas (insert-di-tengah) | Must |
| FR-7 | Builder pivot table drag-drop merujuk `column_id` | Must |
| FR-8 | Builder chart dengan validasi dependency 3 tingkat: structural/semantic/cosmetic | Must |
| FR-9 | Sync Fase 1 terbatas INSERT & UPDATE, merujuk `row_id`, dengan `mutation_version` per row | Must (Fase 1) |
| FR-10 | Worker menerapkan version guard ketat: `==` untuk valid, `<` untuk stale (drop), `>` untuk anomaly (stop & eskalasi) | Must (Fase 1) |
| FR-11 | Setiap sync operation memiliki idempotency key (`sync_operation_id`) untuk mencegah double-write saat retry | Must (Fase 1) |
| FR-12 | Conflict detection berbasis model fingerprint tiga-keadaan (baseline/local/remote) per `row_id`, bukan `revisionId` spreadsheet | Must (Fase 2) |
| FR-13 | `revisionId` diperlakukan murni sebagai pemicu pengecekan, bukan sumber informasi baris yang berubah; sistem melakukan full comparison saat revisi terdeteksi | Must (Fase 2) |
| FR-14 | Polling adaptif berdasarkan tingkat aktivitas dokumen | Must (Fase 2) |
| FR-15 | Status sync multi-dimensi: `connection_status`, `sync_status`, `last_synced_at`, `last_sync_error` | Must |
| FR-16 | Kapasitas dokumen/pivot berdasarkan entitlement; allocation LIFO default dengan opsi override manual H-3 | Must (Fase 3) |
| FR-17 | Generate/revoke/rotate share link dengan token cryptographically random | Must |
| FR-18 | Export chart ke PNG | Must |
| FR-19 | Integrasi Tripay/Midtrans dengan webhook signature verification & idempotency key | Must (Fase 3) |
| FR-20 | Soft-delete/archive (bukan hard delete otomatis) saat entitlement berkurang | Must (Fase 3) |
| FR-21 | Admin panel: harga/entitlement, monitoring, transaksi (payload dibatasi/redacted), audit log | Must (Fase 3) |
| FR-22 | PWA installable, offline read-only cache, divalidasi sebelum billing | Must |
| FR-23 | Data size boundary eksplisit dengan representative workload | Must |
| FR-24 | **Data Recovery**: `document_rows`/`document_columns`/mapping `_Meta` dapat direkonstruksi penuh dari Google Sheets | Must |
| FR-25 | **Application-State Recovery**: `pivot_tables`, `charts`, `share_links`, `subscriptions`, `transactions`, `audit_logs` dipulihkan dari backup PostgreSQL — **tidak** dapat direkonstruksi dari Google Sheets | Must |
| FR-26 | Menampilkan riwayat transaksi ke user | Must |
| FR-27 | Menangani event lifecycle dokumen dengan status semantik jelas | Should |

## 8. Non-Functional Requirements

**Performance — Representative Workload:** sesuai v1.3 (tabel workload berdasarkan jumlah baris/kolom/agregasi, batas dukungan ≤10.000 baris, warning 10.001–25.000, tidak didukung >25.000).

**Data Integrity (Revisi v1.4)**
- Setiap baris diidentifikasi oleh `row_id` immutable, bukan `row_index` yang mutable terhadap insert/pergeseran posisi.
- Setiap kolom diidentifikasi oleh `column_id` immutable, dengan jaminan mapping otomatis Fase 1 **hanya** untuk rename murni tanpa perubahan posisi struktural.
- Conflict detection menggunakan model tiga-fingerprint (baseline/local/remote) per `row_id`, bukan perbandingan tunggal atau `revisionId` spreadsheet.
- Version guard job sync bersifat ketat (`==` untuk valid), dengan state `VERSION_ANOMALY` eksplisit yang menghentikan eksekusi otomatis jika `job.mutation_version > current_version` — kondisi ini dianggap sinyal bug, bukan kasus normal untuk ditangani diam-diam.
- Setiap sync operation memiliki idempotency key untuk mencegah double-write akibat retry setelah timeout jaringan.
- `revisionId` spreadsheet diperlakukan murni sebagai *change trigger* tingkat spreadsheet, bukan sumber informasi granular baris yang berubah.

**Scalability** — sesuai v1.3 (Celery/RQ, polling adaptif).

**Security** — sesuai v1.3 (AES-256-GCM, RLS + application authorization, webhook signature + idempotency, token share link random, rate limiting, `.env` terisolasi, backup + uji restore, audit log).

**Reliability**
- Target uptime ≥99%.
- Job stale (`<`) di-drop; job anomaly (`>`) dihentikan dan dieskalasi, tidak pernah dieksekusi otomatis.
- Zero-tolerance kehilangan data akibat race condition atau kesalahan identitas baris/kolom, divalidasi lewat test skenario konflik dan test skenario insert-row/insert-column sebelum rilis Fase 2.

**Usability & Accessibility** — sesuai v1.3.

**Compliance** — sesuai v1.3.

## 9. Technical Considerations

**Stack:** tetap sesuai v1.3.

### 9.1 Skema Database (Revisi v1.4)

**Kelompok A — Admin & Platform:** tetap sesuai v1.3.

**Kelompok B — User & Data (perubahan v1.4 di-bold):**

| Tabel | Kolom Kunci |
|---|---|
| `documents` | id, user_id, nama, google_sheet_id, sheet_url, connection_status, sync_status, last_synced_at, last_sync_error, lifecycle_status, meta_mapping_status (ok/SCHEMA_MAPPING_REQUIRED), created_at |
| `document_columns` | id, column_id (UUID, immutable), document_id, nama_kolom, posisi_kolom, tipe_data, is_required, is_deleted |
| `document_rows` | id, **row_id (UUID, immutable — identitas utama)**, document_id, row_index (posisi saat ini, **mutable, bukan identitas**), row_data (JSONB, key = column_id), **last_synced_fingerprint**, **local_fingerprint**, **remote_fingerprint**, mutation_version (int), sync_state, last_synced_at, created_by, updated_at |
| `sync_staging` | id, document_id, **row_id** (bukan row_index), operasi (insert/update di Fase 1), payload (JSONB), job_mutation_version, **sync_operation_id (idempotency key)**, sync_state, attempt_count, scheduled_at |
| `pivot_tables` | id, document_id, nama, rows_config (JSONB, merujuk column_id), columns_config, values_config, config_version, created_at |
| `charts` | id, pivot_table_id, tipe_chart, styling_config (JSONB), judul, dependency_status (valid/needs_review/invalid_reference), dependency_reason, created_at |
| `share_links` | id, document_id/chart_id, token, is_active, expires_at, created_at, revoked_at |

**Tabel baru/revisi:**

| Tabel | Fungsi | Kolom Kunci |
|---|---|---|
| `row_mapping_log` (baru, paralel dengan `column_mapping_log`) | Audit trail perubahan posisi/identitas baris (insert terdeteksi, pergeseran posisi) | id, document_id, row_id, event_type (shifted/inserted/removed), detected_via, old_index, new_index, created_at |
| `column_mapping_log` | tetap sesuai v1.3 | — |
| `entitlement_allocation_queue` | tetap sesuai v1.3 | — |

**`_Meta` (tab tersembunyi di Google Sheets) — diperluas mencakup mapping baris:**

| Jenis Mapping | Kolom |
|---|---|
| Column mapping | column_id, posisi_kolom, nama_kolom_terakhir_diketahui, tipe_data |
| **Row mapping (baru)** | **row_id, posisi_baris_saat_ini** |

### 9.2 Sync State Machine Formal (Revisi v1.4 — Version Guard Diperketat)

```
CLEAN
  ↓ (user edit, merujuk row_id)
LOCAL_PENDING (mutation_version += 1)
  ↓ (staging delay ~1 menit)
SYNCING_OUT
  ↓ (worker evaluasi versi)
  ├─ job.version == current_version → VALID → tulis ke Sheets (dengan sync_operation_id)
  │     → SYNCED (update last_synced_fingerprint = remote_fingerprint baru)
  ├─ job.version < current_version → STALE → DROP, log, tidak retry
  └─ job.version > current_version → VERSION_ANOMALY → STOP, eskalasi investigasi

Paralel — Polling Adaptif (per document_id):
revisionId spreadsheet berubah (murni sebagai trigger)
  ↓
Full comparison fingerprint seluruh row_id yang relevan
  ↓
Untuk setiap row_id:
  hitung remote_fingerprint baru
  ↓
  bandingkan terhadap last_synced_fingerprint (baseline) dan local_fingerprint
  ↓
  ┌─────────────────┬──────────────────┬─────────────┐
  │ baseline≠local   │ baseline≠remote  │ Hasil       │
  ├─────────────────┼──────────────────┼─────────────┤
  │ sama             │ sama             │ NO_CHANGE   │
  │ beda             │ sama             │ PUSH_LOCAL  │
  │ sama             │ beda             │ PULL_REMOTE │
  │ beda             │ beda             │ CONFLICT →  │
  │                  │                  │ SHEETS_WINS │
  └─────────────────┴──────────────────┴─────────────┘
```

**Perubahan kunci dari v1.3:**
- Identitas baris sepenuhnya berbasis `row_id`, tidak pernah `row_index`.
- Version guard diperketat menjadi tiga kondisi eksplisit (`==`/`<`/`>`), bukan `>=`.
- Model fingerprint dipecah tiga (`baseline`/`local`/`remote`) menggantikan `row_fingerprint` tunggal.
- `revisionId` ditegaskan hanya sebagai trigger, bukan sumber informasi baris yang berubah.
- Idempotency key (`sync_operation_id`) mencegah double-write saat retry pasca-timeout.

### 9.3 Column & Row Identity Mapping via `_Meta` (Revisi v1.4)

**Column mapping** — sesuai v1.3, dengan **penyempitan jaminan Fase 1**: mapping otomatis (rename terdeteksi via posisi kolom tetap sama) hanya berlaku untuk kasus rename murni. Insert/delete/reorder kolom yang membuat posisi bergeser secara ambigu (misal kolom baru disisipkan di tengah, membuat semua kolom setelahnya "terlihat seperti rename berantai") **tidak diproses otomatis** — seluruh dokumen masuk `SCHEMA_MAPPING_REQUIRED`, meminta konfirmasi manual user melalui UI pencocokan kolom.

**Row mapping (baru di v1.4)** — mekanisme paralel untuk baris:
- Setiap baris data memiliki `row_id` (UUID) yang digenerate saat baris pertama kali masuk sistem (baik dari import awal maupun input baru).
- Mapping `row_id ↔ posisi_baris_saat_ini` tersimpan di `_Meta`, diperbarui setiap kali polling adaptif mendeteksi pergeseran.
- Ketika insert baris manual terdeteksi (baris-baris di bawah titik insert bergeser posisi tapi kontennya tetap dikenali sama), sistem memperbarui `posisi_baris_saat_ini` untuk `row_id` yang sudah ada tanpa mengubah `row_id`-nya, dan menggenerate `row_id` baru khusus untuk baris yang benar-benar baru.
- Untuk kasus ambigu (misal beberapa baris identik isinya, sehingga tidak bisa dipastikan mana yang bergeser vs mana yang baru), sistem masuk `SCHEMA_MAPPING_REQUIRED` untuk baris terkait — tidak menebak.

### 9.4 Model Billing & Allocation — tetap sesuai v1.3

Catatan tambahan untuk Architecture Specification: perlu dikunci eksplisit apakah `entitlement_allocation_queue` beroperasi pada level dokumen, level pivot, atau kombinasi keduanya — ini pertanyaan aturan bisnis yang detailnya diturunkan di tahap Entitlement Rules Engine, bukan di PRD.

### 9.5 Chart Dependency — tetap sesuai v1.3 (structural/semantic/cosmetic).

### 9.6 Recovery — Dipisah Tegas Menjadi Dua Jalur (Revisi v1.4)

**Data Recovery (dari Google Sheets — canonical source untuk data user):**
- Cakupan: `document_rows`, `document_columns`, mapping `_Meta` (column & row).
- Jika PostgreSQL cache untuk data ini hilang/corrupt, sistem menarik ulang dari tab "Raw Data" dan `_Meta`, merekonstruksi `row_id`/`column_id` sesuai mapping yang tersimpan di Sheets.
- Didokumentasikan sebagai runbook operasional.

**Application-State Recovery (dari backup PostgreSQL — tidak punya representasi di Google Sheets):**
- Cakupan: `users`, `subscriptions`, `entitlements`, `transactions`, `pivot_tables` (konfigurasi), `charts` (konfigurasi), `share_links`, `audit_logs`, `admin_settings`.
- Data ini **murni state aplikasi** — konfigurasi pivot/chart yang dibuat user, riwayat pembayaran, dan link share tidak pernah ditulis ke Google Sheets, sehingga **tidak bisa direkonstruksi** dari sana.
- Satu-satunya jalur pemulihan adalah restore dari backup PostgreSQL terjadwal (`pg_dump`) — mempertegas pentingnya kebijakan backup + uji restore berkala yang sudah ditetapkan di Non-Functional Requirements.
- **Klaim "PostgreSQL dapat direkonstruksi penuh dari Google Sheets" pada v1.3 direvisi** — hanya berlaku untuk subset data user, bukan seluruh database.

### 9.7 Tooling Manajemen Database — tetap sesuai v1.3.

## 10. UI/UX Requirements & Wireframe Notes

Tetap sesuai v1.3, dengan tambahan: **Halaman Konfirmasi Mapping** kini menangani dua jenis ambiguitas — kolom (header berubah posisi) dan baris (insert manual yang ambigu) — dengan alur konfirmasi terpisah namun pola interaksi serupa (tampilkan kondisi terkini berdampingan dengan yang dikenal aplikasi, user mencocokkan manual).

## 11. Dependencies & Risks

| Risiko | Dampak | Mitigasi |
|---|---|---|
| **Identitas baris salah setelah insert manual di Sheets, merusak seluruh mekanisme sync** | Tinggi (ditutup) | `row_id` immutable, terpisah dari `row_index` mutable |
| **Conflict detection tidak bisa membedakan "hanya local berubah" vs "hanya remote berubah" vs "keduanya berubah"** | Tinggi (ditutup) | Model fingerprint tiga-keadaan (baseline/local/remote) dengan tabel kebenaran eksplisit |
| Asumsi keliru bahwa `revisionId` memberi tahu baris spesifik yang berubah | Sedang (ditutup) | Ditegaskan `revisionId` murni trigger; full comparison dijalankan setiap kali revisi berubah |
| Version guard `>=` terlalu permisif, berpotensi mengeksekusi job anomaly diam-diam | Sedang (ditutup) | Guard diperketat jadi `==`/`<`/`>` dengan state `VERSION_ANOMALY` eksplisit |
| Klaim recovery penuh dari Sheets menyesatkan (application state tidak ada representasinya di Sheets) | Sedang (ditutup) | Dipisah tegas: Data Recovery vs Application-State Recovery |
| Insert kolom di tengah menciptakan mapping ambigu (bukan hanya rename) | Sedang (dimitigasi) | Jaminan Fase 1 dipersempit ke rename murni; kasus ambigu → `SCHEMA_MAPPING_REQUIRED` |
| Double-write akibat retry setelah timeout jaringan saat sync ke Sheets | Sedang (dimitigasi) | Idempotency key (`sync_operation_id`) per operasi sync |
| Allocation entitlement terasa tidak adil bagi user (LIFO murni) | Sedang (dimitigasi) | Notifikasi H-3 + opsi override manual |
| CRUD penuh + dynamic schema + Sheets sync di Fase 1 membuka terlalu banyak edge case | Sedang (dimitigasi) | Fase 1 dibatasi INSERT/UPDATE saja |
| Google OAuth consent screen belum verified | Tinggi | Mode testing dulu, verifikasi setelah traksi jelas |
| Quota Google Sheets API terlampaui | Tinggi | Polling adaptif, job queue, batching |
| Webhook payment dipalsukan | Tinggi | Signature verification + idempotency key |

## 12. Timeline & Milestones

Struktur 3 fase tetap sesuai v1.3, dengan penambahan validasi eksplisit di setiap fase:

**Fase 1 — Prove Product**
- Google Login, connect sheet, `column_id` + `row_id` + mapping `_Meta` (kolom & baris).
- Pivot builder + chart builder dengan validasi dependency 3 tingkat.
- Sync satu arah terbatas INSERT/UPDATE, merujuk `row_id`, dengan version guard ketat (`==`/`<`/`>`) dan idempotency key.
- **Test eksplisit**: insert baris manual di Sheets tidak merusak identitas baris yang sudah ada; insert kolom di tengah memicu `SCHEMA_MAPPING_REQUIRED`, bukan mapping otomatis yang salah.

**Fase 2 — Prove Workflow**
- Conflict detection dengan model fingerprint tiga-keadaan (baseline/local/remote).
- Polling adaptif dengan full comparison saat `revisionId` berubah.
- Data lifecycle events, `_Meta` rusak → `SCHEMA_MAPPING_REQUIRED`.
- **Test eksplisit**: skenario konflik lengkap (hanya local berubah, hanya remote berubah, keduanya berubah pada `row_id` yang sama, keduanya berubah pada `row_id` berbeda) diverifikasi menghasilkan resolusi yang benar sebelum lanjut Fase 3.

**Fase 3 — Prove Business**
1. Share link view-only + export PNG.
2. PWA hardening (divalidasi sebelum billing).
3. Subscription/entitlement/transaction + Tripay/Midtrans + webhook verification + idempotency key.
4. Kebijakan archive + `entitlement_allocation_queue` (LIFO + override H-3).
5. Admin panel lengkap, dengan **Application-State Recovery** (restore dari backup PostgreSQL) diuji sebagai bagian dari disaster recovery drill.

## 13. Open Questions

- Bahasa UI, kebijakan refund, impersonate admin, nama produk — tetap terbuka sesuai v1.3.
- Kalibrasi angka pasti batas data (10.000/25.000 baris) — perlu benchmark nyata.
- Auto Insight/Auto Dashboard — kandidat v2.
- Retensi `webhook_payload_redacted`.
- Hard delete manual — opsi user/admin di v1 atau ditunda v2?
- Window notifikasi H-3 — perlu diuji terhadap perilaku user riil.
- **Allocation entitlement beroperasi di level dokumen, pivot, atau kombinasi keduanya?** — dikunci di Architecture Specification (Entitlement Rules Engine), bukan di PRD.
- **Delta strategy untuk deteksi row berubah** (alternatif dari full comparison) — dipertimbangkan di v2 jika full comparison terbukti membebani performa/quota API pada skala lebih besar.

---

## Ringkasan Eksekutif

**Top 3 Risiko Terbesar (Setelah v1.4):**
1. **Implementasi row identity dan model fingerprint tiga-keadaan** — dua mekanisme paling fundamental yang menopang seluruh klaim zero-tolerance data loss; wajib diuji dengan skenario nyata (termasuk insert baris manual berulang kali) sebelum Fase 3.
2. **Disiplin `SCHEMA_MAPPING_REQUIRED` sebagai fallback**, bukan mencoba menebak mapping otomatis untuk kasus ambigu — godaan untuk "membuat sistem lebih pintar menebak" harus ditahan karena salah tebak identitas jauh lebih merusak daripada meminta konfirmasi manual.
3. **Kejelasan batas Data Recovery vs Application-State Recovery** — tim operasional harus paham betul bahwa backup PostgreSQL tetap mutlak diperlukan, tidak bisa mengandalkan "toh datanya ada di Sheets" sebagai jaring pengaman untuk seluruh sistem.

**Rekomendasi MVP (Fase 1 — Prove Product):** Tidak berubah dari v1.3 — Login Google, connect sheet dengan `column_id`+`row_id`+`_Meta`, pivot & chart builder dengan validasi dependency, sync satu arah terbatas INSERT/UPDATE dengan version guard ketat dan idempotency key.

**Status Dokumen — ARCHITECTURE FREEZE:** PRD v1.4 menutup seluruh siklus revisi berbasis review arsitektur. Empat gap fundamental (row identity, model fingerprint, revisionId semantics, recovery scope) sudah ditutup di level definisi. Langkah berikutnya adalah menurunkan dokumen ini menjadi **Architecture Specification** dengan struktur:

1. Database ERD (row identity, column identity, billing, lifecycle)
2. Sync Architecture (mutation sequence, fingerprint, conflict matrix, idempotency)
3. Google Sheets Mapping (`_Meta`, column mapping, row mapping, schema evolution)
4. API Contract
5. Entitlement Rules Engine
6. Security Model
7. Recovery/DR Runbook (dipisah Data Recovery vs Application-State Recovery)
8. Implementation Plan

Revisi PRD berikutnya (v1.5 dst.) sebaiknya **tidak dilakukan** kecuali ditemukan gap arsitektur baru yang setara tingkat kekritisannya dengan yang sudah ditutup di v1.2–v1.4. Penambahan fitur baru (termasuk Auto Insight) diarahkan ke dokumen backlog v2 terpisah, bukan revisi PRD v1 lebih lanjut.

---

Apakah ada bagian yang perlu diubah atau ditambahkan?
