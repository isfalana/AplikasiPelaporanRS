import 'package:get/get.dart';

import '../controllers/master_unit_controller.dart';

class MasterUnitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterUnitController>(MasterUnitController.new);
  }
}
