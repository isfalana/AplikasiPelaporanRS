import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';
import '../modules/auth/controllers/dashboard_controller.dart';
import 'sidebar_widgets.dart';

class MainLayoutWidget extends StatelessWidget {
  const MainLayoutWidget({
    super.key,
    required this.title,
    required this.child,
    this.desktopActions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> desktopActions;

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        if (isMobile) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: SidebarWidget.mobileAppBar(
            title: title,
            actions: desktopActions,
          ),
            drawer: SidebarWidget.mobileDrawer(
              child: _buildSidebar(
                dashboardController,
                isCollapsed: false,
                isMobile: true,
              ),
            ),
            body: child,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Obx(() {
            final isCollapsed =
                dashboardController.isSidebarCollapsed.value ||
                constraints.maxWidth < 1024;
            final autoCollapsed = constraints.maxWidth < 1024;

            return Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  width: isCollapsed ? 76 : 248,
                  child: LayoutBuilder(
                    builder: (context, sidebarConstraints) {
                      return _buildSidebar(
                        dashboardController,
                        isCollapsed:
                            isCollapsed || sidebarConstraints.maxWidth < 100,
                        isMobile: false,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 68,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: autoCollapsed
                                  ? 'Sidebar dikolaps otomatis'
                                  : isCollapsed
                                  ? 'Buka sidebar'
                                  : 'Ciutkan sidebar',
                              onPressed: autoCollapsed
                                  ? null
                                  : dashboardController
                                        .isSidebarCollapsed
                                        .toggle,
                              icon: const Icon(
                                Icons.menu_rounded,
                                color: AppColors.textStrong,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.textStrong,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            ...desktopActions,
                          ],
                        ),
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildSidebar(
    DashboardController dashboardController, {
    required bool isCollapsed,
    required bool isMobile,
  }) {
    return Obx(
      () => SidebarWidget(
        isCollapsed: isCollapsed,
        isMobile: isMobile,
        currentRoute: Get.currentRoute,
        unitName: dashboardController.unitName.value,
        employeeName: dashboardController.employeeName.value,
        isMasterExpanded: dashboardController.isMasterExpanded.value,
        onLogout: dashboardController.logout,
        onMasterMenuTap: () {
          if (isCollapsed) {
            dashboardController.isSidebarCollapsed.value = false;
            dashboardController.isMasterExpanded.value = true;
          } else {
            dashboardController.isMasterExpanded.toggle();
          }
        },
      ),
    );
  }
}
