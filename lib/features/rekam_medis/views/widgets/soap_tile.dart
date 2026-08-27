import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/rekam_medis_controller.dart';
import '../dialogs/soap_form_sheet.dart';

/// Expandable card representing a single clinical SOAP entry with vitals visualization.
class SoapTile extends StatefulWidget {
  const SoapTile({
    required super.key,
    required this.data,
    required this.initiallyExpanded,
  });

  final Map<String, dynamic> data;
  final bool initiallyExpanded;

  @override
  State<SoapTile> createState() => _SoapTileState();
}

class _SoapTileState extends State<SoapTile> {
  late bool _isExpanded;
  final _ctrl = Get.find<RekamMedisController>();

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    final uniqueId = '${data['tanggal']}_${data['jam']}_${data['petugas']}';
    if (!_ctrl.expandedStates.containsKey(uniqueId)) {
      _ctrl.expandedStates[uniqueId] = widget.initiallyExpanded;
    }
    _isExpanded = _ctrl.expandedStates[uniqueId]!;
  }

  @override
  void didUpdateWidget(covariant SoapTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final data = widget.data;
      final uniqueId = '${data['tanggal']}_${data['jam']}_${data['petugas']}';
      if (!_ctrl.expandedStates.containsKey(uniqueId)) {
        _ctrl.expandedStates[uniqueId] = widget.initiallyExpanded;
      }
      _isExpanded = _ctrl.expandedStates[uniqueId]!;
    }
  }

  bool _hasVal(String key) {
    final v = widget.data[key]?.toString() ?? '-';
    return v.isNotEmpty && v != '-';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final formattedDate = data['tanggal']?.toString() ?? '-';
    final formattedTime = data['jam']?.toString() ?? '-';
    final timeStr = formattedTime == '-' ? '' : ' pukul $formattedTime';
    final petugas = data['petugas']?.toString() ?? 'Petugas Medis';
    final jabatan = data['jabatan']?.toString() ?? '';
    final uniqueId = '${data['tanggal']}_${data['jam']}_${data['petugas']}';

    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.02),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            key: ValueKey(uniqueId),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (v) {
              setState(() => _isExpanded = v);
              _ctrl.expandedStates[uniqueId] = v;
            },
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sticky_note_2_rounded,
                  color: AppTheme.primary, size: 20),
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
              jabatan.isNotEmpty && jabatan != '-'
                  ? '$petugas • $jabatan'
                  : 'Petugas: $petugas',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
              ),
            ),
            trailing: Obx(() {
              final authCtrl = Get.find<AuthController>();
              final myNip = authCtrl.user.value?['nip'] ??
                  authCtrl.user.value?['username'] ??
                  '';
              final recordNip = data['nip']?.toString() ?? '';
              final isOwnRecord = recordNip == myNip && myNip.isNotEmpty;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOwnRecord && _ctrl.writeEnabled) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: AppTheme.primary, size: 18),
                      tooltip: 'Ubah SOAP',
                      onPressed: () =>
                          showSoapForm(context, _ctrl, existingData: data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.danger, size: 18),
                      tooltip: 'Hapus SOAP',
                      onPressed: () => confirmDeleteSoap(
                          context, _ctrl, formattedDate, formattedTime),
                    ),
                  ],
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ],
              );
            }),
            children: [
              const Divider(height: 24, thickness: 1, color: AppTheme.divider),

              // ── S: SUBJEKTIF ──────────────────────────────────────
              _soapLabel('S', 'Subjektif', AppTheme.primary),
              const SizedBox(height: 10),
              _clinicalSection('Anamnesis', [
                _row('Keluhan Utama', data['keluhan_utama']),
                if (_hasVal('rps'))
                  _row('Riwayat Penyakit Sekarang (RPS)', data['rps']),
                if (_hasVal('rpd'))
                  _row('Riwayat Penyakit Dahulu (RPD)', data['rpd']),
                if (_hasVal('rpk'))
                  _row('Riwayat Penyakit Keluarga (RPK)', data['rpk']),
                if (_hasVal('rpo'))
                  _row('Riwayat Pengobatan (RPO)', data['rpo']),
                if (_hasVal('hubungan'))
                  _row('Diceritakan Oleh', data['hubungan']),
                _row('Alergi', data['alergi']),
              ]),

              const SizedBox(height: 16),

              // ── O: OBJEKTIF ───────────────────────────────────────
              _soapLabel('O', 'Objektif', AppTheme.accent),
              const SizedBox(height: 10),
              _clinicalSection('Tanda Vital', [
                _vitalGrid(data),
                _buildVitalsChart(data),
              ]),
              if (_hasVal('keadaan') ||
                  _hasVal('kesadaran') ||
                  _hasVal('gcs') ||
                  _hasVal('bb') ||
                  _hasVal('tb') ||
                  _hasVal('lingkar_perut')) ...[
                const SizedBox(height: 12),
                _clinicalSection('Keadaan Umum', [
                  if (_hasVal('keadaan')) _row('Keadaan Umum', data['keadaan']),
                  if (_hasVal('kesadaran'))
                    _row('Kesadaran', data['kesadaran']),
                  if (_hasVal('gcs')) _row('GCS', data['gcs']),
                  if (_hasVal('bb')) _row('Berat Badan', '${data['bb']} kg'),
                  if (_hasVal('tb')) _row('Tinggi Badan', '${data['tb']} cm'),
                  if (_hasVal('lingkar_perut'))
                    _row('Lingkar Perut', '${data['lingkar_perut']} cm'),
                ]),
              ],
              if (_hasVal('pemeriksaan_fisik')) ...[
                const SizedBox(height: 12),
                _clinicalSection('Pemeriksaan Fisik', [
                  _row('Hasil Pemeriksaan', data['pemeriksaan_fisik']),
                ]),
              ],
              if (_hasVal('lab') || _hasVal('rad') || _hasVal('penunjang')) ...[
                const SizedBox(height: 12),
                _clinicalSection('Penunjang', [
                  if (_hasVal('lab')) _row('Laboratorium', data['lab']),
                  if (_hasVal('rad')) _row('Radiologi', data['rad']),
                  if (_hasVal('penunjang')) _row('Lainnya', data['penunjang']),
                ]),
              ],

              const SizedBox(height: 16),

              // ── A: ASSESSMENT ─────────────────────────────────────
              _soapLabel('A', 'Assessment', AppTheme.warning),
              const SizedBox(height: 10),
              _clinicalSection('Penilaian / Diagnosis', [
                _row('Diagnosis / Penilaian', data['diagnosis']),
              ]),

              const SizedBox(height: 16),

              // ── P: PLAN ───────────────────────────────────────────
              _soapLabel('P', 'Plan', AppTheme.success),
              const SizedBox(height: 10),
              _clinicalSection('Rencana & Tindak Lanjut', [
                if (_hasVal('tata')) _row('Tata Laksana / RTL', data['tata']),
                if (_hasVal('instruksi')) _row('Instruksi', data['instruksi']),
                if (_hasVal('evaluasi')) _row('Evaluasi', data['evaluasi']),
                if (_hasVal('edukasi')) _row('Edukasi', data['edukasi']),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _soapLabel(String letter, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            letter,
            style: GoogleFonts.robotoMono(
                fontSize: 14, fontWeight: FontWeight.w900, color: color),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13.5, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _clinicalSection(String title, List<Widget> children) {
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
            Text(title,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _vitalGrid(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: [
        _vitalCard('Tekanan Darah', data['td'], 'mmHg', Icons.speed_rounded,
            _evalTensi(data['td'])),
        _vitalCard('Nadi', data['nadi'], 'x/mnt', Icons.favorite_rounded,
            _evalNadi(data['nadi'])),
        _vitalCard('Respirasi (RR)', data['rr'], 'x/mnt', Icons.air_rounded,
            _evalRR(data['rr'])),
        _vitalCard('Suhu Tubuh', data['suhu'], '°C', Icons.thermostat_rounded,
            _evalSuhu(data['suhu'])),
        _vitalCard('SpO₂', data['spo'], '%', Icons.bloodtype_rounded,
            _evalSpo(data['spo'])),
      ],
    );
  }

  Widget _vitalCard(String label, dynamic value, String unit, IconData icon,
      Color statusColor) {
    final displayValue =
        (value == null || value.toString().isEmpty || value.toString() == '-')
            ? '-'
            : value.toString();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 14, color: statusColor),
              Text(unit,
                  style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(displayValue,
              style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 8.5,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty || value.toString() == '-') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value.toString(),
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.4)),
        ],
      ),
    );
  }

  Color _evalTensi(dynamic td) {
    if (td == null) return AppTheme.textMuted;
    final sys = int.tryParse(
        td.toString().split('/')[0].replaceAll(RegExp(r'[^0-9]'), ''));
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
      return (n > 100 || n < 60) ? AppTheme.warning : AppTheme.success;
    }
    return AppTheme.success;
  }

  Color _evalRR(dynamic val) {
    if (val == null) return AppTheme.textMuted;
    final rr = int.tryParse(val.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    if (rr != null) {
      return (rr > 22 || rr < 12) ? AppTheme.warning : AppTheme.success;
    }
    return AppTheme.success;
  }

  Color _evalSuhu(dynamic val) {
    if (val == null) return AppTheme.textMuted;
    final s =
        double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
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
    if (spo != null) return spo < 95 ? AppTheme.danger : AppTheme.success;
    return AppTheme.success;
  }

  Widget _buildVitalsChart(Map<String, dynamic> soap) {
    return Obx(() {
      final points = _ctrl.vitalsChartData;
      if (points.length < 2) {
        return const SizedBox.shrink();
      }

      final tglStr = soap['tanggal']?.toString() ?? '1970-01-01';
      final jamStr = soap['jam']?.toString() ?? '00:00:00';
      DateTime currentSoapTime;
      try {
        currentSoapTime = DateTime.parse('$tglStr $jamStr');
      } catch (_) {
        currentSoapTime = DateTime.tryParse(tglStr) ?? DateTime(1970);
      }

      final filteredPoints = points
          .where((p) =>
              p.dateTime.isBefore(currentSoapTime) ||
              p.dateTime.isAtSameMomentAs(currentSoapTime))
          .toList();

      if (filteredPoints.length < 2) {
        return const SizedBox.shrink();
      }

      final type = _ctrl.activeChartType.value;

      List<FlSpot> spots1 = [];
      List<FlSpot> spots2 = [];

      double minY = 0;
      double maxY = 100;
      String label1 = '';
      String label2 = '';
      Color color1 = AppTheme.primary;
      Color color2 = AppTheme.accent;

      if (type == 0) {
        label1 = 'Sistole';
        label2 = 'Diastole';
        color1 = AppTheme.danger;
        color2 = AppTheme.info;
        for (int i = 0; i < filteredPoints.length; i++) {
          if (filteredPoints[i].systole != null) {
            spots1.add(FlSpot(i.toDouble(), filteredPoints[i].systole!));
          }
          if (filteredPoints[i].diastole != null) {
            spots2.add(FlSpot(i.toDouble(), filteredPoints[i].diastole!));
          }
        }
        minY = 40;
        maxY = 200;
      } else if (type == 1) {
        label1 = 'Suhu (°C)';
        color1 = AppTheme.accent;
        for (int i = 0; i < filteredPoints.length; i++) {
          if (filteredPoints[i].suhu != null) {
            spots1.add(FlSpot(i.toDouble(), filteredPoints[i].suhu!));
          }
        }
        minY = 35;
        maxY = 42;
      } else {
        label1 = 'Nadi (bpm)';
        label2 = 'Respirasi (rr)';
        color1 = AppTheme.success;
        color2 = AppTheme.warning;
        for (int i = 0; i < filteredPoints.length; i++) {
          if (filteredPoints[i].nadi != null) {
            spots1.add(FlSpot(i.toDouble(), filteredPoints[i].nadi!));
          }
          if (filteredPoints[i].rr != null) {
            spots2.add(FlSpot(i.toDouble(), filteredPoints[i].rr!));
          }
        }
      }

      // Calculate dynamic Y limits to prevent clipping
      if (spots1.isNotEmpty || spots2.isNotEmpty) {
        final allY = [
          ...spots1.map((s) => s.y),
          ...spots2.map((s) => s.y),
        ];
        if (allY.isNotEmpty) {
          final minVal = allY.reduce(math.min);
          final maxVal = allY.reduce(math.max);
          if (type == 1) {
            minY = math.max(34.0, minVal - 0.5);
            maxY = maxVal + 0.5;
          } else {
            minY = math.max(0.0, minVal - 10.0);
            maxY = maxVal + 10.0;
          }
        }
      }

      if (minY == maxY) {
        minY -= 1.0;
        maxY += 1.0;
      }

      if (spots1.isEmpty && spots2.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tren TTV',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    if (spots1.isNotEmpty) ...[
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color1, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(label1,
                          style: GoogleFonts.outfit(
                              fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                    if (spots2.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color2, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(label2,
                          style: GoogleFonts.outfit(
                              fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _chartTabButton('TD', 0, type),
                const SizedBox(width: 8),
                _chartTabButton('Suhu', 1, type),
                const SizedBox(width: 8),
                _chartTabButton('Nadi/RR', 2, type),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: math.max(MediaQuery.of(context).size.width - 64,
                    filteredPoints.length * 52.0),
                height: 160,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.divider.withValues(alpha: 0.5),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final int idx = value.toInt();
                              if (idx >= 0 && idx < filteredPoints.length) {
                                final dt = filteredPoints[idx].dateTime;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    DateFormat('dd/MM').format(dt),
                                    style: GoogleFonts.outfit(
                                        fontSize: 8,
                                        color: AppTheme.textMuted),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: GoogleFonts.outfit(
                                    fontSize: 8, color: AppTheme.textMuted),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppTheme.primary,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final idx = spot.x.toInt();
                              final dateStr = DateFormat('dd MMM yyyy HH:mm')
                                  .format(filteredPoints[idx].dateTime);
                              return LineTooltipItem(
                                '$dateStr\n${spot.barIndex == 1 ? label2 : label1}: ${spot.y.toStringAsFixed(1)}',
                                GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        if (spots1.isNotEmpty)
                          LineChartBarData(
                            spots: spots1,
                            isCurved: false,
                            barWidth: 2.5,
                            color: color1,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 3,
                                color: color1,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              ),
                            ),
                          ),
                        if (spots2.isNotEmpty)
                          LineChartBarData(
                            spots: spots2,
                            isCurved: false,
                            barWidth: 2.5,
                            color: color2,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 3,
                                color: color2,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _chartTabButton(String text, int index, int activeIdx) {
    final active = index == activeIdx;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _ctrl.activeChartType.value = index,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.bgDark,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: active ? AppTheme.primary : AppTheme.divider),
          ),
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
