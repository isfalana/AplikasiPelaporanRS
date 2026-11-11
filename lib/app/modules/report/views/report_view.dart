import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/main_layout_widget.dart';
import '../controllers/report_controller.dart';

class ReportView extends GetView<ReportController> {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWidget(
      title: 'Report',
      child: _ReportContent(controller: controller),
    );
  }
}

class _ReportContent extends StatefulWidget {
  const _ReportContent({required this.controller});

  final ReportController controller;

  @override
  State<_ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<_ReportContent> {
  late final TextEditingController _searchController;

  ReportController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chooseRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: controller.dateRange.value,
      helpText: 'Pilih periode laporan',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) controller.dateRange.value = picked;
  }

  Future<void> _exportPdf(int rowCount) async {
    try {
      final document = pw.Document();
      final rows = controller.exportRows;
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Text(
              'LAPORAN PERMATA',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Rekapitulasi ${controller.selectedType.value.toLowerCase()} • '
              '${_periodLabel()} • ${controller.selectedStatus.value} • '
              '${controller.selectedUnit.value}',
            ),
            pw.SizedBox(height: 14),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.6),
                6: const pw.FlexColumnWidth(2.3),
                7: const pw.FlexColumnWidth(1.1),
                8: const pw.FlexColumnWidth(1.3),
                9: const pw.FlexColumnWidth(1.3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: ReportController.exportHeaders
                      .map(
                        (header) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            header,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ...rows.map(
                  (row) => pw.TableRow(
                    children: row
                        .map(
                          (cell) => pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              cell,
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Jumlah data: $rowCount',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );
      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'laporan_permata.pdf',
      );
    } on Exception catch (error) {
      if (mounted) _showExportError('PDF', error);
    }
  }

  Future<void> _exportExcel() async {
    try {
      final workbook = Excel.createExcel();
      final sheet = workbook['Report'];
      sheet.appendRow(
        ReportController.exportHeaders
            .map((header) => TextCellValue(header))
            .toList(),
      );
      for (final row in controller.exportRows) {
        sheet.appendRow(row.map(TextCellValue.new).toList());
      }
      final bytes = workbook.encode();
      if (bytes == null) {
        throw Exception('Data Excel tidak dapat dibuat.');
      }
      await FileSaver.instance.saveFile(
        name: 'laporan_permata_${DateTime.now().millisecondsSinceEpoch}',
        bytes: Uint8List.fromList(bytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    } on Exception catch (error) {
      if (mounted) _showExportError('Excel', error);
    }
  }

  void _showExportError(String format, Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Gagal membuat $format: $error')));
  }

  String _periodLabel() {
    final range = controller.dateRange.value;
    if (range == null) return 'Semua Periode';
    return '${controller.dateText(range.start)} - '
        '${controller.dateText(range.end)}';
  }

  Widget _filterField(String label, Widget child, {double width = 190}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: values.contains(value) ? value : values.first,
      isExpanded: true,
      decoration: _inputDecoration('Pilih'),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _resultRow(bool wide, List<Map<String, dynamic>> reports) {
    final countText = Text(
      '${reports.length} data ditemukan',
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textWeak,
        fontWeight: FontWeight.w600,
      ),
    );
    final exportPdfButton = ElevatedButton.icon(
      onPressed: () => _exportPdf(reports.length),
      icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
      label: const Text('Export PDF'),
      style: AppButtons.danger,
    );
    final exportExcelButton = ElevatedButton.icon(
      onPressed: _exportExcel,
      icon: const Icon(Icons.table_view_outlined, size: 17),
      label: const Text('Export Excel'),
      style: AppButtons.success,
    );

    if (!wide) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: double.infinity, child: countText),
          exportPdfButton,
          exportExcelButton,
        ],
      );
    }

    // Di layar lebar, jumlah data di kiri dan tombol export di sisi kanan.
    return Row(
      children: [
        Expanded(child: countText),
        const SizedBox(width: 10),
        exportPdfButton,
        const SizedBox(width: 8),
        exportExcelButton,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Obx(() {
          final reports = controller.filteredReports;
          final unitOptions = controller.units;

          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Rekapitulasi laporan dan tindak lanjut berdasarkan periode, '
                  'jenis, status, dan unit.',
                  style: TextStyle(fontSize: 13, color: AppColors.textWeak),
                ),
                const SizedBox(height: 20),
                _buildFilters(wide, unitOptions),
                const SizedBox(height: 18),
                _resultRow(wide, reports),
                const SizedBox(height: 12),
                if (reports.isEmpty)
                  _emptyResults()
                else if (wide)
                  _desktopTable(reports)
                else
                  ...reports.map(_mobileCard),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildFilters(bool wide, List<String> unitOptions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          _filterField(
            'Periode',
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _chooseRange,
                icon: const Icon(Icons.calendar_month_outlined, size: 17),
                label: Obx(
                  () => Text(
                    controller.dateRange.value == null
                        ? 'Pilih rentang tanggal'
                        : _periodLabel(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textStrong,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: AppButtons.shape,
                ),
              ),
            ),
            width: wide ? 250 : 280,
          ),
          _filterField(
            'Jenis',
            Obx(
              () => _dropdown(
                controller.selectedType.value,
                const ['Semua', 'Laporan', 'Tindakan'],
                (value) {
                  if (value != null) controller.selectedType.value = value;
                },
              ),
            ),
          ),
          _filterField(
            'Status',
            Obx(
              () => _dropdown(
                controller.selectedStatus.value,
                const ['Semua', 'Open', 'On Progress', 'Done'],
                (value) {
                  if (value != null) controller.selectedStatus.value = value;
                },
              ),
            ),
          ),
          _filterField(
            'Unit',
            Obx(
              () => _dropdown(controller.selectedUnit.value, unitOptions, (
                value,
              ) {
                if (value != null) controller.selectedUnit.value = value;
              }),
            ),
          ),
          _filterField(
            'Pencarian',
            SizedBox(
              height: 46,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => controller.searchQuery.value = value,
                decoration: _inputDecoration('Cari perihal, pelapor, PIC...')
                    .copyWith(prefixIcon: const Icon(Icons.search, size: 18)),
              ),
            ),
            width: wide ? 230 : 280,
          ),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              controller.resetFilters();
            },
            style: AppButtons.outlined,
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _emptyResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 34, color: AppColors.textWeak),
          SizedBox(height: 8),
          Text(
            'Tidak ada data untuk filter ini.',
            style: TextStyle(color: AppColors.textWeak),
          ),
        ],
      ),
    );
  }

  Widget _desktopTable(List<Map<String, dynamic>> reports) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F1F6)),
          columns: const [
            DataColumn(label: Text('Tanggal Laporan')),
            DataColumn(label: Text('Tanggal Kejadian')),
            DataColumn(label: Text('Kategori')),
            DataColumn(label: Text('Perihal')),
            DataColumn(label: Text('Pelapor')),
            DataColumn(label: Text('PIC')),
            DataColumn(label: Text('Tindakan')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Tanggal Mulai Tindak Lanjut')),
            DataColumn(label: Text('Tanggal Selesai')),
          ],
          rows: reports
              .map(
                (report) => DataRow(
                  cells: [
                    DataCell(
                      Text(controller.dateText(controller.reportDate(report))),
                    ),
                    DataCell(Text(controller.eventDate(report))),
                    DataCell(Text(controller.category(report))),
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Text(
                          controller.reportTitle(report),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(controller.reporter(report))),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          controller.pic(report),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Text(
                          controller
                              .actions(report)
                              .map(
                                (action) =>
                                    '${controller.isActionComplete(report, action) ? '[x]' : '[ ]'} ${action['deskripsi_tindakan'] ?? '-'}',
                              )
                              .join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(_statusPill(controller.status(report))),
                    DataCell(Text(controller.actionStartDate(report))),
                    DataCell(Text(controller.completionDate(report))),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _mobileCard(Map<String, dynamic> report) {
    final actions = controller.actions(report);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  controller.reportTitle(report),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _statusPill(controller.status(report)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Laporan ${controller.dateText(controller.reportDate(report))} • '
            'Kejadian ${controller.eventDate(report)} • '
            '${controller.category(report)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textWeak),
          ),
          const SizedBox(height: 5),
          Text(
            'Pelapor: ${controller.reporter(report)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'PIC: ${controller.pic(report)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Deadline: ${controller.value(report, 'deadline')}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Mulai tindak lanjut: ${controller.actionStartDate(report)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Tanggal selesai: ${controller.completionDate(report)}',
            style: const TextStyle(fontSize: 12),
          ),
          if (actions.isNotEmpty) ...[
            const Divider(height: 18),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(
                      controller.isActionComplete(report, action)
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        action['deskripsi_tindakan']?.toString() ?? '-',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = switch (status) {
      'Done' => AppColors.success,
      'On Progress' => AppColors.info,
      _ => AppColors.warning,
    };
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

  InputDecoration _inputDecoration(String hint) {
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
}
