# Architecture Specification v1.0 — SheetViz

## Controlled Revision: Bagian 4 — API Contract

**Baseline yang direvisi:** Bagian 4 v2 (FINAL / APPROVED)
**Dependencies:** Bagian 1 v3.1 (FINAL / APPROVED — Controlled Revision), Bagian 5 v2 (FINAL / APPROVED)
**Tanggal:** 9 September 2026
**Versi controlled revision:** v3.1
**Status:** Draft untuk Final Verification
**Scope revisi:** Tambahan read allocation, manual override, dan restore allocation; extension error details. Seluruh endpoint, envelope, authentication, idempotency, request/correlation/operation model Bagian 4 v2 tetap berlaku dan tidak didesain ulang.

---

## CR-4.1 Ringkasan Controlled Changes

| ID | Perubahan | Alasan | Dampak |
|---|---|---|---|
| CR4-A | Tambah `GET /api/v1/billing/allocations` | User perlu melihat alokasi slot, candidate archive, dan deadline sebagai dasar override | Read-only owner-scoped list untuk document/pivot; quota selalu array agar konsisten untuk filter opsional |
| CR4-B | Tambah `POST /api/v1/billing/allocations/override` | User perlu memilih resource yang dipertahankan sebelum grace deadline | Mengubah allocation/queue secara atomik dan idempotent; lock entitlement lalu relevant allocation rows |
| CR4-C | Tambah `POST /api/v1/billing/allocations/{allocation_id}/restore` | User perlu memulihkan resource dan allocation archived jika slot tersedia | Lock entitlement lalu atomic reserve/restore untuk allocation **dan lifecycle resource** |
| CR4-D | Extension error contract | Bagian 5 menetapkan error entitlement/lifecycle/ownership/anomaly | Tambah detail aman bagi error yang sudah dikontrak; tidak mengubah global envelope |
| CR4-E | Operational correlation mapping | Memastikan audit/API/job bisa dikorelasikan tanpa mengubah model Bagian 4 | `request_id`, `task_correlation_id`, `sync_operation_id` tetap semantics baseline |

---

## CR-4.2 Yang Tidak Berubah

Controlled revision ini **tidak mengubah** keputusan final Bagian 4 v2 berikut:

- API base path tetap `/api/v1`.
- Response envelope sukses/error, pagination, timestamp format, dan naming convention tetap mengikuti Bagian 4 v2.
- Google OAuth, document, row, column, pivot, chart, sync, share, billing subscription/payment endpoint yang telah ada tidak berubah.
- `request_id` adalah correlation identifier untuk satu HTTP request dan selalu dikembalikan pada response/error sesuai baseline.
- `task_correlation_id` adalah correlation identifier untuk background job/asynchronous work; tidak direuse sebagai idempotency key.
- `sync_operation_id` tetap milik domain sync dan tidak dibuat/dipakai oleh allocation endpoint.
- Idempotency-Key header dan persistence/replay semantics tetap persis kontrak Bagian 4 v2; tidak ada perubahan format atau scope.
- Authentication, authorization, CORS, version/mutation guard, operation model, and error envelope baseline tidak berubah.
- Tidak ada endpoint internal/admin baru dalam revision ini.

---

## CR-4.3 Shared Contract Tambahan

### CR-4.3.1 Authentication dan Ownership

Semua endpoint pada revision ini memerlukan session/JWT valid sesuai Bagian 4 v2. `user_id` **tidak boleh** diterima melalui path, query, atau body; server selalu derive dari principal terautentikasi.

Pemanggil hanya dapat melihat/memodifikasi allocation miliknya sendiri. Resource yang bukan milik pemanggil, allocation yang tidak ada, atau type/resource mismatch ditampilkan sebagai `404 RESOURCE_NOT_FOUND` untuk mencegah existence/ownership leakage.

### CR-4.3.2 Resource Type

```text
resource_type ∈ {document, pivot}
```

`document` mereferensikan `documents.id`; `pivot` mereferensikan `pivot_tables.id`. Validasi ownership server mengikuti ERD Bagian 1 v3.1: document harus dimiliki user, sedangkan pivot harus terhubung ke document yang dimiliki user.

