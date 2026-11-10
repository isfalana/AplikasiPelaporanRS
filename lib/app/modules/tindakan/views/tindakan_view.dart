import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/tindakan_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/main_layout_shell.dart';

class TindakanView extends GetView<TindakanController> {
  const TindakanView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutShell(
      activeRoute: Routes.TINDAKAN,
      title: 'Tindakan',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Segarkan Data Tindakan',
          onPressed: controller.fetchDaftarLaporan,
        ),
      ],
      child: ResponsiveLayout(
        mobile: _buildMobileView(context),
        desktop: _buildDesktopView(context),
      ),
    );
  }

  // =========================================================================
  // DESKTOP VIEW (Sesuai Mockup Tindakan-dekstop.png & Lihat Tindakan-dekstop.png)
  // =========================================================================
  Widget _buildDesktopView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Judul Halaman
          const Text(
            'Tindakan',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle Dinamis (Pesan tindakan.... ATAU Tindakan / Lihat Tindakan + Badge Open)
          Obx(() {
            final active = controller.selectedLaporan.value;
            if (active == null) {
              return const Text(
                'Pesan tindakan....',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              );
            }

            final status = active['status']?.toString() ?? 'Open';
            return Row(
              children: [
                const Text(
                  'Tindakan / Lihat Tindakan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(width: 16),
                _buildStatusBadge(status),
              ],
            );
          }),
          const SizedBox(height: 32),

          // 2 Kolom: Kiri Detail & Aksi Tindakan, Kanan Daftar Daftar Laporan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KOLOM KIRI: FORM TINDAKAN & DETAIL LAPORAN AKTIF
              Expanded(
                flex: 6,
                child: _buildFormTindakan(context, isMobile: false),
              ),

              const SizedBox(width: 48),

              // KOLOM KANAN: DAFTAR DAFTAR LAPORAN UNTUK DITINDAK
              Expanded(
                flex: 5,
                child: _buildDaftarTindakan(context, isMobile: false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MOBILE VIEW (Sesuai Mockup Tindakan-mobile.png & Detail tindakan-mobile.png)
  // =========================================================================
  Widget _buildMobileView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Tindakan Masuk',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.primary, size: 24),
                tooltip: 'Filter Tindakan',
                onPressed: () => _showFilterOptions(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daftar Kartu Laporan Mobile
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ));
            }

            final list = controller.filteredLaporan;
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('Tidak ada laporan tindakan untuk saat ini', style: TextStyle(color: Colors.grey)),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return _buildMobileTindakanCard(context, item);
              },
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // FORM TINDAKAN DESKTOP
  // =========================================================================
  Widget _buildFormTindakan(BuildContext context, {required bool isMobile}) {
    return Obx(() {
      final item = controller.selectedLaporan.value;

      final tglLaporan = item != null ? controller.formatDate(item['tgl_kejadian'] ?? item['created_at']) : '-';
      final tglKejadian = item != null ? controller.formatDate(item['tgl_kejadian']) : '-';
      final deadline = item != null ? controller.formatDate(item['deadline'] ?? item['tgl_kejadian']) : '-';
      final perihal = item != null ? (item['perihal']?.toString() ?? '-') : '-';

      String pelapor = '-';
      if (item != null) {
        if (item['user_pelapor'] != null && item['user_pelapor'] is Map) {
          final uName = item['user_pelapor']['nama_karyawan'] ?? '';
          final unit = item['unit_pelapor']?['nama_unit'] ?? '';
          pelapor = unit.isNotEmpty ? '$uName - $unit' : uName;
        } else if (item['unit_pelapor'] != null && item['unit_pelapor'] is Map) {
          pelapor = item['unit_pelapor']['nama_unit']?.toString() ?? '-';
        }
      }

      String kategori = '-';
      if (item != null && item['kategori'] != null && item['kategori'] is Map) {
        kategori = item['kategori']['jenis_kategori']?.toString() ?? '-';
      }

      String pic = '-';
      if (item != null && item['unit_pic'] != null && item['unit_pic'] is Map) {
        pic = item['unit_pic']['nama_unit']?.toString() ?? '-';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: Tanggal Laporan, Tanggal Kejadian, Pelapor
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoField('Tanggal Laporan', tglLaporan),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInfoField('Tanggal Kejadian', tglKejadian),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInfoField('Pelapor', pelapor),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Baris 2: Kategori, PIC, Deadline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoField('Kategori', kategori),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInfoField('PIC', pic),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInfoField('Deadline', deadline),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Baris 3: Perihal & Upload Bukti
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildInfoField('Perihal', perihal),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upload Bukti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 8),
                    if (item != null)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('lihat disini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          const Text('bukti.jpg', style: TextStyle(fontSize: 13, color: Colors.black87)),
                        ],
                      )
                    else
                      const Text('-', style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Tindak Lanjut Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tindak Lanjut', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              InkWell(
                onTap: controller.showTambahTindakanDialog,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Text(
                    '+ Tambah Tindakan',
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Daftar Tindakan Checklist
          Obx(() {
            final items = controller.listTindakanChecklist;
            if (items.isEmpty) {
              return const Text('Belum ada butir tindakan. Klik "+ Tambah Tindakan" di atas.', style: TextStyle(fontSize: 13, color: Colors.grey));
            }

            return Column(
              children: items.map((chk) {
                return Obx(() {
                  final bool isChecked = (chk['checked'] as RxBool).value;
                  return InkWell(
                    onTap: () => (chk['checked'] as RxBool).value = !isChecked,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Icon(
                            isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isChecked ? AppColors.primary : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              chk['text'].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                color: isChecked ? Colors.grey : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              }).toList(),
            );
          }),
          const SizedBox(height: 24),

          // Keterangan Text Area
          const Text('Keterangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
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
              controller: controller.keteranganController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tuliskan catatan tindak lanjut di sini...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Status Dropdown
          const Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 8),
          Container(
            width: 200,
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
                value: controller.selectedStatus.value,
                items: ['Open', 'On Progress', 'Done'].map((st) {
                  return DropdownMenuItem<String>(
                    value: st,
                    child: Text(st, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) controller.selectedStatus.value = val;
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Audit Timestamps
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Update by    :  ${item?['user_pic']?['nama_karyawan'] ?? '-'}',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Start Follow-up at :  $tglLaporan',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Done at                :  ${item?['tgl_selesai'] != null ? controller.formatDate(item!['tgl_selesai']) : '-'}',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Tombol Kirim & Batal
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Obx(() => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: (controller.isSubmitting.value || item == null) ? null : controller.submitTindakan,
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
                onPressed: () {
                  if (item != null) controller.selectLaporan(item);
                },
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          )
        ],
      );
    });
  }

  // =========================================================================
  // DAFTAR DAFTAR LAPORAN UNTUK TINDAKAN (DESKTOP)
  // =========================================================================
  Widget _buildDaftarTindakan(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daftar daftar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            IconButton(
              icon: const Icon(Icons.tune, color: AppColors.primary, size: 24),
              tooltip: 'Filter Tindakan',
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

          final list = controller.filteredLaporan;
          if (list.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Belum ada laporan untuk ditindak', style: TextStyle(color: Colors.grey)),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildDesktopTindakanCard(context, item);
            },
          );
        }),
      ],
    );
  }

  Widget _buildDesktopTindakanCard(BuildContext context, Map<String, dynamic> item) {
    final tglLaporan = controller.formatDate(item['tgl_kejadian'] ?? item['created_at']);
    final deadline = controller.formatDate(item['deadline'] ?? item['tgl_kejadian']);
    final perihal = item['perihal']?.toString() ?? '-';
    final status = item['status']?.toString() ?? 'Open';

    String pelapor = '-';
    if (item['user_pelapor'] != null && item['user_pelapor'] is Map) {
      pelapor = item['user_pelapor']['nama_karyawan'] ?? '-';
    } else if (item['unit_pelapor'] != null && item['unit_pelapor'] is Map) {
      pelapor = item['unit_pelapor']['nama_unit'] ?? '-';
    }

    String lastUpdateBy = '';
    if (item['user_pic'] != null && item['user_pic'] is Map) {
      lastUpdateBy = item['user_pic']['nama_karyawan']?.toString() ?? '';
    }

    return Obx(() {
      final isSelected = controller.selectedLaporan.value?['id_laporan'] == item['id_laporan'];

      return InkWell(
        onTap: () => controller.selectLaporan(item),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
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
              // Baris 1: Tanggal Laporan, Deadline, Status Badge
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
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 12),

              // Baris 2: Perihal dan Pelapor
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
                        const Text('Pelapor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 2),
                        Text(pelapor, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
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
        ),
      );
    });
  }

  // =========================================================================
  // KARTU TINDAKAN MOBILE (Detail Tindakan Mobile Dialog)
  // =========================================================================
  Widget _buildMobileTindakanCard(BuildContext context, Map<String, dynamic> item) {
    final tglLaporan = controller.formatDate(item['tgl_kejadian'] ?? item['created_at']);
    final deadline = controller.formatDate(item['deadline'] ?? item['tgl_kejadian']);
    final perihal = item['perihal']?.toString() ?? '-';
    final status = item['status']?.toString() ?? 'Open';

    String pelapor = '-';
    if (item['user_pelapor'] != null && item['user_pelapor'] is Map) {
      pelapor = item['user_pelapor']['nama_karyawan'] ?? '-';
    }

    return InkWell(
      onTap: () => _openDetailTindakanMobile(context, item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Deadline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(deadline, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Perihal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(perihal, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pelapor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(pelapor, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailTindakanMobile(BuildContext context, Map<String, dynamic> item) {
    controller.selectLaporan(item);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Detail & Input Tindakan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
                ],
              ),
              const Divider(),
              _buildFormTindakan(context, isMobile: true),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================
  Widget _buildInfoField(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF2563EB); // Blue Open
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
            const Text('Filter Tindakan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Semua Status'),
              onTap: () {
                Get.back();
                controller.applyFilter('Semua');
              },
            ),
            ListTile(
              title: const Text('Open'),
              onTap: () {
                Get.back();
                controller.applyFilter('Open');
              },
            ),
            ListTile(
              title: const Text('On Progress'),
              onTap: () {
                Get.back();
                controller.applyFilter('On Progress');
              },
            ),
            ListTile(
              title: const Text('Done'),
              onTap: () {
                Get.back();
                controller.applyFilter('Done');
              },
            ),
          ],
        ),
      ),
    );
  }
}
