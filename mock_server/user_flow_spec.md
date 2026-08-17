# Tim Lima Backend - User Flow & System Workflows (Latest Specification)

Dokumen ini menjelaskan seluruh **User Flow (Alur Pengguna & Bisnis)** dalam sistem Backend **Tim Lima BE**, dilengkapi dengan diagram alur visual (**Mermaid Diagrams**) dan State Machine diagram terbaru.

---

## 1. Peran Pengguna (System Roles)

1. **`CUSTOMER`**: Jelajah event -> Pilih kursi/kategori -> POST /orders/event/:id (Order Created) -> Pembayaran via Payment Gateway (`/mock-pg`) -> Dapat Tiket Aktif (`GET /tickets/my-tickets`) -> Pengajuan Refund (`POST /refunds`).
2. **`ORGANIZER`**: Setup Event & Kategori Tiket -> Bulk Seats -> Daftarkan Gate & Penugasan Gate Operator (`POST /users/register/gate-operator` dengan `gateId`) -> Pantau Statistik & Revenue (`GET /events/:id/statistics`) & Monitoring Refund.
3. **`GATE_OPERATOR`**: Ditugaskan pada `gateId` tertentu. Melakukan pemindaian QR Tiket di pintu masuk (*Gate Admission Scan*).
4. **`ADMIN`**: Peninjauan dan persetujuan pengajuan refund (`PATCH /refunds/:id/approve` / `PATCH /refunds/:id/reject`) dan pengawasan sistem secara menyeluruh.

---

## 2. Diagram Alur Utama (End-to-End System Flow)

```mermaid
flowchart TD
    subgraph Auth["1. Autentikasi & Sesi"]
        A[User Baru] --> B{Pilih Role}
        B -->|Customer / Organizer| C[POST /users/register]
        C --> E[POST /users/login -> Token JWT]
    end

    subgraph OrganizerFlow["2. Event Setup & Gate Assignment (Organizer)"]
        E -->|Role: ORGANIZER| F[POST /events - Buat Event]
        F --> G[POST /ticket-categories - Tambah Kategori Tiket]
        G --> H[POST /seats/bulk - Generate Kursi]
        F --> K[POST /gates - Daftarkan Gate Pintu Masuk]
        K --> K2[POST /users/register/gate-operator - Daftarkan Operator ke Gate]
        F --> L2[GET /events/:id/statistics - Pantau Laporan Revenue]
    end

    subgraph CustomerOrderFlow["3. Pemesanan, Checkout & Bayar (Customer)"]
        E -->|Role: CUSTOMER| L[GET /events - Pilih Event]
        L --> M[POST /orders/event/:eventId - Buat Order - Status: HELD]
        M --> P[POST /mock-pg/transaction - Terima Checkout URL & Snap Token]
        P --> Q[POST /mock-pg/simulate-payment - User Bayar di Mock PG]
        Q -->|Berhasil| R[Order Status: PAID / Ticket Status: AVAILABLE]
        Q -->|Gagal / Timeout| S[Order Status: EXPIRED / Cancelled]
        R --> T[GET /tickets/my-tickets - Lihat Tiket Saya]
    end

    subgraph RefundFlow["4. Alur Pengajuan & Approving Refund"]
        T --> U[POST /refunds - Ajukan Refund Tiket]
        U --> V[Status Refund: PENDING]
        V --> W{Keputusan Admin}
        W -->|Approve| X[PATCH /refunds/:id/approve -> Refund: APPROVED, Ticket: REFUND, Order: PARTIAL/FULL_REFUND]
        W -->|Reject| Y[PATCH /refunds/:id/reject -> Refund: REJECTED]
    end

    subgraph GateFlow["5. Gate Admission (Gate Operator)"]
        E -->|Role: GATE_OPERATOR| Z1[GET /gates/operator/assigned - Ambil Gate & Event Info]
        Z1 --> Z2[GET /scans - Pantau Total Tiket vs Total Scanned]
        Z2 --> Z3[POST /scans - Scan QR Tiket Pengunjung di Gate]
        Z3 --> AA{Validasi Tiket & Status Order}
        AA -->|Paid & Available| AB[Ticket Status -> SEATED & Record AdmissionScan]
        AA -->|Already Scanned / Not Paid| AC[Return 409 Conflict - Deny Entry]
    end
```

