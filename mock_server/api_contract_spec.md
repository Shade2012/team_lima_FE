# Tim Lima Backend - API Contract & Interface Specification (Latest Version)

Dokumen ini berisi spesifikasi kontrak API resmi terbaru untuk proyek **Tim Lima Backend**, mencakup fitur **Account & Auth**, **Event Management**, **Ticket Category & Seat Management**, **Gate Management**, **Order Management**, **Customer Tickets**, **Refund Management**, **Admission Scans**, dan **Payment Gateway Simulation**.

---

## 1. Standar & Konvensi Umum API

### 1.1 Base URL & Environment
- **Development Base URL**: `http://localhost:3000` (dapat disesuaikan via variabel `PORT`)
- **Protocol**: HTTP / HTTPS
- **Data Format**: `application/json`

### 1.2 Autentikasi & Otorisasi
- **Tipe Auth**: JWT (JSON Web Token) - Bearer Token
- **Header**:
  ```http
  Authorization: Bearer <jwt_access_token>
  ```
- **Durasi Token**: 24 Jam (86.400 detik)
- **Token Blacklisting**: Logout akan memasukkan token ke daftar hitam (Redis Cache) sampai expiration time berakhir.

### 1.3 Format Respon Global

#### A. Success Response (2xx)
Seluruh respon sukses dibungkus oleh `ResponseInterceptor` dalam format berikut:
```json
{
  "message": "Success",
  "data": T
}
```
*Keterangan: `data` dapat berupa Object, Array, String, atau Boolean.*

#### B. Error Response (4xx / 5xx)
Seluruh exception yang ditangkap oleh `HttpExceptionFilter` menghasilkan format:
```json
{
  "status_code": 400,
  "message": "Pesan error atau array dari deskripsi validasi DTO"
}
```

---

## 2. API Endpoints & Property Schemas Specification

---

### A. Feature: Account & Authentication (`/users`)

#### 1. Register User (`POST /users/register`)
- **Auth**: Public
- **Request Body** (`RegisterDto`):
  - `username` (`string`, required): Nama pengguna unik.
  - `email` (`string`, email format, required): Alamat email.
  - `password` (`string`, min 8 chars, required): Kata sandi pengguna.
  - `role` (`string`, enum `CUSTOMER` | `ORGANIZER`, required): Peran pengguna.
- **Response 201 Created** (`UserResponseDto`):
  - `id` (`string`, UUID v7): Unique ID pengguna.
  - `username` (`string`): Username pengguna.
  - `email` (`string`): Email pengguna.
  - `role` (`string`): Role pengguna (`CUSTOMER` | `ORGANIZER` | `GATE_OPERATOR` | `ADMIN`).
  - `createdAt` (`string`, ISO 8601): Tanggal pembuatan akun.
  - `updatedAt` (`string`, ISO 8601): Tanggal pembaruan akun.

#### 2. Register Gate Operator (`POST /users/register/gate-operator`)
- **Auth**: Bearer Token (Role: `ORGANIZER` - Pemilik Event)
- **Request Body** (`CreateGateOperatorDto[]`):
  ```json
  [
    {
      "username": "gate_operator_north",
      "email": "operator_north@example.com",
      "password": "Password123!",
      "eventId": "019146a0-7d1e-7abc-9a12-abcdef123456",
      "gateId": "019146a0-7d1e-7abc-9a12-gate00000001"
    }
  ]
  ```
  - `username` (`string`, required): Username operator gate.
  - `email` (`string`, required): Email operator gate.
  - `password` (`string`, required): Password operator gate.
  - `eventId` (`string`, UUID v7, required): ID Event yang ditugaskan.
  - `gateId` (`string`, UUID v7, required): ID Gate yang ditugaskan.
- **Response 201 Created**: Array/Single `UserResponseDto` (disertai `gateId` & `eventId`).

#### 3. Login User (`POST /users/login`)
- **Auth**: Public
- **Request Body**: `{ "email": "user@example.com", "password": "Password123!" }`
- **Response 200 OK**: `{ "message": "Success", "data": "<jwt_access_token>" }`

#### 4. User Profile (`GET /users/profile`, `PATCH /users/profile`, `DELETE /users`, `POST /users/logout`)

---

### B. Feature: Event Management (`/events`)

