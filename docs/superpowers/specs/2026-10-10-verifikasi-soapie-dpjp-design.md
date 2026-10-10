# Desain Teknis: Verifikasi SOAPIE/CPPT oleh DPJP pada Aplikasi Flutter & Backend-Dokter

## 1. Ringkasan Eksekutif & Tujuan
Fitur ini mengintegrasikan mekanisme verifikasi (validasi/paraf) catatan SOAPIE (CPPT) oleh Dokter Penanggung Jawab Pelayanan (DPJP) ke dalam aplikasi mobile Flutter (`simrs-dokter`) dan API server (`Backend-Dokter`), mengacu pada skema tabel database `siknu` dan implementasi desktop pada SIMRS Khanza (`mastering-khanza`).

### Tujuan Utama:
1. Memberikan kemudahan bagi DPJP untuk memverifikasi catatan SOAPIE (yang dibuat oleh perawat, bidan, atau dokter jaga) langsung dari smartphone/tablet saat visite rawat inap atau pelayanan rawat jalan.
2. Menerapkan aturan medikolegal: verifikasi dibatasi batas waktu (smart deadline 24 jam / jadwal dokter). Jika kadaluarsa atau ingin dibatalkan, hanya SuperAdmin yang memiliki wewenang.
3. Otomatis menandai status *Terverifikasi* ke tabel fisik database jika catatan SOAPIE dibuat langsung oleh DPJP yang bersangkutan.
4. Memastikan fitur verifikasi tetap dapat dieksekusi oleh DPJP meskipun kebijakan rumah sakit mengaktifkan pembatasan *read-only* pada mobile (`ALLOW_MOBILE_WRITE=false`).
5. Menjaga kompatibilitas 100% dua arah dengan aplikasi desktop `mastering-khanza`.

---

## 2. Acuan Struktur Data (Database `siknu`)

### A. Tabel Verifikasi Fisik
```sql
-- Rawat Jalan
CREATE TABLE IF NOT EXISTS `verifikasi_pemeriksaan_ralan` (
  `no_rawat` varchar(17) NOT NULL,
  `tgl_perawatan` date NOT NULL,
  `jam_rawat` time NOT NULL,
  `kd_dokter` varchar(20) NOT NULL,
  `tgl_verifikasi` date NOT NULL,
  `jam_verifikasi` time NOT NULL,
  `catatan` text DEFAULT NULL,
  PRIMARY KEY (`no_rawat`, `tgl_perawatan`, `jam_rawat`) USING BTREE,
  KEY `kd_dokter` (`kd_dokter`) USING BTREE,
  CONSTRAINT `verifikasi_pemeriksaan_ralan_ibfk_1` FOREIGN KEY (`no_rawat`, `tgl_perawatan`, `jam_rawat`)
    REFERENCES `pemeriksaan_ralan` (`no_rawat`, `tgl_perawatan`, `jam_rawat`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Rawat Inap
CREATE TABLE IF NOT EXISTS `verifikasi_pemeriksaan_ranap` (
  `no_rawat` varchar(17) NOT NULL,
  `tgl_perawatan` date NOT NULL,
  `jam_rawat` time NOT NULL,
  `kd_dokter` varchar(20) NOT NULL,
  `tgl_verifikasi` date NOT NULL,
  `jam_verifikasi` time NOT NULL,
  `catatan` text DEFAULT NULL,
  PRIMARY KEY (`no_rawat`, `tgl_perawatan`, `jam_rawat`) USING BTREE,
  KEY `kd_dokter` (`kd_dokter`) USING BTREE,
  CONSTRAINT `verifikasi_pemeriksaan_ranap_ibfk_1` FOREIGN KEY (`no_rawat`, `tgl_perawatan`, `jam_rawat`)
    REFERENCES `pemeriksaan_ranap` (`no_rawat`, `tgl_perawatan`, `jam_rawat`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
```

### B. Trigger Audit Trail
Setiap operasi INSERT, UPDATE, dan DELETE pada kedua tabel tersebut otomatis dipantau oleh trigger:
* `trg_aud_verifikasi_pemeriksaan_ralan_ins`, `trg_aud_verifikasi_pemeriksaan_ralan_upd`, `trg_aud_verifikasi_pemeriksaan_ralan_del`
* `trg_aud_verifikasi_pemeriksaan_ranap_ins`, `trg_aud_verifikasi_pemeriksaan_ranap_upd`, `trg_aud_verifikasi_pemeriksaan_ranap_del`
Trigger ini mencatat data audit ke tabel `audit_trail_klinis`.

---

## 3. Aturan Bisnis & Otorisasi

