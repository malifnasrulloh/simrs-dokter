import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/google_fonts.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/patient_search_bar.dart';
import '../widgets/patient_tile.dart';

class PatientListView extends StatefulWidget {
  const PatientListView({super.key});

  @override
  State<PatientListView> createState() => _PatientListViewState();
}

class _PatientListViewState extends State<PatientListView> {
  final ctrl = Get.find<DashboardController>();
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  String searchQuery = '';
  late final String type; // 'RANAP', 'RALAN', or 'IGD'

  @override
  void initState() {
    super.initState();
    type = Get.arguments?['type'] as String? ?? 'RANAP';
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _rawList {
    switch (type) {
      case 'RANAP':
        return ctrl.listPasienRanap;
      case 'RALAN':
        return ctrl.listPasienRalan;
      case 'IGD':
        return ctrl.listPasienIGD;
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> get _filteredList {
    return filterPatientList(_rawList, searchQuery);
  }

  String get _title {
    switch (type) {
      case 'RANAP':
        return 'Pasien Rawat Inap';
      case 'RALAN':
        return 'Pasien Rawat Jalan';
      case 'IGD':
        return 'Pasien Gawat Darurat (IGD)';
      default:
        return 'Daftar Pasien';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: Get.back,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary, size: 14),
            ),
          ),
        ),
        title: Text(
          _title,
          style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.4),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Box
          PatientSearchBar(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: (val) => setState(() => searchQuery = val),
            onClear: () => setState(() => searchQuery = ''),
          ),

          const SizedBox(height: 4),

          // Patient List
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent));
              }

              final list = _filteredList;
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
                            size: 40,
                            color: AppTheme.textMuted.withValues(alpha: 0.5)),
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
                        'Silakan periksa kembali kata kunci pencarian Anda',
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pasien = list[index];
                    final typeColor = type == 'RANAP'
                        ? AppTheme.info
                        : type == 'RALAN'
                            ? AppTheme.success
                            : AppTheme.danger;

                    return PatientTile(
                        pasien: pasien, type: type, typeColor: typeColor);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
