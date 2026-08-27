import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../controllers/rekam_medis_controller.dart';
import '../dialogs/diagnosa_dialogs.dart';
import '../dialogs/prescription_sheet.dart';
import '../widgets/clinical_card.dart';

/// Medication tab showing historical dispensed medicines and pending electronic prescriptions.
class ObatTab extends StatelessWidget {
  final RekamMedisController ctrl;

  const ObatTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 2),
            );
          }
          final listDispensed = ctrl.obat;
          final listPending = ctrl.resepList;

          if (listDispensed.isEmpty && listPending.isEmpty) {
            return buildEmptyState('Belum ada data obat atau resep',
                icon: Icons.medication_outlined);
          }

          final Map<String, List<Map<String, dynamic>>> groups = {};

          // Create a lookup map of code/name -> no_resep from listPending
          final Map<String, String> obatToResepMap = {};
          for (final r in listPending) {
            final String? noResepVal = r['no_resep']?.toString();
            final String? kodeBrngVal = r['kode_brng']?.toString();
            final String? namaBrngVal = r['nama_brng']?.toString();
            if (noResepVal != null) {
              if (kodeBrngVal != null) {
                obatToResepMap[kodeBrngVal] = noResepVal;
              }
              if (namaBrngVal != null) {
                obatToResepMap[namaBrngVal] = noResepVal;
              }
            }
          }

          // Add historical (dispensed) medications
          for (final o in listDispensed) {
            final tgl = o['tgl_perawatan']?.toString() ?? '-';
            final jam = o['jam']?.toString() ?? '-';
            final kodeBrng = o['kode_brng']?.toString() ?? '';
            final namaObat =
                o['nama_obat']?.toString() ?? o['nama_brng']?.toString() ?? '';
            final noResep =
                obatToResepMap[kodeBrng] ?? obatToResepMap[namaObat] ?? 'None';
            final key = 'Dispensed|$noResep|$tgl|$jam';
            if (!groups.containsKey(key)) {
              groups[key] = [];
            }
            groups[key]!.add(o);
          }

          // Add pending electronic prescriptions
          for (final r in listPending) {
            final isAlreadyDispensed = listDispensed.any((o) =>
                (o['kode_brng'] != null && o['kode_brng'] == r['kode_brng']) ||
                o['nama_obat'] == r['nama_brng']);

            if (isAlreadyDispensed) {
              continue;
            }

            final tglPerawatan = r['tgl_perawatan']?.toString() ?? '';
            final isDispensed =
                tglPerawatan.isNotEmpty && tglPerawatan != '0000-00-00';

            final tgl = r['tgl_perawatan']?.toString() ?? '-';
            final jam = r['jam']?.toString() ?? '-';
            final noResep = r['no_resep'].toString();

            if (isDispensed) {
              final key = 'Dispensed|$noResep|$tgl|$jam';
              if (!groups.containsKey(key)) {
                groups[key] = [];
              }
              groups[key]!.add({
                'nama_obat': r['nama_brng'],
                'jumlah': r['jml'],
                'satuan': r['satuan'],
                'aturan': r['aturan_pakai'],
                'tgl_perawatan': tgl,
                'jam': jam,
                'no_resep': noResep,
              });
            } else {
              final tglResep = r['tgl_peresepan']?.toString() ?? '-';
              final jamResep = r['jam_peresepan']?.toString() ?? '-';
              final key = 'Pending|$noResep|$tglResep|$jamResep';
              if (!groups.containsKey(key)) {
                groups[key] = [];
              }
              groups[key]!.add({
                'nama_obat': r['nama_brng'],
                'jumlah': r['jml'],
                'satuan': r['satuan'],
                'aturan': r['aturan_pakai'],
                'tgl_perawatan': tglResep,
                'jam': jamResep,
                'no_resep': noResep,
              });
            }
          }

          final sortedKeys = groups.keys.toList()
            ..sort((a, b) {
              final partsA = a.split('|');
              final partsB = b.split('|');
              final tglA = partsA.length > 2 ? partsA[2] : '';
              final tglB = partsB.length > 2 ? partsB[2] : '';
              final jamA = partsA.length > 3 ? partsA[3] : '';
              final jamB = partsB.length > 3 ? partsB[3] : '';
              return '$tglB|$jamB'.compareTo('$tglA|$jamA');
            });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: sortedKeys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final key = sortedKeys[index];
              final parts = key.split('|');
              final isPending = parts[0] == 'Pending';
              final noResep = parts[1] != 'None' ? parts[1] : null;
              final tgl = parts[2];
              final jam = parts[3];
              final items = groups[key]!;
              final displayTime = jam == '-' ? '' : ' pukul $jam';

              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isPending
                        ? AppTheme.warning.withValues(alpha: 0.4)
                        : AppTheme.divider,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppTheme.warning.withValues(alpha: 0.08)
                            : AppTheme.bgSurface,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(17)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPending
                                    ? Icons.pending_actions_rounded
                                    : Icons.receipt_long_rounded,
                                color: isPending
                                    ? AppTheme.warning
                                    : AppTheme.success,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPending
                                    ? (noResep != null
                                        ? 'No Resep: $noResep\nStatus: Draft/Belum Diproses'
                                        : 'Resep Dokter\nStatus: Draft/Belum Diproses')
                                    : (noResep != null
                                        ? 'No Resep: $noResep\nTanggal Resep: $tgl$displayTime'
                                        : 'Tanggal Resep: $tgl$displayTime'),
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (ctrl.writeEnabled && isPending && noResep != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.danger, size: 18),
                              tooltip: 'Hapus resep',
                              onPressed: () =>
                                  confirmDeleteResep(context, ctrl, noResep),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, thickness: 0.5, color: AppTheme.divider),
                      itemBuilder: (context, itemIdx) {
                        final o = items[itemIdx];
                        final signa = o['aturan'] ?? '';
                        final namaObat = o['nama_obat'] ?? '-';
                        final qty = o['jumlah'] ?? '';
                        final unit = o['satuan'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isPending
                                          ? AppTheme.warning
                                          : AppTheme.success)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.medication_rounded,
                                  color: isPending
                                      ? AppTheme.warning
                                      : AppTheme.success,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      namaObat,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Jumlah: $qty $unit • Aturan: $signa',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildPrescriptionTiming(signa),
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
        }),
        if (ctrl.writeEnabled)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () => showPrescriptionSheet(context, ctrl),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: Text(
                'Buat Resep',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrescriptionTiming(String signa) {
    final s = signa.toLowerCase();
    bool morning = false;
    bool afternoon = false;
    bool night = false;

    if (s.contains('3x') ||
        s.contains('tiga kali') ||
        (s.contains('pagi') && s.contains('siang') && s.contains('malam'))) {
      morning = true;
      afternoon = true;
      night = true;
    } else if (s.contains('2x') ||
        s.contains('dua kali') ||
        (s.contains('pagi') && s.contains('malam'))) {
      morning = true;
      night = true;
    } else if (s.contains('malam') || s.contains('sebelum tidur')) {
      night = true;
    } else {
      morning = true;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (morning)
          _timingIndicator('Pagi', Icons.light_mode_rounded, Colors.amber),
        if (afternoon) ...[
          const SizedBox(width: 4),
          _timingIndicator('Siang', Icons.wb_twilight_rounded, Colors.orange),
        ],
        if (night) ...[
          const SizedBox(width: 4),
          _timingIndicator(
              'Malam', Icons.dark_mode_rounded, Colors.indigoAccent),
        ],
      ],
    );
  }

  Widget _timingIndicator(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 8.5, color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