### CR-4.3.3 Correlation Header dan Field

| Field | Sumber | Semantics pada endpoint allocation |
|---|---|---|
| `request_id` | Server/middleware Bagian 4 | Selalu ada di response dan audit event untuk request HTTP ini |
| `Idempotency-Key` | Client header | Wajib untuk endpoint `POST`; idempotency sesuai baseline Bagian 4 v2 |
| `task_correlation_id` | Server/job enqueue | Muncul hanya jika endpoint/workflow membuat atau mengembalikan background task; tidak wajib untuk synchronous success |
| `sync_operation_id` | Domain sync Bagian 2/4 | Tidak dibuat, diterima, atau dimutasi oleh endpoint allocation |
| `allocation_id` | Path/response | Identitas immutable `resource_allocations.id`; bukan correlation ID |

Jika override atau restore memicu notifikasi/asynchronous side effect, respons sukses dapat mengembalikan `task_correlation_id`. Side effect harus dikorelasikan kembali ke `request_id` pemicu melalui audit/outbox baseline, tanpa mengubah sync operation model.

### CR-4.3.4 Idempotency

- `GET` tidak membutuhkan `Idempotency-Key`.
- Kedua `POST` **wajib** memiliki header `Idempotency-Key` valid sesuai Bagian 4 v2.
- Scope idempotency adalah authenticated user + HTTP method + normalized route + key, sesuai baseline.
- Request ulang dengan key dan payload semantik identik mengembalikan response pertama tanpa mutation baru.
- Request ulang dengan key sama tetapi payload berbeda mengembalikan error idempotency baseline Bagian 4 v2 (tanpa redefinisi code/envelope oleh revision ini).
- Idempotency record, mutation allocation/queue/resource lifecycle, audit event, dan outbox/task enqueue dilakukan atomik dalam satu database transaction sesuai capability endpoint.

---

## CR-4.4 Endpoint: List Allocations

### `GET /api/v1/billing/allocations`

Menampilkan allocation user terautentikasi untuk transparansi quota, grace planning, dan pemilihan manual override.

#### Query Parameters

| Parameter | Type | Wajib | Aturan |
|---|---|---:|---|
| `resource_type` | string | Tidak | Jika ada, harus `document` atau `pivot` |
| `status` | string | Tidak | Salah satu `active`, `pending_archive`, `archived`, `released` |
| `include_resolved_queue` | boolean | Tidak | Default `false`; jika `true`, sertakan latest resolved queue summary |
| `limit` | integer | Tidak | Pagination baseline Bagian 4 v2 |
| `cursor` | string | Tidak | Pagination baseline Bagian 4 v2 |

#### Quota Response Rule (P1)

Field `quota` **selalu array**, karena `resource_type` bersifat optional:

- Tanpa `resource_type`: server mengembalikan quota untuk **document dan pivot**, dalam urutan stabil `document`, lalu `pivot`.
- Dengan `?resource_type=document` atau `?resource_type=pivot`: server mengembalikan array dengan tepat satu item untuk type tersebut.
- Filter `status` hanya memfilter `items`; ia tidak mengubah basis perhitungan quota. `allocated_count` selalu menghitung seluruh allocation `active + pending_archive` user untuk resource type terkait.

#### Success `200 OK` — tanpa `resource_type`

```json
{
  "data": {
    "items": [
      {
        "allocation_id": "a1c2d3e4-0000-4000-8000-000000000001",
        "resource_type": "document",
        "resource_id": "d1c2d3e4-0000-4000-8000-000000000001",
        "allocation_status": "pending_archive",
        "allocation_source": "subscription",
        "allocated_at": "2026-09-09T08:00:00Z",
        "released_at": null,
        "queue": {
          "allocation_reason": "LIFO",
          "notify_at": "2026-09-09T08:00:00Z",
          "deadline_at": "2026-09-12T08:00:00Z",
          "resolved_at": null,
          "resolved_by": null
        }
      }
    ],
    "quota": [
      {
        "resource_type": "document",
        "effective_entitled": 3,
        "allocated_count": 5,
        "available": 0,
        "excess": 2,
        "projected_entitled": 3,
        "projected_excess": 2
      },
      {
        "resource_type": "pivot",
        "effective_entitled": 3,
        "allocated_count": 1,
        "available": 2,
        "excess": 0,
        "projected_entitled": null,
        "projected_excess": null
      }
    ],
    "page": {
      "next_cursor": null,
      "has_more": false
    }
  },
  "request_id": "req_01J..."
}
```

