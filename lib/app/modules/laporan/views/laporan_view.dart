import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/laporan_controller.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/bukti_preview.dart';
import '../../../global_widgets/filter_menu_button.dart';
import '../../../global_widgets/image_upload_field.dart';
import '../../../global_widgets/main_layout_widget.dart';
import '../../../global_widgets/report_style_card.dart';

class LaporanView extends GetView<LaporanController> {
  const LaporanView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWidget(
      title: 'Daftar Laporan RS',
      child: _LaporanContent(controller: controller),
    );
  }
}

class _LaporanContent extends StatefulWidget {
  const _LaporanContent({required this.controller});

  final LaporanController controller;

  @override
  State<_LaporanContent> createState() => _LaporanContentState();
}

class _LaporanContentState extends State<_LaporanContent> {
  final _perihalController = TextEditingController();
  final _buktiController = TextEditingController();

  DateTime _tanggalKejadian = DateTime.now();
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  String _activeNik = '';
  String _activeName = '';
  String _activeUnit = '';
  String? _selectedKategori;
  String? _selectedPrioritas;
  final List<String> _selectedPics = [];
  Uint8List? _buktiBytes;
  Map<String, dynamic>? _editingReport;
  Map<String, dynamic>? _viewingReport;

  // Filter aktif pada card "Daftar Laporan". Bisa lebih dari satu.
  final Set<String> _reportFilters = {};

