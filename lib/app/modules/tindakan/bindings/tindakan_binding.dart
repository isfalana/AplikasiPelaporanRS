import 'package:get/get.dart';
<<<<<<< HEAD

import '../../laporan/controllers/laporan_controller.dart';
=======
>>>>>>> origin/master
import '../controllers/tindakan_controller.dart';

class TindakanBinding extends Bindings {
  @override
  void dependencies() {
<<<<<<< HEAD
    if (!Get.isRegistered<LaporanController>()) {
      Get.put(LaporanController(), permanent: true);
    }
    Get.lazyPut<TindakanController>(
      () => TindakanController(laporanController: Get.find<LaporanController>()),
    );
  }
}
=======
    Get.lazyPut<TindakanController>(() => TindakanController());
  }
}
>>>>>>> origin/master
