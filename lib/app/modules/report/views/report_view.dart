import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:excel/excel.dart' as excel show Border, BorderStyle;
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

      // Pakai sheet bawaan sebagai sheet laporan agar tidak ada sheet kosong.
      final defaultSheet = workbook.getDefaultSheet();
      if (defaultSheet != null && defaultSheet != 'Report') {
        workbook.rename(defaultSheet, 'Report');
      }
      final sheet = workbook['Report'];
      for (final name in workbook.sheets.keys.toList()) {
        if (name != 'Report') workbook.delete(name);
      }
      workbook.setDefaultSheet('Report');

      final headers = ReportController.exportHeaders;
      final rows = controller.exportRows;
      final lastColumn = headers.length - 1;
      final border = excel.Border(
        borderStyle: excel.BorderStyle.Thin,
        borderColorHex: ExcelColor.grey400,
      );
      final headerStyle = CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.fromHexString('FF8C3DD8'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
        leftBorder: border,
        rightBorder: border,
        topBorder: border,
        bottomBorder: border,
      );
      final bodyStyle = CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('FF333333'),
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
        leftBorder: border,
        rightBorder: border,
        topBorder: border,
        bottomBorder: border,
      );
      final alternateStyle = bodyStyle.copyWith(
        backgroundColorHexVal: ExcelColor.grey50,
      );

      void writeMergedRow(
        int rowIndex,
        String text,
        CellStyle style, {
        double height = 22,
      }) {
        final start = CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: rowIndex,
        );
        final end = CellIndex.indexByColumnRow(
          columnIndex: lastColumn,
          rowIndex: rowIndex,
        );
        sheet.merge(start, end, customValue: TextCellValue(text));
        for (var column = 0; column <= lastColumn; column++) {
          sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: column,
                      rowIndex: rowIndex,
                    ),
                  )
                  .cellStyle =
              style;
        }
        sheet.setRowHeight(rowIndex, height);
      }

      writeMergedRow(
        0,
        'LAPORAN PERMATA',
        CellStyle(
          bold: true,
          fontSize: 16,
          fontColorHex: ExcelColor.fromHexString('FF333333'),
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        ),
        height: 28,
      );
      writeMergedRow(
        1,
        'Rekapitulasi Laporan dan Tindak Lanjut',
        CellStyle(
          fontSize: 11,
          fontColorHex: ExcelColor.grey700,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        ),
      );
      writeMergedRow(
        2,
        'Periode: ${_periodLabel()}    •    Jenis: '
        '${controller.selectedType.value}    •    Status: '
        '${controller.selectedStatus.value}    •    Unit: '
        '${controller.selectedUnit.value}',
        CellStyle(
          fontSize: 9,
          fontColorHex: ExcelColor.grey600,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        ),
      );
      sheet.setRowHeight(3, 8);

      const headerRow = 4;
      for (var column = 0; column < headers.length; column++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: column, rowIndex: headerRow),
        );
        cell.value = TextCellValue(headers[column]);
        cell.cellStyle = headerStyle;
      }
      sheet.setRowHeight(headerRow, 34);

      for (var index = 0; index < rows.length; index++) {
        final rowIndex = headerRow + 1 + index;
        sheet.insertRowIterables(
          rows[index].map(TextCellValue.new).toList(),
          rowIndex,
        );
        final style = index.isEven ? bodyStyle : alternateStyle;
        for (var column = 0; column < headers.length; column++) {
          sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: column,
                      rowIndex: rowIndex,
                    ),
                  )
                  .cellStyle =
              style;
        }
        sheet.setRowHeight(rowIndex, 30);
      }

      final footerRow = headerRow + rows.length + 2;
      writeMergedRow(
        footerRow,
        'Jumlah data: ${rows.length}',
        CellStyle(
          bold: true,
          fontSize: 10,
          fontColorHex: ExcelColor.fromHexString('FF333333'),
          horizontalAlign: HorizontalAlign.Left,
          verticalAlign: VerticalAlign.Center,
        ),
      );
      final printed = DateTime.now();
      writeMergedRow(
        footerRow + 1,
        'Dicetak: ${printed.day.toString().padLeft(2, '0')}/'
        '${printed.month.toString().padLeft(2, '0')}/${printed.year} '
        '${printed.hour.toString().padLeft(2, '0')}:'
        '${printed.minute.toString().padLeft(2, '0')}',
        CellStyle(
          fontSize: 9,
          fontColorHex: ExcelColor.grey600,
          horizontalAlign: HorizontalAlign.Left,
          verticalAlign: VerticalAlign.Center,
        ),
      );

      const columnWidths = <double>[14, 14, 18, 34, 26, 24, 36, 12, 20, 14];
      for (var column = 0; column < columnWidths.length; column++) {
        sheet.setColumnWidth(column, columnWidths[column]);
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

  Widget _filterField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: AppColors.textWeak,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
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
                _buildFilters(unitOptions),
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

  Widget _buildFilters(List<String> unitOptions) {
    final fields = <Widget>[
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
                    ? 'Semua periode'
                    : _periodLabel(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textStrong,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: AppButtons.shape,
            ),
          ),
        ),
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
          () => _dropdown(controller.selectedUnit.value, unitOptions, (value) {
            if (value != null) controller.selectedUnit.value = value;
          }),
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter laporan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Persempit data berdasarkan periode, jenis, status, dan unit.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textWeak,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    controller.resetFilters();
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 860
                        ? 4
                        : constraints.maxWidth >= 520
                        ? 2
                        : 1;
                    const gap = 14.0;
                    final fieldWidth =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: 14,
                      children: fields
                          .map(
                            (field) =>
                                SizedBox(width: fieldWidth, child: field),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => controller.searchQuery.value = value,
                  decoration:
                      _inputDecoration('Cari perihal, pelapor, atau PIC...')
                          .copyWith(
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: Obx(
                              () => controller.searchQuery.value.isEmpty
                                  ? const SizedBox.shrink()
                                  : IconButton(
                                      tooltip: 'Hapus pencarian',
                                      onPressed: () {
                                        _searchController.clear();
                                        controller.searchQuery.value = '';
                                      },
                                      icon: const Icon(Icons.close, size: 17),
                                    ),
                            ),
                          ),
                ),
              ],
            ),
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
    final status = controller.status(report);
    final statusColor = _statusColor(status);
    final actions = controller.actions(report);
    final completed = actions
        .where((action) => controller.isActionComplete(report, action))
        .length;
    final progress = actions.isEmpty ? 0.0 : completed / actions.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.sidebarDark.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.value(report, 'id_laporan'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.textWeak,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.reportTitle(report),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _statusPill(status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _metaChip(
                      Icons.folder_outlined,
                      controller.category(report),
                    ),
                    if (actions.isNotEmpty)
                      _metaChip(
                        Icons.checklist_rounded,
                        '${actions.length} tindakan',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoGrid(report),
                const SizedBox(height: 12),
                _personRow(
                  Icons.account_circle_outlined,
                  'Pelapor',
                  controller.reporter(report),
                ),
                const SizedBox(height: 8),
                _personRow(
                  Icons.assignment_ind_outlined,
                  'PIC',
                  controller.pic(report),
                ),
                if (actions.isNotEmpty) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Progres tindakan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completed/${actions.length} selesai',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...actions.map((action) {
                    final complete = controller.isActionComplete(
                      report,
                      action,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            complete
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: complete
                                ? AppColors.success
                                : AppColors.textWeak,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              action['deskripsi_tindakan']?.toString() ?? '-',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: complete
                                    ? AppColors.textWeak
                                    : AppColors.textStrong,
                                decoration: complete
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textWeak),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textWeak,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoGrid(Map<String, dynamic> report) {
    final items = <(IconData, String, String)>[
      (
        Icons.calendar_today_outlined,
        'Tanggal laporan',
        controller.dateText(controller.reportDate(report)),
      ),
      (Icons.event_outlined, 'Tanggal kejadian', controller.eventDate(report)),
      (
        Icons.play_circle_outline,
        'Mulai tindak lanjut',
        controller.actionStartDate(report),
      ),
      (
        Icons.task_alt_rounded,
        'Tanggal selesai',
        controller.completionDate(report),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(item.$1, size: 13, color: AppColors.textWeak),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                item.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textWeak,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _personRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textWeak,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Done' => AppColors.success,
      'On Progress' => AppColors.info,
      _ => AppColors.warning,
    };
  }

  Widget _statusPill(String status) {
    final color = _statusColor(status);
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
      fillColor: AppColors.surface,
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
