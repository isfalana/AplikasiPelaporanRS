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
  static const INITIAL = Routes.LOGIN;

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
    ),
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
  ];
}