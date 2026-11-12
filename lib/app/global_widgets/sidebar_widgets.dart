import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';
import '../routes/app_pages.dart';

class SidebarWidget extends StatelessWidget {
  static const backgroundColor = AppColors.sidebarDark;

  static PreferredSizeWidget mobileAppBar({
    required String title,
    List<Widget> actions = const [],
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textStrong,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textStrong),
      actions: actions,
    );
  }

  static Widget mobileDrawer({required Widget child}) {
    return Drawer(
      width: 280,
      backgroundColor: backgroundColor,
      child: SafeArea(child: child),
    );
  }

  const SidebarWidget({
    required this.isCollapsed,
    required this.isMobile,
    required this.currentRoute,
    required this.unitName,
    required this.employeeName,
    required this.isMasterExpanded,
    required this.onMasterMenuTap,
    required this.onLogout,
    super.key,
  });

  final bool isCollapsed;
  final bool isMobile;
  final String currentRoute;
  final String unitName;
  final String employeeName;
  final bool isMasterExpanded;
  final VoidCallback onMasterMenuTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final profileName = employeeName.trim().isNotEmpty
        ? employeeName.trim()
        : unitName.trim();
    final initials = profileName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return Container(
      color: backgroundColor,
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
            isSelected: currentRoute == Routes.TINDAKAN,
            isCollapsed: isCollapsed,
            onTap: _openActions,
          ),
          _buildSidebarItem(
            icon: Icons.assessment_outlined,
            title: 'Report',
            isSelected: currentRoute == Routes.REPORT,
            isCollapsed: isCollapsed,
            onTap: _openReport,
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
          PopupMenuButton<String>(
            tooltip: 'Menu akun',
            color: AppColors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(minWidth: 230),
            onSelected: (value) {
              if (value == 'profile') {
                _showProfile(context, profileName, unitName, initials);
              } else if (value == 'logout') {
                onLogout();
              }
            },
            itemBuilder: (context) => [
              // Header menu: nama dan unit pengguna.
              PopupMenuItem<String>(
                enabled: false,
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profileName.isEmpty ? 'Pengguna' : profileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unitName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textWeak,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem(
                value: 'profile',
                height: 46,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 19,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Lihat profil',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                height: 46,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_outlined,
                      size: 19,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Keluar akun',
                      style: TextStyle(fontSize: 13, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
            child: Padding(
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
                    child: Text(
                      initials.isEmpty ? 'P' : initials,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileName.isEmpty ? 'Pengguna' : profileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            unitName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textWeak,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.more_vert,
                      color: AppColors.textWeak,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfile(
    BuildContext context,
    String name,
    String unit,
    String initials,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil pengguna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                initials.isEmpty ? 'P' : initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _profileValue('Nama', name.isEmpty ? 'Pengguna' : name),
            const SizedBox(height: 12),
            _profileValue('Unit', unit),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _profileValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textWeak, fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
          _buildMasterSubmenu(
            'Master Unit',
            isSelected: currentRoute == Routes.MASTER_UNIT,
            onTap: _openMasterUnit,
          ),
          _buildMasterSubmenu(
            'Master Karyawan',
            isSelected: currentRoute == Routes.MASTER_KARYAWAN,
            onTap: _openMasterKaryawan,
          ),
          _buildMasterSubmenu('Master Kategori'),
          _buildMasterSubmenu('Master Tindak Lanjut'),
          _buildMasterSubmenu('Master Role'),
        ],
      ],
    );
  }

  Widget _buildMasterSubmenu(
    String title, {
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final content = Padding(
      padding: const EdgeInsets.only(left: 40, right: 12),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.only(left: 17),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.52),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return Tooltip(message: 'Halaman $title belum tersedia', child: content);
    }
    return content;
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

  void _openActions() {
    if (currentRoute == Routes.TINDAKAN) {
      if (isMobile) Get.back();
      return;
    }

    if (isMobile) {
      Get.back();
    }
    Get.offNamed(Routes.TINDAKAN);
  }

  void _openReport() {
    if (currentRoute == Routes.REPORT) {
      if (isMobile) Get.back();
      return;
    }

    if (isMobile) Get.back();
    Get.offNamed(Routes.REPORT);
  }

  void _openMasterUnit() {
    if (currentRoute == Routes.MASTER_UNIT) {
      if (isMobile) Get.back();
      return;
    }

    if (isMobile) Get.back();
    Get.offNamed(Routes.MASTER_UNIT);
  }

  void _openMasterKaryawan() {
    if (currentRoute == Routes.MASTER_KARYAWAN) {
      if (isMobile) Get.back();
      return;
    }

    if (isMobile) Get.back();
    Get.offNamed(Routes.MASTER_KARYAWAN);
  }
}
