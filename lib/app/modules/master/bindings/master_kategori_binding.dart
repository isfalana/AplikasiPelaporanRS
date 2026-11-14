import 'package:get/get.dart';

import '../controllers/master_kategori_controller.dart';

class MasterKategoriBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterKategoriController>(MasterKategoriController.new);
  }
}