#### 1. Create Event (`POST /events`)
- **Auth**: Bearer Token (Role: `ORGANIZER`)
- **Request Body** (`CreateEventDto`):
  - `name` (`string`, required): Nama event.
  - `isSeated` (`boolean`, required): Apakah event memiliki tempat duduk terarah (seated).
  - `salesStartTime` (`string`, ISO Date, required): Waktu mulai penjualan tiket.
  - `salesEndTime` (`string`, ISO Date, required): Waktu akhir penjualan tiket.
  - `eventDate` (`string`, ISO Date, required): Tanggal pelaksanaan event.
  - `refundEndDate` (`string`, ISO Date, required): Batas akhir pengajuan refund.
  - `refundPolicy` (`string`, required): Deskripsi kebijakan pengembalian dana.
  - `refundPercentage` (`number`, int 0-100, required): Persentase pemotongan refund (misal 80%).

#### 2. Get Event Statistics (`GET /events/:id/statistics`)
- **Auth**: Bearer Token (Role: `ORGANIZER` owner)
- **Response 200 OK** (`EventStatisticsDto`):
  ```json
  {
    "message": "Success",
    "data": {
      "eventId": "019146a0-7d1e-7abc-9a12-abcdef123456",
      "eventName": "Konser Sheila On 7",
      "totalQuota": 500,
      "totalTicketsSold": 350,
      "grossRevenue": 525000000,
      "totalRefundCount": 5,
      "totalRefundAmount": 6000000,
      "netRevenue": 519000000,
      "percentageSold": 70.0,
      "refundPercentage": 80,
      "categories": [
        {
          "categoryId": "019146a0-7d1e-7abc-9a12-category0001",
          "categoryName": "VIP",
          "price": 1500000,
          "totalQuota": 100,
          "ticketsSold": 80,
          "revenue": 120000000
        }
      ]
    }
  }
  ```

#### 3. Public Events List (`GET /events`), Detail (`GET /events/:id`), Update (`PATCH /events/:id`), Delete (`DELETE /events/:id`)

---

### C. Feature: Ticket Category (`/ticket-categories`) & Seat Management (`/seats`)

#### 1. Create Ticket Category (`POST /ticket-categories`)
- **Auth**: Bearer Token (Role: `ORGANIZER`)
- **Request Body** (`CreateTicketCategoryDto`):
  - `eventId` (`string`, UUID v7, required): ID Event tempat kategori ini terhubung.
  - `name` (`string`, required): Nama kategori tiket (misal: `VIP`, `CAT 1`, `General Admission`).
  - `price` (`number`, int >= 0, required): Harga tiket dalam satuan rupiah (IDR).
  - `totalQuota` (`number`, int >= 1, optional): Kuota total tiket (wajib jika event non-seated).
  - `posIndex` (`number`, int >= 0, optional, default `0`): Indeks posisi urutan kategori untuk penataan layout stage UI.
  - `rows` (`number`, int >= 1, optional, nullable): Jumlah baris tempat duduk (khusus seated event).
  - `columns` (`number`, int >= 1, optional, nullable): Jumlah kolom tempat duduk (khusus seated event).
- **Response 201 Created** (`TicketCategoryResponseDto`):
  ```json
  {
    "message": "Success",
    "data": {
      "id": "019146a0-7d1e-7abc-9a12-category0001",
      "eventId": "019146a0-7d1e-7abc-9a12-abcdef123456",
      "name": "VIP",
      "price": 1500000,
      "totalQuota": 100,
      "posIndex": 1,
      "rows": 10,
      "columns": 10,
      "availableQuota": 98,
      "isAvailable": true,
      "createdAt": "2026-08-16T10:00:00.000Z",
      "updatedAt": "2026-08-16T10:00:00.000Z"
    }
  }
  ```
  - `id` (`string`, UUID v7): Unique ID kategori tiket.
  - `eventId` (`string`, UUID v7): Unique ID Event terkait.
  - `name` (`string`): Nama kategori tiket.
  - `price` (`number`): Harga per tiket (IDR).
  - `totalQuota` (`number`): Total kapasitas kuota tiket.
  - `posIndex` (`number`): Indeks urutan tata letak UI (stage layout position index).
  - `rows` (`number` | `null`): Jumlah baris kursi (jika seated event).
  - `columns` (`number` | `null`): Jumlah kolom kursi (jika seated event).
  - `availableQuota` (`number`): Sisa kuota tiket yang belum terisi/terpesan (`totalQuota - soldTickets`).
  - `isAvailable` (`boolean`): Indikator ketersediaan (`availableQuota > 0`).
  - `createdAt` (`string`, ISO 8601): Tanggal dan waktu pembuatan record.
  - `updatedAt` (`string`, ISO 8601): Tanggal dan waktu terakhir record diperbarui.

#### 2. Get Ticket Categories by Event (`GET /ticket-categories/event/:eventId`)
- **Auth**: Public
- **Response 200 OK**: Array of `TicketCategoryResponseDto` diurutkan berdasarkan harga / `posIndex`.

