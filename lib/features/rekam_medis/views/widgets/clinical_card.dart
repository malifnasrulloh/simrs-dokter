import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_fonts.dart';

/// Reusable card tile for clinical items (diagnoses, procedures, prescriptions, etc.).
Widget buildListCard({
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
          color: AppTheme.textPrimary.withValues(alpha: 0.03),
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
            color: iconColor.withValues(alpha: 0.08),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}

/// Reusable empty state view for tabs.
Widget buildEmptyState(String message, {IconData icon = Icons.folder_open_rounded}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon,
            size: 48, color: AppTheme.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text(
          message,
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// Standardized shimmer placeholder for loading states.
Widget buildShimmerLoader() {
  return Shimmer.fromColors(
    baseColor: AppTheme.divider,
    highlightColor: AppTheme.bgDark.withValues(alpha: 0.5),
    child: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
