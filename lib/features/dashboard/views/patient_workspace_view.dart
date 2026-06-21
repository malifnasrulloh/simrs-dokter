import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../../../core/utils/google_fonts.dart';

class PatientWorkspaceView extends StatefulWidget {
  const PatientWorkspaceView({super.key});

  @override
  State<PatientWorkspaceView> createState() => _PatientWorkspaceViewState();
}

class _PatientWorkspaceViewState extends State<PatientWorkspaceView> {
  final ctrl = Get.find<DashboardController>();
  final auth = Get.find<AuthController>();
  final searchController = TextEditingController();
  String searchQuery = '';

  late PageController _pageController;
  late Worker _tabWorker;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ctrl.selectedTab.value);
    _tabWorker = ever(ctrl.selectedTab, (int index) {
      if (_pageController.hasClients && _pageController.page?.round() != index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabWorker.dispose();
    _pageController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredListForTab(int tabIndex) {
    List<Map<String, dynamic>> list;
    switch (tabIndex) {
      case 0:
        list = ctrl.listPasienRanap;
        break;
      case 1:
        list = ctrl.listPasienRalan;
        break;
      case 2:
        list = ctrl.listPasienIGD;
        break;
      default:
        list = [];
    }

    if (searchQuery.isEmpty) return list;
    final query = searchQuery.toLowerCase();
    return list.where((p) {
      final name = p['nm_pasien']?.toString().toLowerCase() ?? '';
      final rm =
          (p['no_rm'] ?? p['no_rkm_medis'])?.toString().toLowerCase() ?? '';
      final room = (p['kamar'] ?? p['nm_ruang'] ?? p['nm_poli'])
              ?.toString()
              .toLowerCase() ??
          '';
      return name.contains(query) || rm.contains(query) || room.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(auth),
            // Obx(() => _buildStatStrip()),
            _buildSearchBox(),
            Obx(() => _buildWorkspaceTabs()),
            _buildPatientList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthController auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
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
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w800),
                  );
                }),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Obx(() => Text(
                            auth.user.value?['nama'] ?? 'Dokter',
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.success,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.success.withOpacity(0.4),
                            spreadRadius: 2,
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildStatStrip() {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //     decoration: BoxDecoration(
  //       color: AppTheme.bgCard,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: AppTheme.divider),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppTheme.textPrimary.withOpacity(0.03),
  //           blurRadius: 16,
  //           offset: const Offset(0, 8),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       children: [
  //         _statItem('Ranap', ctrl.totalRanap.value, AppTheme.info, 0),
  //         _verticalDivider(),
  //         _statItem('Ralan', ctrl.totalRalan.value, AppTheme.success, 1),
  //         _verticalDivider(),
  //         _statItem('IGD', ctrl.totalIGD.value, AppTheme.danger, 2),
  //       ],
  //     ),
  //   );
  // }

  // Widget _statItem(String label, int count, Color color, int index) {
  //   final active = ctrl.selectedTab.value == index;
  //   return Expanded(
  //     child: GestureDetector(
  //       onTap: () => ctrl.selectedTab.value = index,
  //       child: Container(
  //         color: Colors.transparent,
  //         child: Column(
  //           children: [
  //             Text(
  //               '$count',
  //               style: GoogleFonts.robotoMono(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.w800,
  //                 color: active ? color : AppTheme.textPrimary,
  //               ),
  //             ),
  //             const SizedBox(height: 2),
  //             Text(
  //               label,
  //               style: GoogleFonts.outfit(
  //                 fontSize: 11.5,
  //                 color: active ? color : AppTheme.textSecondary,
  //                 fontWeight: active ? FontWeight.w800 : FontWeight.w600,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _verticalDivider() {
  //   return Container(
  //     width: 1.2,
  //     height: 28,
  //     color: AppTheme.divider,
  //   );
  // }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: searchController,
        onChanged: (val) => setState(() => searchQuery = val),
        style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Cari nama, No. RM, atau ruangan...',
          hintStyle: GoogleFonts.outfit(
              color: AppTheme.textMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.textMuted, size: 18),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.textSecondary, size: 18),
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.bgCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.divider, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceTabs() {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _workspaceTab(0, 'Rawat Inap', Icons.hotel_rounded, AppTheme.info),
          _workspaceTab(1, 'Rawat Jalan', Icons.directions_walk_rounded,
              AppTheme.success),
          _workspaceTab(2, 'IGD', Icons.emergency_rounded, AppTheme.danger),
        ],
      ),
    );
  }

  Widget _workspaceTab(
      int index, String label, IconData icon, Color activeColor) {
    final active = ctrl.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ctrl.selectedTab.value = index;
        },
        child: Container(
          decoration: BoxDecoration(
            color: active ? AppTheme.bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.textPrimary.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14, color: active ? activeColor : AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    return Expanded(
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          ctrl.selectedTab.value = index;
        },
        children: [
          _buildPatientCategoryList(0),
          _buildPatientCategoryList(1),
          _buildPatientCategoryList(2),
        ],
      ),
    );
  }

  Widget _buildPatientCategoryList(int tabIndex) {
    final typeStr = tabIndex == 0 ? 'RANAP' : tabIndex == 1 ? 'RALAN' : 'IGD';
    final typeColor = tabIndex == 0
        ? AppTheme.info
        : tabIndex == 2
            ? AppTheme.danger
            : AppTheme.success;

    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        );
      }

      final list = _filteredListForTab(tabIndex);
      if (list.isEmpty) {
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
                child: Icon(Icons.person_search_rounded,
                    size: 40, color: AppTheme.textMuted.withOpacity(0.5)),
              ),
              const SizedBox(height: 16),
              Text(
                searchQuery.isEmpty
                    ? 'Tidak ada data pasien'
                    : 'Pasien tidak ditemukan',
                style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Silakan periksa kembali filter pencarian Anda',
                style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.bgCard,
        onRefresh: ctrl.fetchDashboard,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final pasien = list[index];
            return _patientTile(pasien, typeStr, typeColor);
          },
        ),
      );
    });
  }

  Widget _patientTile(
      Map<String, dynamic> pasien, String type, Color typeColor) {
    final penjamin = pasien['png_jawab']?.toString() ?? 'Umum';
    final isBpjs = penjamin.toUpperCase().contains('BPJS');
    final room =
        pasien['kamar'] ?? pasien['nm_ruang'] ?? pasien['nm_poli'] ?? '-';

    String dokterName = '-';
    if (type == 'RANAP') {
      final dpjpList = pasien['dpjp'] as List?;
      if (dpjpList != null && dpjpList.isNotEmpty) {
        dokterName = dpjpList[0]['nm_dokter'] ?? '-';
      }
    } else {
      dokterName = pasien['nm_dokter'] ?? '-';
    }

    final jk = pasien['jk']?.toString() ?? '-';
    final isMale = jk.toUpperCase() == 'L' ||
        jk.toUpperCase() == 'PRIA' ||
        jk.toUpperCase() == 'LAKI-LAKI';
    final genderText = isMale ? 'L' : 'P';
    final age = pasien['umur'] ?? pasien['usia'] ?? '-';
    final date = pasien['tgl_masuk'] ?? pasien['tgl_registrasi'] ?? '-';

    return GestureDetector(
      onTap: () =>
          Get.toNamed('/rekam-medis', arguments: {...pasien, '_type': type}),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  color: typeColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pasien['nm_pasien'] ?? '-',
                                style: GoogleFonts.outfit(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isBpjs
                                    ? const Color(0xFFD1FAE5)
                                    : AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isBpjs
                                      ? const Color(0xFF10B981).withOpacity(0.3)
                                      : AppTheme.divider,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isBpjs ? 'BPJS' : 'UMUM',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isBpjs
                                      ? const Color(0xFF047857)
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              pasien['no_rm'] ?? pasien['no_rkm_medis'] ?? '-',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('•',
                                style: GoogleFonts.outfit(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Text(
                              '$genderText • $age',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700),
                            ),
                            if (type == 'RANAP' && pasien['lama'] != null) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      color: Colors.orange.withOpacity(0.2)),
                                ),
                                child: Text(
                                  '${pasien['lama']} Hari',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.bed_outlined,
                                size: 13, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                room,
                                style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              date,
                              style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 13, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'DPJP: $dokterName',
                                style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
