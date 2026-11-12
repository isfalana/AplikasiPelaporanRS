// lib/app/global_widgets/filter_menu_button.dart
import 'package:flutter/material.dart';

import '../core/theme/app_buttons.dart';
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
    if (includeDone)
      const FilterMenuEntry(value: 's:done', label: 'Status: Done'),
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
    return _normalizeStatus(report['status']?.toString()) ==
        filter.substring(2);
  }
  return true;
}

/// Cek apakah satu laporan cocok dengan beberapa filter sekaligus.
///
/// Filter prioritas dan status digabung dengan logika AND antar kelompok,
/// sedangkan pilihan di dalam kelompok yang sama memakai logika OR.
/// Himpunan kosong berarti semua laporan lolos.
bool matchesReportFilters(Map<String, dynamic> report, Set<String> filters) {
  if (filters.isEmpty) return true;

  final priorities = <String>{};
  final statuses = <String>{};
  for (final filter in filters) {
    if (filter.startsWith('p:')) {
      priorities.add(filter.substring(2));
    } else if (filter.startsWith('s:')) {
      statuses.add(filter.substring(2));
    }
  }

  final priority = _normalizePriority(report['prioritas']?.toString());
  final status = _normalizeStatus(report['status']?.toString());
  final priorityMatch = priorities.isEmpty || priorities.contains(priority);
  final statusMatch = statuses.isEmpty || statuses.contains(status);
  return priorityMatch && statusMatch;
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
    'on progress' || 'on progres' || 'proses' || 'in progress' => 'on progress',
    'done' || 'selesai' => 'done',
    _ => '',
  };
}

/// Tombol filter untuk daftar laporan/tindakan.
///
/// Secara default menampilkan menu popup. Jika [bottomSheet] aktif, filter
/// ditampilkan lewat bottom sheet dengan pilihan berbentuk chip.
class FilterMenuButton extends StatelessWidget {
  const FilterMenuButton({
    super.key,
    required this.value,
    required this.entries,
    required this.onSelected,
    this.tooltip = 'Filter daftar',
    this.bottomSheet = false,
  });

  /// Nilai filter yang sedang aktif.
  final String value;

  /// Daftar pilihan filter.
  final List<FilterMenuEntry> entries;

  /// Dipanggil saat pengguna memilih salah satu filter.
  final ValueChanged<String> onSelected;

  final String tooltip;

  /// Tampilkan filter sebagai bottom sheet (lebih nyaman di layar sentuh).
  final bool bottomSheet;

  String get _activeLabel {
    for (final entry in entries) {
      if (entry.value == value) return entry.label;
    }
    return entries.first.label;
  }

  bool get _isActive => value != 'all';

  @override
  Widget build(BuildContext context) {
    final trigger = _buildTrigger();

    if (!bottomSheet) {
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
        child: trigger,
      );
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openFilterSheet(context),
          child: trigger,
        ),
      ),
    );
  }

  Widget _buildTrigger() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isActive
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isActive
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isActive ? Icons.filter_alt_rounded : Icons.filter_list_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _activeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isActive ? AppColors.primary : AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (context) => _FilterSheet(entries: entries, initialValue: value),
    );
    if (selected != null && selected != value) onSelected(selected);
  }
}

/// Tombol filter multi-pilih untuk daftar laporan/tindakan.
///
/// Menampilkan bottom sheet dengan chip yang bisa dipilih lebih dari satu,
/// baik untuk prioritas maupun status.
class MultiFilterMenuButton extends StatelessWidget {
  const MultiFilterMenuButton({
    super.key,
    required this.selectedValues,
    required this.entries,
    required this.onSelected,
    this.tooltip = 'Filter daftar',
  });

  /// Nilai filter yang sedang aktif. Kosong berarti semua data.
  final Set<String> selectedValues;

  /// Daftar pilihan filter.
  final List<FilterMenuEntry> entries;

  /// Dipanggil saat pengguna menekan "Terapkan".
  final ValueChanged<Set<String>> onSelected;

  final String tooltip;

  bool get _isActive => selectedValues.isNotEmpty;

  String get _activeLabel {
    if (selectedValues.isEmpty) return 'Semua';
    final labels = <String>[];
    for (final entry in entries) {
      if (!selectedValues.contains(entry.value)) continue;
      final parts = entry.label.split(':');
      labels.add(
        parts.length > 1 ? parts.sublist(1).join(':').trim() : entry.label,
      );
    }
    if (labels.isEmpty) return 'Semua';
    if (labels.length <= 2) return labels.join(' · ');
    return 'Filter aktif';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openFilterSheet(context),
          child: _buildTrigger(),
        ),
      ),
    );
  }

  Widget _buildTrigger() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isActive
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isActive
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isActive ? Icons.filter_alt_rounded : Icons.filter_list_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _activeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isActive ? AppColors.primary : AppColors.textStrong,
            ),
          ),
          if (_isActive) ...[
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${selectedValues.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (context) =>
          _MultiFilterSheet(entries: entries, initialValues: selectedValues),
    );
    if (selected == null) return;
    if (selected.length == selectedValues.length &&
        selected.containsAll(selectedValues)) {
      return;
    }
    onSelected(selected);
  }
}