#### 3. Get Ticket Category Detail (`GET /ticket-categories/:id`)
- **Auth**: Public
- **Response 200 OK**: Single `TicketCategoryResponseDto`.

#### 4. Update Ticket Category (`PATCH /ticket-categories/:id`)
- **Auth**: Bearer Token (Role: `ORGANIZER` owner)
- **Request Body** (`UpdateTicketCategoryDto`):
  - `name` (`string`, optional)
  - `price` (`number`, optional)
  - `totalQuota` (`number`, optional)
  - `posIndex` (`number`, optional)
  - `rows` (`number`, optional)
  - `columns` (`number`, optional)
- **Response 200 OK**: Single `TicketCategoryResponseDto` ter-update.

#### 5. Delete Ticket Category (`DELETE /ticket-categories/:id`)
- **Auth**: Bearer Token (Role: `ORGANIZER` owner)
- **Response 200 OK**: Single `TicketCategoryResponseDto` yang dihapus.

---

#### 6. Bulk Generate Seats (`POST /seats/bulk`)
- **Auth**: Bearer Token (Role: `ORGANIZER`)
- **Request Body** (`BulkCreateSeatDto`):
  - `categoryId` (`string`, UUID v7, required): ID Kategori Tiket.
  - `prefix` (`string`, required): Prefix kode kursi (misal: `VIP`, `CAT1`).
- **Response 201 Created** (`BulkCreateSeatResponseDto`):
  ```json
  {
    "message": "Success",
    "data": {
      "seatsCreated": 100,
      "totalQuota": 100,
      "prefix": "VIP",
      "firstSeatCode": "VIP-001",
      "lastSeatCode": "VIP-100"
    }
  }
  ```

#### 7. Get Seats by Category (`GET /seats/category/:categoryId`), Detail (`GET /seats/:id`), Delete (`DELETE /seats/category/:categoryId`)
- **Response 200 OK** (`SeatResponseDto`):
  - `id` (`string`, UUID v7): ID Tempat duduk.
  - `categoryId` (`string`, UUID v7): ID Kategori.
  - `seatCode` (`string`): Kode fisik kursi (misal `VIP-001`).
  - `createdAt` (`string`, ISO 8601): Waktu pembuatan.

---

### D. Feature: Gate Management (`/gates`)

#### 1. Create Gate (`POST /gates`) & Get Gates by Event (`GET /gates/event/:eventId`)
- **Request Body**: `{ "eventId": "uuid", "name": "Gate Utama Utara" }`
- **Response 200 OK**: Array/Single Gate object menyertakan daftar `operators` (UserResponseDto[]).

#### 2. Get Assigned Gate for Operator (`GET /gates/operator/assigned`)
- **Auth**: Bearer Token (Role: `GATE_OPERATOR`)
- **Response 200 OK** (`AssignedGateResponseDto`):
  ```json
  {
    "message": "Success",
    "data": {
      "id": "019146a0-7d1e-7abc-9a12-gate00000001",
      "eventId": "019146a0-7d1e-7abc-9a12-abcdef123456",
      "name": "Gate Utama Utara",
      "event": {
        "id": "019146a0-7d1e-7abc-9a12-abcdef123456",
        "name": "Konser Sheila On 7",
        "eventDate": "2026-10-01T19:00:00.000Z"
      },
      "operators": [...]
    }
  }
  ```

#### 3. Get Gate Details (`GET /gates/:id`), Update (`PATCH /gates/:id`), Delete (`DELETE /gates/:id`)

---

### E. Feature: Order Management (`/orders`)

#### 1. Create Order (`POST /orders/event/:eventId`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Request Body** (`CreateOrderDto`):
  ```json
  {
    "seats": [
      {
        "categoryId": "019146a0-7d1e-7abc-9a12-category0001",
        "seatId": "019146a0-7d1e-7abc-9a12-seat00000001"
      }
    ]
  }
  ```
- **Response 201 Created** (`CreateOrderResponseDto`):
  ```json
  {
    "message": "Success",
    "data": {
      "orderId": "019146a0-7d1e-7abc-9a12-order0000001",
      "checkoutUrl": "https://mock-pg.team-lima.com/checkout/ZXlKcGF5...",
      "providerTrxId": "ZXlKcGF5...",
      "totalAmount": 1500000
    }
  }
  ```

