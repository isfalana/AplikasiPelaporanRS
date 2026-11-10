import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_layout.dart';
import '../routes/app_pages.dart';
import 'shell_controller.dart';

/// MainLayoutShell: Template Layout Reusable (Mirip Blade Template di Web)
/// Mengatur Sidebar Desktop (Collapsible 250px <-> 72px), Mobile Drawer,
/// Header/AppBar Mobile, dan Profil Pengguna Terpusat.
class MainLayoutShell extends StatelessWidget {
  final Widget child;
  final String activeRoute;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const MainLayoutShell({
    super.key,
    required this.child,
    required this.activeRoute,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    // Pastikan ShellController terdaftar secara permanent
    final ShellController shellCtrl = Get.put(ShellController(), permanent: true);

    return Scaffold(
      key: shellCtrl.scaffoldKey,
      backgroundColor: AppColors.surface,
      // Drawer hanya untuk Mobile
      drawer: ResponsiveLayout.isMobile(context) ? _buildDrawer(context, shellCtrl) : null,
      floatingActionButton: floatingActionButton,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context, shellCtrl),
        desktop: _buildDesktopLayout(context, shellCtrl),
      ),
    );
  }

  // =========================================================================
  // MOBILE APPBAR & BODY
  // =========================================================================
  Widget _buildMobileLayout(BuildContext context, ShellController ctrl) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.black, // Header hitam sesuai mockup
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: ctrl.openDrawer,
        ),
        title: Text(
          title ?? _getDefaultTitle(activeRoute),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: actions,
      ),
      body: child,
    );
  }

  // =========================================================================
  // DESKTOP LAYOUT (SIDEBAR KIRI + KONTEN KANAN)
  // =========================================================================
  Widget _buildDesktopLayout(BuildContext context, ShellController ctrl) {
    return Row(
      children: [
        // Sidebar Collapsible Desktop
        Obx(() {
          final bool isExpanded = ctrl.isSidebarExpanded.value;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: isExpanded ? 250 : 72,
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Tombol Hamburger & Title Header Sidebar
                InkWell(
                  onTap: ctrl.toggleSidebar,
                  hoverColor: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isExpanded ? 20.0 : 22.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu, color: Colors.white, size: 28),
                        if (isExpanded) ...[
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Lapor Permata',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),

                // Daftar Menu Navigasi Desktop
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildDesktopNavItem(
                          icon: Icons.home,
                          title: 'Dashboard',
                          route: Routes.DASHBOARD,
                          isActive: activeRoute == Routes.DASHBOARD,
                          isExpanded: isExpanded,
                          ctrl: ctrl,
                        ),
                        const SizedBox(height: 10),
                        _buildDesktopNavItem(
                          icon: Icons.send,
                          title: 'Laporan',
                          route: Routes.PELAPORAN,
                          isActive: activeRoute == Routes.PELAPORAN,
                          isExpanded: isExpanded,
                          ctrl: ctrl,
                        ),
                        const SizedBox(height: 10),
                        _buildDesktopNavItem(
                          icon: Icons.mark_email_unread,
                          title: 'Tindakan',
                          route: Routes.TINDAKAN,
                          isActive: activeRoute == Routes.TINDAKAN,
                          isExpanded: isExpanded,
                          ctrl: ctrl,
                        ),
                        const SizedBox(height: 10),
                        _buildDesktopNavItem(
                          icon: Icons.insert_drive_file,
                          title: 'Report',
                          route: Routes.REPORT,
                          isActive: activeRoute == Routes.REPORT,
                          isExpanded: isExpanded,
                          ctrl: ctrl,
                        ),
                        const SizedBox(height: 10),

                        // Submenu Master Data
                        _buildDesktopMasterItem(isExpanded, ctrl),
                      ],
                    ),
                  ),
                ),

                const Divider(color: Colors.white24, height: 1),

                // Profil Bagian Bawah
                _buildProfileSection(context, ctrl, isExpanded: isExpanded),
              ],
            ),
          );
        }),

        // Konten Halaman Utama
        Expanded(
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: child,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // ITEM NAVIGASI DESKTOP
  // =========================================================================
  Widget _buildDesktopNavItem({
    required IconData icon,
    required String title,
    required String route,
    required bool isActive,
    required bool isExpanded,
    required ShellController ctrl,
  }) {
    return Tooltip(
      message: isExpanded ? '' : title,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: () => ctrl.navigateTo(route),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: isExpanded ? 20.0 : 0),
          decoration: BoxDecoration(
            border: isActive
                ? const Border(left: BorderSide(color: Colors.white, width: 4))
                : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
            color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : Colors.white,
                size: 26,
              ),
              if (isExpanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? AppColors.primary : Colors.white,
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopMasterItem(bool isExpanded, ShellController ctrl) {
    final bool isMasterActive = activeRoute.startsWith('/master');

    if (!isExpanded) {
      return Tooltip(
        message: 'Master Data',
        child: InkWell(
          onTap: () => ctrl.navigateTo(Routes.MASTER_DATA),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              border: isMasterActive
                  ? const Border(left: BorderSide(color: Colors.white, width: 4))
                  : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
              color: isMasterActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Center(
              child: Icon(
                Icons.folder_open,
                color: isMasterActive ? AppColors.primary : Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      );
    }

    return Obx(() => Column(
      children: [
        InkWell(
          onTap: ctrl.toggleMasterMenu,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
            decoration: BoxDecoration(
              border: isMasterActive
                  ? const Border(left: BorderSide(color: Colors.white, width: 4))
                  : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
              color: isMasterActive ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_open,
                  color: isMasterActive ? AppColors.primary : Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Master',
                    style: TextStyle(
                      color: isMasterActive ? AppColors.primary : Colors.white,
                      fontSize: 15,
                      fontWeight: isMasterActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  ctrl.isMasterMenuExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: ctrl.isMasterMenuExpanded.value ? null : 0,
          child: ClipRect(
            child: Column(
              children: [
                _buildDesktopSubMenuItem('Users', Routes.MASTER_USERS, ctrl),
                _buildDesktopSubMenuItem('Unit', Routes.MASTER_UNIT, ctrl),
                _buildDesktopSubMenuItem('Role', Routes.MASTER_ROLE, ctrl),
                _buildDesktopSubMenuItem('Kategori', Routes.MASTER_KATEGORI, ctrl),
                _buildDesktopSubMenuItem('Tindak Lanjut', Routes.MASTER_TINDAK_LANJUT, ctrl),
                _buildDesktopSubMenuItem('Template Tindakan', Routes.MASTER_TEMPLATE_TINDAK_LANJUT, ctrl),
              ],
            ),
          ),
        )
      ],
    ));
  }

  Widget _buildDesktopSubMenuItem(String title, String route, ShellController ctrl) {
    final bool isActive = activeRoute == route;
    return InkWell(
      onTap: () => ctrl.navigateTo(route),
      child: Container(
        padding: const EdgeInsets.only(left: 64.0, top: 10.0, bottom: 10.0, right: 16.0),
        alignment: Alignment.centerLeft,
        color: isActive ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primary : Colors.white70,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // DRAWER MOBILE
  // =========================================================================
  Widget _buildDrawer(BuildContext context, ShellController ctrl) {
    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Lapor Permata',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),

            // Item Navigasi Mobile Drawer
            _buildDrawerTile(Icons.home, 'Dashboard', Routes.DASHBOARD, ctrl),
            const SizedBox(height: 8),
            _buildDrawerTile(Icons.send, 'Laporan', Routes.PELAPORAN, ctrl),
            const SizedBox(height: 8),
            _buildDrawerTile(Icons.mark_email_unread, 'Tindakan', Routes.TINDAKAN, ctrl),
            const SizedBox(height: 8),
            _buildDrawerTile(Icons.insert_drive_file, 'Report', Routes.REPORT, ctrl),
            const SizedBox(height: 8),

            // Dropdown Master Menu
            Obx(() => Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                  leading: const Icon(Icons.folder_open, color: Colors.white, size: 24),
                  title: const Text('Master', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                  trailing: Icon(
                    ctrl.isMasterMenuExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  onTap: ctrl.toggleMasterMenu,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: ctrl.isMasterMenuExpanded.value ? null : 0,
                  child: ClipRect(
                    child: Column(
                      children: [
                        _buildSubDrawerTile('Users', Routes.MASTER_USERS, ctrl),
                        _buildSubDrawerTile('Unit', Routes.MASTER_UNIT, ctrl),
                        _buildSubDrawerTile('Role', Routes.MASTER_ROLE, ctrl),
                        _buildSubDrawerTile('Kategori', Routes.MASTER_KATEGORI, ctrl),
                        _buildSubDrawerTile('Tindak Lanjut', Routes.MASTER_TINDAK_LANJUT, ctrl),
                        _buildSubDrawerTile('Template Tindakan', Routes.MASTER_TEMPLATE_TINDAK_LANJUT, ctrl),
                      ],
                    ),
                  ),
                ),
              ],
            )),

            const Spacer(),
            const Divider(color: Colors.white24, height: 1),

            // Profil Pengguna di Bagian Bawah
            _buildProfileSection(context, ctrl, isExpanded: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, String route, ShellController ctrl) {
    final bool isActive = activeRoute == route;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      leading: Icon(icon, color: isActive ? AppColors.primary : Colors.white, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.primary : Colors.white,
          fontSize: 15,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onTap: () => ctrl.navigateTo(route),
    );
  }

  Widget _buildSubDrawerTile(String title, String route, ShellController ctrl) {
    final bool isActive = activeRoute == route;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 64.0, right: 20.0),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.primary : Colors.white70,
          fontSize: 13,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
        ),
      ),
      onTap: () => ctrl.navigateTo(route),
    );
  }

  // =========================================================================
  // PROFILE SECTION DI BAGIAN BAWAH SIDEBAR / DRAWER
  // =========================================================================
  Widget _buildProfileSection(BuildContext context, ShellController ctrl, {required bool isExpanded}) {
    return Obx(() {
      final initials = ctrl.userInitials;
      final name = ctrl.namaKaryawan.value.isNotEmpty ? ctrl.namaKaryawan.value : ctrl.idNik.value;
      final unit = ctrl.unitName.value;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16.0 : 8.0, vertical: 12.0),
        child: PopupMenuButton<String>(
          tooltip: 'Menu Akun',
          offset: const Offset(0, -110),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'edit_profile') {
              ctrl.showEditProfileDialog(context);
            } else if (value == 'logout') {
              ctrl.confirmLogout();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'edit_profile',
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          unit,
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert, color: Colors.white70, size: 18),
                ]
              ],
            ),
          ),
        ),
      );
    });
  }

  String _getDefaultTitle(String route) {
    switch (route) {
      case Routes.DASHBOARD:
        return 'Dashboard';
      case Routes.PELAPORAN:
        return 'Laporan';
      case Routes.TINDAKAN:
        return 'Tindakan';
      case Routes.REPORT:
        return 'Report';
      case Routes.MASTER_DATA:
        return 'Master Data';
      default:
        return 'Lapor Permata';
    }
  }
}
