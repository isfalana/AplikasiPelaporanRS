import 'package:aplikasilaporan/app/modules/master_data/controllers/kategori_controller.dart';
import 'package:get/get.dart';

class KategoriBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KategoriController>(
      () => KategoriController(),
    );
  }
}