#### 2. Get My Orders (`GET /orders/customer`), Get Order Detail (`GET /orders/customer/:id`), Clear (`GET /orders/clear`)
- **Response 200 OK** (`OrderResponseDto`):
  - `id` (`string`, UUID v7): ID Pesanan.
  - `customerId` (`string`, UUID v7): ID Customer.
  - `eventId` (`string`, UUID v7): ID Event.
  - `totalAmount` (`number`): Total nominal pembayaran.
  - `status` (`string`): Enum `HELD` | `PAYMENT_PENDING` | `PAID` | `CANCELLED` | `FULL_REFUND` | `PARTIAL_REFUND`.
  - `reservationKey` (`string` | `null`): Idempotency key reservasi.
  - `expiresAt` (`string`, ISO Date): Waktu kedaluwarsa pesanan.
  - `tickets` (`Array`): Daftar tiket dalam pesanan.
  - `payments` (`Array`): Transaksi pembayaran terkait.

---

### F. Feature: Customer Tickets (`/tickets`)

#### 1. Get My Active Tickets (`GET /tickets/my-tickets`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Response 200 OK** (Array of `TicketResponseDto`):
  ```json
  {
    "message": "Success",
    "data": [
      {
        "id": "019146a0-0000-7abc-0000-abcdef000010",
        "status": "AVAILABLE",
        "category": {
          "id": "019146a0-0000-7abc-0000-abcdef000002",
          "name": "VIP",
          "price": 1500000,
          "event": {
            "id": "019146a0-0000-7abc-0000-abcdef000001",
            "name": "Konser Sheila On 7",
            "eventDate": "2026-10-01T19:00:00.000Z",
            "isSeated": true
          }
        },
        "seat": {
          "id": "019146a0-0000-7abc-0000-abcdef000003",
          "seatCode": "VIP-001"
        },
        "createdAt": "2026-08-16T10:00:00.000Z"
      }
    ]
  }
  ```

#### 2. Get Ticket Detail by ID (`GET /tickets/:id`)
- **Response 200 OK**: Single `TicketResponseDto` beserta perincian `scan` dan `refund` status.

---

### G. Feature: Refund Management (`/refunds`)

#### 1. Request Refund (`POST /refunds`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Request Body** (`CreateRefundDto`): `{ "ticketId": "uuid", "reason": "Alasan refund" }`
- **Response 201 Created** (`RefundResponseDto`): Status refund `PENDING`, amount dihitung dari % refund event.

#### 2. Get My Refunds (`GET /refunds/my-refunds`), Get All Refunds (`GET /refunds`), Approve (`PATCH /refunds/:id/approve`), Reject (`PATCH /refunds/:id/reject`)

---

### H. Feature: Admission Scans (`/scans`)

#### 1. Scan Ticket (`POST /scans`)
- **Auth**: Bearer Token (Role: `GATE_OPERATOR`)
- **Request Body** (`ScanDto`): `{ "ticketId": "019ff387-745c-76cf-8f69-f5acdd2eba8" }` (UUID v7)
- **Response 201 Created**: `{ "message": "Success", "data": "Success scans" }`
- **Response 409 Conflict**: Tiket telah digunakan/scanned sebelumnya (`SEATED`) atau pesanan belum `PAID`.

#### 2. Get Total Admission Scans (`GET /scans`)
- **Auth**: Bearer Token (Role: `GATE_OPERATOR`)
- **Response 200 OK** (`TotalScansResponse`): `{ "message": "Success", "data": { "scanned": 45, "total": 100 } }`

---

### I. Feature: Payment Gateway Simulation (`/mock-pg`)

#### 1. Create Transaction (`POST /mock-pg/transaction`)
- **Request Body**: `{ "paymentId": "uuid", "orderId": "uuid", "amount": 1500000, "paymentMethod": "GOPAY" }`
- **Response 201 Created**: `{ "providerTrxId": "<snap_token>", "checkoutUrl": "https://..." }`

#### 2. Simulate Payment (`POST /mock-pg/simulate-payment`)
- **Request Body**: `{ "providerTrxId": "<snap_token>", "paymentMethod": "GOPAY" }`
- **Response 200 OK**: `{ "message": "Success", "data": true }`

---

## 3. Database Prisma Enums (Domain Enums)

```prisma
enum Role {
  CUSTOMER
  ORGANIZER
  GATE_OPERATOR
  ADMIN
}

enum TicketStatus {
  AVAILABLE
  SEATED
  CANCELLED
  EXPIRED
  REFUND
}

enum OrderStatus {
  HELD
  PAYMENT_PENDING
  PAID
  CANCELLED
  FULL_REFUND
  PARTIAL_REFUND
}

enum PaymentStatus {
  PENDING
  SUCCESS
  FAILED
}

enum PaymentMethod {
  VIRTUAL_ACCOUNT
  GOPAY
  SHOPPE_PAY
  OVO
}

enum RefundStatus {
  PENDING
  APPROVED
  REJECTED
}
```
