import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/main_layout_widget.dart';
import '../controllers/master_karyawan_controller.dart';

class MasterKaryawanView extends GetView<MasterKaryawanController> {
  const MasterKaryawanView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWidget(
      title: 'Master Karyawan',
      child: _MasterKaryawanContent(controller: controller),
    );
  }
}

class _MasterKaryawanContent extends StatefulWidget {
  const _MasterKaryawanContent({required this.controller});

  final MasterKaryawanController controller;

  @override
  State<_MasterKaryawanContent> createState() => _MasterKaryawanContentState();
}

class _MasterKaryawanContentState extends State<_MasterKaryawanContent> {
  final _searchController = TextEditingController();

  MasterKaryawanController get controller => widget.controller;

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
          final karyawan = controller.filteredKaryawan;
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Master Karyawan',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Kelola akun karyawan beserta unit kerja dan role-nya.',
                  style: TextStyle(fontSize: 13, color: AppColors.textWeak),
                ),
                const SizedBox(height: 20),
                _buildToolbar(
                  wide,
                  karyawan.length,
                  compact: constraints.maxWidth < 380,
                ),
                if (controller.usingDemoData.value) ...[
                  const SizedBox(height: 12),
                  _buildDemoNotice(),
                ],
                const SizedBox(height: 14),
                if (controller.isLoading.value &&
                    controller.listKaryawan.isEmpty)
                  _buildLoading()
                else if (karyawan.isEmpty)
                  _buildEmpty(hasData: controller.listKaryawan.isNotEmpty)
                else if (wide)
                  _buildTable(karyawan)
                else
                  ...karyawan.map(_buildCard),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildToolbar(bool wide, int count, {bool compact = false}) {
    final search = SizedBox(
      width: wide ? 340 : double.infinity,
      height: 46,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => controller.searchQuery.value = value,
        decoration: _inputDecoration('Cari NIK, nama, unit, atau role...')
            .copyWith(prefixIcon: const Icon(Icons.search, size: 18)),
      ),
    );
    final countText = Text(
      '$count karyawan',
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
          onPressed: controller.isLoading.value ? null : controller.fetchAll,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textWeak),
        ),
        const SizedBox(width: 4),
        ElevatedButton.icon(
          onPressed: controller.isSaving.value ? null : () => _openForm(),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: Text(compact ? 'Tambah' : 'Tambah Karyawan'),
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
            onPressed: controller.fetchAll,
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
            Icons.people_outline_rounded,
            size: 34,
            color: AppColors.textWeak,
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? 'Tidak ada karyawan yang cocok dengan pencarian.'
                : 'Belum ada data karyawan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textWeak, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> karyawan) {
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
            label: Text('Karyawan'),
            columnWidth: FlexColumnWidth(2.6),
          ),
          DataColumn(label: Text('Unit'), columnWidth: FlexColumnWidth(1.8)),
          DataColumn(label: Text('Role'), columnWidth: FlexColumnWidth(1.3)),
          DataColumn(label: Text('Login'), columnWidth: FlexColumnWidth(1.5)),
          DataColumn(label: Text('Aksi'), columnWidth: FixedColumnWidth(136)),
        ],
        rows: karyawan.map((item) {
          return DataRow(
            cells: [
              DataCell(_buildIdentity(item)),
              DataCell(
                _relationChip(
                  label: _unitLabel(item),
                  icon: Icons.apartment_rounded,
                  color: AppColors.info,
                ),
              ),
              DataCell(
                _relationChip(
                  label: _roleLabel(item),
                  icon: Icons.verified_user_outlined,
                  color: AppColors.primary,
                ),
              ),
              DataCell(
                Text(
                  _formatLastLogin(item['last_login']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                      tooltip: 'Edit karyawan',
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
                      tooltip: 'Hapus karyawan',
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

  Widget _buildCard(Map<String, dynamic> item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildIdentity(item, avatarSize: 38)),
              IconButton(
                tooltip: 'Edit karyawan',
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
                tooltip: 'Hapus karyawan',
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _relationChip(
                label: _unitLabel(item),
                icon: Icons.apartment_rounded,
                color: AppColors.info,
              ),
              _relationChip(
                label: _roleLabel(item),
                icon: Icons.verified_user_outlined,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textWeak,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Login terakhir: ${_formatLastLogin(item['last_login'])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textWeak,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(Map<String, dynamic> item, {double avatarSize = 32}) {
    final name = _name(item);
    final nik = item['id_nik']?.toString().trim() ?? '';
    final color = _avatarColor(nik.isEmpty ? name : nik);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(avatarSize / 2.8),
          ),
          child: Text(
            _initials(name),
            style: TextStyle(
              fontSize: avatarSize * 0.36,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                nik.isEmpty ? '-' : nik,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textWeak,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _relationChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isEmpty = label.isEmpty || label == '-';
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isEmpty ? AppColors.surface : color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isEmpty ? AppColors.border : color.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isEmpty ? AppColors.textWeak : color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              isEmpty ? 'Belum ditentukan' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isEmpty ? AppColors.textWeak : AppColors.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _name(Map<String, dynamic> item) {
    final name = item['nama_karyawan']?.toString().trim() ?? '';
    return name.isEmpty ? 'Tanpa nama' : name;
  }

  String _unitLabel(Map<String, dynamic> item) {
    final id = item['id_unit']?.toString().trim() ?? '';
    if (id.isEmpty) return '';
    final name = item['nama_unit']?.toString().trim() ?? '';
    return name.isEmpty ? controller.unitName(id) : name;
  }

  String _roleLabel(Map<String, dynamic> item) {
    final id = item['id_role']?.toString().trim() ?? '';
    if (id.isEmpty) return '';
    final name = item['nama_role']?.toString().trim() ?? '';
    return name.isEmpty ? controller.roleName(id) : name;
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final single = parts.first;
      return single.length >= 2
          ? single.substring(0, 2).toUpperCase()
          : single.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  Color _avatarColor(String seed) {
    const palette = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
    ];
    final total = seed.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return palette[total % palette.length];
  }

  String _formatLastLogin(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'null') return 'Belum pernah';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year} '
        '• $hour:$minute';
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _KaryawanFormDialog(
        karyawan: item,
        suggestedNik: item == null ? controller.generateNik() : null,
        units: controller.listUnit.toList(),
        roles: controller.listRole.toList(),
      ),
    );
    if (result == null) return;

    final error = await controller.saveKaryawan(
      originalNik: item?['id_nik']?.toString(),
      idNik: result['id_nik'] ?? '',
      namaKaryawan: result['nama_karyawan'] ?? '',
      idUnit: result['id_unit'] ?? '',
      idRole: result['id_role'] ?? '',
      password: result['password'] ?? '',
    );
    if (!mounted) return;
    Get.snackbar(
      error == null ? 'Berhasil' : 'Perhatian',
      error ??
          (item == null
              ? 'Karyawan baru berhasil ditambahkan.'
              : 'Perubahan data karyawan berhasil disimpan.'),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error == null ? AppColors.primary : AppColors.warning,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final nik = item['id_nik']?.toString() ?? '';
    final name = _name(item);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Hapus karyawan?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
        content: Text(
          'Karyawan "$name" ($nik) akan dihapus. Riwayat laporan yang pernah '
          'dibuat tetap tersimpan, tetapi karyawan ini tidak muncul lagi di '
          'pilihan PIC.',
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

    final error = await controller.deleteKaryawan(nik);
    if (!mounted) return;
    Get.snackbar(
      error == null ? 'Berhasil' : 'Perhatian',
      error ?? 'Karyawan "$name" berhasil dihapus.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error == null ? AppColors.primary : AppColors.warning,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}

class _KaryawanFormDialog extends StatefulWidget {
  const _KaryawanFormDialog({
    this.karyawan,
    this.suggestedNik,
    required this.units,
    required this.roles,
  });

  final Map<String, dynamic>? karyawan;
  final String? suggestedNik;
  final List<Map<String, dynamic>> units;
  final List<Map<String, dynamic>> roles;

  @override
  State<_KaryawanFormDialog> createState() => _KaryawanFormDialogState();
}

class _KaryawanFormDialogState extends State<_KaryawanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nikController;
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late String _selectedUnit;
  late String _selectedRole;
  bool _obscurePassword = true;

  bool get _isEdit => widget.karyawan != null;

  @override
  void initState() {
    super.initState();
    _nikController = TextEditingController(
      text: widget.karyawan?['id_nik']?.toString() ?? widget.suggestedNik ?? '',
    );
    _nameController = TextEditingController(
      text: widget.karyawan?['nama_karyawan']?.toString() ?? '',
    );
    _passwordController = TextEditingController();
    _selectedUnit = _availableValue(
      widget.units,
      'id_unit',
      widget.karyawan?['id_unit']?.toString(),
    );
    _selectedRole = _availableValue(
      widget.roles,
      'id_role',
      widget.karyawan?['id_role']?.toString(),
    );
  }

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _availableValue(
    List<Map<String, dynamic>> options,
    String key,
    String? value,
  ) {
    final id = value?.trim() ?? '';
    if (id.isEmpty) return '';
    final exists = options.any((option) => option[key]?.toString() == id);
    return exists ? id : '';
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop({
      'id_nik': _nikController.text.trim(),
      'nama_karyawan': _nameController.text.trim(),
      'id_unit': _selectedUnit,
      'id_role': _selectedRole,
      'password': _passwordController.text.trim(),
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
            _isEdit ? 'Ubah karyawan' : 'Tambah karyawan',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isEdit
                ? 'Perbarui data akun, unit, atau role karyawan.'
                : 'Buat akun karyawan baru untuk mengakses aplikasi.',
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
                _fieldLabel('NIK Karyawan'),
                TextFormField(
                  key: const ValueKey('karyawan_nik_field'),
                  controller: _nikController,
                  readOnly: true,
                  maxLength: 50,
                  decoration: _inputDecoration('NIK dibuat otomatis').copyWith(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surface,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          _isEdit ? 'ID login' : 'Otomatis',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textWeak,
                          ),
                        ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'NIK karyawan wajib diisi.';
                    if (text.length > 50) {
                      return 'NIK karyawan maksimal 50 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _fieldLabel('Nama Karyawan'),
                TextFormField(
                  key: const ValueKey('karyawan_name_field'),
                  controller: _nameController,
                  maxLength: 150,
                  decoration: _inputDecoration('Contoh: Rina Kartika')
                      .copyWith(counterText: ''),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Nama karyawan wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 12),
                _buildRelationFields(),
                const SizedBox(height: 12),
                _fieldLabel(_isEdit ? 'Password baru' : 'Password'),
                TextFormField(
                  key: const ValueKey('karyawan_password_field'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration:
                      _inputDecoration(
                        _isEdit
                            ? 'Kosongkan jika tidak diubah'
                            : 'Minimal 6 karakter',
                      ).copyWith(
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.textWeak,
                          ),
                        ),
                      ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (!_isEdit && text.isEmpty) {
                      return 'Password wajib diisi.';
                    }
                    if (text.isNotEmpty && text.length < 6) {
                      return 'Password minimal 6 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unit dan role menentukan penempatan karyawan serta aksesnya. '
                  'Karyawan aktif akan muncul di pilihan PIC saat membuat laporan.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textWeak,
                    height: 1.45,
                  ),
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

  Widget _buildRelationFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final unitField = _buildUnitField();
        final roleField = _buildRoleField();
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [unitField, const SizedBox(height: 12), roleField],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: unitField),
            const SizedBox(width: 12),
            Expanded(child: roleField),
          ],
        );
      },
    );
  }

  Widget _buildUnitField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Unit'),
        DropdownButtonFormField<String>(
          key: const ValueKey('karyawan_unit_dropdown'),
          initialValue: _selectedUnit,
          isExpanded: true,
          decoration: _inputDecoration('Pilih unit'),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('Belum ditentukan', overflow: TextOverflow.ellipsis),
            ),
            for (final unit in widget.units)
              if ((unit['id_unit']?.toString() ?? '').isNotEmpty)
                DropdownMenuItem(
                  value: unit['id_unit']?.toString() ?? '',
                  child: Text(_unitName(unit), overflow: TextOverflow.ellipsis),
                ),
          ],
          onChanged: (value) => setState(() => _selectedUnit = value ?? ''),
        ),
      ],
    );
  }

  Widget _buildRoleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Role'),
        DropdownButtonFormField<String>(
          key: const ValueKey('karyawan_role_dropdown'),
          initialValue: _selectedRole,
          isExpanded: true,
          decoration: _inputDecoration('Pilih role'),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('Belum ditentukan', overflow: TextOverflow.ellipsis),
            ),
            for (final role in widget.roles)
              if ((role['id_role']?.toString() ?? '').isNotEmpty)
                DropdownMenuItem(
                  value: role['id_role']?.toString() ?? '',
                  child: Text(_roleName(role), overflow: TextOverflow.ellipsis),
                ),
          ],
          onChanged: (value) => setState(() => _selectedRole = value ?? ''),
        ),
      ],
    );
  }

  String _unitName(Map<String, dynamic> unit) {
    final name = unit['nama_unit']?.toString().trim() ?? '';
    return name.isEmpty ? unit['id_unit']?.toString() ?? '-' : name;
  }

  String _roleName(Map<String, dynamic> role) {
    final name = role['nama_role']?.toString().trim() ?? '';
    return name.isEmpty ? role['id_role']?.toString() ?? '-' : name;
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
