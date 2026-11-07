import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../routes/app_pages.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey, // Tetap dipertahankan untuk Hamburger Mobile
      backgroundColor: AppColors.surface,
      drawer: ResponsiveLayout.isMobile(context) ? _buildDrawerMenu() : null, // Drawer hanya untuk Mobile
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  // =========================================================================
  // MENU DRAWER (KHUSUS MOBILE)
  // =========================================================================
  Widget _buildDrawerMenu() {
    return Drawer(
      backgroundColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              onPressed: () => Get.back(),
            ),
          ),
          const SizedBox(height: 40),
          _buildMenuTile(Icons.home, 'Dashboard', isActive: true, route: Routes.DASHBOARD),
          const SizedBox(height: 16),
          _buildMenuTile(Icons.send, 'Laporan', isActive: false, route: Routes.PELAPORAN),
          const SizedBox(height: 16),
          _buildMenuTile(Icons.mark_email_unread, 'Tindakan', isActive: false, route: Routes.TINDAKAN),
          const SizedBox(height: 16),
          _buildMenuTile(Icons.insert_drive_file, 'Master', isActive: false, route: Routes.MASTER_DATA),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, {required bool isActive, required String route}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: () {
        Get.back(); // Tutup drawer dulu
        if (Get.currentRoute != route) {
          Get.toNamed(route);
        }
      },
    );
  }

  // =========================================================================
  // LAYOUT MOBILE (Tetap dengan Hamburger)
  // =========================================================================
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: controller.openDrawer,
        ),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selamat Datang', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(icon: const Icon(Icons.tune, color: AppColors.primary, size: 28), onPressed: () {}),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildMobileMetricCard('1', 'Laporan Terkirim'),
                _buildMobileMetricCard('1', 'Pesan Tindakan'),
                _buildMobileMetricCard('1', 'Tindakan Selesai'),
                _buildMobileMetricCard('1', '.......'),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('List Prioritas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildPriorityListItem(tgl: '25/10/2026', deadline: '30/10/2026', perihal: 'Sistem yang Error', pic: 'IT Dev'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMetricCard(String value, String title) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  // =========================================================================
  // LAYOUT DESKTOP (Statis, Lebar Penuh, Tanpa Hamburger)
  // =========================================================================
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // SIDEBAR DESKTOP (Tetap memanjang statis)
        Container(
          width: 250, // Lebar tetap terbuka penuh sesuai gambar
          color: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80), // Jarak atas yang bersih (tanpa ikon menu)
              
              // List Menu Statis
              _buildDesktopSidebarItem(Icons.home, 'Dashboard', isActive: true, route: Routes.DASHBOARD),
              const SizedBox(height: 24),
              _buildDesktopSidebarItem(Icons.send, 'Laporan', isActive: false, route: Routes.PELAPORAN),
              const SizedBox(height: 24),
              _buildDesktopSidebarItem(Icons.mark_email_unread, 'Tindakan', isActive: false, route: Routes.TINDAKAN),
              const SizedBox(height: 24),
              _buildDesktopSidebarItem(Icons.insert_drive_file, 'Master', isActive: false, route: Routes.MASTER_DATA),
            ],
          ),
        ),
        
        // AREA KONTEN UTAMA
        Expanded(
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 1.4,
                            children: [
                              _buildDesktopMetricCard('Laporan Terkirim', '1'),
                              _buildDesktopMetricCard('Pesan Tindakan', '2'),
                              _buildDesktopMetricCard('Tindakan Selesai', '5'),
                              _buildDesktopMetricCard('Tindakan On Progress', '1'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('List Prioritas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 24),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      _buildPriorityListItem(tgl: '30/10/2026', deadline: '01/11/2026', perihal: 'test ......', pic: 'IT Dev'),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDesktopSidebarItem(IconData icon, String title, {required bool isActive, required String route}) {
    return InkWell(
      onTap: () {
        if (Get.currentRoute != route) {
          Get.toNamed(route);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: isActive ? const Border(left: BorderSide(color: Colors.white, width: 4)) : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0), 
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopMetricCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.black)),
          const Text('Lihat Detail >>', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPriorityListItem({required String tgl, required String deadline, required String perihal, required String pic}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Laporan Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), Text(tgl, style: const TextStyle(fontSize: 12)), const SizedBox(height: 12), const Text('Perihal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), Text(perihal, style: const TextStyle(fontSize: 12))])),
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Deadline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), Text(deadline, style: const TextStyle(fontSize: 12)), const SizedBox(height: 12), const Text('PIC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), Text(pic, style: const TextStyle(fontSize: 12))])),
          Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(20)), child: const Text('Open', style: TextStyle(color: Colors.white, fontSize: 11))), const SizedBox(height: 32), const Text('Last Update by :', style: TextStyle(fontSize: 10, color: Colors.grey))])),
        ],
      ),
    );
  }
}