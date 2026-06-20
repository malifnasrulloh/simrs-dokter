import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final ctrl = Get.find<DashboardController>();
    auth.fetchProfile();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Obx(() {
        final profile = auth.profileData.value ?? {};
        final user = auth.user.value ?? {};

        final nama = profile['nama'] ?? user['nama'] ?? 'Dokter Spesialis';
        final nip = profile['nik'] ?? user['nip'] ?? '-';
        
        final docInfo = profile['dokter_info'] as Map<String, dynamic>?;
        final spesialis = docInfo?['spesialis'] ?? '';
        final jabatan = profile['jabatan'] ?? (spesialis.isNotEmpty ? 'Dokter Spesialis $spesialis' : 'Staf Medik Fungsional');
        
        final settingName = auth.setting.value?['nama_instansi'];
        final departemen = profile['departemen'] ?? settingName ?? user['departemen'] ?? '';
        
        final noIjn = docInfo?['no_ijn_praktek'] ?? '-';
        final gender = profile['jenis_kelamin'] ?? '-';
        final birthPlace = profile['tempat_lahir'] ?? '';
        final birthDate = profile['tanggal_lahir'] ?? '';
        final birthStr = (birthPlace.isNotEmpty && birthDate.isNotEmpty)
            ? '$birthPlace, $birthDate'
            : birthDate.isNotEmpty
                ? birthDate
                : '-';
        final alamat = profile['alamat'] ?? '-';

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(nama, jabatan),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Informasi Akun Medis'),
                    const SizedBox(height: 8),
                    _buildProfileDetailsCard(
                      nip: nip,
                      dept: departemen,
                      noIjn: noIjn,
                      gender: gender,
                      ttl: birthStr,
                      alamat: alamat,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Statistik Kerja Hari Ini'),
                    const SizedBox(height: 8),
                    _buildWorkStats(ctrl),
                    const SizedBox(height: 24),
                    _buildBrandingAndLogout(auth, settingName),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(String name, String job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
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
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.15),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.person_rounded, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              job,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
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
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildProfileDetailsCard({
    required String nip,
    required String dept,
    required String noIjn,
    required String gender,
    required String ttl,
    required String alamat,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.badge_outlined, 'NIP / Kode Dokter', nip),
          const Divider(height: 24, thickness: 0.8),
          _buildDetailRow(Icons.local_hospital_outlined, 'Unit / Departemen', dept),
          const Divider(height: 24, thickness: 0.8),
          _buildDetailRow(Icons.card_membership_rounded, 'No. Izin Praktek (SIP)', noIjn),
          const Divider(height: 24, thickness: 0.8),
          _buildDetailRow(Icons.person_outline_rounded, 'Jenis Kelamin', gender),
          const Divider(height: 24, thickness: 0.8),
          _buildDetailRow(Icons.cake_outlined, 'Tempat, Tanggal Lahir', ttl),
          const Divider(height: 24, thickness: 0.8),
          _buildDetailRow(Icons.location_on_outlined, 'Alamat Rumah', alamat),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkStats(DashboardController ctrl) {
    return Obx(() {
      final ralanCount = ctrl.listPasienRalan.length;
      final ranapCount = ctrl.listPasienRanap.length;
      final igdCount = ctrl.listPasienIGD.length;
      final totalToday = ralanCount + ranapCount + igdCount;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            _buildStatRow('Total Pasien Dilayani', '$totalToday orang', AppTheme.success),
            const Divider(height: 20),
            _buildStatRow('Pemeriksaan Ralan', '$ralanCount pasien', Colors.blue),
            const Divider(height: 20),
            _buildStatRow('Pemeriksaan Ranap', '$ranapCount pasien', Colors.orange),
            const Divider(height: 20),
            _buildStatRow('Pemeriksaan IGD', '$igdCount pasien', Colors.red),
          ],
        ),
      );
    });
  }

  Widget _buildStatRow(String label, String value, Color bulletColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bulletColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingAndLogout(AuthController auth, String? settingName) {
    return Column(
      children: [
        Text(
          'CareDoc EMR v1.0.0',
          style: GoogleFonts.outfit(
            fontSize: 10.5,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (settingName != null && settingName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            settingName,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: auth.logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger.withOpacity(0.08),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.danger, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Keluar Aplikasi',
                  style: GoogleFonts.outfit(
                    color: AppTheme.danger,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
