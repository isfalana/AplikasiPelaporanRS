import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/kategori_controller.dart';
import '../../../core/theme/app_colors.dart';

class KategoriView extends GetView<KategoriController> {
  const KategoriView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Master Kategori', style: TextStyle(color: AppColors.textStrong)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textStrong),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          controller.bersihkanForm();
          _tampilDialogForm(context, isEdit: false);
        },
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.listKategori.isEmpty) {
          return const Center(child: Text('Belum ada data kategori'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surface),
              columns: const [
                DataColumn(label: Text('ID Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Jenis Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: controller.listKategori.map((kategori) {
                return DataRow(
                  cells: [
                    DataCell(Text(kategori['id_kategori'].toString())),
                    DataCell(Text(kategori['jenis_kategori'].toString())),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.warning),
                          onPressed: () {
                            controller.idController.text = kategori['id_kategori'];
                            controller.namaController.text = kategori['jenis_kategori'];
                            _tampilDialogForm(context, isEdit: true);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          onPressed: () => _konfirmasiHapus(kategori['id_kategori']),
                        ),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }

  void _tampilDialogForm(BuildContext context, {required bool isEdit}) {
    Get.defaultDialog(
      title: isEdit ? 'Edit Kategori' : 'Tambah Kategori',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller.idController,
            enabled: !isEdit, // ID tidak bisa diedit setelah dibuat
            decoration: const InputDecoration(labelText: 'ID Kategori (Contoh: KAT-01)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.namaController,
            decoration: const InputDecoration(labelText: 'Jenis Kategori', border: OutlineInputBorder()),
          ),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        onPressed: () => controller.simpanKategori(isEdit),
        child: const Text('Simpan', style: TextStyle(color: AppColors.white)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal', style: TextStyle(color: AppColors.textWeak)),
      ),
    );
  }

  void _konfirmasiHapus(String id) {
    Get.defaultDialog(
      title: 'Hapus Data',
      middleText: 'Yakin ingin menghapus kategori $id? Data yang berelasi mungkin akan terpengaruh.',
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        onPressed: () {
          Get.back();
          controller.hapusKategori(id);
        },
        child: const Text('Hapus', style: TextStyle(color: AppColors.white)),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
    );
  }
}