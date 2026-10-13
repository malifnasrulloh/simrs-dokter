import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../controllers/rekam_medis_controller.dart';

class VerifikasiSoapieSheet extends StatefulWidget {
  final Map<String, dynamic> soapData;
  final String jenis; // 'ranap' | 'ralan'

  const VerifikasiSoapieSheet({
    super.key,
    required this.soapData,
    required this.jenis,
  });

  static void show(
      BuildContext context, Map<String, dynamic> soapData, String jenis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VerifikasiSoapieSheet(soapData: soapData, jenis: jenis),
    );
  }

  @override
  State<VerifikasiSoapieSheet> createState() => _VerifikasiSoapieSheetState();
}

class _VerifikasiSoapieSheetState extends State<VerifikasiSoapieSheet> {
  final _catatanController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RekamMedisController>();
    final pembuat = widget.soapData['petugas'] ?? widget.soapData['nama'] ?? '-';
    final jabatan = widget.soapData['jabatan'] ?? '';
    final tgl = widget.soapData['tanggal'] ?? widget.soapData['tgl_perawatan'] ?? '-';
    final jam = widget.soapData['jam'] ?? widget.soapData['jam_rawat'] ?? '-';
    final tglJam = '$tgl pukul $jam';

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: AppTheme.success, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi SOAPIE / CPPT',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Validasi asuhan medis oleh DPJP',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person_pin_rounded,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        jabatan.isNotEmpty && jabatan != '-'
                            ? '$pembuat ($jabatan)'
                            : pembuat,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Waktu Asuhan: $tglJam',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Catatan / Instruksi Tambahan DPJP (Opsional):',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _catatanController,
            maxLines: 3,
            style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Contoh: Terapi lanjutkan, evaluasi TTV per 2 jam...',
              hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final nav = Navigator.of(context);
                          setState(() => _isLoading = true);
                          final ok = await controller.verifikasiSoapie(
                            jenis: widget.jenis,
                            tglPerawatan: tgl,
                            jamRawat: jam,
                            catatan: _catatanController.text,
                          );
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                          if (ok) {
                            nav.pop(true);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Verifikasi DPJP',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
