import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_retry_widget.dart';
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
              Obx(() {
                if (ctrl.hasDashboardError.value &&
                    ctrl.listPasienRanap.isEmpty &&
                    ctrl.listPasienRalan.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: ErrorRetryWidget(
                      message: 'Gagal memuat data dashboard. Periksa koneksi Anda.',
                      onRetry: () => ctrl.fetchDashboard(),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildSectionTitle('Status Pelayanan Hari Ini'),
                      const SizedBox(height: 6),
                      _buildStatsGrid(context, ctrl),
                      const SizedBox(height: 14),
                      _buildKonsultasiInboxSection(ctrl),
                      const SizedBox(height: 14),
                      _buildSbarInboxSection(ctrl),
                      const SizedBox(height: 14),
                      _buildSectionTitle('Jadwal Operasi Hari Ini'),
                      const SizedBox(height: 6),
                      _buildSurgeryList(ctrl),
                      const SizedBox(height: 14),
                      _buildSectionTitle('Ketersediaan Bed Rawat Inap'),
                      const SizedBox(height: 6),
                      _buildBedOccupancyList(ctrl),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorHeader(AuthController auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.2),
              ),
              child: const Icon(Icons.medical_services_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      Expanded(
                        child: Obx(() {
                          final settingName = auth.setting.value?['nama_instansi'];
                          final displayText =
                              settingName ?? auth.user.value?['departemen'] ?? 'SIMRS RS Islam Aminah';
                          return Text(
                            displayText,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Obx(() => Text(
                        auth.user.value?['nama'] ?? 'Dokter Spesialis',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
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
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardController ctrl) {
    return Obx(() {
      // Calculate checked Ralan count
      final ralanTotal = ctrl.listPasienRalan.length;
      final ralanChecked = ctrl.listPasienRalan
          .where((p) =>
              p['stts']?.toString().toLowerCase().startsWith('sudah') ?? false)
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
        padding: EdgeInsets.zero,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
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
    return Semantics(
      label: '$title: $value, $subText',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.015),
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
                    color: color.withValues(alpha: 0.08),
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
    ),
  );
}

  Widget _buildKonsultasiInboxSection(DashboardController ctrl) {
    return Obx(() {
      final pending = ctrl.incomingConsultations
          .where((c) =>
              c['status']?.toString().toLowerCase() != 'sudah dijawab' &&
              c['jawaban'] == null)
          .length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionTitle('Konsultasi Masuk'),
              if (pending > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$pending belum dijawab',
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          _buildKonsultasiInboxList(ctrl),
        ],
      );
    });
  }

  Widget _buildKonsultasiInboxList(DashboardController ctrl) {
    if (ctrl.isLoading.value || ctrl.isLoadingConsultations.value) {
      return _buildShimmerPlaceholder();
    }
    if (ctrl.incomingConsultations.isEmpty) {
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
            Icon(Icons.chat_bubble_outline_rounded,
                color: AppTheme.textMuted.withValues(alpha: 0.5), size: 36),
            const SizedBox(height: 8),
            Text(
              'Tidak ada konsultasi masuk untuk Anda',
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
      padding: EdgeInsets.zero,
      itemCount: ctrl.incomingConsultations.length,
      itemBuilder: (context, index) {
        final item = ctrl.incomingConsultations[index];
        final drPeminta = item['nm_dokter_peminta'] ??
            item['kd_dokter_peminta'] ??
            'Rekan Dokter';
        final nmPasien = item['nm_pasien']?.toString() ?? 'Pasien';
        final noRawat = item['no_rawat']?.toString() ?? '';
        final tgl = item['tgl_perawatan'] ?? item['tgl_pesan'] ?? '';
        final jam = item['jam_pesan'] ?? '';
        final jamStr = jam.length >= 5 ? jam.substring(0, 5) : jam;
        final status = item['status']?.toString() ?? 'Belum Dijawab';
        final isAnswered = status.toLowerCase() == 'sudah dijawab' ||
            item['jawaban'] != null;
        final diagnosa = item['diagnosa_kerja']?.toString().trim() ?? '';
        final deskripsi = item['deskripsi_rujukan']?.toString().trim() ?? '';

        return GestureDetector(
          onTap: () => Get.toNamed('/rekam-medis', arguments: <String, dynamic>{
            'no_rawat': noRawat,
            'nm_pasien': nmPasien,
            '_type': item['status_lanjut'] ?? 'RANAP',
            '_targetTab': 5, // Konsultasi tab
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAnswered
                    ? AppTheme.divider
                    : AppTheme.primary.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: (isAnswered ? AppTheme.success : AppTheme.primary)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAnswered
                        ? Icons.mark_chat_read_rounded
                        : Icons.forward_to_inbox_rounded,
                    size: 16,
                    color: isAnswered ? AppTheme.success : AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              nmPasien,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            tgl.isNotEmpty && jamStr.isNotEmpty
                                ? '$tgl $jamStr'
                                : tgl,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Dari: $drPeminta',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (diagnosa.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Diagnosa: $diagnosa',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (deskripsi.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          deskripsi,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isAnswered ? AppTheme.success : AppTheme.primary)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAnswered ? 'Dijawab' : 'Pending',
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isAnswered ? AppTheme.success : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSbarInboxSection(DashboardController ctrl) {
    return Obx(() {
      final pending = ctrl.sbarInbox
          .where((s) => s['validasi']?['status_validasi'] == null)
          .length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionTitle('SBAR Masuk'),
              if (pending > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$pending belum divalidasi',
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          _buildSbarInboxList(ctrl),
        ],
      );
    });
  }

  Widget _buildSbarInboxList(DashboardController ctrl) {
    if (ctrl.isLoading.value) {
      return _buildShimmerPlaceholder();
    }
    if (ctrl.sbarInbox.isEmpty) {
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
            Icon(Icons.fact_check_outlined,
                color: AppTheme.textMuted.withValues(alpha: 0.5), size: 36),
            const SizedBox(height: 8),
            Text(
              'Tidak ada SBAR masuk untuk Anda',
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
      padding: EdgeInsets.zero,
      itemCount: ctrl.sbarInbox.length,
      itemBuilder: (context, index) {
        final sbar = ctrl.sbarInbox[index];
        final nmPasien = sbar['nm_pasien']?.toString() ?? 'Pasien';
        final petugas = sbar['petugas']?['nama']?.toString() ??
            sbar['petugas']?['nik']?.toString() ??
            '-';
        final tgl = sbar['tgl_perawatan']?.toString() ?? '';
        final jam = sbar['jam_rawat']?.toString() ?? '';
        final jamStr = jam.length >= 5 ? jam.substring(0, 5) : jam;
        final isAnswered = sbar['validasi']?['status_validasi'] != null;
        final situation = sbar['situation']?.toString().trim() ?? '';

        return GestureDetector(
          onTap: () => Get.toNamed('/rekam-medis', arguments: <String, dynamic>{
            'no_rawat': sbar['no_rawat'],
            'nm_pasien': nmPasien,
            '_type': 'RANAP',
            '_targetTab': 6, // SBAR tab (only present for RANAP)
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAnswered
                    ? AppTheme.divider
                    : Colors.orange.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: (isAnswered ? AppTheme.success : Colors.orange)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: isAnswered ? AppTheme.success : Colors.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nmPasien,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: (isAnswered
                                      ? AppTheme.success
                                      : Colors.orange)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAnswered ? 'Divalidasi' : 'Menunggu',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isAnswered
                                    ? AppTheme.success
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        situation,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dari $petugas • $tgl $jamStr',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
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
              Icon(Icons.calendar_today_rounded,
                  color: AppTheme.textMuted.withValues(alpha: 0.5), size: 36),
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
        padding: EdgeInsets.zero,
        itemCount: ctrl.listJadwalOperasi.length,
        itemBuilder: (context, index) {
          final op = ctrl.listJadwalOperasi[index];
          final jamMulaiRaw = op['jam_mulai']?.toString() ?? '';
          final jamMulai = jamMulaiRaw.length >= 5
              ? jamMulaiRaw.substring(0, 5)
              : (jamMulaiRaw.isNotEmpty ? jamMulaiRaw : '00:00');
          final jamSelesaiRaw = op['jam_selesai']?.toString() ?? '';
          final jamSelesai = jamSelesaiRaw.length >= 5
              ? jamSelesaiRaw.substring(0, 5)
              : (jamSelesaiRaw.isNotEmpty ? jamSelesaiRaw : 'Selesai');
          final timeStr = '$jamMulai - $jamSelesai';
          final room = op['nm_ruang_ok']?.toString() ?? 'Kamar OK';
          final procedure =
              op['nm_perawatan']?.toString() ?? 'Tindakan Operasi';
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.access_time_filled_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(height: 4),
                      Text(
                        jamMulai,
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
              totalKosong +=
                  int.tryParse(d['total_kosong']?.toString() ?? '0') ?? 0;
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
                          color: totalKosong > 0
                              ? AppTheme.primary
                              : AppTheme.danger,
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
                      color: percent > 0.85
                          ? Colors.red
                          : (percent > 0.60 ? Colors.orange : AppTheme.success),
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
