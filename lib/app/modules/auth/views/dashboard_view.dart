import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dashboard_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../global_widgets/sidebar_widgets.dart';
import '../../../routes/app_pages.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: isMobile
              ? SidebarWidget.mobileAppBar(
                  title: 'Dashboard',
                  actions: [
                    IconButton(
                      tooltip: 'Keluar',
                      onPressed: controller.logout,
                      icon: const Icon(Icons.logout_outlined),
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              : null,
          drawer: isMobile
              ? SidebarWidget.mobileDrawer(
                  child: _buildSidebar(isCollapsed: false, isMobile: true),
                )
              : null,
          body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return _buildContent();
  }

  Widget _buildDesktopLayout() {
    return Obx(() {
      final isCollapsed = controller.isSidebarCollapsed.value;
      return Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: isCollapsed ? 76 : 248,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sidebarIsCollapsed = constraints.maxWidth < 100;
                return _buildSidebar(
                  isCollapsed: sidebarIsCollapsed,
                  isMobile: false,
                );
              },
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildDesktopAppBar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDesktopAppBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: controller.isSidebarCollapsed.value
                ? 'Buka sidebar'
                : 'Ciutkan sidebar',
            onPressed: () {
              controller.isSidebarCollapsed.toggle();
            },
            icon: const Icon(Icons.menu_rounded, color: AppColors.textStrong),
          ),
          const SizedBox(width: 12),
          const Text(
            'Dashboard',
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Muat ulang data',
            onPressed: controller.fetchDashboardData,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textWeak),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout_outlined, size: 18),
            label: const Text('Keluar'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textWeak),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isCollapsed, required bool isMobile}) {
    return Obx(
      () => SidebarWidget(
        isCollapsed: isCollapsed,
        isMobile: isMobile,
        currentRoute: Routes.DASHBOARD,
        unitName: controller.unitName.value,
        employeeName: controller.employeeName.value,
        isMasterExpanded: controller.isMasterExpanded.value,
        onMasterMenuTap: () {
          if (isCollapsed) {
            controller.isSidebarCollapsed.value = false;
            controller.isMasterExpanded.value = true;
          } else {
            controller.isMasterExpanded.toggle();
          }
        },
      ),
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
                        controller.jumlahLaporan.value.toString(),
                        AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: Obx(
                      () => _buildMetricCard(
                        'Pesan Tindakan',
                        controller.jumlahPesanTindakan.value.toString(),
                        AppColors.warning,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: Obx(
                      () => _buildMetricCard(
                        'Tindakan Selesai',
                        controller.jumlahTindakanSelesai.value.toString(),
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
                  if (ResponsiveLayout.isMobile(context))
                    IconButton(
                      tooltip: 'Muat ulang data',
                      onPressed: controller.fetchDashboardData,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.textWeak,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() {
                final priorityReports = controller.listLaporan.toList()
                  ..sort((first, second) {
                    int priority(Map<String, dynamic> laporan) {
                      return switch (laporan['prioritas']
                          ?.toString()
                          .toLowerCase()) {
                        'high' => 0,
                        'mid' => 1,
                        'low' => 2,
                        _ => 3,
                      };
                    }

                    final priorityOrder = priority(first)
                        .compareTo(priority(second));
                    if (priorityOrder != 0) {
                      return priorityOrder;
                    }

                    int statusOrder(Map<String, dynamic> laporan) {
                      return switch (laporan['status']
                          ?.toString()
                          .toLowerCase()) {
                        'open' => 0,
                        'on progress' => 1,
                        'done' => 2,
                        _ => 3,
                      };
                    }

                    return statusOrder(first).compareTo(statusOrder(second));
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

                return Column(
                  children: priorityReports
                      .map((laporan) => _buildReportCard(laporan))
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
    final status = laporan['status']?.toString() ?? 'Open';
    final statusColor = switch (status.toLowerCase()) {
      'done' => AppColors.success,
      'open' => AppColors.warning,
      'on progress' => AppColors.info,
      _ => AppColors.textWeak,
    };
    final prioritas = laporan['prioritas']?.toString() ?? 'Low';
    final priorityColor = switch (prioritas.toLowerCase()) {
      'high' => AppColors.error,
      'mid' => AppColors.warning,
      'low' => AppColors.success,
      _ => AppColors.textWeak,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  laporan['id']?.toString() ?? 'Laporan',
                  style: const TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              _buildReportBadge(status, statusColor, background: true),
              const SizedBox(width: 8),
              _buildReportBadge(prioritas, priorityColor, background: false),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            laporan['perihal']?.toString() ?? 'Tanpa perihal',
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildReportDetail(
                Icons.calendar_today_outlined,
                'Tanggal laporan',
                laporan['tanggal']?.toString() ?? '-',
              ),
              _buildReportDetail(
                Icons.event_outlined,
                'Deadline',
                laporan['deadline']?.toString() ?? '-',
              ),
              _buildReportDetail(
                Icons.person_outline,
                'PIC',
                laporan['pic']?.toString() ?? '-',
              ),
              _buildReportDetail(
                Icons.history_outlined,
                'Last update by',
                laporan['lastUpdateBy']?.toString() ?? '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportBadge(
    String text,
    Color color, {
    required bool background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: background
            ? null
            : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReportDetail(IconData icon, String label, String value) {
    return SizedBox(
      width: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textWeak),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
