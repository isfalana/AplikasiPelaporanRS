import 'package:get/get.dart';

import '../controllers/master_karyawan_controller.dart';

class MasterKaryawanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterKaryawanController>(MasterKaryawanController.new);
  }
}
