import 'package:flutter/material.dart';
import 'package:get/get.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';

import '../../laporan/controllers/laporan_controller.dart';

class TindakanController extends GetxController {
  TindakanController({required this.laporanController});

  final LaporanController laporanController;

  final activeNik = ''.obs;
  final activeUnit = ''.obs;
  final selectedReport = Rxn<Map<String, dynamic>>();
  final actionItems = <Map<String, dynamic>>[].obs;
  final actionTemplates = <Map<String, dynamic>>[].obs;
  final selectedStatus = 'Open'.obs;
  final actionInputController = TextEditingController();
  final noteController = TextEditingController();

  final Map<String, List<Map<String, dynamic>>> _detailsByReport = {};

  List<Map<String, dynamic>> get reportsForCurrentUser {
    final reports = laporanController.listLaporan;
    return reports
        .where(
          (report) =>
              _isAssignedToCurrentUser(report) &&
              _normalizeStatus(report['status']?.toString()) != 'Done',
        )
        .toList();
  }
=======
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_services.dart';
import '../../../core/theme/app_colors.dart';

class TindakanController extends GetxController {
  var isLoading = false.obs;
  var isSubmitting = false.obs;

  // List Semua Laporan yang Masuk untuk Ditindak
  var listLaporan = <Map<String, dynamic>>[].obs;
  var filteredLaporan = <Map<String, dynamic>>[].obs;

  // Laporan yang sedang aktif dipilih untuk ditindaklanjuti
  var selectedLaporan = Rxn<Map<String, dynamic>>();

  // Form Tindakan
  final keteranganController = TextEditingController();
  final tambahTindakanController = TextEditingController();
  var selectedStatus = 'On Progress'.obs;
  var listTindakanChecklist = <Map<String, dynamic>>[].obs;

  // User PIC
  var idNikPic = ''.obs;
  var namaPic = ''.obs;
  var unitName = ''.obs;

  // Filter
  var activeFilter = 'Semua'.obs;
>>>>>>> origin/master

  @override
  void onInit() {
    super.onInit();
<<<<<<< HEAD
    if (reportsForCurrentUser.isNotEmpty) {
      selectReport(reportsForCurrentUser.first);
    }
    _loadActiveUser();
  }

  Future<void> _loadActiveUser() async {
    final preferences = await SharedPreferences.getInstance();
    activeNik.value = preferences.getString('id_nik') ?? '';
    activeUnit.value = preferences.getString('unit_name') ?? '';
    final reports = reportsForCurrentUser;
    if (selectedReport.value == null && reports.isNotEmpty) {
      selectReport(reports.first);
    } else if (selectedReport.value != null &&
        !reports.any(
          (report) =>
              report['id_laporan'] ==
              selectedReport.value?['id_laporan'],
        )) {
      selectedReport.value = reports.isEmpty ? null : reports.first;
      if (selectedReport.value != null) {
        selectReport(selectedReport.value!);
      }
    }
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
    actionItems.assignAll(
      savedDetails.map(
        (item) => Map<String, dynamic>.from(item)
          ..putIfAbsent('selesai', () => false),
      ),
    );
    selectedStatus.value = _normalizeStatus(report['status']?.toString());
    noteController.text = report['keterangan_tindakan']?.toString() ?? '';
  }

