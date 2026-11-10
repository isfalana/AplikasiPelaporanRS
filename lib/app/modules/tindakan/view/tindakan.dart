import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/dashboard_controller.dart';
import '../controllers/tindakan_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/sidebar_widgets.dart';
import '../../../routes/app_pages.dart';

class TindakanView extends GetView<TindakanController> {
  const TindakanView({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: isMobile
              ? SidebarWidget.mobileAppBar(title: 'Tindakan')
              : null,
          drawer: isMobile
              ? SidebarWidget.mobileDrawer(
                  child: _buildSidebar(
                    dashboardController,
                    isCollapsed: false,
                    isMobile: true,
                  ),
                )
              : null,
          body: isMobile
              ? _buildContent()
              : Obx(() {
                  final isCollapsed =
                      dashboardController.isSidebarCollapsed.value;
                  return Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        width: isCollapsed ? 76 : 248,
                        child: _buildSidebar(
                          dashboardController,
                          isCollapsed: isCollapsed,
                          isMobile: false,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _buildDesktopAppBar(dashboardController),
                            const Expanded(child: _TindakanContent()),
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

  Widget _buildContent() => const _TindakanContent();

  Widget _buildDesktopAppBar(DashboardController dashboardController) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Obx(
            () => IconButton(
              tooltip: dashboardController.isSidebarCollapsed.value
                  ? 'Buka sidebar'
                  : 'Ciutkan sidebar',
              onPressed: dashboardController.isSidebarCollapsed.toggle,
              icon: const Icon(Icons.menu_rounded, color: AppColors.textStrong),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Tindakan',
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: dashboardController.logout,
            icon: const Icon(Icons.logout_outlined, size: 18),
            label: const Text('Keluar'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textWeak),
          ),
        ],
      ),
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
        currentRoute: Routes.TINDAKAN,
        unitName: dashboardController.unitName.value,
        employeeName: dashboardController.employeeName.value,
        isMasterExpanded: dashboardController.isMasterExpanded.value,
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

class _TindakanContent extends GetView<TindakanController> {
  const _TindakanContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final contentWidth = constraints.maxWidth - 40;
        final formWidth = isWide ? (contentWidth - 20) * 0.6 : contentWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tindakan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
              const Text(
                'Pesan tindakan dan tindak lanjut laporan.',
                style: TextStyle(fontSize: 13, color: AppColors.textWeak),
              ),
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: formWidth, child: _buildActionForm()),
                    const SizedBox(width: 20),
                    const Expanded(child: _ReportList()),
                  ],
                )
              else ...[
                _buildActionForm(),
                const SizedBox(height: 24),
                const _ReportList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionForm() {
    return Obx(() {
      final report = controller.selectedReport.value;
      if (report == null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _decoration(),
          child: const Text(
            'Pilih laporan pada daftar untuk mengisi tindak lanjut.',
            style: TextStyle(color: AppColors.textWeak),
          ),
        );
      }

      final details = <(String, String)>[
        ('ID laporan', _value(report, 'id_laporan')),
        ('Tanggal laporan', _value(report, 'tgl_laporan', 'tanggal_laporan')),
        ('Tanggal kejadian', _value(report, 'tgl_kejadian')),
        ('Deadline', _value(report, 'deadline')),
        ('ID tindak lanjut', _value(report, 'id_tindak_lanjut')),
        ('Perihal', _value(report, 'perihal')),
        (
          'Pelapor',
          [
            _value(report, 'id_nik_pelapor', 'nik_pelapor'),
            _value(report, 'id_unit_pelapor', 'unit_pelapor'),
          ].where((value) => value != '-').join(' - '),
        ),
        ('Kategori', _value(report, 'id_kategori', 'kategori')),
        (
          'PIC',
          [
            _value(report, 'id_nik_pic', 'nik_pic'),
            _value(report, 'id_unit_pic', 'unit_pic'),
          ].where((value) => value != '-').join(' - '),
        ),
        ('Prioritas', _value(report, 'prioritas')),
        ('Bukti laporan', _value(report, 'bukti', 'file_lampiran')),
        ('Keterangan laporan', _value(report, 'keterangan')),
      ];

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _decoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Laporan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final spacing = constraints.maxWidth < 360 ? 10.0 : 16.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: 12,
                  children: details
                      .map(
                        (detail) => SizedBox(
                          width: itemWidth,
                          child: _ReadOnlyInfo(
                            label: detail.$1,
                            value: detail.$2,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const Divider(height: 28),
            const Text(
              'Tindak Lanjut',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final templates = controller.actionTemplates;
              if (templates.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DropdownButtonFormField<String>(
                  decoration: _inputDecoration(
                    hint: 'Pilih template tindak lanjut',
                  ),
                  items: templates
                      .map(
                        (template) => DropdownMenuItem<String>(
                          value: template['id_template']?.toString(),
                          child: Text(
                            template['nama_template']?.toString() ??
                                template['id_template']?.toString() ??
                                '-',
                          ),
                        ),
                      )
                      .where((item) => item.value != null)
                      .toList(),
                  onChanged: (templateId) {
                    if (templateId == null) return;
                    for (final template in templates) {
                      if (template['id_template']?.toString() == templateId) {
                        controller.applyTemplate(template);
                        break;
                      }
                    }
                  },
                ),
              );
            }),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.actionInputController,
                    onSubmitted: (_) => _addActionItem(),
                    decoration: _inputDecoration(
                      hint: 'Tuliskan langkah tindak lanjut...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _addActionItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.actionItems.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Belum ada tindak lanjut.',
                    style: TextStyle(color: AppColors.textWeak, fontSize: 12),
                  ),
                );
              }
              return Column(
                children: controller.actionItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isDone = item['selesai'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isDone,
                          activeColor: AppColors.primary,
                          onChanged: (value) =>
                              controller.toggleActionItem(index, value),
                        ),
                        Expanded(
                          child: Text(
                            item['deskripsi_tindakan']?.toString() ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDone
                                  ? AppColors.textWeak
                                  : AppColors.textStrong,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hapus tindak lanjut',
                          onPressed: () => controller.removeActionItem(index),
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textWeak,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 12),
            const Text(
              'Keterangan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller.noteController,
              maxLines: 3,
              decoration: _inputDecoration(
                hint: 'Tuliskan keterangan tindak lanjut...',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Obx(
                      () => DropdownButton<String>(
                        value: controller.selectedStatus.value,
                        items: const [
                          DropdownMenuItem(value: 'Open', child: Text('Open')),
                          DropdownMenuItem(
                            value: 'On Progress',
                            child: Text('On Progress'),
                          ),
                          DropdownMenuItem(value: 'Done', child: Text('Done')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedStatus.value = value;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _saveAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Kirim Tindakan'),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _addActionItem() {
    final added = controller.addActionItem(
      controller.actionInputController.text,
    );
    controller.actionInputController.clear();
    if (!added) {
      Get.snackbar(
        'Perhatian',
        'Isi tindak lanjut terlebih dahulu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _saveAction() {
    final error = controller.saveAction();
    Get.snackbar(
      error == null ? 'Berhasil' : 'Perhatian',
      error ?? 'Tindak lanjut berhasil disimpan.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error == null ? AppColors.primary : AppColors.warning,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  String _value(Map<String, dynamic> report, String key, [String? fallback]) {
    final value = report[key] ?? (fallback == null ? null : report[fallback]);
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }
}

class _ReportList extends GetView<TindakanController> {
  const _ReportList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Tindakan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final reports = controller.reportsForCurrentUser;
          if (reports.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: _decoration(),
              child: const Center(
                child: Text(
                  'Belum ada pesan tindakan untuk akun ini.',
                  style: TextStyle(color: AppColors.textWeak),
                ),
              ),
            );
          }

          return Column(
            children: reports
                .map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ReportCard(
                      report: report,
                      onTap: () => controller.selectReport(report),
                    ),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});

  final Map<String, dynamic> report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(report['status']?.toString());
    final priorityColor = switch (report['prioritas']?.toString()) {
      'Tinggi' => AppColors.error,
      'Sedang' => AppColors.warning,
      _ => AppColors.success,
    };
    final color = switch (status) {
      'Done' => AppColors.success,
      'On Progress' => AppColors.info,
      _ => AppColors.warning,
    };

    return Material(
      color: AppColors.white,
      surfaceTintColor: AppColors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _decoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report['id_laporan']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _StatusPill(status: status, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report['perihal']?.toString() ?? '-',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 20,
                runSpacing: 14,
                children: [
                  _ReportCardInfo(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal laporan',
                    value:
                        report['tgl_laporan']?.toString() ??
                        report['tanggal_laporan']?.toString() ??
                        '-',
                  ),
                  _ReportCardInfo(
                    icon: Icons.event_outlined,
                    label: 'Deadline',
                    value: report['deadline']?.toString() ?? '-',
                  ),
                  _ReportCardInfo(
                    icon: Icons.person_outline,
                    label: 'Pelapor',
                    value:
                        '${report['id_nik_pelapor'] ?? '-'} - ${report['id_unit_pelapor'] ?? '-'}',
                  ),
                  _ReportCardInfo(
                    icon: Icons.history_outlined,
                    label: 'Last update by',
                    value:
                        report['last_update_by']?.toString() ??
                        report['lastUpdateBy']?.toString() ??
                        report['update_by']?.toString() ??
                        report['updateBy']?.toString() ??
                        '-',
                  ),
                  _PriorityInfo(
                    value: report['prioritas']?.toString() ?? '-',
                    color: priorityColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyInfo extends StatelessWidget {
  const _ReadOnlyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textWeak,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(color: AppColors.textStrong, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ReportCardInfo extends StatelessWidget {
  const _ReportCardInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textWeak),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? '-' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityInfo extends StatelessWidget {
  const _PriorityInfo({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_outlined, size: 15, color: color),
        const SizedBox(width: 5),
        RichText(
          text: TextSpan(
            style: TextStyle(color: color, fontSize: 12),
            children: [
              const TextSpan(
                text: 'Prioritas: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

BoxDecoration _decoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppColors.divider),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

String _statusLabel(String? status) {
  return switch (status?.trim().toLowerCase()) {
    'done' || 'selesai' => 'Done',
    'on progress' || 'on progres' || 'proses' || 'in progress' => 'On Progress',
    _ => 'Open',
  };
}
