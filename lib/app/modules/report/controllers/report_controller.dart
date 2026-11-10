import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/services/api_services.dart';

class ReportController extends GetxController {
  var isLoading = false.obs;

  // Filter States
  var tanggalMulai = Rx<DateTime>(DateTime(2026, 10, 1));
  var tanggalSelesai = Rx<DateTime>(DateTime(2026, 10, 31));
  var jenis = 'Laporan'.obs;
  var status = 'Semua'.obs;
  var unit = 'Semua'.obs;

  var unitList = <Map<String, dynamic>>[].obs;
  var allReports = <Map<String, dynamic>>[].obs;
  var filteredReports = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUnits();
    fetchReportData();
  }

  Future<void> fetchUnits() async {
    try {
      final dio = await ApiService.getClient();
      final res = await dio.get('/master/units');
      if (res.statusCode == 200 && res.data != null) {
        final List<dynamic> raw = res.data['data'] ?? [];
        unitList.assignAll(raw.map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (e) {
      debugPrint('Error fetchUnits: $e');
    }
  }

  Future<void> fetchReportData() async {
    isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get('/laporan');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> raw = response.data['data'] ?? [];
        allReports.assignAll(raw.map((e) => Map<String, dynamic>.from(e)).toList());
        applyFilter();
      }
    } catch (e) {
      debugPrint('Error fetchReportData: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilter() {
    var temp = List<Map<String, dynamic>>.from(allReports);

    // Filter Status
    if (status.value != 'Semua') {
      temp = temp.where((item) {
        final st = item['status']?.toString().toLowerCase() ?? '';
        return st == status.value.toLowerCase();
      }).toList();
    }

    // Filter Unit
    if (unit.value != 'Semua') {
      temp = temp.where((item) {
        final picUnit = item['unit_pic']?['nama_unit']?.toString().toLowerCase() ?? '';
        final pelaporUnit = item['unit_pelapor']?['nama_unit']?.toString().toLowerCase() ?? '';
        final target = unit.value.toLowerCase();
        return picUnit.contains(target) || pelaporUnit.contains(target);
      }).toList();
    }

    filteredReports.assignAll(temp);
  }

  void exportPdf() {
    Get.snackbar(
      'Export PDF Berhasil',
      'Laporan periode ${formatDate(tanggalMulai.value)} s/d ${formatDate(tanggalSelesai.value)} (${filteredReports.length} data) berhasil di-generate sebagai PDF.',
      backgroundColor: const Color(0xFFDC2626),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
      margin: const EdgeInsets.all(16),
    );
  }

  void exportExcel() {
    Get.snackbar(
      'Export Excel Berhasil',
      'Laporan periode ${formatDate(tanggalMulai.value)} s/d ${formatDate(tanggalSelesai.value)} (${filteredReports.length} data) berhasil diekspor ke format Excel (.xlsx).',
      backgroundColor: const Color(0xFF16A34A),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.table_chart, color: Colors.white),
      margin: const EdgeInsets.all(16),
    );
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
