import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../controllers/rekam_medis_controller.dart';
import '../dialogs/diagnosa_dialogs.dart';
import '../widgets/clinical_card.dart';

/// Diagnosis & procedure tab (ICD-10 active diagnoses + ICD-9 procedures).
class DiagnosaTab extends StatefulWidget {
  final RekamMedisController ctrl;

  const DiagnosaTab({super.key, required this.ctrl});

  @override
  State<DiagnosaTab> createState() => _DiagnosaTabState();
}

class _DiagnosaTabState extends State<DiagnosaTab> {
  final _icd10SearchCtrl = TextEditingController();
  final _icd9SearchCtrl = TextEditingController();

  @override
  void dispose() {
    _icd10SearchCtrl.dispose();
    _icd9SearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;

    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child:
              CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ──── DIAGNOSA (ICD-10) ────
            Text(
              'Diagnosa (ICD-10)',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
            if (ctrl.writeEnabled) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _icd10SearchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Cari ICD-10 (Kode atau Deskripsi)...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (val) => ctrl.searchICD10(val),
              ),
              const SizedBox(height: 8),

              // Autocomplete results ICD-10
              Obx(() {
                if (ctrl.isLoadingICD.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                }
                if (ctrl.searchICD10Results.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: ctrl.searchICD10Results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (context, idx) {
                      final item = ctrl.searchICD10Results[idx];
                      final code = item['kd_penyakit']?.toString() ?? '';
                      final name = item['nm_penyakit']?.toString() ?? '';
                      return ListTile(
                        dense: true,
                        title: Text('$code - $name',
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        onTap: () {
                          ctrl.searchICD10Results.clear();
                          _icd10SearchCtrl.clear();
                          showAddDiagnosaDialog(context, ctrl, code, name);
                        },
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 12),

            // Active diagnoses list
            Obx(() {
              if (ctrl.diagnosa.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                      child: Text('Belum ada diagnosa aktif',
                          style:
                              GoogleFonts.outfit(color: AppTheme.textMuted))),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ctrl.diagnosa.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final d = ctrl.diagnosa[i];
                  final code = d['kd_penyakit']?.toString() ?? '';
                  final name = d['nm_penyakit'] ?? code;
                  final priority = d['prioritas']?.toString() ?? '-';
                  final status = d['status_penyakit']?.toString() ?? '-';

                  return buildListCard(
                    icon: Icons.medical_information_rounded,
                    iconColor: AppTheme.info,
                    title: name,
                    subtitle:
                        'Kode: $code • Prioritas: $priority • Status: $status',
                    trailing: ctrl.writeEnabled
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.danger, size: 18),
                            tooltip: 'Hapus diagnosa',
                            onPressed: () => ctrl.deleteDiagnosa(code),
                          )
                        : null,
                  );
                },
              );
            }),

            const SizedBox(height: 24),
            const Divider(color: AppTheme.divider),
            const SizedBox(height: 16),

            // ──── PROSEDUR (ICD-9-CM) ────
            Text(
              'Prosedur (ICD-9-CM)',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
            if (ctrl.writeEnabled) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _icd9SearchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Cari ICD-9 (Kode atau Deskripsi)...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (val) => ctrl.searchICD9(val),
              ),
              const SizedBox(height: 8),

              // Autocomplete results ICD-9
              Obx(() {
                if (ctrl.isLoadingICD.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                }
                if (ctrl.searchICD9Results.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: ctrl.searchICD9Results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (context, idx) {
                      final item = ctrl.searchICD9Results[idx];
                      final code = item['kode']?.toString() ?? '';
                      final name = item['deskripsi_panjang']?.toString() ??
                          item['deskripsi_pendek']?.toString() ??
                          '';
                      return ListTile(
                        dense: true,
                        title: Text('$code - $name',
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        onTap: () {
                          ctrl.searchICD9Results.clear();
                          _icd9SearchCtrl.clear();
                          showAddProsedurDialog(context, ctrl, code, name);
                        },
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 12),

            // Active procedures list
            Obx(() {
              if (ctrl.prosedurList.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                      child: Text('Belum ada prosedur aktif',
                          style:
                              GoogleFonts.outfit(color: AppTheme.textMuted))),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ctrl.prosedurList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = ctrl.prosedurList[i];
                  final code = p['kode']?.toString() ?? '';
                  final name = p['deskripsi_panjang']?.toString() ??
                      p['deskripsi_pendek']?.toString() ??
                      code;
                  final priority = p['prioritas']?.toString() ?? '1';

                  return buildListCard(
                    icon: Icons.settings_accessibility_rounded,
                    iconColor: AppTheme.accentAlt,
                    title: name,
                    subtitle: 'Kode: $code • Prioritas: $priority',
                    trailing: ctrl.writeEnabled
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.danger, size: 18),
                            tooltip: 'Hapus prosedur',
                            onPressed: () => ctrl.deleteProsedur(code),
                          )
                        : null,
                  );
                },
              );
            }),
          ],
        ),
      );
    });
  }
}
