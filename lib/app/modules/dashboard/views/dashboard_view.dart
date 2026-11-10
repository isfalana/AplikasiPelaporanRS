import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/main_layout_shell.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutShell(
      activeRoute: Routes.DASHBOARD,
      title: 'Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Segarkan Data',
          onPressed: controller.fetchDashboardData,
        ),
      ],
      child: ResponsiveLayout(
        mobile: _buildMobileContent(context),
        desktop: _buildDesktopContent(context),
      ),
    );
  }

  // =========================================================================
  // KONTEN MOBILE (Sesuai Mockup Dashboard.png)
  // =========================================================================
  Widget _buildMobileContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.fetchDashboardData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Selamat Datang & Ikon Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune, color: AppColors.primary, size: 26),
                  tooltip: 'Filter Laporan',
                  onPressed: () => _showFilterDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4 Metrik Kartu dalam Grid 2x2
            Obx(() => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                _buildMobileMetricCard('Laporan Terkirim', controller.jumlahLaporan.value.toString(), () => Get.toNamed(Routes.PELAPORAN)),
                _buildMobileMetricCard('Pesan Tindakan', controller.jumlahPesanTindakan.value.toString(), () => Get.toNamed(Routes.TINDAKAN)),
                _buildMobileMetricCard('Tindakan Selesai', controller.jumlahTindakanSelesai.value.toString(), () => Get.toNamed(Routes.TINDAKAN)),
                _buildMobileMetricCard('Tindakan On Progress', controller.jumlahTindakanOnProgress.value.toString(), () => Get.toNamed(Routes.TINDAKAN)),
              ],
            )),
            const SizedBox(height: 24),

            // Container List Prioritas Mobile
            _buildPriorityContainer(context, isMobile: true),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // KONTEN DESKTOP (Sesuai Mockup Dashboard-Desktop.png)
  // =========================================================================
  Widget _buildDesktopContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 36.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Dashboard Desktop
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary, size: 26),
                  tooltip: 'Segarkan Data Real-Time',
                  onPressed: controller.fetchDashboardData,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Grid Metrik & List Prioritas (Dua Kolom)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KOLOM KIRI: 2x2 METRIC CARDS
                Expanded(
                  flex: 5,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.25,
                    children: [
                      _buildDesktopMetricCard(
                        title: 'Laporan Terkirim',
                        value: controller.jumlahLaporan.value.toString(),
                        onViewDetail: () => Get.toNamed(Routes.PELAPORAN),
                      ),
                      _buildDesktopMetricCard(
                        title: 'Pesan Tindakan',
                        value: controller.jumlahPesanTindakan.value.toString(),
                        onViewDetail: () => Get.toNamed(Routes.TINDAKAN),
                      ),
                      _buildDesktopMetricCard(
                        title: 'Tindakan Selesai',
                        value: controller.jumlahTindakanSelesai.value.toString(),
                        onViewDetail: () => Get.toNamed(Routes.TINDAKAN),
                      ),
                      _buildDesktopMetricCard(
                        title: 'Tindakan On Progress',
                        value: controller.jumlahTindakanOnProgress.value.toString(),
                        onViewDetail: () => Get.toNamed(Routes.TINDAKAN),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),

                // KOLOM KANAN: LIST PRIORITAS
                Expanded(
                  flex: 5,
                  child: _buildPriorityContainer(context, isMobile: false),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // =========================================================================
  // METRIC CARDS
  // =========================================================================
  Widget _buildDesktopMetricCard({
    required String title,
    required String value,
    required VoidCallback onViewDetail,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.black)),
          InkWell(
            onTap: onViewDetail,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lihat Detail >>', style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMetricCard(String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CONTAINER LIST PRIORITAS
  // =========================================================================
  Widget _buildPriorityContainer(BuildContext context, {required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Obx(() {
        final items = controller.listPrioritas;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'List Prioritas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 20),

            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'Belum ada laporan prioritas',
                    style: TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildPriorityCard(context, item);
                },
              ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Get.toNamed(Routes.PELAPORAN),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                    'Lihat Detail >>',
                    style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPriorityCard(BuildContext context, Map<String, dynamic> item) {
    final tglLaporan = controller.formatDate(item['tgl_kejadian'] ?? item['created_at']);
    final deadline = controller.formatDate(item['deadline'] ?? item['tgl_kejadian']);
    final perihal = item['perihal']?.toString() ?? '-';

    String picName = 'IT Dev';
    if (item['unit_pic'] != null && item['unit_pic'] is Map) {
      picName = item['unit_pic']['nama_unit']?.toString() ?? picName;
    } else if (item['id_unit_pic'] != null) {
      picName = item['id_unit_pic'].toString();
    }

    String lastUpdateBy = 'PIC IT';
    if (item['user_pic'] != null && item['user_pic'] is Map) {
      lastUpdateBy = item['user_pic']['nama_karyawan']?.toString() ?? lastUpdateBy;
    } else if (item['user_pelapor'] != null && item['user_pelapor'] is Map) {
      lastUpdateBy = item['user_pelapor']['nama_karyawan']?.toString() ?? lastUpdateBy;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Laporan Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(tglLaporan, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deadline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(deadline, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ),
              // Tombol Biru "Open" sesuai mockup
              InkWell(
                onTap: () => _showDetailLaporan(context, item),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Perihal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(
                      perihal,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PIC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(picName, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(width: 50),
            ],
          ),
          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Last Update by : $lastUpdateBy',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailLaporan(BuildContext context, Map<String, dynamic> item) {
    final idLaporan = item['id_laporan']?.toString() ?? '-';
    final perihal = item['perihal']?.toString() ?? '-';
    final keterangan = item['keterangan']?.toString() ?? 'Tidak ada keterangan tambahan';
    final status = item['status']?.toString() ?? 'Pending';
    final prioritas = item['prioritas']?.toString() ?? 'Sedang';

    Get.defaultDialog(
      title: 'Detail Laporan $idLaporan',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBadge('Status: $status', _getStatusColor(status)),
                _buildBadge('Prioritas: $prioritas', _getPriorityColor(prioritas)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Perihal:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(perihal, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            const Text('Keterangan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(keterangan, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tanggal: ${controller.formatDate(item['tgl_kejadian'])}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Unit: ${item['unit_pelapor']?['nama_unit'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        onPressed: () => Get.back(),
        child: const Text('Tutup', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'done' || s == 'selesai') return AppColors.success;
    if (s == 'on progress' || s == 'proses') return AppColors.warning;
    return AppColors.info;
  }

  Color _getPriorityColor(String priority) {
    final p = priority.toLowerCase();
    if (p == 'tinggi' || p == 'urgent') return AppColors.error;
    if (p == 'sedang') return AppColors.warning;
    return AppColors.success;
  }

  void _showFilterDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter List Prioritas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.primary),
              title: const Text('Tampilkan Semua Laporan'),
              onTap: () {
                Get.back();
                controller.fetchDashboardData();
              },
            ),
          ],
        ),
      ),
    );
  }
}