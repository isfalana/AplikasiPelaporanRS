import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchDaftarLaporan();
  }

  @override
  void onClose() {
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
