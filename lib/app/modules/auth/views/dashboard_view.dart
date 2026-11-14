import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dashboard_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/filter_menu_button.dart';
import '../../../global_widgets/main_layout_widget.dart';
import '../../../global_widgets/report_style_card.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWidget(
      title: 'Dashboard',
      desktopActions: [
        IconButton(
          tooltip: 'Muat ulang data',
          onPressed: controller.fetchDashboardData,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textWeak),
        ),
        const SizedBox(width: 8),
      ],
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 600 ? 18.0 : 32.0;
          final availableWidth = constraints.maxWidth - horizontalPadding * 2;
          final columnCount = availableWidth >= 900
              ? 3
              : availableWidth >= 560
              ? 2
              : 1;
          final cardWidth =
              (availableWidth - (columnCount - 1) * 16) / columnCount;
          // Kartu prioritas memakai grid agar tidak melebar penuh di desktop.
          final priorityColumnCount = constraints.maxWidth >= 1400
              ? 3
              : constraints.maxWidth >= 900
              ? 2
              : 1;
          final priorityCardWidth =
              (availableWidth - (priorityColumnCount - 1) * 16) /
              priorityColumnCount;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    'Selamat datang, ${controller.unitName.value}',
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Berikut ringkasan laporan dan tindak lanjut unit Anda.',
                  style: TextStyle(color: AppColors.textWeak, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: Obx(
                        () => _buildMetricCard(
                          'Laporan Terkirim',
                          controller.jumlahLaporan.toString(),
                          AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: Obx(
                        () => _buildMetricCard(
                          'Pesan Tindakan',
                          controller.jumlahPesanTindakan.toString(),
                          AppColors.warning,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: Obx(
                        () => _buildMetricCard(
                          'Tindakan Selesai',
                          controller.jumlahTindakanSelesai.toString(),
                          AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Prioritas tindak lanjut',
                        style: TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => MultiFilterMenuButton(
                        selectedValues: controller.priorityFilters.toSet(),
                        entries: reportFilterEntries(),
                        onSelected: (values) {
                          controller.priorityFilters
                            ..clear()
                            ..addAll(values);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final priorityReports =
                      controller.listLaporan
                          .where(
                            (laporan) => matchesReportFilters(
                              laporan,
                              controller.priorityFilters,
                            ),
                          )
                          .toList()
                        ..sort((first, second) {
                          int priority(Map<String, dynamic> laporan) {
                            return switch (controller.priorityLabel(laporan)) {
                              'Tinggi' => 0,
                              'Sedang' => 1,
                              'Rendah' => 2,
                              _ => 3,
                            };
                          }

                          final priorityOrder = priority(first)
                              .compareTo(priority(second));
                          if (priorityOrder != 0) {
                            return priorityOrder;
                          }

                          int statusOrder(Map<String, dynamic> laporan) {
                            return switch (controller.statusLabel(laporan)) {
                              'Open' => 0,
                              'On Progress' => 1,
                              'Done' => 2,
                              _ => 3,
                            };
                          }

                          return statusOrder(first)
                              .compareTo(statusOrder(second));
                        });

                  if (controller.isLoading.value &&
                      controller.listLaporan.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  }

                  if (priorityReports.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: priorityReports
                        .map(
                          (laporan) => SizedBox(
                            width: priorityCardWidth,
                            child: _buildReportCard(laporan),
                          ),
                        )
                        .toList(),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color borderColor) {
    final icon = switch (title) {
      'Laporan Terkirim' => Icons.send_outlined,
      'Pesan Tindakan' => Icons.mark_email_unread_outlined,
      'Tindakan Selesai' => Icons.task_alt_outlined,
      _ => Icons.insights_outlined,
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: borderColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> laporan) {
    final status = controller.statusLabel(laporan);
    final prioritas = controller.priorityLabel(laporan);
    final priorityColor = switch (prioritas) {
      'Tinggi' => AppColors.error,
      'Sedang' => AppColors.warning,
      'Rendah' => AppColors.success,
      _ => AppColors.textWeak,
    };
    final kategori =
        laporan['id_kategori']?.toString().trim().isNotEmpty == true
        ? laporan['id_kategori'].toString()
        : '-';
    final deadline = laporan['deadline']?.toString().trim();
    final lastUpdatedBy =
        laporan['last_update_by']?.toString() ??
        laporan['lastUpdateBy']?.toString() ??
        laporan['update_by']?.toString() ??
        laporan['updateBy']?.toString() ??
        '-';

    return ReportStyleCard(
      reportId: laporan['id_laporan']?.toString() ?? 'Laporan',
      title: laporan['perihal']?.toString() ?? 'Tanpa perihal',
      status: status,
      metaChips: [
        ReportMetaChip(icon: Icons.folder_outlined, label: kategori),
        if (prioritas != '-')
          ReportMetaChip(
            icon: Icons.flag_outlined,
            label: prioritas,
            color: priorityColor,
          ),
      ],
      infoItems: [
        ReportInfoItem(
          icon: Icons.calendar_today_outlined,
          label: 'Tanggal laporan',
          value: controller.reportDate(laporan),
        ),
        ReportInfoItem(
          icon: Icons.event_outlined,
          label: 'Deadline',
          value: deadline == null || deadline.isEmpty ? '-' : deadline,
        ),
        ReportInfoItem(
          icon: Icons.history_outlined,
          label: 'Last update by',
          value: lastUpdatedBy,
        ),
      ],
      people: [
        ReportPersonRow(
          icon: Icons.account_circle_outlined,
          label: 'Pelapor',
          value: controller.reporter(laporan),
        ),
        ReportPersonRow(
          icon: Icons.assignment_ind_outlined,
          label: 'PIC',
          value: controller.reportPic(laporan),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, color: AppColors.textWeak, size: 30),
          SizedBox(height: 10),
          Text(
            'Tidak ada tindak lanjut yang perlu diprioritaskan.',
            style: TextStyle(color: AppColors.textWeak, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
