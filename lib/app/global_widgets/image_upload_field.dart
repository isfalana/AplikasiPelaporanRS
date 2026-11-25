import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';
import 'bukti_preview.dart';
import 'camera/web_camera_helper.dart';
import 'compression/file_compress_helper.dart';

/// Field upload bukti dengan pratinjau lokal.
///
/// Mendukung gambar (galeri/kamera) maupun dokumen (PDF, DOC, XLS, dll).
/// File dipilih langsung dari perangkat, lalu ditampilkan sebagai pratinjau
/// kecil yang bisa diklik untuk dilihat lebih besar. Penyimpanan ke server
/// belum tersedia, jadi file hanya disimpan di memori selama aplikasi jalan.
class ImageUploadField extends StatelessWidget {
  const ImageUploadField({
    super.key,
    required this.fileName,
    required this.bytes,
    required this.onChanged,
    this.imageUrl,
    this.idEvidence,
    this.label = 'Upload bukti',
    this.hint = 'Gambar (JPG, PNG, WEBP) atau dokumen (PDF, DOC, XLS) · Maks. 5 MB',
  });

  /// [MODIFIKASI] Batas maksimal ukuran file (5 MB) untuk mencegah kelebihan beban server
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  static const String maxFileSizeText = '5 MB';

  /// Nama file yang sedang terpilih.
  final String fileName;

  /// Isi file untuk pratinjau. Bisa null bila hanya nama file yang tersimpan.
  final Uint8List? bytes;

  // [MODIFIKASI] URL gambar tersimpan di backend (jika ada)
  final String? imageUrl;
  final String? idEvidence;

  /// Dipanggil setelah file dipilih atau dihapus.
  final void Function(String fileName, Uint8List? bytes) onChanged;

  final String label;
  final String hint;

