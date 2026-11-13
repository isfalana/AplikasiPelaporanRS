import 'package:get/get.dart';

import '../controllers/master_role_controller.dart';

class MasterRoleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterRoleController>(MasterRoleController.new);
  }
}
