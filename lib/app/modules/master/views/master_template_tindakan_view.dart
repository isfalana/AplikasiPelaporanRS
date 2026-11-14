import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/main_layout_widget.dart';
import '../controllers/master_template_tindakan_controller.dart';

class MasterTemplateTindakanView
    extends GetView<MasterTemplateTindakanController> {
  const MasterTemplateTindakanView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWidget(
      title: 'Master Template Tindakan',
      child: _MasterTemplateContent(controller: controller),
    );
  }
}

class _MasterTemplateContent extends StatefulWidget {
  const _MasterTemplateContent({required this.controller});

  final MasterTemplateTindakanController controller;

  @override
  State<_MasterTemplateContent> createState() => _MasterTemplateContentState();
}

class _MasterTemplateContentState extends State<_MasterTemplateContent> {
  final _searchController = TextEditingController();

  MasterTemplateTindakanController get controller => widget.controller;

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
          final templates = controller.filteredTemplate;
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Master Template Tindakan',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Kelola template tindak lanjut yang bisa dipilih penindak '
                  'pada halaman Tindakan.',
                  style: TextStyle(fontSize: 13, color: AppColors.textWeak),
                ),
                const SizedBox(height: 20),
                _buildToolbar(wide, templates.length),
                if (controller.usingDemoData.value) ...[
                  const SizedBox(height: 12),
                  _buildDemoNotice(),
                ],
                const SizedBox(height: 14),
                if (controller.isLoading.value &&
                    controller.listTemplate.isEmpty)
                  _buildLoading()
                else if (templates.isEmpty)
                  _buildEmpty(hasData: controller.listTemplate.isNotEmpty)
                else if (wide)
                  _buildTable(templates)
                else
                  ...templates.map(_buildCard),
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
        decoration: _inputDecoration('Cari ID, nama, atau isi tindakan...')
            .copyWith(prefixIcon: const Icon(Icons.search, size: 18)),
      ),
    );
    final countText = Text(
      '$count template',
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
              : controller.fetchTemplate,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textWeak),
        ),
        const SizedBox(width: 4),
        ElevatedButton.icon(
          onPressed: controller.isSaving.value ? null : () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: Text(compact ? 'Tambah' : 'Tambah Template'),
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
            onPressed: controller.fetchTemplate,
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
            Icons.design_services_outlined,
            size: 34,
            color: AppColors.textWeak,
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? 'Tidak ada template yang cocok dengan pencarian.'
                : 'Belum ada data template tindakan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textWeak, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> templates) {
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
            label: Text('ID Template'),
            columnWidth: FlexColumnWidth(1.1),
          ),
          DataColumn(
            label: Text('Nama Template'),
            columnWidth: FlexColumnWidth(1.8),
          ),
          DataColumn(
            label: Text('Tindakan'),
            columnWidth: FlexColumnWidth(2.4),
          ),
          DataColumn(label: Text('Aksi'), columnWidth: FixedColumnWidth(130)),
        ],
        rows: templates.map((item) {
          final id = item['id_template']?.toString() ?? '';
          final actions = _actionsOf(item);
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
                  _namaTemplate(item),
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
                Tooltip(
                  message: actions.join('\n'),
                  child: Text(
                    actions.isEmpty ? '-' : actions.join('; '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textWeak,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit template',
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
                      tooltip: 'Hapus template',
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

  Widget _buildCard(Map<String, dynamic> template) {
    final id = template['id_template']?.toString() ?? '';
    final actions = _actionsOf(template);
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
            _namaTemplate(template),
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
          const SizedBox(height: 8),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: AppColors.textWeak,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Edit template',
                onPressed: controller.isSaving.value
                    ? null
                    : () => _openForm(template),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textWeak,
                ),
              ),
              IconButton(
                tooltip: 'Hapus template',
                onPressed: controller.isSaving.value
                    ? null
                    : () => _confirmDelete(template),
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

  String _namaTemplate(Map<String, dynamic> template) {
    final name = template['nama_template']?.toString().trim() ?? '';
    return name.isEmpty ? 'Tanpa nama' : name;
  }

  List<String> _actionsOf(Map<String, dynamic> template) {
    final value = template['list_tindakan'];
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map(
          (item) =>
              (item['deskripsi_tindakan'] ?? item['deskripsiTindakan'] ?? '')
                  .toString()
                  .trim(),
        )
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _openForm([Map<String, dynamic>? template]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TemplateFormDialog(
        template: template,
        generatedId: template == null ? controller.generateTemplateId() : null,
      ),
    );
    if (result == null) return;

    final actions =
        (result['list_tindakan'] as List?)?.cast<String>() ?? const <String>[];
    final error = await controller.saveTemplate(
      originalId: template?['id_template']?.toString(),
      namaTemplate: result['nama_template']?.toString() ?? '',
      listTindakan: actions,
    );
    if (!mounted) return;
    Get.snackbar(
      error == null ? 'Berhasil' : 'Perhatian',
      error ??
          (template == null
              ? 'Template tindakan baru berhasil ditambahkan.'
              : 'Perubahan template berhasil disimpan.'),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error == null ? AppColors.primary : AppColors.warning,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> template) async {
    final id = template['id_template']?.toString() ?? '';
    final name = _namaTemplate(template);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Hapus template?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
        content: Text(
          'Template "$name" akan dihapus. Data template yang sudah dihapus '
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

    final error = await controller.deleteTemplate(id);
    if (!mounted) return;
    Get.snackbar(
      error == null ? 'Berhasil' : 'Perhatian',
      error ?? 'Template "$name" berhasil dihapus.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error == null ? AppColors.primary : AppColors.warning,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}

class _TemplateFormDialog extends StatefulWidget {
  const _TemplateFormDialog({this.template, this.generatedId});

  final Map<String, dynamic>? template;
  final String? generatedId;

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final List<TextEditingController> _actionControllers;

  bool get _isEdit => widget.template != null;

  String get _templateId {
    if (_isEdit) return widget.template?['id_template']?.toString() ?? '-';
    return widget.generatedId ?? '-';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.template?['nama_template']?.toString() ?? '',
    );
    _actionControllers = _initialActions()
        .map((action) => TextEditingController(text: action))
        .toList();
    if (_actionControllers.isEmpty) {
      _actionControllers.add(TextEditingController());
    }
  }

  List<String> _initialActions() {
    final value = widget.template?['list_tindakan'];
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map(
          (item) =>
              (item['deskripsi_tindakan'] ?? item['deskripsiTindakan'] ?? '')
                  .toString()
                  .trim(),
        )
        .where((item) => item.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _actionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addAction() {
    setState(() => _actionControllers.add(TextEditingController()));
  }

  void _removeAction(int index) {
    if (_actionControllers.length <= 1) return;
    setState(() {
      _actionControllers[index].dispose();
      _actionControllers.removeAt(index);
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final actions = _actionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    if (actions.isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Tambahkan minimal satu tindakan pada template.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    Navigator.of(context).pop({
      'nama_template': _nameController.text.trim(),
      'list_tindakan': actions,
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
            _isEdit ? 'Ubah template' : 'Tambah template',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isEdit
                ? 'Perbarui nama dan daftar tindakan template.'
                : 'Daftarkan template tindak lanjut baru.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textWeak,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('ID Template'),
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
                          _templateId,
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
                _fieldLabel('Nama Template'),
                TextFormField(
                  key: const ValueKey('template_nama_field'),
                  controller: _nameController,
                  maxLength: 255,
                  decoration: _inputDecoration('Contoh: Perbaikan AC')
                      .copyWith(counterText: ''),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Nama template wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 12),
                _fieldLabel('Daftar Tindakan'),
                const SizedBox(height: 6),
                for (var index = 0; index < _actionControllers.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 13),
                          child: Text(
                            '${index + 1}.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWeak,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _actionControllers[index],
                            minLines: 1,
                            maxLines: 2,
                            decoration: _inputDecoration(
                              'Contoh: Cek suhu dan tekanan freon AC',
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Hapus tindakan',
                          onPressed: _actionControllers.length <= 1
                              ? null
                              : () => _removeAction(index),
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textWeak,
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addAction,
                    icon: const Icon(Icons.add, size: 17),
                    label: const Text('Tambah tindakan'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Isi template akan menjadi pilihan cepat penindak pada '
                  'halaman Tindakan.',
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
