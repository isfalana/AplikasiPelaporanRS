import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/laporan_controller.dart';
import '../../auth/controllers/dashboard_controller.dart';
import '../../../data/services/master_data_store.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../global_widgets/bukti_preview.dart';
import '../../../global_widgets/filter_menu_button.dart';
import '../../../global_widgets/image_upload_field.dart';
import '../../../global_widgets/main_layout_widget.dart';
import '../../../global_widgets/report_style_card.dart';
import '../../../routes/app_pages.dart';
import '../../tindakan/controllers/tindakan_controller.dart';

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
  String? _buktiUrl;
  Map<String, dynamic>? _editingReport;
  Map<String, dynamic>? _viewingReport;

  // [MODIFIKASI] Filter dan state tampilan riwayat laporan (default 5 riwayat terbaru)
  String _historyFilter = '5';
  String? _lastViewingReportIdForHistory;

  // Filter aktif pada card "Daftar Laporan". Bisa lebih dari satu.
  final Set<String> _reportFilters = {};

  LaporanController get controller => widget.controller;
  Worker? _viewingWorker;
  Worker? _resetWorker;

  @override
  void initState() {
    super.initState();
    _resetForm(notify: false);
    _loadActiveUser();

    // [MODIFIKASI] Dengarkan pemicu resetViewTrigger untuk mereset tampilan ke kondisi awal
    _resetWorker = ever(widget.controller.resetViewTrigger, (_) {
      if (mounted) {
        setState(() {
          _viewingReport = null;
          _editingReport = null;
          _reportFilters.clear();
          _historyFilter = '5';
          _lastViewingReportIdForHistory = null;
          _resetForm(notify: false);
        });
      }
    });

    // [MODIFIKASI] Dengarkan perubahan target viewingReportId saat notifikasi diklik agar detail laporan langsung terbuka
    _viewingWorker = ever(widget.controller.viewingReportId, (id) {
      if (id != null && id.isNotEmpty) {
        final match = widget.controller.listLaporan.firstWhereOrNull(
          (m) => m['id_laporan']?.toString() == id,
        );
        if (match != null && mounted) {
          setState(() {
            _viewingReport = match;
          });
          widget.controller.viewingReportId.value = null;
        }
      }
    });

    // [MODIFIKASI] Mengambil data laporan, prioritas, dan master data terbaru dari backend saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.fetchLaporanData();
      controller.fetchPrioritas();
      controller.master.fetchFromBackend();

      final targetId = widget.controller.viewingReportId.value;
      if (targetId != null && targetId.isNotEmpty) {
        final match = widget.controller.listLaporan.firstWhereOrNull(
          (m) => m['id_laporan']?.toString() == targetId,
        );
        if (match != null && mounted) {
          setState(() {
            _viewingReport = match;
          });
          widget.controller.viewingReportId.value = null;
        }
      }
    });
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

  /// Cek hak akses akun yang sedang login. Bila sesi belum termuat, izinkan
  /// agar tombol tidak sempat berkedip hilang.
  bool _can(String permission) {
    if (!Get.isRegistered<DashboardController>()) return true;
    return Get.find<DashboardController>().can(permission);
  }

  /// Cek izin buka kembali langsung dari data karyawan aktif.
  ///
  /// Sengaja tidak memakai fallback [_can] yang mengizinkan semua saat sesi
  /// belum termuat, supaya role tanpa izin tidak sempat melihat aksi ini.
  bool _canReopen() {
    final nik = _activeNik.trim();
    if (nik.isEmpty) return false;
    return controller.master.hasPermission(nik, 'laporan.buka_kembali');
  }

  @override
  void dispose() {
    _viewingWorker?.dispose();
    _resetWorker?.dispose();
    _perihalController.dispose();
    _buktiController.dispose();
    super.dispose();
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
      _buktiUrl = null;
    }

    if (notify) {
      setState(reset);
    } else {
      reset();
    }
  }

  void _loadForEdit(Map<String, dynamic> report) {
    // [MODIFIKASI] Validasi: PIC yang ditugaskan pada laporan ini TIDAK BISA mengedit laporan dalam keadaan apapun di semua menu
    if (_isPic(report)) {
      _showMessage('PIC yang ditugaskan tidak dapat mengedit laporan.');
      return;
    }
    // Laporan yang sudah Done bersifat final dan tidak boleh diubah lagi.
    if (_displayStatus(report['status']?.toString()) == 'Done') {
      _showMessage('Laporan yang sudah Done tidak dapat diubah lagi.');
      return;
    }
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
      _buktiUrl = report['bukti_url']?.toString();
    });
  }

  Future<void> _pickDate({required bool isDeadline}) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isDeadline ? _deadline : _tanggalKejadian,
      firstDate: DateTime(2010),
      lastDate: DateTime(2035),
      helpText: isDeadline ? 'Pilih batas waktu' : 'Pilih tanggal kejadian',
      confirmText: 'Pilih',
      cancelText: 'Batal',
      // [MODIFIKASI] Styling elegan menggunakan Theme bawaan DatePicker Flutter tanpa Container ganda.
      // Menghindari kontainer putih kosong yang membesar/tidak proporsional saat beralih ke mode input teks (ikon pensil).
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textStrong,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: AppColors.primary,
              headerForegroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
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

  // [MODIFIKASI] Format tanggal ke ISO YYYY-MM-DD agar valid di PostgreSQL backend
  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // [MODIFIKASI] Auto-resolve ID prioritas berdasarkan sisa hari menuju deadline
  String _priorityForDeadline(DateTime deadline) {
    final reportDate =
        _parseDate(_editingReport?['tgl_laporan']?.toString()) ??
        DateUtils.dateOnly(DateTime.now());
    final remainingDays = DateUtils.dateOnly(deadline)
        .difference(DateUtils.dateOnly(reportDate))
        .inDays;
    if (remainingDays <= 0) return 'P-01'; // Kritis
    if (remainingDays <= 1) return 'P-02'; // Tinggi
    if (remainingDays <= 3) return 'P-03'; // Sedang
    return 'P-04'; // Rendah
  }

  // [MODIFIKASI] POST laporan baru atau update PIC laporan ke backend
  Future<void> _submitReport() async {
    final editing = _editingReport;
    if (editing != null &&
        _displayStatus(editing['status']?.toString()) == 'Done') {
      _showMessage('Laporan yang sudah Done tidak dapat diubah lagi.');
      return;
    }
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

    // [MODIFIKASI] Filter agar pelapor tidak terpilih sebagai PIC (aturan validasi backend)
    final filteredPics = _selectedPics.where((nik) => nik != _activeNik).toList();
    if (filteredPics.isEmpty) {
      _showMessage('Pilih minimal satu orang PIC lain (bukan pelapor).');
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

    // [MODIFIKASI] Validasi bukti laporan pelapor wajib diunggah untuk laporan baru
    if (editing == null && (_buktiBytes == null || _buktiBytes!.isEmpty)) {
      _showMessage('Bukti laporan (gambar/dokumen) wajib diunggah.');
      return;
    }

    // [MODIFIKASI] Validasi batasan ukuran file bukti (maksimal 5 MB)
    if (_buktiBytes != null &&
        _buktiBytes!.lengthInBytes > ImageUploadField.maxFileSizeBytes) {
      _showMessage(
        'Ukuran file bukti (${buktiFileSize(_buktiBytes)}) melebihi batas maksimal ${ImageUploadField.maxFileSizeText}. Silakan sesuaikan atau kompres file Anda.',
      );
      return;
    }

    // [MODIFIKASI] Jika sedang mode edit laporan, panggil update detail laporan ke backend (khusus pelapor/admin)
    if (editing != null) {
      if (_isPic(editing)) {
        _showMessage('PIC yang ditugaskan tidak dapat mengedit laporan.');
        return;
      }
      final id = editing['id_laporan']?.toString();
      if (id != null) {
        final success = await controller.updateReport(
          idLaporan: id,
          perihal: title,
          tglKejadian: _formatIsoDate(_tanggalKejadian),
          idKategori: _selectedKategori!,
          deadline: _formatIsoDate(_deadline),
          idPrioritas: _selectedPrioritas!,
          idNikPics: filteredPics,
          keterangan: editing['keterangan']?.toString(),
          buktiBytes: _buktiBytes,
          buktiFilename: _buktiController.text.trim().isNotEmpty
              ? _buktiController.text.trim()
              : null,
        );
        if (success) {
          _resetForm();
          _showMessage('Laporan berhasil diperbarui.', isSuccess: true);
        }
        return;
      }
    }

    // [MODIFIKASI] Kirim request POST ke backend dengan tanggal ISO YYYY-MM-DD
    final success = await controller.createReport(
      tglKejadian: _formatIsoDate(_tanggalKejadian),
      idKategori: _selectedKategori!,
      deadline: _formatIsoDate(_deadline),
      perihal: title,
      keterangan: _perihalController.text.trim(),
      idPrioritas: _selectedPrioritas,
      idNikPics: filteredPics,
      buktiBytes: _buktiBytes,
      buktiFilename: _buktiController.text.trim().isNotEmpty
          ? _buktiController.text.trim()
          : null,
    );

    if (success) {
      _resetForm();
      _showMessage('Laporan berhasil dikirim.', isSuccess: true);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    Get.snackbar(
      isSuccess ? 'Sukses' : 'Informasi',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isSuccess ? AppColors.success : AppColors.primary,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  // [MODIFIKASI] Memeriksa apakah pengguna aktif memiliki hak akses Admin
  bool _isAdmin() {
    final store = MasterDataStore.ensure();
    final role = store.employeeRole(_activeNik).toUpperCase();
    if (role == 'R-01' || role.contains('ADMIN')) return true;
    if (Get.isRegistered<DashboardController>()) {
      final activeRole = Get.find<DashboardController>().activeRoleId.value.toUpperCase();
      if (activeRole == 'R-01' || activeRole.contains('ADMIN')) return true;
      if (Get.find<DashboardController>().can('laporan.hapus')) return true;
    }
    return false;
  }

  // [MODIFIKASI] Hak akses hapus: Admin dapat menghapus semua laporan, User pelapor hanya laporan miliknya.
  // User yang bukan pelapor TIDAK BISA menghapus laporan.
  bool _canDeleteReport(Map<String, dynamic> report) {
    if (_isAdmin()) return true;
    return _isPelapor(report);
  }

  Future<void> _confirmDelete(Map<String, dynamic> report) async {
    if (!_canDeleteReport(report)) {
      _showMessage('Hanya Admin atau Pelapor yang dapat menghapus laporan ini.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus laporan?'),
        content: Text('Laporan ${(report['nomor_laporan'] ?? report['id_laporan'] ?? '')} akan dihapus.'),
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
      final idLaporan = report['id_laporan']?.toString() ?? '';
      if (idLaporan.isNotEmpty) {
        final success = await controller.deleteReport(idLaporan);
        if (success) {
          Get.snackbar(
            'Berhasil',
            'Laporan berhasil dihapus.',
            backgroundColor: AppColors.success,
            colorText: Colors.white,
          );
          if (mounted) setState(() => _viewingReport = null);
        }
      }
    }
  }

  bool _isPelapor(Map<String, dynamic> report) {
    final nikPelapor = (report['id_nik_pelapor'] ?? report['pelapor']?['id_nik'])
        ?.toString()
        .trim()
        .toUpperCase() ?? '';
    final currentNik = _activeNik.trim().toUpperCase();
    return currentNik.isNotEmpty && currentNik == nikPelapor;
  }

  // [MODIFIKASI] Memeriksa apakah pengguna aktif ditugaskan sebagai PIC pada laporan ini
  bool _isPic(Map<String, dynamic> report) {
    final currentNik = _activeNik.trim().toUpperCase();
    if (currentNik.isEmpty) return false;

    // Cek dari string koma id_nik_pic
    final picStr = report['id_nik_pic']?.toString().toUpperCase() ?? '';
    final picList = picStr
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (picList.contains(currentNik)) return true;

    // Cek dari list penugasan_pic
    if (report['penugasan_pic'] is List) {
      for (final p in report['penugasan_pic'] as List) {
        if (p is Map) {
          final nik = (p['id_nik_pic'] ?? p['pic']?['id_nik'])
              ?.toString()
              .trim()
              .toUpperCase();
          if (nik == currentNik) return true;
        }
      }
    }

    // Cek dari list pics
    if (report['pics'] is List) {
      for (final p in report['pics'] as List) {
        if (p is Map) {
          final nik = (p['id_nik'] ?? p['id_nik_pic'])
              ?.toString()
              .trim()
              .toUpperCase();
          if (nik == currentNik) return true;
        }
      }
    }

    return false;
  }

  /// Ringkasan status validasi/approval pelapor pada kartu dan detail laporan.
  String _validationLabel(Map<String, dynamic> report) {
    final status = _displayStatus(report['status']?.toString());
    if (status == 'Done') {
      final by = report['approved_by']?.toString().trim() ?? '';
      final approver = report['approver']?['nama_karyawan']?.toString().trim() ??
          (by.isNotEmpty ? controller.userName(by) : '');
      if (approver.isNotEmpty) return 'Disetujui oleh $approver';
      return 'Tervalidasi / Disetujui';
    } else if (status == 'Menunggu Approval') {
      return 'Menunggu Approval Pelapor';
    } else if (status == 'Dikembalikan') {
      return 'Dikembalikan untuk Perbaikan';
    }
    return 'Belum Approval';
  }

  /// Pelapor menyetujui laporan yang berstatus PENDING_APPROVAL menjadi COMPLETED.
  Future<void> _confirmApprove(Map<String, dynamic> report) async {
    if (!_isPelapor(report)) {
      _showMessage('Hanya pelapor yang dapat menyetujui laporan.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Setujui Laporan Selesai?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
        content: Text(
          'Pastikan laporan ${report['nomor_laporan'] ?? report['id_laporan'] ?? ''} beserta seluruh '
          'tindak lanjutnya benar-benar sudah selesai. Setelah disetujui, '
          'status laporan akan menjadi Selesai (Done).',
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
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Setujui (Approve)'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final id = report['id_laporan']?.toString();
    if (id == null) return;

    final success = await controller.updateApprovalStatus(
      idLaporan: id,
      status: 'COMPLETED',
    );

    if (success) {
      if (mounted) {
        setState(() => _viewingReport = null);
        _showMessage('Laporan berhasil disetujui dan dinyatakan selesai.', isSuccess: true);
      }
    }
  }

  /// Pelapor menolak approval laporan yang berstatus PENDING_APPROVAL dan mengembalikannya ke PIC.
  /// Wajib menyertakan catatan / komentar penolakan.
  Future<void> _confirmReject(Map<String, dynamic> report) async {
    if (!_isPelapor(report)) {
      _showMessage('Hanya pelapor yang dapat menolak approval laporan.');
      return;
    }

    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Tolak & Kembalikan Laporan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.redAccent,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan ${report['nomor_laporan'] ?? report['id_laporan'] ?? ''} akan dikembalikan ke PIC untuk perbaikan.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textWeak,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Catatan penolakan / perbaikan (wajib diisi):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: noteController,
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Catatan penolakan wajib diisi';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Tuliskan alasan penolakan dan bagian yang perlu diperbaiki...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textWeak),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textWeak),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Tolak & Kembalikan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final id = report['id_laporan']?.toString();
    if (id == null) return;

    final success = await controller.updateApprovalStatus(
      idLaporan: id,
      status: 'RETURNED',
      approvalNote: noteController.text.trim(),
    );

    if (success) {
      if (mounted) {
        setState(() => _viewingReport = null);
        _showMessage('Laporan berhasil dikembalikan kepada PIC dengan catatan.', isSuccess: true);
      }
    }
  }

  /// Membuka kembali laporan yang sudah Done agar bisa diperbaiki lagi.
  /// Approval dan buka kembali hanya dapat dilakukan oleh Pelapor.
  /// Wajib menyertakan catatan / komentar alasan buka kembali.
  Future<void> _confirmReopen(Map<String, dynamic> report) async {
    if (!_isPelapor(report)) {
      _showMessage('Hanya pelapor yang dapat membuka kembali laporan ini.');
      return;
    }

    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Buka Kembali Laporan?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan ${report['nomor_laporan'] ?? report['id_laporan'] ?? ''} akan dibuka kembali dan dikembalikan ke PIC untuk tindak lanjut ulang.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textWeak,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Catatan / Alasan membuka kembali (wajib diisi):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: noteController,
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Catatan atau alasan buka kembali wajib diisi';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Tuliskan alasan mengapa laporan dibuka kembali...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textWeak),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textWeak),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Buka Kembali'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final id = report['id_laporan']?.toString();
    if (id == null) return;

    final success = await controller.updateApprovalStatus(
      idLaporan: id,
      status: 'RETURNED',
      approvalNote: noteController.text.trim(),
    );

    if (success) {
      if (mounted) {
        setState(() => _viewingReport = null);
        _showMessage('Laporan berhasil dibuka kembali untuk perbaikan.', isSuccess: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // [MODIFIKASI] Tangani pembukaan detail laporan langsung saat notifikasi diklik
    final targetId = widget.controller.viewingReportId.value;
    if (targetId != null && targetId.isNotEmpty) {
      for (final item in widget.controller.listLaporan) {
        if (item['id_laporan']?.toString() == targetId) {
          _viewingReport = item;
          widget.controller.viewingReportId.value = null;
          break;
        }
      }
    }

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
        // Di layar sempit field upload dibuat selebar form supaya tombol dan
        // keterangan file tidak meluber ke kanan.
        final uploadWidth = constraints.maxWidth < 600
            ? formContentWidth
            : fieldWidth;
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
                        uploadWidth: uploadWidth,
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
                  uploadWidth: uploadWidth,
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
    required double uploadWidth,
  }) {
    final kategoriOptions = controller.kategoriOptions;
    // [MODIFIKASI] Ambil nama kategori yang valid dari backend (nama_kategori / jenis_kategori)
    final categoryLabels = <String, String>{
      for (final kategori in kategoriOptions)
        kategori['id_kategori']?.toString() ?? '':
            (kategori['nama_kategori']?.toString().trim().isNotEmpty == true)
                ? kategori['nama_kategori']!.toString()
                : (kategori['jenis_kategori']?.toString() ?? ''),
    };

    // [MODIFIKASI] PIC options HANYA mengambil karyawan yang aktif (tidak di-soft-delete).
    // Tidak lagi menyertakan data historis dari laporan lama agar karyawan yang telah dihapus tidak muncul.
    // Juga mengecualikan pelapor aktif dan PIC yang sudah dipilih ke dalam daftar chip.
    final picOptions = controller.employeeNiks
        .where((nik) =>
            nik.isNotEmpty &&
            nik != _activeNik &&
            !_selectedPics.contains(nik))
        .toSet()
        .toList()
      ..sort(
        (first, second) =>
            controller.userName(first).compareTo(controller.userName(second)),
      );

    // [MODIFIKASI] Prioritas diambil dari data master backend (P-01 s/d P-04)
    final priorityLabels = <String, String>{
      for (final p in controller.listPrioritas)
        p['id_prioritas']?.toString() ?? '':
            p['nama_prioritas']?.toString() ?? p['id_prioritas']?.toString() ?? '',
    };
    final priorities = priorityLabels.isNotEmpty
        ? priorityLabels.keys.toList()
        : <String>['P-01', 'P-02', 'P-03', 'P-04'];

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
                  _editingReport != null
                      ? _formatDisplayDate(_editingReport!['tgl_laporan'])
                      : _formatDate(DateTime.now()),
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
                  values: categoryLabels.keys.toList(),
                  labels: categoryLabels,
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
                  labels: priorityLabels.isNotEmpty ? priorityLabels : null,
                  onChanged: (value) =>
                      setState(() => _selectedPrioritas = value),
                ),
              ),
              SizedBox(
                width: uploadWidth,
                // [MODIFIKASI] Label bukti laporan diubah menjadi wajib diisi dan mendukung pratinjau bukti dokumen tersimpan
                child: ImageUploadField(
                  label: 'Upload bukti laporan (Wajib)',
                  fileName: _buktiController.text,
                  bytes: _buktiBytes,
                  imageUrl: _buktiUrl,
                  onChanged: (name, bytes) => setState(() {
                    _buktiController.text = name;
                    _buktiBytes = bytes;
                    if (bytes != null) _buktiUrl = null;
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
          if (!_can(_editingReport == null ? 'laporan.buat' : 'laporan.ubah'))
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Akun Anda tidak memiliki akses untuk menyimpan laporan.',
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed:
                    _can(
                      _editingReport == null ? 'laporan.buat' : 'laporan.ubah',
                    )
                    ? _submitReport
                    : null,
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
    // [MODIFIKASI] Format tampilan tanggal laporan menjadi DD-MM-YYYY
    final rawReportDate =
        report['tgl_laporan'] ??
        report['tanggal_laporan'] ??
        report['created_at'];
    final reportDate = _formatDisplayDate(rawReportDate);
    final pic = _picDisplay(report);
    // [MODIFIKASI] Format lastUpdatedBy agar menampilkan nama karyawan dan unit kerja, bukan NIK mentah
    final lastUpdatedBy = _lastUpdateByDisplay(report);
    final kategori = controller.kategoriName(
      report['id_kategori']?.toString() ?? '',
    );
    // [MODIFIKASI] Format deadline menjadi DD-MM-YYYY
    final deadline = _formatDisplayDate(report['deadline']);

    return ReportStyleCard(
      // [MODIFIKASI] Tampilkan nomor_laporan ringkas (lap01-tanggalbuat), fallback ke id_laporan
      reportId: (report['nomor_laporan'] ?? report['id_laporan'])?.toString() ?? '-',
      title: report['perihal']?.toString() ?? '-',
      status: status,
      onTap: () => setState(() => _viewingReport = report),
      metaChips: [
        if (kategori.isNotEmpty && kategori != '-')
          ReportMetaChip(icon: Icons.folder_outlined, label: kategori),
        if (priority != null && priority.isNotEmpty && priority != '-')
          ReportMetaChip(
            icon: Icons.flag_outlined,
            label: priority,
            color: priorityColor,
          ),
        if (status == 'Done')
          const ReportMetaChip(
            icon: Icons.verified_outlined,
            label: 'Laporan Selesai & Disetujui',
            color: AppColors.success,
          ),
        if (status == 'Menunggu Approval')
          const ReportMetaChip(
            icon: Icons.rate_review_outlined,
            label: 'Menunggu Approval Pelapor',
            color: Colors.purple,
          ),
        if (status == 'Dikembalikan')
          ReportMetaChip(
            icon: Icons.assignment_return_outlined,
            label: report['approval_note'] != null &&
                    report['approval_note'].toString().trim().isNotEmpty
                ? 'Dikembalikan: ${report['approval_note']}'
                : 'Dikembalikan untuk Perbaikan',
            color: Colors.redAccent,
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
          value: deadline.isEmpty ? '-' : deadline,
        ),
        ReportInfoItem(
          icon: Icons.history_outlined,
          label: 'Last update by',
          value: lastUpdatedBy,
        ),
        if (status == 'Done' || status == 'Menunggu Approval' || status == 'Dikembalikan')
          ReportInfoItem(
            icon: Icons.how_to_reg_outlined,
            label: 'Status Approval',
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
        if (status == 'Menunggu Approval' && _isPelapor(report)) ...[
          _cardActionButton(
            tooltip: 'Setujui Laporan (Selesai)',
            onPressed: () => _confirmApprove(report),
            icon: const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppColors.success,
            ),
          ),
          _cardActionButton(
            tooltip: 'Tolak & Kembalikan',
            onPressed: () => _confirmReject(report),
            icon: const Icon(
              Icons.cancel_outlined,
              size: 18,
              color: Colors.redAccent,
            ),
          ),
        ],
        if (status == 'Done' && _isPelapor(report))
          _cardActionButton(
            tooltip: 'Buka kembali laporan',
            onPressed: () => _confirmReopen(report),
            icon: const Icon(
              Icons.lock_open_outlined,
              size: 17,
              color: AppColors.warning,
            ),
          ),
        // [MODIFIKASI] Tombol edit disembunyikan jika pengguna aktif adalah PIC pada laporan ini
        if (_can('laporan.ubah') && !_isPic(report) && status != 'Done')
          _cardActionButton(
            tooltip: 'Edit laporan',
            onPressed: () => _loadForEdit(report),
            icon: const Icon(
              Icons.edit_outlined,
              size: 17,
              color: AppColors.primary,
            ),
          ),
        // [MODIFIKASI] Hak akses hapus: Admin dapat menghapus semua, Pelapor dapat menghapus miliknya sendiri
        if (_canDeleteReport(report))
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
    final displayName = controller.userName(nik);
    final unitId = (unit == null || unit.trim().isEmpty)
        ? controller.employeeUnit(nik)
        : unit;
    final displayUnit = unitId.trim().isEmpty
        ? ''
        : controller.unitName(unitId);
    final values = [
      displayName,
      displayUnit,
    ].where((value) => value.trim().isNotEmpty && value != '-').toList();
    return values.isEmpty ? nik : values.join(' - ');
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

  // [MODIFIKASI] Format NIK / ID actor menjadi nama karyawan dan unit kerja
  String _formatActorOrNik(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') return '-';
    final name = controller.userName(trimmed);
    final unit = controller.employeeUnitName(trimmed);
    final parts = [name, unit].where((v) => v.isNotEmpty && v != '-').toList();
    return parts.isEmpty ? trimmed : parts.join(' · ');
  }

  // [MODIFIKASI] Menampilkan informasi Last Update By lengkap (Nama · Unit), fallback ke Pelapor
  String _lastUpdateByDisplay(Map<String, dynamic> report) {
    final raw = (report['last_update_by'] ?? report['lastUpdateBy'])?.toString().trim();
    if (raw != null && raw.isNotEmpty && raw != '-') {
      if (!raw.contains('·') && !raw.contains(' - ') && !raw.contains(' ')) {
        return _formatActorOrNik(raw);
      }
      return raw;
    }
    return _pelaporDisplay(report);
  }

  void _navigateToTindakan(Map<String, dynamic> report) {
    if (Get.isRegistered<TindakanController>()) {
      final tindakanCtrl = Get.find<TindakanController>();
      tindakanCtrl.selectReport(report);
    }
    Get.toNamed(Routes.TINDAKAN, arguments: report);
  }

  Widget _buildDetail(Map<String, dynamic> report) {
    final details = <(String, String)>[
      // [MODIFIKASI] Format tanggal kejadian dan deadline menjadi DD-MM-YYYY pada detail laporan
      (
        'Tanggal kejadian',
        _formatDisplayDate(report['tgl_kejadian'] ?? report['tanggal_kejadian']),
      ),
      ('Pelapor', _pelaporDisplay(report)),
      (
        'Kategori',
        controller.kategoriName(report['id_kategori']?.toString() ?? ''),
      ),
      ('PIC', _picDisplay(report)),
      ('Prioritas', report['prioritas']?.toString() ?? '-'),
      ('Deadline', _formatDisplayDate(report['deadline'])),
      ('Bukti laporan', report['bukti']?.toString() ?? '-'),
      (
        'Last update by',
        _lastUpdateByDisplay(report),
      ),
    ];
    final actionDetails = _actionDetails(report['detail_tindakan']);
    // [MODIFIKASI] Membaca actionProgress langsung dari detail_tindakan agar sinkron dengan status database
    final actionProgress = _actionProgress(report['detail_tindakan'] ?? report['progres_tindakan']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _viewingReport = null),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                label: const Text('Kembali ke Daftar'),
              ),
              const Spacer(),
              // [MODIFIKASI] Tombol "Berikan Tindakan" di samping tombol kembali jika pengguna aktif adalah PIC laporan ini
              if (_isPic(report) && _displayStatus(report['status']?.toString()) != 'Done')
                FilledButton.icon(
                  onPressed: () => _navigateToTindakan(report),
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: const Text('Berikan Tindakan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
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
                    // [MODIFIKASI] Tombol edit disembunyikan di detail laporan jika pengguna aktif adalah PIC
                    if (_can('laporan.ubah') &&
                        !_isPic(report) &&
                        _displayStatus(report['status']?.toString()) != 'Done')
                      IconButton(
                        tooltip: 'Edit laporan',
                        onPressed: () => _loadForEdit(report),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    if (_displayStatus(report['status']?.toString()) ==
                            'Done' &&
                        _canReopen())
                      IconButton(
                        tooltip: 'Buka kembali laporan',
                        onPressed: () => _confirmReopen(report),
                        icon: const Icon(
                          Icons.lock_open_outlined,
                          color: AppColors.warning,
                        ),
                      ),
                    // [MODIFIKASI] Tombol hapus di detail jika pengguna adalah Admin atau Pelapor laporan ini
                    if (_canDeleteReport(report))
                      IconButton(
                        tooltip: 'Hapus laporan',
                        onPressed: () => _confirmDelete(report),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                      ),
                    _statusPill(_displayStatus(report['status']?.toString())),
                  ],
                ),
                const SizedBox(height: 4),
                // [MODIFIKASI] Tampilkan nomor_laporan ringkas pada detail laporan (misal: lap01-tanggalbuat)
                Text(
                  (report['nomor_laporan'] ?? report['id_laporan'])?.toString() ?? '-',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
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
                // [MODIFIKASI] Tampilkan pratinjau bukti laporan pelapor (mendukung bytes lokal atau URL storage backend)
                if ((report['bukti'] != null && report['bukti'].toString().trim().isNotEmpty && report['bukti'] != '-') ||
                    report['bukti_bytes'] != null ||
                    (report['bukti_url'] != null && report['bukti_url'].toString().trim().isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  BuktiPreviewTile(
                    fileName: report['bukti']?.toString() ?? '',
                    bytes: report['bukti_bytes'] is Uint8List ? report['bukti_bytes'] as Uint8List : null,
                    imageUrl: report['bukti_url']?.toString(),
                    idEvidence: report['id_evidence']?.toString(),
                    idLaporan: report['id_laporan']?.toString(),
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
                      // [MODIFIKASI] Memeriksa status ceklis langsung dari field selesai/is_completed database
                      final isDone = action['selesai'] == true ||
                          action['is_completed'] == true ||
                          (detailId != null && (actionProgress[detailId] ?? false));
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
                // [MODIFIKASI] Tampilkan pratinjau bukti tindak lanjut (mendukung bytes lokal atau URL storage backend)
                if ((report['bukti_tindakan'] != null && report['bukti_tindakan'].toString().trim().isNotEmpty && report['bukti_tindakan'] != '-') ||
                    report['bukti_tindakan_bytes'] != null ||
                    (report['bukti_tindakan_url'] != null && report['bukti_tindakan_url'].toString().trim().isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  BuktiPreviewTile(
                    fileName: report['bukti_tindakan']?.toString() ?? '',
                    bytes: report['bukti_tindakan_bytes'] is Uint8List ? report['bukti_tindakan_bytes'] as Uint8List : null,
                    imageUrl: report['bukti_tindakan_url']?.toString(),
                    idEvidence: report['id_evidence_tindakan']?.toString(),
                    idLaporan: report['id_laporan']?.toString(),
                  ),
                ],
                _validationSection(report),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // [MODIFIKASI] Section Riwayat Laporan dipisahkan dalam container/card tersendiri di bagian bawah
          _buildHistorySection(report),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _viewingReport = null),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text('Kembali ke daftar'),
              ),
              if (_isPic(report) && _displayStatus(report['status']?.toString()) != 'Done')
                FilledButton.icon(
                  onPressed: () => _navigateToTindakan(report),
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: const Text('Berikan Tindakan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Blok status approval / catatan pada detail laporan.
  Widget _validationSection(Map<String, dynamic> report) {
    final status = _displayStatus(report['status']?.toString());
    final isPelapor = _isPelapor(report);
    final hasNote = report['approval_note'] != null &&
        report['approval_note'].toString().trim().isNotEmpty;

    final noteWidget = hasNote
        ? Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status == 'Dikembalikan'
                            ? 'Catatan Pelapor (Laporan Dikembalikan / Perlu Perbaikan):'
                            : 'Catatan Pelapor:',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report['approval_note'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textStrong,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    if (status == 'Menunggu Approval') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review_outlined, size: 20, color: Colors.purple),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Menunggu Approval Pelapor',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending Approval',
                    style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isPelapor
                  ? 'Seluruh checklist tindakan telah diselesaikan oleh PIC. Sebagai pelapor, Anda dapat menyetujui laporan atau menolak jika masih perlu perbaikan.'
                  : 'Seluruh checklist tindakan telah diselesaikan oleh PIC. Menunggu review dan persetujuan dari pelapor (${_pelaporDisplay(report)}).',
              style: const TextStyle(fontSize: 12, color: AppColors.textWeak, height: 1.4),
            ),
            noteWidget,
            if (isPelapor) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmApprove(report),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Setujui (Approve)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmReject(report),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Tolak & Kembalikan'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    if (status == 'Done') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_outlined, size: 20, color: AppColors.success),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Laporan Telah Disetujui (Done)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Laporan dan seluruh tindakan telah dinyatakan selesai dan disetujui oleh pelapor (${_pelaporDisplay(report)}).',
              style: const TextStyle(fontSize: 12, color: AppColors.textWeak, height: 1.4),
            ),
            noteWidget,
            if (isPelapor) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmReopen(report),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
                icon: const Icon(Icons.lock_open_outlined, size: 17),
                label: const Text('Buka Kembali Laporan'),
              ),
            ],
          ],
        ),
      );
    }

    if (status == 'Dikembalikan') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_return_outlined, size: 20, color: Colors.redAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Laporan Dikembalikan untuk Perbaikan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Perlu Perbaikan',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Pelapor telah menolak approval atau membuka kembali laporan ini agar PIC melakukan perbaikan tindakan.',
              style: TextStyle(fontSize: 12, color: AppColors.textWeak, height: 1.4),
            ),
            noteWidget,
          ],
        ),
      );
    }

    return noteWidget;
  }

  DateTime _parseWibDateTime(dynamic raw) {
    if (raw == null) return DateTime.now();
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return DateTime.now();
    return dt.toUtc().add(const Duration(hours: 7));
  }

  String _formatDateHeader(DateTime wib) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final day = wib.day.toString().padLeft(2, '0');
    final monthName = months[wib.month - 1];
    final year = wib.year;

    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(wib.year, wib.month, wib.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) {
      return 'Hari Ini - $day $monthName $year';
    } else if (diffDays == 1) {
      return 'Kemarin - $day $monthName $year';
    } else {
      return '$day $monthName $year';
    }
  }

  String _formatShortDate(DateTime wib) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final day = wib.day.toString().padLeft(2, '0');
    final monthName = months[wib.month - 1];
    return '$day $monthName ${wib.year}';
  }

  // [MODIFIKASI] Bagian Riwayat Laporan (History):
  // 1. Separate berdasarkan tanggal (WIB) dengan badge tanggal & garis pemisah
  // 2. Dropdown & tombol expand: default menampilkan 5 riwayat terbaru, dengan opsi "Lihat semua riwayat"
  Widget _buildHistorySection(Map<String, dynamic> report) {
    final reportId = report['id_laporan']?.toString() ?? '';
    if (_lastViewingReportIdForHistory != reportId) {
      _lastViewingReportIdForHistory = reportId;
      _historyFilter = '5';
    }

    final rawHistory = report['history'];
    final historyList = (rawHistory is List)
        ? List<Map<String, dynamic>>.from(rawHistory.whereType<Map>())
        : <Map<String, dynamic>>[];

    // Urutkan riwayat laporan berdasarkan waktu update terbaru (DESC)
    historyList.sort((a, b) {
      final dtA = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dtB.compareTo(dtA);
    });

    // Kumpulkan tanggal-tanggal unik untuk filter dropdown
    final Map<String, List<Map<String, dynamic>>> allDatesMap = {};
    for (final h in historyList) {
      final wib = _parseWibDateTime(h['created_at']);
      final dateKey = '${wib.year}-${wib.month.toString().padLeft(2, '0')}-${wib.day.toString().padLeft(2, '0')}';
      allDatesMap.putIfAbsent(dateKey, () => []).add(h);
    }

    // Tentukan daftar riwayat yang akan ditampilkan sesuai filter aktif
    final List<Map<String, dynamic>> displayedList;
    if (_historyFilter == 'all') {
      displayedList = historyList;
    } else if (_historyFilter.startsWith('date_')) {
      final targetDate = _historyFilter.substring(5);
      displayedList = historyList.where((h) {
        final wib = _parseWibDateTime(h['created_at']);
        final k = '${wib.year}-${wib.month.toString().padLeft(2, '0')}-${wib.day.toString().padLeft(2, '0')}';
        return k == targetDate;
      }).toList();
    } else {
      // Default: '5' (5 riwayat terbaru)
      displayedList = historyList.take(5).toList();
    }

    // Kelompokkan displayedList berdasarkan tanggal (WIB)
    final Map<String, List<Map<String, dynamic>>> groupedDisplayed = {};
    for (final h in displayedList) {
      final wib = _parseWibDateTime(h['created_at']);
      final dateKey = '${wib.year}-${wib.month.toString().padLeft(2, '0')}-${wib.day.toString().padLeft(2, '0')}';
      groupedDisplayed.putIfAbsent(dateKey, () => []).add(h);
    }

    // Bangun daftar opsi untuk dropdown
    final List<DropdownMenuItem<String>> dropdownItems = [
      const DropdownMenuItem(
        value: '5',
        child: Text('5 Riwayat Terbaru'),
      ),
      DropdownMenuItem(
        value: 'all',
        child: Text('Semua Riwayat (${historyList.length})'),
      ),
    ];
    if (allDatesMap.length > 1) {
      for (final entry in allDatesMap.entries) {
        final sampleDt = _parseWibDateTime(entry.value.first['created_at']);
        dropdownItems.add(
          DropdownMenuItem(
            value: 'date_${entry.key}',
            child: Text('Tanggal: ${_formatShortDate(sampleDt)} (${entry.value.length})'),
          ),
        );
      }
    }

    final currentDropdownValue = dropdownItems.any((item) => item.value == _historyFilter)
        ? _historyFilter
        : '5';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Text(
                'Riwayat Laporan',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Text(
                  '${historyList.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (historyList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentDropdownValue,
                      isDense: true,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
                      items: dropdownItems,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _historyFilter = val);
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          if (historyList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada aktivitas riwayat yang dicatat.',
                style: TextStyle(color: AppColors.textWeak, fontSize: 13),
              ),
            )
          else ...[
            for (final entry in groupedDisplayed.entries) ...[
              Builder(
                builder: (context) {
                  final firstWib = _parseWibDateTime(entry.value.first['created_at']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDateHeader(firstWib),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${entry.value.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFE9D5FF),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              for (final h in entry.value)
                _buildHistoryItemRow(h),
            ],
            if (historyList.length > 5) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    if (_historyFilter == '5') {
                      _historyFilter = 'all';
                    } else {
                      _historyFilter = '5';
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: (_historyFilter == 'all') ? AppColors.surface : const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_historyFilter == 'all') ? AppColors.border : const Color(0xFFE9D5FF),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        (_historyFilter == 'all')
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (_historyFilter == 'all')
                            ? 'Tampilkan 5 riwayat terbaru'
                            : 'Lihat semua riwayat (${historyList.length})',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItemRow(Map<String, dynamic> h) {
    final dateStr = h['created_at']?.toString() ?? '';
    final dt = DateTime.tryParse(dateStr);
    String timeFormatted = dateStr;
    String timeOnly = dateStr;
    if (dt != null) {
      final wib = dt.toUtc().add(const Duration(hours: 7));
      final day = wib.day.toString().padLeft(2, '0');
      final month = wib.month.toString().padLeft(2, '0');
      final year = wib.year;
      final hour = wib.hour.toString().padLeft(2, '0');
      final minute = wib.minute.toString().padLeft(2, '0');
      final second = wib.second.toString().padLeft(2, '0');
      timeFormatted = '$day-$month-$year $hour:$minute:$second WIB';
      timeOnly = '$hour:$minute:$second WIB';
    }

    // Tampilkan nama actor dan nama unit kerja (Nama · Unit), bukan ID
    final actorObj = h['actor'];
    String actorName = '-';
    String actorUnit = '';
    if (actorObj is Map) {
      actorName = actorObj['nama_karyawan']?.toString().trim() ??
          actorObj['id_nik']?.toString().trim() ??
          '-';
      actorUnit = actorObj['nama_unit']?.toString().trim() ?? '';
      if (actorUnit.isEmpty && actorObj['unit'] is Map) {
        actorUnit = actorObj['unit']['nama_unit']?.toString().trim() ?? '';
      }
      if (actorUnit.isEmpty && actorObj['id_unit'] != null) {
        actorUnit = controller.unitName(actorObj['id_unit'].toString());
      }
    } else if (h['actor_id'] != null) {
      final aNik = h['actor_id'].toString().trim();
      actorName = controller.userName(aNik);
      actorUnit = controller.employeeUnitName(aNik);
    } else {
      actorName = 'Sistem';
    }
    final actor = (actorUnit.isNotEmpty && actorUnit != '-') ? '$actorName · $actorUnit' : actorName;

    var desc = h['description']?.toString() ?? '-';

    // Format PIC beserta nama unit kerja jika ada di new_value atau description
    final newVal = h['new_value'];
    if (newVal is Map) {
      List<String> picLabels = [];
      if (newVal['pics'] is List && (newVal['pics'] as List).isNotEmpty) {
        picLabels = (newVal['pics'] as List).map<String>((p) {
          if (p is Map) {
            final pName = p['nama_karyawan']?.toString().trim() ?? p['id_nik']?.toString().trim() ?? '';
            final pUnit = p['nama_unit']?.toString().trim() ?? '';
            return (pUnit.isNotEmpty && pUnit != '-') ? '$pName ($pUnit)' : pName;
          }
          return p.toString();
        }).where((s) => s.isNotEmpty).toList();
      } else if (newVal['nama_pics'] is List && (newVal['nama_pics'] as List).isNotEmpty) {
        picLabels = (newVal['nama_pics'] as List).map((n) => n.toString()).toList();
      } else if (newVal['id_nik_pics'] is List && (newVal['id_nik_pics'] as List).isNotEmpty) {
        picLabels = (newVal['id_nik_pics'] as List).map((nik) {
          final pName = controller.userName(nik.toString());
          final pUnit = controller.employeeUnitName(nik.toString());
          return (pUnit.isNotEmpty && pUnit != '-') ? '$pName ($pUnit)' : pName;
        }).toList();
      }

      if (picLabels.isNotEmpty) {
        final pJoined = picLabels.join(', ');
        if (desc.contains('Laporan baru dibuat') && !desc.contains('PIC:')) {
          desc = '$desc. PIC: $pJoined';
        } else if (desc.contains('Penugasan PIC diperbarui') && !desc.contains(':')) {
          desc = '$desc: $pJoined';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        actor,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textStrong,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: timeFormatted,
                      child: Text(
                        timeOnly,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textWeak,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textStrong,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _actionDetails(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      m['id_detail'] = m['id_detail_tindakan'] ?? m['id_detail'];
      m['deskripsi_tindakan'] = m['nama_tindakan'] ?? m['deskripsi_tindakan'];
      m['selesai'] = m['is_completed'] == true || m['selesai'] == true;
      return m;
    }).toList();
  }

  Map<String, bool> _actionProgress(dynamic value) {
    if (value is! List) return {};
    return {
      for (final item in value.whereType<Map>())
        if (item['id_detail_tindakan'] != null || item['id_detail'] != null)
          (item['id_detail_tindakan'] ?? item['id_detail']).toString():
              item['is_completed'] == true || item['selesai'] == true,
    };
  }

  Widget _dropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
    Map<String, String>? labels,
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
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(labels?[item] ?? item),
                ),
              )
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
      'Menunggu Approval' => Colors.purple,
      'Dikembalikan' => Colors.redAccent,
      'On Progress' => AppColors.info,
      _ => AppColors.warning,
    };
  }

  String _displayStatus(String? status) {
    return switch (status?.trim().toUpperCase()) {
      'COMPLETED' || 'DONE' || 'SELESAI' => 'Done',
      'PENDING_APPROVAL' || 'PENDING APPROVAL' => 'Menunggu Approval',
      'RETURNED' || 'DIKEMBALIKAN' => 'Dikembalikan',
      'IN_PROGRESS' || 'ON PROGRESS' || 'PROSES' => 'On Progress',
      _ => 'Open',
    };
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    // [MODIFIKASI] Sesuaikan format tanggal laporan menjadi DD-MM-YYYY
    return '$day-$month-${date.year}';
  }

  // [MODIFIKASI] Helper format tampilan tanggal laporan menjadi DD-MM-YYYY dari string ISO atau DateTime
  String _formatDisplayDate(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    if (text.isEmpty || text == '-') return '-';

    final dt = DateTime.tryParse(text);
    if (dt != null) {
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day-$month-${dt.year}';
    }

    final clean = text.replaceAll('/', '-');
    final parts = clean.split('-');
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        final y = parts[0];
        final m = parts[1].padLeft(2, '0');
        final d = parts[2].padLeft(2, '0');
        return '$d-$m-$y';
      }
      if (parts[2].length == 4) {
        final d = parts[0].padLeft(2, '0');
        final m = parts[1].padLeft(2, '0');
        final y = parts[2];
        return '$d-$m-$y';
      }
    }
    return text;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) return isoDate;

    final clean = value.replaceAll('/', '-');
    final parts = clean.split('-');
    if (parts.length != 3) return null;
    if (parts[0].length == 4) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) return null;
      return DateTime(year, month, day);
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
