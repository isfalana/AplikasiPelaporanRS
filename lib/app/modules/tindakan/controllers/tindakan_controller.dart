import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/api_services.dart';
import '../../laporan/controllers/laporan_controller.dart';

class TindakanController extends GetxController {
  TindakanController({required this.laporanController});

  /// Endpoint master template tindakan pada backend.
  static const _templateEndpoint = '/template-tindakan';

  final LaporanController laporanController;

  final activeNik = ''.obs;
  final activeName = ''.obs;
  final activeUnit = ''.obs;
  final selectedReport = Rxn<Map<String, dynamic>>();
  final actionItems = <Map<String, dynamic>>[].obs;
  final actionTemplates = <Map<String, dynamic>>[].obs;
  final isLoadingTemplates = false.obs;
  final usingDemoTemplates = false.obs;
  final selectedTemplateId = RxnString();
  final selectedStatus = 'Open'.obs;
  final actionInputController = TextEditingController();
  final noteController = TextEditingController();

  // Bukti tindak lanjut yang dipilih (pratinjau lokal, belum diunggah).
  final buktiTindakanName = ''.obs;
  final buktiTindakanBytes = Rxn<Uint8List>();

  // Filter aktif pada card "Daftar Tindakan". Bisa lebih dari satu.
  final listFilters = <String>{}.obs;

  final Map<String, List<Map<String, dynamic>>> _detailsByReport = {};

  /// Laporan yang menjadi tanggung jawab akun ini.
  ///
  /// Semua status tetap ditampilkan (Open, On Progress, maupun Done) agar
  /// penindak masih bisa melihat riwayat tindakan yang sudah selesai.
  List<Map<String, dynamic>> get reportsForCurrentUser {
    final reports = laporanController.listLaporan;
    return reports.where(_isAssignedToCurrentUser).toList();
  }

  @override
  void onInit() {
    super.onInit();
    if (reportsForCurrentUser.isNotEmpty) {
      selectReport(reportsForCurrentUser.first);
    }
    _loadActiveUser();
    fetchTemplates();
  }

  /// Ambil daftar template tindakan dari backend. Bila server belum
  /// terhubung, pakai data contoh agar pilihan template tetap muncul.
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

  /// Seragamkan bentuk template dari backend: `list_tindakan` boleh berupa
  /// string maupun object berisi `deskripsi_tindakan`.
  Map<String, dynamic> _normalizeTemplate(Map<String, dynamic> row) {
    final rawList = row['list_tindakan'] ?? row['listTindakan'];
    final actions = rawList is List
        ? rawList
              .map(
                (item) => item is Map
                    ? <String, dynamic>{
                        'deskripsi_tindakan':
                            (item['deskripsi_tindakan'] ??
                                    item['deskripsiTindakan'] ??
                                    item)
                                .toString(),
                      }
                    : <String, dynamic>{'deskripsi_tindakan': item.toString()},
              )
              .toList()
        : <Map<String, dynamic>>[];
    return {
      'id_template': (row['id_template'] ?? row['idTemplate'] ?? '').toString(),
      'nama_template': (row['nama_template'] ?? row['namaTemplate'] ?? '')
          .toString(),
      'list_tindakan': actions,
    };
  }

  List<Map<String, dynamic>> _demoTemplates() {
    return [
      {
        'id_template': 'TPL-01',
        'nama_template': 'Perbaikan AC',
        'list_tindakan': [
          {'deskripsi_tindakan': 'Cek suhu dan tekanan freon AC'},
          {'deskripsi_tindakan': 'Bersihkan filter dan evaporator'},
          {'deskripsi_tindakan': 'Uji ulang suhu ruangan'},
        ],
      },
      {
        'id_template': 'TPL-02',
        'nama_template': 'Gangguan Jaringan LAN',
        'list_tindakan': [
          {'deskripsi_tindakan': 'Cek kabel dan switch jaringan'},
          {'deskripsi_tindakan': 'Restart perangkat jaringan'},
          {'deskripsi_tindakan': 'Konfirmasi koneksi ke pengguna'},
        ],
      },
      {
        'id_template': 'TPL-03',
        'nama_template': 'Pembersihan Fasilitas',
        'list_tindakan': [
          {'deskripsi_tindakan': 'Lakukan pembersihan menyeluruh'},
          {'deskripsi_tindakan': 'Foto kondisi sebelum dan sesudah'},
        ],
      },
    ];
  }

  Future<void> _loadActiveUser() async {
    final preferences = await SharedPreferences.getInstance();
    activeNik.value = preferences.getString('id_nik') ?? '';
    activeName.value = preferences.getString('nama_karyawan') ?? '';
    activeUnit.value = preferences.getString('unit_name') ?? '';
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

  /// Label pelapor pada kartu/detail: "Nama · Unit".
  String reporterLabel(Map<String, dynamic> report) {
    final nik = report['id_nik_pelapor']?.toString().trim() ?? '';
    final name = report['nama_pelapor']?.toString().trim() ?? '';
    final unit =
        report['nama_unit_pelapor']?.toString().trim() ??
        report['id_unit_pelapor']?.toString().trim() ??
        '';
    final displayName = name.isNotEmpty
        ? name
        : laporanController.userName(nik);
    final displayUnit = laporanController.unitName(unit);
    final values = [
      displayName,
      displayUnit,
    ].where((value) => value.trim().isNotEmpty).toList();
    return values.isEmpty ? '-' : values.join(' · ');
  }

  /// Label penanggung jawab perubahan tindak lanjut terakhir:
  /// "Nama · Unit". Dipakai pada kolom "Last update by".
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

  bool _isAssignedToCurrentUser(Map<String, dynamic> report) {
    final nik = activeNik.value.trim().toLowerCase();
    final assignedNiks = (report['id_nik_pic']?.toString() ?? '')
        .split(',')
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty);
    if (nik.isNotEmpty && assignedNiks.contains(nik)) return true;

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
    final reportId = report['id_laporan']?.toString() ?? '';
    final savedDetails =
        _detailsByReport[reportId] ??
        _detailsFromReport(
          report['detail_tindakan'] ?? report['detailTindakan'],
        );
    final savedProgress = _progressFromReport(report['progres_tindakan']);
    actionItems.assignAll(
      savedDetails.map((item) {
        final action = Map<String, dynamic>.from(item);
        final detailId = action['id_detail']?.toString();
        if (detailId != null && savedProgress.containsKey(detailId)) {
          action['selesai'] = savedProgress[detailId];
        }
        action.putIfAbsent('selesai', () => false);
        return action;
      }),
    );
    selectedStatus.value = _normalizeStatus(report['status']?.toString());
    noteController.text = report['keterangan_tindakan']?.toString() ?? '';
    buktiTindakanName.value = report['bukti_tindakan']?.toString() ?? '';
    final savedBukti = report['bukti_tindakan_bytes'];
    buktiTindakanBytes.value = savedBukti is Uint8List ? savedBukti : null;
  }

