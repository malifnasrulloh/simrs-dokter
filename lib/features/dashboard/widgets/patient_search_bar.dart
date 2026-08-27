import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/google_fonts.dart';

/// Reusable search bar for filtering patient lists.
class PatientSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  const PatientSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Cari nama, No. RM, atau ruangan...',
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: GoogleFonts.outfit(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.outfit(
            color: AppTheme.textMuted,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textMuted,
            size: 18,
          ),
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    controller.clear();
                    onClear();
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
}

/// Helper function to filter patient lists by query across name, RM, room, and doctor.
List<Map<String, dynamic>> filterPatientList(
  List<Map<String, dynamic>> source,
  String query,
) {
  if (query.isEmpty) return source;
  final q = query.toLowerCase().trim();

  return source.where((p) {
    final name = (p['nm_pasien'] ?? '').toString().toLowerCase();
    final rm = (p['no_rkm_medis'] ?? '').toString().toLowerCase();
    final kamar = (p['kamar'] ?? p['nm_poli'] ?? '').toString().toLowerCase();
    final dokter = (p['nm_dokter'] ?? '').toString().toLowerCase();
    return name.contains(q) ||
        rm.contains(q) ||
        kamar.contains(q) ||
        dokter.contains(q);
  }).toList();
}