#### Success `200 OK` — dengan `?resource_type=document`

```json
{
  "data": {
    "items": [],
    "quota": [
      {
        "resource_type": "document",
        "effective_entitled": 3,
        "allocated_count": 2,
        "available": 1,
        "excess": 0,
        "projected_entitled": null,
        "projected_excess": null
      }
    ],
    "page": {
      "next_cursor": null,
      "has_more": false
    }
  },
  "request_id": "req_01J..."
}
```

Untuk setiap quota item, aturan Bagian 5 berlaku: `allocated_count` menghitung `active + pending_archive`; `available = max(0, effective_entitled - allocated_count)`; `excess = max(0, allocated_count - effective_entitled)`; dan `projected_excess = max(0, allocated_count - projected_entitled)`. `projected_entitled`/`projected_excess` bernilai `null` bila resource type tersebut tidak memiliki allocation plan lifecycle mendatang yang relevan.

#### Error

| Kondisi | HTTP | Code |
|---|---:|---|
| Tidak terautentikasi | Baseline | Baseline Bagian 4 v2 |
| `resource_type`/`status` invalid | 400 | `VALIDATION_ERROR` |

---

## CR-4.5 Endpoint: Manual Override

### `POST /api/v1/billing/allocations/override`

Memilih resource yang dipertahankan selama allocation plan H-3. Endpoint hanya dapat dipakai sebelum `deadline_at` dan hanya terhadap candidate allocation plan yang unresolved.

#### Headers

```http
Idempotency-Key: <key sesuai baseline Bagian 4 v2>
Content-Type: application/json
```

#### Request Body

```json
{
  "resource_type": "document",
  "preserve_allocation_ids": [
    "a1c2d3e4-0000-4000-8000-000000000001",
    "a1c2d3e4-0000-4000-8000-000000000002"
  ]
}
```

| Field | Type | Wajib | Aturan |
|---|---|---:|---|
| `resource_type` | string | Ya | `document` atau `pivot` |
| `preserve_allocation_ids` | UUID[] | Ya | Non-empty, unique UUID, semua allocation owner-scoped dan sesuai `resource_type` |

#### Atomic Server Behavior (P1 Locking Clarification)

1. Resolve authenticated `user_id`; validasi header idempotency sesuai baseline.
2. Mulai transaction dan `SELECT entitlements ... FOR UPDATE` untuk user sebagai mutex per-user.
3. Setelah entitlement lock diperoleh, `SELECT` seluruh relevant allocation dengan `allocation_status IN ('active', 'pending_archive')` untuk `user_id` dan `resource_type`, **`FOR UPDATE`**. Ambil juga queue unresolved terkait dengan lock yang sesuai sebelum mutation.
4. Validasi ownership, resource/type cross-check, queue consistency, dan `deadline_at`.
5. Resolve `projected_entitled` dari allocation plan lifecycle yang aktif; server tidak menerima quota dari client.
6. Tolak jika jumlah preserve selection melebihi `projected_entitled`, atau selection tidak valid terhadap plan H-3.
7. Set selected candidate menjadi `active`; hitung ulang candidate lain secara deterministic LIFO dan set yang perlu dipertahankan sebagai `pending_archive`.
8. Buat/update/resolve queue secara atomik agar tepat satu queue unresolved berlaku per allocation `pending_archive`.
9. Tulis idempotency record, audit event, dan outbox notification bila diperlukan; commit.

Lock order wajib: **entitlement → relevant allocation rows → related queue rows → resource row bila lifecycle resource harus diverifikasi/mutasi**. Endpoint tidak membuat atau mengubah `sync_operation_id`, dan tidak mengubah effective entitlement; override hanya memodifikasi candidate allocation plan berdasarkan projected entitlement Bagian 5.

