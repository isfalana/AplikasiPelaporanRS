import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/tindakan_controller.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/filter_menu_button.dart';
import '../../../global_widgets/image_upload_field.dart';
import '../../../global_widgets/main_layout_widget.dart';
import '../../../global_widgets/report_style_card.dart';

class TindakanView extends GetView<TindakanController> {
  const TindakanView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWidget(title: 'Tindakan', child: const _TindakanContent());
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
        ('Pelapor', controller.reporterLabel(report)),
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
                  style: AppButtons.outlined,
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
            const SizedBox(height: 14),
            ImageUploadField(
              label: 'Upload bukti tindak lanjut',
              fileName: controller.buktiTindakanName.value,
              bytes: controller.buktiTindakanBytes.value,
              onChanged: (name, bytes) {
                controller.buktiTindakanName.value = name;
                controller.buktiTindakanBytes.value = bytes;
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
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
                  style: AppButtons.primary,
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
        Row(
          children: [
            const Expanded(
              child: Text(
                'Daftar Tindakan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => MultiFilterMenuButton(
                selectedValues: controller.listFilters.toSet(),
                entries: reportFilterEntries(includeDone: false),
                onSelected: (values) {
                  controller.listFilters
                    ..clear()
                    ..addAll(values);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final reports = controller.reportsForCurrentUser
              .where(
                (report) => matchesReportFilters(
                  report,
                  controller.listFilters.toSet(),
                ),
              )
              .toList();
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
                      reporter: controller.reporterLabel(report),
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
  const _ReportCard({
    required this.report,
    required this.reporter,
    required this.onTap,
  });

  final Map<String, dynamic> report;
  final String reporter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(report['status']?.toString());
    final priority = report['prioritas']?.toString().trim();
    final priorityColor = switch (priority) {
      'Tinggi' => AppColors.error,
      'Sedang' => AppColors.warning,
      'Rendah' => AppColors.success,
      _ => AppColors.textWeak,
    };
    final kategori = report['id_kategori']?.toString().trim();
    final reportDate =
        report['tgl_laporan']?.toString() ??
        report['tanggal_laporan']?.toString() ??
        '-';
    final deadline = report['deadline']?.toString().trim();
    final lastUpdatedBy =
        report['last_update_by']?.toString() ??
        report['lastUpdateBy']?.toString() ??
        report['update_by']?.toString() ??
        report['updateBy']?.toString() ??
        '-';

    return ReportStyleCard(
      reportId: report['id_laporan']?.toString() ?? '-',
      title: report['perihal']?.toString() ?? '-',
      status: status,
      onTap: onTap,
      metaChips: [
        if (kategori != null && kategori.isNotEmpty)
          ReportMetaChip(icon: Icons.folder_outlined, label: kategori),
        if (priority != null && priority.isNotEmpty && priority != '-')
          ReportMetaChip(
            icon: Icons.flag_outlined,
            label: priority,
            color: priorityColor,
          ),
      ],
      infoItems: [
        ReportInfoItem(
          icon: Icons.calendar_today_outlined,
          label: 'Tanggal laporan',
          value: reportDate,
        ),
        ReportInfoItem(
          icon: Icons.event_outlined,
          label: 'Deadline',
          value: deadline == null || deadline.isEmpty ? '-' : deadline,
        ),
      ],
      people: [
        ReportPersonRow(
          icon: Icons.person_outline,
          label: 'Pelapor',
          value: reporter,
        ),
        ReportPersonRow(
          icon: Icons.history_outlined,
          label: 'Last update by',
          value: lastUpdatedBy,
        ),
      ],
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
