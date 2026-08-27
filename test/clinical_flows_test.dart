import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:simrs_dokter/features/auth/controllers/auth_controller.dart';
import 'package:simrs_dokter/features/rekam_medis/controllers/rekam_medis_controller.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    TestHelper.setupTestMockChannels();
    TestHelper.setupMockApi();
  });

  setUp(() {
    Get.reset();
    Get.put(AuthController());
    TestHelper.mockWriteAccess = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Prescription & E-Prescribing Flows', () {
    test('searchObat queries medicine list and populates results', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
        'nm_pasien': 'Widji Ernawati',
        '_type': 'RANAP',
      };

      await ctrl.searchObat('paracetamol');
      expect(ctrl.searchObatResults.isNotEmpty, true);
    });

    test('addToPrescription adds item and manages duplicates in draft', () {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      final item = {
        'kode_brng': 'OBT001',
        'nama_brng': 'Paracetamol 500mg',
        'satuan': 'tablet',
      };

      ctrl.addToPrescription(item);
      expect(ctrl.prescriptionDraft.length, 1);
      expect(ctrl.prescriptionDraft[0]['kode_brng'], 'OBT001');

      // Adding same item should not duplicate
      ctrl.addToPrescription(item);
      expect(ctrl.prescriptionDraft.length, 1);
    });

    test('removeFromPrescription and clearPrescriptionDraft update state', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      ctrl.addToPrescription({'kode_brng': 'OBT001', 'nama_brng': 'Obat A'});
      ctrl.addToPrescription({'kode_brng': 'OBT002', 'nama_brng': 'Obat B'});
      expect(ctrl.prescriptionDraft.length, 2);

      ctrl.removeFromPrescription('OBT001');
      expect(ctrl.prescriptionDraft.length, 1);
      expect(ctrl.prescriptionDraft[0]['kode_brng'], 'OBT002');

      await ctrl.clearPrescriptionDraft();
      expect(ctrl.prescriptionDraft.isEmpty, true);
    });

    test('submitPrescription sends prescription and refreshes list', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      ctrl.addToPrescription({
        'kode_brng': 'OBT001',
        'nama_brng': 'Paracetamol 500mg',
        'jml': 10,
        'aturan_pakai': '3x1 tablet',
      });

      final success = await ctrl.submitPrescription();
      expect(success, true);
      expect(ctrl.prescriptionDraft.isEmpty, true);
    });
  });

  group('Consultation & Referral Flows', () {
    test('fetchConsultations and fetchDokterList populate consultation state', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      await ctrl.fetchDokterList();
      expect(ctrl.dokterList.isNotEmpty, true);

      await ctrl.fetchConsultations();
      expect(ctrl.incomingConsults.isNotEmpty, true);
    });

    test('sendConsultation sends referral request and returns success', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      final success = await ctrl.sendConsultation(
        targetDokter: '2021101713',
        jenis: 'Konsultasi',
        diagnosa: 'Post Op Care',
        uraian: 'Mohon advice terapi antibiotik lanjutan',
      );

      expect(success, true);
    });

    test('replyConsultation sends consultation reply and returns success', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      final success = await ctrl.replyConsultation(
        noPermintaan: 'KM202608260001',
        diagnosa: 'Post Op Baik',
        uraian: 'Lanjutkan antibiotik ceftriaxone 2x1g',
      );

      expect(success, true);
    });
  });

  group('SOAP Draft & Offline Persistence', () {
    test('saveSoapDraft and clearSoapDraft manage draft state', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      await ctrl.saveSoapDraft({
        'keluhan_utama': 'Nyeri kepala berdenyut',
        'diagnosis': 'Cephalea tension',
      });

      expect(ctrl.soapDraft['keluhan_utama'], 'Nyeri kepala berdenyut');
      expect(ctrl.soapDraft['diagnosis'], 'Cephalea tension');

      await ctrl.clearSoapDraft();
      expect(ctrl.soapDraft.isEmpty, true);
    });
  });

  group('Diagnosa & Prosedur Add/Delete Flows', () {
    test('addDiagnosa adds diagnosis and refreshes list', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      final success = await ctrl.addDiagnosa(
        kdPenyakit: 'J45',
        prioritas: 1,
        statusPenyakit: 'Baru',
      );

      expect(success, true);
    });

    test('deleteDiagnosa removes diagnosis and refreshes list', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      final success = await ctrl.deleteDiagnosa('J45');
      expect(success, true);
    });

    test('addProsedur adds procedure and refreshes list', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      final success = await ctrl.addProsedur(kode: '01.01', prioritas: 1);
      expect(success, true);
    });

    test('deleteProsedur removes procedure and refreshes list', () async {
      final ctrl = Get.put(RekamMedisController());
      ctrl.pasienData.value = {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '009483',
      };

      final success = await ctrl.deleteProsedur('01.01');
      expect(success, true);
    });
  });
}
