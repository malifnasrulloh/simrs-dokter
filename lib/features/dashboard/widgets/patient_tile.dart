import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/google_fonts.dart';

/// Shared patient card used by the patient workspace and the standalone
/// patient list (notification deep-links). Tapping opens rekam medis for
/// the given rawat type.
class PatientTile extends StatelessWidget {
  final Map<String, dynamic> pasien;
  final String type;
  final Color typeColor;

  const PatientTile({
    super.key,
    required this.pasien,
    required this.type,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    final penjamin = pasien['png_jawab']?.toString() ?? 'Umum';
    final isBpjs = penjamin.toUpperCase().contains('BPJS');
    final room =
        pasien['kamar'] ?? pasien['nm_ruang'] ?? pasien['nm_poli'] ?? '-';

    String dokterName = '-';
    if (type == 'RANAP') {
      final dpjpList = pasien['dpjp'] as List?;
      if (dpjpList != null && dpjpList.isNotEmpty) {
        dokterName = dpjpList[0]['nm_dokter'] ?? '-';
      }
    } else {
      dokterName = pasien['nm_dokter'] ?? '-';
    }

    final jk = pasien['jk']?.toString() ?? '-';
    final isMale = jk.toUpperCase() == 'L' ||
        jk.toUpperCase() == 'PRIA' ||
        jk.toUpperCase() == 'LAKI-LAKI';
    final genderText = isMale ? 'L' : 'P';
    final age = pasien['umur'] ?? pasien['usia'] ?? '-';
    final date = pasien['tgl_masuk'] ?? pasien['tgl_registrasi'] ?? '-';

    final patientName = pasien['nm_pasien'] ?? 'Pasien';
    final roomOrPoli = pasien['kamar'] ?? pasien['nm_poli'] ?? '-';

    return Semantics(
      label: 'Pasien $patientName, No RM ${pasien['no_rkm_medis'] ?? '-'}, $roomOrPoli, penjamin ${isBpjs ? 'BPJS' : 'Umum'}',
      button: true,
      child: GestureDetector(
        onTap: () =>
            Get.toNamed('/rekam-medis', arguments: {...pasien, '_type': type}),
        child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: typeColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pasien['nm_pasien'] ?? '-',
                                style: GoogleFonts.outfit(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isBpjs
                                    ? const Color(0xFFD1FAE5)
                                    : AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isBpjs
                                      ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.3)
                                      : AppTheme.divider,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isBpjs ? 'BPJS' : 'UMUM',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isBpjs
                                      ? const Color(0xFF047857)
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              pasien['no_rm'] ?? pasien['no_rkm_medis'] ?? '-',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$genderText • $age',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700),
                            ),
                            if (type == 'RANAP' && pasien['lama'] != null) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      color:
                                          Colors.orange.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  '${pasien['lama']} Hari',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.bed_outlined,
                                size: 13, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                room,
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              date,
                              style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 13, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'DPJP: $dokterName',
                                style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    ),
    ),
    );
  }
}
