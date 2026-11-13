import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/main_layout_widget.dart';
import '../controllers/master_kategori_controller.dart';

class MasterKategoriView extends GetView<MasterKategoriController> {
  const MasterKategoriView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWidget(
      title: 'Master Kategori',
      child: _MasterKategoriContent(controller: controller),
    );
  }
}

class _MasterKategoriContent extends StatefulWidget {
  const _MasterKategoriContent({required this.controller});

  final MasterKategoriController controller;

  @override
  State<_MasterKategoriContent> createState() => _MasterKategoriContentState();
}

class _MasterKategoriContentState extends State<_MasterKategoriContent> {
  final _searchController = TextEditingController();

  MasterKategoriController get controller => widget.controller;

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
          final kategori = controller.filteredKategori;
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Master Kategori',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Kelola jenis kategori untuk mengelompokkan laporan dan '
                  'tindak lanjut.',
                  style: TextStyle(fontSize: 13, color: AppColors.textWeak),
                ),
                const SizedBox(height: 20),
                _buildToolbar(wide, kategori.length),
                if (controller.usingDemoData.value) ...[
                  const SizedBox(height: 12),
                  _buildDemoNotice(),
                ],
                const SizedBox(height: 14),
                if (controller.isLoading.value &&
                    controller.listKategori.isEmpty)
                  _buildLoading()
                else if (kategori.isEmpty)
                  _buildEmpty(hasData: controller.listKategori.isNotEmpty)
                else if (wide)
                  _buildTable(kategori)
                else
                  ...kategori.map(_buildCard),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildToolbar(bool wide, int count) {
    // Di ponsel sempit, label tombol dipersingkat agar toolbar tidak meluber.
    final compact = !wide && MediaQuery.sizeOf(context).width < 380;
    final search = SizedBox(
      width: wide ? 320 : double.infinity,
      height: 46,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => controller.searchQuery.value = value,
        decoration: _inputDecoration('Cari ID atau jenis kategori...')
            .copyWith(prefixIcon: const Icon(Icons.search, size: 18)),
      ),
    );
    final countText = Text(
      '$count kategori',
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
          onPressed: controller.isLoading.value
              ? null
              : controller.fetchKategori,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textWeak),
        ),
        const SizedBox(width: 4),
        ElevatedButton.icon(
          onPressed: controller.isSaving.value ? null : () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: Text(compact ? 'Tambah' : 'Tambah Kategori'),
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
            onPressed: controller.fetchKategori,
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
            Icons.category_outlined,
            size: 34,
            color: AppColors.textWeak,
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? 'Tidak ada kategori yang cocok dengan pencarian.'
                : 'Belum ada data kategori.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textWeak, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> kategori) {
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
            label: Text('ID Kategori'),
            columnWidth: FlexColumnWidth(1.2),
          ),
          DataColumn(
            label: Text('Jenis Kategori'),
            columnWidth: FlexColumnWidth(2.4),
          ),
          DataColumn(label: Text('Dibuat'), columnWidth: FlexColumnWidth(1.3)),
          DataColumn(label: Text('Aksi'), columnWidth: FixedColumnWidth(130)),
        ],
        rows: kategori.map((item) {
          final id = item['id_kategori']?.toString() ?? '';
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
                  _jenisKategori(item),
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
                Text(
                  _dateText(item['created_at']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textWeak,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit kategori',
                      onPressed: controller.isSaving.value
                          ? null
                          : () => _openForm(item),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.textWeak,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus kategori',
                      onPressed: controller.isSaving.value
                          ? null
                          : () => _confirmDelete(item),
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

  Widget _buildCard(Map<String, dynamic> kategori) {
    final id = kategori['id_kategori']?.toString() ?? '';
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
            _jenisKategori(kategori),
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
          Text(
            'Dibuat ${_dateText(kategori['created_at'])}',
            style: const TextStyle(fontSize: 11, color: AppColors.textWeak),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Edit kategori',
                onPressed: controller.isSaving.value
                    ? null
                    : () => _openForm(kategori),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textWeak,
                ),
              ),
              IconButton(
                tooltip: 'Hapus kategori',
                onPressed: controller.isSaving.value
                    ? null
                    : () => _confirmDelete(kategori),
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

  String _jenisKategori(Map<String, dynamic> kategori) {
    final name = kategori['jenis_kategori']?.toString().trim() ?? '';
    return name.isEmpty ? 'Tanpa nama' : name;
  }

  String _dateText(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) return '-';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  Future<void> _openForm([Map<String, dynamic>? kategori]) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _KategoriFormDialog(
        kategori: kategori,
        generatedId: kategori == null ? controller.generateKategoriId() : null,
      ),
    );
    if (result == null) return;

    final error = await controller.saveKategori(
      originalId: kategori?['id_kategori']?.toString(),
      jenisKategori: result['jenis_kategori'] ?? '',
    );
    if (!mounted) return;
    Get.snackbar(
      error == null ? 'Berhasil' : 'Perhatian',
      error ??
          (kategori == null
              ? 'Kategori baru berhasil ditambahkan.'
              : 'Perubahan kategori berhasil disimpan.'),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error == null ? AppColors.primary : AppColors.warning,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> kategori) async {
    final id = kategori['id_kategori']?.toString() ?? '';
    final name = _jenisKategori(kategori);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Hapus kategori?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
        content: Text(
          'Kategori "$name" akan dihapus. Data kategori yang sudah dihapus '
          'tidak dapat dikembalikan.',
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

    final error = await controller.deleteKategori(id);
    if (!mounted) return;
    Get.snackbar(
      error == null ? 'Berhasil' : 'Perhatian',
      error ?? 'Kategori "$name" berhasil dihapus.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error == null ? AppColors.primary : AppColors.warning,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}

class _KategoriFormDialog extends StatefulWidget {
  const _KategoriFormDialog({this.kategori, this.generatedId});

  final Map<String, dynamic>? kategori;
  final String? generatedId;

  @override
  State<_KategoriFormDialog> createState() => _KategoriFormDialogState();
}

class _KategoriFormDialogState extends State<_KategoriFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool get _isEdit => widget.kategori != null;

  String get _kategoriId {
    if (_isEdit) return widget.kategori?['id_kategori']?.toString() ?? '-';
    return widget.generatedId ?? '-';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.kategori?['jenis_kategori']?.toString() ?? '',
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
      'id_kategori': widget.kategori?['id_kategori']?.toString() ?? '',
      'jenis_kategori': _nameController.text.trim(),
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
            _isEdit ? 'Ubah kategori' : 'Tambah kategori',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isEdit
                ? 'Perbarui jenis kategori laporan.'
                : 'Daftarkan jenis kategori baru.',
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
                _fieldLabel('ID Kategori'),
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
                          _kategoriId,
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
                _fieldLabel('Jenis Kategori'),
                TextFormField(
                  key: const ValueKey('kategori_jenis_field'),
                  controller: _nameController,
                  maxLength: 100,
                  decoration: _inputDecoration('Contoh: Kelistrikan')
                      .copyWith(counterText: ''),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Jenis kategori wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kategori dipakai untuk mengelompokkan laporan pada halaman '
                  'Laporan dan Report.',
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
