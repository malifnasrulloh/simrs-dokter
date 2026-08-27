import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../controllers/rekam_medis_controller.dart';

/// Dialog to set priority and status when adding an ICD-10 diagnosis.
void showAddDiagnosaDialog(
    BuildContext context, RekamMedisController ctrl, String code, String name) {
  int priority = 1;
  String status = 'Baru';

  Get.dialog(StatefulBuilder(builder: (context, setState) {
    return AlertDialog(
      title: Text('Tambah Diagnosa',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$code - $name',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Text('Prioritas',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary)),
          RadioGroup<int>(
            groupValue: priority,
            onChanged: (v) => setState(() => priority = v!),
            child: Row(
              children: [
                Radio<int>(value: 1),
                Text('1 (Utama)', style: GoogleFonts.outfit(fontSize: 12)),
                const SizedBox(width: 12),
                Radio<int>(value: 2),
                Text('2+ (Sekunder)', style: GoogleFonts.outfit(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Status Kasus',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary)),
          RadioGroup<String>(
            groupValue: status,
            onChanged: (v) => setState(() => status = v!),
            child: Row(
              children: [
                Radio<String>(value: 'Baru'),
                Text('Baru', style: GoogleFonts.outfit(fontSize: 12)),
                const SizedBox(width: 12),
                Radio<String>(value: 'Lama'),
                Text('Lama', style: GoogleFonts.outfit(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final success = await ctrl.addDiagnosa(
                kdPenyakit: code, prioritas: priority, statusPenyakit: status);
            if (success) {
              Get.snackbar('Sukses', 'Diagnosa berhasil ditambahkan',
                  backgroundColor: Colors.white, colorText: AppTheme.primary);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: Text('Simpan', style: GoogleFonts.outfit(color: Colors.white)),
        ),
      ],
    );
  }));
}

/// Dialog to set priority when adding an ICD-9 procedure.
void showAddProsedurDialog(
    BuildContext context, RekamMedisController ctrl, String code, String name) {
  int priority = 1;

  Get.dialog(StatefulBuilder(builder: (context, setState) {
    return AlertDialog(
      title: Text('Tambah Prosedur',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$code - $name',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Text('Prioritas',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary)),
          RadioGroup<int>(
            groupValue: priority,
            onChanged: (v) => setState(() => priority = v!),
            child: Row(
              children: [
                Radio<int>(value: 1),
                Text('1 (Utama)', style: GoogleFonts.outfit(fontSize: 12)),
                const SizedBox(width: 12),
                Radio<int>(value: 2),
                Text('2+ (Sekunder)', style: GoogleFonts.outfit(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final success =
                await ctrl.addProsedur(kode: code, prioritas: priority);
            if (success) {
              Get.snackbar('Sukses', 'Prosedur berhasil ditambahkan',
                  backgroundColor: Colors.white, colorText: AppTheme.primary);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: Text('Simpan', style: GoogleFonts.outfit(color: Colors.white)),
        ),
      ],
    );
  }));
}

/// Confirmation dialog before deleting a prescription.
void confirmDeleteResep(
    BuildContext context, RekamMedisController ctrl, String noResep) {
  Get.dialog(
    AlertDialog(
      title: Text('Hapus Resep',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: Text('Apakah Anda yakin ingin menghapus resep $noResep ini?',
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
            final success = await ctrl.deletePrescription(noResep);
            if (success) {
              Get.snackbar('Sukses', 'Resep berhasil dihapus',
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
