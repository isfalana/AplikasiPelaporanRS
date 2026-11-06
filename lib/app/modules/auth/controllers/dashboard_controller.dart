import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_pages.dart';

class DashboardController extends GetxController {
  var unitName = ''.obs;
  
  // Variabel metrik
  var jumlahLaporan = 0.obs;
  var jumlahPesanTindakan = 0.obs;
  var jumlahTindakanSelesai = 0.obs;
  
  // List data
  var listLaporan = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchDashboardData();
  }

  void loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    unitName.value = prefs.getString('unit_name') ?? 'Unit';
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
          "kegiatan": "Perbaikan IBS & Penambahan Mesin Cuci",
          "deadline": "30 Okt 2026",
          "pic": "Umum",
          "status": "Pending"
        },
        {
          "id": "LP-002",
          "kegiatan": "Follow up MOU dengan dr Enung Sp PD EMD",
          "deadline": "15 Okt 2026",
          "pic": "SDM",
          "status": "Done"
        },
        {
          "id": "LP-003",
          "kegiatan": "Buat link untuk progres tindaklanjut IT",
          "deadline": "23 Okt 2026",
          "pic": "IT",
          "status": "On Progress"
        }
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus sesi login
    Get.offAllNamed(Routes.LOGIN); // Kembali ke halaman login
  }
}