import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';
import '../../controllers/rekam_medis_controller.dart';
import '../widgets/clinical_card.dart';

/// Radiology tab displaying imaging reports, doctor readings/expertise, and full-screen photo viewer.
class RadiologiTab extends StatelessWidget {
  final RekamMedisController ctrl;

  const RadiologiTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingRad.value) {
        return buildShimmerLoader();
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded,
                  color: AppTheme.primary, size: 18),
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
            ...ctrl.radiologi.map((r) => _buildRadiologiCard(context, r)),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: AppTheme.divider),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _buildRadiologiCard(BuildContext context, Map<String, dynamic> r) {
    final title = r['nm_periksa']?.toString() ?? '-';
    final expertise = r['keterangan']?.toString() ?? '-';
    final fotoUrl = r['foto']?.toString();
    final cleanExpertise = _cleanHtml(expertise);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                const Icon(Icons.image_search_rounded,
                    color: AppTheme.primary, size: 16),
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
                if (fotoUrl != null &&
                    fotoUrl.isNotEmpty &&
                    fotoUrl != '-') ...[
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
                                child: CircularProgressIndicator(
                                    color: AppTheme.primary),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.bgSurface,
                              height: 160,
                              child: const Icon(Icons.broken_image,
                                  color: AppTheme.textMuted, size: 40),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.zoom_in,
                                    color: Colors.white, size: 14),
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
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 40),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Text(
                title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
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
          Icon(Icons.info_outline_rounded,
              size: 24, color: AppTheme.textMuted.withValues(alpha: 0.6)),
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
}
