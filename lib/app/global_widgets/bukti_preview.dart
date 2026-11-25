import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../core/theme/app_colors.dart';
import '../data/services/api_services.dart';

/// Ekstensi gambar yang bisa ditampilkan sebagai pratinjau langsung.
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
// [MODIFIKASI] Memeriksa apakah file adalah gambar berdasarkan ekstensi, bytes, atau imageUrl
bool isImageBukti(String fileName, {Uint8List? bytes, String? imageUrl}) {
  final extension = buktiFileExtension(fileName);
  if (extension.isEmpty) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final urlExt = buktiFileExtension(imageUrl);
      if (_imageExtensions.contains(urlExt)) return true;
    }
    return bytes != null;
  }
  if (_imageExtensions.contains(extension)) return true;
  if (_documentExtensions.contains(extension)) return false;
  return bytes != null || (imageUrl != null && imageUrl.isNotEmpty);
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

/// [MODIFIKASI] Warna tema untuk jenis file agar tampilan visual informatif
Color buktiFileColor(String fileName) {
  return switch (buktiFileExtension(fileName)) {
    'pdf' => const Color(0xFFD32F2F), // Red
    'doc' || 'docx' => const Color(0xFF1976D2), // Word Blue
    'xls' || 'xlsx' || 'csv' => const Color(0xFF2E7D32), // Excel Green
    'ppt' || 'pptx' => const Color(0xFFE64A19), // Orange
    'zip' || 'rar' || '7z' => const Color(0xFFF57C00),
    _ => AppColors.primary,
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
// [MODIFIKASI] Menampilkan thumbnail visual gambar atau badge dokumen dengan warna aksen sesuai format file
class BuktiPreviewTile extends StatelessWidget {
  const BuktiPreviewTile({
    required this.fileName,
    this.bytes,
    this.imageUrl,
    this.idEvidence,
    this.idLaporan,
    this.thumbnailSize = 76,
    super.key,
  });

  final String fileName;
  final Uint8List? bytes;
  final String? imageUrl;
  final String? idEvidence;
  final String? idLaporan;
  final double thumbnailSize;

  String? get resolvedImageUrl {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) return imageUrl!.trim();
    if (idEvidence != null && idEvidence!.trim().isNotEmpty) {
      return '${ApiService.baseUrl}/evidence/file/${idEvidence!.trim()}';
    }
    if (idLaporan != null && idLaporan!.trim().isNotEmpty) {
      return '${ApiService.baseUrl}/evidence/file-laporan/${idLaporan!.trim()}';
    }
    return null;
  }

  bool get _isImage => isImageBukti(fileName, bytes: bytes, imageUrl: resolvedImageUrl);

  @override
  Widget build(BuildContext context) {
    final name = fileName.trim().isEmpty ? 'Bukti tanpa nama' : fileName;
    final ext = buktiFileExtension(name);
    final color = buktiFileColor(name);

    return InkWell(
      onTap: () => showBuktiViewer(
        context,
        fileName: fileName,
        bytes: bytes,
        imageUrl: resolvedImageUrl,
        idEvidence: idEvidence,
        idLaporan: idLaporan,
      ),
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
            _thumbnail(color),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          buktiFileTypeLabel(name),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        buktiFileSize(bytes),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textWeak,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        ext == 'pdf' || _isImage || ext == 'xlsx' || ext == 'xls'
                            ? Icons.visibility_outlined
                            : Icons.file_download_outlined,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ext == 'pdf' || _isImage || ext == 'xlsx' || ext == 'xls'
                            ? 'Klik untuk pratinjau'
                            : 'Klik untuk membuka / unduh',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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

  Widget _thumbnail(Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: thumbnailSize,
        height: thumbnailSize,
        color: _isImage ? AppColors.surface : color.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: _buildThumbnailContent(color),
      ),
    );
  }

  Widget _buildThumbnailContent(Color color) {
    if (!_isImage) return _documentBadge(color);

    if (bytes != null && bytes!.isNotEmpty) {
      return Image.memory(
        bytes!,
        width: thumbnailSize,
        height: thumbnailSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _documentBadge(color),
      );
    }

    final imgUrl = resolvedImageUrl;
    if (imgUrl != null && imgUrl.trim().isNotEmpty) {
      return Image.network(
        imgUrl.trim(),
        width: thumbnailSize,
        height: thumbnailSize,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _documentBadge(color),
      );
    }

    return _documentBadge(color);
  }

  Widget _documentBadge(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(buktiFileIcon(fileName), size: 26, color: color),
        const SizedBox(height: 2),
        Text(
          buktiFileTypeLabel(fileName),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// [MODIFIKASI] Tampilkan file bukti pada dialog layar penuh dengan pratinjau interaktif.
///
/// - Gambar: InteractiveViewer dengan zoom dan pan
/// - PDF: PdfPreview interaktif (dapat dibaca per halaman, diperbesar, dicetak, dan diunduh)
/// - Excel: Pratinjau tabel lembar kerja interaktif beserta tombol unduh berkas
/// - Word / Dokumen lain: Kartu dokumen lengkap dengan aksi unduh dan buka berkas
Future<void> showBuktiViewer(
  BuildContext context, {
  required String fileName,
  Uint8List? bytes,
  String? imageUrl,
  String? idEvidence,
  String? idLaporan,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return _BuktiViewerDialog(
        fileName: fileName,
        bytes: bytes,
        imageUrl: imageUrl,
        idEvidence: idEvidence,
        idLaporan: idLaporan,
      );
    },
  );
}

// [MODIFIKASI] Dialog pratinjau dan unduh bukti yang komprehensif
class _BuktiViewerDialog extends StatefulWidget {
  const _BuktiViewerDialog({
    required this.fileName,
    this.bytes,
    this.imageUrl,
    this.idEvidence,
    this.idLaporan,
  });

  final String fileName;
  final Uint8List? bytes;
  final String? imageUrl;
  final String? idEvidence;
  final String? idLaporan;

  @override
  State<_BuktiViewerDialog> createState() => _BuktiViewerDialogState();
}

class _BuktiViewerDialogState extends State<_BuktiViewerDialog> {
  Uint8List? _bytes;
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _errorMessage;
  int _selectedSheetIndex = 0;

  String get _name => widget.fileName.trim().isEmpty ? 'Bukti tanpa nama' : widget.fileName.trim();
  String get _ext => buktiFileExtension(_name);
  String? get _resolvedUrl {
    if (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty) return widget.imageUrl!.trim();
    if (widget.idEvidence != null && widget.idEvidence!.trim().isNotEmpty) {
      return '${ApiService.baseUrl}/evidence/file/${widget.idEvidence!.trim()}';
    }
    if (widget.idLaporan != null && widget.idLaporan!.trim().isNotEmpty) {
      return '${ApiService.baseUrl}/evidence/file-laporan/${widget.idLaporan!.trim()}';
    }
    return null;
  }
  bool get _isImage => isImageBukti(widget.fileName, bytes: _bytes ?? widget.bytes, imageUrl: _resolvedUrl);

  @override
  void initState() {
    super.initState();
    _bytes = widget.bytes;

    // Unduh bytes jika belum ada di memori agar pratinjau PDF, Excel, dll. langsung dirender
    if (_bytes == null && (_resolvedUrl != null || widget.idLaporan != null)) {
      if (_ext == 'pdf' || _ext == 'xlsx' || _ext == 'xls' || _ext == 'csv') {
        _loadBytes();
      }
    }
  }

  Future<void> _loadBytes() async {
    if (_bytes != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? targetUrl = _resolvedUrl;
      if (targetUrl == null && widget.idLaporan != null && widget.idLaporan!.isNotEmpty) {
        targetUrl = '${ApiService.baseUrl}/evidence/file-laporan/${widget.idLaporan!.trim()}';
      }

      if (targetUrl != null && targetUrl.isNotEmpty) {
        final dio = await ApiService.getClient();
        final res = await dio.get<List<int>>(
          targetUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null && res.data!.isNotEmpty && mounted) {
          setState(() {
            _bytes = Uint8List.fromList(res.data!);
            _isLoading = false;
          });
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Data file tidak ditemukan di server';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Tidak dapat memuat file: $e';
        });
      }
    }
  }

  MimeType _resolveMimeType(String ext) {
    return switch (ext.toLowerCase()) {
      'pdf' => MimeType.pdf,
      'doc' || 'docx' => MimeType.microsoftWord,
      'xls' || 'xlsx' => MimeType.microsoftExcel,
      'csv' => MimeType.csv,
      'png' => MimeType.png,
      'jpg' || 'jpeg' => MimeType.jpeg,
      'gif' => MimeType.gif,
      'bmp' => MimeType.bmp,
      _ => MimeType.other,
    };
  }

  Future<void> _downloadFile() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      Uint8List? data = _bytes;
      if (data == null) {
        String? targetUrl = _resolvedUrl;
        if (targetUrl == null && widget.idLaporan != null && widget.idLaporan!.isNotEmpty) {
          targetUrl = '${ApiService.baseUrl}/evidence/file-laporan/${widget.idLaporan!.trim()}';
        }

        if (targetUrl != null && targetUrl.isNotEmpty) {
          final dio = await ApiService.getClient();
          final res = await dio.get<List<int>>(
            targetUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.data != null && res.data!.isNotEmpty) {
            data = Uint8List.fromList(res.data!);
            _bytes = data;
          }
        }
      }

      if (data == null || data.isEmpty) {
        Get.snackbar(
          'Gagal Mengunduh',
          'Isi berkas tidak ditemukan di penyimpanan server.',
          backgroundColor: AppColors.warning,
          colorText: AppColors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final ext = _ext.isNotEmpty ? _ext : 'bin';
      final baseName = _name.replaceAll('.$ext', '');
      final mime = _resolveMimeType(ext);

      await FileSaver.instance.saveFile(
        name: baseName.isNotEmpty ? baseName : 'evidence_${DateTime.now().millisecondsSinceEpoch}',
        bytes: data,
        ext: ext,
        mimeType: mime,
      );

      Get.snackbar(
        'Berhasil Mengunduh',
        'Berkas "$_name" berhasil disimpan ke perangkat.',
        backgroundColor: AppColors.success,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal Mengunduh',
        'Terjadi kendala saat mengunduh berkas: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final color = buktiFileColor(_name);

    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: screen.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Dialog
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _isImage ? Icons.image_outlined : buktiFileIcon(_name),
                      size: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(
                          '${buktiFileTypeLabel(_name)} · ${buktiFileSize(_bytes)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textWeak,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol Unduh di Header
                  IconButton(
                    tooltip: 'Unduh file',
                    onPressed: _isDownloading ? null : _downloadFile,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.download_rounded,
                            size: 22,
                            color: AppColors.primary,
                          ),
                  ),
                  // Tombol Tutup di Header
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
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

            // Konten Viewer
            Expanded(
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: _buildContent(),
              ),
            ),

            const Divider(height: 1),
            // Footer Info & Aksi
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _footerText(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textWeak,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isDownloading ? null : _downloadFile,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Unduh Dokumen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _footerText() {
    if (_isImage) {
      return 'Geser atau gunakan gesture cubit untuk memperbesar gambar.';
    }
    if (_ext == 'pdf') {
      return 'Pratinjau interaktif PDF. Anda dapat memperbesar, mencetak, atau mengunduh.';
    }
    if (_ext == 'xlsx' || _ext == 'xls' || _ext == 'csv') {
      return 'Pratinjau lembar kerja Excel.';
    }
    return 'Dokumen tersimpan pada server. Klik tombol Unduh untuk membukanya.';
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              'Memuat pratinjau $_name...',
              style: const TextStyle(fontSize: 13, color: AppColors.textWeak),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorCard(_errorMessage!);
    }

    if (_isImage) {
      return _buildImageViewer();
    }

    if (_ext == 'pdf') {
      return _buildPdfViewer();
    }

    if (_ext == 'xlsx' || _ext == 'xls' || _ext == 'csv') {
      return _buildExcelViewer();
    }

    if (_ext == 'doc' || _ext == 'docx') {
      return _buildWordViewer();
    }

    return _buildGenericDocViewer();
  }

  Widget _buildImageViewer() {
    if (_bytes != null && _bytes!.isNotEmpty) {
      return InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Image.memory(
            _bytes!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildGenericDocViewer(),
          ),
        ),
      );
    }

    final imgUrl = _resolvedUrl;
    if (imgUrl != null && imgUrl.trim().isNotEmpty) {
      return InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Image.network(
            imgUrl.trim(),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              final expected = loadingProgress.expectedTotalBytes;
              final loaded = loadingProgress.cumulativeBytesLoaded;
              final progress = (expected != null && expected > 0)
                  ? loaded / expected
                  : null;
              return Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(value: progress, strokeWidth: 3),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                _buildGenericDocViewer(),
          ),
        ),
      );
    }

    return _buildGenericDocViewer();
  }

  // [MODIFIKASI] Render PDF interaktif menggunakan PdfPreview dari package printing
  Widget _buildPdfViewer() {
    if (_bytes == null || _bytes!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 56, color: Color(0xFFD32F2F)),
            const SizedBox(height: 12),
            const Text(
              'Dokumen PDF siap diunduh',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textStrong),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadBytes,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Muat Pratinjau PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      child: PdfPreview(
        build: (format) async => _bytes!,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: _name,
        maxPageWidth: 720,
        scrollViewDecoration: const BoxDecoration(color: Color(0xFFEBEFF2)),
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Menyiapkan pratinjau halaman PDF...'),
            ],
          ),
        ),
        onError: (context, error) => _buildErrorCard('Gagal merender dokumen PDF: $error'),
      ),
    );
  }

  // [MODIFIKASI] Render tabel spreadsheet interaktif dari file Excel
  Widget _buildExcelViewer() {
    if (_bytes == null || _bytes!.isEmpty) {
      return _buildExcelCard();
    }

    // Coba decode XLSX menggunakan package excel
    if (_ext == 'xlsx') {
      try {
        final excel = excel_pkg.Excel.decodeBytes(_bytes!);
        final sheetNames = excel.tables.keys.toList();
        if (sheetNames.isNotEmpty) {
          if (_selectedSheetIndex >= sheetNames.length) {
            _selectedSheetIndex = 0;
          }
          final currentSheetName = sheetNames[_selectedSheetIndex];
          final sheet = excel.tables[currentSheetName];

          if (sheet != null && sheet.rows.isNotEmpty) {
            final rows = sheet.rows;
            // Ambil maksimal 50 baris untuk performa
            final displayRows = rows.take(50).toList();
            final colCount = sheet.maxColumns;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sheet Tab Selector bila lebih dari 1 sheet
                if (sheetNames.length > 1)
                  Container(
                    height: 40,
                    color: AppColors.white,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sheetNames.length,
                      itemBuilder: (context, i) {
                        final isSel = i == _selectedSheetIndex;
                        return InkWell(
                          onTap: () => setState(() => _selectedSheetIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isSel ? const Color(0xFF2E7D32) : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Text(
                              sheetNames[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? const Color(0xFF2E7D32) : AppColors.textWeak,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Data Table Spreadsheet Preview
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F5E9)),
                          headingTextStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                          dataTextStyle: const TextStyle(fontSize: 11, color: AppColors.textStrong),
                          border: TableBorder.all(color: AppColors.divider, width: 0.8),
                          columns: List.generate(colCount, (colIdx) {
                            final headerVal = displayRows.first.length > colIdx
                                ? displayRows.first[colIdx]?.value?.toString() ?? 'Kolom ${colIdx + 1}'
                                : 'Kolom ${colIdx + 1}';
                            return DataColumn(label: Text(headerVal));
                          }),
                          rows: List.generate(displayRows.length - 1, (rowIdx) {
                            final row = displayRows[rowIdx + 1];
                            return DataRow(
                              cells: List.generate(colCount, (colIdx) {
                                final cellVal = row.length > colIdx ? row[colIdx]?.value?.toString() ?? '' : '';
                                return DataCell(Text(cellVal));
                              }),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        }
      } catch (_) {
        // Fallback bila decode gagal (misal file XLS binary lama atau terproteksi)
      }
    }

    // CSV viewer sederhana
    if (_ext == 'csv') {
      try {
        final content = utf8.decode(_bytes!);
        final lines = content.split('\n').where((l) => l.trim().isNotEmpty).take(50).toList();
        if (lines.isNotEmpty) {
          final firstLine = lines.first.split(',');
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F5E9)),
                  border: TableBorder.all(color: AppColors.divider, width: 0.8),
                  columns: firstLine.map((c) => DataColumn(label: Text(c.trim()))).toList(),
                  rows: lines.skip(1).map((line) {
                    final cells = line.split(',');
                    return DataRow(
                      cells: List.generate(
                        firstLine.length,
                        (idx) => DataCell(Text(idx < cells.length ? cells[idx].trim() : '')),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        }
      } catch (_) {}
    }

    return _buildExcelCard();
  }

  Widget _buildExcelCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
              ),
              child: const Icon(Icons.table_chart_rounded, size: 54, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textStrong),
            ),
            const SizedBox(height: 4),
            Text(
              'Dokumen Lembar Kerja Excel · ${buktiFileSize(_bytes)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textWeak),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Text(
                'File tersimpan pada server. Klik Unduh Dokumen untuk membukanya di Microsoft Excel atau Google Spreadsheet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textWeak),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadFile,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Buka / Unduh File Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [MODIFIKASI] Render kartu pratinjau dokumen Microsoft Word
  Widget _buildWordViewer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
              ),
              child: const Icon(Icons.article_rounded, size: 54, color: Color(0xFF1976D2)),
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textStrong),
            ),
            const SizedBox(height: 4),
            Text(
              'Dokumen Microsoft Word · ${buktiFileSize(_bytes)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textWeak),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Text(
                'File tersimpan pada server. Klik tombol di bawah untuk mengunduh dan membukanya di Microsoft Word.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textWeak),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadFile,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Buka / Unduh Dokumen Word'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericDocViewer() {
    final color = buktiFileColor(_name);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(buktiFileIcon(_name), size: 54, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textStrong),
            ),
            const SizedBox(height: 4),
            Text(
              '${buktiFileTypeLabel(_name)} · ${buktiFileSize(_bytes)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textWeak),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadFile,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Unduh Berkas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textStrong),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _downloadFile,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Coba Unduh Langsung'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
