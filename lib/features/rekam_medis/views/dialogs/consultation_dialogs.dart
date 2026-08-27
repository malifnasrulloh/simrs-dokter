import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../controllers/rekam_medis_controller.dart';

/// Dialog to create and send a consultation/referral request to another doctor.
void showConsultationDialog(BuildContext context, RekamMedisController ctrl) {
  final selectedDokter = Rxn<Map<String, dynamic>>();
  final rujukanCtrl = TextEditingController();
  final diagnosaCtrl = TextEditingController();
  final attachmentCtrl = TextEditingController();
  final dokterSearchCtrl = TextEditingController();
  final filteredDokterList = <Map<String, dynamic>>[].obs;
  // Konsultasi types must match the konsultasi_medik.jenis_permintaan ENUM
  final jenisPermintaan = RxnString('Konsultasi');
  const jenisOptions = [
    'Konsultasi',
    'Evaluasi',
    'Rawat Bersama',
    'Alih Rawat',
    'Pre/Post Operasi'
  ];

  filteredDokterList.value = ctrl.dokterList;

  Get.dialog(
    AlertDialog(
      title: Text('Kirim Permintaan Konsultasi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      content: SizedBox(
        width: Get.width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Dokter Tujuan',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: dokterSearchCtrl,
                decoration: const InputDecoration(
                    hintText: 'Cari nama dokter...',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                onChanged: (val) {
                  if (val.trim().isEmpty) {
                    filteredDokterList.value = ctrl.dokterList;
                  } else {
                    filteredDokterList.value = ctrl.dokterList
                        .where((d) => (d['nm_dokter'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(val.toLowerCase()))
                        .toList();
                  }
                },
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.divider),
                    borderRadius: BorderRadius.circular(8)),
                child: Obx(() {
                  if (filteredDokterList.isEmpty) {
                    return Center(
                        child: Text('Dokter tidak ditemukan',
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: AppTheme.textMuted)));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredDokterList.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (context, idx) {
                      final dr = filteredDokterList[idx];
                      final code = dr['kd_dokter'] ?? '';
                      final name = dr['nm_dokter'] ?? '';
                      return Obx(() {
                        final isSelected =
                            selectedDokter.value?['kd_dokter'] == code;
                        return ListTile(
                          dense: true,
                          title: Text(name,
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          onTap: () {
                            selectedDokter.value = dr;
                            dokterSearchCtrl.text = name;
                          },
                        );
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text('Jenis Konsultasi',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: jenisPermintaan.value,
                  isDense: true,
                  decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                  items: jenisOptions
                      .map((j) => DropdownMenuItem(
                          value: j,
                          child:
                              Text(j, style: GoogleFonts.outfit(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => jenisPermintaan.value = v,
                ),
              ),
              const SizedBox(height: 16),
              Text('Diagnosa Kerja',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: diagnosaCtrl,
                decoration: const InputDecoration(
                    hintText: 'Tuliskan diagnosa kerja...',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
              ),
              const SizedBox(height: 16),
              Text('Isi Permintaan / Rujukan / Keterangan',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: rujukanCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                    hintText: 'Tuliskan deskripsi rujukan/pertanyaan...',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
              ),
              const SizedBox(height: 16),
              Text('URL Lampiran (Opsional, cth: PACS, Lab PDF)',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: attachmentCtrl,
                decoration: const InputDecoration(
                    hintText: 'http://pacs.link/...',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () async {
            if (selectedDokter.value == null) {
              Get.snackbar(
                  'Error', 'Silakan pilih dokter tujuan terlebih dahulu',
                  backgroundColor: Colors.white, colorText: AppTheme.danger);
              return;
            }
            if (rujukanCtrl.text.trim().isEmpty) {
              Get.snackbar('Error', 'Isi rujukan tidak boleh kosong',
                  backgroundColor: Colors.white, colorText: AppTheme.danger);
              return;
            }
            Get.back();

            String finalUraian = rujukanCtrl.text;
            if (attachmentCtrl.text.trim().isNotEmpty) {
              finalUraian += '\n[Attachment: ${attachmentCtrl.text.trim()}]';
            }

            final success = await ctrl.sendConsultation(
              targetDokter: selectedDokter.value!['kd_dokter'],
              jenis: jenisPermintaan.value ?? 'Konsultasi',
              diagnosa: diagnosaCtrl.text,
              uraian: finalUraian,
            );
            if (success) {
              Get.snackbar('Sukses', 'Permintaan konsultasi berhasil dikirim',
                  backgroundColor: Colors.white, colorText: AppTheme.primary);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: Text('Kirim', style: GoogleFonts.outfit(color: Colors.white)),
        ),
      ],
    ),
  );
}

/// Dialog to reply/respond to an incoming consultation request.
void showReplyConsultationDialog(BuildContext context,
    RekamMedisController ctrl, Map<String, dynamic> item) {
  final jawabanCtrl = TextEditingController();
  final diagnosaCtrl = TextEditingController();
  final attachmentCtrl = TextEditingController();

  Get.dialog(
    AlertDialog(
      title: Text('Jawab Konsultasi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Dari: ${item['nm_dokter_peminta'] ?? item['kd_dokter_peminta'] ?? '-'}',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text(item['deskripsi_rujukan'] ?? '-',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Text('Diagnosa Kerja / Hasil Pemeriksaan',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: diagnosaCtrl,
              decoration: const InputDecoration(
                  hintText: 'Tuliskan diagnosa kerja/hasil...',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            ),
            const SizedBox(height: 16),
            Text('Jawaban / Keterangan',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: jawabanCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: 'Tuliskan jawaban...',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            ),
            const SizedBox(height: 16),
            Text('URL Lampiran (Opsional, cth: PACS, Lab PDF)',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: attachmentCtrl,
              decoration: const InputDecoration(
                  hintText: 'http://pacs.link/...',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () async {
            if (jawabanCtrl.text.trim().isEmpty) {
              Get.snackbar('Error', 'Jawaban tidak boleh kosong',
                  backgroundColor: Colors.white, colorText: AppTheme.danger);
              return;
            }
            Get.back();

            String finalJawaban = jawabanCtrl.text;
            if (attachmentCtrl.text.trim().isNotEmpty) {
              finalJawaban += '\n[Attachment: ${attachmentCtrl.text.trim()}]';
            }

            final success = await ctrl.replyConsultation(
              noPermintaan: item['no_permintaan']?.toString() ?? '',
              diagnosa: diagnosaCtrl.text,
              uraian: finalJawaban,
            );
            if (success) {
              Get.snackbar('Sukses', 'Konsultasi berhasil dijawab',
                  backgroundColor: Colors.white, colorText: AppTheme.primary);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: Text('Kirim', style: GoogleFonts.outfit(color: Colors.white)),
        ),
      ],
    ),
  );
}