#### Success `200 OK`

```json
{
  "data": {
    "resource_type": "document",
    "projected_entitled": 3,
    "preserved_allocation_ids": [
      "a1c2d3e4-0000-4000-8000-000000000001",
      "a1c2d3e4-0000-4000-8000-000000000002"
    ],
    "pending_archive_allocation_ids": [
      "a1c2d3e4-0000-4000-8000-000000000003"
    ],
    "deadline_at": "2026-09-12T08:00:00Z"
  },
  "request_id": "req_01J..."
}
```

Jika notification asynchronous dibuat, respons dapat menyertakan `task_correlation_id` pada envelope/metadata sesuai convention Bagian 4 v2.

#### Error

| Kondisi | HTTP | Code | Details aman minimum |
|---|---:|---|---|
| Body/type/ID duplicate atau format invalid | 400 | `VALIDATION_ERROR` | `field`, `reason` |
| Preserve selection > projected quota | 400 | `VALIDATION_ERROR` | `resource_type`, `max_preserve_count` |
| Allocation/resource bukan milik user, tidak ada, atau type mismatch | 404 | `RESOURCE_NOT_FOUND` | `allocation_id` bila aman/baseline mengizinkan |
| Tidak ada active unresolved H-3 plan | 422 | `INVALID_STATE_TRANSITION` | `resource_type`, `current_state` |
| Deadline sudah lewat | 422 | `INVALID_STATE_TRANSITION` | `deadline_at`, `current_state` |
| Mismatch allocation/queue/ownership terdeteksi | 409 | `VERSION_ANOMALY` | `support_reference` |
| Concurrent/reconciliation transition conflict | 409 | `INVALID_STATE_TRANSITION` | `retry_after` optional |

---

## CR-4.6 Endpoint: Restore Allocation

### `POST /api/v1/billing/allocations/{allocation_id}/restore`

Mengembalikan allocation `archived` menjadi `active` **dan mengaktifkan kembali lifecycle resource terkait** jika resource tetap valid dan quota efektif saat ini memiliki slot. Endpoint ini tidak membuat `resource_allocations` baru; ia mengaktifkan kembali record allocation yang sama sesuai unique `(resource_type, resource_id)` pada Bagian 1 v3.1.

#### Path Parameters

| Parameter | Type | Aturan |
|---|---|---|
| `allocation_id` | UUID | Harus allocation owner-scoped milik user terautentikasi |

#### Headers

```http
Idempotency-Key: <key sesuai baseline Bagian 4 v2>
Content-Type: application/json
```

#### Request Body

```json
{}
```

Body kosong wajib dikirim sebagai JSON object. Tidak ada `user_id`, `resource_type`, `resource_id`, atau quota yang diterima dari client; seluruhnya berasal dari allocation record dan entitlement server.

#### Atomic Server Behavior (P0 Resource Lifecycle Fix)

1. Resolve authenticated `user_id`; validasi idempotency header sesuai baseline.
2. Mulai transaction, lookup allocation owner-scoped, lalu `SELECT entitlements ... FOR UPDATE` sebagai mutex per user.
3. Lock allocation dan resource terkait sesuai type/resource ID; pastikan allocation berstatus `archived`. `active`, `pending_archive`, atau `released` ditolak sebagai state transition invalid.
4. Validasi kembali existence, type, ownership, dan lifecycle resource berdasarkan ERD Bagian 1 v3.1.
5. Hitung `allocated_count = active + pending_archive` untuk `resource_type` allocation, tanpa `FOR UPDATE` pada aggregate `COUNT(*)`.
6. Ambil quota effective server-side; jika `allocated_count >= effective_entitled`, reject tanpa mutation.
7. Setelah quota lolos, dalam transaction yang sama: ubah **allocation record yang sama** menjadi `active`; ubah **lifecycle resource terkait** menjadi `active` dengan lifecycle field/state yang sudah didefinisikan oleh resource tersebut (tanpa menciptakan enum baru); set `resource_allocations.released_at = NULL`; resolve/cancel queue terkait bila terdapat queue inconsistency.
8. Tulis idempotency record, audit event, dan outbox/task enqueue atomik, lalu commit.

