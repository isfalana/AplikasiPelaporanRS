// lib/app/routes/app_pages.dart
import 'package:aplikasilaporan/app/modules/auth/bindings/dashboard_binding.dart';
import 'package:aplikasilaporan/app/modules/auth/views/dashboard_view.dart';
import 'package:get/get.dart';
// Import nanti jika module sudah dibuat
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
// import '../modules/dashboard/views/dashboard_view.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    // Kita komentari dulu sampai view-nya dibuat
    
    // GetPage(
    //   name: Routes.LOGIN,
    //   page: () => const LoginView(),
    // ),
    GetPage(
      name: Routes.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    
  ];
}