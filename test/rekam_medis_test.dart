import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:simrs_dokter/features/auth/controllers/auth_controller.dart';
import 'package:simrs_dokter/features/rekam_medis/controllers/rekam_medis_controller.dart';
import 'package:simrs_dokter/features/rekam_medis/views/rekam_medis_view.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    TestHelper.setupTestMockChannels();
    TestHelper.setupMockApi();
  });

  setUp(() {
    Get.reset();
    TestHelper.mockSecureStorage.clear();
    final authCtrl = Get.put(AuthController());
    authCtrl.user.value = {
      'kd_dokter': 'D0001',
      'nm_dokter': 'Dr. Test Provider',
      'nama': 'Dr. Test Provider',
      'nip': 'D0001',
    };
  });

  group('RekamMedisController Unit Tests', () {
    test('initializes and loads patient data from arguments', () async {
      final mockArgs = {
        'no_rawat': '2026/06/20/0001',
        'no_rkm_medis': 'P00001',
        'nm_pasien': 'Budi Santoso',
        '_type': 'RANAP',
      };
      Get.routing.args = mockArgs;

      final controller = Get.put(RekamMedisController());
      await controller.fetchAllData();

      expect(controller.pasienData.value, isNotNull);
      expect(controller.pasienData.value?['no_rawat'], '2026/06/20/0001');

      // Verify SOAP list loaded
      expect(controller.riwayatMedis.length, equals(1));
      expect(controller.riwayatMedis[0]['keluhan_utama'], 'Keluhan sesak');
    });

    test('validasiSbar posts response and returns true', () async {
      Get.routing.args = {
        'no_rawat': '2026/06/20/0001',
        'no_rkm_medis': 'P00001',
        '_type': 'RANAP',
      };
      final controller = Get.put(RekamMedisController());
      await controller.fetchAllData();

      final result = await controller.validasiSbar(
        noPermintaan: 'KM202606200001',
        tglPerawatan: '2026-06-20',
        jamRawat: '08:00:00',
        respon: 'Ok Tanggapan',
        instruksi: 'Terapi dilanjutkan',
        rencana: 'Pulang besok',
      );

      expect(result, isTrue);
    });

    test('saveSoap posts data and refreshes list', () async {
      Get.routing.args = {
        'no_rawat': '2026/06/20/0001',
        'no_rkm_medis': 'P00001',
        '_type': 'RANAP',
      };
      final controller = Get.put(RekamMedisController());
      await controller.fetchAllData();

      final result = await controller.saveSoap(
        data: {
          'keluhan': 'Sesak bertambah',
          'pemeriksaan': 'Paru ronkhi',
          'suhu': '37.2',
          'tensi': '130/90',
          'nadi': '90',
          'respirasi': '24',
          'tinggi': '170',
          'berat': '65',
          'gcs': '15',
          'kesadaran': 'Compos Mentis',
          'rtl': 'Terapi nebulizer',
          'penilaian': 'Asma eksaserbasi akut',
          'instruksi': 'Nebulizer tiap 4 jam',
        },
      );

      expect(result, isTrue);
    });

    testWidgets('SSE alerts trigger local notifications and refreshes lists', (WidgetTester tester) async {
      debugPrint('=== SSE Test: Start ===');
      Get.routing.args = {
        'no_rawat': '2026/06/20/0001',
        'no_rkm_medis': 'P00001',
        '_type': 'RANAP',
      };
      // Pump MaterialApp so GetX has overlay context for Snackbars
      await tester.pumpWidget(GetMaterialApp(home: const Scaffold()));
      debugPrint('=== SSE Test: MaterialApp pumped ===');
      
      final controller = Get.put(RekamMedisController());
      debugPrint('=== SSE Test: Controller put ===');

      await tester.runAsync(() async {
        await controller.fetchAllData();
        debugPrint('=== SSE Test: Data fetched ===');

        // 1. Test new_admission event
        controller.handleSseEventForTesting('new_admission', {
          'no_rawat': '2026/06/20/0004',
          'nm_pasien': 'Test Admission Patient',
        });
        debugPrint('=== SSE Test: Event 1 handled ===');

        // 2. Test emergency_igd_consultation event
        controller.handleSseEventForTesting('emergency_igd_consultation', {
          'nm_dokter_pemberi': 'Dr. IGD Sender',
          'nm_pasien': 'IGD Emergency Patient',
        });
        debugPrint('=== SSE Test: Event 2 handled ===');

        // 3. Test consultation_request event
        controller.handleSseEventForTesting('consultation_request', {
          'nm_dokter_pemberi': 'Dr. Consult Sender',
          'nm_pasien': 'Budi Santoso',
        });
        debugPrint('=== SSE Test: Event 3 handled ===');

        // 4. Test consultation_response event
        controller.handleSseEventForTesting('consultation_response', {
          'nm_dokter_pemberi': 'Dr. Consult Responder',
          'nm_pasien': 'Budi Santoso',
        });
        debugPrint('=== SSE Test: Event 4 handled ===');
      });

      await tester.pumpAndSettle();
      debugPrint('=== SSE Test: Pump completed ===');

      // Simple verify that calls didn't crash
      expect(controller.riwayatMedis.length, equals(1));
      debugPrint('=== SSE Test: Finish ===');
    });
  });

  group('RekamMedisView Widget Tests', () {
    testWidgets('renders patient details and SOAP entries', (WidgetTester tester) async {
      Get.routing.args = {
        'no_rawat': '2026/06/20/0001',
        'no_rkm_medis': 'P00001',
        'nm_pasien': 'Budi Santoso',
        '_type': 'RANAP',
      };
      final controller = Get.put(RekamMedisController());
      await tester.runAsync(() async {
        await controller.fetchAllData();
      });

      addTearDown(() {
        Get.closeAllSnackbars();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          home: const RekamMedisView(),
        ),
      );
      controller.showDetails.value = true;
      await tester.pumpAndSettle();

      // Verify patient basic info is rendered on screen
      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.text('2026/06/20/0001'), findsOneWidget);
    });
  });
}
