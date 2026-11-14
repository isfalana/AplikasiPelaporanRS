import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Ekstensi gambar yang bisa ditampilkan sebagai pratinjau.
const Set<String> _imageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'heic',
  'heif',
};

/// Ekstensi dokumen yang dikenali pada field bukti.
const Set<String> _documentExtensions = {
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
  'zip',
  'rar',
  '7z',
  'mp4',
  'mov',
  'mp3',
  'wav',
};

/// Ekstensi file huruf kecil tanpa titik, kosong bila tidak ada.
String buktiFileExtension(String fileName) {
  final name = fileName.trim();
  final index = name.lastIndexOf('.');
  if (index < 0 || index == name.length - 1) return '';
  return name.substring(index + 1).toLowerCase();
}

/// Apakah isi file berupa gambar sehingga bisa ditampilkan langsung.
///
/// Bila nama file kosong tapi tersedia isi bytes, diperlakukan sebagai gambar
/// (data bukti lama yang hanya menyimpan bytes).
bool isImageBukti(String fileName, {Uint8List? bytes}) {
  final extension = buktiFileExtension(fileName);
  if (extension.isEmpty) return bytes != null;
  if (_imageExtensions.contains(extension)) return true;
  if (_documentExtensions.contains(extension)) return false;
  return bytes != null;
}

/// Ikon dokumen sesuai jenis file.
IconData buktiFileIcon(String fileName) {
  return switch (buktiFileExtension(fileName)) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' || 'docx' || 'rtf' || 'odt' => Icons.article_outlined,
    'xls' || 'xlsx' || 'csv' || 'ods' => Icons.table_chart_outlined,
    'ppt' || 'pptx' || 'odp' => Icons.slideshow_outlined,
    'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
    'mp4' || 'mov' => Icons.video_file_outlined,
    'mp3' || 'wav' => Icons.audio_file_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

/// Label jenis file, mis. `PDF`, `PNG`, atau `FILE`.
String buktiFileTypeLabel(String fileName) {
  final extension = buktiFileExtension(fileName);
  return extension.isEmpty ? 'FILE' : extension.toUpperCase();
}

/// Ukuran file dalam teks ringkas, mis. `1,2 MB` atau `840 KB`.
String buktiFileSize(Uint8List? bytes) {
  if (bytes == null) return '-';
  final size = bytes.lengthInBytes;
  if (size < 1024) return '$size B';
  if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Tile pratinjau bukti berukuran kecil.
///
/// Menampilkan thumbnail (gambar) atau ikon dokumen, nama file, dan petunjuk
/// bahwa file dapat diklik untuk dilihat lebih besar.
class BuktiPreviewTile extends StatelessWidget {
  const BuktiPreviewTile({
    required this.fileName,
    this.bytes,
    this.thumbnailSize = 76,
    super.key,
  });

  final String fileName;
  final Uint8List? bytes;
  final double thumbnailSize;

  bool get _isImage => isImageBukti(fileName, bytes: bytes);

  @override
  Widget build(BuildContext context) {
    final name = fileName.trim().isEmpty ? 'Bukti tanpa nama' : fileName;

    return InkWell(
      onTap: () => showBuktiViewer(context, fileName: fileName, bytes: bytes),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            _thumbnail(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${buktiFileTypeLabel(name)} · ${buktiFileSize(bytes)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textWeak,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Klik untuk melihat',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.open_in_full, size: 15, color: AppColors.textWeak),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: thumbnailSize,
        height: thumbnailSize,
        color: AppColors.surface,
        alignment: Alignment.center,
        child: _isImage && bytes != null
            ? Image.memory(
                bytes!,
                width: thumbnailSize,
                height: thumbnailSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _documentIcon(),
              )
            : _documentIcon(),
      ),
    );
  }

  Widget _documentIcon() {
    return Icon(buktiFileIcon(fileName), size: 26, color: AppColors.primary);
  }
}

/// Tampilkan file bukti pada dialog layar penuh.
///
/// Gambar ditampilkan dalam `InteractiveViewer` (bisa digeser/di-zoom),
/// dokumen ditampilkan beserta nama, jenis, dan ukuran file.
Future<void> showBuktiViewer(
  BuildContext context, {
  required String fileName,
  Uint8List? bytes,
}) {
  final name = fileName.trim().isEmpty ? 'Bukti tanpa nama' : fileName;
  final isImage = isImageBukti(fileName, bytes: bytes);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final screen = MediaQuery.sizeOf(dialogContext);
      return Dialog(
        backgroundColor: AppColors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: screen.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  children: [
                    Icon(
                      isImage ? Icons.image_outlined : buktiFileIcon(name),
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.textWeak,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: isImage && bytes != null
                    ? InteractiveViewer(
                        maxScale: 5,
                        child: Center(
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _documentPlaceholder(name, bytes),
                          ),
                        ),
                      )
                    : _documentPlaceholder(name, bytes),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Text(
                  isImage && bytes != null
                      ? 'Geser untuk memperbesar. ${buktiFileSize(bytes)}'
                      : 'Pratinjau dokumen tidak tersedia. File disimpan '
                            'lokal pada sesi ini.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textWeak,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _documentPlaceholder(String fileName, Uint8List? bytes) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(buktiFileIcon(fileName), size: 64, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            fileName.trim().isEmpty ? 'Bukti tanpa nama' : fileName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${buktiFileTypeLabel(fileName)} · ${buktiFileSize(bytes)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textWeak),
          ),
        ],
      ),
    ),
  );
}
