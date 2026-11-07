import 'package:get/get.dart';

// --- IMPOR AUTH ---
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';

// --- IMPOR DASHBOARD ---
// Perhatikan perbaikan nama foldernya di sini
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';

// --- IMPOR MASTER DATA ---
import '../modules/master_data/views/master_data_views.dart';
import '../modules/master_data/views/kategori_views.dart';
import '../modules/master_data/bindings/kategori_binding.dart'; 
// (Pastikan file kategori_binding.dart sudah Anda buat, lihat Langkah 2 di bawah)

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