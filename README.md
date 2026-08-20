# VELOCE - Platform Tiket Event

Platform tiket event digital yang memungkinkan organizer menjual tiket, customer membeli tiket dengan seat selection, gate operator memvalidasi tiket via QR scan, dan admin mengelola refund.

## Fitur

### Customer
- Jelajahi dan cari event
- Pilih kursi secara visual (untuk event berjadwal)
- Checkout dan pembayaran melalui mock payment gateway
- Tiket aktif dengan QR code
- Ajukan refund
- VelocePay Wallet (cek saldo, top up, riwayat transaksi)
- Kelola profil

### Event Organizer
- Buat, edit, dan hapus event
- Kelola kategori tiket (VIP, Festival, dll)
- Bulk seat generation dengan prefix kode
- Kelola gate dan assign gate operator
- Dashboard statistik event (pendapatan, tiket terjual, refund)
- Pantau refund per event

### Gate Operator
- Scan QR code tiket untuk validasi masuk
- Dashboard dengan jumlah scan (scanned vs total)
- Info gate dan event yang ditugaskan

### Admin
- Kelola semua permintaan refund
- Approve atau reject refund dengan alasan

## Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Framework | Flutter 3.x, Dart ^3.11.5 |
| State Management | Riverpod 3.x |
| Networking | Dio 5.x, SSE (Server-Sent Events) |
| QR Code | mobile_scanner, qr_flutter |
| Auth | JWT Bearer Token, flutter_secure_storage |
| Firebase | Firebase App Distribution (CI/CD) |
| Mock Server | Node.js, Express.js 4.x |
| Testing | flutter_test (unit & widget) |
| CI/CD | GitHub Actions |

## Struktur Project

```
team_lima_FE/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── core/
│   │   ├── constants/               # API endpoints
│   │   ├── network/                 # Dio client, SSE client
│   │   ├── theme/                   # Warna, teks, styling
│   │   └── widgets/                 # Widget reusable
│   └── features/
│       ├── auth/                    # Login, register, profil
│       ├── event/                   # Manajemen event (organizer)
│       ├── ticket_category/         # Kategori tiket & seat preview
│       ├── seat/                    # Manajemen kursi
│       ├── customer/                # Explore, checkout, tiket, refund
│       ├── gate/                    # Gate management & scanner
│       ├── order/                   # Manajemen pesanan
│       └── admin/                   # Kelola refund
├── mock_server/                     # Node.js mock API
│   ├── server.js                    # Entry point
│   ├── routes/                      # 11 file route
│   └── data/                        # Seed data
├── test/
│   ├── unit/models/                 # 9 unit test model
│   ├── unit/providers/              # 5 unit test provider
│   └── widgets/                     # 8 widget test
└── .github/workflows/               # CI/CD pipelines
```

## Memulai

### Prasyarat
- Flutter SDK (stable channel)
- Dart SDK ^3.11.5
- Node.js v16+ dan npm
- Java 17 (untuk Android build)

### Instalasi

```bash
# Clone repository
git clone https://github.com/username/team_lima_FE.git
cd team_lima_FE

# Install dependencies Flutter
flutter pub get

# (Opsional) Code generation untuk Riverpod
dart run build_runner build

# Install dependencies Mock Server
cd mock_server
npm install
cd ..
```

### Menjalankan Mock Server

```bash
cd mock_server
npm start
# Server berjalan di http://localhost:3000
```

### Menjalankan Aplikasi

```bash
# Android Emulator
flutter run

# Physical Device (ubah IP di api_constants.dart)
flutter run
```

## Pengujian

```bash
# Jalankan semua test
flutter test

# Unit test saja
flutter test test/unit/

# Widget test saja
flutter test test/widgets/

# Dengan coverage report
flutter test --coverage
```

## CI/CD

### Quality Checks (Pull Request)
- `dart format --set-exit-if-changed`
- `flutter analyze`
- `flutter test`

### Build & Deploy (Push to master/develop)
- Build APK dan AAB (release)
- Distribute ke Firebase App Distribution (untuk tag `v*.*.*`)
- Create GitHub Release dengan artifact APK + AAB


## Konfigurasi API Base URL

Dikonfigurasi otomatis berdasarkan platform di `lib/core/constants/api_constants.dart`:

| Platform | URL |
|----------|-----|
| Web / Desktop | `http://localhost:3000` |
| Android Emulator | `http://10.0.2.2:3000` |
| Android Physical Device | `http://<IP_DEVICE>:3000` |

## Akun Dummy (Mock Server)

| Role | Email | Password |
|------|-------|----------|
| Customer | `customer@example.com` | `password123` |
| Event Organizer | `organizer@example.com` | `password123` |
| Gate Operator | `gateoperator@example.com` | `password123` |
| Admin | `admin@example.com` | `password123` |

## Arsitektur

Menggunakan **Clean Architecture** dengan pattern:

```
feature/
├── data/
│   ├── models/          # Data models (JSON serialization)
│   └── repositories/    # API communication (Dio)
├── presentation/
│   ├── pages/           # UI screens
│   ├── providers/       # Riverpod state management
│   └── widgets/         # Reusable UI components
```

## License

Proprietary - COMPFEST 2026 Academy
