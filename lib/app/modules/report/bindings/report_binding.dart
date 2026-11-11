import 'package:get/get.dart';

import '../../laporan/controllers/laporan_controller.dart';
import '../controllers/report_controller.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LaporanController>()) {
      Get.put(LaporanController(), permanent: true);
    }
    Get.lazyPut<ReportController>(
      () => ReportController(laporanController: Get.find<LaporanController>()),
    );
  }
}
