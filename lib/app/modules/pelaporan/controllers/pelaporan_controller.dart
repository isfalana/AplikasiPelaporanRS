import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/services/api_services.dart';
import '../../../core/theme/app_colors.dart';

class PelaporanController extends GetxController {
  var isLoading = false.obs;
  var isSubmitting = false.obs;

  // Master Data
  var kategoriList = <Map<String, dynamic>>[].obs;
  var unitList = <Map<String, dynamic>>[].obs;
  var selectedKategori = Rxn<String>();
  var selectedUnitPic = Rxn<String>();

  // Form Fields
  var tglLaporan = Rx<DateTime>(DateTime.now());
  var tglKejadian = Rx<DateTime>(DateTime.now());
  var deadline = Rx<DateTime>(DateTime.now().add(const Duration(days: 3)));
  
  final perihalController = TextEditingController();
  final keteranganController = TextEditingController();

  // User Pelapor Data
  var namaPelapor = 'TS - Marketing'.obs;
  var idNikPelapor = ''.obs;
  var idUnitPelapor = ''.obs;

  // Bukti Upload
  var uploadedFileName = ''.obs;
  var uploadedFilePath = ''.obs;

  // List Laporan
  var listLaporan = <Map<String, dynamic>>[].obs;
  var filterStatus = 'Semua'.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchMasterData();
    fetchLaporan();
  }

  @override
  void onClose() {
    perihalController.dispose();
    keteranganController.dispose();
    super.onClose();
  }

  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      idNikPelapor.value = prefs.getString('id_nik') ?? '';
      final name = prefs.getString('nama_karyawan') ?? '';
      final unit = prefs.getString('unit_name') ?? '';
      idUnitPelapor.value = prefs.getString('id_unit') ?? '';

      if (name.isNotEmpty && unit.isNotEmpty) {
        namaPelapor.value = '$name - $unit';
      } else if (name.isNotEmpty) {
        namaPelapor.value = name;
      }
    } catch (e) {
      debugPrint('Error loadUserData: $e');
    }
  }

  Future<void> fetchMasterData() async {
    try {
      final dio = await ApiService.getClient();

      // Ambil Kategori
      final resKategori = await dio.get('/master/kategoris');
      if (resKategori.statusCode == 200 && resKategori.data != null) {
        final List<dynamic> raw = resKategori.data['data'] ?? [];
        kategoriList.assignAll(raw.map((e) => Map<String, dynamic>.from(e)).toList());
        if (kategoriList.isNotEmpty && selectedKategori.value == null) {
          selectedKategori.value = kategoriList.first['id_kategori']?.toString();
        }
      }

      // Ambil Unit PIC
      final resUnit = await dio.get('/master/units');
      if (resUnit.statusCode == 200 && resUnit.data != null) {
        final List<dynamic> raw = resUnit.data['data'] ?? [];
        unitList.assignAll(raw.map((e) => Map<String, dynamic>.from(e)).toList());
        if (unitList.isNotEmpty && selectedUnitPic.value == null) {
          selectedUnitPic.value = unitList.first['id_unit']?.toString();
        }
      }
    } catch (e) {
      debugPrint('Error fetchMasterData: $e');
    }
  }

  Future<void> fetchLaporan() async {
    isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get('/laporan');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> raw = response.data['data'] ?? [];
        listLaporan.assignAll(raw.map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (e) {
      debugPrint('Error fetchLaporan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Pilih File Bukti Laporan
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        uploadedFileName.value = file.name;
        uploadedFilePath.value = file.path ?? '';
      }
    } catch (e) {
      debugPrint('Error pickFile: $e');
      uploadedFileName.value = 'bukti.jpg'; // fallback mockup
    }
  }

  /// Format Tanggal dd/MM/yyyy
  String formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      if (date is DateTime) {
        return DateFormat('dd/MM/yyyy').format(date);
      }
      final parsed = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return date.toString();
    }
  }

  /// Kirim Laporan Baru ke Backend API
  Future<void> submitLaporan() async {
    final perihal = perihalController.text.trim();
    if (perihal.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Perihal laporan wajib diisi.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedKategori.value == null) {
      Get.snackbar(
        'Peringatan',
        'Kategori laporan wajib dipilih.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedUnitPic.value == null) {
      Get.snackbar(
        'Peringatan',
        'PIC Tujuan wajib dipilih.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final dio = await ApiService.getClient();
      final body = {
        'id_unit_pelapor': idUnitPelapor.value.isNotEmpty ? idUnitPelapor.value : 'U-MARKETING',
        'id_nik_pelapor': idNikPelapor.value.isNotEmpty ? idNikPelapor.value : null,
        'id_unit_pic': selectedUnitPic.value,
        'id_kategori': selectedKategori.value,
        'perihal': perihal,
        'prioritas': 'Sedang',
        'keterangan': keteranganController.text.trim().isNotEmpty 
            ? keteranganController.text.trim() 
            : perihal,
        'tgl_kejadian': tglKejadian.value.toIso8601String(),
        'deadline': deadline.value.toIso8601String(),
      };

      final response = await dio.post('/laporan', data: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          'Laporan berhasil dikirim dan tersimpan!',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        resetForm();
        await fetchLaporan();
      } else {
        throw Exception(response.data?['message'] ?? 'Gagal membuat laporan');
      }
    } catch (e) {
      debugPrint('Error submitLaporan: $e');
      Get.snackbar(
        'Gagal Mengirim Laporan',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void resetForm() {
    perihalController.clear();
    keteranganController.clear();
    uploadedFileName.value = '';
    uploadedFilePath.value = '';
    tglKejadian.value = DateTime.now();
    deadline.value = DateTime.now().add(const Duration(days: 3));
  }
}