---

## 3. Detail Sub-Flow & Diagram Spesifik

### 3.1 Alur Pemesanan (Order) & Simulasi Pembayaran Payment Gateway

```mermaid
sequenceDiagram
    autonumber
    actor Customer as Customer (App)
    participant OrderCtrl as Order Controller
    participant MockPG as Mock PG Controller
    participant DB as Database (Postgres)

    Customer->>OrderCtrl: POST /orders/event/:eventId (Body: seats array)
    OrderCtrl->>DB: Check Category Quota & Seat Availability
    OrderCtrl->>DB: Save Order (Status: HELD), Tickets, & Payment (Status: PENDING)
    OrderCtrl->>MockPG: POST /mock-pg/transaction (paymentId, orderId, amount)
    MockPG-->>OrderCtrl: Snap Token & Checkout URL
    OrderCtrl-->>Customer: 201 Created (orderId, checkoutUrl, providerTrxId)

    Customer->>MockPG: POST /mock-pg/simulate-payment (providerTrxId, paymentMethod)
    MockPG->>DB: Update Payment Status = SUCCESS
    MockPG->>DB: Update Order Status = PAID
    MockPG-->>Customer: 200 OK (data: true)
```

---

### 3.2 Alur Pengajuan Refund & Persetujuan Admin

```mermaid
sequenceDiagram
    autonumber
    actor Customer as Customer
    actor Admin as Admin
    participant RefundCtrl as Refund Controller
    participant MockPG as Mock PG Service
    participant DB as Database

    Customer->>RefundCtrl: POST /refunds (ticketId, reason)
    RefundCtrl->>DB: Validate Order Status (PAID) & Ticket Status (AVAILABLE) & refundEndDate
    RefundCtrl->>DB: Save Refund (Status: PENDING, amount calculated)
    RefundCtrl-->>Customer: 201 Created (CreateRefundResponse)

    Admin->>RefundCtrl: PATCH /refunds/:id/approve (Header: Admin Token)
    RefundCtrl->>MockPG: processRefund (amount, ticketId)
    RefundCtrl->>DB: Update Refund Status = APPROVED
    RefundCtrl->>DB: Update Ticket Status = REFUND
    RefundCtrl->>DB: Update Order Status = PARTIAL_REFUND / FULL_REFUND
    RefundCtrl-->>Admin: 200 OK (ApproveRefundResponse)
```

---

### 3.3 State Machine: Refund Lifecycle

```mermaid
stateDiagram-v2
    [*] --> PENDING: Customer Submit Refund (POST /refunds)
    PENDING --> APPROVED: Admin Approve (PATCH /refunds/:id/approve)
    PENDING --> REJECTED: Admin Reject (PATCH /refunds/:id/reject)
    APPROVED --> [*]: Dana Dikembalikan ke Customer
    REJECTED --> [*]: Tiket Tetap AVAILABLE untuk Dipakai
```

---

## 4. Ringkasan Business Rules Utama

1. **Order Creation & Hold Constraints**:
   - Pemesanan (`POST /orders/event/:eventId`) memverifikasi sisa kuota kategori dan ketersediaan kursi.
   - Jika berhasil, pesanan masuk ke status `HELD` dan diberikan Snap Token pembayaran dari Mock PG.
2. **Refund Rules**:
   - Pengajuan refund (`POST /refunds`) hanya diperbolehkan jika tiket milik pengguna, status pesanan `PAID` / `PARTIAL_REFUND`, tiket berstatus `AVAILABLE`, dan waktu belum melewati `event.refundEndDate`.
   - Admin menyetujui refund via `PATCH /refunds/:id/approve` yang otomatis mengubah status tiket ke `REFUND` dan status pesanan ke `FULL_REFUND` (jika tidak ada tiket aktif tersisa) atau `PARTIAL_REFUND`.
3. **Gate Operator Assignment**:
   - Detail Gate (`GET /gates/:id` & `GET /gates/event/:eventId`) menyajikan perincian daftar petugas gerbang (`operators`) yang ditugaskan di gate tersebut.
