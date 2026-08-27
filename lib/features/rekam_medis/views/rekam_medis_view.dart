import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/google_fonts.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/rekam_medis_controller.dart';
import 'tabs/diagnosa_tab.dart';
import 'tabs/konsultasi_tab.dart';
import 'tabs/lab_tab.dart';
import 'tabs/medis_tab.dart';
import 'tabs/obat_tab.dart';
import 'tabs/radiologi_tab.dart';
import 'tabs/sbar_tab.dart';

/// Main electronic medical record (EMR) view with 7 clinical tabs.
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
    final valueStr = formatRupiah(selisih);

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
            color: AppTheme.primary.withValues(alpha: 0.2),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
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
                        final isAlreadyDpjp = ctrl.dpjpList
                            .any((d) => d['kd_dokter']?.toString() == myNip);
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
                                  color: Colors.white.withValues(alpha: 0.95),
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
                        color: Colors.white.withValues(alpha: 0.15),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    height: 1,
                    thickness: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _infoChip(Icons.badge_rounded, 'No. Rawat',
                        pasien['no_rawat'] ?? '-'),
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
                          color: Colors.white.withValues(alpha: 0.2),
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
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              formatRupiah(total),
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
                            _billingItem('Total Billing', formatRupiah(total)),
                            const SizedBox(width: 12),
                            if (hasPerkiraan) ...[
                              _billingItem(
                                  'Estimasi Tarif', formatRupiah(perkiraan)),
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
    final tabs = [
      'Medis',
      'Diagnosa',
      'Obat',
      'Lab',
      'Radiologi',
      'Konsultasi'
    ];
    if (ctrl.tipeRawat == 'RANAP') {
      tabs.add('SBAR');
    }
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.separated(
        controller: ctrl.tabScrollController,
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
                        ? AppTheme.primaryLight.withValues(alpha: 0.3)
                        : AppTheme.divider,
                    width: 1,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
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
    final children = [
      MedisTab(ctrl: ctrl),
      DiagnosaTab(ctrl: ctrl),
      ObatTab(ctrl: ctrl),
      LabTab(ctrl: ctrl),
      RadiologiTab(ctrl: ctrl),
      KonsultasiTab(ctrl: ctrl),
    ];
    if (ctrl.tipeRawat == 'RANAP') {
      children.add(SbarTab(ctrl: ctrl));
    }

    return PageView(
      controller: ctrl.pageController,
      onPageChanged: (index) {
        ctrl.activeTab.value = index;
      },
      children: children,
    );
  }
}
