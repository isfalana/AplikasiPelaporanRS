import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/main_layout_shell.dart';

class MasterDataView extends StatelessWidget {
  const MasterDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutShell(
      activeRoute: Routes.MASTER_DATA,
      title: 'Master Data',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 36.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Master Data',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kelola konfigurasi referensi sistem Lapor Permata',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: Get.width > 900 ? 3 : (Get.width > 600 ? 2 : 1),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.35,
              children: [
                _buildMenuCard('Kategori', Icons.category, Routes.MASTER_KATEGORI),
                _buildMenuCard('Unit', Icons.business, Routes.MASTER_UNIT),
                _buildMenuCard('Users', Icons.people, Routes.MASTER_USERS),
                _buildMenuCard('Role', Icons.admin_panel_settings, Routes.MASTER_ROLE),
                _buildMenuCard('Tindak Lanjut', Icons.task_alt, Routes.MASTER_TINDAK_LANJUT),
                _buildMenuCard('Template Tindakan', Icons.file_copy, Routes.MASTER_TEMPLATE_TINDAK_LANJUT),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, String route) {
    return InkWell(
      onTap: () {
        try {
          Get.toNamed(route);
        } catch (_) {
          Get.snackbar(
            'Master Data',
            'Modul $title siap dikonfigurasi.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}