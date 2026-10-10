# Verifikasi SOAPIE oleh DPJP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mengimplementasikan fitur verifikasi catatan SOAPIE/CPPT oleh DPJP pada aplikasi mobile Flutter (`simrs-dokter`) dan API server (`Backend-Dokter`) dengan validasi hak DPJP, batasan waktu kadaluarsa 1x24 jam, auto-verifikasi untuk pembuat DPJP, dan pengecualian write-access.

**Architecture:** Penambahan service verifikasi di Backend-Dokter yang mengecek DPJP (didukung `dokter_user_mapping`) dan batas waktu 24 jam/jadwal dokter; ekspansi endpoint riwayat SOAP dengan status verifikasi; endpoint eksekusi verifikasi yang dikecualikan dari `ALLOW_MOBILE_WRITE`; serta pembaruan tampilan 3-tier styling pada `SoapTile` Flutter beserta bottom sheet konfirmasi arahan DPJP.

**Tech Stack:** Node.js / Bun, Hono, Knex / MySQL2 (Database `siknu`), Flutter 3 / Dart, GetX, Dio.

**Spec:** `docs/superpowers/specs/2026-10-10-verifikasi-soapie-dpjp-design.md`

## Global Constraints
- Target database: MySQL `siknu` dengan tabel `verifikasi_pemeriksaan_ranap` dan `verifikasi_pemeriksaan_ralan`.
- Trigger `audit_trail_klinis` di database `siknu` harus otomatis terpanggil saat terjadi INSERT/DELETE verifikasi.
- Endpoint verifikasi `POST /api/soap/verifikasi` dan `DELETE /api/soap/verifikasi` harus dikecualikan dari pembatasan `ALLOW_MOBILE_WRITE=false` (`writeAccessMiddleware.exemptPaths`).
- Aturan verifikasi:
  1. Hanya DPJP pasien atau SuperAdmin yang berwenang memverifikasi.
  2. Catatan yang kadaluarsa (>24 jam/jadwal dokter) hanya dapat diverifikasi oleh SuperAdmin.
  3. Catatan yang sudah terverifikasi hanya dapat dibatalkan oleh SuperAdmin.
  4. Catatan SOAP yang dibuat langsung oleh dokter DPJP otomatis berstatus terverifikasi.

## Review Focus
1. Perbedaan format identitas dokter (NIK vs kode Dxxxx) — harus di-resolve menggunakan `doctorIdentity.js` (`dokter_user_mapping`).
2. Pasien ranap dengan multiple DPJP (`dpjp_ranap`) — semua DPJP yang terdaftar untuk pasien tersebut harus sah memverifikasi.
3. Zona waktu server (`+07:00` / Asia/Jakarta) pada perbandingan deadline dan pencatatan tanggal-jam verifikasi.
4. Nilai `ALLOW_MOBILE_WRITE=false` di `.env` tidak boleh memblokir `POST /api/soap/verifikasi`.
5. Null-safety dan backward-compatibility respons JSON riwayat SOAPIE di aplikasi Flutter.

---

### Task 1: Layanan Logika Verifikasi SOAPIE di Backend-Dokter (`soapVerificationService.js`)

**Files:**
- Create: `/home/malifnasrulloh/Downloads/Backend-Dokter/services/soapVerificationService.js`
- Test: `/home/malifnasrulloh/Downloads/Backend-Dokter/tests/units/soapVerificationService.test.js`

**Interfaces:**
- Consumes: `config/db.js`, `utils/doctorIdentity.js` (`resolveDoctorKdSet`)
- Produces: 
  - `isDoctorDPJP(noRawat, username, jenis)` -> `Promise<boolean>`
  - `checkVerificationDeadline(noRawat, tglPerawatan, jamRawat, jenis)` -> `Promise<{ isExpired: boolean, deadline: Date }>`
  - `verifySoap({ noRawat, tglPerawatan, jamRawat, jenis, kdDokter, catatan, isSuperAdmin })` -> `Promise<object>`
  - `unverifySoap({ noRawat, tglPerawatan, jamRawat, jenis, isSuperAdmin })` -> `Promise<object>`

