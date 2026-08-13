import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:simrs_dokter/features/auth/controllers/auth_controller.dart';
import 'package:simrs_dokter/features/rekam_medis/controllers/rekam_medis_controller.dart';
import 'package:simrs_dokter/core/services/notification_polling_service.dart';
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

  tearDown(() {
    Get.delete<RekamMedisController>();
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

    test('IGD riwayat includes obstetric triage (igd-kebidanan)', () async {
      Get.routing.args = {
        'no_rawat': '2026/06/20/0001',
        'no_rkm_medis': 'P00001',
        'nm_pasien': 'Siti Rahayu',
        '_type': 'IGD',
      };
      final controller = Get.put(RekamMedisController());
      await controller.fetchAllData();

      final kebidanan = controller.riwayatMedis
          .where((e) => e['pemeriksaan_fisik']?.contains('TFU: 32') ?? false)
          .toList();
      expect(kebidanan.length, equals(1));
      expect(kebidanan[0]['diagnosis'], contains('Kontraksi teratur'));
      expect(kebidanan[0]['tata'], contains('Observasi his'));
      expect(kebidanan[0]['petugas'], 'Bidan Rina');
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

    test('searchICD10 parses the paginated {list, pagination} envelope',
        () async {
      Get.routing.args = {
        'no_rawat': '2026/06/20/0001',
        'no_rkm_medis': 'P00001',
        '_type': 'RANAP',
      };
      final controller = Get.put(RekamMedisController());
      await controller.fetchAllData();

      controller.searchICD10('asma');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(controller.searchICD10Results.length, 2);
      expect(controller.searchICD10Results.first['kd_penyakit'], 'J45');
    });

    test('searchICD9 parses the paginated {list, pagination} envelope',
        () async {
      Get.routing.args = {
        'no_rawat': '2026/06/20/0001',
        'no_rkm_medis': 'P00001',
        '_type': 'RANAP',
      };
      final controller = Get.put(RekamMedisController());
      await controller.fetchAllData();

      controller.searchICD9('insisi');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(controller.searchICD9Results.length, 1);
      expect(controller.searchICD9Results.first['kode'], '01.01');
    });
  });

  group('Notification Routing Tests', () {
    test('all backend event types map to a known route', () {
      // Keep the trigger set (setup_notification_triggers.sql) in sync:
      // every event_type the triggers can enqueue must be routable.
      const backendEventTypes = [
        'consultation_request',
        'consultation_response',
        'emergency_igd_consultation',
        'sbar_request',
        'second_opinion_request',
        'lab_request',
        'labpa_request',
        'labmb_request',
        'radiology_request',
        'discharge_prescription',
        'prescription_dispensed',
        'medication_stock_request',
        'medication_dispensed',
        'medication_request',
        'spiritual_guidance_request',
        'violence_protection_letter',
        'new_admission',
        'bed_request',
        'surgery_booking',
      ];
      for (final event in backendEventTypes) {
        expect(
          notificationRoutes.containsKey(event),
          isTrue,
          reason: 'Backend trigger enum $event has no route in the app',
        );
        final route = notificationRoutes[event]!;
        expect(route.route, isNotEmpty);
      }
    });

    test('billing threshold events remain routable', () {
      expect(notificationRoutes.containsKey('billing_threshold_80'), isTrue);
      expect(notificationRoutes.containsKey('billing_threshold_100'), isTrue);
      expect(notificationRoutes.containsKey('billing_threshold_120'), isTrue);
    });

    test('support/facility events fall back to the dashboard home', () {
      // kitchen / supply / inventory / leave triggers from the DB trigger
      // set are not patient-bound; they must still be routable (default).
      const facilityEvents = [
        'kitchen_request',
        'kitchen_approved',
        'kitchen_rejected',
        'medical_supply_request',
        'medical_supply_approved',
        'medical_supply_rejected',
        'non_medical_request',
        'non_medical_approved',
        'non_medical_rejected',
        'inventory_repair_request',
        'inventory_application',
        'inventory_approved',
        'inventory_rejected',
        'leave_application',
        'leave_approved',
        'leave_rejected',
        'leave_approved_manajemen',
        'leave_rejected_manajemen',
      ];
      for (final event in facilityEvents) {
        expect(notificationRoutes.containsKey(event), isFalse);
        expect(
          notificationRoutes[event] ?? defaultNotifRoute,
          same(defaultNotifRoute),
          reason: '$event should use the /home fallback',
        );
      }
    });
  });

  group('RekamMedisView Widget Tests', () {
    testWidgets('renders patient details and SOAP entries',
        (WidgetTester tester) async {
      addTearDown(() {
        Get.closeAllSnackbars();
      });
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
      Get.delete<RekamMedisController>();
    });

    testWidgets('hides all write access UI controls in read-only mode',
        (WidgetTester tester) async {
      Get.routing.args = {
        'no_rawat': '2026/06/20/0001',
        'no_rkm_medis': 'P00001',
        'nm_pasien': 'Budi Santoso',
        '_type': 'RANAP',
      };
      Get.put(RekamMedisController());

      await tester.pumpWidget(
        GetMaterialApp(
          home: const RekamMedisView(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure write control FABs and actions are not present in read-only mode
      expect(find.text('Tambah SOAP'), findsNothing);
      expect(find.text('Buat Resep'), findsNothing);
      expect(find.text('Minta Konsul'), findsNothing);
      expect(find.byIcon(Icons.edit_rounded), findsNothing);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      Get.delete<RekamMedisController>();
    });

    testWidgets(
        'server write access reveals controls and konsultasi dialog offers jenis dropdown',
        (WidgetTester tester) async {
      TestHelper.mockWriteAccess = true;
      addTearDown(() => TestHelper.mockWriteAccess = false);
      Get.routing.args = {
        'no_rawat': '2026/06/20/0001',
        'no_rkm_medis': 'P00001',
        'nm_pasien': 'Budi Santoso',
        '_type': 'RANAP',
      };
      final authCtrl = Get.find<AuthController>();
      await tester.runAsync(() => authCtrl.fetchCapabilities());
      final controller = Get.put(RekamMedisController());

      await tester.pumpWidget(
        GetMaterialApp(
          home: const RekamMedisView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.writeEnabled, isTrue);

      // The konsultasi FAB lives on the Konsultasi tab (index 5)
      controller.activeTab.value = 5;
      await tester.pumpAndSettle();
      expect(find.text('Minta Konsul'), findsOneWidget);

      // Open the consultation dialog and verify the jenis dropdown exists
      await tester.tap(find.text('Minta Konsul'));
      await tester.pumpAndSettle();
      expect(find.text('Jenis Konsultasi'), findsOneWidget);
      Get.delete<RekamMedisController>();
    });
  });
}
