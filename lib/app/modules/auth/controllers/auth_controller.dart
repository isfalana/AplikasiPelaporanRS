import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../data/services/api_services.dart';
import '../../../routes/app_pages.dart';

class AuthController extends GetxController {
  static const demoAccounts = <String, Map<String, String>>{
    'NIK-002': {
      'password': '123456',
      'name': 'PIC Umum',
      'unit': 'UNIT-UMUM',
    },
    'NIK-004': {
      'password': '123456',
      'name': 'PIC IT',
      'unit': 'UNIT-IT',
    },
  };

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  
  var isLoading = false.obs;
  var isPasswordHidden = true.obs;

  void togglePasswordView() => isPasswordHidden.value = !isPasswordHidden.value;

  void selectDemoAccount(String nik) {
    final account = demoAccounts[nik];
    if (account == null) return;
    usernameController.text = nik;
    passwordController.text = account['password']!;
  }

  // Future<void> login() async {
  //   if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
  //     Get.snackbar('Error', 'Username dan Password tidak boleh kosong', 
  //         backgroundColor: Colors.redAccent, colorText: Colors.white);
  //     return;
  //   }

  //   isLoading.value = true;
  //   try {
  //     // 1. Bypass FCM Token untuk Web agar terhindar dari Error PromiseJsImpl
  //     String? fcmToken;
  //     try {
  //       if (kIsWeb) {
  //         fcmToken = "dummy_fcm_token_web"; 
  //       } else {
  //         fcmToken = await FirebaseMessaging.instance.getToken(); 
  //       }
  //     } catch (e) {
  //       debugPrint('FCM Error: $e');
  //       fcmToken = "dummy_token_fallback";
  //     }

  //     // 2. Eksekusi Login ke Backend Node.js
  //     Dio dio = await ApiService.getClient();
  //     final response = await dio.post('/auth/login', data: {
  //       "id_nik": usernameController.text.trim(),
  //       "password": passwordController.text.trim(),
  //       "fcm_token": fcmToken // Kirimkan token FCM ke backend untuk diupdate
  //     });

  //     // 3. Simpan Sesi jika berhasil
  //     if (response.statusCode == 200) {
  //       String token = response.data['token'];
  //       String namaUnit = response.data['data']['nama_unit'] ?? 'Unit';
  //       String idNik = response.data['data']['id_nik'];
        
  //       SharedPreferences prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('jwt_token', token);
  //       await prefs.setString('unit_name', namaUnit);
  //       await prefs.setString('id_nik', idNik);

  //       Get.snackbar('Sukses', 'Berhasil Login sebagai $namaUnit', 
  //           backgroundColor: Colors.green, colorText: Colors.white);
        
  //       Get.offAllNamed(Routes.DASHBOARD);
  //     }
  //   } on DioException catch (e) {
  //     String errorMessage = 'Gagal menghubungi server';
  //     if (e.response != null && e.response?.data != null) {
  //        errorMessage = e.response?.data['message'] ?? errorMessage;
  //     }
  //     Get.snackbar('Login Gagal', errorMessage, 
  //         backgroundColor: Colors.redAccent, colorText: Colors.white);
  //   } catch (e) {
  //     Get.snackbar('Error', 'Terjadi kesalahan sistem: $e', 
  //         backgroundColor: Colors.redAccent, colorText: Colors.white);
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<void> login() async {
    final nik = usernameController.text.trim().toUpperCase();
    final password = passwordController.text;
    if (nik.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Username dan Password tidak boleh kosong', 
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    final account = demoAccounts[nik];
    if (account == null || account['password'] != password) {
      Get.snackbar(
        'Login gagal',
        'Gunakan salah satu akun demo yang tersedia.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
<<<<<<< HEAD
      // --- SIMULASI LOGIN LOKAL (TANPA KE BACKEND) ---
      await Future.delayed(const Duration(milliseconds: 800)); // Efek loading sebentar

      // Simulasi simpan data dummy ke SharedPreferences (biar aman kalau halaman lain butuh)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', 'dummy_token_12345');
      await prefs.setString('unit_name', account['unit']!);
      await prefs.setString('id_nik', nik);
      await prefs.setString('nama_karyawan', account['name']!);

      Get.snackbar('Sukses (Mock Mode)', 'Berhasil Login sebagai ${account['name']}!',
          backgroundColor: Colors.green, colorText: Colors.white);
      
      // Langsung meluncur ke Dashboard!
      Get.offAllNamed(Routes.DASHBOARD);

=======
      // 1. Dapatkan FCM Token sesuai platform
      String? fcmToken;
      try {
        if (kIsWeb) {
          fcmToken = "web_token_${usernameController.text.trim()}";
        } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } else {
          // Windows Desktop atau OS Desktop lainnya
          fcmToken = "desktop_${defaultTargetPlatform.name}_${usernameController.text.trim()}";
        }
      } catch (e) {
        debugPrint('FCM Error: $e');
        fcmToken = "fallback_token_${DateTime.now().millisecondsSinceEpoch}";
      }

      fcmToken ??= "fallback_token_${DateTime.now().millisecondsSinceEpoch}";

      // 2. Eksekusi Login ke Backend Node.js
      Dio dio = await ApiService.getClient();
      final response = await dio.post('/auth/login', data: {
        "id_nik": usernameController.text.trim(),
        "password": passwordController.text.trim(),
        "fcm_token": fcmToken // Mengirimkan fcm_token ke backend
      });

      // 3. Simpan Sesi jika berhasil
      if (response.statusCode == 200) {
        final String token = response.data['token'];
        final Map<String, dynamic> userData = response.data['data'] ?? {};
        final String idNik = userData['id_nik']?.toString() ?? usernameController.text.trim();
        final String namaKaryawan = userData['nama_karyawan']?.toString() ?? '';
        final String namaUnit = userData['nama_unit']?.toString() ?? 'Unit';
        final String idUnit = userData['id_unit']?.toString() ?? '';
        final String idRole = userData['id_role']?.toString() ?? '';
        final String namaRole = userData['nama_role']?.toString() ?? 'User';

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('id_nik', idNik);
        await prefs.setString('nama_karyawan', namaKaryawan);
        await prefs.setString('unit_name', namaUnit);
        await prefs.setString('nama_unit', namaUnit);
        await prefs.setString('id_unit', idUnit);
        await prefs.setString('id_role', idRole);
        await prefs.setString('nama_role', namaRole);
        await prefs.setString('fcm_token', fcmToken);

        debugPrint('====================================');
        debugPrint('✅ LOGIN BERHASIL');
        debugPrint('🔑 JWT Token: $token');
        debugPrint('📲 FCM Token: $fcmToken');
        debugPrint('👤 User: $namaKaryawan ($idNik) - Unit: $namaUnit');
        debugPrint('====================================');

        Get.snackbar(
          'Sukses',
          'Berhasil Login sebagai $namaUnit ($namaKaryawan)',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        Get.offAllNamed(Routes.DASHBOARD);
      }
    } on DioException catch (e) {
      String errorMessage = 'Gagal menghubungi server';
      if (e.response != null && e.response?.data != null) {
         errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      Get.snackbar('Login Gagal', errorMessage, 
          backgroundColor: Colors.redAccent, colorText: Colors.white);
>>>>>>> origin/master
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan sistem: $e', 
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
  
  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}