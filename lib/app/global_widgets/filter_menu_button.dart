// lib/app/global_widgets/filter_menu_button.dart
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Satu pilihan pada menu filter.
class FilterMenuEntry {
  const FilterMenuEntry({required this.value, required this.label});

  /// Nilai filter, misal 'all', 'p:Tinggi', atau 's:Open'.
  final String value;

  /// Teks yang tampil pada menu, misal 'Semua' atau 'Prioritas: Tinggi'.
  final String label;
}

/// Entri filter standar untuk daftar laporan/tindakan:
/// filter by prioritas atau status.
List<FilterMenuEntry> reportFilterEntries({bool includeDone = true}) {
  return [
    const FilterMenuEntry(value: 'all', label: 'Semua'),
    const FilterMenuEntry(value: 'p:tinggi', label: 'Prioritas: Tinggi'),
    const FilterMenuEntry(value: 'p:sedang', label: 'Prioritas: Sedang'),
    const FilterMenuEntry(value: 'p:rendah', label: 'Prioritas: Rendah'),
    const FilterMenuEntry(value: 's:open', label: 'Status: Open'),
    const FilterMenuEntry(value: 's:on progress', label: 'Status: On Progress'),
    if (includeDone) const FilterMenuEntry(value: 's:done', label: 'Status: Done'),
  ];
}

/// Cek apakah satu laporan cocok dengan nilai filter aktif.
/// Nilai filter: `'all'`, `'p:<prioritas>'`, atau `'s:<status>'`.
bool matchesReportFilter(Map<String, dynamic> report, String filter) {
  if (filter == 'all') return true;
  if (filter.startsWith('p:')) {
    return _normalizePriority(report['prioritas']?.toString()) ==
        filter.substring(2);
  }
  if (filter.startsWith('s:')) {
    return _normalizeStatus(report['status']?.toString()) == filter.substring(2);
  }
  return true;
}

String _normalizePriority(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'tinggi' || 'high' => 'tinggi',
    'sedang' || 'mid' || 'medium' => 'sedang',
    'rendah' || 'low' => 'rendah',
    _ => '',
  };
}

String _normalizeStatus(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'open' => 'open',
    'on progress' || 'on progres' || 'proses' || 'in progress' =>
      'on progress',
    'done' || 'selesai' => 'done',
    _ => '',
  };
}

/// Tombol filter untuk daftar (card) laporan/tindakan.
///
/// Saat diklik akan muncul menu pilihan filter, misalnya
/// "Filter by: Semua / Prioritas / Status / Kategori".
class FilterMenuButton extends StatelessWidget {
  const FilterMenuButton({
    super.key,
    required this.value,
    required this.entries,
    required this.onSelected,
    this.tooltip = 'Filter daftar',
  });

  /// Nilai filter yang sedang aktif.
  final String value;

  /// Daftar pilihan filter.
  final List<FilterMenuEntry> entries;

  /// Dipanggil saat pengguna memilih salah satu filter.
  final ValueChanged<String> onSelected;

  final String tooltip;

  String get _activeLabel {
    for (final entry in entries) {
      if (entry.value == value) return entry.label;
    }
    return entries.first.label;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      initialValue: value,
      color: AppColors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      constraints: const BoxConstraints(minWidth: 230),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final entry in entries)
          PopupMenuItem(
            value: entry.value,
            height: 42,
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: entry.value == value
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    entry.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              _activeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