Lock order wajib: **entitlement → allocation → resource → related queue**. Endpoint tidak membuat resource atau allocation record baru, tidak mengubah entitlement, dan tidak membuat/mengubah `sync_operation_id`. Setelah commit, invariant yang wajib berlaku adalah `allocation_status = active` dan lifecycle resource = `active`.

#### Success `200 OK`

```json
{
  "data": {
    "allocation_id": "a1c2d3e4-0000-4000-8000-000000000001",
    "resource_type": "document",
    "resource_id": "d1c2d3e4-0000-4000-8000-000000000001",
    "allocation_status": "active",
    "resource_lifecycle_status": "active",
    "allocated_at": "2026-08-01T10:00:00Z",
    "released_at": null,
    "restored_at": "2026-09-09T08:30:00Z",
    "quota": {
      "effective_entitled": 3,
      "allocated_count": 3,
      "available": 0
    }
  },
  "request_id": "req_01J..."
}
```

#### Error

| Kondisi | HTTP | Code | Details aman minimum |
|---|---:|---|---|
| `allocation_id` tidak valid format | 400 | `VALIDATION_ERROR` | `field`, `reason` |
| Allocation tidak ditemukan/tidak dimiliki | 404 | `RESOURCE_NOT_FOUND` | — |
| Allocation bukan `archived` atau resource lifecycle tidak dapat dipulihkan | 422 | `INVALID_STATE_TRANSITION` | `current_state` |
| Quota tidak tersedia | 422 | `ENTITLEMENT_REQUIRED` | `resource_type`, `effective_entitled`, `allocated_count`, `available` |
| Allocation-resource ownership/type mismatch | 409 | `VERSION_ANOMALY` | `support_reference` |
| Concurrent transition/reconciliation conflict | 409 | `INVALID_STATE_TRANSITION` | `retry_after` optional |

---

## CR-4.7 Error Contract Extension

Semua error mengikuti envelope Bagian 4 v2. Berikut adalah additional usage/detail constraints; tidak ada error envelope baru.

| Code | HTTP umum | Dipakai untuk | Detail yang boleh dikembalikan |
|---|---:|---|---|
| `ENTITLEMENT_REQUIRED` | 422 | Create/restore ditolak karena slot quota tidak tersedia | `resource_type`, `effective_entitled`, `allocated_count`, `available` |
| `VALIDATION_ERROR` | 400 | Field/body/query invalid atau preserve count melampaui projected quota | `field`, `reason`, `resource_type`, `max_preserve_count` |
| `RESOURCE_NOT_FOUND` | 404 | Allocation/resource tidak ada, bukan owner, atau type mismatch | Tidak membocorkan owner/keberadaan; hanya ID bila baseline mengizinkan |
| `INVALID_STATE_TRANSITION` | 422/409 | Override di luar window, restore state invalid, atau transition konflik | `current_state`, `deadline_at`, `retry_after` bila relevan |
| `VERSION_ANOMALY` | 409 | Allocation/queue/resource ownership/integrity mismatch | `support_reference`; tanpa object detail sensitif |

`ENTITLEMENT_REQUIRED` adalah rejection bisnis yang expected, bukan server error. `VERSION_ANOMALY` adalah integrity/anomaly signal dan wajib menghasilkan audit/security alert sesuai Bagian 6 nanti.

---

## CR-4.8 Response Field Semantics

| Field | Semantics |
|---|---|
| `effective_entitled` | Quota efektif user saat response disusun |
| `allocated_count` | Count allocation `active + pending_archive` untuk resource type |
| `available` | `max(0, effective_entitled - allocated_count)` |
| `excess` | `max(0, allocated_count - effective_entitled)` |
| `projected_entitled` | Quota yang berlaku setelah lifecycle expiry yang sedang memiliki active plan; `null` jika tidak relevan |
| `projected_excess` | `max(0, allocated_count - projected_entitled)`; `null` jika projected entitlement null |
| `deadline_at` | Deadline plan terkait; bukan claim bahwa resource telah inaccessible sebelum waktu ini |
| `pending_archive` | Planning state, tetap mengonsumsi slot tetapi akses normal hingga deadline sesuai Bagian 5 |
| `resource_lifecycle_status` | Lifecycle state aktual resource; restore success menjamin nilai `active` |
| `released_at` | Waktu allocation dilepas/diarchive sesuai lifecycle persistence Bagian 1; `null` ketika allocation aktif |

