# Tim Lima Backend - API Contract & Interface Specification (Latest Version)

Dokumen ini berisi spesifikasi kontrak API resmi terbaru untuk proyek **Tim Lima Backend**, mencakup fitur **Order Management**, **Customer Tickets**, **Refund Management**, **Payment Gateway Simulation**, dan **Event & Gate Management**.

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

## 2. API Endpoints Specification

---

### A. Feature: Account & Authentication (`/users`)

#### 1. Register User (Public: Customer & Organizer)
- **Method & Path**: `POST /users/register`
- **Auth**: Public
- **Request Body**: `{ "username": "john_doe", "email": "john@example.com", "password": "Password123!", "role": "CUSTOMER" }`
- **Response 201 Created**: `UserResponseDto`

#### 2. Register Gate Operator (Organizer Only)
- **Method & Path**: `POST /users/register/gate-operator`
- **Auth**: Bearer Token (Role: `ORGANIZER` - Pemilik Event)
- **Request Body**: Array of `CreateGateOperatorDto` (atau Single Object)
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
- **Response 201 Created**: `UserResponseDto` (Array/Object)

#### 3. Login User (`POST /users/login`)
- **Auth**: Public
- **Response 200 OK**: `{ "message": "Success", "data": "<jwt_access_token>" }`

#### 4. Get Profile (`GET /users/profile`), Logout (`POST /users/logout`), Update (`PATCH /users/profile`), Delete (`DELETE /users`)

---

### B. Feature: Event Management (`/events`)

#### 1. Create Event (`POST /events`), Get All (`GET /events`), Get Organizer Events (`GET /events/organizer/me`)
#### 2. Get Event Statistics (`GET /events/:id/statistics`)
- **Auth**: Bearer Token (Role: `ORGANIZER` - Pemilik Event)
- **Response 200 OK**: `{ "eventId", "eventName", "totalQuota", "totalTicketsSold", "grossRevenue", "totalRefundCount", "totalRefundAmount", "netRevenue", "percentageSold", "refundPercentage", "categories": [...] }`
#### 3. Get Details (`GET /events/:id`), Update (`PATCH /events/:id`), Delete (`DELETE /events/:id`)

---

### C. Feature: Ticket Category (`/ticket-categories`) & Seat Management (`/seats`)

#### 1. Ticket Categories (`POST`, `GET /event/:eventId`, `GET /:id`, `PATCH /:id`, `DELETE /:id`)
#### 2. Seat Management (`POST /seats/bulk`, `GET /seats/category/:categoryId`, `GET /seats/:id`, `DELETE /seats/category/:categoryId`)

---

### D. Feature: Gate Management (`/gates`)

#### 1. Create Gate (`POST /gates`) & Get Gates by Event (`GET /gates/event/:eventId`)
#### 2. Get Gate Details (`GET /gates/:id`)
- **Auth**: Public
- **Response 200 OK**: Gate object beserta daftar `operators` (UserResponseDto[]) yang ditugaskan di gate tersebut.

---

### E. Feature: Order Management (`/orders`)

#### 1. Create Order (`POST /orders/event/:eventId`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Request Body**:
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
- **Response 201 Created**:
  ```json
  {
    "message": "Success",
    "data": {
      "orderId": "019146a0-7d1e-7abc-9a12-order0000001",
      "checkoutUrl": "https://mock-pg.team-lima.com/checkout/ZXlKcGF5bWVudElk...",
      "providerTrxId": "ZXlKcGF5bWVudElk...",
      "totalAmount": 1500000
    }
  }
  ```

#### 2. Get My Orders (`GET /orders/customer`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Response 200 OK**: Array of `OrderResponseDto` (dengan daftar `tickets`, `payments`, dan total).

#### 3. Get Order Detail (`GET /orders/customer/:id`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Response 200 OK**: Single `OrderResponseDto`

---

### F. Feature: Customer Tickets (`/tickets`)

#### 1. Get My Active Tickets (`GET /tickets/my-tickets`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Response 200 OK**: Array of `TicketResponseDto` (tiket yang memiliki status pesanan `PAID` atau `PARTIAL_REFUND` dan status tiket `AVAILABLE`).
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
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Response 200 OK**: Single `TicketResponseDto` lengkap dengan event, category, seat, order, scan, dan refund info.

---

### G. Feature: Refund Management (`/refunds`)

#### 1. Request Refund (`POST /refunds`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Request Body**:
  ```json
  {
    "ticketId": "019146a0-0000-7abc-0000-abcdef000010",
    "reason": "Saya tidak dapat hadir karena ada kepentingan mendadak"
  }
  ```
- **Response 201 Created**: `CreateRefundResponseDto` (Status refund: `PENDING`, amount dihitung otomatis berdasarkan persentase refund event).

#### 2. Get My Refund Requests (`GET /refunds/my-refunds`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Response 200 OK**: Array of `RefundResponseDto` milik Customer login.

#### 3. Get All Refund Requests (`GET /refunds`)
- **Auth**: Bearer Token (Role: `ADMIN` atau `ORGANIZER`)
- **Response 200 OK**: Array of `RefundResponseDto` (Admin: seluruh refund, Organizer: refund khusus event miliknya).

#### 4. Approve Refund (`PATCH /refunds/:id/approve`)
- **Auth**: Bearer Token (Role: `ADMIN` saja)
- **Response 200 OK**: `ApproveRefundResponseDto` (Refund status berubah menjadi `APPROVED`, status tiket menjadi `REFUND`, status pesanan diperbarui ke `FULL_REFUND` atau `PARTIAL_REFUND`).

#### 5. Reject Refund (`PATCH /refunds/:id/reject`)
- **Auth**: Bearer Token (Role: `ADMIN` saja)
- **Request Body**: `{ "rejectReason": "Bukti tidak sesuai kebijakan" }`
- **Response 200 OK**: `RejectRefundResponseDto` (Refund status berubah menjadi `REJECTED`).

---

### H. Feature: Payment Gateway Simulation (`/mock-pg`)

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
