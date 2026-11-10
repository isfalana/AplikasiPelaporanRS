import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pelaporan_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/main_layout_shell.dart';

class PelaporanView extends GetView<PelaporanController> {
  const PelaporanView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutShell(
      activeRoute: Routes.PELAPORAN,
      title: 'Laporan',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Segarkan Laporan',
          onPressed: controller.fetchLaporan,
        ),
      ],
      child: ResponsiveLayout(
        mobile: _buildMobileView(context),
        desktop: _buildDesktopView(context),
      ),
    );
  }

  // =========================================================================
  // DESKTOP VIEW (Sesuai Mockup Laporan-dekstop.png)
  // =========================================================================
  Widget _buildDesktopView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Judul Halaman
          const Text(
            'Laporan',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Isi informasi Secara Benar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 32),

          // Row 2 Kolom: Kiri Form Input, Kanan Daftar Laporan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KOLOM KIRI: FORM INPUT LAPORAN
              Expanded(
                flex: 6,
                child: _buildFormLaporan(context, isMobile: false),
              ),

              const SizedBox(width: 48),

              // KOLOM KANAN: DAFTAR LAPORAN
              Expanded(
                flex: 5,
                child: _buildDaftarLaporan(context, isMobile: false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MOBILE VIEW (Sesuai Mockup Laporan-mobile.png)
  // =========================================================================
  Widget _buildMobileView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'isi laporan dibawah ini dengan lengkap',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Form Input Mobile
          _buildFormLaporan(context, isMobile: true),
          const SizedBox(height: 32),

          // Daftar Laporan Mobile
          _buildDaftarLaporan(context, isMobile: true),
        ],
      ),
    );
  }

  // =========================================================================
  // FORM INPUT LAPORAN (Desktop & Mobile)
  // =========================================================================
  Widget _buildFormLaporan(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris 1: Tanggal Laporan, Tanggal Kejadian, Pelapor
        if (!isMobile)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFieldContainer(
                  title: 'Tanggal laporan',
                  child: Obx(() => Text(
                    controller.formatDate(controller.tglLaporan.value),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  )),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDatePickerField(
                  title: 'Tanggal Kejadian',
                  date: controller.tglKejadian,
                  onSelect: (val) => controller.tglKejadian.value = val,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildFieldContainer(
                  title: 'Pelapor',
                  child: Obx(() => Text(
                    controller.namaPelapor.value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  )),
                ),
              ),
            ],
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _buildFieldContainer(
                  title: 'Tanggal laporan',
                  child: Obx(() => Text(
                    controller.formatDate(controller.tglLaporan.value),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  )),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePickerField(
                  title: 'Tanggal Kejadian',
                  date: controller.tglKejadian,
                  onSelect: (val) => controller.tglKejadian.value = val,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFieldContainer(
                  title: 'Pelapor',
                  child: Obx(() => Text(
                    controller.namaPelapor.value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  )),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKategoriDropdown(),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Baris 2: Kategori, PIC, Deadline
        if (!isMobile)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildKategoriDropdown(),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildPicDropdown(),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDatePickerField(
                  title: 'Deadline',
                  date: controller.deadline,
                  onSelect: (val) => controller.deadline.value = val,
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPicDropdown(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePickerField(
                  title: 'Deadline',
                  date: controller.deadline,
                  onSelect: (val) => controller.deadline.value = val,
                ),
              ),
            ],
          ),

        const SizedBox(height: 24),

        // Baris 3: Perihal
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perihal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
                ],
              ),
              child: TextField(
                controller: controller.perihalController,
                decoration: const InputDecoration(
                  hintText: 'Sistem yang Error',
                  hintStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  suffixIcon: Icon(Icons.search, color: AppColors.primary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sistem yang Error',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Baris 4: Upload Bukti
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMobile ? 'Upload bukti laporan' : 'Upload Bukti',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: controller.pickFile,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'upload disini',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Obx(() => Text(
                  controller.uploadedFileName.value.isNotEmpty
                      ? controller.uploadedFileName.value
                      : 'bukti.jpg',
                  style: TextStyle(
                    fontSize: 14,
                    color: controller.uploadedFileName.value.isNotEmpty ? AppColors.primary : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                )),
              ],
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Baris 5: Tombol Kirim & Batal
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.end,
          children: [
            Obx(() => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: controller.isSubmitting.value ? null : controller.submitLaporan,
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Kirim',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            )),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: controller.resetForm,
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        )
      ],
    );
  }

  // =========================================================================
  // DAFTAR LAPORAN (Desktop & Mobile)
  // =========================================================================
  Widget _buildDaftarLaporan(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daftar Laporan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            IconButton(
              icon: const Icon(Icons.tune, color: AppColors.primary, size: 24),
              tooltip: 'Filter Laporan',
              onPressed: () => _showFilterOptions(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ));
          }

          final list = controller.listLaporan;
          if (list.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Belum ada laporan yang terdaftar', style: TextStyle(color: Colors.grey)),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildLaporanCard(context, item);
            },
          );
        }),
      ],
    );
  }

  // =========================================================================
  // KARTU LAPORAN (Sesuai Mockup Laporan-dekstop.png & Laporan-mobile.png)
  // =========================================================================
  Widget _buildLaporanCard(BuildContext context, Map<String, dynamic> item) {
    final tglLaporan = controller.formatDate(item['tgl_kejadian'] ?? item['created_at']);
    final deadline = controller.formatDate(item['deadline'] ?? item['tgl_kejadian']);
    final perihal = item['perihal']?.toString() ?? '-';
    final status = item['status']?.toString() ?? 'Open';

    String picName = 'IT Dev';
    if (item['unit_pic'] != null && item['unit_pic'] is Map) {
      picName = item['unit_pic']['nama_unit']?.toString() ?? picName;
    }

    String lastUpdateBy = '';
    if (item['user_pic'] != null && item['user_pic'] is Map) {
      lastUpdateBy = item['user_pic']['nama_karyawan']?.toString() ?? '';
    } else if (item['user_pelapor'] != null && item['user_pelapor'] is Map) {
      lastUpdateBy = item['user_pelapor']['nama_karyawan']?.toString() ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Baris 1: Tanggal Laporan, Deadline, Status Badge + Edit Icon
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
              // Icon Edit + Badge Status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: AppColors.primary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Lihat Detail Laporan',
                    onPressed: () => _openDetailLaporan(context, item),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baris 2: Perihal dan PIC
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
              const SizedBox(width: 60),
            ],
          ),
          const SizedBox(height: 10),

          // Baris 3: Last Update by
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Last Update by : $lastUpdateBy',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // DETAIL LAPORAN MODAL (Sesuai Mockup Detail Laporan-mobile.png)
  // =========================================================================
  void _openDetailLaporan(BuildContext context, Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'Open';
    final tglLaporan = controller.formatDate(item['tgl_kejadian'] ?? item['created_at']);
    final tglKejadian = controller.formatDate(item['tgl_kejadian']);
    final deadline = controller.formatDate(item['deadline'] ?? item['tgl_kejadian']);
    final perihal = item['perihal']?.toString() ?? '-';
    final keterangan = item['keterangan']?.toString() ?? perihal;

    String pelaporName = controller.namaPelapor.value;
    if (item['user_pelapor'] != null && item['user_pelapor'] is Map) {
      pelaporName = item['user_pelapor']['nama_karyawan']?.toString() ?? pelaporName;
    }

    String kategori = 'Permasalahan';
    if (item['kategori'] != null && item['kategori'] is Map) {
      kategori = item['kategori']['jenis_kategori']?.toString() ?? kategori;
    }

    String picName = 'IT Dev, IT Support';
    if (item['unit_pic'] != null && item['unit_pic'] is Map) {
      picName = item['unit_pic']['nama_unit']?.toString() ?? picName;
    }

    // Mock checklist tindak lanjut yang dapat diceklis
    final checklist = <Map<String, dynamic>>[
      {'title': 'Tindak Lanjut 1', 'checked': true.obs},
      {'title': 'Tindak Lanjut 2', 'checked': false.obs},
      {'title': 'Tindak Lanjut 3', 'checked': false.obs},
      {'title': 'Tindak Lanjut 4', 'checked': false.obs},
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Tombol Back (<) & Status Badge di Kanan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
                      onPressed: () => Get.back(),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 16),

                // Tanggal Laporan & Tanggal Kejadian
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tanggal Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(tglLaporan, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tanggal Kejadian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(tglKejadian, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Pelapor & Kategori (Grey Containers)
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailPill('Pelapor', pelaporName),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailPill('Kategori', kategori),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // PIC & Deadline (Grey Containers)
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailPill('PIC', picName),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailPill('Deadline', deadline),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Perihal
                const Text('Perihal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(perihal, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(keterangan, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 18),

                // Bukti Laporan
                const Text('Bukti laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Lihat disini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Text('bukti.jpg', style: TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 20),

                // Tindak Lanjut Checklist
                const Text('Tindak Lanjut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Column(
                  children: checklist.map((chk) {
                    return Obx(() {
                      final bool isChecked = chk['checked'].value;
                      return InkWell(
                        onTap: () => chk['checked'].value = !isChecked,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                                color: isChecked ? AppColors.primary : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                chk['title'],
                                style: TextStyle(
                                  fontSize: 13,
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                  color: isChecked ? Colors.grey : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Keterangan Box
                const Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  height: 90,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    keterangan,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 20),

                // Status & Timestamp Footer
                Row(
                  children: [
                    const Text('Status : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Last Update by    :  $pelaporName', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 4),
                Text('Start Follow-up at :  $tglLaporan', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 4),
                const Text('Done at                :  -', style: TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPill(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================
  Widget _buildFieldContainer({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDatePickerField({
    required String title,
    required Rx<DateTime> date,
    required Function(DateTime) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildKategoriDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
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
              value: controller.selectedKategori.value,
              hint: const Text('Pilih Kategori'),
              items: controller.kategoriList.map((kat) {
                final id = kat['id_kategori']?.toString() ?? '';
                final name = kat['jenis_kategori']?.toString() ?? id;
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) controller.selectedKategori.value = val;
              },
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPicDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PIC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
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
              value: controller.selectedUnitPic.value,
              hint: const Text('Pilih PIC Unit'),
              items: controller.unitList.map((unit) {
                final id = unit['id_unit']?.toString() ?? '';
                final name = unit['nama_unit']?.toString() ?? id;
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) controller.selectedUnitPic.value = val;
              },
            ),
          ),
        )),
        const SizedBox(height: 6),
        const Text('IT Dev, IT Support', style: TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF2563EB); // Default Blue Open
    final s = status.toLowerCase();

    if (s.contains('progress') || s.contains('proses')) {
      bg = const Color(0xFF6F32B5); // Purple On Progress
    } else if (s.contains('done') || s.contains('selesai')) {
      bg = const Color(0xFF16A34A); // Green Done
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
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
            const Text('Filter Status Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Semua Status'),
              onTap: () {
                Get.back();
                controller.fetchLaporan();
              },
            ),
            ListTile(
              title: const Text('Open'),
              onTap: () {
                Get.back();
                controller.fetchLaporan();
              },
            ),
            ListTile(
              title: const Text('On Progress'),
              onTap: () {
                Get.back();
                controller.fetchLaporan();
              },
            ),
            ListTile(
              title: const Text('Done'),
              onTap: () {
                Get.back();
                controller.fetchLaporan();
              },
            ),
          ],
        ),
      ),
    );
  }
}