- [ ] **Step 1: Tulis unit test untuk `soapVerificationService`**

Buat file `/home/malifnasrulloh/Downloads/Backend-Dokter/tests/units/soapVerificationService.test.js`:
```javascript
import { describe, it, expect, vi, beforeEach } from 'vitest';
const soapVerificationService = require('../../services/soapVerificationService');
const db = require('../../config/db');

describe('soapVerificationService', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('isDoctorDPJP mengembalikan true jika username adalah SuperAdmin', async () => {
    const isDPJP = await soapVerificationService.isDoctorDPJP('2026/10/10/000001', 'admin', 'ranap', true);
    expect(isDPJP).toBe(true);
  });

  it('checkVerificationDeadline mendeteksi kadaluarsa jika melewati 24 jam', async () => {
    // Tanggal perawatan 2 hari yang lalu
    const tglLalu = '2026-10-08';
    const jamLalu = '08:00:00';
    const res = await soapVerificationService.checkVerificationDeadline('2026/10/08/000001', tglLalu, jamLalu, 'ranap');
    expect(res.isExpired).toBe(true);
  });
});
```

- [ ] **Step 2: Jalankan test dan pastikan gagal**

Jalankan:
```bash
cd /home/malifnasrulloh/Downloads/Backend-Dokter && npx vitest run tests/units/soapVerificationService.test.js
```
Expected: FAIL dengan "Cannot find module '../../services/soapVerificationService'"

- [ ] **Step 3: Implementasikan `soapVerificationService.js`**