  List<Map<String, dynamic>> _detailsFromReport(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, bool> _progressFromReport(dynamic value) {
    if (value is! List) return {};
    return {
      for (final item in value.whereType<Map>())
        if (item['id_detail'] != null)
          item['id_detail'].toString(): item['selesai'] == true,
    };
  }

  String _normalizeStatus(String? status) {
    return switch (status?.trim().toLowerCase()) {
      'done' || 'selesai' => 'Done',
      'on progress' ||
      'on progres' ||
      'proses' ||
      'in progress' => 'On Progress',
      _ => 'Open',
    };
  }

  bool addActionItem(String description) {
    final text = description.trim();
    if (text.isEmpty) return false;
    actionItems.add({
      'id_detail': 'DT-${DateTime.now().microsecondsSinceEpoch}',
      'id_laporan': selectedReport.value?['id_laporan']?.toString() ?? '',
      'id_nik_pic': activeNik.value,
      'deskripsi_tindakan': text,
      'file_lampiran': null,
      'selesai': false,
    });
    return true;
  }

  void toggleActionItem(int index, bool? isDone) {
    if (index < 0 || index >= actionItems.length) return;
    actionItems[index]['selesai'] = isDone ?? false;
    actionItems.refresh();
  }

  /// Terapkan template berdasarkan ID yang dipilih penindak.
  /// Mengembalikan pesan error, atau null bila berhasil.
  String? applyTemplateById(String? templateId) {
    final id = templateId?.trim() ?? '';
    if (id.isEmpty) return 'Pilih template terlebih dahulu.';
    Map<String, dynamic>? template;
    for (final item in actionTemplates) {
      if (item['id_template']?.toString() == id) {
        template = item;
        break;
      }
    }
    if (template == null) return 'Template tidak ditemukan.';

    final before = actionItems.length;
    applyTemplate(template);
    if (actionItems.length == before) {
      return 'Template tidak berisi daftar tindakan.';
    }
    return null;
  }

  void applyTemplate(Map<String, dynamic> template) {
    final actions = template['list_tindakan'];
    if (actions is! List) return;
    for (final action in actions) {
      final description = action is Map
          ? action['deskripsi_tindakan']?.toString() ?? ''
          : action.toString();
      if (description.trim().isEmpty) continue;
      addActionItem(description);
    }
  }

  void removeActionItem(int index) {
    if (index < 0 || index >= actionItems.length) return;
    actionItems.removeAt(index);
  }

  String? saveAction() {
    final report = selectedReport.value;
    if (report == null) return 'Pilih laporan yang akan ditindaklanjuti.';
    if (!_isAssignedToCurrentUser(report)) {
      return 'Laporan ini bukan tanggung jawab PIC akun Anda.';
    }
    if (actionItems.isEmpty) {
      return 'Tambahkan minimal satu tindak lanjut.';
    }
    final reportId = report['id_laporan']?.toString() ?? '';
    final details = actionItems
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _detailsByReport[reportId] = details;
    report['detail_tindakan'] = details
        .map(
          (item) => <String, dynamic>{
            'id_detail': item['id_detail'],
            'id_laporan': item['id_laporan'],
            'id_nik_pic': item['id_nik_pic'],
            'deskripsi_tindakan': item['deskripsi_tindakan'],
            'file_lampiran': item['file_lampiran'],
          },
        )
        .toList();
    report['progres_tindakan'] = details
        .map(
          (item) => <String, dynamic>{
            'id_detail': item['id_detail'],
            'selesai': item['selesai'] == true,
          },
        )
        .toList();
    report['keterangan_tindakan'] = noteController.text.trim();
    report['bukti_tindakan'] = buktiTindakanName.value.trim();
    report['bukti_tindakan_bytes'] = buktiTindakanBytes.value;
    report['status'] = selectedStatus.value;
    // Catat siapa (nama + unit) yang terakhir mengubah tindak lanjut ini.
    report['last_update_by'] = updaterLabel();
    if (selectedStatus.value == 'Done') {
      // Laporan yang ditandai Done oleh penindak menunggu validasi pelapor.
      report['validasi_pelapor'] = false;
      report['tgl_validasi'] = null;
      report['validasi_by'] = null;
    }
    laporanController.listLaporan.refresh();
    if (selectedStatus.value == 'Done') {
      selectedReport.value = null;
      actionItems.clear();
      actionInputController.clear();
      noteController.clear();
      buktiTindakanName.value = '';
      buktiTindakanBytes.value = null;
      selectedStatus.value = 'Open';
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
