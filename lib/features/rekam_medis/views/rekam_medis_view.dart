import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../controllers/rekam_medis_controller.dart';

class RekamMedisView extends StatelessWidget {
  const RekamMedisView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(RekamMedisController());

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Obx(() {
          final pasien = ctrl.pasienData.value ?? Get.arguments as Map<String, dynamic>? ?? {};
          return Column(
            children: [
              _buildAppBar(pasien),
              _buildPatientCard(pasien),
              _buildTabBar(ctrl),
              Expanded(
                child: ctrl.pasienData.value == null
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                    : _buildTabContent(ctrl),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 15),
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

  Widget _buildPatientCard(Map<String, dynamic> pasien) {
    final penjamin = pasien['png_jawab']?.toString() ?? 'Umum';
    final isBpjs = penjamin.toUpperCase().contains('BPJS');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (pasien['nm_pasien'] ?? 'P')[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pasien['nm_pasien'] ?? '-',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          pasien['no_rm'] ?? pasien['no_rkm_medis'] ?? '-',
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isBpjs ? 'BPJS' : 'UMUM',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2), height: 1, thickness: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _infoChip(Icons.badge_rounded, 'No. Rawat', pasien['no_rawat'] ?? '-'),
              const SizedBox(width: 20),
              _infoChip(Icons.bed_rounded, 'Kamar/Poli', pasien['nm_ruang'] ?? pasien['nm_poli'] ?? pasien['kamar'] ?? '-'),
            ],
          ),
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
              Icon(icon, size: 13, color: Colors.white70),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.outfit(
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

  Widget _buildTabBar(RekamMedisController ctrl) {
    final tabs = ['Medis', 'Diagnosa', 'Obat', 'Lab', 'Radiologi'];
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
                    color: active ? AppTheme.primaryLight.withOpacity(0.3) : AppTheme.divider,
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

  Widget _buildTabContent(RekamMedisController ctrl) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
        );
      }
      switch (ctrl.activeTab.value) {
        case 0: return _buildMedisTab(ctrl);
        case 1: return _buildDiagnosaTab(ctrl);
        case 2: return _buildObatTab(ctrl);
        case 3: return _buildLabTab(ctrl);
        case 4: return _buildRadiologiTab(ctrl);
        default: return const SizedBox();
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
        return _buildSoapExpansionTile(data, index == 0);
      },
    );
  }

  Widget _buildSoapExpansionTile(Map<String, dynamic> data, bool isExpanded) {
    final formattedDate = data['tanggal']?.toString() ?? '-';
    final formattedTime = data['jam']?.toString() ?? '-';
    final timeStr = formattedTime == '-' ? '' : ' pukul $formattedTime';
    final petugas = data['petugas']?.toString() ?? 'Petugas Medis';

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
          initiallyExpanded: isExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sticky_note_2_rounded, color: AppTheme.primary, size: 20),
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
            'Petugas: $petugas',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
            ),
          ),
          children: [
            const Divider(height: 24, thickness: 1, color: AppTheme.divider),
            _buildClinicalSection('Anamnesis', [
              _row('Keluhan Utama', data['keluhan_utama']),
              _row('Riwayat Penyakit Sekarang (RPS)', data['rps']),
              _row('Riwayat Penyakit Dahulu (RPD)', data['rpd']),
              _row('Alergi', data['alergi']),
            ]),
            const SizedBox(height: 16),
            _buildClinicalSection('Tanda Vital', [
              _buildVitalGrid(data),
            ]),
            const SizedBox(height: 16),
            _buildClinicalSection('Rencana Tata Laksana', [
              _row('Diagnosis / Penilaian', data['diagnosis']),
              _row('Tata Laksana', data['tata']),
              _row('Edukasi', data['edukasi']),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalSection(String title, List<Widget> children) {
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
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildVitalGrid(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: [
        _vitalCard('Tekanan Darah', data['td'], 'mmHg', Icons.speed_rounded, _evalTensi(data['td'])),
        _vitalCard('Nadi', data['nadi'], 'x/mnt', Icons.favorite_rounded, _evalNadi(data['nadi'])),
        _vitalCard('Respirasi (RR)', data['rr'], 'x/mnt', Icons.air_rounded, _evalRR(data['rr'])),
        _vitalCard('Suhu Tubuh', data['suhu'], '°C', Icons.thermostat_rounded, _evalSuhu(data['suhu'])),
        _vitalCard('SpO₂', data['spo'], '%', Icons.bloodtype_rounded, _evalSpo(data['spo'])),
      ],
    );
  }

  Color _evalTensi(dynamic td) {
    if (td == null) return AppTheme.textMuted;
    final str = td.toString().split('/')[0].replaceAll(RegExp(r'[^0-9]'), '');
    final sys = int.tryParse(str);
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
      if (n > 100 || n < 60) return AppTheme.warning;
      return AppTheme.success;
    }
    return AppTheme.success;
  }

  Color _evalRR(dynamic val) {
    if (val == null) return AppTheme.textMuted;
    final rr = int.tryParse(val.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    if (rr != null) {
      if (rr > 22 || rr < 12) return AppTheme.warning;
      return AppTheme.success;
    }
    return AppTheme.success;
  }

  Color _evalSuhu(dynamic val) {
    if (val == null) return AppTheme.textMuted;
    final s = double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
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
    if (spo != null) {
      if (spo < 95) return AppTheme.danger;
      return AppTheme.success;
    }
    return AppTheme.success;
  }

  Widget _vitalCard(String label, dynamic value, String unit, IconData icon, Color statusColor) {
    final displayValue = (value == null || value.toString().isEmpty || value.toString() == '-') ? '-' : value.toString();
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
              Text(
                unit,
                style: GoogleFonts.outfit(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 8.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
          subtitle: 'ICD-10: ${d['kd_penyakit'] ?? '-'} • Status: ${d['status'] ?? '-'}',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppTheme.success, size: 16),
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
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: AppTheme.divider),
                itemBuilder: (context, itemIdx) {
                  final o = items[itemIdx];
                  final signa = o['aturan'] ?? o['signa'] ?? '';
                  final namaObat = o['nama_obat'] ?? o['nm_obat'] ?? '-';
                  final qty = o['jumlah'] ?? '';
                  final unit = o['satuan'] ?? '';
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.medication_rounded, color: AppTheme.success, size: 16),
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
    
    if (s.contains('3x') || s.contains('tiga kali') || (s.contains('pagi') && s.contains('siang') && s.contains('malam'))) {
      morning = true;
      afternoon = true;
      night = true;
    } else if (s.contains('2x') || s.contains('dua kali') || (s.contains('pagi') && s.contains('malam'))) {
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
        if (morning) _timingIndicator('Pagi', Icons.light_mode_rounded, Colors.amber),
        if (afternoon) ...[
          const SizedBox(width: 4),
          _timingIndicator('Siang', Icons.wb_twilight_rounded, Colors.orange),
        ],
        if (night) ...[
          const SizedBox(width: 4),
          _timingIndicator('Malam', Icons.dark_mode_rounded, Colors.indigoAccent),
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
          Text(label, style: GoogleFonts.outfit(fontSize: 8.5, color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildLabTab(RekamMedisController ctrl) {
    if (ctrl.laboratorium.isEmpty) return _emptyState('Belum ada hasil laboratorium');
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: AppTheme.divider),
                itemBuilder: (context, itemIndex) {
                  final l = items[itemIndex] as Map<String, dynamic>;
                  final nmPeriksa = l['pemeriksaan']?.toString() ?? '-';
                  final hasil = l['hasil']?.toString() ?? '-';
                  final satuan = l['satuan']?.toString() ?? '';
                  final normal = l['nilai_normal']?.toString() ?? '-';
                  
                  final isAbnormal = _checkAbnormal(hasil, normal);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                hasil,
                                style: GoogleFonts.robotoMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isAbnormal ? AppTheme.danger : AppTheme.textPrimary,
                                ),
                              ),
                              if (satuan.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  satuan,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
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

  bool _checkAbnormal(String hasilStr, String normalStr) {
    final cleanHasil = hasilStr.replaceAll(RegExp(r'[^0-9.]'), '');
    final double? hasil = double.tryParse(cleanHasil);
    
    if (hasil != null) {
      if (normalStr.contains('-')) {
        final parts = normalStr.split('-');
        if (parts.length == 2) {
          final low = double.tryParse(parts[0].replaceAll(RegExp(r'[^0-9.]'), ''));
          final high = double.tryParse(parts[1].replaceAll(RegExp(r'[^0-9.]'), ''));
          if (low != null && high != null) {
            return hasil < low || hasil > high;
          }
        }
      } else if (normalStr.contains('<')) {
        final val = double.tryParse(normalStr.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (val != null) {
          return hasil >= val;
        }
      } else if (normalStr.contains('>')) {
        final val = double.tryParse(normalStr.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (val != null) {
          return hasil <= val;
        }
      }
    }
    return false;
  }

  Widget _buildRadiologiTab(RekamMedisController ctrl) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section 1: Hasil Bacaan & Foto
        Row(
          children: [
            const Icon(Icons.description_rounded, color: AppTheme.primary, size: 18),
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
        Row(
          children: [
            const Icon(Icons.settings_system_daydream_rounded, color: AppTheme.accentAlt, size: 18),
            const SizedBox(width: 8),
            Text(
              'Integrasi PACS (Orthanc DICOM)',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (ctrl.isLoadingDicom.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            );
          }
          if (ctrl.dicomStudies.isEmpty) {
            return _emptyStateMini('Tidak ada data DICOM ditemukan di server PACS');
          }
          return Column(
            children: ctrl.dicomStudies.map((study) => _buildDicomCard(ctrl, study)).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildRadiologiCard(Map<String, dynamic> r) {
    final title = r['nm_periksa']?.toString() ?? '-';
    final expertise = r['keterangan']?.toString() ?? '-';
    final fotoUrl = r['foto']?.toString();
    final cleanExpertise = _cleanHtml(expertise);
    
    return Builder(
      builder: (context) {
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
                    const Icon(Icons.image_search_rounded, color: AppTheme.primary, size: 16),
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
                    if (fotoUrl != null && fotoUrl.isNotEmpty && fotoUrl != '-') ...[
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
                                    child: CircularProgressIndicator(color: AppTheme.primary),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppTheme.bgSurface,
                                  height: 160,
                                  child: const Icon(Icons.broken_image, color: AppTheme.textMuted, size: 40),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.zoom_in, color: Colors.white, size: 14),
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
      }
    );
  }

  Widget _buildDicomCard(RekamMedisController ctrl, Map<String, dynamic> study) {
    final studyDesc = study['studyDescription']?.toString() ?? 'Pemeriksaan PACS';
    final studyDateRaw = study['studyDate']?.toString() ?? '-';
    String formattedDate = studyDateRaw;
    if (studyDateRaw.length == 8) {
      formattedDate = '${studyDateRaw.substring(6, 8)}/${studyDateRaw.substring(4, 6)}/${studyDateRaw.substring(0, 4)}';
    }
    final modalityList = study['modality'] as List? ?? [];
    final modality = modalityList.isNotEmpty ? modalityList.join(', ') : 'unknown';
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
                  onTap: () {
                    if (studyId.isNotEmpty) {
                      final url = '${AppConfig.baseUrl}/orthanc/view/$studyId';
                      Get.to(() => DicomViewerPage(url: url, title: studyDesc));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        const Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 14),
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
                  placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 40),
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
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
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
          Icon(Icons.info_outline_rounded, size: 24, color: AppTheme.textMuted.withOpacity(0.6)),
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


  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty || value.toString() == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 10.5, color: AppTheme.textMuted, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
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
            child: Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.textMuted.withOpacity(0.6)),
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
    const credentials = 'sirs:K@sub1ds1rs54';
    final base64Creds = base64.encode(utf8.encode(credentials));
    final headers = {
      'Authorization': 'Basic $base64Creds',
    };

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
          onHttpAuthRequest: (HttpAuthRequest request) {
            request.onProceed(
              const WebViewCredential(
                user: 'sirs',
                password: 'K@sub1ds1rs54',
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url), headers: headers);
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
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
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
