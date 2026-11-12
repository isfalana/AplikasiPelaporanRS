import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/main_layout_widget.dart';
import '../controllers/master_unit_controller.dart';

class MasterUnitView extends GetView<MasterUnitController> {
  const MasterUnitView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWidget(
      title: 'Master Unit',
      child: _MasterUnitContent(controller: controller),
    );
  }
}

class _MasterUnitContent extends StatefulWidget {
  const _MasterUnitContent({required this.controller});

  final MasterUnitController controller;

  @override
  State<_MasterUnitContent> createState() => _MasterUnitContentState();
}

class _MasterUnitContentState extends State<_MasterUnitContent> {
  final _searchController = TextEditingController();

  MasterUnitController get controller => widget.controller;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Obx(() {
          final units = controller.filteredUnits;
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Master Unit',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Kelola data unit kerja yang terdaftar di aplikasi.',
                  style: TextStyle(fontSize: 13, color: AppColors.textWeak),
                ),
                const SizedBox(height: 20),
                _buildToolbar(wide, units.length),
                if (controller.usingDemoData.value) ...[
                  const SizedBox(height: 12),
                  _buildDemoNotice(),
                ],
                const SizedBox(height: 14),
                if (controller.isLoading.value && controller.listUnit.isEmpty)
                  _buildLoading()
                else if (units.isEmpty)
                  _buildEmpty(hasData: controller.listUnit.isNotEmpty)
                else if (wide)
                  _buildTable(units)
                else
                  ...units.map(_buildCard),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildToolbar(bool wide, int count) {
    final search = SizedBox(
      width: wide ? 320 : double.infinity,
      height: 46,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => controller.searchQuery.value = value,
        decoration: _inputDecoration('Cari ID atau nama unit...')
            .copyWith(prefixIcon: const Icon(Icons.search, size: 18)),
      ),
    );
    final countText = Text(
      '$count unit',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textWeak,
        fontWeight: FontWeight.w600,
      ),
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Muat ulang data',
          onPressed: controller.isLoading.value ? null : controller.fetchUnits,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textWeak),
        ),
        const SizedBox(width: 4),
        ElevatedButton.icon(
          onPressed: controller.isSaving.value ? null : () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah Unit'),
          style: AppButtons.primary,
        ),
      ],
    );

    if (wide) {
      return Row(
        children: [
          search,
          const SizedBox(width: 14),
          Expanded(child: countText),
          actions,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        search,
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: countText),
            actions,
          ],
        ),
      ],
    );
  }

  Widget _buildDemoNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 17,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Server belum terhubung. Data contoh ditampilkan agar halaman '
              'tetap bisa dipakai.',
              style: TextStyle(fontSize: 12, color: AppColors.textStrong),
            ),
          ),
          TextButton(
            onPressed: controller.fetchUnits,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text(
              'Coba lagi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildEmpty({required bool hasData}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.apartment_outlined,
            size: 34,
            color: AppColors.textWeak,
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? 'Tidak ada unit yang cocok dengan pencarian.'
                : 'Belum ada data unit.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textWeak, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> units) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F1F6)),
        horizontalMargin: 20,
        columnSpacing: 20,
        columns: const [
          DataColumn(
            label: Text('ID Unit'),
            columnWidth: FlexColumnWidth(1.2),
          ),
          DataColumn(
            label: Text('Nama Unit'),
            columnWidth: FlexColumnWidth(2.4),
          ),
          DataColumn(
            label: Text('Aksi'),
            columnWidth: FixedColumnWidth(130),
          ),
        ],
        rows: units.map((unit) {
          final id = unit['id_unit']?.toString() ?? '';
          return DataRow(
            cells: [
              DataCell(
                Text(
                  id.isEmpty ? '-' : id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              DataCell(
                Text(
                  _unitName(unit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit unit',
                      onPressed: controller.isSaving.value
                          ? null
                          : () => _openForm(unit),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.textWeak,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus unit',
                      onPressed: controller.isSaving.value
                          ? null
                          : () => _confirmDelete(unit),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> unit) {
    final id = unit['id_unit']?.toString() ?? '';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _unitName(unit),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            id.isEmpty ? '-' : id,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Edit unit',
                onPressed: controller.isSaving.value
                    ? null
                    : () => _openForm(unit),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textWeak,
                ),
              ),
              IconButton(
                tooltip: 'Hapus unit',
                onPressed: controller.isSaving.value
                    ? null
                    : () => _confirmDelete(unit),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _unitName(Map<String, dynamic> unit) {
    final name = unit['nama_unit']?.toString().trim() ?? '';
    return name.isEmpty ? 'Tanpa nama' : name;
  }

  Future<void> _openForm([Map<String, dynamic>? unit]) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UnitFormDialog(
        unit: unit,
        generatedId: unit == null ? controller.generateUnitId() : null,
      ),
    );
    if (result == null) return;

    final error = await controller.saveUnit(
      originalId: unit?['id_unit']?.toString(),
      namaUnit: result['nama_unit'] ?? '',
    );
    if (!mounted) return;
    Get.snackbar(
      error == null ? 'Berhasil' : 'Perhatian',
      error ??
          (unit == null
              ? 'Unit baru berhasil ditambahkan.'
              : 'Perubahan unit berhasil disimpan.'),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error == null ? AppColors.primary : AppColors.warning,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> unit) async {
    final id = unit['id_unit']?.toString() ?? '';
    final name = _unitName(unit);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Hapus unit?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
        content: Text(
          'Unit "$name" akan dihapus. Data unit yang sudah dihapus tidak '
          'dapat dikembalikan.',
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
              foregroundColor: AppColors.error,
              backgroundColor: AppColors.error.withValues(alpha: 0.08),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await controller.deleteUnit(id);
    if (!mounted) return;
    Get.snackbar(
      error == null ? 'Berhasil' : 'Perhatian',
      error ?? 'Unit "$name" berhasil dihapus.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error == null ? AppColors.primary : AppColors.warning,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}

class _UnitFormDialog extends StatefulWidget {
  const _UnitFormDialog({this.unit, this.generatedId});

  final Map<String, dynamic>? unit;
  final String? generatedId;

  @override
  State<_UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<_UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool get _isEdit => widget.unit != null;

  String get _unitId {
    if (_isEdit) return widget.unit?['id_unit']?.toString() ?? '-';
    return widget.generatedId ?? '-';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.unit?['nama_unit']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop({
      'id_unit': widget.unit?['id_unit']?.toString() ?? '',
      'nama_unit': _nameController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? 'Ubah unit' : 'Tambah unit',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isEdit
                ? 'Perbarui data unit kerja.'
                : 'Daftarkan unit kerja baru.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textWeak,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('ID Unit'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _unitId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEdit ? 'tidak dapat diubah' : 'dibuat otomatis',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textWeak,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _fieldLabel('Nama Unit'),
                TextFormField(
                  key: const ValueKey('unit_name_field'),
                  controller: _nameController,
                  maxLength: 100,
                  decoration: _inputDecoration(
                    'Contoh: Unit Umum',
                  ).copyWith(counterText: ''),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                      ? 'Nama unit wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Karyawan dan PIC unit dikelola di Master Karyawan.',
                  style: TextStyle(fontSize: 11, color: AppColors.textWeak),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: AppButtons.outlined,
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: AppButtons.primary,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
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
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
