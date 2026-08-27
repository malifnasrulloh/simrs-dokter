import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../controllers/rekam_medis_controller.dart';

/// Bottom sheet for creating and sending electronic prescriptions to the pharmacy.
void showPrescriptionSheet(BuildContext context, RekamMedisController ctrl) {
  final searchCtrl = TextEditingController();

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
                    'Resep Elektronik (E-Prescribing)',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Cari nama obat / barang medis...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (val) => ctrl.searchObat(val),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      if (ctrl.isLoadingObat.value) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (ctrl.searchObatResults.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: ctrl.searchObatResults.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, thickness: 0.5),
                          itemBuilder: (context, idx) {
                            final item = ctrl.searchObatResults[idx];
                            final name = item['nama_brng'] ?? '-';
                            final stock = double.tryParse(
                                    item['total_stok']?.toString() ?? '0') ??
                                0.0;
                            final isLowStock = stock <= 0;

                            return ListTile(
                              dense: true,
                              title: Text(name,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Stok: ${stock.toStringAsFixed(0)} ${item['satuan'] ?? ''}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: isLowStock
                                      ? AppTheme.danger
                                      : AppTheme.textSecondary,
                                  fontWeight: isLowStock
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isLowStock
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: AppTheme.danger
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text('Habis',
                                          style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              color: AppTheme.danger,
                                              fontWeight: FontWeight.bold)),
                                    )
                                  : Icon(Icons.add_circle_outline_rounded,
                                      color: AppTheme.primary, size: 20),
                              onTap: isLowStock
                                  ? () {
                                      Get.snackbar(
                                          'Peringatan', 'Stok obat habis!',
                                          backgroundColor: Colors.white,
                                          colorText: AppTheme.danger);
                                    }
                                  : () {
                                      ctrl.addToPrescription(item);
                                      searchCtrl.clear();
                                      ctrl.searchObatResults.clear();
                                    },
                            );
                          },
                        ),
                      );
                    }),
                    Obx(() {
                      if (ctrl.prescriptionDraft.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                  'Melanjutkan resep draft (${ctrl.prescriptionDraft.length} obat)',
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
                                onPressed: () => ctrl.clearPrescriptionDraft(),
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
                    Text(
                      'Daftar Obat Resep',
                      style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (ctrl.prescriptionDraft.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.shopping_basket_outlined,
                                    size: 40,
                                    color: AppTheme.textMuted
                                        .withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                Text('Keranjang resep kosong',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ctrl.prescriptionDraft.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final item = ctrl.prescriptionDraft[idx];
                          final code = item['kode_brng'];
                          final qtyCtrl = TextEditingController(
                              text: item['jml']?.toString() ?? '1');
                          final sigCtrl = TextEditingController(
                              text: item['aturan_pakai'] ?? '3x1 tablet');

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['nama_brng'] ?? '-',
                                        style: GoogleFonts.outfit(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppTheme.danger,
                                          size: 18),
                                      tooltip: 'Hapus obat',
                                      onPressed: () =>
                                          ctrl.removeFromPrescription(code),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Jumlah',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  color:
                                                      AppTheme.textSecondary)),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: qtyCtrl,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8)),
                                            onChanged: (val) {
                                              final q = int.tryParse(val) ?? 1;
                                              item['jml'] = q;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Aturan Pakai / Signa',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  color:
                                                      AppTheme.textSecondary)),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: sigCtrl,
                                            decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8)),
                                            onChanged: (val) {
                                              item['aturan_pakai'] = val;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 24),
                    Obx(() {
                      final hasItems = ctrl.prescriptionDraft.isNotEmpty;
                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: hasItems
                              ? () async {
                                  final success =
                                      await ctrl.submitPrescription();
                                  if (success) {
                                    Get.back();
                                    Get.snackbar(
                                        'Sukses', 'Resep berhasil dikirim',
                                        backgroundColor: Colors.white,
                                        colorText: AppTheme.primary);
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Kirim Resep Ke Farmasi',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5),
                          ),
                        ),
                      );
                    }),
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
