# 📱 CareDoc EMR — Aplikasi Mobile Dokter SIMRS

Aplikasi mobile berbasis **Flutter** untuk dokter di **RS Islam Aminah Blitar**, digunakan untuk memonitor pasien rawat inap (RANAP), rawat jalan (RALAN), dan IGD secara real-time langsung dari smartphone.

---

## ✨ Fitur Utama

| Fitur | Keterangan |
|---|---|
| 🔐 **Login & Auto Re-login** | Autentikasi JWT dengan silent token refresh otomatis |
| 📊 **Dashboard** | Rekapitulasi pasien RANAP / RALAN / IGD milik dokter yang login |
| 🏥 **List Pasien** | Filter pasien berdasarkan DPJP dokter yang sedang login |
| 📋 **Rekam Medis Digital** | SOAP, anamnesis, diagnosa, obat, lab, radiologi, vital sign |
| 🩺 **SBAR Ranap** | Lihat & validasi catatan SBAR pasien rawat inap |
| 👨‍⚕️ **DPJP Ranap** | Set diri sebagai DPJP utama pasien rawat inap |
| 💊 **Pemberian Obat** | Riwayat obat yang diberikan selama perawatan |
| 🧪 **Laboratorium** | Hasil pemeriksaan lab beserta nilai rujukan |
| 🔬 **Radiologi** | Hasil & gambar foto radiologi pasien |
| 🗓️ **Jadwal Operasi** | Daftar jadwal operasi hari ini |
| 🛏️ **Ketersediaan Bed** | Rekapitulasi bed per kelas & status hunian |
| 💰 **Billing & Perkiraan Biaya** | Total tagihan + estimasi biaya BPJS (INA-CBGs) |

---

## 🏗️ Arsitektur

```
lib/
├── core/
│   ├── config/         # AppConfig (BASE_URL, timeout)
│   ├── network/        # ApiClient (Dio + JWT interceptor + auto re-login)
│   ├── theme/          # Tema warna & tipografi
│   └── utils/          # Helper functions
├── features/
│   ├── auth/           # Login, logout, check token
│   ├── dashboard/      # Daftar pasien, jadwal operasi, ketersediaan bed
│   ├── pasien/         # Detail info pasien
│   └── rekam_medis/    # Rekam medis lengkap (SOAP, lab, radiologi, SBAR, dll)
├── widgets/            # Widget reusable global
└── main.dart           # Entry point, routing GetX
```

**State Management:** GetX  
**HTTP Client:** Dio (dengan auto token refresh saat 401)  
**Storage:** FlutterSecureStorage (token, user data, setting cache)

---

## 🔧 Requirements

- **Flutter** SDK `^3.5.4`
- **Dart** SDK `^3.5.4`
- **Android** min SDK 21 (Android 5.0+)
- **iOS** 12+ *(opsional)*
- Backend: [BackEnd-Dokter](../BackEnd-Dokter) berjalan di port `4002`

---

## 🚀 Quick Start

### 1. Clone & Install Dependencies

```bash
git clone <repo-url>
cd simrs_dokter
flutter pub get
```

### 2. Konfigurasi `.env`

```bash
cp .env.example .env   # jika tersedia, atau edit langsung
```

Edit file `.env`:

```env
# Emulator Android (10.0.2.2 = localhost host mesin)
BASE_URL=http://10.0.2.2:4002/api

# Device fisik / production
# BASE_URL=http://192.168.x.x:4002/api

CONNECT_TIMEOUT=30000
RECEIVE_TIMEOUT=30000
```

### 3. Jalankan Aplikasi

```bash
# Debug mode
flutter run

# Build APK
flutter build apk --release

# Build APK split per ABI (lebih kecil)
flutter build apk --split-per-abi --release
```

---

## ⚙️ Konfigurasi Lengkap `.env`

| Variable | Default | Keterangan |
|---|---|---|
| `BASE_URL` | `http://10.0.2.2:4002/api` | Base URL API backend dokter |
| `CONNECT_TIMEOUT` | `30000` | Timeout koneksi (ms) |
| `RECEIVE_TIMEOUT` | `30000` | Timeout menerima response (ms) |

---

## 🔌 API Endpoints yang Digunakan

### Auth & Setting
| Method | Endpoint | Keterangan |
|---|---|---|
| `POST` | `/auth/login` | Login dokter |
| `GET` | `/setting` | Konfigurasi rumah sakit |

### Dashboard
| Method | Endpoint | Keterangan |
|---|---|---|
| `GET` | `/list-pasien-ranap` | Daftar pasien rawat inap |
| `GET` | `/list-pasien-ralan` | Daftar pasien rawat jalan hari ini |
| `GET` | `/list-pasien-igd` | Daftar pasien IGD hari ini |
| `GET` | `/jadwal/operasi` | Jadwal operasi hari ini |
| `GET` | `/jadwal/bed` | Ketersediaan bed per kelas |

