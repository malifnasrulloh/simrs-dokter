import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../controllers/rekam_medis_controller.dart';
import '../widgets/clinical_card.dart';

/// Laboratory tab displaying test panels, results, normal ranges, and flags (H/L/T).
class LabTab extends StatelessWidget {
  final RekamMedisController ctrl;

  const LabTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingLab.value) {
        return buildShimmerLoader();
      }
      if (ctrl.laboratorium.isEmpty) {
        return buildEmptyState('Belum ada hasil laboratorium',
            icon: Icons.biotech_outlined);
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ctrl.laboratorium.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, groupIndex) {
          final group = ctrl.laboratorium[groupIndex];
          final groupName =
              group['group_name']?.toString() ?? 'Pemeriksaan Lab';
          final items = group['items'] as List? ?? [];

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(17)),
                  ),
                  child: Text(
                    groupName,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Pemeriksaan',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Hasil',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Nilai Rujukan',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppTheme.divider),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, thickness: 0.5, color: AppTheme.divider),
                  itemBuilder: (context, itemIndex) {
                    final l = items[itemIndex] as Map<String, dynamic>;
                    final nmPeriksa = l['pemeriksaan']?.toString() ?? '-';
                    final hasil = l['hasil']?.toString() ?? '-';
                    final satuan = l['satuan']?.toString() ?? '';
                    final normal = l['nilai_normal']?.toString() ?? '-';
                    final ket = l['keterangan']?.toString().toUpperCase() ?? '';

                    Color hasilColor = AppTheme.textPrimary;
                    FontWeight hasilWeight = FontWeight.w800;

                    if (ket == 'H') {
                      hasilColor = AppTheme.danger;
                    } else if (ket == 'L') {
                      hasilColor = AppTheme.info;
                    } else if (ket == 'T') {
                      hasilColor = AppTheme.danger;
                      hasilWeight = FontWeight.w900;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              nmPeriksa,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: hasil,
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 13,
                                      fontWeight: hasilWeight,
                                      color: hasilColor,
                                    ),
                                  ),
                                  if (satuan.isNotEmpty)
                                    TextSpan(
                                      text: ' $satuan',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              normal,
                              style: GoogleFonts.robotoMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
