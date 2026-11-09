// lib/app/modules/dashboard/views/dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  // --- LAYOUT MOBILE (Dengan Bottom Navigation) ---
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: AppColors.textStrong)),
        backgroundColor: AppColors.white,
        elevation: 1,
      ),
      body: _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Index 1 = Dashboard
        onTap: (index) {
          // Logika pindah halaman (0: Laporan, 1: Dashboard, 2: Tindakan)
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textWeak,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.send), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.mark_email_unread), label: 'Tindakan'),
        ],
      ),
    );
  }

  // --- LAYOUT DESKTOP (Dengan Sidebar) ---
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar Kiri
        Container(
          width: 250,
          color: AppColors.sidebarDark,
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text('Lapor Permata', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              ListTile(
                leading: const Icon(Icons.home, color: AppColors.white),
                title: const Text('Dashboard', style: TextStyle(color: AppColors.white)),
                tileColor: AppColors.primary.withValues(alpha: 0.2), // Active indicator
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.send, color: AppColors.textWeak),
                title: const Text('Laporan', style: TextStyle(color: AppColors.textWeak)),
                onTap: () => Get.toNamed('/pelaporan'),
              ),
              ListTile(
                leading: const Icon(Icons.mark_email_unread, color: AppColors.textWeak),
                title: const Text('Tindakan', style: TextStyle(color: AppColors.textWeak)),
                onTap: () {},
              ),
            ],
          ),
        ),
        // Konten Utama Kanan
        Expanded(
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              title: const Text('Dashboard', style: TextStyle(color: AppColors.textStrong)),
              backgroundColor: AppColors.white,
              elevation: 1,
              actions: [
                IconButton(icon: const Icon(Icons.logout, color: AppColors.textStrong), onPressed: controller.logout)
              ],
            ),
            body: _buildContent(),
          ),
        )
      ],
    );
  }

  // --- KONTEN DASHBOARD (Kartu Metrik) ---
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text('Selamat Datang', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textStrong)),
           const SizedBox(height: 24),
           Expanded(
             child: Obx(() => GridView.count(
               crossAxisCount: ResponsiveLayout.isMobile(Get.context!) ? 2 : 4,
               crossAxisSpacing: 16,
               mainAxisSpacing: 16,
               childAspectRatio: 1.2,
               children: [
                 _buildMetricCard('Laporan Terkirim', controller.jumlahLaporan.value.toString(), AppColors.primary),
                 _buildMetricCard('Pesan Tindakan', controller.jumlahPesanTindakan.value.toString(), AppColors.warning),
                 _buildMetricCard('Tindakan Selesai', controller.jumlahTindakanSelesai.value.toString(), AppColors.success),
               ],
             )),
           )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(bottom: BorderSide(color: borderColor, width: 4)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.textStrong)),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textWeak)),
        ],
      ),
    );
  }
}