Buat file `/home/malifnasrulloh/Downloads/Backend-Dokter/services/soapVerificationService.js`:
```javascript
const db = require('../config/db');
const { resolveDoctorKdSet } = require('../utils/doctorIdentity');

/**
 * Memeriksa apakah user login berstatus DPJP untuk pasien (Ralan / Ranap)
 */
async function isDoctorDPJP(noRawat, username, jenis = 'ranap', isSuperAdmin = false) {
  if (isSuperAdmin) return true;
  if (!username) return false;

  const doctorCodes = await resolveDoctorKdSet(username);
  if (doctorCodes.length === 0) return false;

  const placeholders = doctorCodes.map(() => '?').join(', ');

  if (jenis === 'ranap') {
    const [rows] = await db.query(
      `SELECT COUNT(*) AS total FROM dpjp_ranap WHERE no_rawat = ? AND kd_dokter IN (${placeholders})`,
      [noRawat, ...doctorCodes]
    );
    return rows[0].total > 0;
  } else {
    const [rows] = await db.query(
      `SELECT COUNT(*) AS total FROM reg_periksa WHERE no_rawat = ? AND kd_dokter IN (${placeholders})`,
      [noRawat, ...doctorCodes]
    );
    return rows[0].total > 0;
  }
}

/**
 * Menghitung batas waktu verifikasi (smart deadline: 24 jam atau jadwal dokter berikutnya)
 */
async function checkVerificationDeadline(noRawat, tglPerawatan, jamRawat, jenis = 'ranap') {
  const tglJamStr = `${tglPerawatan} ${jamRawat}`;
  const now = new Date();

  // Query deadline konsisten dengan SIMRS Khanza desktop
  const tablePemeriksaan = jenis === 'ranap' ? 'pemeriksaan_ranap' : 'pemeriksaan_ralan';
  const query = `
    SELECT
      IF(NOW() > COALESCE(
          (SELECT MIN(TIMESTAMP(DATE_ADD(?, INTERVAL 1 DAY), j.jam_mulai))
           FROM ${jenis === 'ranap' ? 'dpjp_ranap dr' : 'reg_periksa dr'}
           INNER JOIN jadwal j ON j.kd_dokter = dr.kd_dokter
           WHERE dr.no_rawat = ?
             AND j.hari_kerja = ELT(DAYOFWEEK(?), 'AKHAD', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU')
             AND j.jam_mulai >= ?),
          DATE_ADD(TIMESTAMP(?, ?), INTERVAL 24 HOUR)
      ), 1, 0) AS is_expired,
      COALESCE(
          (SELECT MIN(TIMESTAMP(DATE_ADD(?, INTERVAL 1 DAY), j.jam_mulai))
           FROM ${jenis === 'ranap' ? 'dpjp_ranap dr' : 'reg_periksa dr'}
           INNER JOIN jadwal j ON j.kd_dokter = dr.kd_dokter
           WHERE dr.no_rawat = ?
             AND j.hari_kerja = ELT(DAYOFWEEK(?), 'AKHAD', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU')
             AND j.jam_mulai >= ?),
          DATE_ADD(TIMESTAMP(?, ?), INTERVAL 24 HOUR)
      ) AS deadline_waktu
  `;

  try {
    const [rows] = await db.query(query, [
      tglPerawatan, noRawat, tglPerawatan, jamRawat, tglPerawatan, jamRawat,
      tglPerawatan, noRawat, tglPerawatan, jamRawat, tglPerawatan, jamRawat
    ]);

    if (rows.length > 0) {
      return {
        isExpired: rows[0].is_expired === 1,
        deadline: rows[0].deadline_waktu
      };
    }
  } catch (_e) {
    // Fallback 24 jam manual jika kalkulasi jadwal error
  }

  const dtPerawatan = new Date(tglJamStr);
  const deadlineFallback = new Date(dtPerawatan.getTime() + 24 * 60 * 60 * 1000);
  return {
    isExpired: now > deadlineFallback,
    deadline: deadlineFallback
  };
}

/**
 * Menyimpan verifikasi ke database
 */
async function verifySoap({ noRawat, tglPerawatan, jamRawat, jenis = 'ranap', kdDokter, catatan = '-', isSuperAdmin = false }) {
  const tableVerif = jenis === 'ranap' ? 'verifikasi_pemeriksaan_ranap' : 'verifikasi_pemeriksaan_ralan';

  // 1. Cek apakah sudah terverifikasi sebelumnya
  const [existing] = await db.query(
    `SELECT * FROM ${tableVerif} WHERE no_rawat = ? AND tgl_perawatan = ? AND jam_rawat = ?`,
    [noRawat, tglPerawatan, jamRawat]
  );
  if (existing.length > 0) {
    throw new Error('ALREADY_VERIFIED');
  }

  // 2. Cek apakah kadaluarsa jika bukan SuperAdmin
  if (!isSuperAdmin) {
    const { isExpired } = await checkVerificationDeadline(noRawat, tglPerawatan, jamRawat, jenis);
    if (isExpired) {
      throw new Error('VERIFICATION_EXPIRED');
    }
  }

  // 3. Simpan ke database
  const tglVerif = new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Jakarta' });
  const jamVerif = new Date().toLocaleTimeString('it-IT', { timeZone: 'Asia/Jakarta' });

  await db.query(
    `INSERT INTO ${tableVerif} (no_rawat, tgl_perawatan, jam_rawat, kd_dokter, tgl_verifikasi, jam_verifikasi, catatan)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [noRawat, tglPerawatan, jamRawat, kdDokter, tglVerif, jamVerif, catatan || '-']
  );

  return {
    no_rawat: noRawat,
    tgl_perawatan: tglPerawatan,
    jam_rawat: jamRawat,
    kd_dokter: kdDokter,
    tgl_verifikasi: tglVerif,
    jam_verifikasi: jamVerif,
    catatan: catatan || '-'
  };
}

/**
 * Membatalkan verifikasi (hanya SuperAdmin)
 */
async function unverifySoap({ noRawat, tglPerawatan, jamRawat, jenis = 'ranap', isSuperAdmin = false }) {
  if (!isSuperAdmin) {
    throw new Error('ONLY_SUPERADMIN_ALLOWED');
  }
  const tableVerif = jenis === 'ranap' ? 'verifikasi_pemeriksaan_ranap' : 'verifikasi_pemeriksaan_ralan';
  const [res] = await db.query(
    `DELETE FROM ${tableVerif} WHERE no_rawat = ? AND tgl_perawatan = ? AND jam_rawat = ?`,
    [noRawat, tglPerawatan, jamRawat]
  );
  if (res.affectedRows === 0) {
    throw new Error('NOT_FOUND');
  }
  return true;
}

