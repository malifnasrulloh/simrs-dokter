import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
    final tabs = ['Medis', 'Diagnosa', 'Obat', 'Lab', 'Radiologi'];
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
      if (ctrl.isLoading.value) {
        return const Center(
          child:
              CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
        );
      }
      switch (ctrl.activeTab.value) {
        case 0:
          return _buildMedisTab(ctrl);
        case 1:
          return _buildDiagnosaTab(ctrl);
        case 2:
          return _buildObatTab(ctrl);
        case 3:
          return _buildLabTab(ctrl);
        case 4:
          return _buildRadiologiTab(ctrl);
        case 5:
          return _buildSbarTab(context, ctrl);
        default:
          return const SizedBox();
      }
    });
  }

  Widget _buildMedisTab(RekamMedisController ctrl) {
    final list = ctrl.riwayatMedis;
    if (list.isEmpty) return _emptyState('Belum ada data medis');
    final sortedList = list.reversed.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildDiagnosaTab(RekamMedisController ctrl) {
    if (ctrl.diagnosa.isEmpty) return _emptyState('Belum ada diagnosa');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ctrl.diagnosa.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final d = ctrl.diagnosa[i];
        return _listCard(
          icon: Icons.medical_information_rounded,
          iconColor: AppTheme.info,
          title: d['nm_penyakit'] ?? d['kd_penyakit'] ?? '-',
          subtitle:
              'ICD-10: ${d['kd_penyakit'] ?? '-'} • Status: ${d['status'] ?? '-'}',
        );
      },
    );
  }

  Widget _buildObatTab(RekamMedisController ctrl) {
    if (ctrl.obat.isEmpty) return _emptyState('Belum ada data obat');

    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final o in ctrl.obat) {
      final tgl = o['tgl_perawatan']?.toString() ?? '-';
      final jam = o['jam']?.toString() ?? '-';
      final key = '$tgl|$jam';
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(o);
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final parts = key.split('|');
        final tgl = parts[0];
        final jam = parts[1];
        final items = groups[key]!;

        final displayTime = jam == '-' ? '' : ' pukul $jam';

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
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: AppTheme.success, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Resep $tgl$displayTime',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
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
                  final signa = o['aturan'] ?? o['signa'] ?? '';
                  final namaObat = o['nama_obat'] ?? o['nm_obat'] ?? '-';
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
                            color: AppTheme.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.medication_rounded,
                              color: AppTheme.success, size: 16),
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
  }

  Widget _buildRadiologiTab(RekamMedisController ctrl) {
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

  Widget _emptyState(String message) {
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
        return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent));
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
            _clinicalSection('Tanda Vital', [_vitalGrid(data)]),
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
