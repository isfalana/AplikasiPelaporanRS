import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../data/services/api_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_pages.dart';

class DashboardController extends GetxController {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // State untuk mengontrol Sidebar Desktop: DEFAULT TERBUKA (true)
  var isSidebarExpanded = true.obs;

  void toggleSidebar() {
    isSidebarExpanded.value = !isSidebarExpanded.value;
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  // Observable Profil Pengguna
  var idNik = ''.obs;
  var namaKaryawan = ''.obs;
  var unitName = ''.obs;
  var idUnit = ''.obs;
  var roleName = ''.obs;
  var idRole = ''.obs;

  // Inisial nama profil (contoh: "AI" untuk "Admin IT")
  String get userInitials {
    final name = namaKaryawan.value.trim().isNotEmpty
        ? namaKaryawan.value.trim()
        : unitName.value.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  // Observable Metrik Dashboard
  var jumlahLaporan = 0.obs;
  var jumlahPesanTindakan = 0.obs;
  var jumlahTindakanSelesai = 0.obs;
  var jumlahTindakanOnProgress = 0.obs;

  // Observable Data Laporan
  var listLaporan = <Map<String, dynamic>>[].obs;
  var listPrioritas = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var isMasterMenuExpanded = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchDashboardData();
  }

  void toggleMasterMenu() {
    isMasterMenuExpanded.value = !isMasterMenuExpanded.value;
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    idNik.value = prefs.getString('id_nik') ?? '';
    namaKaryawan.value = prefs.getString('nama_karyawan') ?? '';
    unitName.value = prefs.getString('nama_unit') ?? prefs.getString('unit_name') ?? 'Unit';
    idUnit.value = prefs.getString('id_unit') ?? '';
    roleName.value = prefs.getString('nama_role') ?? 'User';
    idRole.value = prefs.getString('id_role') ?? '';
  }

  // Mengambil data laporan real dari Backend Database PostgreSQL
  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get('/laporan');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = response.data['data'] ?? [];
        final List<Map<String, dynamic>> reports =
            rawList.map((e) => Map<String, dynamic>.from(e)).toList();

        listLaporan.assignAll(reports);

        // 1. Total Laporan Terkirim
        jumlahLaporan.value = reports.length;

        // 2. Pesan Tindakan (Status 'Pending' atau menunggu tindakan)
        jumlahPesanTindakan.value = reports.where((r) {
          final s = (r['status'] ?? '').toString().toLowerCase();
          return s == 'pending' || s == 'menunggu';
        }).length;

        // 3. Tindakan Selesai (Status 'Done' atau 'Selesai')
        jumlahTindakanSelesai.value = reports.where((r) {
          final s = (r['status'] ?? '').toString().toLowerCase();
          return s == 'done' || s == 'selesai';
        }).length;

        // 4. Tindakan On Progress
        jumlahTindakanOnProgress.value = reports.where((r) {
          final s = (r['status'] ?? '').toString().toLowerCase();
          return s == 'on progress' || s == 'on-progress' || s == 'proses';
        }).length;

        // 5. List Prioritas: ambil laporan dengan prioritas Tinggi terlebih dahulu
        final prioritasTinggi = reports.where((r) {
          final p = (r['prioritas'] ?? '').toString().toLowerCase();
          return p == 'tinggi' || p == 'urgent';
        }).toList();

        if (prioritasTinggi.isNotEmpty) {
          listPrioritas.assignAll(prioritasTinggi);
        } else {
          listPrioritas.assignAll(reports.take(5).toList());
        }
      }
    } on DioException catch (e) {
      debugPrint('Error fetchDashboardData DioException: ${e.message}');
      Get.snackbar(
        'Info Koneksi',
        'Tidak dapat terhubung ke server backend: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error fetchDashboardData: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Format tanggal rapi dd/MM/yyyy
  String formatDate(dynamic dateVal) {
    if (dateVal == null) return '-';
    try {
      final d = DateTime.parse(dateVal.toString());
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = d.year.toString();
      return '$day/$month/$year';
    } catch (_) {
      return dateVal.toString();
    }
  }

  // Dialog Edit / Lihat Detail Profil
  void showEditProfileDialog(BuildContext context) {
    final nikCtrl = TextEditingController(text: idNik.value);
    final namaCtrl = TextEditingController(text: namaKaryawan.value);
    final unitCtrl = TextEditingController(text: unitName.value);
    final roleCtrl = TextEditingController(text: roleName.value);

    Get.defaultDialog(
      title: 'Profil Pengguna',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary,
              child: Text(
                userInitials,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              namaKaryawan.value.isNotEmpty ? namaKaryawan.value : 'Nama Karyawan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              unitName.value,
              style: const TextStyle(fontSize: 13, color: AppColors.textWeak),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nikCtrl,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'NIK / Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: namaCtrl,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitCtrl,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Unit Kerja',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleCtrl,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Peran / Hak Akses',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security_outlined),
              ),
            ),
          ],
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        ),
        onPressed: () => Get.back(),
        child: const Text('Tutup', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Dialog Konfirmasi Logout
  void confirmLogout() {
    Get.defaultDialog(
      title: 'Konfirmasi Keluar',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText: 'Apakah Anda yakin ingin keluar dari akun?',
      textConfirm: 'Keluar',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      cancelTextColor: AppColors.textWeak,
      onConfirm: () {
        Get.back();
        logout();
      },
    );
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus sesi login
    Get.offAllNamed(Routes.LOGIN); // Kembali ke halaman login
  }
}