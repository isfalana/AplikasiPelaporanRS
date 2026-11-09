import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';
import '../routes/app_pages.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({
    required this.isCollapsed,
    required this.isMobile,
    required this.currentRoute,
    required this.unitName,
    required this.isMasterExpanded,
    required this.onMasterMenuTap,
    super.key,
  });

  final bool isCollapsed;
  final bool isMobile;
  final String currentRoute;
  final String unitName;
  final bool isMasterExpanded;
  final VoidCallback onMasterMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCollapsed ? 16 : 22,
              24,
              isCollapsed ? 16 : 22,
              28,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.accent,
                  size: 25,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Text(
                      'Lapor Permata',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildSidebarItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            isSelected: currentRoute == Routes.DASHBOARD,
            isCollapsed: isCollapsed,
            onTap: _openDashboard,
          ),
          const SizedBox(height: 24),
          if (!isCollapsed)
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 16, 8),
              child: Text(
                'MENU UTAMA',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          _buildSidebarItem(
            icon: Icons.send_outlined,
            title: 'Laporan',
            isSelected: currentRoute == Routes.LAPORAN,
            isCollapsed: isCollapsed,
            onTap: _openReports,
          ),
          _buildSidebarItem(
            icon: Icons.task_alt_outlined,
            title: 'Tindakan',
            isSelected: false,
            isCollapsed: isCollapsed,
            onTap: () => _showModuleUnavailable('Tindakan'),
          ),
          const SizedBox(height: 18),
          if (!isCollapsed)
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 16, 8),
              child: Text(
                'PENGELOLAAN',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          _buildMasterMenu(),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCollapsed ? 12 : 20,
              12,
              isCollapsed ? 12 : 20,
              20,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.white,
                    size: 19,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      unitName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildMasterMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSidebarItem(
          icon: Icons.folder_open_outlined,
          title: 'Master Data',
          isSelected: false,
          isCollapsed: isCollapsed,
          trailing: isCollapsed
              ? null
              : Icon(
                  isMasterExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
          onTap: onMasterMenuTap,
        ),
        if (isMasterExpanded && !isCollapsed) ...[
          _buildMasterSubmenu('Data Unit'),
          _buildMasterSubmenu('Data Pegawai'),
          _buildMasterSubmenu('Kategori Laporan'),
        ],
      ],
    );
  }

  Widget _buildMasterSubmenu(String title) {
    return Tooltip(
      message: 'Halaman $title belum tersedia',
      child: Padding(
        padding: const EdgeInsets.only(left: 57, right: 12),
        child: SizedBox(
          height: 38,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.52),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isCollapsed,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final item = Container(
      height: 44,
      margin: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 10 : 12,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: isCollapsed ? 0 : 12),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.white : AppColors.accent,
              ),
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.accent,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailing != null) ...[trailing, const SizedBox(width: 10)],
            ],
          ],
        ),
      ),
    );

    return isCollapsed ? Tooltip(message: title, child: item) : item;
  }

  void _openDashboard() {
    if (currentRoute == Routes.DASHBOARD) {
      if (isMobile) {
        Get.back();
      }
      return;
    }

    if (isMobile) {
      Get.back();
    }
    Get.offNamed(Routes.DASHBOARD);
  }

  void _openReports() {
    if (currentRoute == Routes.LAPORAN) {
      if (isMobile) {
        Get.back();
      }
      return;
    }

    if (isMobile) {
      Get.back();
    }
    Get.offNamed(Routes.LAPORAN);
  }

  void _showModuleUnavailable(String title) {
    if (isMobile) {
      Get.back();
    }
    Get.snackbar(
      title,
      'Halaman modul ini belum tersedia.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.sidebarDark,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}
