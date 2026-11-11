import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../laporan/controllers/laporan_controller.dart';
import '../../../routes/app_pages.dart';

class DashboardController extends GetxController {
  var unitName = ''.obs;
  var employeeName = ''.obs;
  var isSidebarCollapsed = false.obs;
  var isMasterExpanded = true.obs;

  // Variabel metrik
  var jumlahLaporan = 0.obs;
  var jumlahPesanTindakan = 0.obs;
  var jumlahTindakanSelesai = 0.obs;

  // List data
  var listLaporan = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  // Filter aktif pada card "Prioritas tindak lanjut".
  var priorityFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchDashboardData();
  }

  void loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    unitName.value = prefs.getString('unit_name') ?? 'Unit';
    employeeName.value = _readEmployeeName(prefs);
  }

  String _readEmployeeName(SharedPreferences prefs) {
    for (final key in [
      'nama_karyawan',
      'nama_pegawai',
      'nama_lengkap',
      'employee_name',
      'full_name',
    ]) {
      final name = prefs.getString(key)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return prefs.getString('id_nik') ?? 'Pengguna';
  }

  void fetchDashboardData() async {
    isLoading.value = true;
    try {
      // Simulasi delay ambil data dari API (1.5 detik)
      await Future.delayed(const Duration(milliseconds: 1500));

      // Mock Data
      jumlahLaporan.value = 12;
      jumlahPesanTindakan.value = 4;
      jumlahTindakanSelesai.value = 8;

      listLaporan.assignAll([
        {
          "id": "LP-001",
          "tanggal": "8 Nov 2026",
          "deadline": "12 Nov 2026",
          "perihal": "Perbaikan IBS & Penambahan Mesin Cuci",
          "pic": "Umum",
          "prioritas": "High",
          "lastUpdateBy": "Admin Unit",
          "status": "Open",
        },
        {
          "id": "LP-002",
          "tanggal": "7 Nov 2026",
          "deadline": "15 Nov 2026",
          "perihal": "Follow up MOU dengan dr Enung Sp PD EMD",
          "pic": "SDM",
          "prioritas": "Mid",
          "lastUpdateBy": "Kepala SDM",
          "status": "Done",
        },
        {
          "id": "LP-003",
          "tanggal": "9 Nov 2026",
          "deadline": "11 Nov 2026",
          "perihal": "Buat link untuk progres tindaklanjut IT",
          "pic": "IT",
          "prioritas": "Mid",
          "lastUpdateBy": "Staff IT",
          "status": "On Progress",
        },
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus sesi login
    if (Get.isRegistered<LaporanController>()) {
      Get.delete<LaporanController>(force: true);
    }
    Get.offAllNamed(Routes.LOGIN); // Kembali ke halaman login
  }
}