### Rekam Medis
| Method | Endpoint | Keterangan |
|---|---|---|
| `GET` | `/riwayat/pasien/medis-ranap` | Riwayat medis RANAP |
| `GET` | `/riwayat/pasien/medis-ranap-neonatus` | Riwayat medis neonatus |
| `GET` | `/riwayat/pasien/medis-ranap-kebidanan` | Riwayat medis kebidanan |
| `GET` | `/riwayat/pasien/medis-igd` | Riwayat medis IGD |
| `GET` | `/riwayat/pasien/soap-ralan` | SOAP rawat jalan |
| `GET` | `/riwayat/pasien/soap-ranap` | SOAP rawat inap |
| `GET` | `/riwayat/pasien/diagnosa` | Diagnosa ICD-10 |
| `GET` | `/riwayat/pasien/pemberian-obat` | Riwayat pemberian obat |
| `GET` | `/riwayat/pasien/laboratorium` | Hasil laboratorium |
| `GET` | `/riwayat/pasien/radiologi` | Hasil + gambar radiologi |
| `GET` | `/riwayat/pasien/total-tagihan` | Total tagihan billing |
| `GET` | `/perkiraan-biaya` | Estimasi biaya BPJS (INA-CBGs) |

### SBAR & DPJP
| Method | Endpoint | Keterangan |
|---|---|---|
| `GET` | `/pemeriksaan` | List SBAR pasien ranap |
| `POST` | `/pemeriksaan/validasi` | Validasi catatan SBAR |
| `GET` | `/dpjp-ranap` | List DPJP pasien ranap |
| `POST` | `/dpjp-ranap` | Set dokter sebagai DPJP |

---

## 🔐 Mekanisme Auth

1. **Login** → token JWT disimpan di `FlutterSecureStorage`
2. Setiap request otomatis menyertakan `Authorization: Bearer <token>`
3. Jika server mengembalikan **401** → app melakukan **silent re-login** dengan username/password tersimpan
4. Jika silent re-login gagal → semua data dihapus dan redirect ke halaman login

---

## 📦 Dependencies Utama

| Package | Versi | Kegunaan |
|---|---|---|
| `get` | ^4.6.6 | State management & routing |
| `dio` | ^5.7.0 | HTTP client |
| `flutter_secure_storage` | ^9.2.2 | Simpan token & kredensial |
| `flutter_dotenv` | ^5.2.1 | Load konfigurasi `.env` |
| `cached_network_image` | ^3.4.1 | Cache gambar radiologi |
| `fl_chart` | ^0.69.0 | Grafik dashboard |
| `google_fonts` | ^6.2.1 | Tipografi |
| `shimmer` | ^3.0.0 | Loading skeleton |
| `webview_flutter` | ^4.10.0 | DICOM viewer (OHIF) |
| `intl` | ^0.19.0 | Format tanggal & angka |
| `connectivity_plus` | ^6.1.0 | Deteksi koneksi jaringan |

---

## 🗂️ Backend Terkait

Aplikasi ini membutuhkan **BackEnd-Dokter** — backend Express/Hono yang dipersempit khusus untuk endpoint yang dipakai aplikasi ini.

```bash
# Jalankan backend dokter
cd ../BackEnd-Dokter
npm run dev
# atau
pm2 start ecosystem.config.js --env production
```

Lihat dokumentasi lengkap di [`../BackEnd-Dokter/README.md`](https://github.com/Putra-S/Backend-Dokter.git).

---

## 🛠️ Build & Deployment

### APK Release

```bash
# Generate launcher icon
flutter pub run flutter_launcher_icons

# Build APK
flutter build apk --release --split-per-abi

# Output
build/app/outputs/flutter-apk/
  app-arm64-v8a-release.apk   ← Install di device modern (64-bit)
  app-armeabi-v7a-release.apk ← Install di device lama (32-bit)
```

### Update Versi

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2   # format: versiNama+versiKode
```

---

## ☕ Dukung Pengembang

Jika aplikasi ini membantu Anda atau rumah sakit Anda, Anda bisa memberikan dukungan melalui:

[![Dukung via Saweria](https://img.shields.io/badge/Saweria-Dukung%20Saya-orange?style=for-the-badge&logo=heart)](https://saweria.co/marufp1605)

---

## 🤝 Kustomisasi & Kerja Sama Profesional

Jika membutuhkan kustomisasi tersendiri atau kerja sama profesional, silakan hubungi:
- **Telepon/WhatsApp:** [085232406085](https://wa.me/6285232406085)
- **Telegram:** [@m_putra_s](https://t.me/m_putra_s)

---

## 📄 Lisensi

Proyek ini dikembangkan untuk internal **RS Islam Aminah Blitar**.  
Hak cipta © 2024–2026 Tim IT SIMRS RSI Aminah.
