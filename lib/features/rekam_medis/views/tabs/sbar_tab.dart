import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/rekam_medis_controller.dart';
import '../widgets/clinical_card.dart';

/// SBAR handover tab showing nurse reports and DPJP verification workflow.
class SbarTab extends StatelessWidget {
  final RekamMedisController ctrl;

  const SbarTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingSbar.value) {
        return buildShimmerLoader();
      }
      final list = ctrl.sbarList;
      if (list.isEmpty) {
        return buildEmptyState('Belum ada handover SBAR',
            icon: Icons.assignment_outlined);
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final sbar = list[index];
          final noPermintaan = sbar['no_permintaan'];
          final tgl = sbar['tgl_perawatan'] ?? '-';
          final jam = sbar['jam_rawat'] ?? '-';
          final isValidated = sbar['validasi']?['status_validasi'] != null;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SBAR Handover',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      '$tgl • $jam',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sbarSection('S (Situation)', sbar['situation']),
                const SizedBox(height: 10),
                _sbarSection('B (Background)', sbar['background']),
                const SizedBox(height: 10),
                _sbarSection('A (Assessment)', sbar['assesment']),
                const SizedBox(height: 10),
                _sbarSection('R (Recommendation)', sbar['recommendation']),
                if (isValidated) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.8),
                  const SizedBox(height: 12),
                  Text(
                    'Respon / Instruksi Dokter:',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (sbar['validasi']?['respon']?.toString().isNotEmpty ==
                      true) ...[
                    _sbarResponseSection(
                        'Tanggapan / Respon', sbar['validasi']['respon']),
                    const SizedBox(height: 6),
                  ],
                  if (sbar['validasi']?['instruksi']?.toString().isNotEmpty ==
                      true) ...[
                    _sbarResponseSection(
                        'Instruksi', sbar['validasi']['instruksi']),
                    const SizedBox(height: 6),
                  ],
                  if (sbar['validasi']?['rencana']?.toString().isNotEmpty ==
                      true) ...[
                    _sbarResponseSection(
                        'Rencana Tindak Lanjut', sbar['validasi']['rencana']),
                  ],
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.8),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dilaporkan oleh: ${sbar['petugas']?['nama'] ?? '-'}',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dokter: ${sbar['dokter']?['nama'] ?? '-'}',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isValidated) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.success.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppTheme.success, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      )
                    ] else if (sbar['dokter']?['nik']?.toString() ==
                        Get.find<AuthController>().user.value?['nip']) ...[
                      ElevatedButton(
                        onPressed: () => _confirmValidasiSbar(
                            context, ctrl, noPermintaan, tgl, jam),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Verifikasi DPJP',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.warning.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pending_actions_rounded,
                                color: AppTheme.warning, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Pending',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _sbarSection(String title, dynamic content) {
    final text = (content == null ||
            content.toString().isEmpty ||
            content.toString() == '-')
        ? '-'
        : content.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 10.5,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _sbarResponseSection(String title, dynamic content) {
    final text = (content == null ||
            content.toString().isEmpty ||
            content.toString() == '-')
        ? '-'
        : content.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 10.5,
            color: AppTheme.primaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  void _confirmValidasiSbar(BuildContext context, RekamMedisController ctrl,
      String? noPermintaan, String tgl, String jam) {
    final responController = TextEditingController(text: 'Sesuai rencana');
    final instruksiController = TextEditingController();
    final rencanaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Respon / Verifikasi SBAR',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Berikan respon, instruksi, dan rencana medis Anda untuk perawat.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Respon / Tanggapan',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: responController,
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Sesuai rencana, Lanjutkan terapi',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Respon tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Instruksi Medis',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: instruksiController,
                      maxLines: 3,
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Masukkan instruksi medis baru (jika ada)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rencana Tindak Lanjut',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: rencanaController,
                      maxLines: 2,
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Rencana USG besok pagi',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.divider),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() ?? false) {
                                Navigator.pop(context);
                                final success = await ctrl.validasiSbar(
                                  noPermintaan: noPermintaan,
                                  tglPerawatan: tgl,
                                  jamRawat: jam,
                                  respon: responController.text.trim(),
                                  instruksi: instruksiController.text.trim(),
                                  rencana: rencanaController.text.trim(),
                                );
                                if (success) {
                                  Get.snackbar(
                                    'Sukses',
                                    'Instruksi SBAR berhasil diverifikasi oleh DPJP',
                                    backgroundColor:
                                        AppTheme.success.withValues(alpha: 0.1),
                                    colorText: AppTheme.success,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Kirim Respon',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