class _MultiFilterSheet extends StatefulWidget {
  const _MultiFilterSheet({required this.entries, required this.initialValues});

  final List<FilterMenuEntry> entries;
  final Set<String> initialValues;

  @override
  State<_MultiFilterSheet> createState() => _MultiFilterSheetState();
}

class _MultiFilterSheetState extends State<_MultiFilterSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialValues};
  }

  @override
  Widget build(BuildContext context) {
    final allEntry = _findAllEntry();
    final groups = _groupEntries();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pilih satu atau lebih prioritas dan status.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textWeak,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup filter',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textWeak,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allEntry != null) ...[
                      _FilterChip(
                        label: allEntry.label,
                        selected: _selected.isEmpty,
                        onTap: () => setState(_selected.clear),
                      ),
                      const SizedBox(height: 20),
                    ],
                    for (final group in groups) ...[
                      Text(
                        group.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWeak,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final choice in group.choices)
                            _FilterChip(
                              label: choice.label,
                              selected: _selected.contains(choice.value),
                              onTap: () => setState(() {
                                if (!_selected.remove(choice.value)) {
                                  _selected.add(choice.value);
                                }
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(_selected.clear),
                      style: AppButtons.outlined,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop({..._selected}),
                      style: AppButtons.primary,
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  FilterMenuEntry? _findAllEntry() {
    for (final entry in widget.entries) {
      if (entry.value == 'all') return entry;
    }
    return null;
  }

  List<_FilterGroup> _groupEntries() {
    final groups = <String, List<_FilterChoice>>{};
    for (final entry in widget.entries) {
      if (entry.value == 'all') continue;
      final parts = entry.label.split(':');
      final hasGroup = parts.length > 1;
      final title = hasGroup ? parts.first.trim() : 'Pilihan';
      final label = hasGroup
          ? parts.sublist(1).join(':').trim()
          : entry.label.trim();
      groups
          .putIfAbsent(title, () => [])
          .add(_FilterChoice(value: entry.value, label: label));
    }
    return [
      for (final group in groups.entries)
        _FilterGroup(title: group.key, choices: group.value),
    ];
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.entries, required this.initialValue});

  final List<FilterMenuEntry> entries;
  final String initialValue;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final allEntry = _findAllEntry();
    final groups = _groupEntries();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pilih satu filter prioritas atau status.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textWeak,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup filter',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textWeak,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allEntry != null) ...[
                      _FilterChip(
                        label: allEntry.label,
                        selected: _selected == allEntry.value,
                        onTap: () => setState(() => _selected = allEntry.value),
                      ),
                      const SizedBox(height: 20),
                    ],
                    for (final group in groups) ...[
                      Text(
                        group.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWeak,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final choice in group.choices)
                            _FilterChip(
                              label: choice.label,
                              selected: _selected == choice.value,
                              onTap: () =>
                                  setState(() => _selected = choice.value),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _selected = 'all'),
                      style: AppButtons.outlined,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      style: AppButtons.primary,
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  FilterMenuEntry? _findAllEntry() {
    for (final entry in widget.entries) {
      if (entry.value == 'all') return entry;
    }
    return null;
  }

  List<_FilterGroup> _groupEntries() {
    final groups = <String, List<_FilterChoice>>{};
    for (final entry in widget.entries) {
      if (entry.value == 'all') continue;
      final parts = entry.label.split(':');
      final hasGroup = parts.length > 1;
      final title = hasGroup ? parts.first.trim() : 'Pilihan';
      final label = hasGroup
          ? parts.sublist(1).join(':').trim()
          : entry.label.trim();
      groups
          .putIfAbsent(title, () => [])
          .add(_FilterChoice(value: entry.value, label: label));
    }
    return [
      for (final group in groups.entries)
        _FilterGroup(title: group.key, choices: group.value),
    ];
  }
}

class _FilterGroup {
  const _FilterGroup({required this.title, required this.choices});

  final String title;
  final List<_FilterChoice> choices;
}

class _FilterChoice {
  const _FilterChoice({required this.value, required this.label});

  final String value;
  final String label;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