module.exports = {
  isDoctorDPJP,
  checkVerificationDeadline,
  verifySoap,
  unverifySoap
};
```

- [ ] **Step 4: Jalankan test dan pastikan lulus**

Jalankan:
```bash
cd /home/malifnasrulloh/Downloads/Backend-Dokter && npx vitest run tests/units/soapVerificationService.test.js
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd /home/malifnasrulloh/Downloads/Backend-Dokter
git add services/soapVerificationService.js tests/units/soapVerificationService.test.js
git commit -m "feat(soap): add soap verification service with dpjp and deadline rules"
```

---

### Task 2: Perluasan Endpoint Riwayat SOAP Ralan & Ranap di Backend-Dokter

**Files:**
- Modify: `/home/malifnasrulloh/Downloads/Backend-Dokter/controllers/rekammedis/riwayat/riwayatSoapRanapController.js`
- Modify: `/home/malifnasrulloh/Downloads/Backend-Dokter/controllers/rekammedis/riwayat/riwayatSoapRalanController.js`
- Test: `/home/malifnasrulloh/Downloads/Backend-Dokter/tests/e2e/riwayat-pasien.e2e.test.js`

**Interfaces:**
- Consumes: `verifikasi_pemeriksaan_ranap`, `verifikasi_pemeriksaan_ralan`, `dokterIdentity`
- Produces: Respons data riwayat SOAP dengan field `is_verified`, `status_verifikasi`, `v_kd_dokter`, `v_nm_dokter`, `v_tgl`, `v_jam`, `v_catatan`, `can_verify`, `is_own_entry`.

- [ ] **Step 1: Perbarui kueri SQL di `riwayatSoapRanapController.js`**

Tambahkan `LEFT JOIN verifikasi_pemeriksaan_ranap` dan hitung status verifikasi:
```javascript
const db = require('../../../config/db');
const validateParams = require('../../../middleware/validateParams');
const response = require('../../../middleware/responseHandler');
const { resolveDoctorKdSet } = require('../../../utils/doctorIdentity');

