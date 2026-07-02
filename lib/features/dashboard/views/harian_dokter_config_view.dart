import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/harian_dokter_config_controller.dart';

class HarianDokterConfigView extends StatelessWidget {
  const HarianDokterConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(HarianDokterConfigController());
    final searchCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'Konfigurasi Akses Harian',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.bgCard,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Cari Nama atau Kode Dokter...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              onChanged: ctrl.filterDoctors,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (ctrl.filteredDoctors.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada dokter ditemukan',
                    style: GoogleFonts.outfit(color: AppTheme.textMuted),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: ctrl.fetchAccessList,
                color: AppTheme.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: ctrl.filteredDoctors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = ctrl.filteredDoctors[index];
                    final code = doc['kd_dokter']?.toString() ?? '';
                    final name = doc['nm_dokter']?.toString() ?? '';
                    final spesialis = doc['spesialis']?.toString() ?? '-';
                    final isEnabled = doc['harian_dokter'] == true;

                    return Card(
                      color: AppTheme.bgCard,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.divider, width: 0.8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$spesialis • Kode: $code',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CupertinoSwitch(
                              activeColor: AppTheme.primary,
                              value: isEnabled,
                              onChanged: (val) => ctrl.toggleAccess(code, val),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
