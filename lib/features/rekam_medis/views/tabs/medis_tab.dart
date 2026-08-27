import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../controllers/rekam_medis_controller.dart';
import '../dialogs/soap_form_sheet.dart';
import '../widgets/soap_tile.dart';

/// Clinical timeline tab showing all historical medical records, neonatal/obstetric assessments, and SOAP notes.
class MedisTab extends StatelessWidget {
  final RekamMedisController ctrl;

  const MedisTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child:
              CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
        );
      }
      if (ctrl.hasError.value && ctrl.riwayatMedis.isEmpty) {
        return ErrorRetryWidget(
          message: 'Gagal memuat rekam medis pasien.',
          onRetry: () => ctrl.fetchAllData(),
        );
      }
      final list = ctrl.riwayatMedis;
      final sortedList = list.reversed.toList();
      return Column(
        children: [
          Obx(() {
            if (ctrl.offlineSoapQueue.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_rounded, color: AppTheme.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Koneksi Offline',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.warning,
                            ),
                          ),
                          Text(
                            '${ctrl.offlineSoapQueue.length} data SOAP tersimpan di antrean lokal.',
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warning,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => ctrl.syncOfflineSoap(),
                      child: Text(
                        'Sinkronkan',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Stack(
              children: [
                sortedList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_rounded,
                                size: 48, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text('Belum ada data medis',
                                style: GoogleFonts.outfit(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: sortedList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final data = sortedList[index];
                          final uniqueId =
                              '${data['tanggal']}_${data['jam']}_$index';
                          return SoapTile(
                            key: GlobalObjectKey(uniqueId),
                            data: data,
                            initiallyExpanded: index == 0,
                          );
                        },
                      ),
                if (ctrl.writeEnabled)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: () => showSoapForm(context, ctrl),
                      backgroundColor: AppTheme.primary,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        'Tambah SOAP',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