exports.getRiwayatSoapRanap = async (req, res) => {
  const { no_rawat } = req.query;

  const queryParams = { no_rawat };
  const validateErrors = validateParams(req, res, queryParams);
  if (validateErrors) return;

  const user = req.user || {};
  const username = user.username || '';
  const isSuperAdmin = user.isadmin === true || username.toLowerCase() === 'admin';
  const doctorCodes = await resolveDoctorKdSet(username);

  const query = `SELECT
          pemeriksaan_ranap.suhu_tubuh,
          pemeriksaan_ranap.tensi,
          pemeriksaan_ranap.nadi,
          pemeriksaan_ranap.respirasi,
          pemeriksaan_ranap.tinggi,
          pemeriksaan_ranap.berat,
          pemeriksaan_ranap.spo2,
          pemeriksaan_ranap.gcs,
          pemeriksaan_ranap.kesadaran,
          pemeriksaan_ranap.keluhan,
          pemeriksaan_ranap.penilaian,
          pemeriksaan_ranap.rtl,
          pemeriksaan_ranap.pemeriksaan,
          pemeriksaan_ranap.alergi,
          pemeriksaan_ranap.tgl_perawatan,
          pemeriksaan_ranap.jam_rawat,
          pemeriksaan_ranap.nip,
          pegawai.nama,
          pegawai.jbtn,
          pemeriksaan_ranap.instruksi,
          pemeriksaan_ranap.evaluasi,
          verif.kd_dokter AS v_kd_dokter,
          COALESCE(dok_v.nm_dokter, peg_v.nama, verif.kd_dokter) AS v_nm_dokter,
          IFNULL(verif.tgl_verifikasi, '') AS v_tgl,
          IFNULL(verif.jam_verifikasi, '') AS v_jam,
          IFNULL(verif.catatan, '') AS v_catatan,
          IF(verif.tgl_verifikasi IS NOT NULL, 'SUDAH',
             IF(NOW() > COALESCE(
                 (SELECT MIN(TIMESTAMP(DATE_ADD(pemeriksaan_ranap.tgl_perawatan, INTERVAL 1 DAY), j.jam_mulai))
                  FROM dpjp_ranap dr
                  INNER JOIN jadwal j ON j.kd_dokter = dr.kd_dokter
                  WHERE dr.no_rawat = pemeriksaan_ranap.no_rawat
                    AND j.hari_kerja = ELT(DAYOFWEEK(pemeriksaan_ranap.tgl_perawatan), 'AKHAD', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU')
                    AND j.jam_mulai >= pemeriksaan_ranap.jam_rawat),
                 DATE_ADD(TIMESTAMP(pemeriksaan_ranap.tgl_perawatan, pemeriksaan_ranap.jam_rawat), INTERVAL 24 HOUR)
             ), 'KADALUARSA', 'BELUM')) AS status_verifikasi,
          (SELECT COUNT(*) FROM dpjp_ranap WHERE dpjp_ranap.no_rawat = pemeriksaan_ranap.no_rawat AND dpjp_ranap.kd_dokter IN (?)) AS is_patient_dpjp
      FROM
          pemeriksaan_ranap
          INNER JOIN pegawai ON pemeriksaan_ranap.nip = pegawai.nik
          INNER JOIN reg_periksa ON pemeriksaan_ranap.no_rawat = reg_periksa.no_rawat
          LEFT JOIN verifikasi_pemeriksaan_ranap verif ON verif.no_rawat = pemeriksaan_ranap.no_rawat
            AND verif.tgl_perawatan = pemeriksaan_ranap.tgl_perawatan
            AND verif.jam_rawat = pemeriksaan_ranap.jam_rawat
          LEFT JOIN dokter dok_v ON dok_v.kd_dokter = verif.kd_dokter
          LEFT JOIN pegawai peg_v ON peg_v.nik = verif.kd_dokter
      WHERE
          reg_periksa.no_rkm_medis = (SELECT no_rkm_medis FROM reg_periksa WHERE no_rawat = ?)
      ORDER BY
          pemeriksaan_ranap.tgl_perawatan,
          pemeriksaan_ranap.jam_rawat`;

  const [rows] = await db.query(query, [doctorCodes.length > 0 ? doctorCodes : ['-'], no_rawat]);

  if (rows.length === 0) {
    return response.noContent(res);
  }

  const mapped = rows.map((r) => {
    const isVerified = r.status_verifikasi === 'SUDAH';
    const isExpired = r.status_verifikasi === 'KADALUARSA';
    const isDPJP = isSuperAdmin || r.is_patient_dpjp > 0;
    const isOwnEntry = doctorCodes.includes(r.nip) || r.nip === username;

    return {
      ...r,
      is_verified: isVerified,
      is_own_entry: isOwnEntry,
      can_verify: isSuperAdmin ? !isVerified : (!isVerified && !isExpired && isDPJP && !isOwnEntry),
    };
  });

  return response.ok(res, mapped);
};
```

- [ ] **Step 2: Perbarui kueri SQL di `riwayatSoapRalanController.js`**

Lakukan hal serupa untuk Ralan dengan `LEFT JOIN verifikasi_pemeriksaan_ralan` dan pengecekan DPJP pada `reg_periksa.kd_dokter`.

- [ ] **Step 3: Uji endpoint melalui test suite**

Jalankan:
```bash
cd /home/malifnasrulloh/Downloads/Backend-Dokter && npm test
```
Expected: PASS

- [ ] **Step 4: Commit**

```bash
cd /home/malifnasrulloh/Downloads/Backend-Dokter
git add controllers/rekammedis/riwayat/riwayatSoapRanapController.js controllers/rekammedis/riwayat/riwayatSoapRalanController.js
git commit -m "feat(soap): enrich soap history with verification metadata and status"
```

---

### Task 3: Controller & Rute Eksekusi Verifikasi SOAP di Backend-Dokter

**Files:**
- Create: `/home/malifnasrulloh/Downloads/Backend-Dokter/controllers/rekammedis/pemeriksaan/soapVerificationController.js`
- Modify: `/home/malifnasrulloh/Downloads/Backend-Dokter/routes/rekammedis/soapRoute.js`
- Modify: `/home/malifnasrulloh/Downloads/Backend-Dokter/middleware/writeAccessMiddleware.js`
- Test: `/home/malifnasrulloh/Downloads/Backend-Dokter/tests/e2e/soap-verification.e2e.test.js`

**Interfaces:**
- Consumes: `soapVerificationService.js`
- Produces:
  - `POST /api/soap/verifikasi`
  - `DELETE /api/soap/verifikasi`

- [ ] **Step 1: Tambahkan exempt paths di `middleware/writeAccessMiddleware.js`**

Edit `middleware/writeAccessMiddleware.js` agar menyertakan:
```javascript
const exemptPaths = options.exemptPaths || [
  '/api/pemeriksaan/validasi',
  '/pemeriksaan/validasi',
  '/api/soap/verifikasi',
  '/soap/verifikasi',
];
```

- [ ] **Step 2: Implementasikan `soapVerificationController.js`**

Buat file `/home/malifnasrulloh/Downloads/Backend-Dokter/controllers/rekammedis/pemeriksaan/soapVerificationController.js`:
```javascript
const response = require('../../../middleware/responseHandler');
const { isDoctorDPJP, verifySoap, unverifySoap } = require('../../../services/soapVerificationService');
const { resolveDoctorKdSet } = require('../../../utils/doctorIdentity');

