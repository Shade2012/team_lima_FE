# 🧪 Panduan & Dokumentasi Testing - Tim Lima FE

Dokumen ini berisi panduan lengkap mengenai strategi pengujian (**Unit Testing**, **Widget Testing**, dan **Integration Testing**) pada aplikasi Flutter **Tim Lima FE**, mencakup skenario *Happy Path* dan *Unhappy Path*, serta strategi optimasi CI/CD pada GitHub Actions.

---

## 📋 Daftar Isi
1. [Strategi Testing & Optimasi CI/CD](#1-strategi-testing--optimasi-cicd)
2. [Matriks Skenario Testing (Happy Path vs Unhappy Path)](#2-matriks-skenario-testing-happy-path-vs-unhappy-path)
3. [Struktur File Pengujian](#3-struktur-file-pengujian)
4. [Cara Menjalankan Test](#4-cara-menjalankan-test)
5. [Detail Skenario Integration Testing](#5-detail-skenario-integration-testing)

---

## 1. Strategi Testing & Optimasi CI/CD

### ⚡ Mengapa Unit & Widget Test Berjalan Super Cepat?
Seluruh **Unit Test** dan **Widget Test** di dalam proyek ini memanfaatkan **Dart Layer Mocking** (Headless Dart VM) tanpa tergantung pada koneksi network eksternal.
- **Kecepatan**: Running 13+ test suite hanya membutuhkan waktu **~10-15 detik**.
- **Terisolasi & Deterministik**: Bebas dari risiko *flaky test* akibat port network terblokir atau delay server.

### 🤖 Pengaturan CI/CD (GitHub Actions `quality-checks.yml`)
1. **Tidak Perlu Menyalakan Node.js Server di CI**:
   - Untuk tahap Pull Request (`quality-checks.yml`), `flutter test` berjalan terisolasi di memori VM.
   - Hal ini menghindarkan pemborosan runtime `npm install` (~30-60 detik) pada setiap PR, sehingga CI pipeline tetap cepat & hemat kuota GitHub Runner minutes.

---

## 2. Matriks Skenario Testing (Happy Path vs Unhappy Path)

| Tipe Tes | Target Module | Skenario *Happy Path* | Skenario *Unhappy Path* |
| :--- | :--- | :--- | :--- |
| **Unit Test** | `UserModel` | Parser JSON lengkap dari backend DTO menghasilkan objek `UserModel` yang valid. | Mengolah Map JSON kosong/null tanpa terjadi *crash* (menghasilkan default fallback value). |
| **Unit Test** | `LoginRequest` & `RegisterRequest` | Serialisasi `.toJson()` menghasilkan payload yang sesuai dengan DTO backend (`CUSTOMER`, `ORGANIZER`, `GATE_OPERATOR`). | `eventId` otomatis diabaikan dari Map JSON jika nilainya null/kosong. |
| **Unit Test** | `AuthNotifier` (Riverpod) | Update state `setEmail`, `setPassword`, `setRole`, dan `togglePasswordVisibility` merubah state secara konsisten. | Form submit dengan email/password kosong memicu error *"Email and password are required"*. Password mismatch memicu error *"Passwords do not match"*. |
| **Widget Test** | `LoginPage` | Merender logo `VELOCE`, email field, password field, tombol `Sign In`, dan link `Sign Up`. | Menekan tombol `Sign In` saat field kosong menampilkan SnackBar error validasi. |
| **Widget Test** | `SignupPage` | Merender Form Sign Up, Toggle Role Picker (Customer vs Event Organizer) dapat dipindah dengan lancar. | Menekan tombol `Create Account` saat field kosong menampilkan SnackBar error validasi. |

---

## 3. Struktur File Pengujian

Semua file pengujian tersusun di folder `test/`:

```text
team_five_fe/
├── test/
│   ├── unit/                           <-- Logika Bisnis & Model
│   │   ├── models/
│   │   │   ├── user_model_test.dart
│   │   │   └── auth_request_test.dart
│   │   └── providers/
│   │       └── auth_provider_test.dart
│   └── widgets/                        <-- Komponen UI & Interaksi Form
│       ├── login_page_test.dart
│       └── signup_page_test.dart
└── docs/
    └── testing_guide.md                <-- Dokumentasi Testing Ini
```

---

## 4. Cara Menjalankan Test

### A. Jalankan Seluruh Test Suite
Jalankan perintah berikut di terminal akar proyek:
```bash
flutter test
```

### B. Jalankan File Tes Tertentu
- **Menjalankan Unit Test saja**:
  ```bash
  flutter test test/unit/
  ```
- **Menjalankan Widget Test saja**:
  ```bash
  flutter test test/widgets/
  ```

### C. Menjalankan Test dengan Coverage Report
```bash
flutter test --coverage
```

---

## 5. Detail Skenario Integration Testing

Skenario pengujian integrasi *End-to-End* (E2E) dirancang untuk memverifikasi alur lengkap pengguna:

### Skenario E2E 1: Alur Pendaftaran & Login Pengguna Baru (Happy Path)
1. **User Sign Up**:
   - Pengguna membuka `SignupPage`.
   - Mengisi `username`, `email`, `password`, dan `confirmPassword`.
   - Memilih role `CUSTOMER` atau `ORGANIZER`.
   - Menekan tombol `Create Account` -> Menerima respon HTTP 201 Created dari backend.
2. **User Login**:
   - Navigasi ke `LoginPage`.
   - Mengisi email dan password terdaftar.
   - Menekan tombol `Sign In` -> Respon HTTP 200 OK mengembalikan `jwt_access_token`.
3. **Persistensi Token & Auto-Login**:
   - Token disimpan di `FlutterSecureStorage`.
   - Aplikasi mengambil profil via `GET /users/profile`.
   - Saat aplikasi ditutup dan dibuka kembali, `checkAuthStatus()` mengenali token tersimpan dan langsung membawa pengguna ke Dashboard tanpa perlu login ulang.

### Skenario E2E 2: Penanganan Error & Sesi Kadaluwarsa (Unhappy Path)
1. **Gagal Login**:
   - Input password salah -> Backend mengembalikan HTTP 401 Unauthorized (`{ "status_code": 401, "message": "Invalid email or password" }`).
   - Aplikasi menampilkan SnackBar error berwarna merah.
2. **Token Blacklist pada Logout**:
   - Pengguna menekan tombol `Logout`.
   - `POST /users/logout` dipanggil dengan Bearer Token.
   - Token dimasukkan ke *blacklist* Redis oleh backend dan dihapus dari `FlutterSecureStorage` lokal.
