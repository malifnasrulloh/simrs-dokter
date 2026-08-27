import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/patient_tile.dart';
import '../widgets/patient_search_bar.dart';
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
      if (_pageController.hasClients &&
          _pageController.page?.round() != index) {
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

    return filterPatientList(list, searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(auth),
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
                  color: AppTheme.primary.withValues(alpha: 0.2),
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
                  final displayText =
                      settingName ?? auth.user.value?['departemen'] ?? '';
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
                            color: AppTheme.success.withValues(alpha: 0.4),
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

  Widget _buildSearchBox() {
    return PatientSearchBar(
      controller: searchController,
      onChanged: (val) => setState(() => searchQuery = val),
      onClear: () => setState(() => searchQuery = ''),
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
                      color: AppTheme.textPrimary.withValues(alpha: 0.04),
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
    final typeStr = tabIndex == 0
        ? 'RANAP'
        : tabIndex == 1
            ? 'RALAN'
            : 'IGD';
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
                    size: 40, color: AppTheme.textMuted.withValues(alpha: 0.5)),
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
            return PatientTile(
                pasien: pasien, type: typeStr, typeColor: typeColor);
          },
        ),
      );
    });
  }
}
