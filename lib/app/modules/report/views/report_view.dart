import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/report_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/main_layout_shell.dart';

class ReportView extends GetView<ReportController> {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutShell(
      activeRoute: Routes.REPORT,
      title: 'Report',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Segarkan Laporan',
          onPressed: controller.fetchReportData,
        ),
      ],
      child: ResponsiveLayout(
        mobile: _buildMobileView(context),
        desktop: _buildDesktopView(context),
      ),
    );
  }

  // =========================================================================
  // DESKTOP VIEW (Sesuai Mockup Report-dekstop.png)
  // =========================================================================
  Widget _buildDesktopView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Judul Halaman
          const Text(
            'Report',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),

          // Baris Filter: Tanggal Mulai, Tanggal Selesai, Jenis, Status, Unit, Tombol Terapkan
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: _buildDatePickerField(
                  title: 'Tanggal Mulai',
                  date: controller.tanggalMulai,
                  onSelect: (val) => controller.tanggalMulai.value = val,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDatePickerField(
                  title: 'Tanggal Selesai',
                  date: controller.tanggalSelesai,
                  onSelect: (val) => controller.tanggalSelesai.value = val,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDropdownField(
                  title: 'Jenis',
                  value: controller.jenis,
                  items: const ['Laporan', 'Tindakan', 'Semua'],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDropdownField(
                  title: 'Status',
                  value: controller.status,
                  items: const ['Semua', 'Done', 'On Progress', 'Open'],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Obx(() {
                  final units = ['Semua', ...controller.unitList.map((u) => u['nama_unit']?.toString() ?? '')];
                  return _buildDropdownField(
                    title: 'Unit',
                    value: controller.unit,
                    items: units,
                  );
                }),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: controller.applyFilter,
                child: const Text('Terapkan Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tombol Export PDF & Export Excel di Atas Tabel Sebelah Kanan
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626), // Merah Export PDF
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                label: const Text('Export PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: controller.exportPdf,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A), // Hijau Export Excel
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.table_chart, color: Colors.white, size: 18),
                label: const Text('Export Excel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: controller.exportExcel,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tabel Laporan Desktop
          _buildDesktopReportTable(context),
        ],
      ),
    );
  }

  // =========================================================================
  // TABEL REPORT DESKTOP (Sesuai Mockup Report-dekstop.png)
  // =========================================================================
  Widget _buildDesktopReportTable(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ));
      }

      final list = controller.filteredReports;
      if (list.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Text('Tidak ada data yang sesuai filter', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
            columns: const [
              DataColumn(label: Text('Tanggal Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Tanggal Kejadian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Perihal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Pelapor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('PIC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Tindakan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Tanggal mulai tindak lanjut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Tanggal Selesai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            ],
            rows: list.map((item) {
              final tglLaporan = controller.formatDate(item['tgl_kejadian'] ?? item['created_at']);
              final tglKejadian = controller.formatDate(item['tgl_kejadian']);
              final tglSelesai = item['tgl_selesai'] != null ? controller.formatDate(item['tgl_selesai']) : '-';
              final status = item['status']?.toString() ?? 'Done';

              String kategori = 'Permasalahan';
              if (item['kategori'] != null && item['kategori'] is Map) {
                kategori = item['kategori']['jenis_kategori']?.toString() ?? kategori;
              }

              String pelapor = 'TS - Marketing';
              if (item['user_pelapor'] != null && item['user_pelapor'] is Map) {
                pelapor = item['user_pelapor']['nama_karyawan']?.toString() ?? pelapor;
              }

              String pic = 'IT';
              if (item['unit_pic'] != null && item['unit_pic'] is Map) {
                pic = item['unit_pic']['nama_unit']?.toString() ?? pic;
              }

              // Extract Tindakan bullet points
              String tindakanText = '• Memeriksa kendala teknis';
              if (item['riwayat_tindakan'] != null && item['riwayat_tindakan'] is List && (item['riwayat_tindakan'] as List).isNotEmpty) {
                tindakanText = (item['riwayat_tindakan'] as List)
                    .map((act) => '• ${act['deskripsi_tindakan']}')
                    .join('\n');
              }

              return DataRow(
                cells: [
                  DataCell(Text(tglLaporan, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(tglKejadian, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(kategori, style: const TextStyle(fontSize: 12))),
                  DataCell(SizedBox(
                    width: 200,
                    child: Text(
                      '“${item['perihal'] ?? '-'}”',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
                  DataCell(Text(pelapor, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(pic, style: const TextStyle(fontSize: 12))),
                  DataCell(Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(tindakanText, style: const TextStyle(fontSize: 11)),
                  )),
                  DataCell(Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  DataCell(Text(tglLaporan, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(tglSelesai, style: const TextStyle(fontSize: 12))),
                ],
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  // =========================================================================
  // MOBILE VIEW (Sesuai Mockup Report-mobile.png)
  // =========================================================================
  Widget _buildMobileView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Form Mobile
          _buildDatePickerField(
            title: 'Tanggal Mulai',
            date: controller.tanggalMulai,
            onSelect: (val) => controller.tanggalMulai.value = val,
          ),
          const SizedBox(height: 16),
          _buildDatePickerField(
            title: 'Tanggal Selesai',
            date: controller.tanggalSelesai,
            onSelect: (val) => controller.tanggalSelesai.value = val,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            title: 'Jenis',
            value: controller.jenis,
            items: const ['Laporan', 'Tindakan', 'Semua'],
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            title: 'Status',
            value: controller.status,
            items: const ['Semua', 'Done', 'On Progress', 'Open'],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final units = ['Semua', ...controller.unitList.map((u) => u['nama_unit']?.toString() ?? '')];
            return _buildDropdownField(
              title: 'Unit',
              value: controller.unit,
              items: units,
            );
          }),
          const SizedBox(height: 20),

          // Tombol Terapkan Filter Mobile
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: controller.applyFilter,
              child: const Text('Terapkan Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Export PDF & Export Excel Berdampingan
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.file_download, color: Colors.white, size: 18),
                  label: const Text('Export PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: controller.exportPdf,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.file_download, color: Colors.white, size: 18),
                  label: const Text('Export Excel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: controller.exportExcel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Section Header "Hasil report" & Jumlah Laporan
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hasil report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                '${controller.filteredReports.length} laporan',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          )),
          const SizedBox(height: 16),

          // Daftar Kartu Report Mobile
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ));
            }

            final list = controller.filteredReports;
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text('Tidak ada laporan ditemukan', style: TextStyle(color: Colors.grey))),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return _buildMobileReportCard(context, item);
              },
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // KARTU REPORT MOBILE (Sesuai Mockup Report-mobile.png)
  // =========================================================================
  Widget _buildMobileReportCard(BuildContext context, Map<String, dynamic> item) {
    final tglLaporan = controller.formatDate(item['tgl_kejadian'] ?? item['created_at']);
    final tglKejadian = controller.formatDate(item['tgl_kejadian']);
    final tglSelesai = item['tgl_selesai'] != null ? controller.formatDate(item['tgl_selesai']) : '-';
    final perihal = item['perihal']?.toString() ?? '-';
    final status = item['status']?.toString() ?? 'Done';

    String kategori = 'Permasalahan';
    if (item['kategori'] != null && item['kategori'] is Map) {
      kategori = item['kategori']['jenis_kategori']?.toString() ?? kategori;
    }

    String pelapor = 'TS - Marketing';
    if (item['user_pelapor'] != null && item['user_pelapor'] is Map) {
      pelapor = item['user_pelapor']['nama_karyawan']?.toString() ?? pelapor;
    }

    String pic = 'IT';
    if (item['unit_pic'] != null && item['unit_pic'] is Map) {
      pic = item['unit_pic']['nama_unit']?.toString() ?? pic;
    }

    List<String> actions = ['Memeriksa jaringan'];
    if (item['riwayat_tindakan'] != null && item['riwayat_tindakan'] is List && (item['riwayat_tindakan'] as List).isNotEmpty) {
      actions = (item['riwayat_tindakan'] as List).map((act) => act['deskripsi_tindakan'].toString()).toList();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: Tanggal Laporan & Tanggal Kejadian
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanggal Laporan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(tglLaporan, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanggal Kejadian', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(tglKejadian, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Kategori
          const Text('Kategori', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(kategori, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Perihal
          const Text('Perihal', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text('“$perihal”', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Pelapor & PIC
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pelapor', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(pelapor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PIC', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(pic, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tindakan
          const Text('Tindakan', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: actions.map((act) => Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text('• $act', style: const TextStyle(fontSize: 13)),
            )).toList(),
          ),
          const SizedBox(height: 12),

          // Status Badge with dot
          const Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          _buildStatusDotBadge(status),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Timestamps
          const Text('Tanggal mulai tindak lanjut', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(tglLaporan, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          const Text('Tanggal selesai', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(tglSelesai, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusDotBadge(String status) {
    Color color = const Color(0xFF16A34A); // Green Done
    final s = status.toLowerCase();
    if (s.contains('progress') || s.contains('proses')) {
      color = const Color(0xFF6F32B5);
    } else if (s.contains('open')) {
      color = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER FORM FIELDS
  // =========================================================================
  Widget _buildDatePickerField({
    required String title,
    required Rx<DateTime> date,
    required Function(DateTime) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        Obx(() => InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: Get.context!,
              initialDate: date.value,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) onSelect(picked);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.formatDate(date.value),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildDropdownField({
    required String title,
    required RxString value,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value.value) ? value.value : items.first,
              items: items.map((st) {
                return DropdownMenuItem<String>(
                  value: st,
                  child: Text(
                    st,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) value.value = val;
              },
            ),
          ),
        )),
      ],
    );
  }
}