exports.verifikasiSoap = async (req, res) => {
  const { no_rawat, tgl_perawatan, jam_rawat, jenis = 'ranap', catatan } = req.body || {};
  if (!no_rawat || !tgl_perawatan || !jam_rawat) {
    return response.badRequest(res, 'Parameter no_rawat, tgl_perawatan, dan jam_rawat wajib diisi');
  }

  const user = req.user || {};
  const username = user.username || '';
  const isSuperAdmin = user.isadmin === true || username.toLowerCase() === 'admin';

  // 1. Validasi hak DPJP
  const isDPJP = await isDoctorDPJP(no_rawat, username, jenis, isSuperAdmin);
  if (!isDPJP) {
    return response.forbidden(res, 'Maaf, Anda bukan Dokter DPJP untuk pasien ini');
  }

  // 2. Ambil kode dokter verifikator
  const doctorCodes = await resolveDoctorKdSet(username);
  const kdDokterVerif = doctorCodes.length > 0 ? doctorCodes[0] : username;

  try {
    const data = await verifySoap({
      noRawat: no_rawat,
      tglPerawatan: tgl_perawatan,
      jamRawat: jam_rawat,
      jenis,
      kdDokter: kdDokterVerif,
      catatan,
      isSuperAdmin
    });
    return response.ok(res, data, 'Catatan SOAPIE berhasil diverifikasi oleh DPJP');
  } catch (err) {
    if (err.message === 'ALREADY_VERIFIED') {
      return response.badRequest(res, 'Catatan SOAPIE ini sudah diverifikasi sebelumnya');
    }
    if (err.message === 'VERIFICATION_EXPIRED') {
      return response.forbidden(res, 'Batas waktu verifikasi DPJP telah berakhir (Kadaluarsa). Hanya SuperAdmin yang dapat memberikan dispensasi');
    }
    return response.internalError(req, res, err, 'Gagal memproses verifikasi SOAPIE');
  }
};

exports.batalVerifikasiSoap = async (req, res) => {
  const { no_rawat, tgl_perawatan, jam_rawat, jenis = 'ranap' } = req.body || {};
  if (!no_rawat || !tgl_perawatan || !jam_rawat) {
    return response.badRequest(res, 'Parameter no_rawat, tgl_perawatan, dan jam_rawat wajib diisi');
  }

  const user = req.user || {};
  const username = user.username || '';
  const isSuperAdmin = user.isadmin === true || username.toLowerCase() === 'admin';

  if (!isSuperAdmin) {
    return response.forbidden(res, 'Catatan SOAPIE ini sudah diverifikasi oleh DPJP. Hanya SuperAdmin yang berwenang membatalkan verifikasi');
  }

  try {
    await unverifySoap({ noRawat: no_rawat, tglPerawatan: tgl_perawatan, jamRawat: jam_rawat, jenis, isSuperAdmin });
    return response.ok(res, null, 'Verifikasi SOAPIE berhasil dibatalkan');
  } catch (err) {
    if (err.message === 'NOT_FOUND') {
      return response.notFound(res, 'Data verifikasi tidak ditemukan');
    }
    return response.internalError(req, res, err, 'Gagal membatalkan verifikasi SOAPIE');
  }
};
```

- [ ] **Step 3: Daftarkan rute di `routes/rekammedis/soapRoute.js`**

Tambahkan rute:
```javascript
const soapVerificationController = require('../../controllers/rekammedis/pemeriksaan/soapVerificationController');

