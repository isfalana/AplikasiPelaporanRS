import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/api_services.dart';
import '../../../data/services/notification_service.dart';
import '../../../global_widgets/bukti_preview.dart';
import '../../../global_widgets/image_upload_field.dart';
import '../../laporan/controllers/laporan_controller.dart';

class TindakanController extends GetxController {
  TindakanController({required this.laporanController});

  /// Endpoint master template tindakan pada backend.
  static const _templateEndpoint = '/master/templates';

  final LaporanController laporanController;

  final activeNik = ''.obs;
  final activeName = ''.obs;
  final activeUnit = ''.obs;
  final selectedReport = Rxn<Map<String, dynamic>>();
  final actionItems = <Map<String, dynamic>>[].obs;
  final actionTemplates = <Map<String, dynamic>>[].obs;
  final isLoadingTemplates = false.obs;
  final isLoadingActions = false.obs;
  final usingDemoTemplates = false.obs;
  final selectedTemplateId = RxnString();
  final selectedStatus = 'Open'.obs;
  final actionInputController = TextEditingController();
  final noteController = TextEditingController();

  // Bukti tindak lanjut yang dipilih
  final buktiTindakanName = ''.obs;
  final buktiTindakanBytes = Rxn<Uint8List>();
  // [MODIFIKASI] Observable URL bukti tindak lanjut dari backend agar dapat ditampilkan di preview foto
  final buktiTindakanUrl = ''.obs;

  final listFilters = <String>{}.obs;

  int _detailCounter = 0;

  List<Map<String, dynamic>> get reportsForCurrentUser {
    if (!canView) return [];
    final reports = laporanController.listLaporan;
    return reports.where(_isPicOfCurrentUser).toList();
  }

  bool get canView => _hasPermission('tindakan.lihat');
  bool get canUpdate => _hasPermission('tindakan.ubah');

  bool _hasPermission(String permission) {
    final nik = activeNik.value.trim();
    if (nik.isEmpty) return true;
    return laporanController.master.hasPermission(nik, permission);
  }

  @override
  void onInit() {
    super.onInit();
    _loadActiveUser();
    fetchTemplates();
  }

  /// [MODIFIKASI] Reset tampilan ke kondisi awal (tanpa filter, form bersih, dan laporan default terpilih)
  void resetToInitialView() {
    listFilters.clear();
    actionInputController.clear();
    noteController.clear();
    buktiTindakanName.value = '';
    buktiTindakanBytes.value = null;
    buktiTindakanUrl.value = '';
    selectedTemplateId.value = null;
    laporanController.fetchLaporanData().then((_) {
      final reports = reportsForCurrentUser;
      if (reports.isNotEmpty) {
        selectReport(reports.first);
      } else {
        selectedReport.value = null;
        actionItems.clear();
      }
    });
  }

  Future<void> _loadActiveUser() async {
    final preferences = await SharedPreferences.getInstance();
    activeNik.value = preferences.getString('id_nik') ?? '';
    activeName.value = preferences.getString('nama_karyawan') ?? '';
    activeUnit.value = preferences.getString('unit_name') ?? '';

    // [MODIFIKASI] Selalu segarkan data laporan dari backend agar data tindakan dan status laporan sinkron
    await laporanController.fetchLaporanData();

    // [MODIFIKASI] Periksa apakah ada target laporan yang diteruskan melalui Get.arguments (misal dari tombol 'Berikan Tindakan')
    final arg = Get.arguments;
    Map<String, dynamic>? initialReport;
    if (arg is Map<String, dynamic>) {
      initialReport = arg;
    } else if (arg is String && arg.isNotEmpty) {
      initialReport = laporanController.listLaporan.firstWhereOrNull(
        (r) => r['id_laporan']?.toString() == arg,
      );
    }

    if (initialReport != null) {
      selectReport(initialReport);
    } else {
      final reports = reportsForCurrentUser;
      if (selectedReport.value == null && reports.isNotEmpty) {
        selectReport(reports.first);
      } else if (selectedReport.value != null &&
          !reports.any(
            (report) =>
                report['id_laporan'] == selectedReport.value?['id_laporan'],
          )) {
        selectedReport.value = reports.isEmpty ? null : reports.first;
        if (selectedReport.value != null) {
          selectReport(selectedReport.value!);
        }
      }
    }
  }

