import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';

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
    if (searchQuery.isEmpty) return _rawList;
    return _rawList.where((p) {
      final name = p['nm_pasien']?.toString().toLowerCase() ?? '';
      final rm = (p['no_rm'] ?? p['no_rkm_medis'])?.toString().toLowerCase() ?? '';
      final room = (p['kamar'] ?? p['nm_ruang'] ?? p['nm_poli'])?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      return name.contains(query) || rm.contains(query) || room.contains(query);
    }).toList();
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 14),
            ),
          ),
        ),
        title: Text(
          _title,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.4),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
              style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Cari nama, No. RM, atau ruangan...',
                hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13.5, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 18),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.bgCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          ),
          
          const SizedBox(height: 4),
          
          // Patient List
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
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
                        child: Icon(Icons.person_search_rounded, size: 40, color: AppTheme.textMuted.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isEmpty ? 'Tidak ada data pasien' : 'Pasien tidak ditemukan',
                        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Silakan periksa kembali kata kunci pencarian Anda',
                        style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
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
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pasien = list[index];
                    final penjamin = pasien['png_jawab']?.toString() ?? 'Umum';
                    final isBpjs = penjamin.toUpperCase().contains('BPJS');
                    final room = pasien['kamar'] ?? pasien['nm_ruang'] ?? pasien['nm_poli'] ?? '-';
                    
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
                    final isMale = jk.toUpperCase() == 'L' || jk.toUpperCase() == 'PRIA' || jk.toUpperCase() == 'LAKI-LAKI';
                    final genderText = isMale ? 'L' : 'P';
                    final age = pasien['umur'] ?? pasien['usia'] ?? '-';
                    final date = pasien['tgl_masuk'] ?? pasien['tgl_registrasi'] ?? '-';

                    return GestureDetector(
                      onTap: () => Get.toNamed('/rekam-medis', arguments: {...pasien, '_type': type}),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.divider, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.textPrimary.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isBpjs ? const Color(0xFFD1FAE5) : AppTheme.bgSurface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isBpjs ? const Color(0xFF10B981).withOpacity(0.3) : AppTheme.divider,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    isBpjs ? 'BPJS' : 'UMUM',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isBpjs ? const Color(0xFF047857) : AppTheme.textSecondary,
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
                                Text('•', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontWeight: FontWeight.w800)),
                                const SizedBox(width: 8),
                                Text(
                                  '$genderText • $age',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
                                ),
                                if (type == 'RANAP' && pasien['lama'] != null) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
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
                            const Divider(height: 1, thickness: 1, color: AppTheme.divider),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.bed_outlined, size: 13, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    room,
                                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  date,
                                  style: GoogleFonts.outfit(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 13, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'DPJP: $dokterName',
                                    style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
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
