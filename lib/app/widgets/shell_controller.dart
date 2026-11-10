import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../data/services/api_services.dart';
import '../routes/app_pages.dart';

class ShellController extends GetxController {
  // State Sidebar Desktop (Default Terbuka / Expanded = 250px, Menciut = 72px)
  var isSidebarExpanded = true.obs;
  var isMasterMenuExpanded = false.obs;

  // Scaffold Key untuk mengontrol Drawer Mobile secara programatis
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Data Profil Pengguna
  var idNik = ''.obs;
  var namaKaryawan = ''.obs;
  var unitName = ''.obs;
  var roleName = ''.obs;
  var idRole = ''.obs;
  var idUnit = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  /// Memuat data profil dari SharedPreferences
  Future<void> loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      idNik.value = prefs.getString('id_nik') ?? '';
      namaKaryawan.value = prefs.getString('nama_karyawan') ?? '';
      unitName.value = prefs.getString('unit_name') ?? 'Unit Permata';
      roleName.value = prefs.getString('nama_role') ?? 'Staff';
      idRole.value = prefs.getString('id_role') ?? '';
      idUnit.value = prefs.getString('id_unit') ?? '';
    } catch (e) {
      debugPrint('Error memuat profil pengguna: $e');
    }
  }

  /// Hitung inisial nama pengguna (misal "Asep Irawan" -> "AI", "Super Admin" -> "SA")
  String get userInitials {
    final name = namaKaryawan.value.trim();
    if (name.isEmpty) {
      if (idNik.value.isNotEmpty) {
        return idNik.value.length >= 2 ? idNik.value.substring(0, 2).toUpperCase() : idNik.value.toUpperCase();
      }
      return 'RS';
    }

    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].length >= 2 ? parts[0].substring(0, 2).toUpperCase() : parts[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Toggle menciutkan / melebarkan Sidebar Desktop
  void toggleSidebar() {
    isSidebarExpanded.value = !isSidebarExpanded.value;
  }

  /// Toggle submenu Master Data
  void toggleMasterMenu() {
    isMasterMenuExpanded.value = !isMasterMenuExpanded.value;
  }

  /// Membuka Drawer Mobile
  void openDrawer() {
    if (scaffoldKey.currentState != null) {
      scaffoldKey.currentState!.openDrawer();
    }
  }

  /// Navigasi rute dengan penanganan state bersih
  void navigateTo(String route) {
    if (Get.currentRoute == route) {
      if (scaffoldKey.currentState != null && scaffoldKey.currentState!.isDrawerOpen) {
        Get.back();
      }
      return;
    }

    if (scaffoldKey.currentState != null && scaffoldKey.currentState!.isDrawerOpen) {
      Get.back();
    }

    Get.offNamed(route);
  }

  /// Dialog Konfirmasi Logout
  void confirmLogout() {
    Get.defaultDialog(
      title: 'Konfirmasi Logout',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText: 'Apakah Anda yakin ingin keluar dari sistem Lapor Permata?',
      middleTextStyle: const TextStyle(fontSize: 14, color: Colors.black87),
      textConfirm: 'Keluar',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      cancelTextColor: Colors.black54,
      radius: 12,
      onConfirm: () async {
        Get.back(); // Tutup dialog
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Get.offAllNamed(Routes.LOGIN);
        Get.snackbar(
          'Logout Berhasil',
          'Anda telah berhasil keluar dari sistem.',
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      },
    );
  }

  /// Dialog Edit Profile
  void showEditProfileDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: namaKaryawan.value);
    final unitCtrl = TextEditingController(text: unitName.value);
    final roleCtrl = TextEditingController(text: roleName.value);
    final passCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profil Pengguna',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: 24),
              const SizedBox(height: 8),

              // NIK (Read-only)
              TextField(
                controller: TextEditingController(text: idNik.value),
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'ID / NIK',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Nama Karyawan
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Karyawan',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Unit (Read-only)
              TextField(
                controller: unitCtrl,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Unit / Bagian',
                  prefixIcon: const Icon(Icons.apartment_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Role (Read-only)
              TextField(
                controller: roleCtrl,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Hak Akses / Role',
                  prefixIcon: const Icon(Icons.shield_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Ganti Password Baru
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password Baru (opsional)',
                  hintText: 'Kosongkan jika tidak ingin mengubah',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Simpan & Batal
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isNotEmpty) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('nama_karyawan', nameCtrl.text.trim());
                        namaKaryawan.value = nameCtrl.text.trim();
                      }
                      Get.back();
                      Get.snackbar(
                        'Profil Diperbarui',
                        'Perubahan profil berhasil disimpan.',
                        backgroundColor: AppColors.primary,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(16),
                      );
                    },
                    child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
