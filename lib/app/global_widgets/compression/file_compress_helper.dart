import 'package:flutter/foundation.dart';

import 'file_compress_stub.dart'
    if (dart.library.html) 'file_compress_web.dart';

String formatBytesSize(int size) {
  if (size < 1024) return '$size B';
  if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class CompressedFileResult {
  final String fileName;
  final Uint8List bytes;
  final int originalSize;
  final int compressedSize;
  final bool wasCompressed;

  const CompressedFileResult({
    required this.fileName,
    required this.bytes,
    required this.originalSize,
    required this.compressedSize,
    required this.wasCompressed,
  });

  String get formattedOriginalSize => formatBytesSize(originalSize);
  String get formattedCompressedSize => formatBytesSize(compressedSize);

  /// Persentase penghematan ukuran file
  int get savingsPercentage {
    if (originalSize <= 0 || compressedSize >= originalSize) return 0;
    return (((originalSize - compressedSize) / originalSize) * 100).round();
  }
}

// [MODIFIKASI] Helper kompresi dokumen & bukti otomatis lintas platform
abstract class FileCompressHelper {
  /// Ekstensi gambar yang didukung untuk kompresi otomatis
  static const imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'};

  static bool isImageFile(String fileName) {
    if (!fileName.contains('.')) return false;
    final ext = fileName.split('.').last.toLowerCase().trim();
    return imageExtensions.contains(ext);
  }

  /// Kompresi otomatis untuk file gambar (merampingkan resolusi dan mengompres ukuran file)
  static Future<CompressedFileResult> compressIfImage({
    required String fileName,
    required Uint8List bytes,
    int maxDimension = 1600,
    double quality = 0.78,
  }) async {
    final originalSize = bytes.lengthInBytes;
    if (!isImageFile(fileName)) {
      return CompressedFileResult(
        fileName: fileName,
        bytes: bytes,
        originalSize: originalSize,
        compressedSize: originalSize,
        wasCompressed: false,
      );
    }

    try {
      final compressed = await compressImageWeb(
        bytes,
        maxDimension: maxDimension,
        quality: quality,
      );

      if (compressed != null &&
          compressed.isNotEmpty &&
          compressed.lengthInBytes < originalSize) {
        // Ganti ekstensi file menjadi .jpg jika sebelumnya .png/.webp agar backend menerima format JPEG yang terkompresi
        var newName = fileName;
        final parts = fileName.split('.');
        if (parts.length > 1) {
          final ext = parts.last.toLowerCase();
          if (ext == 'png' || ext == 'webp' || ext == 'bmp' || ext == 'gif') {
            parts.removeLast();
            newName = '${parts.join('.')}.jpg';
          }
        }

        return CompressedFileResult(
          fileName: newName,
          bytes: compressed,
          originalSize: originalSize,
          compressedSize: compressed.lengthInBytes,
          wasCompressed: true,
        );
      }
    } catch (e) {
      debugPrint('[FileCompressHelper] Gagal melakukan kompresi otomatis: $e');
    }

    return CompressedFileResult(
      fileName: fileName,
      bytes: bytes,
      originalSize: originalSize,
      compressedSize: originalSize,
      wasCompressed: false,
    );
  }
}