router.post('/verifikasi', asyncHandler(soapVerificationController.verifikasiSoap));
router.delete('/verifikasi', asyncHandler(soapVerificationController.batalVerifikasiSoap));
```

- [ ] **Step 4: Integrasikan verifikasi otomatis saat DPJP membuat SOAP baru di `soapController.js`**

Pada `createSoapRanap` dan `createSoapRalan`:
Jika dokter yang membuat adalah DPJP pasien tersebut, panggil `verifySoap` secara otomatis di dalam blok transaksi penyimpanan.

- [ ] **Step 5: Buat end-to-end test dan jalankan**

Buat file `/home/malifnasrulloh/Downloads/Backend-Dokter/tests/e2e/soap-verification.e2e.test.js` dan jalankan:
```bash
cd /home/malifnasrulloh/Downloads/Backend-Dokter && npx vitest run tests/e2e/soap-verification.e2e.test.js
```
Expected: PASS

- [ ] **Step 6: Commit**

```bash
cd /home/malifnasrulloh/Downloads/Backend-Dokter
git add controllers/rekammedis/pemeriksaan/soapVerificationController.js routes/rekammedis/soapRoute.js middleware/writeAccessMiddleware.js controllers/rekammedis/pemeriksaan/soapController.js tests/e2e/soap-verification.e2e.test.js
git commit -m "feat(soap): add verification endpoints and auto-verify on dpjp creation"
```

---

### Task 4: UI & Modal BottomSheet Verifikasi SOAPIE di Aplikasi Flutter (`simrs-dokter`)

**Files:**
- Create: `/home/malifnasrulloh/Downloads/simrs-dokter/lib/features/rekam_medis/views/dialogs/verifikasi_soapie_sheet.dart`
- Modify: `/home/malifnasrulloh/Downloads/simrs-dokter/lib/features/rekam_medis/controllers/rekam_medis_controller.dart`
- Modify: `/home/malifnasrulloh/Downloads/simrs-dokter/lib/features/rekam_medis/views/widgets/soap_tile.dart`

**Interfaces:**
- Consumes: `/api/soap/verifikasi`, `RekamMedisController`
- Produces: BottomSheet interaktif & 3-tier styling pada tile kartu SOAPIE.

- [ ] **Step 1: Tambahkan method `verifikasiSoapie` pada `RekamMedisController`**

Edit `/home/malifnasrulloh/Downloads/simrs-dokter/lib/features/rekam_medis/controllers/rekam_medis_controller.dart`:
```dart
Future<bool> verifikasiSoapie({
  required String jenis,
  required String tglPerawatan,
  required String jamRawat,
  String? catatan,
}) async {
  try {
    final payload = {
      'no_rawat': noRawat,
      'tgl_perawatan': tglPerawatan,
      'jam_rawat': jamRawat,
      'jenis': jenis,
      if (catatan != null && catatan.trim().isNotEmpty) 'catatan': catatan.trim(),
    };

    final res = await _api.dio.post('/soap/verifikasi', data: payload);
    if (res.data != null && res.data['success'] == true) {
      Get.snackbar(
        'Berhasil',
        'Catatan SOAPIE berhasil diverifikasi oleh DPJP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
      );
      // Refresh riwayat SOAPIE
      if (jenis == 'ranap') {
        fetchSoapRanap();
      } else {
        fetchSoapRalan();
      }
      return true;
    }
    return false;
  } catch (e) {
    AppLogger.error('Verifikasi SOAPIE', e);
    Get.snackbar(
      'Gagal Verifikasi',
      e.toString(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
    );
    return false;
  }
}
```

- [ ] **Step 2: Buat widget Modal BottomSheet `VerifikasiSoapieSheet`**

Buat file `/home/malifnasrulloh/Downloads/simrs-dokter/lib/features/rekam_medis/views/dialogs/verifikasi_soapie_sheet.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/rekam_medis_controller.dart';

class VerifikasiSoapieSheet extends StatefulWidget {
  final Map<String, dynamic> soapData;
  final String jenis; // 'ranap' | 'ralan'

  const VerifikasiSoapieSheet({
    Key? key,
    required this.soapData,
    required this.jenis,
  }) : super(key: key);

  static void show(BuildContext context, Map<String, dynamic> soapData, String jenis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VerifikasiSoapieSheet(soapData: soapData, jenis: jenis),
    );
  }

  @override
  State<VerifikasiSoapieSheet> createState() => _VerifikasiSoapieSheetState();
}

