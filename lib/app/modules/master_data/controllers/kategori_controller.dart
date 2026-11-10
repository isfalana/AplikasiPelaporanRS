
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../data/services/api_services.dart';

class KategoriController extends GetxController {
  // Menampung data kategori dari API
  final RxList<dynamic> listKategori = <dynamic>[].obs;

  var isLoading = true.obs;

  final idController = TextEditingController();
  final namaController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchKategori();
  }

  Future<void> fetchKategori() async {
    isLoading.value = true;

    try {
      Dio dio = await ApiService.getClient();
      final response = await dio.get('/kategori');

      if (response.statusCode == 200) {
        listKategori.assignAll(
          List<dynamic>.from(response.data['data']),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data kategori');
      debugPrint('Error fetchKategori: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> simpanKategori(bool isEdit) async {
    if (idController.text.isEmpty || namaController.text.isEmpty) {
      Get.snackbar('Validasi', 'Semua kolom wajib diisi');
      return;
    }

    try {
      Dio dio = await ApiService.getClient();

      final data = {
        "id_kategori": idController.text.trim(),
        "jenis_kategori": namaController.text.trim(),
      };

      if (isEdit) {
        await dio.put(
          '/kategori/${idController.text.trim()}',
          data: data,
        );

        Get.snackbar('Sukses', 'Kategori diperbarui');
      } else {
        await dio.post('/kategori', data: data);

        Get.snackbar('Sukses', 'Kategori ditambahkan');
      }

      Get.back();
      fetchKategori();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan data');
      debugPrint('Error simpanKategori: $e');
    }
  }

  Future<void> hapusKategori(String id) async {
    try {
      Dio dio = await ApiService.getClient();

      await dio.delete('/kategori/$id');

      Get.snackbar(
        'Sukses',
        'Kategori dihapus',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      fetchKategori();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus data');
      debugPrint('Error hapusKategori: $e');
    }
  }

  void bersihkanForm() {
    idController.clear();
    namaController.clear();
  }

  @override
  void onClose() {
    idController.dispose();
    namaController.dispose();
    super.onClose();
  }
}
