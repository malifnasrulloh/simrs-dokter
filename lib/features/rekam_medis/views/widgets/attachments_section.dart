import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';

/// Renders attachment links/chips parsed from text containing `[Attachment: URL]`.
Widget buildAttachmentsSection(String content) {
  final regExp = RegExp(r'\[Attachment:\s*(.*?)\]');
  final matches = regExp.allMatches(content);
  if (matches.isEmpty) return const SizedBox.shrink();

  final List<String> urls = [];
  for (final m in matches) {
    final matchVal = m.group(1)?.trim();
    if (matchVal != null && matchVal.isNotEmpty) {
      urls.addAll(
          matchVal.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    }
  }

  if (urls.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      Text(
        'Lampiran / Attachments:',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: urls.map((url) {
          final uri = Uri.tryParse(url);
          final filename = uri != null
              ? uri.pathSegments.lastOrNull ?? 'File Lampiran'
              : 'File Lampiran';
          final isImage = url.toLowerCase().endsWith('.png') ||
              url.toLowerCase().endsWith('.jpg') ||
              url.toLowerCase().endsWith('.jpeg') ||
              url.toLowerCase().endsWith('.webp');
          final isPdf = url.toLowerCase().endsWith('.pdf');

          return InkWell(
            onTap: () async {
              final parsedUri = Uri.tryParse(url);
              if (parsedUri != null && await canLaunchUrl(parsedUri)) {
                await launchUrl(parsedUri,
                    mode: LaunchMode.externalApplication);
              } else {
                Get.snackbar('Error', 'Tidak dapat membuka lampiran',
                    backgroundColor: Colors.white, colorText: AppTheme.danger);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isImage
                        ? Icons.image_rounded
                        : isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.attach_file_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        filename,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

/// Helper to remove attachment markers from free text.
String stripAttachment(String content) {
  return content.replaceAll(RegExp(r'\[Attachment:\s*(.*?)\]'), '').trim();
}
