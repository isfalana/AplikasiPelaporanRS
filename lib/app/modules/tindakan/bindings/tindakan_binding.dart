import 'package:get/get.dart';

import '../../laporan/controllers/laporan_controller.dart';
import '../controllers/tindakan_controller.dart';

class TindakanBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LaporanController>()) {
      Get.put(LaporanController(), permanent: true);
    }
    Get.lazyPut<TindakanController>(
      () => TindakanController(laporanController: Get.find<LaporanController>()),
    );
  }
}