### A. Validasi DPJP
* **Rawat Jalan (Ralan):** Dokter dianggap DPJP jika kode dokternya (atau hasil mapping via `dokter_user_mapping`) cocok dengan `reg_periksa.kd_dokter`.
* **Rawat Inap (Ranap):** Dokter dianggap DPJP jika kode dokternya terdaftar di tabel `dpjp_ranap` untuk `no_rawat` terkait.
* **SuperAdmin:** Akun bertipe `admin` atau `isadmin: true` dianggap memiliki hak DPJP dan dispensasi universal.

### B. Smart Deadline (Tenggat Waktu Kadaluarsa)
Batas waktu verifikasi dihitung dari waktu perawatan (`tgl_perawatan` & `jam_rawat`):
1. Formula acuan kueri (sesuai desktop):
   ```sql
   IF(verif.tgl_verifikasi IS NOT NULL, 'SUDAH',
      IF(NOW() > COALESCE(
          (SELECT MIN(TIMESTAMP(DATE_ADD(pemeriksaan.tgl_perawatan, INTERVAL 1 DAY), j.jam_mulai))
           FROM dpjp_ranap dr
           INNER JOIN jadwal j ON j.kd_dokter = dr.kd_dokter
           WHERE dr.no_rawat = pemeriksaan.no_rawat
             AND j.hari_kerja = ELT(DAYOFWEEK(pemeriksaan.tgl_perawatan), 'AKHAD', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU')
             AND j.jam_mulai >= pemeriksaan.jam_rawat),
          DATE_ADD(TIMESTAMP(pemeriksaan.tgl_perawatan, pemeriksaan.jam_rawat), INTERVAL 24 HOUR)
      ), 'KADALUARSA', 'BELUM')) AS status_verifikasi
   ```
2. **Kondisi Hak Verifikasi (`can_verify`):**
   * Jika `status_verifikasi == 'SUDAH'` -> `can_verify: false` (terkunci).
   * Jika `status_verifikasi == 'KADALUARSA'` -> `can_verify: false` (hanya `true` jika user adalah SuperAdmin).
   * Jika `status_verifikasi == 'BELUM'` -> `can_verify: true` jika user adalah DPJP pasien tersebut dan bukan pembuat catatan itu sendiri.

### C. Verifikasi Otomatis untuk Pembuat DPJP
Ketika dokter DPJP menginput SOAPIE di Flutter (atau backend), backend otomatis melakukan INSERT verifikasi ke tabel yang bersangkutan dengan:
* `kd_dokter` = kode dokter DPJP.
* `tgl_verifikasi` = CURRENT_DATE.
* `jam_verifikasi` = CURRENT_TIME.
* `catatan` = `'-'`.

### D. Pengecualian Write Access (Write Exemption)
* Endpoint `POST /api/soap/verifikasi` dan `DELETE /api/soap/verifikasi` didaftarkan ke `exemptPaths` pada `writeAccessMiddleware` di backend.
* Di aplikasi Flutter, aksi verifikasi tidak diblokir oleh getter `authController.writeEnabled`.

---

## 4. Desain Kontrak API (`Backend-Dokter`)

### A. Pengayaan Endpoint Riwayat SOAP
1. `GET /api/riwayat/pasien/soap-ranap?no_rawat=...`
2. `GET /api/riwayat/pasien/soap-ralan?no_rawat=...`

#### Output JSON Per Item SOAP:
```json
{
  "tgl_perawatan": "2026-10-10",
  "jam_rawat": "08:30:00",
  "nip": "198501012010121001",
  "nama": "Ns. Siti Rahma, S.Kep",
  "jbtn": "Perawat Pelaksana",
  "suhu_tubuh": "36.8",
  "tensi": "120/80",
  "nadi": "82",
  "respirasi": "20",
  "keluhan": "Nyeri perut berkurang",
  "pemeriksaan": "Abdomen supel, bising usus normal",
  "penilaian": "Post op appendectomy H+1",
  "rtl": "Lanjutkan infus, rawat luka",
  "instruksi": "Mobilisasi bertahap",
  "evaluasi": "Pasien kooperatif",
  
  "is_verified": false,
  "status_verifikasi": "BELUM",
  "v_kd_dokter": null,
  "v_nm_dokter": null,
  "v_tgl": null,
  "v_jam": null,
  "v_catatan": null,
  "can_verify": true,
  "is_own_entry": false
}
```

