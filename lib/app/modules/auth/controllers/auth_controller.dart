import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/api_services.dart';
import '../../../data/services/master_data_store.dart';
// [MODIFIKASI] Import NotificationService
import '../../../data/services/notification_service.dart';
import '../../laporan/controllers/laporan_controller.dart';
import '../../../routes/app_pages.dart';

class AuthController extends GetxController {
  static const demoAccounts = <String, Map<String, String>>{
    'NIK-001': {'password': '123456', 'name': 'Admin IT', 'unit': 'U-IT'},
    'NIK-002': {'password': '123456', 'name': 'Siti Aminah (Pelapor)', 'unit': 'U-PENDAFTARAN'},
    'NIK-003': {'password': '123456', 'name': 'Budi Teknisi (PIC)', 'unit': 'U-UMUM'},
    'NIK-004': {'password': '123456', 'name': 'Andi IT (PIC)', 'unit': 'U-IT'},
  };

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  // [MODIFIKASI] FocusNode untuk navigasi keyboard Enter dari NIK ke Kata Sandi
  final passwordFocusNode = FocusNode();

  var isLoading = false.obs;
  var isPasswordHidden = true.obs;

  void togglePasswordView() => isPasswordHidden.value = !isPasswordHidden.value;

  void selectDemoAccount(String nik) {
    final account = demoAccounts[nik];
    if (account == null) return;
    usernameController.text = nik;
    passwordController.text = account['password']!;
  }

  Future<void> login() async {
    final nik = usernameController.text.trim().toUpperCase();
    final password = passwordController.text;
    if (nik.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'NIK dan Password tidak boleh kosong',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.post('/auth/login', data: {
        'id_nik': nik,
        'password': password,
      });

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token']?.toString() ?? '';
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final idNik = data['id_nik']?.toString() ?? nik;
        final namaKaryawan = data['nama_karyawan']?.toString() ?? '';
        final idUnit = data['id_unit']?.toString() ?? '';
        final namaUnit = data['nama_unit']?.toString() ?? 'Unit';
        final idRole = data['id_role']?.toString() ?? '';
        final namaRole = data['nama_role']?.toString() ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('id_nik', idNik);
        await prefs.setString('nama_karyawan', namaKaryawan);
        await prefs.setString('id_unit', idUnit);
        await prefs.setString('unit_name', namaUnit);
        await prefs.setString('id_role', idRole);
        await prefs.setString('nama_role', namaRole);

        // [MODIFIKASI] Ambil data master terbaru dari backend
        final store = MasterDataStore.ensure();
        await store.fetchFromBackend();

        // [MODIFIKASI] Muat data laporan dan prioritas dari backend segera setelah token JWT tersimpan
        if (Get.isRegistered<LaporanController>()) {
          final lapCtrl = Get.find<LaporanController>();
          await lapCtrl.fetchLaporanData();
          await lapCtrl.fetchPrioritas();
        }

        // [MODIFIKASI] Ambil notifikasi terbaru dan minta izin notifikasi sistem untuk akun yang login
        if (Get.isRegistered<NotificationService>()) {
          final notif = Get.find<NotificationService>();
          notif.requestPermission();
          await notif.fetchNotifications();
          await notif.init();
        }

        Get.snackbar(
          'Login Berhasil',
          'Selamat datang, $namaKaryawan ($namaUnit)',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.offAllNamed(Routes.DASHBOARD);
      } else {
        Get.snackbar(
          'Login Gagal',
          response.data?['message'] ?? 'Terjadi kesalahan saat login',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          'Gagal menghubungi server: ${e.message}';
      Get.snackbar(
        'Login Gagal',
        msg.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan sistem: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // [MODIFIKASI] Reset / Lupa kata sandi ke backend
  Future<bool> resetPassword({
    required String nik,
    required String newPassword,
  }) async {
    try {
      final dio = await ApiService.getClient();
      final response = await dio.post('/auth/reset-password', data: {
        'id_nik': nik.trim().toUpperCase(),
        'new_password': newPassword.trim(),
      });
      if (response.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          response.data?['message'] ?? 'Kata sandi berhasil diubah.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mereset kata sandi: ${e.message}';
      Get.snackbar(
        'Gagal',
        msg.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.onClose();
  }
}
