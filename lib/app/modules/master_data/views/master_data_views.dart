import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_pages.dart';

class MasterDataView extends StatelessWidget {
  const MasterDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Master Data', style: TextStyle(color: AppColors.textStrong)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textStrong),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: Get.width > 800 ? 4 : 2, // 4 kolom desktop, 2 kolom mobile
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildMenuCard('Kategori', Icons.category, Routes.MASTER_KATEGORI),
            _buildMenuCard('Unit', Icons.business, '/master-data/unit'), // Rute placeholder
            _buildMenuCard('Users', Icons.people, '/master-data/users'),
            _buildMenuCard('Role', Icons.admin_panel_settings, '/master-data/role'),
            _buildMenuCard('Tindak Lanjut', Icons.task_alt, '/master-data/tindak-lanjut'),
            _buildMenuCard('Template Tindakan', Icons.file_copy, '/master-data/template'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, String route) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textStrong),
            ),
          ],
        ),
      ),
    );
  }
}