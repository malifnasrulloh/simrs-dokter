import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../controllers/rekam_medis_controller.dart';
import '../dialogs/consultation_dialogs.dart';
import '../widgets/attachments_section.dart';
import '../widgets/clinical_card.dart';

/// Medical consultation tab displaying incoming and outgoing doctor consultations.
class KonsultasiTab extends StatefulWidget {
  final RekamMedisController ctrl;

  const KonsultasiTab({super.key, required this.ctrl});

  @override
  State<KonsultasiTab> createState() => _KonsultasiTabState();
}

class _KonsultasiTabState extends State<KonsultasiTab> {
  final _activeSubTab = 0.obs;

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;

    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final active = _activeSubTab.value == 0;
                      return GestureDetector(
                        onTap: () => _activeSubTab.value = 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            border: Border(
                                bottom: BorderSide(
                                    color: active
                                        ? AppTheme.primary
                                        : Colors.transparent,
                                    width: 2)),
                          ),
                          child: Text(
                            'Konsul Keluar',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight:
                                  active ? FontWeight.bold : FontWeight.w600,
                              color: active
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  Expanded(
                    child: Obx(() {
                      final active = _activeSubTab.value == 1;
                      return GestureDetector(
                        onTap: () => _activeSubTab.value = 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            border: Border(
                                bottom: BorderSide(
                                    color: active
                                        ? AppTheme.primary
                                        : Colors.transparent,
                                    width: 2)),
                          ),
                          child: Text(
                            'Konsul Masuk',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight:
                                  active ? FontWeight.bold : FontWeight.w600,
                              color: active
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (ctrl.isLoadingConsult.value) {
                  return buildShimmerLoader();
                }

                final isOutgoing = _activeSubTab.value == 0;
                final list =
                    isOutgoing ? ctrl.outgoingConsults : ctrl.incomingConsults;

                if (list.isEmpty) {
                  return buildEmptyState(
                    isOutgoing
                        ? 'Belum ada permintaan konsul keluar'
                        : 'Belum ada konsul masuk',
                    icon: Icons.chat_bubble_outline_rounded,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final item = list[idx];
                    final tgl = item['tgl_perawatan'] ?? item['tgl_pesan'] ?? '-';
                    final jam = item['jam_pesan'] ?? '-';
                    final drPemberi = item['nm_dokter_pemberi'] ??
                        item['kd_dokter_pemberi'] ??
                        '-';
                    final drPeminta = item['nm_dokter_peminta'] ??
                        item['kd_dokter_peminta'] ??
                        '-';

                    final status = item['status']?.toString() ?? 'Belum Dijawab';
                    final isAnswered = status.toLowerCase() == 'sudah dijawab' ||
                        item['jawaban'] != null;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$tgl pukul $jam',
                                style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isAnswered
                                          ? AppTheme.success
                                          : AppTheme.warning)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAnswered ? 'Dijawab' : 'Pending',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isAnswered
                                        ? AppTheme.success
                                        : AppTheme.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isOutgoing
                                ? 'Dokter Penerima: $drPemberi'
                                : 'Dokter Pengirim: $drPeminta',
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          if (item['deskripsi_rujukan'] != null &&
                              item['deskripsi_rujukan']
                                  .toString()
                                  .isNotEmpty) ...[
                            Text(
                              'Permintaan / Konsultasi:',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary),
                            ),
                            Text(
                              stripAttachment(item['deskripsi_rujukan']),
                              style: GoogleFonts.outfit(
                                  fontSize: 12.5, color: AppTheme.textPrimary),
                            ),
                            buildAttachmentsSection(item['deskripsi_rujukan']),
                            const SizedBox(height: 8),
                          ],
                          if (isAnswered && item['jawaban'] != null) ...[
                            const Divider(color: AppTheme.divider, height: 16),
                            Text(
                              'Jawaban / Balasan:',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.success),
                            ),
                            Text(
                              stripAttachment(item['jawaban']),
                              style: GoogleFonts.outfit(
                                  fontSize: 12.5, color: AppTheme.textPrimary),
                            ),
                            buildAttachmentsSection(item['jawaban']),
                          ],
                          if (!isOutgoing && !isAnswered) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => showReplyConsultationDialog(
                                    context, ctrl, item),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8))),
                                child: Text('Jawab Konsultasi',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        Obx(() {
          if (_activeSubTab.value == 0) {
            return Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => showConsultationDialog(context, ctrl),
                backgroundColor: AppTheme.primary,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  'Minta Konsul',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
