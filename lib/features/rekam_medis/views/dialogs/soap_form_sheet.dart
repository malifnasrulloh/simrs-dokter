import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../controllers/rekam_medis_controller.dart';

/// Bottom sheet for adding or editing SOAP clinical entries.
void showSoapForm(BuildContext context, RekamMedisController ctrl,
    {Map<String, dynamic>? existingData}) {
  final isEdit = existingData != null;

  final draft = !isEdit ? ctrl.soapDraft : <String, String>{};

  final keluhanCtrl = TextEditingController(
      text: existingData?['keluhan_utama'] ?? draft['keluhan_utama'] ?? '');
  final pemeriksaanCtrl = TextEditingController(
      text: existingData?['pemeriksaan_fisik'] ??
          draft['pemeriksaan_fisik'] ??
          '');
  final penilaianCtrl = TextEditingController(
      text: existingData?['diagnosis'] ?? draft['diagnosis'] ?? '');
  final rtlCtrl =
      TextEditingController(text: existingData?['tata'] ?? draft['tata'] ?? '');
  final instruksiCtrl = TextEditingController(
      text: existingData?['instruksi'] ?? draft['instruksi'] ?? '');
  final evaluasiCtrl = TextEditingController(
      text: existingData?['evaluasi'] ?? draft['evaluasi'] ?? '');

  final suhuCtrl = TextEditingController(
      text: existingData?['suhu']?.toString() ?? draft['suhu'] ?? '');
  final tensiCtrl = TextEditingController(
      text: existingData?['td']?.toString() ?? draft['td'] ?? '');
  final nadiCtrl = TextEditingController(
      text: existingData?['nadi']?.toString() ?? draft['nadi'] ?? '');
  final respirasiCtrl = TextEditingController(
      text: existingData?['rr']?.toString() ?? draft['rr'] ?? '');
  final tinggiCtrl = TextEditingController(
      text: existingData?['tb']?.toString() ?? draft['tb'] ?? '');
  final beratCtrl = TextEditingController(
      text: existingData?['bb']?.toString() ?? draft['bb'] ?? '');
  final spo2Ctrl = TextEditingController(
      text: existingData?['spo']?.toString() ?? draft['spo'] ?? '');
  final gcsCtrl = TextEditingController(
      text: existingData?['gcs']?.toString() ?? draft['gcs'] ?? '');
  final kesadaranCtrl = TextEditingController(
      text: existingData?['kesadaran']?.toString() ??
          draft['kesadaran'] ??
          'Compos Mentis');

  if (!isEdit) {
    void save() {
      ctrl.saveSoapDraft({
        'keluhan_utama': keluhanCtrl.text,
        'pemeriksaan_fisik': pemeriksaanCtrl.text,
        'diagnosis': penilaianCtrl.text,
        'tata': rtlCtrl.text,
        'instruksi': instruksiCtrl.text,
        'evaluasi': evaluasiCtrl.text,
        'suhu': suhuCtrl.text,
        'td': tensiCtrl.text,
        'nadi': nadiCtrl.text,
        'rr': respirasiCtrl.text,
        'tb': tinggiCtrl.text,
        'bb': beratCtrl.text,
        'spo': spo2Ctrl.text,
        'gcs': gcsCtrl.text,
        'kesadaran': kesadaranCtrl.text,
      });
    }

    keluhanCtrl.addListener(save);
    pemeriksaanCtrl.addListener(save);
    penilaianCtrl.addListener(save);
    rtlCtrl.addListener(save);
    instruksiCtrl.addListener(save);
    evaluasiCtrl.addListener(save);
    suhuCtrl.addListener(save);
    tensiCtrl.addListener(save);
    nadiCtrl.addListener(save);
    respirasiCtrl.addListener(save);
    tinggiCtrl.addListener(save);
    beratCtrl.addListener(save);
    spo2Ctrl.addListener(save);
    gcsCtrl.addListener(save);
    kesadaranCtrl.addListener(save);
  }

  Get.bottomSheet(
    Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: Get.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.bgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: AppTheme.divider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit
                        ? 'Ubah Pemeriksaan SOAP'
                        : 'Tambah Pemeriksaan SOAP',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textSecondary),
                    tooltip: 'Tutup',
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      if (!isEdit && ctrl.soapDraft.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.3),
                                width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFD97706), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Melanjutkan draft SOAP lokal yang belum tersimpan',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    color: const Color(0xFF92400E),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  ctrl.clearSoapDraft();
                                  keluhanCtrl.clear();
                                  pemeriksaanCtrl.clear();
                                  penilaianCtrl.clear();
                                  rtlCtrl.clear();
                                  instruksiCtrl.clear();
                                  evaluasiCtrl.clear();
                                  suhuCtrl.clear();
                                  tensiCtrl.clear();
                                  nadiCtrl.clear();
                                  respirasiCtrl.clear();
                                  tinggiCtrl.clear();
                                  beratCtrl.clear();
                                  spo2Ctrl.clear();
                                  gcsCtrl.clear();
                                  kesadaranCtrl.text = 'Compos Mentis';
                                },
                                child: Text(
                                  'Hapus',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFFB45309),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    Text('Tanda Vital & Fisik',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _formField('Suhu (°C)', suhuCtrl,
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _formField('Tensi (mmHg)', tensiCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _formField('Nadi (bpm)', nadiCtrl,
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _formField('Respirasi (x/m)', respirasiCtrl,
                                keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _formField('Tinggi (cm)', tinggiCtrl,
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _formField('Berat (kg)', beratCtrl,
                                keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _formField('SpO2 (%)', spo2Ctrl,
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _formField('GCS', gcsCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _formField('Kesadaran', kesadaranCtrl),
                    const SizedBox(height: 20),
                    const Divider(color: AppTheme.divider),
                    const SizedBox(height: 16),
                    Text('Catatan SOAP',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary)),
                    const SizedBox(height: 12),
                    _formField('S (Subjective) - Keluhan Utama', keluhanCtrl,
                        maxLines: 3),
                    const SizedBox(height: 12),
                    _formField(
                        'O (Objective) - Pemeriksaan Fisik', pemeriksaanCtrl,
                        maxLines: 3),
                    const SizedBox(height: 12),
                    _formField(
                        'A (Assessment) - Diagnosis/Penilaian', penilaianCtrl,
                        maxLines: 3),
                    const SizedBox(height: 12),
                    _formField('P (Plan) - Tata Laksana / RTL', rtlCtrl,
                        maxLines: 3),
                    const SizedBox(height: 12),
                    _formField('Instruksi', instruksiCtrl, maxLines: 2),
                    const SizedBox(height: 12),
                    _formField('Evaluasi', evaluasiCtrl, maxLines: 2),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final data = {
                            'keluhan': keluhanCtrl.text,
                            'pemeriksaan': pemeriksaanCtrl.text,
                            'penilaian': penilaianCtrl.text,
                            'rtl': rtlCtrl.text,
                            'instruksi': instruksiCtrl.text,
                            'evaluasi': evaluasiCtrl.text,
                            'suhu_tubuh': suhuCtrl.text,
                            'tensi': tensiCtrl.text,
                            'nadi': nadiCtrl.text,
                            'respirasi': respirasiCtrl.text,
                            'tinggi': tinggiCtrl.text,
                            'berat': beratCtrl.text,
                            'spo2': spo2Ctrl.text,
                            'gcs': gcsCtrl.text,
                            'kesadaran': kesadaranCtrl.text,
                          };

                          final success = await ctrl.saveSoap(
                            data: data,
                            isEdit: isEdit,
                            tglPerawatan: existingData?['tanggal'],
                            jamRawat: existingData?['jam'],
                          );

                          if (success) {
                            Get.back();
                            Get.snackbar(
                                'Sukses',
                                isEdit
                                    ? 'SOAP berhasil diperbarui'
                                    : 'SOAP berhasil disimpan',
                                backgroundColor: Colors.white,
                                colorText: AppTheme.primary);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isEdit ? 'Perbarui Catatan' : 'Simpan Catatan',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

/// Confirmation dialog before deleting a SOAP entry.
void confirmDeleteSoap(
    BuildContext context, RekamMedisController ctrl, String tgl, String jam) {
  Get.dialog(
    AlertDialog(
      title: Text('Hapus SOAP',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: Text('Apakah Anda yakin ingin menghapus data SOAP ini?',
          style: GoogleFonts.outfit()),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Batal',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final success = await ctrl.deleteSoap(tgl, jam);
            if (success) {
              Get.snackbar('Sukses', 'Data SOAP berhasil dihapus',
                  backgroundColor: Colors.white, colorText: AppTheme.primary);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white)),
        ),
      ],
    ),
  );
}

Widget _formField(String label, TextEditingController controller,
    {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(
            fontSize: 13,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    ],
  );
}