  List<Map<String, dynamic>> _detailsFromReport(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _normalizeStatus(String? status) {
    return switch (status?.trim().toLowerCase()) {
      'done' || 'selesai' => 'Done',
      'on progress' || 'on progres' || 'proses' || 'in progress' =>
        'On Progress',
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

  void applyTemplate(Map<String, dynamic> template) {
    final actions = template['list_tindakan'];
    if (actions is! List) return;
    for (final action in actions) {
      final description = action is Map
          ? action['deskripsi_tindakan']?.toString() ?? ''
          : action.toString();
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
    report['keterangan_tindakan'] = noteController.text.trim();
    report['status'] = selectedStatus.value;
    laporanController.listLaporan.refresh();
    if (selectedStatus.value == 'Done') {
      selectedReport.value = null;
      actionItems.clear();
      actionInputController.clear();
      noteController.clear();
      selectedStatus.value = 'Open';
    }
    return null;
=======
    loadUserData();
    fetchDaftarLaporan();
>>>>>>> origin/master
  }

  @override
  void onClose() {
<<<<<<< HEAD
    actionInputController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
=======
    keteranganController.dispose();
    tambahTindakanController.dispose();
    super.onClose();
  }

  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      idNikPic.value = prefs.getString('id_nik') ?? '';
      namaPic.value = prefs.getString('nama_karyawan') ?? '';
      unitName.value = prefs.getString('unit_name') ?? '';
    } catch (e) {
      debugPrint('Error loadUserData: $e');
    }
  }

  /// Ambil data laporan dari backend
  Future<void> fetchDaftarLaporan() async {
    isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get('/laporan');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> raw = response.data['data'] ?? [];
        listLaporan.assignAll(raw.map((e) => Map<String, dynamic>.from(e)).toList());
        applyFilter(activeFilter.value);

        // Jika belum ada yang dipilih, pilih item pertama sebagai default
        if (selectedLaporan.value == null && filteredLaporan.isNotEmpty) {
          selectLaporan(filteredLaporan.first);
        } else if (selectedLaporan.value != null) {
          // Refresh item aktif
          final currentId = selectedLaporan.value!['id_laporan'];
          final refreshed = listLaporan.firstWhereOrNull((l) => l['id_laporan'] == currentId);
          if (refreshed != null) {
            selectLaporan(refreshed);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetchDaftarLaporan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Pilih Laporan untuk ditindaklanjuti
  void selectLaporan(Map<String, dynamic> item) {
    selectedLaporan.value = item;
    final status = item['status']?.toString() ?? 'On Progress';
    selectedStatus.value = (status == 'Done' || status == 'On Progress' || status == 'Open') ? status : 'On Progress';
    keteranganController.text = item['keterangan']?.toString() ?? '';

    // Muat riwayat tindakan yang sudah ada
    listTindakanChecklist.clear();
    final rawActions = item['riwayat_tindakan'];
    if (rawActions != null && rawActions is List && rawActions.isNotEmpty) {
      for (var act in rawActions) {
        listTindakanChecklist.add({
          'text': act['deskripsi_tindakan']?.toString() ?? '-',
          'checked': true.obs,
        });
      }
    } else {
      // Default checklist awal
      listTindakanChecklist.addAll([
        {'text': 'Pemeriksaan awal kendala', 'checked': true.obs},
        {'text': 'Perbaikan sistem / koordinasi teknis', 'checked': false.obs},
      ]);
    }
  }

  /// Tambah item checklist tindakan baru
  void showTambahTindakanDialog() {
    tambahTindakanController.clear();
    Get.defaultDialog(
      title: 'Tambah Tindakan',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          controller: tambahTindakanController,
          decoration: const InputDecoration(
            hintText: 'Masukkan uraian tindakan...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        onPressed: () {
          final text = tambahTindakanController.text.trim();
          if (text.isNotEmpty) {
            listTindakanChecklist.add({
              'text': text,
              'checked': false.obs,
            });
            Get.back();
          }
        },
        child: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  /// Kirim Pembaruan Tindakan & Status ke Database
  Future<void> submitTindakan() async {
    if (selectedLaporan.value == null) return;

    final idLaporan = selectedLaporan.value!['id_laporan'];
    final keterangan = keteranganController.text.trim();
    final newStatus = selectedStatus.value;

    isSubmitting.value = true;
    try {
      final dio = await ApiService.getClient();

      // Buat ringkasan tindakan dari checklist
      final checkedActions = listTindakanChecklist
          .where((chk) => (chk['checked'] as RxBool).value == true)
          .map((chk) => chk['text'].toString())
          .toList();

      final deskripsiTindakan = checkedActions.isNotEmpty
          ? checkedActions.join(', ')
          : (keterangan.isNotEmpty ? keterangan : 'Pembaruan tindakan operasional');

      // 1. Simpan Catatan Tindakan
      await dio.post('/tindakan', data: {
        'id_laporan': idLaporan,
        'id_nik_pic': idNikPic.value.isNotEmpty ? idNikPic.value : null,
        'deskripsi_tindakan': deskripsiTindakan,
        'update_status': newStatus,
      });

      // 2. Perbarui Keterangan Status Laporan
      await dio.put('/laporan/$idLaporan/status', data: {
        'status': newStatus,
        'keterangan': keterangan,
        'id_nik_pic': idNikPic.value.isNotEmpty ? idNikPic.value : null,
      });

      Get.snackbar(
        'Berhasil',
        'Tindakan & status laporan $idLaporan berhasil diperbarui!',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh data
      await fetchDaftarLaporan();
    } catch (e) {
      debugPrint('Error submitTindakan: $e');
      Get.snackbar(
        'Gagal Menyimpan Tindakan',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void applyFilter(String filter) {
    activeFilter.value = filter;
    if (filter == 'Semua') {
      filteredLaporan.assignAll(listLaporan);
    } else {
      filteredLaporan.assignAll(listLaporan.where((item) {
        final st = item['status']?.toString().toLowerCase() ?? '';
        return st == filter.toLowerCase();
      }).toList());
    }
  }

  String formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      if (date is DateTime) return DateFormat('dd/MM/yyyy').format(date);
      final parsed = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return date.toString();
    }
  }
}
>>>>>>> origin/master
