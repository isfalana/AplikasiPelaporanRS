import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/controllers/dashboard_controller.dart';
import '../controllers/laporan_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/sidebar_widgets.dart';
import '../../../routes/app_pages.dart';

class LaporanView extends GetView<LaporanController> {
  const LaporanView({super.key});

  @override
  Widget build(BuildContext context) {
    // Memanggil atau mendaftarkan DashboardController untuk state sidebar
    final dashboardController = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: isMobile
              ? SidebarWidget.mobileAppBar(title: 'Daftar Laporan RS')
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
                            Expanded(child: _buildContent()),
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
          IconButton(
            tooltip: dashboardController.isSidebarCollapsed.value
                ? 'Buka sidebar'
                : 'Ciutkan sidebar',
            onPressed: dashboardController.isSidebarCollapsed.toggle,
            icon: const Icon(Icons.menu_rounded, color: AppColors.textStrong),
          ),
          const SizedBox(width: 12),
          const Text(
            'Daftar Laporan RS',
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
        currentRoute: Routes.LAPORAN,
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

  Widget _buildContent() {
    return _LaporanContent(controller: controller);
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
  String _activeUnit = '';
  String? _selectedKategori;
  String? _selectedPrioritas;
  final List<String> _selectedPics = [];
  Map<String, dynamic>? _editingReport;
  Map<String, dynamic>? _viewingReport;

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
      'id_kategori': _selectedKategori,
      'id_nik_pic': _selectedPics.join(', '),
      'perihal': title,
      'prioritas': _selectedPrioritas,
      'deadline': _formatDate(_deadline),
      'bukti': _buktiController.text.trim(),
      'status': _displayStatus(_editingReport?['status']?.toString()),
      'tgl_selesai': _editingReport?['tgl_selesai'],
    };

    if (_editingReport == null) {
      report.addAll({'id_unit_pelapor': _activeUnit, 'id_tindak_lanjut': null});
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

  @override
  Widget build(BuildContext context) {
    if (_viewingReport case final report?) {
      return _buildDetail(report);
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
        const Text(
          'Daftar Laporan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textStrong,
          ),
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
                .map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildReportCard(report),
                    ),
                  ),
                )
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
                  [
                    _activeNik,
                    if (_activeUnit.isNotEmpty) _activeUnit,
                  ].where((value) => value.isNotEmpty).join(' · '),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Upload bukti'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _buktiController,
                      decoration: _inputDecoration(
                        hint: 'Pilih atau masukkan nama file bukti',
                        suffixIcon: IconButton(
                          tooltip: 'Lampirkan bukti',
                          onPressed: () {
                            setState(() {
                              _buktiController.text = 'bukti_laporan.jpg';
                            });
                          },
                          icon: const Icon(Icons.attach_file_rounded),
                        ),
                      ),
                    ),
                  ],
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_editingReport == null ? 'Kirim' : 'Perbarui'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _resetForm, child: const Text('Batal')),
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
    final priorityColor = switch (report['prioritas']?.toString()) {
      'Tinggi' => AppColors.error,
      'Sedang' => AppColors.warning,
      _ => AppColors.success,
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

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _viewingReport = report),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
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
                IconButton(
                  tooltip: 'Edit laporan',
                  onPressed: () => _loadForEdit(report),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: AppColors.primary,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                _statusPill(status),
                PopupMenuButton<String>(
                  tooltip: 'Aksi laporan',
                  onSelected: (_) => _confirmDelete(report),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
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
                _reportCardInfo(
                  Icons.calendar_today_outlined,
                  'Tanggal laporan',
                  reportDate,
                ),
                _reportCardInfo(
                  Icons.event_outlined,
                  'Deadline',
                  report['deadline']?.toString() ?? '-',
                ),
                _reportCardInfo(Icons.person_outline, 'PIC', pic),
                _reportCardInfo(
                  Icons.history_outlined,
                  'Last update by',
                  lastUpdatedBy,
                ),
                _infoTag(
                  Icons.flag_outlined,
                  'Prioritas',
                  report['prioritas']?.toString() ?? '-',
                  priorityColor,
                ),
              ],
            ),
          ],
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

  Widget _reportCardInfo(IconData icon, String label, String value) {
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

  Widget _buildDetail(Map<String, dynamic> report) {
    final details = <(String, String)>[
      ('Tanggal kejadian', report['tgl_kejadian']?.toString() ?? '-'),
      ('Pelapor', report['id_nik_pelapor']?.toString() ?? '-'),
      ('Unit pelapor', report['id_unit_pelapor']?.toString() ?? '-'),
      ('Kategori', report['id_kategori']?.toString() ?? '-'),
      ('PIC', _picDisplay(report)),
      ('Prioritas', report['prioritas']?.toString() ?? '-'),
      ('Deadline', report['deadline']?.toString() ?? '-'),
      ('Bukti laporan', report['bukti']?.toString() ?? '-'),
      ('Keterangan', report['keterangan']?.toString() ?? '-'),
    ];

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

  Widget _infoTag(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        RichText(
          text: TextSpan(
            style: TextStyle(color: color, fontSize: 12),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ],
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
