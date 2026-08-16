# Mock API Server Guide

Dokumen ini berisi panduan lengkap cara menjalankan, menguji, dan mengintegrasikan **Mock API Server** untuk proyek **Tim Lima**. Mock server ini dibuat berbasis Node.js & Express.js dan menyajikan 100% kontrak API & alur bisnis sesuai spesifikasi backend.

---

## Daftar Isi

1. [Fitur & Kemampuan Mock Server](#1-fitur--kemampuan-mock-server)
2. [Cara Menjalankan Server](#2-cara-menjalankan-server)
3. [Akun & Seed Data Bawaan](#3-akun--seed-data-bawaan)
4. [Spesifikasi & Contoh Payload Endpoint](#4-spesifikasi--contoh-payload-endpoint)
   - [A. User Auth & Profile (`/users`)](#a-user-auth--profile-users)
   - [B. Event Management (`/events`)](#b-event-management-events)
   - [C. Ticket Categories (`/ticket-categories`)](#c-ticket-categories-ticket-categories)
   - [D. Seat Management (`/seats`)](#d-seat-management-seats)
   - [E. Gate Management (`/gates`)](#e-gate-management-gates)
5. [Integrasi dengan Aplikasi Flutter](#5-integrasi-dengan-aplikasi-flutter)
6. [Troubleshooting & FAQ](#6-troubleshooting--faq)

---

## 1. Fitur & Kemampuan Mock Server

- **Stateful In-Memory Store**: Perubahan data (Register User baru, Tambah Event, Generate Seats) akan tersimpan secara dinamis selama server berjalan.
- **JWT Auth Simulation**: Mensimulasikan pembuat token JWT Bearer, validasi role (`CUSTOMER`, `ORGANIZER`, `GATE_OPERATOR`), serta _blacklist token_ saat Logout.
- **Auto Bulk Seats Generation**: Secara otomatis membuat kode tempat duduk (contoh: `VIP-001` s.d `VIP-100`) sesuai kuota kategori tiket.
- **Strict Business Validation**: Memvalidasi aturan bisnis seperti:
  - Tanggal event (`salesEndTime > salesStartTime`, `eventDate > salesEndTime`).
  - Quota kategori tiket tidak boleh dikurangi di bawah jumlah tempat duduk yang ter-generate.
  - Role protection (hanya `ORGANIZER` milik event yang bisa mengedit event/tiket/gate terkait).
- **Standar Respon Global**:
  - Success Response (2xx): `{ "message": "Success", "data": ... }`
  - Error Response (4xx/5xx): `{ "status_code": 400, "message": "..." }`

---

## 2. Cara Menjalankan Server

### Prasyarat

- **Node.js** (Versi v16 atau lebih baru) & **npm**.

### Langkah-Langkah Running:

1. Buka Terminal / PowerShell dan masuk ke folder `mock_server`:

   ```bash
   cd mock_server
   ```

2. Install dependensi (hanya perlu dilakukan sekali):

   ```bash
   npm install
   ```

3. Jalankan Server:

   ```bash
   npm start
   ```

   _Untuk pengembangan (otomatis reload saat file diubah):_

   ```bash
   npm run dev
   ```

4. Server akan berjalan di **Port 3000**:
   ```text
   =================================================
   🚀 Mock API Server running on port 3000
   🌐 Base URL: http://localhost:3000
   =================================================
   ```

## 3. Akun & Seed Data Bawaan

Server sudah dilengkapi data awal (_seed data_) dari file `mock_server/data/initial_mock_data.json`:

### Data Pengguna (Users)

| Role            | Email                   | Password       | User ID                                | Keterangan                            |
| :-------------- | :---------------------- | :------------- | :------------------------------------- | :------------------------------------ |
| `CUSTOMER`      | `john@example.com`      | `Password123!` | `019146a0-7d1e-7abc-9a12-abcdef123456` | Pengunjung/Pembeli Tiket              |
| `ORGANIZER`     | `organizer@example.com` | `Password123!` | `019146a0-0000-7abc-0000-abcdef000001` | Pemilik Event                         |
| `GATE_OPERATOR` | `gateop@example.com`    | `Password123!` | `019146a0-0000-7abc-0000-abcdef000002` | Petugas Gerbang (`eventId` & `gateId` terhubung) |
| `ADMIN`         | `admin@example.com`     | `Password123!` | `019146a0-0000-7abc-0000-admin0000001` | Pengelola / Admin Sistem (Approve/Reject Refund) |

---

## 4. Spesifikasi & Contoh Payload Endpoint

---

### A. User Auth & Profile (`/users`)

#### 1. Register User (`POST /users/register`)

- **Auth**: Public
- **Headers**: `Content-Type: application/json`
- **Body Request**:
  ```json
  {
    "username": "budi_santoso",
    "email": "budi@example.com",
    "password": "Password123!",
    "role": "CUSTOMER"
  }
  ```
  _(Catatan: Role `GATE_OPERATOR` tidak diizinkan melalui endpoint ini. Gunakan `POST /users/register/gate-operator`)_
- **Response 201 Created**:
  ```json
  {
    "message": "Success",
    "data": {
      "id": "019146a0-8888-7abc-9a12-1234567890ab",
      "username": "budi_santoso",
      "email": "budi@example.com",
      "role": "CUSTOMER",
      "createdAt": "2026-08-12T11:00:00.000Z",
      "updatedAt": "2026-08-12T11:00:00.000Z"
    }
  }
  ```

#### 2. Register Gate Operator (`POST /users/register/gate-operator`)

- **Auth**: Bearer Token (Role: `ORGANIZER` - Harus pemilik event)
- **Headers**: `Authorization: Bearer <organizer_token>`, `Content-Type: application/json`
- **Body Request**: Array of `CreateGateOperatorDto` atau Single Object
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
- **Response 201 Created**:
  ```json
  {
    "message": "Success",
    "data": [
      {
        "id": "019146a0-7d1e-7abc-9a12-gateop000001",
        "username": "gate_operator_north",
        "email": "operator_north@example.com",
        "role": "GATE_OPERATOR",
        "eventId": "019146a0-7d1e-7abc-9a12-abcdef123456",
        "createdAt": "2026-08-12T10:00:00.000Z",
        "updatedAt": "2026-08-12T10:00:00.000Z"
      }
    ]
  }
  ```

#### 3. Login User (`POST /users/login`)

- **Body Request**:
  ```json
  {
    "email": "john@example.com",
    "password": "Password123!"
  }
  ```
- **Response 200 OK**:
  ```json
  {
    "message": "Success",
    "data": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMTkxNDZhMC03ZDFlLTdhYmMtOWExMi1hYmNkZWYxMjM0NTYiLCJ1c2VybmFtZSI6ImpvaG5fZG9lIiwicm9sZSI6IkNVU1RPTUVSIiwiaWF0IjoxNzU1MDAwMDAwLCJleHAiOjE3NTUwODY0MDB9.mockSignature1234567890"
  }
  ```

#### 4. Get User Profile (`GET /users/profile`)

- **Headers**: `Authorization: Bearer <jwt_access_token>`
- **Response 200 OK**:
  ```json
  {
    "message": "Success",
    "data": {
      "id": "019146a0-7d1e-7abc-9a12-abcdef123456",
      "username": "john_doe",
      "email": "john@example.com",
      "role": "CUSTOMER",
      "createdAt": "2026-08-12T10:00:00.000Z",
      "updatedAt": "2026-08-12T10:00:00.000Z"
    }
  }
  ```

---

### B. Event Management (`/events`)

#### 1. Get All Events (`GET /events`)

- **Auth**: Public
- **Response 200 OK**: Array event diurutkan berdasarkan `eventDate` ASC.
  ```json
  {
    "message": "Success",
    "data": [
      {
        "id": "019146a0-7d1e-7abc-9a12-abcdef123456",
        "organizerId": "019146a0-0000-7abc-0000-abcdef000001",
        "name": "Konser Sheila On 7 Jakarta 2026",
        "isSeated": true,
        "salesStartTime": "2026-09-01T10:00:00.000Z",
        "salesEndTime": "2026-09-15T23:59:59.000Z",
        "eventDate": "2026-10-01T19:00:00.000Z",
        "refundEndDate": "2026-09-25T23:59:59.000Z",
        "refundPolicy": "Refund dapat diajukan maksimal 7 hari sebelum event.",
        "refundPercentage": 80,
        "createdAt": "2026-08-12T10:00:00.000Z",
        "updatedAt": "2026-08-12T10:00:00.000Z"
      }
    ]
  }
  ```

#### 2. Create Event (`POST /events`)

- **Headers**: `Authorization: Bearer <organizer_token>` (Role must be `ORGANIZER`)
- **Body Request**:
  ```json
  {
    "name": "Festival Musik Bandung 2026",
    "isSeated": true,
    "salesStartTime": "2026-09-01T10:00:00.000Z",
    "salesEndTime": "2026-09-20T23:59:59.000Z",
    "eventDate": "2026-10-10T18:00:00.000Z",
    "refundEndDate": "2026-10-01T23:59:59.000Z",
    "refundPolicy": "Pengajuan refund H-9 event",
    "refundPercentage": 75
  }
  ```
- **Response 201 Created**: Object Event baru.

#### 3. Get Event Statistics (`GET /events/:id/statistics`)
- **Headers**: `Authorization: Bearer <organizer_token>` (Role must be `ORGANIZER` owner of event)
- **Response 200 OK**:
  ```json
  {
    "message": "Success",
    "data": {
      "eventId": "019146a0-7d1e-7abc-9a12-abcdef123456",
      "eventName": "Konser Sheila On 7 Jakarta 2026",
      "totalQuota": 600,
      "totalTicketsSold": 2,
      "grossRevenue": 3000000,
      "totalRefundCount": 0,
      "totalRefundAmount": 0,
      "netRevenue": 3000000,
      "percentageSold": 0.33,
      "refundPercentage": 0,
      "categories": [
        {
          "categoryId": "019146a0-7d1e-7abc-9a12-category0001",
          "categoryName": "VIP Front Row",
          "price": 1500000,
          "totalQuota": 100,
          "ticketsSold": 2,
          "grossRevenue": 3000000,
          "refundCount": 0,
          "totalRefundAmount": 0,
          "refundPercentage": 0
        }
      ]
    }
  }
  ```

---

### C. Ticket Categories (`/ticket-categories`)

#### 1. Get Categories by Event (`GET /ticket-categories/event/:eventId`)

- **Auth**: Public
- **Response 200 OK**: Array kategori tiket diurutkan dari `price` tertinggi (DESC).
  ```json
  {
    "message": "Success",
    "data": [
      {
        "id": "019146a0-7d1e-7abc-9a12-category0001",
        "eventId": "019146a0-7d1e-7abc-9a12-abcdef123456",
        "name": "VIP Front Row",
        "price": 1500000,
        "totalQuota": 100
      }
    ]
  }
  ```

#### 2. Create Ticket Category (`POST /ticket-categories`)

- **Headers**: `Authorization: Bearer <organizer_token>`
- **Body Request**:
  ```json
  {
    "eventId": "019146a0-7d1e-7abc-9a12-abcdef123456",
    "name": "CAT 1 Festival",
    "price": 950000,
    "totalQuota": 250
  }
  ```

---

### D. Seat Management (`/seats`)

#### 1. Bulk Generate Seats (`POST /seats/bulk`)

- **Headers**: `Authorization: Bearer <organizer_token>`
- **Body Request**:
  ```json
  {
    "categoryId": "019146a0-7d1e-7abc-9a12-category0001",
    "prefix": "VIP"
  }
  ```
- **Response 201 Created**:
  ```json
  {
    "message": "Success",
    "data": {
      "seatsCreated": 98,
      "totalQuota": 100,
      "prefix": "VIP",
      "firstSeatCode": "VIP-003",
      "lastSeatCode": "VIP-100"
    }
  }
  ```

#### 2. Get Seats by Category (`GET /seats/category/:categoryId`)

- **Auth**: Public
- **Response 200 OK**: Array tempat duduk diurutkan berdasarkan `seatCode` ASC.

---

### E. Gate Management (`/gates`)

#### 1. Get Gates by Event (`GET /gates/event/:eventId`)

- **Response 200 OK**: Array daftar gerbang pintu masuk beserta daftar `operators` (UserResponseDto[]).

#### 2. Get Assigned Gate for Operator (`GET /gates/operator/assigned`)

- **Auth**: Bearer Token (Role: `GATE_OPERATOR`)
- **Response 200 OK**:
  ```json
  {
    "message": "Success",
    "data": {
      "id": "019146a0-7d1e-7abc-9a12-gate00000001",
      "eventId": "019146a0-7d1e-7abc-9a12-abcdef123456",
      "name": "Gate Utama Utara",
      "event": {
        "id": "019146a0-7d1e-7abc-9a12-abcdef123456",
        "name": "Konser Sheila On 7 Jakarta 2026",
        "eventDate": "2026-10-01T19:00:00.000Z"
      },
      "operators": [...]
    }
  }
  ```

#### 3. Create Gate (`POST /gates`)

- **Headers**: `Authorization: Bearer <organizer_token>`
- **Body Request**:
  ```json
  {
    "eventId": "019146a0-7d1e-7abc-9a12-abcdef123456",
    "name": "Gate Barat Pintu B"
  }
  ```

---

### F. Payment Gateway Simulation (`/mock-pg`)

#### 1. Create Transaction / Generate Snap Token (`POST /mock-pg/transaction`)
- **Auth**: Public
- **Body Request**:
  ```json
  {
    "paymentId": "019146a0-7d1e-7abc-9a12-pay000000001",
    "orderId": "019146a0-7d1e-7abc-9a12-order0000001",
    "amount": 1500000,
    "paymentMethod": "QRIS"
  }
  ```
- **Response 201 Created**:
  ```json
  {
    "message": "Success",
    "data": {
      "providerTrxId": "ZXlKcGF5bWVudElkIjoiMDE5MTQ2YTAtN2QxZS03YWJjLTlhMTItcGF5MDAwMDAwMDAxIiwib3JkZXJJZCI6IjAxOTE0NmEwLTdkMWUtN2FiYy05YTEyLW9yZGVyMDAwMDAwMSJ9",
      "checkoutUrl": "https://mock-pg.team-lima.com/checkout/ZXlKcGF5bWVudElkIjoiMDE5MTQ2YTAtN2QxZS03YWJjLTlhMTItcGF5MDAwMDAwMDAxIiwib3JkZXJJZCI6IjAxOTE0NmEwLTdkMWUtN2FiYy05YTEyLW9yZGVyMDAwMDAwMSJ9"
    }
  }
  ```

#### 2. Simulate Payment Completion (`POST /mock-pg/simulate-payment`)
- **Auth**: Public
- **Body Request**:
  ```json
  {
    "providerTrxId": "ZXlKcGF5bWVudElkIjoiMDE5MTQ2YTAtN2QxZS03YWJjLTlhMTItcGF5MDAwMDAwMDAxIiwib3JkZXJJZCI6IjAxOTE0NmEwLTdkMWUtN2FiYy05YTEyLW9yZGVyMDAwMDAwMSJ9",
    "paymentMethod": "GOPAY"
  }
  ```
- **Response 200 OK**:
  ```json
  {
    "message": "Success",
    "data": true
  }
  ```

---

### G. Order Management (`/orders`)

#### 1. Create Order (`POST /orders/event/:eventId`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Body Request**:
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
      "checkoutUrl": "https://mock-pg.team-lima.com/checkout/ZXlKcGF5...",
      "providerTrxId": "ZXlKcGF5...",
      "totalAmount": 1500000
    }
  }
  ```

#### 2. Get My Orders (`GET /orders/customer`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Response 200 OK**: Array of Order objects dengan `tickets` & `payments`.

---

### H. Customer Tickets (`/tickets`)

#### 1. Get My Active Tickets (`GET /tickets/my-tickets`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Response 200 OK**: Array tiket aktif (`status == "AVAILABLE"` dan order `PAID`).

#### 2. Get Ticket Detail (`GET /tickets/:id`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Response 200 OK**: Detail tiket beserta event, category, seat, scan, & refund status.

---

### I. Refund Management (`/refunds`)

#### 1. Request Refund (`POST /refunds`)
- **Auth**: Bearer Token (Role: `CUSTOMER`)
- **Body Request**:
  ```json
  {
    "ticketId": "019146a0-0000-7abc-0000-abcdef000010",
    "reason": "Tidak bisa hadir karena halangan mendadak"
  }
  ```
- **Response 201 Created**: Object Refund dengan `status: "PENDING"`.

#### 2. Approve Refund (`PATCH /refunds/:id/approve`)
- **Auth**: Bearer Token (Role: `ADMIN`)
- **Response 200 OK**: Object Refund dengan `status: "APPROVED"`.

#### 3. Reject Refund (`PATCH /refunds/:id/reject`)
- **Auth**: Bearer Token (Role: `ADMIN`)
- **Body Request**: `{ "rejectReason": "Alasan pengajuan tidak valid" }`
- **Response 200 OK**: Object Refund dengan `status: "REJECTED"`.

---

## 5. Integrasi dengan Aplikasi Flutter

Aplikasi Flutter sudah terhubung dengan Mock Server ini melalui layer `lib/core/`.

### Konfigurasi Base URL (`ApiConstants`)

Secara otomatis menyesuaikan platform saat app dijalankan:

- **Web / Desktop / Physical Device**: `http://localhost:3000`
- **Android Emulator**: `http://10.0.2.2:3000`

### Contoh Pemanggilan di Repository / State Management Flutter:

```dart
import 'package:team_five_fe/core/network/dio_client.dart';
import 'package:team_five_fe/core/constants/api_constants.dart';

class EventRepository {
  final DioClient _client = DioClient();

  Future<List<dynamic>> fetchEvents() async {
    final response = await _client.dio.get(ApiConstants.events);
    if (response.statusCode == 200) {
      return response.data['data'];
    }
    throw Exception(response.data['message']);
  }

  Future<void> login(String email, String password) async {
    final response = await _client.dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final String token = response.data['data'];
    _client.setToken(token); // Simpan token di Header Dio
  }
}
```

---

## 6. Troubleshooting & FAQ

1. **`Error: Cannot find module 'express'`**
   - **Penyebab**: `npm install` belum dijalankan di folder `mock_server`.
   - **Solusi**: Jalankan `cd mock_server && npm install`.

2. **Gagal Konek dari Android Emulator (`Connection Refused`)**
   - Pastikan di Flutter menggunakan `http://10.0.2.2:3000` bukannya `http://localhost:3000`. `10.0.2.2` adalah IP loopback khusus Android Emulator ke localhost komputer host.

3. **Status `403 Forbidden` saat Create Event / Seat**
   - Pastikan Anda menyertakan Header `Authorization: Bearer <token>` dan user yang login memiliki `role: "ORGANIZER"`. Gunakan akun seed `organizer@example.com` / `Password123!`.
