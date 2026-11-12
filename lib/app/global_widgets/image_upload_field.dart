import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';

/// Field upload gambar dengan pratinjau lokal.
///
/// Gambar dipilih langsung dari galeri/kamera perangkat, lalu ditampilkan
/// sebagai pratinjau di aplikasi. Penyimpanan ke server belum tersedia, jadi
/// file hanya disimpan di memori selama aplikasi berjalan.
class ImageUploadField extends StatelessWidget {
  const ImageUploadField({
    super.key,
    required this.fileName,
    required this.bytes,
    required this.onChanged,
    this.label = 'Upload bukti',
    this.hint = 'JPG, PNG, atau WEBP',
  });

  /// Nama file yang sedang terpilih.
  final String fileName;

  /// Isi file untuk pratinjau. Bisa null bila hanya nama file yang tersimpan.
  final Uint8List? bytes;

  /// Dipanggil setelah gambar dipilih atau dihapus.
  final void Function(String fileName, Uint8List? bytes) onChanged;

  final String label;
  final String hint;

  bool get _hasFile => bytes != null || fileName.trim().isNotEmpty;

  bool get _supportsCamera {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 6),
        if (_hasFile) _buildPreview(context) else _buildEmpty(context),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Belum ada gambar dipilih',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: const TextStyle(fontSize: 11, color: AppColors.textWeak),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: () => _chooseSource(context),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
            label: const Text('Pilih gambar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                bytes!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _brokenImage(),
              ),
            )
          else
            _brokenImage(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                size: 16,
                color: AppColors.textWeak,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fileName.trim().isEmpty ? 'Gambar bukti' : fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Ganti gambar',
                onPressed: () => _chooseSource(context),
                icon: const Icon(
                  Icons.sync_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Hapus gambar',
                onPressed: () => onChanged('', null),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const Text(
            'Pratinjau lokal - belum diunggah ke server.',
            style: TextStyle(fontSize: 10.5, color: AppColors.textWeak),
          ),
        ],
      ),
    );
  }

  Widget _brokenImage() {
    return Container(
      height: 110,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Icon(
        Icons.broken_image_outlined,
        size: 30,
        color: AppColors.textWeak,
      ),
    );
  }

  Future<void> _chooseSource(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih sumber gambar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih gambar dari perangkat'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              if (_supportsCamera)
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Kamera'),
                  subtitle: const Text('Ambil gambar langsung'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;
      final data = await picked.readAsBytes();
      final name = picked.name.trim().isEmpty
          ? 'bukti_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : picked.name;
      onChanged(name, data);
    } catch (_) {
      Get.snackbar(
        'Tidak dapat membuka gambar',
        'Pemilih gambar belum tersedia di perangkat ini. Coba lewat galeri '
            'atau jalankan aplikasi di browser.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}
