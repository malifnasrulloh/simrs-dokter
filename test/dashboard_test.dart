import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:simrs_dokter/features/auth/controllers/auth_controller.dart';
import 'package:simrs_dokter/features/dashboard/controllers/dashboard_controller.dart';
import 'package:simrs_dokter/features/dashboard/views/dashboard_view.dart';
import 'package:simrs_dokter/features/dashboard/views/home_dashboard_view.dart';
import 'package:simrs_dokter/features/dashboard/views/patient_workspace_view.dart';
import 'package:simrs_dokter/features/dashboard/views/harian_dokter_view.dart';
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

  group('DashboardController Unit Tests', () {
    test('initializes states and loads dashboard data successfully', () async {
      final controller = Get.put(DashboardController());

      // Wait for async initialization
      while (controller.isLoading.value) {
        await Future.delayed(Duration.zero);
      }

      expect(controller.isLoading.value, isFalse);

      // Verify patient lists loaded from mock ApiClient
      expect(controller.listPasienRanap.length, equals(1));
      expect(controller.listPasienRanap[0]['nm_pasien'], 'Budi Santoso');
      expect(controller.totalRanap.value, equals(1));

      expect(controller.listPasienRalan.length, equals(1));
      expect(controller.listPasienRalan[0]['nm_pasien'], 'Siti Aminah');
      expect(controller.totalRalan.value, equals(1));

      expect(controller.listPasienIGD.length, equals(1));
      expect(controller.listPasienIGD[0]['nm_pasien'], 'Joko Susilo');
      expect(controller.totalIGD.value, equals(1));

      // Verify bed info and schedule loads
      expect(controller.listJadwalOperasi.length, equals(1));
      expect(controller.listJadwalOperasi[0]['nm_operasi'], 'Operasi Usus Buntu');
    });

    test('harian dokter fetching handles lists and pagination', () async {
      final controller = Get.put(DashboardController());

      while (controller.isLoadingHarian.value) {
        await Future.delayed(Duration.zero);
      }

      await controller.fetchHarianDokter();

      expect(controller.isLoadingHarian.value, isFalse);
      expect(controller.harianList.length, equals(1));
      expect(controller.harianList[0]['nm_pasien'], 'Budi Santoso');
      expect(controller.totalHarianCount.value, equals(1));
    });
  });

  group('Dashboard UI & Navigation Integration Tests', () {
    testWidgets('renders DashboardView, handles bottom tab switching', (WidgetTester tester) async {
      // Set test viewport to avoid overflow exceptions
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Get.put(DashboardController());

      await tester.pumpWidget(
        GetMaterialApp(
          home: const DashboardView(),
        ),
      );
      await tester.pumpAndSettle();

      // Home Page should be loaded initially
      expect(find.byType(HomeDashboardView), findsOneWidget);
      expect(find.text('Dr. Test Provider'), findsOneWidget);

      // Verify patient counters are showing numbers
      expect(find.text('1'), findsNWidgets(3)); // Ranap, Ralan, and IGD totals are all '1'

      // Tap on bottom navigation item 'Jasa Medis'
      await tester.tap(find.text('Jasa Medis'));
      await tester.pumpAndSettle();

      // HarianDokterView should be active
      expect(find.byType(HarianDokterView), findsOneWidget);
    });

    testWidgets('navigates to PatientWorkspaceView and filters correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Get.put(DashboardController());

      await tester.pumpWidget(
        GetMaterialApp(
          home: const DashboardView(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Inpatient/Rawat Inap total card and tap it
      expect(find.text('Pasien Rawat Inap'), findsOneWidget);
      await tester.tap(find.text('Pasien Rawat Inap'));
      await tester.pumpAndSettle();

      // Verify it switched body to PatientWorkspaceView
      expect(find.byType(PatientWorkspaceView), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('P00001'), findsOneWidget);
    });
  });
}
