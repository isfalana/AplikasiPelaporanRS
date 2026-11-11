// lib/app/routes/app_pages.dart
import 'package:aplikasilaporan/app/modules/auth/bindings/dashboard_binding.dart';
import 'package:aplikasilaporan/app/modules/laporan/bindings/laporan_binding.dart';
import 'package:aplikasilaporan/app/modules/tindakan/bindings/tindakan_binding.dart';
import 'package:aplikasilaporan/app/modules/auth/views/dashboard_view.dart';
import 'package:aplikasilaporan/app/modules/laporan/views/laporan_view.dart';
import 'package:aplikasilaporan/app/modules/tindakan/view/tindakan.dart';
import 'package:get/get.dart';

import '../modules/report/bindings/report_binding.dart';
import '../modules/report/views/report_view.dart';
// Import nanti jika module sudah dibuat
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
// import '../modules/dashboard/views/dashboard_view.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.DASHBOARD;

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
      transition: Transition.noTransition,
    ),

    GetPage(
      name: Routes.LAPORAN,
      page: () => const LaporanView(),
      binding: LaporanBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.TINDAKAN,
      page: () => const TindakanView(),
      binding: TindakanBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.REPORT,
      page: () => const ReportView(),
      binding: ReportBinding(),
      transition: Transition.noTransition,
    ),
  ];
}