  LaporanController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _resetForm(notify: false);
    _loadActiveUser();
  }

  Future<void> _loadActiveUser() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _activeNik = preferences.getString('id_nik') ?? '';
      _activeName = preferences.getString('nama_karyawan') ?? '';
      _activeUnit = preferences.getString('unit_name') ?? '';
    });
  }

  @override
  void dispose() {
    _perihalController.dispose();
    _buktiController.dispose();
    super.dispose();
  }

  List<String> _availableValues(String key) {
    return controller.listLaporan
        .map((report) => report[key]?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  void _resetForm({bool notify = true}) {
    void reset() {
      _editingReport = null;
      _tanggalKejadian = DateTime.now();
      _deadline = DateTime.now().add(const Duration(days: 1));
      _selectedKategori = null;
      _selectedPrioritas = _priorityForDeadline(_deadline);
      _selectedPics.clear();
      _perihalController.clear();
      _buktiController.clear();
      _buktiBytes = null;
    }

    if (notify) {
      setState(reset);
    } else {
      reset();
    }
  }

  void _loadForEdit(Map<String, dynamic> report) {
    setState(() {
      _viewingReport = null;
      _editingReport = report;
      _tanggalKejadian =
          _parseDate(report['tgl_kejadian']?.toString()) ?? DateTime.now();
      _deadline =
          _parseDate(report['deadline']?.toString()) ??
          DateTime.now().add(const Duration(days: 1));
      _selectedKategori = report['id_kategori']?.toString();
      _selectedPrioritas =
          report['prioritas']?.toString() ?? _priorityForDeadline(_deadline);
      _selectedPics
        ..clear()
        ..addAll(
          (report['id_nik_pic']?.toString() ?? '')
              .split(',')
              .map((unit) => unit.trim())
              .where((unit) => unit.isNotEmpty),
        );
      _perihalController.text = report['perihal']?.toString() ?? '';
      _buktiController.text = report['bukti']?.toString() ?? '';
      final savedBytes = report['bukti_bytes'];
      _buktiBytes = savedBytes is Uint8List ? savedBytes : null;
    });
  }

  Future<void> _pickDate({required bool isDeadline}) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isDeadline ? _deadline : _tanggalKejadian,
      firstDate: DateTime(2010),
      lastDate: DateTime(2035),
    );
    if (selectedDate == null || !mounted) return;

    setState(() {
      if (isDeadline) {
        _deadline = selectedDate;
        _selectedPrioritas = _priorityForDeadline(selectedDate);
      } else {
        _tanggalKejadian = selectedDate;
      }
    });
  }

  String _priorityForDeadline(DateTime deadline) {
    final reportDate =
        _parseDate(_editingReport?['tgl_laporan']?.toString()) ??
        DateUtils.dateOnly(DateTime.now());
    final remainingDays = DateUtils.dateOnly(deadline)
        .difference(DateUtils.dateOnly(reportDate))
        .inDays;
    if (remainingDays <= 1) return 'Tinggi';
    if (remainingDays <= 3) return 'Sedang';
    return 'Rendah';
  }

  void _submitReport() {
    final title = _perihalController.text.trim();
    if (title.isEmpty) {
      _showMessage('Perihal wajib diisi.');
      return;
    }
    if (_selectedKategori == null) {
      _showMessage('Pilih kategori laporan terlebih dahulu.');
      return;
    }
    if (_activeNik.isEmpty) {
      _showMessage(
        'Data pengguna aktif tidak ditemukan. Silakan login kembali.',
      );
      return;
    }
    if (_selectedPics.isEmpty) {
      _showMessage('Pilih minimal satu orang PIC.');
      return;
    }
    if (_selectedPrioritas == null) {
      _showMessage('Pilih prioritas laporan terlebih dahulu.');
      return;
    }
    if (_deadline.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      _showMessage('Deadline tidak boleh lebih awal dari tanggal laporan.');
      return;
    }

    final isEditing = _editingReport != null;
    final report = <String, dynamic>{
      ...?_editingReport,
      'id_laporan':
          _editingReport?['id_laporan'] ??
          'LAP-${DateTime.now().millisecondsSinceEpoch}',
      'tgl_laporan':
          _editingReport?['tgl_laporan'] ?? _formatDate(DateTime.now()),
      'tgl_kejadian': _formatDate(_tanggalKejadian),
      'id_nik_pelapor': _activeNik,
      'nama_pelapor': _pelaporName(_activeName, _activeNik),
      'id_unit_pelapor': _activeUnit,
      'nama_unit_pelapor': controller.unitName(_activeUnit),
      'id_kategori': _selectedKategori,
      'id_nik_pic': _selectedPics.join(', '),
      'perihal': title,
      'prioritas': _selectedPrioritas,
      'deadline': _formatDate(_deadline),
      'bukti': _buktiController.text.trim(),
      'bukti_bytes': _buktiBytes,
      'status': _displayStatus(_editingReport?['status']?.toString()),
      'tgl_selesai': _editingReport?['tgl_selesai'],
    };

    if (_editingReport == null) {
      report['id_tindak_lanjut'] = null;
      report['id_nik_pic'] = _selectedPics.join(', ');
      controller.listLaporan.insert(0, report);
    } else {
      final index = controller.listLaporan.indexOf(_editingReport!);
      if (index >= 0) {
        controller.listLaporan[index] = report;
      }
    }

    controller.listLaporan.refresh();
    _resetForm();
    _showMessage(
      isEditing ? 'Laporan berhasil diperbarui.' : 'Laporan berhasil dikirim.',
    );
  }

  void _showMessage(String message) {
    Get.snackbar(
      'Informasi',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus laporan?'),
        content: Text('Laporan ${report['id_laporan'] ?? ''} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      controller.listLaporan.remove(report);
      controller.listLaporan.refresh();
      if (mounted) setState(() => _viewingReport = null);
    }
  }

  /// Ringkasan status validasi pelapor pada kartu dan detail laporan.
  String _validationLabel(Map<String, dynamic> report) {
    if (report['validasi_pelapor'] == true) {
      final date = report['tgl_validasi']?.toString().trim() ?? '';
      final by = report['nama_validasi_by']?.toString().trim() ?? '';
      if (date.isNotEmpty && by.isNotEmpty) return '$date oleh $by';
      if (date.isNotEmpty) return 'Tervalidasi $date';
      return 'Tervalidasi';
    }
    return 'Menunggu validasi pelapor';
  }

  /// Pelapor mengonfirmasi bahwa laporan beserta tindak lanjutnya benar-benar
  /// sudah selesai (Done).
  Future<void> _confirmValidate(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Validasi laporan?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
        content: Text(
          'Pastikan laporan ${report['id_laporan'] ?? ''} beserta seluruh '
          'tindak lanjutnya benar-benar sudah selesai. Setelah divalidasi, '
          'kartu laporan akan ditandai tervalidasi.',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textWeak,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textWeak),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.success,
              backgroundColor: AppColors.success.withValues(alpha: 0.08),
            ),
            child: const Text('Valid'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final id = report['id_laporan']?.toString();
    var target = report;
    for (final item in controller.listLaporan) {
      if (item['id_laporan']?.toString() == id) {
        target = item;
        break;
      }
    }
    target['validasi_pelapor'] = true;
    target['tgl_validasi'] = _formatDate(DateTime.now());
    target['validasi_by'] = _activeNik;
    target['nama_validasi_by'] = _pelaporName(_activeName, _activeNik);
    controller.listLaporan.refresh();

    if (!mounted) return;
    setState(() {});
    Get.snackbar(
      'Berhasil',
      'Laporan dan tindak lanjut dinyatakan selesai oleh pelapor.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewingReport case final viewing?) {
      return Obx(() {
        // Baca langsung dari daftar reaktif supaya perubahan dari halaman
        // Tindakan (status, keterangan, bukti, validasi) langsung tampil.
        final reports = controller.listLaporan;
        reports.length;
        Map<String, dynamic> report = viewing;
        final id = viewing['id_laporan']?.toString();
        for (final item in reports) {
          if (item['id_laporan']?.toString() == id) {
            report = item;
            break;
          }
        }
        return _buildDetail(report);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final contentWidth = constraints.maxWidth - 40;
        final formWidth = isWide ? (contentWidth - 20) * 0.6 : contentWidth;
        final formPadding = constraints.maxWidth < 600 ? 14.0 : 20.0;
        final fieldSpacing = constraints.maxWidth < 600 ? 12.0 : 20.0;
        final formContentWidth = formWidth - formPadding * 2 - 2;
        const formColumns = 2;
        final fieldWidth =
            (formContentWidth - (formColumns - 1) * fieldSpacing) / formColumns;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(
                          'Isi informasi laporan dengan lengkap dan benar.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textWeak,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: formWidth,
                      child: _buildForm(
                        fieldWidth,
                        fieldSpacing: fieldSpacing,
                        padding: formPadding,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(child: _buildReportList()),
                  ],
                )
              else ...[
                _buildForm(
                  fieldWidth,
                  fieldSpacing: fieldSpacing,
                  padding: formPadding,
                ),
                const SizedBox(height: 24),
                _buildReportList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Daftar Laporan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
            ),
            const SizedBox(width: 8),
            MultiFilterMenuButton(
              selectedValues: _reportFilters,
              entries: reportFilterEntries(),
              onSelected: (values) => setState(() {
                _reportFilters
                  ..clear()
                  ..addAll(values);
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (controller.listLaporan.isEmpty) {
            return _emptyState();
          }

          return Column(
            children: controller.listLaporan
                .where((report) => matchesReportFilters(report, _reportFilters))
                .map(_buildReportCard)
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildForm(
    double fieldWidth, {
    required double fieldSpacing,
    required double padding,
  }) {
    final categories = _availableValues('id_kategori');
    final picOptions = _availableValues('id_nik_pic')
        .expand((value) => value.split(','))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final priorities = <String>{
      ..._availableValues('prioritas'),
      'Tinggi',
      'Sedang',
      'Rendah',
    }.toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: fieldSpacing,
            runSpacing: 16,
            children: [
              SizedBox(
                width: fieldWidth,
                child: _readOnlyField(
                  'Tanggal laporan',
                  _editingReport?['tgl_laporan']?.toString() ??
                      _formatDate(DateTime.now()),
                  Icons.lock_outline,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _dateField(
                  'Tanggal kejadian',
                  _tanggalKejadian,
                  () => _pickDate(isDeadline: false),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _readOnlyField(
                  'Pelapor',
                  _pelaporLabel(_activeName, _activeNik, _activeUnit),
                  Icons.lock_outline,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _dropdownField(
                  label: 'Kategori',
                  hint: 'Pilih kategori',
                  value: _selectedKategori,
                  values: categories,
                  onChanged: (value) =>
                      setState(() => _selectedKategori = value),
                ),
              ),
              SizedBox(width: fieldWidth, child: _buildPicField(picOptions)),
              SizedBox(
                width: fieldWidth,
                child: _dateField(
                  'Deadline',
                  _deadline,
                  () => _pickDate(isDeadline: true),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _dropdownField(
                  label: 'Prioritas',
                  hint: 'Pilih prioritas',
                  value: _selectedPrioritas,
                  values: priorities,
                  onChanged: (value) =>
                      setState(() => _selectedPrioritas = value),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: ImageUploadField(
                  fileName: _buktiController.text,
                  bytes: _buktiBytes,
                  onChanged: (name, bytes) => setState(() {
                    _buktiController.text = name;
                    _buktiBytes = bytes;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel('Perihal'),
          const SizedBox(height: 6),
          TextField(
            controller: _perihalController,
            decoration: _inputDecoration(hint: 'Ringkasan perihal kendala...'),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _submitReport,
                style: AppButtons.primary,
                child: Text(_editingReport == null ? 'Kirim' : 'Perbarui'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _resetForm,
                style: AppButtons.outlined,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPicField(List<String> picOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('PIC (bisa memilih lebih dari satu)'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedPics.join('|')),
          isExpanded: true,
          decoration: _inputDecoration(
            hint: picOptions.isEmpty ? 'Belum ada pilihan PIC' : 'Tambah PIC',
          ),
          items: picOptions
              .map(
                (pic) =>
                    DropdownMenuItem(value: pic, child: Text(_picLabel(pic))),
              )
              .toList(),
          onChanged: picOptions.isEmpty
              ? null
              : (value) {
                  if (value != null && !_selectedPics.contains(value)) {
                    setState(() => _selectedPics.add(value));
                  }
                },
        ),
        if (_selectedPics.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedPics
                .map(
                  (pic) => Chip(
                    label: Text(
                      _picLabel(pic),
                      style: const TextStyle(fontSize: 11),
                    ),
                    onDeleted: () => setState(() => _selectedPics.remove(pic)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    deleteIconColor: AppColors.primary,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = _displayStatus(report['status']?.toString());
    final priority = report['prioritas']?.toString().trim();
    final priorityColor = switch (priority) {
      'Tinggi' => AppColors.error,
      'Sedang' => AppColors.warning,
      'Rendah' => AppColors.success,
      _ => AppColors.textWeak,
    };
    final reportDate =
        report['tgl_laporan']?.toString() ??
        report['tanggal_laporan']?.toString() ??
        '-';
    final pic = _picDisplay(report);
    final lastUpdatedBy =
        report['last_update_by']?.toString() ??
        report['lastUpdateBy']?.toString() ??
        report['update_by']?.toString() ??
        report['updateBy']?.toString() ??
        '-';
    final kategori = report['id_kategori']?.toString().trim();
    final deadline = report['deadline']?.toString().trim();
    final isDone = status == 'Done';
    final isValidated = report['validasi_pelapor'] == true;

    return ReportStyleCard(
      reportId: report['id_laporan']?.toString() ?? '-',
      title: report['perihal']?.toString() ?? '-',
      status: status,
      onTap: () => setState(() => _viewingReport = report),
      metaChips: [
        if (kategori != null && kategori.isNotEmpty)
          ReportMetaChip(icon: Icons.folder_outlined, label: kategori),
        if (priority != null && priority.isNotEmpty && priority != '-')
          ReportMetaChip(
            icon: Icons.flag_outlined,
            label: priority,
            color: priorityColor,
          ),
        if (isDone && isValidated)
          const ReportMetaChip(
            icon: Icons.verified_outlined,
            label: 'Laporan & tindakan tervalidasi',
            color: AppColors.success,
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
        ReportInfoItem(
          icon: Icons.history_outlined,
          label: 'Last update by',
          value: lastUpdatedBy,
        ),
        if (isDone)
          ReportInfoItem(
            icon: Icons.how_to_reg_outlined,
            label: 'Validasi pelapor',
            value: _validationLabel(report),
          ),
      ],
      people: [
        ReportPersonRow(
          icon: Icons.account_circle_outlined,
          label: 'Pelapor',
          value: _pelaporDisplay(report),
        ),
        ReportPersonRow(
          icon: Icons.assignment_ind_outlined,
          label: 'PIC',
          value: pic,
        ),
      ],
      actions: [
        if (isDone && !isValidated) _validateButton(report),
        _cardActionButton(
          tooltip: 'Edit laporan',
          onPressed: () => _loadForEdit(report),
          icon: const Icon(
            Icons.edit_outlined,
            size: 17,
            color: AppColors.primary,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Aksi laporan',
          padding: EdgeInsets.zero,
          iconSize: 18,
          splashRadius: 16,
          style: IconButton.styleFrom(
            minimumSize: const Size(30, 30),
            maximumSize: const Size(30, 30),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onSelected: (_) => _confirmDelete(report),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ],
    );
  }

  /// Tombol aksi kecil agar area edit/hapus tidak memakan tinggi kartu.
  Widget _cardActionButton({
    required String tooltip,
    required VoidCallback onPressed,
    required Widget icon,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        visualDensity: VisualDensity.compact,
        splashRadius: 15,
        icon: icon,
      ),
    );
  }

  /// Tombol validasi pelapor agar laporan Done dari penindak bisa langsung
  /// divalidasi dengan satu klik dari kartu laporan.
  Widget _validateButton(Map<String, dynamic> report) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: OutlinedButton.icon(
        onPressed: () => _confirmValidate(report),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.success,
          side: const BorderSide(color: AppColors.success),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.how_to_reg_outlined, size: 15),
        label: const Text(
          'Validasi',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _picDisplay(Map<String, dynamic> report) {
    final ids = (report['id_nik_pic']?.toString() ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (ids.isEmpty) return '-';

    final unit =
        report['nama_unit_pic']?.toString() ??
        report['unit_pic']?.toString() ??
        report['id_unit_pic']?.toString();
    return ids.map((id) => _picLabel(id, unit: unit)).join(', ');
  }

  String _picLabel(String nik, {String? unit}) {
    String? name;
    String? employeeUnit = unit;
    for (final report in controller.listLaporan) {
      final reportPics = (report['id_nik_pic']?.toString() ?? '')
          .split(',')
          .map((value) => value.trim());
      if (!reportPics.contains(nik) && report['id_nik']?.toString() != nik) {
        continue;
      }

      for (final key in [
        'nama_karyawan_pic',
        'nama_pegawai_pic',
        'nama_pic',
        'nama_karyawan',
        'nama_pegawai',
      ]) {
        final value = report[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          name = value;
          break;
        }
      }
      employeeUnit ??=
          report['nama_unit_pic']?.toString() ??
          report['unit_pic']?.toString() ??
          report['id_unit_pic']?.toString();
      if (name != null && name.isNotEmpty) break;
    }

    final displayName = name?.isNotEmpty == true ? name! : nik;
    if (employeeUnit == null || employeeUnit.isEmpty) return displayName;
    return '$displayName - $employeeUnit';
  }

  /// Nama pelapor berdasarkan NIK. Bila nama tidak tersedia, pakai NIK.
  String _pelaporName(String name, String nik) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed : nik;
  }

  /// Label pelapor untuk form: "Nama · Unit".
  String _pelaporLabel(String name, String nik, String unit) {
    final displayName = _pelaporName(name, nik);
    final displayUnit = controller.unitName(unit);
    return [
      displayName,
      displayUnit,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  /// Label pelapor pada kartu/detail: "Nama · Unit".
  String _pelaporDisplay(Map<String, dynamic> report) {
    final nik = report['id_nik_pelapor']?.toString().trim() ?? '';
    final name = report['nama_pelapor']?.toString().trim() ?? '';
    final unit =
        report['nama_unit_pelapor']?.toString().trim() ??
        report['id_unit_pelapor']?.toString().trim() ??
        '';
    final displayName = name.isNotEmpty ? name : controller.userName(nik);
    final displayUnit = controller.unitName(unit);
    final values = [
      displayName,
      displayUnit,
    ].where((value) => value.trim().isNotEmpty).toList();
    return values.isEmpty ? '-' : values.join(' · ');
  }

  Widget _buildDetail(Map<String, dynamic> report) {
    final details = <(String, String)>[
      ('Tanggal kejadian', report['tgl_kejadian']?.toString() ?? '-'),
      ('Pelapor', _pelaporDisplay(report)),
      ('Kategori', report['id_kategori']?.toString() ?? '-'),
      ('PIC', _picDisplay(report)),
      ('Prioritas', report['prioritas']?.toString() ?? '-'),
      ('Deadline', report['deadline']?.toString() ?? '-'),
      ('Bukti laporan', report['bukti']?.toString() ?? '-'),
      (
        'Last update by',
        (report['last_update_by'] ?? report['lastUpdateBy'])?.toString() ?? '-',
      ),
    ];
    final actionDetails = _actionDetails(report['detail_tindakan']);
    final actionProgress = _actionProgress(report['progres_tindakan']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _viewingReport = null),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: const Text('Detail Laporan'),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report['perihal']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit laporan',
                      onPressed: () => _loadForEdit(report),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    _statusPill(_displayStatus(report['status']?.toString())),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  report['id_laporan']?.toString() ?? '-',
                  style: const TextStyle(color: AppColors.primary),
                ),
                const Divider(height: 28),
                Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  children: details
                      .map(
                        (detail) => SizedBox(
                          width: 240,
                          child: _detailField(detail.$1, detail.$2),
                        ),
                      )
                      .toList(),
                ),
                if (report['bukti_bytes'] case final Uint8List bytes) ...[
                  const SizedBox(height: 16),
                  BuktiPreviewTile(
                    fileName: report['bukti']?.toString() ?? '',
                    bytes: bytes,
                  ),
                ],
                const Divider(height: 32),
                const Text(
                  'Tindak lanjut',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (actionDetails.isEmpty)
                  const Text(
                    'Belum ada tindakan yang dicatat.',
                    style: TextStyle(color: AppColors.textWeak, fontSize: 13),
                  )
                else
                  Column(
                    children: actionDetails.map((action) {
                      final detailId = action['id_detail']?.toString();
                      final isDone = detailId == null
                          ? false
                          : actionProgress[detailId] ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isDone
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: isDone
                                  ? AppColors.success
                                  : AppColors.textWeak,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                action['deskripsi_tindakan']?.toString() ?? '-',
                                style: const TextStyle(
                                  color: AppColors.textStrong,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isDone ? 'Selesai' : 'Belum selesai',
                              style: TextStyle(
                                color: isDone
                                    ? AppColors.success
                                    : AppColors.textWeak,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                _detailField(
                  'Keterangan tindak lanjut',
                  report['keterangan_tindakan']?.toString() ?? '-',
                ),
                const SizedBox(height: 12),
                _detailField(
                  'Bukti tindak lanjut',
                  report['bukti_tindakan']?.toString() ?? '-',
                ),
                if (report['bukti_tindakan_bytes']
                    case final Uint8List bytes) ...[
                  const SizedBox(height: 8),
                  BuktiPreviewTile(
                    fileName: report['bukti_tindakan']?.toString() ?? '',
                    bytes: bytes,
                  ),
                ],
                _validationSection(report),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _viewingReport = null),
                      child: const Text('Kembali ke daftar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Blok validasi pelapor pada detail laporan berstatus Done.
  Widget _validationSection(Map<String, dynamic> report) {
    if (_displayStatus(report['status']?.toString()) != 'Done') {
      return const SizedBox.shrink();
    }
    final validated = report['validasi_pelapor'] == true;
    final canValidate = !validated;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: validated
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: validated
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                validated ? Icons.verified_outlined : Icons.how_to_reg_outlined,
                size: 18,
                color: validated ? AppColors.success : AppColors.textWeak,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Validasi Pelapor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              _validationPill(validated),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            validated
                ? 'Pelapor menyatakan laporan beserta tindak lanjutnya sudah '
                      'selesai. ${_validationLabel(report)}'
                : 'Penindak menandai laporan ini Done. Pelapor perlu '
                      'memvalidasi bahwa laporan dan tindak lanjut memang sudah '
                      'selesai.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textWeak,
              height: 1.5,
            ),
          ),
          if (canValidate) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _confirmValidate(report),
              style: AppButtons.primary,
              icon: const Icon(Icons.how_to_reg_outlined, size: 17),
              label: const Text('Validasi sebagai Pelapor'),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _actionDetails(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Map<String, bool> _actionProgress(dynamic value) {
    if (value is! List) return {};
    return {
      for (final item in value.whereType<Map>())
        if (item['id_detail'] != null)
          item['id_detail'].toString(): item['selesai'] == true,
    };
  }

  Widget _dropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: values.contains(value) ? value : null,
          isExpanded: true,
          decoration: _inputDecoration(hint: hint),
          items: values
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: values.isEmpty ? null : onChanged,
        ),
      ],
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: _inputDecoration(
              hint: 'Pilih $label',
              suffixIcon: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            child: Text(_formatDate(value)),
          ),
        ),
      ],
    );
  }

  Widget _readOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: _inputDecoration(
            hint: label,
            suffixIcon: Icon(icon, size: 18, color: AppColors.textWeak),
          ),
          child: Text(value),
        ),
      ],
    );
  }

  Widget _detailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(value.isEmpty ? '-' : value),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: AppColors.textStrong,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      isDense: true,
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

  BoxDecoration _cardDecoration() {
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

  /// Pill khusus status validasi pelapor.
  Widget _validationPill(bool validated) {
    final color = validated ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        validated ? 'Tervalidasi' : 'Menunggu',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 30, color: AppColors.textWeak),
          SizedBox(height: 8),
          Text(
            'Belum ada daftar laporan.',
            style: TextStyle(color: AppColors.textWeak),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (_displayStatus(status)) {
      'Done' => AppColors.success,
      'On Progress' => AppColors.info,
      _ => AppColors.warning,
    };
  }

  String _displayStatus(String? status) {
    return switch (status?.trim().toLowerCase()) {
      'done' || 'selesai' => 'Done',
      'on progress' ||
      'on progres' ||
      'proses' ||
      'in progress' => 'On Progress',
      _ => 'Open',
    };
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) return isoDate;

    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