class _VerifikasiSoapieSheetState extends State<VerifikasiSoapieSheet> {
  final _catatanController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RekamMedisController>();
    final pembuat = widget.soapData['nama'] ?? '-';
    final tglJam = '${widget.soapData['tgl_perawatan']} ${widget.soapData['jam_rawat']}';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Verifikasi SOAPIE oleh DPJP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PPA Pembuat : $pembuat', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Waktu Asuhan : $tglJam', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Catatan / Instruksi Tambahan DPJP (Opsional):',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _catatanController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Contoh: Lanjutkan terapi, evaluasi TTV per 2 jam...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          final ok = await controller.verifikasiSoapie(
                            jenis: widget.jenis,
                            tglPerawatan: widget.soapData['tgl_perawatan'],
                            jamRawat: widget.soapData['jam_rawat'],
                            catatan: _catatanController.text,
                          );
                          setState(() => _isLoading = false);
                          if (ok && mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verifikasi Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Perbarui `SoapTile` (`features/rekam_medis/views/widgets/soap_tile.dart`)**

Perbarui tampilan `SoapTile`:
1. Badge Terverifikasi Hijau: jika `data['is_verified'] == true`. Tampilkan nama verifikator `data['v_nm_dokter']`, jam verifikasi, dan kutipan `data['v_catatan']` jika ada.
2. Badge Kadaluarsa Merah: jika `data['status_verifikasi'] == 'KADALUARSA'`. Tombol Verifikasi dinonaktifkan dengan tooltip atau dialog penjelasan.
3. Tombol Verifikasi Hijau: jika `data['can_verify'] == true`. Memanggil `VerifikasiSoapieSheet.show(context, data, jenis)`.

- [ ] **Step 4: Jalankan flutter analyzer dan test**

Jalankan:
```bash
flutter analyze
flutter test
```
Expected: Tidak ada lint error fatal dan tes berjalan lancar.

- [ ] **Step 5: Commit**

```bash
git add lib/features/rekam_medis/views/dialogs/verifikasi_soapie_sheet.dart lib/features/rekam_medis/controllers/rekam_medis_controller.dart lib/features/rekam_medis/views/widgets/soap_tile.dart
git commit -m "feat(rekam_medis): implement soapie verification sheet and 3-tier styling in soap tile"
```

---

### Task 5: Uji Kompatibilitas Menyeluruh & Sinkronisasi Dua Arah

**Files:**
- Modify / Verify: Sinkronisasi database `siknu` dengan desktop `mastering-khanza`

- [ ] **Step 1: Uji verifikasi dari Flutter ke Database `siknu`**
Pastikan baris verifikasi masuk ke `verifikasi_pemeriksaan_ranap` dan `audit_trail_klinis`.

- [ ] **Step 2: Uji tampilan di Desktop `mastering-khanza`**
Buka data pasien yang telah diverifikasi di mobile pada aplikasi desktop, pastikan baris otomatis berwarna hijau `#E6FFE6` (*SUDAH*) dan QR Code tanda tangan siap dicetak.

- [ ] **Step 3: Commit final plan & docs**

```bash
git add docs/superpowers/plans/2026-10-10-verifikasi-soapie-dpjp.md
git commit -m "docs(plan): rencana implementasi verifikasi soapie dpjp"
```
