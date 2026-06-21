import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';

class HarianDokterView extends StatefulWidget {
  const HarianDokterView({super.key});

  @override
  State<HarianDokterView> createState() => _HarianDokterViewState();
}

class _HarianDokterViewState extends State<HarianDokterView> {
  final ScrollController _scrollController = ScrollController();
  late DashboardController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<DashboardController>();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!ctrl.isLoadingHarian.value && ctrl.harianList.length < ctrl.totalHarianCount.value) {
          ctrl.fetchHarianDokter(isLoadMore: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatRupiah(double val) {
    if (val == 0) return 'Rp 0';
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
    return '${isNegative ? '- ' : ''}Rp $reversed';
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? ctrl.selectedDateStart.value : ctrl.selectedDateEnd.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.black,
              surface: AppTheme.bgCard,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppTheme.bgDark,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (isStart) {
        ctrl.selectedDateStart.value = picked;
      } else {
        ctrl.selectedDateEnd.value = picked;
      }
      ctrl.fetchHarianDokter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'Jasa Medis & Laporan Harian',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: AppTheme.bgCard,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ctrl.fetchHarianDokter(),
        color: AppTheme.primary,
        backgroundColor: AppTheme.bgCard,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(context),
                    const SizedBox(height: 16),
                    _buildSummarySection(),
                    const SizedBox(height: 20),
                    _buildSectionHeader(),
                  ],
                ),
              ),
            ),
            _buildListSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final dateStartStr = ctrl.selectedDateStart.value.toIso8601String().substring(0, 10);
    final dateEndStr = ctrl.selectedDateEnd.value.toIso8601String().substring(0, 10);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Rentang Tanggal & Cara Bayar',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ctrl.selectedDateStart.value.toIso8601String().substring(0, 10),
                            style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 12),
                          ),
                          const Icon(Icons.calendar_month, color: AppTheme.primary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('s/d', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ctrl.selectedDateEnd.value.toIso8601String().substring(0, 10),
                            style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 12),
                          ),
                          const Icon(Icons.calendar_month, color: AppTheme.primary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final options = ctrl.caraBayarOptions;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: ctrl.selectedCaraBayar.value,
                  dropdownColor: AppTheme.bgCard,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  items: [
                    DropdownMenuItem(
                      value: 'Semua',
                      child: Text('Semua Cara Bayar', style: GoogleFonts.outfit()),
                    ),
                    ...options.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt['kd_pj'] ?? '',
                        child: Text(opt['png_jawab'] ?? '', style: GoogleFonts.outfit()),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ctrl.selectedCaraBayar.value = val;
                      ctrl.fetchHarianDokter();
                    }
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Obx(() {
      final summary = ctrl.harianSummary;
      final grandTotal = double.tryParse(summary['grand_total']?.toString() ?? '0') ?? 0;
      final rj = double.tryParse(summary['total_rj']?.toString() ?? '0') ?? 0;
      final ri = double.tryParse(summary['total_ri']?.toString() ?? '0') ?? 0;
      final op = double.tryParse(summary['total_op']?.toString() ?? '0') ?? 0;
      final lab = double.tryParse(summary['total_lab']?.toString() ?? '0') ?? 0;
      final rad = double.tryParse(summary['total_rad']?.toString() ?? '0') ?? 0;

      final width = MediaQuery.of(context).size.width;
      final int columns = width > 600 ? 5 : (width > 360 ? 2 : 1);
      final double aspectRatio = width > 600 ? 2.0 : (width > 360 ? 2.2 : 4.0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.15),
                  AppTheme.primary.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL JASA MEDIS',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRupiah(grandTotal),
                  style: GoogleFonts.robotoMono(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildSummaryCard('Rawat Jalan', rj, const Color(0xFFCBEBFF)),
              _buildSummaryCard('Rawat Inap', ri, const Color(0xFFCBFCD4)),
              _buildSummaryCard('Bedah / Operasi', op, const Color(0xFFFFD4D4)),
              _buildSummaryCard('Laboratorium', lab, const Color(0xFFFFF0CB)),
              _buildSummaryCard('Radiologi', rad, const Color(0xFFFFE3D2)),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard(String title, double val, Color dotColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatRupiah(val),
            style: GoogleFonts.robotoMono(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Daftar Transaksi Pasien',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${ctrl.totalHarianCount.value} Tindakan',
              style: GoogleFonts.outfit(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildListSection() {
    return Obx(() {
      if (ctrl.isLoadingHarian.value && ctrl.harianList.isEmpty) {
        return SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildShimmerLoader(),
          ),
        );
      }

      if (ctrl.harianList.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 48, color: AppTheme.textSecondary.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text(
                  'Tidak ada data transaksi harian.',
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == ctrl.harianList.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                  ),
                ),
              );
            }

            final tx = ctrl.harianList[index];
            final noRawat = tx['no_rawat'] ?? '-';
            final patientName = tx['nm_pasien'] ?? 'Pasien Anonim';
            final nrm = tx['no_rkm_medis'] ?? '-';
            final category = tx['tipe'] ?? 'Tindakan';
            final categoryCode = tx['kat_code'] ?? 'RJ';
            final procedure = tx['nm_perawatan'] ?? '-';
            final dateStr = tx['tgl'] ?? '';
            final timeStr = tx['jam'] ?? '';
            final payMethod = tx['png_jawab'] ?? '-';
            final tarif = double.tryParse(tx['tarif']?.toString() ?? '0') ?? 0;

            Color tagColor;
            switch (categoryCode) {
              case 'RJ':
                tagColor = const Color(0xFFCBEBFF);
                break;
              case 'RI':
                tagColor = const Color(0xFFCBFCD4);
                break;
              case 'OP':
                tagColor = const Color(0xFFFFD4D4);
                break;
              case 'LAB':
                tagColor = const Color(0xFFFFF0CB);
                break;
              case 'RAD':
                tagColor = const Color(0xFFFFE3D2);
                break;
              default:
                tagColor = AppTheme.divider;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tagColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: tagColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.outfit(
                                    color: tagColor,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$dateStr $timeStr',
                                style: GoogleFonts.robotoMono(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            patientName,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'No. RM: $nrm  •  $noRawat',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            procedure,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.payments_outlined, size: 12, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  payMethod,
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Jasa Medis',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRupiah(tarif),
                          style: GoogleFonts.robotoMono(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: ctrl.harianList.length + (ctrl.harianList.length < ctrl.totalHarianCount.value ? 1 : 0),
        ),
      );
    });
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: AppTheme.bgCard,
      highlightColor: AppTheme.divider,
      child: ListView.builder(
        itemCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}