### B. Endpoint Eksekusi Verifikasi
* **URL:** `POST /api/soap/verifikasi`
* **Headers:** `Authorization: Bearer <token>`
* **Request Body:**
  ```json
  {
    "no_rawat": "2026/10/10/000001",
    "tgl_perawatan": "2026-10-10",
    "jam_rawat": "08:30:00",
    "jenis": "ranap",
    "catatan": "Terapi lanjutkan, awasi intake cairan"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "code": 200,
    "success": true,
    "message": "Catatan SOAPIE berhasil diverifikasi oleh DPJP",
    "data": {
      "no_rawat": "2026/10/10/000001",
      "tgl_perawatan": "2026-10-10",
      "jam_rawat": "08:30:00",
      "kd_dokter": "D0001",
      "tgl_verifikasi": "2026-10-10",
      "jam_verifikasi": "10:15:22",
      "catatan": "Terapi lanjutkan, awasi intake cairan"
    }
  }
  ```
* **Error Response (403 Forbidden - Kadaluarsa):**
  ```json
  {
    "code": 403,
    "success": false,
    "message": "Batas waktu verifikasi DPJP telah berakhir (Kadaluarsa). Hanya SuperAdmin yang dapat memberikan dispensasi."
  }
  ```

### C. Endpoint Batal Verifikasi (SuperAdmin Only)
* **URL:** `DELETE /api/soap/verifikasi`
* **Headers:** `Authorization: Bearer <token>`
* **Request Body:**
  ```json
  {
    "no_rawat": "2026/10/10/000001",
    "tgl_perawatan": "2026-10-10",
    "jam_rawat": "08:30:00",
    "jenis": "ranap"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "code": 200,
    "success": true,
    "message": "Verifikasi SOAPIE berhasil dibatalkan"
  }
  ```

---

## 5. Desain UI & Komponen Aplikasi Flutter (`simrs-dokter`)

### A. Modifikasi `SoapTile` (`features/rekam_medis/views/widgets/soap_tile.dart`)
1. **Container Header & Status Badge:**
   * Jika `is_verified == true`:
     * Background border/badge bernuansa hijau lembut (`Colors.green.shade50`).
     * Badge `✔ Terverifikasi DPJP` warna teks `Colors.green.shade800`.
     * Teks keterangan: `dr. [Nama DPJP] • [Tanggal & Jam Verifikasi]`.
     * Kotak kutipan catatan DPJP (jika ada catatan non-kosong).
   * Jika `status_verifikasi == 'KADALUARSA'`:
     * Background border/badge bernuansa merah lembut (`Colors.red.shade50`).
     * Badge `Kadaluarsa (>24 Jam)` warna teks `Colors.red.shade800`.
     * Tombol verifikasi non-aktif (disabled) dengan ikon gembok kecil.
   * Jika `status_verifikasi == 'BELUM'`:
     * Badge abu-abu netral `Belum Diverifikasi`.
     * Tombol aksi hijau `[Verifikasi DPJP]` jika `can_verify == true`.

### B. Modal BottomSheet Verifikasi (`VerifikasiSoapieSheet`)
* Header: Judul *"Verifikasi Catatan SOAPIE"* dan ringkasan PPA pembuat serta waktu pencatatan.
* Teks informasi edukatif: *"Dengan memverifikasi, Anda menyatakan telah menelaah dan menyetujui catatan asuhan ini sebagai DPJP."*
* Input Field: `TextFormField` multiline opsional untuk *Catatan / Arahan Klinis DPJP*.
* Tombol Aksi:
  * `Batal` (OutlinedButton).
  * `Konfirmasi Verifikasi` (ElevatedButton hijau dengan indikator loading).

### C. Modifikasi Controller (`RekamMedisController`)
* Method `verifikasiSoapie({required String jenis, required String tglPerawatan, required String jamRawat, String? catatan})`.
* Memanggil `_api.dio.post('/soap/verifikasi', data: payload)`.
* Menampilkan snackbar sukses dan melakukan auto-refresh pada tab rekam medis SOAPIE.

---

## 6. Rencana Pengujian (Testing Strategy)
1. **Backend Tests (Vitest):**
   * Tes verifikasi oleh dokter yang merupakan DPJP (berhasil 200).
   * Tes verifikasi oleh dokter yang BUKAN DPJP (gagal 403).
   * Tes verifikasi catatan yang sudah melewati 24 jam oleh dokter biasa (gagal 403).
   * Tes verifikasi catatan kadaluarsa oleh SuperAdmin (berhasil 200 dispensasi).
   * Tes auto-verifikasi saat dokter DPJP membuat SOAPIE baru.
   * Tes verifikasi saat `ALLOW_MOBILE_WRITE=false` (harus tetap lolos karena exempt).
2. **Flutter Integration / Manual Testing:**
   * Membuka rekam medis pasien di tab SOAPIE ranap & ralan.
   * Memverifikasi kartu perawat melalui BottomSheet dan memeriksa apakah badge berubah hijau real-time.
   * Membuka aplikasi desktop `mastering-khanza` untuk memastikan baris yang diverifikasi di HP otomatis berubah hijau di desktop dan memunculkan data verifikator.