  Future<void> fetchTemplates() async {
    if (isLoadingTemplates.value) return;
    isLoadingTemplates.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get(_templateEndpoint);
      actionTemplates.assignAll(
        _extractRows(response.data).map(_normalizeTemplate),
      );
      usingDemoTemplates.value = false;
    } on DioException {
      _useDemoTemplates();
    } catch (_) {
      _useDemoTemplates();
    } finally {
      isLoadingTemplates.value = false;
    }
  }

  void _useDemoTemplates() {
    usingDemoTemplates.value = true;
    if (actionTemplates.isEmpty) {
      actionTemplates.assignAll(_demoTemplates());
    }
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    dynamic rows = payload;
    if (payload is Map) {
      rows =
          payload['data'] ??
          payload['rows'] ??
          payload['templateTindakan'] ??
          payload['templates'] ??
          payload['items'];
      if (rows is Map) {
        rows = rows['rows'] ?? rows['data'] ?? rows['items'];
      }
    }
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Map<String, dynamic> _normalizeTemplate(Map<String, dynamic> row) {
    final rawList =
        row['details'] ?? row['list_tindakan'] ?? row['listTindakan'];
    final actions = rawList is List
        ? rawList.map((item) {
            final desc = item is Map
                ? (item['nama_tindakan'] ??
                    item['deskripsi_tindakan'] ??
                    item['deskripsiTindakan'] ??
                    '')
                : item;
            return <String, dynamic>{
              'deskripsi_tindakan': desc.toString(),
            };
          }).toList()
        : <Map<String, dynamic>>[];
    return {
      'id_template': (row['id_template'] ?? row['idTemplate'] ?? '').toString(),
      'nama_template':
          (row['nama_template'] ?? row['namaTemplate'] ?? '').toString(),
      'list_tindakan': actions,
    };
  }

  List<Map<String, dynamic>> _demoTemplates() {
    return [
      {
        'id_template': 'TPL-01',
        'nama_template': 'Perbaikan Fasilitas / AC',
        'list_tindakan': [
          {'deskripsi_tindakan': 'Melakukan pemeriksaan kerusakan'},
          {'deskripsi_tindakan': 'Mengidentifikasi penyebab kerusakan'},
          {'deskripsi_tindakan': 'Melakukan perbaikan'},
          {'deskripsi_tindakan': 'Melakukan pengujian hasil perbaikan'},
        ],
      },
      {
        'id_template': 'TPL-02',
        'nama_template': 'Pengadaan Barang',
        'list_tindakan': [
          {'deskripsi_tindakan': 'Memeriksa kebutuhan barang'},
          {'deskripsi_tindakan': 'Mengajukan permintaan pengadaan'},
          {'deskripsi_tindakan': 'Melakukan verifikasi barang'},
        ],
      },
    ];
  }

  String reporterLabel(Map<String, dynamic> report) {
    final nik = report['id_nik_pelapor']?.toString().trim() ?? '';
    final name = report['nama_pelapor']?.toString().trim() ?? '';
    final unit =
        report['nama_unit_pelapor']?.toString().trim() ??
        report['id_unit_pelapor']?.toString().trim() ??
        '';
    final displayName =
        name.isNotEmpty ? name : laporanController.userName(nik);
    final displayUnit = laporanController.unitName(unit);
    final values = [
      displayName,
      displayUnit,
    ].where((value) => value.trim().isNotEmpty).toList();
    return values.isEmpty ? '-' : values.join(' · ');
  }

  String kategoriLabel(Map<String, dynamic> report) {
    final raw =
        report['id_kategori'] ?? report['kategori'] ?? report['nama_kategori'];
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return '-';
    final name = laporanController.kategoriName(value);
    return name.trim().isEmpty ? value : name;
  }

  // [MODIFIKASI] Label PIC untuk detail tindakan: Menampilkan nama karyawan dan unit kerja (Nama · Unit)
  String picLabel(Map<String, dynamic> report) {
    final storedPicUnit = report['nama_pic_unit']?.toString().trim();
    if (storedPicUnit != null && storedPicUnit.isNotEmpty && storedPicUnit != '-') {
      return storedPicUnit;
    }
    final rawNiks = (report['id_nik_pic'] ?? report['nik_pic'])?.toString() ?? '';
    final ids = rawNiks
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (ids.isNotEmpty) {
      final entries = ids.map((nik) {
        final name = laporanController.userName(nik);
        var uName = laporanController.employeeUnitName(nik);
        if (uName.isEmpty) {
          final repUnit = report['nama_unit_pic'] ?? report['id_unit_pic'] ?? report['unit_pic'];
          if (repUnit != null && repUnit.toString().isNotEmpty) {
            uName = laporanController.unitName(repUnit.toString());
          }
        }
        final values = [
          (name.isNotEmpty && name != nik) ? name : nik,
          uName,
        ].where((v) => v.isNotEmpty && v != '-').toList();
        return values.join(' · ');
      }).where((e) => e.isNotEmpty).toList();

      if (entries.isNotEmpty) {
        return entries.join(', ');
      }
    }

    final picDisplay = report['nama_pic']?.toString().trim();
    if (picDisplay != null && picDisplay.isNotEmpty && picDisplay != '-') {
      final repUnit = report['nama_unit_pic'] ?? report['id_unit_pic'] ?? report['unit_pic'];
      final uName = repUnit != null ? laporanController.unitName(repUnit.toString()) : '';
      final values = [picDisplay, uName].where((v) => v.isNotEmpty && v != '-').toList();
      return values.join(' · ');
    }
    return '-';
  }

  // [MODIFIKASI] Menampilkan informasi Last Update By lengkap (Nama · Unit), fallback ke Pelapor
  String lastUpdateByDisplay(Map<String, dynamic> report) {
    final raw = (report['last_update_by'] ?? report['lastUpdateBy'])?.toString().trim();
    if (raw != null && raw.isNotEmpty && raw != '-') {
      if (!raw.contains('·') && !raw.contains(' - ') && !raw.contains(' ')) {
        final name = laporanController.userName(raw);
        final unit = laporanController.employeeUnitName(raw);
        final parts = [name, unit].where((v) => v.isNotEmpty && v != '-').toList();
        return parts.isEmpty ? raw : parts.join(' · ');
      }
      return raw;
    }
    return reporterLabel(report);
  }

  String updaterLabel() {
    final nik = activeNik.value.trim();
    var name = activeName.value.trim();
    if (name.isEmpty && nik.isNotEmpty) {
      name = laporanController.userName(nik);
    }
    final unitRaw = activeUnit.value.trim();
    final unit = unitRaw.isEmpty ? '' : laporanController.unitName(unitRaw);
    final values = [
      name,
      unit,
    ].where((value) => value.trim().isNotEmpty).toList();
    return values.isEmpty ? '-' : values.join(' · ');
  }

  bool _isPicOfCurrentUser(Map<String, dynamic> report) {
    final nik = activeNik.value.trim().toLowerCase();
    if (nik.isEmpty) return false;

    // Cek penugasan_pic dari backend
    final penugasan = report['penugasan_pic'];
    if (penugasan is List) {
      for (final p in penugasan) {
        final pNik = (p is Map ? (p['id_nik_pic'] ?? p['pic']?['id_nik']) : p)
            ?.toString()
            .trim()
            .toLowerCase();
        if (pNik == nik) return true;
      }
    }

    final assignedNiks = (report['id_nik_pic']?.toString() ?? '')
        .split(',')
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList();

    if (assignedNiks.isNotEmpty) {
      return assignedNiks.contains(nik);
    }

    // Role Admin boleh melihat semua laporan
    final role = laporanController.master.employeeRole(nik);
    if (role == 'R-01' || role.toLowerCase().contains('admin')) {
      return true;
    }

    // Fallback untuk unit
    final currentUnits = _unitTokens(activeUnit.value);
    if (currentUnits.isEmpty) return false;
    final assignedUnits = [
      report['id_unit_pic']?.toString(),
      report['unit_pic']?.toString(),
      report['nama_unit_pic']?.toString(),
    ].whereType<String>().expand(_unitTokens);
    return assignedUnits.any(currentUnits.contains);
  }

  Set<String> _unitTokens(String value) {
    return value
        .split(RegExp(r'[,/]'))
        .map(
          (part) => part
              .trim()
              .toLowerCase()
              .replaceFirst(RegExp(r'^unit[\s_-]*'), '')
              .replaceAll(RegExp(r'[\s_-]+'), ''),
        )
        .where((part) => part.isNotEmpty)
        .toSet();
  }

  void selectReport(Map<String, dynamic> report) {
    selectedReport.value = report;
    actionInputController.clear();
    selectedStatus.value = _normalizeStatus(report['status']?.toString());
    // [MODIFIKASI] Tampilkan keterangan tindak lanjut dan bukti tindak lanjut yang tersimpan
    noteController.text = report['keterangan_tindakan']?.toString() ?? '';
    buktiTindakanName.value = report['bukti_tindakan']?.toString() ?? '';
    buktiTindakanBytes.value = null;
    buktiTindakanUrl.value = report['bukti_tindakan_url']?.toString() ?? '';

    // Pastikan bukti_url pelapor juga tersimpan di report jika belum ada
    if ((report['bukti_url'] == null || report['bukti_url'].toString().isEmpty) && report['evidence'] is List) {
      final evList = (report['evidence'] as List).whereType<Map>().toList();
      if (evList.isNotEmpty) {
        final evId = evList.first['id_evidence']?.toString();
        if (evId != null && evId.isNotEmpty) {
          report['bukti_url'] = '${ApiService.baseUrl}/evidence/file/$evId';
          report['id_evidence'] = evId;
        }
      }
    }

    final reportId = report['id_laporan']?.toString();
    if (reportId != null) {
      fetchTindakanFromBackend(reportId);
    } else {
      actionItems.clear();
    }
  }

  Future<void> fetchTindakanFromBackend(String idLaporan) async {
    isLoadingActions.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get('/tindakan/laporan/$idLaporan');
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data['data'];
        if (raw is List) {
          final items = raw.map((item) {
            final m = Map<String, dynamic>.from(item);
            m['id_detail'] =
                m['id_detail_tindakan'] ?? m['id_detail'] ?? _newDetailId();
            m['deskripsi_tindakan'] =
                m['nama_tindakan'] ?? m['deskripsi_tindakan'] ?? '';
            m['selesai'] = m['is_completed'] == true;
            return m;
          }).toList();
          actionItems.assignAll(items);
        }
      }
    } catch (e) {
      debugPrint('Error fetchTindakan: $e');
    } finally {
      isLoadingActions.value = false;
    }
  }

  void _refreshSelectedReport() {
    final currentId = selectedReport.value?['id_laporan']?.toString();
    if (currentId == null) return;
    final match = laporanController.listLaporan.firstWhereOrNull(
      (r) => r['id_laporan']?.toString() == currentId,
    );
    if (match != null) {
      selectedReport.value = Map<String, dynamic>.from(match);
      selectedStatus.value = _normalizeStatus(match['status']?.toString());
      // [MODIFIKASI] Perbarui URL bukti tindak lanjut setelah data laporan di-refresh
      buktiTindakanUrl.value = match['bukti_tindakan_url']?.toString() ?? '';
    }
  }

  bool get allActionsComplete =>
      actionItems.isNotEmpty &&
      actionItems.every((item) => item['selesai'] == true);

  bool isReportDone(Map<String, dynamic> report) {
    final s = report['status']?.toString().toUpperCase();
    return s == 'COMPLETED' || s == 'DONE';
  }

  String _normalizeStatus(String? status) {
    return switch (status?.trim().toUpperCase()) {
      'COMPLETED' || 'DONE' || 'SELESAI' => 'Done',
      'PENDING_APPROVAL' || 'PENDING APPROVAL' => 'Menunggu Approval',
      'RETURNED' || 'DIKEMBALIKAN' => 'Dikembalikan',
      'IN_PROGRESS' || 'ON PROGRESS' || 'PROSES' => 'On Progress',
      _ => 'Open',
    };
  }

  String _newDetailId() {
    return 'DT-${DateTime.now().microsecondsSinceEpoch}-${_detailCounter++}';
  }

  Future<bool> addActionItem(String description) async {
    final report = selectedReport.value;
    if (report != null && isReportDone(report)) return false;
    final text = description.trim();
    if (text.isEmpty) return false;
    final reportId = report?['id_laporan']?.toString();
    if (reportId == null) return false;

    try {
      final dio = await ApiService.getClient();
      final response = await dio.post('/tindakan', data: {
        'id_laporan': reportId,
        'nama_tindakan': text,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        actionInputController.clear();
        await fetchTindakanFromBackend(reportId);
        await laporanController.fetchLaporanData();
        _refreshSelectedReport();
        return true;
      }
      return false;
    } on DioException catch (e) {
      Get.snackbar(
        'Gagal',
        e.response?.data?['message'] ?? 'Gagal menambah tindakan',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> toggleActionItem(int index, bool? isDone) async {
    final report = selectedReport.value;
    if (report != null && isReportDone(report)) return;
    if (index < 0 || index >= actionItems.length) return;

    final item = actionItems[index];
    final detailId = item['id_detail_tindakan'] ?? item['id_detail'];
    final targetVal = isDone ?? false;

    actionItems[index]['selesai'] = targetVal;
    actionItems.refresh();

    if (detailId != null && detailId.toString().isNotEmpty) {
      try {
        final dio = await ApiService.getClient();
        final response = await dio.put(
          '/tindakan/$detailId/toggle',
          data: {'is_completed': targetVal},
        );

        if (response.statusCode == 200) {
          final reportId = report?['id_laporan']?.toString();
          if (reportId != null) {
            await laporanController.fetchLaporanData();
            _refreshSelectedReport();
            if (Get.isRegistered<NotificationService>()) {
              NotificationService.to.fetchNotifications(silent: true);
            }
          }
        }
      } on DioException catch (e) {
        actionItems[index]['selesai'] = !targetVal;
        actionItems.refresh();
        Get.snackbar(
          'Gagal',
          e.response?.data?['message'] ?? 'Gagal memperbarui checklist',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<String?> applyTemplateById(String? templateId) async {
    final report = selectedReport.value;
    if (report != null && isReportDone(report)) {
      return 'Laporan yang sudah Done tidak dapat diubah lagi.';
    }
    final reportId = report?['id_laporan']?.toString();
    if (reportId == null) return 'Pilih laporan terlebih dahulu.';

    final id = templateId?.trim() ?? '';
    if (id.isEmpty) return 'Pilih template terlebih dahulu.';

    try {
      final dio = await ApiService.getClient();
      final response = await dio.post('/tindakan/apply-template', data: {
        'id_laporan': reportId,
        'id_template': id,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchTindakanFromBackend(reportId);
        await laporanController.fetchLaporanData();
        _refreshSelectedReport();
        return null;
      }
      return 'Gagal menerapkan template.';
    } on DioException catch (e) {
      return e.response?.data?['message'] ?? 'Gagal menerapkan template: ${e.message}';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> removeActionItem(int index) async {
    final report = selectedReport.value;
    if (report != null && isReportDone(report)) return;
    if (index < 0 || index >= actionItems.length) return;

    final item = actionItems[index];
    final detailId = item['id_detail_tindakan'] ?? item['id_detail'];

    if (detailId != null && detailId.toString().isNotEmpty) {
      try {
        final dio = await ApiService.getClient();
        await dio.delete('/tindakan/$detailId');
        final reportId = report?['id_laporan']?.toString();
        if (reportId != null) {
          await fetchTindakanFromBackend(reportId);
          await laporanController.fetchLaporanData();
          _refreshSelectedReport();
        }
      } catch (_) {
        actionItems.removeAt(index);
      }
    } else {
      actionItems.removeAt(index);
    }
  }

  Future<String?> saveAction() async {
    final report = selectedReport.value;
    if (report == null) return 'Pilih laporan yang akan ditindaklanjuti.';
    if (isReportDone(report)) {
      return 'Laporan yang sudah Done tidak dapat diubah lagi.';
    }
    if (!canUpdate) {
      return 'Akun Anda tidak memiliki akses untuk menyimpan tindak lanjut.';
    }
    if (!_isPicOfCurrentUser(report)) {
      return 'Laporan ini bukan tanggung jawab PIC akun Anda.';
    }

    final reportId = report['id_laporan']?.toString();
    if (reportId == null) return 'ID laporan tidak valid.';

    // [MODIFIKASI] Validasi bukti foto tindak lanjut wajib diisi sebelum menyimpan (Revisi 5)
    final hasBuktiTindakan = (buktiTindakanBytes.value != null &&
            buktiTindakanBytes.value!.isNotEmpty) ||
        buktiTindakanUrl.value.trim().isNotEmpty ||
        (report['bukti_tindakan'] != null &&
            report['bukti_tindakan'].toString().trim().isNotEmpty &&
            report['bukti_tindakan'] != '-');
    if (!hasBuktiTindakan) {
      return 'Bukti dokumen/foto tindak lanjut wajib diunggah sebelum menyimpan.';
    }

    // [MODIFIKASI] Validasi batasan ukuran file bukti tindakan (maksimal 5 MB)
    if (buktiTindakanBytes.value != null &&
        buktiTindakanBytes.value!.lengthInBytes > ImageUploadField.maxFileSizeBytes) {
      return 'Ukuran file bukti tindakan (${buktiFileSize(buktiTindakanBytes.value)}) melebihi batas maksimal ${ImageUploadField.maxFileSizeText}. Silakan sesuaikan ukuran file Anda.';
    }

    // Jika ada bukti foto tindak lanjut, unggah ke backend
    if (buktiTindakanBytes.value != null &&
        buktiTindakanBytes.value!.isNotEmpty) {
      try {
        final dio = await ApiService.getClient();
        final formData = FormData.fromMap({
          'id_laporan': reportId,
          'file': MultipartFile.fromBytes(
            buktiTindakanBytes.value!,
            filename: buktiTindakanName.value.isNotEmpty
                ? buktiTindakanName.value
                : 'bukti_tindakan.jpg',
          ),
        });
        await dio.post('/evidence', data: formData);
      } catch (e) {
        debugPrint('Gagal unggah bukti tindakan: $e');
      }
    }

    // [MODIFIKASI] Simpan keterangan tindak lanjut dan bukti tindak lanjut ke backend
    final note = noteController.text.trim();
    final filename = buktiTindakanName.value.trim().isNotEmpty
        ? buktiTindakanName.value.trim()
        : (buktiTindakanBytes.value != null ? 'bukti_tindakan.jpg' : null);

    await laporanController.saveTindakLanjut(
      idLaporan: reportId,
      keteranganTindakan: note,
      buktiTindakan: filename,
    );

    await laporanController.fetchLaporanData();
    _refreshSelectedReport();
    if (Get.isRegistered<NotificationService>()) {
      NotificationService.to.fetchNotifications(silent: true);
    }
    return null;
  }

  @override
  void onClose() {
    actionInputController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