---

## CR-4.9 Security & Privacy Boundary

- Semua lookup allocation selalu owner-scoped memakai principal terautentikasi; tidak ada `user_id` client-controlled.
- Endpoint list tidak mengekspos document/pivot content atau owner identifier lain; hanya allocation metadata yang diperlukan untuk billing lifecycle.
- Untuk `404 RESOURCE_NOT_FOUND`, server tidak membedakan resource tidak ada, tidak dimiliki, atau type mismatch.
- `VERSION_ANOMALY` tidak mengekspos mismatch detail; gunakan `support_reference` dan audit internal.
- Idempotency-Key disimpan dan diproses sesuai retention/security policy Bagian 4 v2; key tidak ditulis ke client-visible audit metadata.
- Audit event minimum: actor user ID internal, allocation ID, resource type, before/after allocation dan resource lifecycle status, projected/effective quota snapshot, `request_id`, idempotency outcome, dan `task_correlation_id` bila ada.

---

## CR-4.10 Compatibility & Non-Goals

| Area | Keputusan |
|---|---|
| Existing API | Tidak ada request/response existing yang diubah |
| Sync API | Tidak menggunakan `sync_operation_id`; tidak mengubah sync contract |
| Payment/subscription API | Tidak berubah; entitlement resolver tetap domain Bagian 5 |
| Admin/reconciliation API | Tidak ditambah dalam revision ini |
| Batch override/restore lintas `resource_type` | Out of scope; satu request hanya satu `resource_type` untuk override dan satu allocation untuk restore |
| Create resource API | Existing endpoint tetap memakai enforcement Bagian 5; payload/route existing tidak diubah di dokumen ini |
| Pagination model | Mengikuti Bagian 4 v2 tanpa redefinisi |

---

## CR-4.11 Acceptance Checklist

- [ ] `GET /billing/allocations` owner-scoped, filterable document/pivot/status, dan quota **selalu array**: dua item saat resource type tidak difilter, satu item saat difilter.
- [ ] `POST /billing/allocations/override` memakai projected entitlement, hanya sebelum deadline, atomic, idempotent, dan lock `entitlements → relevant allocation rows FOR UPDATE → queue`.
- [ ] `POST /billing/allocations/{allocation_id}/restore` memakai effective entitlement, lock entitlement, recount active+pending, serta mengaktifkan **allocation dan lifecycle resource** pada transaction yang sama.
- [ ] Restore success menjamin `allocation_status = active`, `resource_lifecycle_status = active`, dan `released_at = null`.
- [ ] Tidak ada `FOR UPDATE` pada aggregate `COUNT(*)`.
- [ ] `pending_archive` dijelaskan sebagai planning state dan tetap mengonsumsi slot hingga deadline.
- [ ] Semua `POST` memakai Idempotency-Key baseline Bagian 4 v2.
- [ ] `request_id`/`task_correlation_id` digunakan tanpa redesign; `sync_operation_id` tidak dipakai endpoint allocation.
- [ ] Ownership/type mismatch tidak membocorkan eksistensi resource.
- [ ] Error contract memakai `ENTITLEMENT_REQUIRED`, `VALIDATION_ERROR`, `RESOURCE_NOT_FOUND`, `INVALID_STATE_TRANSITION`, `VERSION_ANOMALY` dengan detail aman.
- [ ] Tidak ada endpoint/API decision lain dari Bagian 4 v2 yang berubah.

---

**Status Controlled Revision Bagian 4 v3.1:** Draft untuk Final Verification. Setelah ketiga koreksi (restore lifecycle resource, quota array GET, explicit allocation row locking override) dikonfirmasi, Bagian 4 menjadi **FINAL / APPROVED (Controlled Revision)** dan proyek dapat lanjut ke **Bagian 6 — Security Model**, tanpa coding/implementasi pada tahap architecture specification ini.