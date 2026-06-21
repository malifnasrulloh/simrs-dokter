import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: RefreshIndicator(
        onRefresh: ctrl.fetchDashboard,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorHeader(auth),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildSectionTitle('Status Pelayanan Hari Ini'),
                    const SizedBox(height: 8),
                    _buildStatsGrid(context, ctrl),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Jadwal Operasi Hari Ini'),
                    const SizedBox(height: 8),
                    _buildSurgeryList(ctrl),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Ketersediaan Bed Rawat Inap'),
                    const SizedBox(height: 8),
                    _buildBedOccupancyList(ctrl),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorHeader(AuthController auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final settingName = auth.setting.value?['nama_instansi'];
                    final displayText = settingName ?? auth.user.value?['departemen'] ?? '';
                    if (displayText.isEmpty) return const SizedBox.shrink();
                    return Text(
                      displayText,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        auth.user.value?['nama'] ?? 'Dokter Spesialis',
                        style: GoogleFonts.outfit(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      )),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DPJP Aktif',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardController ctrl) {
    return Obx(() {
      // Calculate checked Ralan count
      final ralanTotal = ctrl.listPasienRalan.length;
      final ralanChecked = ctrl.listPasienRalan
          .where((p) => p['stts']?.toString().toLowerCase().startsWith('sudah') ?? false)
          .length;

      final ranapTotal = ctrl.listPasienRanap.length;
      final igdTotal = ctrl.listPasienIGD.length;
      final operasiTotal = ctrl.listJadwalOperasi.length;

      final width = MediaQuery.of(context).size.width;
      final int columns = width > 600 ? 4 : 2;
      final double aspectRatio = width > 600 ? 1.8 : 1.45;

      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: aspectRatio,
        children: [
          _buildStatCard(
            title: 'Antrean Ralan',
            value: '$ralanChecked / $ralanTotal',
            subText: 'Sudah Diperiksa',
            icon: Icons.people_outline_rounded,
            color: AppTheme.success,
            onTap: () {
              ctrl.selectedTab.value = 1; // Ralan
              ctrl.currentNavIndex.value = 1; // Pasien tab
            },
          ),
          _buildStatCard(
            title: 'Pasien Rawat Inap',
            value: '$ranapTotal',
            subText: 'DPJP Tanggung Jawab',
            icon: Icons.hotel_outlined,
            color: Colors.blue,
            onTap: () {
              ctrl.selectedTab.value = 0; // Ranap
              ctrl.currentNavIndex.value = 1; // Pasien tab
            },
          ),
          _buildStatCard(
            title: 'Pasien IGD',
            value: '$igdTotal',
            subText: 'Perawatan Darurat',
            icon: Icons.emergency_outlined,
            color: Colors.red,
            onTap: () {
              ctrl.selectedTab.value = 2; // IGD
              ctrl.currentNavIndex.value = 1; // Pasien tab
            },
          ),
          _buildStatCard(
            title: 'Jadwal Operasi',
            value: '$operasiTotal',
            subText: 'Rencana Tindakan',
            icon: Icons.healing_outlined,
            color: Colors.amber[700]!,
            onTap: () {
              // Stay on home dashboard to see list below
            },
          ),
        ],
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subText,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurgeryList(DashboardController ctrl) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return _buildShimmerPlaceholder();
      }
      if (ctrl.listJadwalOperasi.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            children: [
              Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted.withOpacity(0.5), size: 36),
              const SizedBox(height: 8),
              Text(
                'Tidak ada jadwal operasi hari ini',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ctrl.listJadwalOperasi.length,
        itemBuilder: (context, index) {
          final op = ctrl.listJadwalOperasi[index];
          final timeStr = '${op['jam_mulai']?.toString().substring(0, 5) ?? '00:00'} - ${op['jam_selesai']?.toString().substring(0, 5) ?? 'Selesai'}';
          final room = op['nm_ruang_ok']?.toString() ?? 'Kamar OK';
          final procedure = op['nm_perawatan']?.toString() ?? 'Tindakan Operasi';
          final patient = op['nm_pasien']?.toString() ?? 'Pasien';
          final rm = op['no_rkm_medis']?.toString() ?? '';
          final doctor = op['nm_dokter']?.toString() ?? '-';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: Colors.amber, size: 16),
                      const SizedBox(height: 4),
                      Text(
                        op['jam_mulai']?.toString().substring(0, 5) ?? '00:00',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber[900],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'RM: $rm • $timeStr',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        procedure,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        '$room • Dr. $doctor',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildBedOccupancyList(DashboardController ctrl) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return _buildShimmerPlaceholder();
      }
      if (ctrl.bedClasses.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: Text(
            'Data bed tidak tersedia',
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: ctrl.bedClasses.map((item) {
            final cls = item['kelas']?.toString() ?? '-';
            
            // Look up total bed counts for this class from bedDetails
            final details = ctrl.bedDetails.where((d) => d['kelas'] == cls);
            int totalKosong = 0;
            int totalBed = 0;
            for (var d in details) {
              totalKosong += int.tryParse(d['total_kosong']?.toString() ?? '0') ?? 0;
              totalBed += int.tryParse(d['total_bed']?.toString() ?? '0') ?? 0;
            }
            final totalIsi = totalBed - totalKosong;
            final double percent = totalBed > 0 ? (totalIsi / totalBed) : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cls,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '$totalKosong Kosong dari $totalBed Bed',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: totalKosong > 0 ? AppTheme.primary : AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      backgroundColor: AppTheme.bgSurface,
                      color: percent > 0.85 ? Colors.red : (percent > 0.60 ? Colors.orange : AppTheme.success),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }
}
