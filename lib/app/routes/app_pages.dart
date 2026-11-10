<<<<<<< HEAD
// lib/app/routes/app_pages.dart
import 'package:aplikasilaporan/app/modules/auth/bindings/dashboard_binding.dart';
import 'package:aplikasilaporan/app/modules/laporan/bindings/laporan_binding.dart';
import 'package:aplikasilaporan/app/modules/tindakan/bindings/tindakan_binding.dart';
import 'package:aplikasilaporan/app/modules/auth/views/dashboard_view.dart';
import 'package:aplikasilaporan/app/modules/laporan/views/laporan_view.dart';
import 'package:aplikasilaporan/app/modules/tindakan/view/tindakan.dart';
=======
>>>>>>> origin/master
import 'package:get/get.dart';

// --- IMPOR AUTH ---
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';

// --- IMPOR DASHBOARD ---
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';

// --- IMPOR PELAPORAN ---
import '../modules/pelaporan/bindings/pelaporan_binding.dart';
import '../modules/pelaporan/views/pelaporan_view.dart';

// --- IMPOR TINDAKAN ---
import '../modules/tindakan/bindings/tindakan_binding.dart';
import '../modules/tindakan/views/tindakan_view.dart';

// --- IMPOR REPORT ---
import '../modules/report/bindings/report_binding.dart';
import '../modules/report/views/report_view.dart';

// --- IMPOR MASTER DATA ---
import '../modules/master_data/views/master_data_views.dart';
import '../modules/master_data/views/kategori_views.dart';
import '../modules/master_data/bindings/kategori_binding.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.DASHBOARD;

  static final routes = [
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
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
<<<<<<< HEAD
=======
    GetPage(
      name: Routes.PELAPORAN,
      page: () => const PelaporanView(),
      binding: PelaporanBinding(),
    ),
    GetPage(
      name: Routes.TINDAKAN,
      page: () => const TindakanView(),
      binding: TindakanBinding(),
    ),
    GetPage(
      name: Routes.REPORT,
      page: () => const ReportView(),
      binding: ReportBinding(),
    ),
    GetPage(
      name: Routes.MASTER_DATA,
      page: () => const MasterDataView(),
    ),
    GetPage(
      name: Routes.MASTER_KATEGORI,
      page: () => const KategoriView(),
      binding: KategoriBinding(),
    ),
>>>>>>> origin/master
  ];
}