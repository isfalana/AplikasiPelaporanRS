import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes/app_pages.dart';

// [MODIFIKASI] Middleware otentikasi rute: Menjaga semua menu agar pengguna yang belum login
// tidak dapat loncat atau mengakses menu apapun sebelum berhasil login
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Periksa apakah pengguna memiliki token JWT yang tersimpan
    SharedPreferences? prefs;
    if (Get.isRegistered<SharedPreferences>()) {
      prefs = Get.find<SharedPreferences>();
    }

    final token = prefs?.getString('jwt_token');
    final isLoggedIn = token != null && token.trim().isNotEmpty;

    // Jika belum login dan mencoba membuka rute selain login, paksa arahkan ke halaman login
    if (!isLoggedIn) {
      if (route != Routes.LOGIN) {
        return const RouteSettings(name: Routes.LOGIN);
      }
    } else {
      // Jika sudah login dan mencoba membuka rute login lagi, arahkan ke dashboard
      if (route == Routes.LOGIN) {
        return const RouteSettings(name: Routes.DASHBOARD);
      }
    }

    return null;
  }
}
