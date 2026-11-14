import 'package:get/get.dart';

import '../controllers/master_template_tindakan_controller.dart';

class MasterTemplateTindakanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterTemplateTindakanController>(
      MasterTemplateTindakanController.new,
    );
  }
}
