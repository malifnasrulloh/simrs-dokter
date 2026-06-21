import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/rekam_medis_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class RekamMedisView extends StatelessWidget {
  const RekamMedisView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(RekamMedisController());

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Obx(() {
          final pasien = ctrl.pasienData.value ??
              Get.arguments as Map<String, dynamic>? ??
              {};
          return Column(
            children: [
              _buildAppBar(pasien),
              _buildPatientCard(pasien, ctrl),
              _buildTabBar(ctrl),
              Expanded(
                child: ctrl.pasienData.value == null
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.accent))
                    : _buildTabContent(context, ctrl),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAppBar(Map<String, dynamic> pasien) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary, size: 15),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Rekam Medis Pasien',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(double val) {
    if (val == 0) return 'Rp0';
    final isNegative = val < 0;
    final absVal = val.abs().toInt();
    final str = absVal.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    final reversed = buffer.toString().split('').reversed.join('');
    return (isNegative ? '-Rp' : 'Rp') + reversed;
  }

  Widget _billingItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
                fontSize: 9.5,
                color: Colors.white70,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _billingItemSelisih(String label, double selisih) {
    final isNegative = selisih < 0;
    final color =
        isNegative ? const Color(0xFFFFD2D2) : const Color(0xFFD2FFD2);
    final valueStr = _formatRupiah(selisih);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
                fontSize: 9.5,
                color: Colors.white70,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            valueStr,
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(
      Map<String, dynamic> pasien, RekamMedisController ctrl) {
    final penjamin = pasien['png_jawab']?.toString() ?? 'Umum';
    final isBpjs = penjamin.toUpperCase().contains('BPJS');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (pasien['nm_pasien'] ?? 'P')[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pasien['nm_pasien'] ?? '-',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          pasien['no_rm'] ?? pasien['no_rkm_medis'] ?? '-',
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            isBpjs ? 'BPJS' : 'UMUM',
                            style: GoogleFonts.outfit(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Obx(() {
                      final alergi = ctrl.alergiInfo;
                      if (alergi.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD2D2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: const Color(0xFFFF8B8B), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_rounded,
                                color: Color(0xFFD32F2F), size: 10),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'ALERGI: $alergi',
                                style: GoogleFonts.outfit(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFD32F2F),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (ctrl.tipeRawat == 'RANAP') ...[
                      const SizedBox(height: 3),
                      Obx(() {
                        if (ctrl.isLoadingDpjp.value) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 1),
                            ),
                          );
                        }
                        final authCtrl = Get.find<AuthController>();
                        final myNip = authCtrl.user.value?['nip'];
                        final isAlreadyDpjp =
                            ctrl.dpjpList.any((d) => d['kd_dokter']?.toString() == myNip);
                        final names = ctrl.dpjpList
                            .map((d) => d['nm_dokter']?.toString() ?? '-')
                            .join(', ');

                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                'DPJP: ${names.isNotEmpty ? names : 'Belum ditentukan'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isAlreadyDpjp && myNip != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () async {
                                  final success = await ctrl.setAsDpjp();
                                  if (success) {
                                    Get.snackbar('Sukses',
                                        'Anda telah terdaftar sebagai DPJP pasien ini',
                                        backgroundColor: Colors.white,
                                        colorText: AppTheme.primary,
                                        snackPosition: SnackPosition.BOTTOM);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+ DPJP SAYA',
                                    style: GoogleFonts.outfit(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Obx(() => GestureDetector(
                onTap: () => ctrl.showDetails.toggle(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ctrl.showDetails.value
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              )),
            ],
          ),
          Obx(() {
            if (!ctrl.showDetails.value) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Divider(
                    color: Colors.white.withOpacity(0.2), height: 1, thickness: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _infoChip(
                        Icons.badge_rounded, 'No. Rawat', pasien['no_rawat'] ?? '-'),
                    const SizedBox(width: 12),
                    _infoChip(
                        Icons.bed_rounded,
                        'Kamar/Poli',
                        pasien['nm_ruang'] ??
                            pasien['nm_poli'] ??
                            pasien['kamar'] ??
                            '-'),
                  ],
                ),
                Obx(() {
                  if (ctrl.isLoadingBilling.value) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 1.5),
                        ),
                      ),
                    );
                  }
                  final total = ctrl.totalBilling.value;
                  final hasPerkiraan = ctrl.hasPerkiraan.value;
                  final perkiraan = ctrl.perkiraanBiaya.value;
                  final selisih = ctrl.selisihBiaya.value;

                  if (total == 0 && !hasPerkiraan) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Divider(
                          color: Colors.white.withOpacity(0.2),
                          height: 1,
                          thickness: 1),
                      const SizedBox(height: 10),
                      if (!isBpjs) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Billing',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              _formatRupiah(total),
                              style: GoogleFonts.robotoMono(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _billingItem('Total Billing', _formatRupiah(total)),
                            const SizedBox(width: 12),
                            if (hasPerkiraan) ...[
                              _billingItem(
                                  'Estimasi Tarif', _formatRupiah(perkiraan)),
                              const SizedBox(width: 12),
                              _billingItemSelisih('Selisih', selisih),
                            ] else ...[
                              _billingItem('Estimasi Tarif', '-'),
                              const SizedBox(width: 12),
                              _billingItem('Selisih', '-'),
                            ],
                          ],
                        ),
                      ],
                    ],
                  );
                }),
              ],
            );
          }),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(RekamMedisController ctrl) {
    final tabs = ['Medis', 'Diagnosa', 'Obat', 'Lab', 'Radiologi', 'Konsultasi'];
    if (ctrl.tipeRawat == 'RANAP') {
      tabs.add('SBAR');
    }
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return Obx(() {
            final active = ctrl.activeTab.value == i;
            return GestureDetector(
              onTap: () => ctrl.activeTab.value = i,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppTheme.primary : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? AppTheme.primaryLight.withOpacity(0.3)
                        : AppTheme.divider,
                    width: 1,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  tabs[i],
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, RekamMedisController ctrl) {
    return Obx(() {
      switch (ctrl.activeTab.value) {
        case 0:
          return _buildMedisTab(context, ctrl);
        case 1:
          return _buildDiagnosaTab(context, ctrl);
        case 2:
          return _buildObatTab(context, ctrl);
        case 3:
          return _buildLabTab(ctrl);
        case 4:
          return _buildRadiologiTab(ctrl);
        case 5:
          return _buildKonsultasiTab(context, ctrl);
        case 6:
          return _buildSbarTab(context, ctrl);
        default:
          return const SizedBox();
      }
    });
  }

  Widget _buildMedisTab(BuildContext context, RekamMedisController ctrl) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
        );
      }
      final list = ctrl.riwayatMedis;
      final sortedList = list.reversed.toList();
      return Column(
        children: [
          Obx(() {
            if (ctrl.offlineSoapQueue.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_rounded, color: AppTheme.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Koneksi Offline',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.warning,
                            ),
                          ),
                          Text(
                            '${ctrl.offlineSoapQueue.length} data SOAP tersimpan di antrean lokal.',
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warning,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => ctrl.syncOfflineSoap(),
                      child: Text(
                        'Sinkronkan',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Stack(
              children: [
                sortedList.isEmpty
                    ? _emptyState('Belum ada data medis')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: sortedList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final data = sortedList[index];
                          final uniqueId = '${data['tanggal']}_${data['jam']}_$index';
                          return _SoapTile(
                            key: GlobalObjectKey(uniqueId),
                            data: data,
                            initiallyExpanded: index == 0,
                          );
                        },
                      ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showSoapForm(context, ctrl),
                    backgroundColor: AppTheme.primary,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      'Tambah SOAP',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDiagnosaTab(BuildContext context, RekamMedisController ctrl) {
    final icd10SearchCtrl = TextEditingController();
    final icd9SearchCtrl = TextEditingController();

    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ──── DIAGNOSA (ICD-10) ────
          Text(
            'Diagnosa (ICD-10)',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: icd10SearchCtrl,
            decoration: const InputDecoration(
              hintText: 'Cari ICD-10 (Kode atau Deskripsi)...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (val) => ctrl.searchICD10(val),
          ),
          const SizedBox(height: 8),
          
          // Autocomplete results ICD-10
          Obx(() {
            if (ctrl.isLoadingICD.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              );
            }
            if (ctrl.searchICD10Results.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              maxHeight: 200,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: ctrl.searchICD10Results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                itemBuilder: (context, idx) {
                  final item = ctrl.searchICD10Results[idx];
                  final code = item['kd_penyakit']?.toString() ?? '';
                  final name = item['nm_penyakit']?.toString() ?? '';
                  return ListTile(
                    dense: true,
                    title: Text('$code - $name', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                    onTap: () {
                      ctrl.searchICD10Results.clear();
                      icd10SearchCtrl.clear();
                      _showAddDiagnosaDialog(context, ctrl, code, name);
                    },
                  );
                },
              ),
            );
          }),
          
          const SizedBox(height: 12),
          
          // Active diagnoses list
          Obx(() {
            if (ctrl.diagnosa.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text('Belum ada diagnosa aktif', style: GoogleFonts.outfit(color: AppTheme.textMuted))),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ctrl.diagnosa.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final d = ctrl.diagnosa[i];
                final code = d['kd_penyakit']?.toString() ?? '';
                final name = d['nm_penyakit'] ?? code;
                final priority = d['prioritas']?.toString() ?? '-';
                final status = d['status_penyakit']?.toString() ?? '-';
                
                return _listCard(
                  icon: Icons.medical_information_rounded,
                  iconColor: AppTheme.info,
                  title: name,
                  subtitle: 'Kode: $code • Prioritas: $priority • Status: $status',
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
                    onPressed: () => ctrl.deleteDiagnosa(code),
                  ),
                );
              },
            );
          }),
          
          const SizedBox(height: 24),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 16),
          
          // ──── PROSEDUR (ICD-9-CM) ────
          Text(
            'Prosedur (ICD-9-CM)',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: icd9SearchCtrl,
            decoration: const InputDecoration(
              hintText: 'Cari ICD-9 (Kode atau Deskripsi)...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (val) => ctrl.searchICD9(val),
          ),
          const SizedBox(height: 8),
          
          // Autocomplete results ICD-9
          Obx(() {
            if (ctrl.isLoadingICD.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              );
            }
            if (ctrl.searchICD9Results.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              maxHeight: 200,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: ctrl.searchICD9Results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                itemBuilder: (context, idx) {
                  final item = ctrl.searchICD9Results[idx];
                  final code = item['kode']?.toString() ?? '';
                  final name = item['deskripsi_panjang']?.toString() ?? item['deskripsi_pendek']?.toString() ?? '';
                  return ListTile(
                    dense: true,
                    title: Text('$code - $name', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                    onTap: () {
                      ctrl.searchICD9Results.clear();
                      icd9SearchCtrl.clear();
                      _showAddProsedurDialog(context, ctrl, code, name);
                    },
                  );
                },
              ),
            );
          }),
          
          const SizedBox(height: 12),
          
          // Active procedures list
          Obx(() {
            if (ctrl.prosedurList.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text('Belum ada prosedur aktif', style: GoogleFonts.outfit(color: AppTheme.textMuted))),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ctrl.prosedurList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = ctrl.prosedurList[i];
                final code = p['kode']?.toString() ?? '';
                final name = p['deskripsi_panjang']?.toString() ?? p['deskripsi_pendek']?.toString() ?? code;
                final priority = p['prioritas']?.toString() ?? '1';
                
                return _listCard(
                  icon: Icons.settings_accessibility_rounded,
                  iconColor: AppTheme.accentAlt,
                  title: name,
                  subtitle: 'Kode: $code • Prioritas: $priority',
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
                    onPressed: () => ctrl.deleteProsedur(code),
                  ),
                );
              },
            );
          }),
        ],
      );
    });
  }

  Widget _buildObatTab(BuildContext context, RekamMedisController ctrl) {
    return Stack(
      children: [
        Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
            );
          }
          final listDispensed = ctrl.obat;
          final listPending = ctrl.resepList;
          
          if (listDispensed.isEmpty && listPending.isEmpty) {
            return _emptyState('Belum ada data obat atau resep');
          }
          
          final Map<String, List<Map<String, dynamic>>> groups = {};
          
          // Add historical (dispensed) medications
          for (final o in listDispensed) {
            final tgl = o['tgl_perawatan']?.toString() ?? '-';
            final jam = o['jam']?.toString() ?? '-';
            final key = 'Dispensed|$tgl|$jam';
            if (!groups.containsKey(key)) {
              groups[key] = [];
            }
            groups[key]!.add(o);
          }

          // Add pending electronic prescriptions
          for (final r in listPending) {
            final tgl = r['tgl_perawatan']?.toString() ?? '-';
            final jam = r['jam']?.toString() ?? '-';
            final key = 'Pending|${r['no_resep']}|$tgl|$jam';
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
              'no_resep': r['no_resep'],
            });
          }

          final sortedKeys = groups.keys.toList()..sort((a, b) {
            final partsA = a.split('|');
            final partsB = b.split('|');
            final tglA = partsA.length > 2 ? partsA[partsA.length - 2] : '';
            final tglB = partsB.length > 2 ? partsB[partsB.length - 2] : '';
            final jamA = partsA.length > 1 ? partsA[partsA.length - 1] : '';
            final jamB = partsB.length > 1 ? partsB[partsB.length - 1] : '';
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
              final noResep = isPending ? parts[1] : null;
              final tgl = isPending ? parts[2] : parts[1];
              final jam = isPending ? parts[3] : parts[2];
              final items = groups[key]!;
              final displayTime = jam == '-' ? '' : ' pukul $jam';

              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isPending ? AppTheme.warning.withOpacity(0.4) : AppTheme.divider,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isPending ? AppTheme.warning.withOpacity(0.08) : AppTheme.bgSurface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPending ? Icons.pending_actions_rounded : Icons.receipt_long_rounded,
                                color: isPending ? AppTheme.warning : AppTheme.success,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPending ? 'Resep Dokter (Draft/Belum Diproses)' : 'Resep $tgl$displayTime',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (isPending && noResep != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
                              onPressed: () => _confirmDeleteResep(context, ctrl, noResep),
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
                      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: AppTheme.divider),
                      itemBuilder: (context, itemIdx) {
                        final o = items[itemIdx];
                        final signa = o['aturan'] ?? '';
                        final namaObat = o['nama_obat'] ?? '-';
                        final qty = o['jumlah'] ?? '';
                        final unit = o['satuan'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isPending ? AppTheme.warning : AppTheme.success).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.medication_rounded,
                                  color: isPending ? AppTheme.warning : AppTheme.success,
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
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showPrescriptionSheet(context, ctrl),
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
      morning = true; // default
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
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

  Widget _buildLabTab(RekamMedisController ctrl) {
    return Obx(() {
      if (ctrl.isLoadingLab.value) {
        return _buildShimmerLoader();
      }
      if (ctrl.laboratorium.isEmpty) {
        return _emptyState('Belum ada hasil laboratorium');
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
      itemCount: ctrl.laboratorium.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, groupIndex) {
        final group = ctrl.laboratorium[groupIndex];
        final groupName = group['group_name']?.toString() ?? 'Pemeriksaan Lab';
        final items = group['items'] as List? ?? [];

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.divider),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textPrimary.withOpacity(0.02),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
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

  Widget _buildRadiologiTab(RekamMedisController ctrl) {
    return Obx(() {
      if (ctrl.isLoadingRad.value) {
        return _buildShimmerLoader();
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
        // Section 1: Hasil Bacaan & Foto
        Row(
          children: [
            const Icon(Icons.description_rounded,
                color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Hasil & Foto Pemeriksaan',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (ctrl.radiologi.isEmpty)
          _emptyStateMini('Belum ada hasil & foto pemeriksaan')
        else
          ...ctrl.radiologi.map((r) => _buildRadiologiCard(r)),

        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: AppTheme.divider),
        const SizedBox(height: 24),

        // Section 2: DICOM PACS
        // Row(
        //   children: [
        //     const Icon(Icons.settings_system_daydream_rounded, color: AppTheme.accentAlt, size: 18),
        //     const SizedBox(width: 8),
        //     Text(
        //       'Integrasi PACS (Orthanc DICOM)',
        //       style: GoogleFonts.outfit(
        //         fontSize: 14,
        //         fontWeight: FontWeight.w800,
        //         color: AppTheme.textPrimary,
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 12),
        // Obx(() {
        //   if (ctrl.isLoadingDicom.value) {
        //     return const Padding(
        //       padding: EdgeInsets.symmetric(vertical: 24),
        //       child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        //     );
        //   }
        //   if (ctrl.dicomStudies.isEmpty) {
        //     return _emptyStateMini('Tidak ada data DICOM ditemukan di server PACS');
        //   }
        //   return Column(
        //     children: ctrl.dicomStudies.map((study) => _buildDicomCard(ctrl, study)).toList(),
        //   );
        // }),
      ],
    );
    });
  }

  Widget _buildRadiologiCard(Map<String, dynamic> r) {
    final title = r['nm_periksa']?.toString() ?? '-';
    final expertise = r['keterangan']?.toString() ?? '-';
    final fotoUrl = r['foto']?.toString();
    final cleanExpertise = _cleanHtml(expertise);

    return Builder(builder: (context) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withOpacity(0.02),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_search_rounded,
                      color: AppTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expertise / Bacaan Dokter:',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cleanExpertise,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  if (fotoUrl != null &&
                      fotoUrl.isNotEmpty &&
                      fotoUrl != '-') ...[
                    const SizedBox(height: 16),
                    Text(
                      'Foto Radiologi:',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showImageDialog(context, fotoUrl, title),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CachedNetworkImage(
                              imageUrl: fotoUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.bgSurface,
                                height: 160,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      color: AppTheme.primary),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.bgSurface,
                                height: 160,
                                child: const Icon(Icons.broken_image,
                                    color: AppTheme.textMuted, size: 40),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.zoom_in,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Perbesar Foto',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /*
  Widget _buildDicomCard(
      RekamMedisController ctrl, Map<String, dynamic> study) {
    final studyDesc =
        study['studyDescription']?.toString() ?? 'Pemeriksaan PACS';
    final studyDateRaw = study['studyDate']?.toString() ?? '-';
    String formattedDate = studyDateRaw;
    if (studyDateRaw.length == 8) {
      formattedDate =
          '${studyDateRaw.substring(6, 8)}/${studyDateRaw.substring(4, 6)}/${studyDateRaw.substring(0, 4)}';
    }
    final modalityList = study['modality'] as List? ?? [];
    final modality =
        modalityList.isNotEmpty ? modalityList.join(', ') : 'unknown';
    final seriesCount = study['seriesCount'] ?? 0;
    final studyId = study['studyId']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentAlt.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentAlt.withOpacity(0.2)),
            ),
            child: Text(
              modality.toUpperCase(),
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentAlt,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studyDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tanggal: $formattedDate • Seri: $seriesCount',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    if (studyId.isNotEmpty) {
                      final url = await ctrl.getDicomViewerUrl(studyId);
                      Get.to(() => DicomViewerPage(url: url, title: studyDesc));
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.zoom_out_map_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Buka DICOM Viewer',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  */

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 40),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Text(
                title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<p>'), '')
        .replaceAll(RegExp(r'</p>'), '\n')
        .replaceAll(RegExp(r'<strong>'), '')
        .replaceAll(RegExp(r'</strong>'), '')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .trim();
  }

  Widget _emptyStateMini(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 24, color: AppTheme.textMuted.withOpacity(0.6)),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _listCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing,
          ],
        ],
      ),
    );
  }

  static Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: AppTheme.divider,
      highlightColor: AppTheme.bgDark.withOpacity(0.5),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, _) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 180,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.divider),
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 40, color: AppTheme.textMuted.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Belum ada riwayat tercatat untuk pasien ini',
            style: GoogleFonts.outfit(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSbarTab(BuildContext context, RekamMedisController ctrl) {
    return Obx(() {
      if (ctrl.isLoadingSbar.value) {
        return _buildShimmerLoader();
      }
      final list = ctrl.sbarList;
      if (list.isEmpty) return _emptyState('Belum ada handover SBAR');

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final sbar = list[index];
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
                  color: AppTheme.textPrimary.withOpacity(0.015),
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
                          color: AppTheme.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.success.withOpacity(0.2)),
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
                        onPressed: () =>
                            _confirmValidasiSbar(context, ctrl, tgl, jam),
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
                          color: AppTheme.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.warning.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pending_actions_rounded,
                                color: AppTheme.warning, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Belum Diverifikasi',
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

  void _confirmValidasiSbar(
      BuildContext context, RekamMedisController ctrl, String tgl, String jam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text(
          'Verifikasi DPJP',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        content: Text(
          'Apakah Anda yakin ingin melakukan verifikasi DPJP untuk instruksi SBAR ini?',
          style:
              GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ctrl.validasiSbar(tgl, jam);
              if (success) {
                Get.snackbar(
                    'Sukses', 'Instruksi SBAR berhasil diverifikasi oleh DPJP',
                    backgroundColor: AppTheme.success.withOpacity(0.1),
                    colorText: AppTheme.success,
                    snackPosition: SnackPosition.BOTTOM);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              'Ya, Verifikasi',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

void _confirmDeleteSoap(BuildContext context, RekamMedisController ctrl, String tgl, String jam) {
    Get.dialog(
      AlertDialog(
        title: Text('Hapus SOAP', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus data SOAP ini?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
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

  void _showSoapForm(BuildContext context, RekamMedisController ctrl, {Map<String, dynamic>? existingData}) {
    final isEdit = existingData != null;
    
    final draft = !isEdit ? ctrl.soapDraft : <String, String>{};

    final keluhanCtrl = TextEditingController(text: existingData?['keluhan_utama'] ?? draft['keluhan_utama'] ?? '');
    final pemeriksaanCtrl = TextEditingController(text: existingData?['pemeriksaan_fisik'] ?? draft['pemeriksaan_fisik'] ?? '');
    final penilaianCtrl = TextEditingController(text: existingData?['diagnosis'] ?? draft['diagnosis'] ?? '');
    final rtlCtrl = TextEditingController(text: existingData?['tata'] ?? draft['tata'] ?? '');
    final instruksiCtrl = TextEditingController(text: existingData?['instruksi'] ?? draft['instruksi'] ?? '');
    final evaluasiCtrl = TextEditingController(text: existingData?['evaluasi'] ?? draft['evaluasi'] ?? '');
    
    final suhuCtrl = TextEditingController(text: existingData?['suhu']?.toString() ?? draft['suhu'] ?? '');
    final tensiCtrl = TextEditingController(text: existingData?['td']?.toString() ?? draft['td'] ?? '');
    final nadiCtrl = TextEditingController(text: existingData?['nadi']?.toString() ?? draft['nadi'] ?? '');
    final respirasiCtrl = TextEditingController(text: existingData?['rr']?.toString() ?? draft['rr'] ?? '');
    final tinggiCtrl = TextEditingController(text: existingData?['tb']?.toString() ?? draft['tb'] ?? '');
    final beratCtrl = TextEditingController(text: existingData?['bb']?.toString() ?? draft['bb'] ?? '');
    final spo2Ctrl = TextEditingController(text: existingData?['spo']?.toString() ?? draft['spo'] ?? '');
    final gcsCtrl = TextEditingController(text: existingData?['gcs']?.toString() ?? draft['gcs'] ?? '');
    final kesadaranCtrl = TextEditingController(text: existingData?['kesadaran']?.toString() ?? draft['kesadaran'] ?? 'Compos Mentis');

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
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    isEdit ? 'Ubah Pemeriksaan SOAP' : 'Tambah Pemeriksaan SOAP',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7), // Warm premium amber
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xFFF59E0B).withOpacity(0.12),
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
                    Text('Tanda Vital & Fisik', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _formField('Suhu (°C)', suhuCtrl, keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _formField('Tensi (mmHg)', tensiCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _formField('Nadi (bpm)', nadiCtrl, keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _formField('Respirasi (x/m)', respirasiCtrl, keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _formField('Tinggi (cm)', tinggiCtrl, keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _formField('Berat (kg)', beratCtrl, keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _formField('SpO2 (%)', spo2Ctrl, keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _formField('GCS', gcsCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _formField('Kesadaran', kesadaranCtrl),
                    
                    const SizedBox(height: 20),
                    const Divider(color: AppTheme.divider),
                    const SizedBox(height: 16),
                    
                    Text('Catatan SOAP', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                    const SizedBox(height: 12),
                    _formField('S (Subjective) - Keluhan Utama', keluhanCtrl, maxLines: 3),
                    const SizedBox(height: 12),
                    _formField('O (Objective) - Pemeriksaan Fisik', pemeriksaanCtrl, maxLines: 3),
                    const SizedBox(height: 12),
                    _formField('A (Assessment) - Diagnosis/Penilaian', penilaianCtrl, maxLines: 3),
                    const SizedBox(height: 12),
                    _formField('P (Plan) - Tata Laksana / RTL', rtlCtrl, maxLines: 3),
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
                            Get.snackbar('Sukses', isEdit ? 'SOAP berhasil diperbarui' : 'SOAP berhasil disimpan',
                                backgroundColor: Colors.white, colorText: AppTheme.primary);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isEdit ? 'Perbarui Catatan' : 'Simpan Catatan',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _formField(String label, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  void _showAddDiagnosaDialog(BuildContext context, RekamMedisController ctrl, String code, String name) {
    int priority = 1;
    String status = 'Baru';
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Tambah Diagnosa', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$code - $name', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                Text('Prioritas', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                Row(
                  children: [
                    Radio<int>(value: 1, groupValue: priority, onChanged: (v) => setState(() => priority = v!)),
                    Text('1 (Utama)', style: GoogleFonts.outfit(fontSize: 12)),
                    const SizedBox(width: 12),
                    Radio<int>(value: 2, groupValue: priority, onChanged: (v) => setState(() => priority = v!)),
                    Text('2+ (Sekunder)', style: GoogleFonts.outfit(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Status Kasus', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                Row(
                  children: [
                    Radio<String>(value: 'Baru', groupValue: status, onChanged: (v) => setState(() => status = v!)),
                    Text('Baru', style: GoogleFonts.outfit(fontSize: 12)),
                    const SizedBox(width: 12),
                    Radio<String>(value: 'Lama', groupValue: status, onChanged: (v) => setState(() => status = v!)),
                    Text('Lama', style: GoogleFonts.outfit(fontSize: 12)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('Batal', style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                  final success = await ctrl.addDiagnosa(kdPenyakit: code, prioritas: priority, statusPenyakit: status);
                  if (success) {
                    Get.snackbar('Sukses', 'Diagnosa berhasil ditambahkan', backgroundColor: Colors.white, colorText: AppTheme.primary);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: Text('Simpan', style: GoogleFonts.outfit(color: Colors.white)),
              ),
            ],
          );
        }
      )
    );
  }

  void _showAddProsedurDialog(BuildContext context, RekamMedisController ctrl, String code, String name) {
    int priority = 1;
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Tambah Prosedur', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$code - $name', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                Text('Prioritas', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                Row(
                  children: [
                    Radio<int>(value: 1, groupValue: priority, onChanged: (v) => setState(() => priority = v!)),
                    Text('1 (Utama)', style: GoogleFonts.outfit(fontSize: 12)),
                    const SizedBox(width: 12),
                    Radio<int>(value: 2, groupValue: priority, onChanged: (v) => setState(() => priority = v!)),
                    Text('2+ (Sekunder)', style: GoogleFonts.outfit(fontSize: 12)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('Batal', style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                  final success = await ctrl.addProsedur(kode: code, prioritas: priority);
                  if (success) {
                    Get.snackbar('Sukses', 'Prosedur berhasil ditambahkan', backgroundColor: Colors.white, colorText: AppTheme.primary);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: Text('Simpan', style: GoogleFonts.outfit(color: Colors.white)),
              ),
            ],
          );
        }
      )
    );
  }

  void _confirmDeleteResep(BuildContext context, RekamMedisController ctrl, String noResep) {
    Get.dialog(
      AlertDialog(
        title: Text('Hapus Resep', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus resep $noResep ini?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
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

  void _showPrescriptionSheet(BuildContext context, RekamMedisController ctrl) {
    final searchCtrl = TextEditingController();
    
    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
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
                          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                          itemBuilder: (context, idx) {
                            final item = ctrl.searchObatResults[idx];
                            final name = item['nama_brng'] ?? '-';
                            final code = item['kode_brng'] ?? '';
                            final stock = double.tryParse(item['total_stok']?.toString() ?? '0') ?? 0.0;
                            final isLowStock = stock <= 0;
                            
                            return ListTile(
                              dense: true,
                              title: Text(name, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Stok: ${stock.toStringAsFixed(0)} ${item['satuan'] ?? ''}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: isLowStock ? AppTheme.danger : AppTheme.textSecondary,
                                  fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: isLowStock
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                      child: Text('Habis', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.bold)),
                                    )
                                  : Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary, size: 20),
                              onTap: isLowStock
                                  ? () {
                                      Get.snackbar('Peringatan', 'Stok obat habis!', backgroundColor: Colors.white, colorText: AppTheme.danger);
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7), // Warm premium amber
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xFFF59E0B).withOpacity(0.12),
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
                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (ctrl.prescriptionDraft.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.shopping_basket_outlined, size: 40, color: AppTheme.textMuted.withOpacity(0.5)),
                                const SizedBox(height: 8),
                                Text('Keranjang resep kosong', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
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
                          final qtyCtrl = TextEditingController(text: item['jml']?.toString() ?? '1');
                          final sigCtrl = TextEditingController(text: item['aturan_pakai'] ?? '3x1 tablet');
                          
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['nama_brng'] ?? '-',
                                        style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
                                      onPressed: () => ctrl.removeFromPrescription(code),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Jumlah', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary)),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: qtyCtrl,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Aturan Pakai / Signa', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary)),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: sigCtrl,
                                            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
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
                                  final success = await ctrl.submitPrescription();
                                  if (success) {
                                    Get.back();
                                    Get.snackbar('Sukses', 'Resep berhasil dikirim', backgroundColor: Colors.white, colorText: AppTheme.primary);
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Kirim Resep Ke Farmasi',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
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

  Widget _buildKonsultasiTab(BuildContext context, RekamMedisController ctrl) {
    final activeSubTab = 0.obs;
    
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
                      final active = activeSubTab.value == 0;
                      return GestureDetector(
                        onTap: () => activeSubTab.value = 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: active ? AppTheme.primary : Colors.transparent, width: 2)),
                          ),
                          child: Text(
                            'Konsul Keluar',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: active ? FontWeight.bold : FontWeight.w600,
                              color: active ? AppTheme.primary : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  Expanded(
                    child: Obx(() {
                      final active = activeSubTab.value == 1;
                      return GestureDetector(
                        onTap: () => activeSubTab.value = 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: active ? AppTheme.primary : Colors.transparent, width: 2)),
                          ),
                          child: Text(
                            'Konsul Masuk',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: active ? FontWeight.bold : FontWeight.w600,
                              color: active ? AppTheme.primary : AppTheme.textSecondary,
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
                  return RekamMedisView._buildShimmerLoader();
                }
                
                final isOutgoing = activeSubTab.value == 0;
                final list = isOutgoing ? ctrl.outgoingConsults : ctrl.incomingConsults;
                
                if (list.isEmpty) {
                  return RekamMedisView._emptyState(isOutgoing ? 'Belum ada permintaan konsul keluar' : 'Belum ada konsul masuk');
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final item = list[idx];
                    final tgl = item['tgl_perawatan'] ?? item['tgl_pesan'] ?? '-';
                    final jam = item['jam_pesan'] ?? '-';
                    final drPemberi = item['nm_dokter_pemberi'] ?? item['kd_dokter_pemberi'] ?? '-';
                    final drPeminta = item['nm_dokter_peminta'] ?? item['kd_dokter_peminta'] ?? '-';
                    
                    final status = item['status']?.toString() ?? 'Belum Dijawab';
                    final isAnswered = status.toLowerCase() == 'sudah dijawab' || item['jawaban'] != null;
                    
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
                                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isAnswered ? AppTheme.success : AppTheme.warning).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAnswered ? 'Dijawab' : 'Pending',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isAnswered ? AppTheme.success : AppTheme.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isOutgoing ? 'Dokter Penerima: $drPemberi' : 'Dokter Pengirim: $drPeminta',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          if (item['deskripsi_rujukan'] != null && item['deskripsi_rujukan'].toString().isNotEmpty) ...[
                            Text(
                              'Permintaan / Konsultasi:',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                            Text(
                              _stripAttachment(item['deskripsi_rujukan']),
                              style: GoogleFonts.outfit(fontSize: 12.5, color: AppTheme.textPrimary),
                            ),
                            _buildAttachmentsSection(item['deskripsi_rujukan']),
                            const SizedBox(height: 8),
                          ],
                          if (isAnswered && item['jawaban'] != null) ...[
                            const Divider(color: AppTheme.divider, height: 16),
                            Text(
                              'Jawaban / Balasan:',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                            ),
                            Text(
                              _stripAttachment(item['jawaban']),
                              style: GoogleFonts.outfit(fontSize: 12.5, color: AppTheme.textPrimary),
                            ),
                            _buildAttachmentsSection(item['jawaban']),
                          ],
                          if (!isOutgoing && !isAnswered) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _showReplyConsultationDialog(context, ctrl, item),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                child: Text('Jawab Konsultasi', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
          if (activeSubTab.value == 0) {
            return Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _showConsultationDialog(context, ctrl),
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

  void _showConsultationDialog(BuildContext context, RekamMedisController ctrl) {
    Map<String, dynamic>? selectedDokter;
    final rujukanCtrl = TextEditingController();
    final diagnosaCtrl = TextEditingController();
    final attachmentCtrl = TextEditingController();
    final dokterSearchCtrl = TextEditingController();
    final filteredDokterList = <Map<String, dynamic>>[].obs;
    
    filteredDokterList.value = ctrl.dokterList;
    
    Get.dialog(
      AlertDialog(
        title: Text('Kirim Permintaan Konsultasi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: Get.width * 0.85,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih Dokter Tujuan', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: dokterSearchCtrl,
                  decoration: const InputDecoration(hintText: 'Cari nama dokter...', prefixIcon: Icon(Icons.search_rounded), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (val) {
                    if (val.trim().isEmpty) {
                      filteredDokterList.value = ctrl.dokterList;
                    } else {
                      filteredDokterList.value = ctrl.dokterList.where((d) => (d['nm_dokter'] ?? '').toString().toLowerCase().contains(val.toLowerCase())).toList();
                    }
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.divider), borderRadius: BorderRadius.circular(8)),
                  child: Obx(() {
                    if (filteredDokterList.isEmpty) {
                      return Center(child: Text('Dokter tidak ditemukan', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)));
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredDokterList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                      itemBuilder: (context, idx) {
                        final dr = filteredDokterList[idx];
                        final code = dr['kd_dokter'] ?? '';
                        final name = dr['nm_dokter'] ?? '';
                        return Obx(() {
                          final isSelected = selectedDokter?['kd_dokter'] == code;
                          return ListTile(
                            dense: true,
                            title: Text(name, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            selected: isSelected,
                            selectedColor: AppTheme.primary,
                            onTap: () {
                              selectedDokter = dr;
                              dokterSearchCtrl.text = name;
                              filteredDokterList.refresh();
                            },
                          );
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text('Diagnosa Kerja', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: diagnosaCtrl,
                  decoration: const InputDecoration(hintText: 'Tuliskan diagnosa kerja...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                ),
                const SizedBox(height: 16),
                Text('Isi Permintaan / Rujukan / Keterangan', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: rujukanCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Tuliskan deskripsi rujukan/pertanyaan...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                ),
                const SizedBox(height: 16),
                Text('URL Lampiran (Opsional, cth: PACS, Lab PDF)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: attachmentCtrl,
                  decoration: const InputDecoration(hintText: 'http://pacs.link/...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Batal', style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              if (selectedDokter == null) {
                Get.snackbar('Error', 'Silakan pilih dokter tujuan terlebih dahulu', backgroundColor: Colors.white, colorText: AppTheme.danger);
                return;
              }
              if (rujukanCtrl.text.trim().isEmpty) {
                Get.snackbar('Error', 'Isi rujukan tidak boleh kosong', backgroundColor: Colors.white, colorText: AppTheme.danger);
                return;
              }
              Get.back();
              
              String finalUraian = rujukanCtrl.text;
              if (attachmentCtrl.text.trim().isNotEmpty) {
                finalUraian += '\n[Attachment: ${attachmentCtrl.text.trim()}]';
              }

              final success = await ctrl.sendConsultation(
                targetDokter: selectedDokter!['kd_dokter'],
                jenis: ctrl.tipeRawat.isEmpty ? 'RALAN' : ctrl.tipeRawat,
                diagnosa: diagnosaCtrl.text,
                uraian: finalUraian,
              );
              if (success) {
                Get.snackbar('Sukses', 'Permintaan konsultasi berhasil dikirim', backgroundColor: Colors.white, colorText: AppTheme.primary);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text('Kirim', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

void _showReplyConsultationDialog(BuildContext context, RekamMedisController ctrl, Map<String, dynamic> item) {
  final jawabanCtrl = TextEditingController();
  final diagnosaCtrl = TextEditingController();
  final attachmentCtrl = TextEditingController();
  
  Get.dialog(
    AlertDialog(
      title: Text('Jawab Konsultasi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dari: ${item['nm_dokter_peminta'] ?? item['kd_dokter_peminta'] ?? '-'}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text(item['deskripsi_rujukan'] ?? '-', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Text('Diagnosa Kerja / Hasil Pemeriksaan', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: diagnosaCtrl,
              decoration: const InputDecoration(hintText: 'Tuliskan diagnosa kerja/hasil...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            ),
            const SizedBox(height: 16),
            Text('Jawaban / Keterangan', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: jawabanCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Tuliskan jawaban...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            ),
            const SizedBox(height: 16),
            Text('URL Lampiran (Opsional, cth: PACS, Lab PDF)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: attachmentCtrl,
              decoration: const InputDecoration(hintText: 'http://pacs.link/...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Batal', style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () async {
            if (jawabanCtrl.text.trim().isEmpty) {
              Get.snackbar('Error', 'Jawaban tidak boleh kosong', backgroundColor: Colors.white, colorText: AppTheme.danger);
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
              Get.snackbar('Sukses', 'Konsultasi berhasil dijawab', backgroundColor: Colors.white, colorText: AppTheme.primary);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: Text('Kirim', style: GoogleFonts.outfit(color: Colors.white)),
        ),
      ],
    ),
  );
}

// ── _SoapTile ─────────────────────────────────────────────────────────────────
// StatefulWidget terpisah agar state expand tidak ter-recycle oleh ListView
class _SoapTile extends StatefulWidget {
  const _SoapTile({
    required super.key,
    required this.data,
    required this.initiallyExpanded,
  });

  final Map<String, dynamic> data;
  final bool initiallyExpanded;

  @override
  State<_SoapTile> createState() => _SoapTileState();
}

class _SoapTileState extends State<_SoapTile> {
  late bool _isExpanded;
  final _ctrl = Get.find<RekamMedisController>();

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    final uniqueId = '${data['tanggal']}_${data['jam']}_${data['petugas']}';
    if (!_ctrl.expandedStates.containsKey(uniqueId)) {
      _ctrl.expandedStates[uniqueId] = widget.initiallyExpanded;
    }
    _isExpanded = _ctrl.expandedStates[uniqueId]!;
  }

  @override
  void didUpdateWidget(covariant _SoapTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final data = widget.data;
      final uniqueId = '${data['tanggal']}_${data['jam']}_${data['petugas']}';
      if (!_ctrl.expandedStates.containsKey(uniqueId)) {
        _ctrl.expandedStates[uniqueId] = widget.initiallyExpanded;
      }
      _isExpanded = _ctrl.expandedStates[uniqueId]!;
    }
  }

  bool _hasVal(String key) {
    final v = widget.data[key]?.toString() ?? '-';
    return v.isNotEmpty && v != '-';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final formattedDate = data['tanggal']?.toString() ?? '-';
    final formattedTime = data['jam']?.toString() ?? '-';
    final timeStr = formattedTime == '-' ? '' : ' pukul $formattedTime';
    final petugas = data['petugas']?.toString() ?? 'Petugas Medis';
    final jabatan = data['jabatan']?.toString() ?? '';
    final uniqueId = '${data['tanggal']}_${data['jam']}_${data['petugas']}';

    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withOpacity(0.02),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ExpansionTile(
          key: ValueKey(uniqueId),
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (v) {
            setState(() => _isExpanded = v);
            _ctrl.expandedStates[uniqueId] = v;
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sticky_note_2_rounded,
                color: AppTheme.primary, size: 20),
          ),
          title: Text(
            'Catatan SOAP $formattedDate$timeStr',
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            jabatan.isNotEmpty && jabatan != '-'
                ? '$petugas • $jabatan'
                : 'Petugas: $petugas',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: Obx(() {
            final authCtrl = Get.find<AuthController>();
            final myNip = authCtrl.user.value?['nip'] ?? authCtrl.user.value?['username'] ?? '';
            final recordNip = data['nip']?.toString() ?? '';
            final isOwnRecord = recordNip == myNip && myNip.isNotEmpty;
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOwnRecord) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 18),
                    onPressed: () => _showSoapForm(context, _ctrl, existingData: data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
                    onPressed: () => _confirmDeleteSoap(context, _ctrl, formattedDate, formattedTime),
                  ),
                ],
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textSecondary,
                ),
              ],
            );
          }),
          children: [
            const Divider(height: 24, thickness: 1, color: AppTheme.divider),

            // ── S: SUBJEKTIF ──────────────────────────────────────
            _soapLabel('S', 'Subjektif', AppTheme.primary),
            const SizedBox(height: 10),
            _clinicalSection('Anamnesis', [
              _row('Keluhan Utama', data['keluhan_utama']),
              if (_hasVal('rps'))
                _row('Riwayat Penyakit Sekarang (RPS)', data['rps']),
              if (_hasVal('rpd'))
                _row('Riwayat Penyakit Dahulu (RPD)', data['rpd']),
              if (_hasVal('rpk'))
                _row('Riwayat Penyakit Keluarga (RPK)', data['rpk']),
              if (_hasVal('rpo')) _row('Riwayat Pengobatan (RPO)', data['rpo']),
              if (_hasVal('hubungan'))
                _row('Diceritakan Oleh', data['hubungan']),
              _row('Alergi', data['alergi']),
            ]),

            const SizedBox(height: 16),

            // ── O: OBJEKTIF ───────────────────────────────────────
            _soapLabel('O', 'Objektif', AppTheme.accent),
            const SizedBox(height: 10),
            _clinicalSection('Tanda Vital', [
              _vitalGrid(data),
              _buildVitalsChart(),
            ]),
            if (_hasVal('keadaan') ||
                _hasVal('kesadaran') ||
                _hasVal('gcs') ||
                _hasVal('bb') ||
                _hasVal('tb')) ...[
              const SizedBox(height: 12),
              _clinicalSection('Keadaan Umum', [
                if (_hasVal('keadaan')) _row('Keadaan Umum', data['keadaan']),
                if (_hasVal('kesadaran')) _row('Kesadaran', data['kesadaran']),
                if (_hasVal('gcs')) _row('GCS', data['gcs']),
                if (_hasVal('bb')) _row('Berat Badan', '${data['bb']} kg'),
                if (_hasVal('tb')) _row('Tinggi Badan', '${data['tb']} cm'),
              ]),
            ],
            if (_hasVal('pemeriksaan_fisik')) ...[
              const SizedBox(height: 12),
              _clinicalSection('Pemeriksaan Fisik', [
                _row('Hasil Pemeriksaan', data['pemeriksaan_fisik']),
              ]),
            ],
            if (_hasVal('lab') || _hasVal('rad') || _hasVal('penunjang')) ...[
              const SizedBox(height: 12),
              _clinicalSection('Penunjang', [
                if (_hasVal('lab')) _row('Laboratorium', data['lab']),
                if (_hasVal('rad')) _row('Radiologi', data['rad']),
                if (_hasVal('penunjang')) _row('Lainnya', data['penunjang']),
              ]),
            ],

            const SizedBox(height: 16),

            // ── A: ASSESSMENT ─────────────────────────────────────
            _soapLabel('A', 'Assessment', AppTheme.warning),
            const SizedBox(height: 10),
            _clinicalSection('Penilaian / Diagnosis', [
              _row('Diagnosis / Penilaian', data['diagnosis']),
            ]),

            const SizedBox(height: 16),

            // ── P: PLAN ───────────────────────────────────────────
            _soapLabel('P', 'Plan', AppTheme.success),
            const SizedBox(height: 10),
            _clinicalSection('Rencana & Tindak Lanjut', [
              if (_hasVal('tata')) _row('Tata Laksana / RTL', data['tata']),
              if (_hasVal('instruksi')) _row('Instruksi', data['instruksi']),
              if (_hasVal('evaluasi')) _row('Evaluasi', data['evaluasi']),
              if (_hasVal('edukasi')) _row('Edukasi', data['edukasi']),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _soapLabel(String letter, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            letter,
            style: GoogleFonts.robotoMono(
                fontSize: 14, fontWeight: FontWeight.w900, color: color),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13.5, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _clinicalSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _vitalGrid(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: [
        _vitalCard('Tekanan Darah', data['td'], 'mmHg', Icons.speed_rounded,
            _evalTensi(data['td'])),
        _vitalCard('Nadi', data['nadi'], 'x/mnt', Icons.favorite_rounded,
            _evalNadi(data['nadi'])),
        _vitalCard('Respirasi (RR)', data['rr'], 'x/mnt', Icons.air_rounded,
            _evalRR(data['rr'])),
        _vitalCard('Suhu Tubuh', data['suhu'], '°C', Icons.thermostat_rounded,
            _evalSuhu(data['suhu'])),
        _vitalCard('SpO₂', data['spo'], '%', Icons.bloodtype_rounded,
            _evalSpo(data['spo'])),
      ],
    );
  }

  Widget _vitalCard(String label, dynamic value, String unit, IconData icon,
      Color statusColor) {
    final displayValue =
        (value == null || value.toString().isEmpty || value.toString() == '-')
            ? '-'
            : value.toString();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 14, color: statusColor),
              Text(unit,
                  style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(displayValue,
              style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 8.5,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty || value.toString() == '-') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value.toString(),
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.4)),
        ],
      ),
    );
  }

  Color _evalTensi(dynamic td) {
    if (td == null) return AppTheme.textMuted;
    final sys = int.tryParse(
        td.toString().split('/')[0].replaceAll(RegExp(r'[^0-9]'), ''));
    if (sys != null) {
      if (sys >= 140) return AppTheme.danger;
      if (sys >= 130) return AppTheme.warning;
      if (sys < 90) return AppTheme.warning;
      return AppTheme.success;
    }
    return AppTheme.success;
  }

  Color _evalNadi(dynamic val) {
    if (val == null) return AppTheme.textMuted;
    final n = int.tryParse(val.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    if (n != null) {
      return (n > 100 || n < 60) ? AppTheme.warning : AppTheme.success;
    }
    return AppTheme.success;
  }

  Color _evalRR(dynamic val) {
    if (val == null) return AppTheme.textMuted;
    final rr = int.tryParse(val.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    if (rr != null) {
      return (rr > 22 || rr < 12) ? AppTheme.warning : AppTheme.success;
    }
    return AppTheme.success;
  }

  Color _evalSuhu(dynamic val) {
    if (val == null) return AppTheme.textMuted;
    final s =
        double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
    if (s != null) {
      if (s > 37.8 || s < 35.5) return AppTheme.danger;
      if (s > 37.2) return AppTheme.warning;
      return AppTheme.success;
    }
    return AppTheme.success;
  }

  Color _evalSpo(dynamic val) {
    if (val == null) return AppTheme.textMuted;
    final spo = int.tryParse(val.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    if (spo != null) return spo < 95 ? AppTheme.danger : AppTheme.success;
    return AppTheme.success;
  }

  Widget _buildVitalsChart() {
    return Obx(() {
      final points = _ctrl.vitalsChartData;
      if (points.length < 2) {
        return const SizedBox.shrink();
      }

      final type = _ctrl.activeChartType.value;

      List<FlSpot> spots1 = [];
      List<FlSpot> spots2 = [];

      double minY = 0;
      double maxY = 100;
      String label1 = '';
      String label2 = '';
      Color color1 = AppTheme.primary;
      Color color2 = AppTheme.accent;

      if (type == 0) {
        label1 = 'Sistole';
        label2 = 'Diastole';
        color1 = AppTheme.danger;
        color2 = AppTheme.info;
        for (int i = 0; i < points.length; i++) {
          if (points[i].systole != null) {
            spots1.add(FlSpot(i.toDouble(), points[i].systole!));
          }
          if (points[i].diastole != null) {
            spots2.add(FlSpot(i.toDouble(), points[i].diastole!));
          }
        }
        minY = 40;
        maxY = 200;
      } else if (type == 1) {
        label1 = 'Suhu (°C)';
        color1 = AppTheme.accent;
        for (int i = 0; i < points.length; i++) {
          if (points[i].suhu != null) {
            spots1.add(FlSpot(i.toDouble(), points[i].suhu!));
          }
        }
        minY = 35;
        maxY = 42;
      } else {
        label1 = 'Nadi (bpm)';
        label2 = 'Respirasi (rr)';
        color1 = AppTheme.success;
        color2 = AppTheme.warning;
        for (int i = 0; i < points.length; i++) {
          if (points[i].nadi != null) {
            spots1.add(FlSpot(i.toDouble(), points[i].nadi!));
          }
          if (points[i].rr != null) {
            spots2.add(FlSpot(i.toDouble(), points[i].rr!));
          }
        }
        minY = 10;
        maxY = 150;
      }

      if (spots1.isEmpty && spots2.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tren Perkembangan Vital',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    if (spots1.isNotEmpty) ...[
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color1, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(label1, style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                    if (spots2.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color2, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(label2, style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _chartTabButton('TD', 0, type),
                const SizedBox(width: 8),
                _chartTabButton('Suhu', 1, type),
                const SizedBox(width: 8),
                _chartTabButton('Nadi/RR', 2, type),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.divider.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final int idx = value.toInt();
                          if (idx >= 0 && idx < points.length) {
                            final dt = points[idx].dateTime;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                DateFormat('dd/MM').format(dt),
                                style: GoogleFonts.outfit(fontSize: 8, color: AppTheme.textMuted),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: GoogleFonts.outfit(fontSize: 8, color: AppTheme.textMuted),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.bgDark.withOpacity(0.9),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final dateStr = DateFormat('dd MMM yyyy HH:mm').format(points[idx].dateTime);
                          return LineTooltipItem(
                            '$dateStr\n${spot.bar.gradient != null ? label2 : label1}: ${spot.y.toStringAsFixed(1)}',
                            GoogleFonts.outfit(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    if (spots1.isNotEmpty)
                      LineChartBarData(
                        spots: spots1,
                        isCurved: true,
                        barWidth: 2.5,
                        color: color1,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 3,
                            color: color1,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                        ),
                      ),
                    if (spots2.isNotEmpty)
                      LineChartBarData(
                        spots: spots2,
                        isCurved: true,
                        barWidth: 2.5,
                        color: color2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 3,
                            color: color2,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _chartTabButton(String text, int index, int activeIdx) {
    final active = index == activeIdx;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _ctrl.activeChartType.value = index,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.bgDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? AppTheme.primary : AppTheme.divider),
          ),
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class DicomViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const DicomViewerPage({super.key, required this.url, required this.title});

  @override
  State<DicomViewerPage> createState() => _DicomViewerPageState();
}

class _DicomViewerPageState extends State<DicomViewerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

Widget _buildAttachmentsSection(String content) {
  final regExp = RegExp(r'\[Attachment:\s*(.*?)\]');
  final matches = regExp.allMatches(content);
  if (matches.isEmpty) return const SizedBox.shrink();

  final List<String> urls = [];
  for (final m in matches) {
    final matchVal = m.group(1)?.trim();
    if (matchVal != null && matchVal.isNotEmpty) {
      urls.addAll(matchVal.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    }
  }

  if (urls.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      Text(
        'Lampiran / Attachments:',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: urls.map((url) {
          final uri = Uri.tryParse(url);
          final filename = uri != null ? uri.pathSegments.lastOrNull ?? 'File Lampiran' : 'File Lampiran';
          final isImage = url.toLowerCase().endsWith('.png') ||
              url.toLowerCase().endsWith('.jpg') ||
              url.toLowerCase().endsWith('.jpeg') ||
              url.toLowerCase().endsWith('.webp');
          final isPdf = url.toLowerCase().endsWith('.pdf');

          return InkWell(
            onTap: () async {
              final parsedUri = Uri.tryParse(url);
              if (parsedUri != null && await canLaunchUrl(parsedUri)) {
                await launchUrl(parsedUri, mode: LaunchMode.externalApplication);
              } else {
                Get.snackbar('Error', 'Tidak dapat membuka lampiran', backgroundColor: Colors.white, colorText: AppTheme.danger);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isImage
                        ? Icons.image_rounded
                        : isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.attach_file_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        filename,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

String _stripAttachment(String content) {
  return content.replaceAll(RegExp(r'\[Attachment:\s*(.*?)\]'), '').trim();
}
