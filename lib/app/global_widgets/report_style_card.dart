import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Kartu laporan dengan gaya yang sama seperti kartu pada halaman Report di
/// tampilan mobile. Dipakai ulang di Dashboard, Laporan, dan Tindakan supaya
/// tampilan data tetap konsisten di semua halaman.
class ReportStyleCard extends StatelessWidget {
  const ReportStyleCard({
    required this.reportId,
    required this.title,
    required this.status,
    this.metaChips = const [],
    this.infoItems = const [],
    this.people = const [],
    this.actions = const [],
    this.onTap,
    super.key,
  });

  final String reportId;
  final String title;
  final String status;
  final List<ReportMetaChip> metaChips;
  final List<ReportInfoItem> infoItems;
  final List<ReportPersonRow> people;
  final List<Widget> actions;
  final VoidCallback? onTap;

  static Color statusColor(String status) {
    return switch (status) {
      'Done' => AppColors.success,
      'On Progress' => AppColors.info,
      _ => AppColors.warning,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.sidebarDark.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        surfaceTintColor: AppColors.white,
        child: InkWell(
          onTap: onTap,
          hoverColor: onTap == null ? Colors.transparent : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(color),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (metaChips.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: metaChips.map(_buildMetaChip).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (infoItems.isNotEmpty) ...[
                      _buildInfoGrid(),
                      if (people.isNotEmpty) const SizedBox(height: 10),
                    ],
                    ...people.map(_buildPersonRow),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          alignment: WrapAlignment.end,
                          children: actions,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reportId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: AppColors.textWeak,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusPill(color),
        ],
      ),
    );
  }

  Widget _buildStatusPill(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetaChip(ReportMetaChip chip) {
    final color = chip.color;
    final foreground = color ?? AppColors.textWeak;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color == null
            ? AppColors.surface
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color == null
              ? AppColors.border
              : color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon, size: 12, color: foreground),
          const SizedBox(width: 5),
          Text(
            chip.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        // Lebar ideal tiap sel ±200px, maksimal 4 kolom dan tidak melebihi
        // jumlah item. Di layar sempit tetap 2 kolom agar kartu tidak tinggi.
        final maxColumns = infoItems.length < 4 ? infoItems.length : 4;
        var columns = (constraints.maxWidth / 200).floor();
        if (constraints.maxWidth >= 240 && maxColumns >= 2 && columns < 2) {
          columns = 2;
        }
        columns = columns.clamp(1, maxColumns).toInt();
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: infoItems
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 12,
                              color: AppColors.textWeak,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textWeak,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildPersonRow(ReportPersonRow person) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(person.icon, size: 13, color: AppColors.primary),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textWeak,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  person.value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportMetaChip {
  const ReportMetaChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;
}

class ReportInfoItem {
  const ReportInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class ReportPersonRow {
  const ReportPersonRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}
