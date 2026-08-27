import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simrs_dokter/features/dashboard/widgets/patient_search_bar.dart';

void main() {
  group('filterPatientList Helper Tests', () {
    final samplePatients = [
      {
        'no_rawat': '2026/08/24/000001',
        'no_rkm_medis': '001234',
        'nm_pasien': 'Budi Santoso',
        'kamar': 'Mawar 01',
        'nm_dokter': 'dr. Setiawan',
      },
      {
        'no_rawat': '2026/08/24/000002',
        'no_rkm_medis': '005678',
        'nm_pasien': 'Siti Rahayu',
        'kamar': 'Melati 02',
        'nm_dokter': 'dr. Aisyah',
      },
      {
        'no_rawat': '2026/08/24/000003',
        'no_rkm_medis': '009012',
        'nm_pasien': 'Ahmad Fauzi',
        'nm_poli': 'Poli Penyakit Dalam',
        'nm_dokter': 'dr. Setiawan',
      },
    ];

    test('returns full list when query is empty', () {
      final result = filterPatientList(samplePatients, '');
      expect(result.length, 3);
    });

    test('filters by patient name (case-insensitive)', () {
      final result = filterPatientList(samplePatients, 'budi');
      expect(result.length, 1);
      expect(result[0]['nm_pasien'], 'Budi Santoso');
    });

    test('filters by medical record number (No RM)', () {
      final result = filterPatientList(samplePatients, '005678');
      expect(result.length, 1);
      expect(result[0]['nm_pasien'], 'Siti Rahayu');
    });

    test('filters by room or clinic name', () {
      final result1 = filterPatientList(samplePatients, 'Melati');
      expect(result1.length, 1);

      final result2 = filterPatientList(samplePatients, 'Dalam');
      expect(result2.length, 1);
      expect(result2[0]['nm_pasien'], 'Ahmad Fauzi');
    });

    test('filters by doctor name', () {
      final result = filterPatientList(samplePatients, 'Aisyah');
      expect(result.length, 1);
      expect(result[0]['nm_pasien'], 'Siti Rahayu');
    });

    test('returns empty list when no matches found', () {
      final result = filterPatientList(samplePatients, 'nonexistent');
      expect(result.isEmpty, true);
    });
  });

  group('PatientSearchBar Widget Tests', () {
    testWidgets('renders search field with hint and prefix icon', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PatientSearchBar(
            controller: controller,
            onChanged: (_) {},
            onClear: () {},
          ),
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('Cari nama, No. RM, atau ruangan...'), findsOneWidget);
    });

    testWidgets('shows clear button when text is present and invokes onClear', (tester) async {
      final controller = TextEditingController(text: 'Budi');
      bool clearCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PatientSearchBar(
            controller: controller,
            onChanged: (_) {},
            onClear: () {
              clearCalled = true;
            },
          ),
        ),
      ));

      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump();

      expect(clearCalled, true);
      expect(controller.text, '');
    });
  });
}