  bool get _hasFile => bytes != null || fileName.trim().isNotEmpty || (imageUrl != null && imageUrl!.trim().isNotEmpty);

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Pada layar sempit tombol turun ke baris sendiri agar tidak
          // meluber ke kanan. Di layar lebar tombol tetap di samping info.
          final isNarrow = constraints.maxWidth < 260;
          final info = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.upload_file_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Belum ada file dipilih',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textWeak,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final button = OutlinedButton.icon(
            onPressed: () => _chooseSource(context),
            icon: const Icon(Icons.attach_file_rounded, size: 17),
            label: const Text('Pilih file'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [info, const SizedBox(height: 12), button],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // [MODIFIKASI] Teruskan imageUrl dan idEvidence ke BuktiPreviewTile agar file dari server dapat ditampilkan & diunduh
                child: BuktiPreviewTile(
                  fileName: fileName,
                  bytes: bytes,
                  imageUrl: imageUrl,
                  idEvidence: idEvidence,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Ganti file',
                onPressed: () => _chooseSource(context),
                icon: const Icon(
                  Icons.sync_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Hapus file',
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
          const SizedBox(height: 6),
          // [MODIFIKASI] Berikan keterangan yang tepat bila file sudah tersimpan di server atau baru dipilih lokal
          Text(
            (imageUrl != null && imageUrl!.trim().isNotEmpty && (bytes == null || bytes!.isEmpty))
                ? 'File tersimpan di server · Siap dilihat & diunduh'
                : 'Pratinjau lokal · ${buktiFileSize(bytes)} (Maks. $maxFileSizeText) - klik Simpan untuk mengunggah.',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textWeak),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseSource(BuildContext context) async {
    final source = await showModalBottomSheet<String>(
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
                    'Pilih sumber bukti',
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
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              if (_supportsCamera)
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Kamera'),
                  subtitle: const Text('Ambil gambar langsung'),
                  onTap: () => Navigator.of(context).pop('camera'),
                ),
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Dokumen'),
                subtitle: const Text('PDF, DOC, XLS, dan lainnya'),
                onTap: () => Navigator.of(context).pop('document'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    if (source == 'gallery') {
      await _pickImage(ImageSource.gallery);
    } else if (source == 'camera') {
      await _pickImage(ImageSource.camera);
    } else if (source == 'document') {
      await _pickDocument();
    }
  }

  /// Ekstensi dokumen yang boleh dipilih pada field bukti.
  static const List<String> _allowedExtensions = <String>[
    'pdf',
    'doc',
    'docx',
    'rtf',
    'odt',
    'xls',
    'xlsx',
    'csv',
    'ods',
    'ppt',
    'pptx',
    'odp',
    'txt',
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'zip',
    'rar',
    '7z',
    'mp4',
    'mp3',
  ];

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final data = file.bytes;
      if (data == null) {
        Get.snackbar(
          'Perhatian',
          'Isi file tidak dapat dibaca. Coba pilih file lain.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: AppColors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      var chosenName = file.name.trim().isEmpty
          ? 'bukti_${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? 'file'}'
          : file.name;
      var chosenBytes = data;

      // [MODIFIKASI] Kompresi otomatis untuk gambar atau foto dokumen yang diunggah
      if (FileCompressHelper.isImageFile(chosenName)) {
        final compressed = await FileCompressHelper.compressIfImage(
          fileName: chosenName,
          bytes: chosenBytes,
        );
        if (compressed.wasCompressed) {
          chosenName = compressed.fileName;
          chosenBytes = compressed.bytes;
          Get.snackbar(
            'Kompresi Otomatis Berhasil',
            'Ukuran file berhasil dioptimalkan dari ${compressed.formattedOriginalSize} menjadi ${compressed.formattedCompressedSize} (hemat ${compressed.savingsPercentage}%).',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            icon: const Icon(Icons.compress_rounded, color: Colors.white),
            duration: const Duration(seconds: 4),
          );
        }
      }

      // Validasi batas ukuran file dokumen (maks. 5 MB) setelah kompresi
      if (chosenBytes.lengthInBytes > maxFileSizeBytes) {
        Get.snackbar(
          'Ukuran File Terlalu Besar',
          'Dokumen "$chosenName" berukuran ${buktiFileSize(chosenBytes)}, melebihi batas maksimal $maxFileSizeText. Silakan sesuaikan atau pilih dokumen lain.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: AppColors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.white),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      onChanged(chosenName, chosenBytes);
    } catch (_) {
      Get.snackbar(
        'Tidak dapat membuka file',
        'Pemilih file belum tersedia di perangkat ini. Coba lewat aplikasi '
            'pendukung atau jalankan aplikasi di browser.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // [MODIFIKASI] Buka kamera perangkat langsung via live viewfinder WebRTC jika di platform Web
      if (kIsWeb && source == ImageSource.camera) {
        final camResult = await WebCameraHelper.openCamera();
        if (camResult == null) return;
        var name = camResult['name']?.toString() ??
            'foto_kamera_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final dataUrl = camResult['dataUrl']?.toString() ?? '';
        if (dataUrl.isEmpty) return;
        final base64Str =
            dataUrl.contains(',') ? dataUrl.split(',').last : dataUrl;
        var data = base64Decode(base64Str);

        // [MODIFIKASI] Kompresi otomatis hasil kamera
        final compressed = await FileCompressHelper.compressIfImage(
          fileName: name,
          bytes: data,
        );
        if (compressed.wasCompressed) {
          name = compressed.fileName;
          data = compressed.bytes;
        }

        // Validasi batas ukuran file foto (maks. 5 MB) sebelum diproses
        if (data.lengthInBytes > maxFileSizeBytes) {
          Get.snackbar(
            'Ukuran Foto Terlalu Besar',
            'Foto berukuran ${buktiFileSize(data)}, melebihi batas maksimal $maxFileSizeText. Silakan sesuaikan atau kompres foto sebelum diunggah.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: AppColors.white,
            margin: const EdgeInsets.all(16),
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.white),
            duration: const Duration(seconds: 4),
          );
          return;
        }

        onChanged(name, data);
        return;
      }

      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;
      var data = await picked.readAsBytes();
      var name = picked.name.trim().isEmpty
          ? 'bukti_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : picked.name;

      // [MODIFIKASI] Kompresi otomatis untuk foto galeri
      final compressed = await FileCompressHelper.compressIfImage(
        fileName: name,
        bytes: data,
      );
      if (compressed.wasCompressed) {
        name = compressed.fileName;
        data = compressed.bytes;
        Get.snackbar(
          'Kompresi Otomatis Berhasil',
          'Ukuran foto berhasil dioptimalkan dari ${compressed.formattedOriginalSize} menjadi ${compressed.formattedCompressedSize} (hemat ${compressed.savingsPercentage}%).',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.compress_rounded, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }

      // Validasi batas ukuran file foto (maks. 5 MB) sebelum diproses
      if (data.lengthInBytes > maxFileSizeBytes) {
        Get.snackbar(
          'Ukuran Foto Terlalu Besar',
          'Foto "$name" berukuran ${buktiFileSize(data)}, melebihi batas maksimal $maxFileSizeText. Silakan sesuaikan atau kompres foto sebelum diunggah.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: AppColors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.white),
          duration: const Duration(seconds: 4),
        );
        return;
      }

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
