import 'package:get/get.dart';

import '../../laporan/controllers/laporan_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LaporanController>()) {
      Get.put(LaporanController(), permanent: true);
    }
    Get.lazyPut<DashboardController>(
      () =>
          DashboardController(laporanController: Get.find<LaporanController>()),
    );
  }
}
