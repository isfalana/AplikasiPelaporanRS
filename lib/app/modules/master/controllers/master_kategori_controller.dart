import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../data/services/api_services.dart';
import '../../../data/services/master_data_store.dart';

/// Controller halaman Master Kategori.
///
/// Data diambil dari endpoint `/kategori` pada backend. Bila server belum
/// terhubung, halaman memakai data contoh dari [MasterDataStore] supaya tetap
/// bisa dipakai dan tetap terhubung dengan halaman Laporan/Report.
class MasterKategoriController extends GetxController {
  // [MODIFIKASI] Endpoint diselaraskan dengan backend masterRoutes.js (/master/kategoris)
  static const _endpoint = '/master/kategoris';

  MasterDataStore get _store => MasterDataStore.ensure();

  /// Daftar kategori milik store bersama, dipakai juga oleh form Laporan.
  RxList<Map<String, dynamic>> get listKategori => _store.listKategori;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final usingDemoData = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchKategori();
  }

  /// Kategori yang tampil setelah pencarian diterapkan.
  List<Map<String, dynamic>> get filteredKategori {
    final keyword = searchQuery.value.trim().toLowerCase();
    if (keyword.isEmpty) return listKategori;
    return listKategori.where((kategori) {
      return [kategori['id_kategori'], kategori['jenis_kategori']].any(
        (value) => value?.toString().toLowerCase().contains(keyword) ?? false,
      );
    }).toList();
  }

  /// [MODIFIKASI] Ambil ID kategori berikutnya langsung dari database (termasuk soft-delete)
  Future<String> fetchNextId() async {
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get('/master/next-id/kategori');
      if (response.statusCode == 200 && response.data != null) {
        final nextId = response.data['data']?['next_id']?.toString();
        if (nextId != null && nextId.isNotEmpty) {
          return nextId;
        }
      }
    } catch (_) {}
    return generateKategoriId();
  }

  /// [MODIFIKASI] Buat ID kategori baru 2 digit (KAT-01) sebagai fallback
  String generateKategoriId() {
    var maxNumber = 0;
    for (final kategori in listKategori) {
      final id = kategori['id_kategori']?.toString().toUpperCase() ?? '';
      final match = RegExp(r'^KAT-(\d+)$').firstMatch(id);
      if (match != null) {
        final number = int.tryParse(match.group(1)!);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }
    return 'KAT-${(maxNumber + 1).toString().padLeft(2, '0')}';
  }

  Future<void> fetchKategori() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get(_endpoint);
      listKategori.assignAll(_extractRows(response.data).map(_normalize));
      _sort();
      usingDemoData.value = false;
    } on DioException {
      _useDemoData();
    } catch (_) {
      _useDemoData();
    } finally {
      isLoading.value = false;
    }
  }

  /// Simpan kategori baru (saat [originalId] null) atau perubahan kategori.
  /// ID kategori dibuat otomatis untuk kategori baru.
  /// Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> saveKategori({
    String? originalId,
    String? customId,
    required String jenisKategori,
  }) async {
    final jenis = jenisKategori.trim();
    if (jenis.isEmpty) return 'Jenis kategori wajib diisi.';
    if (jenis.length > 100) return 'Jenis kategori maksimal 100 karakter.';

    final isCreate = originalId == null;
    final id = isCreate ? (customId ?? await fetchNextId()) : originalId.trim();
    if (id.isEmpty) return 'ID kategori tidak valid.';

    final now = DateTime.now().toIso8601String();
    Map<String, dynamic>? existing;
    if (!isCreate) {
      final index = listKategori.indexWhere(
        (kategori) => kategori['id_kategori']?.toString() == originalId,
      );
      if (index != -1) existing = listKategori[index];
    }
    final row = <String, dynamic>{
      'id_kategori': id,
      'nama_kategori': jenis,
      'jenis_kategori': jenis,
      'created_at': existing?['created_at'] ?? now,
      'updated_at': now,
    };

    isSaving.value = true;
    try {
      // [MODIFIKASI] Selalu simpan ke endpoint backend /master/kategoris
      final dio = await ApiService.getClient();
      final data = <String, dynamic>{
        'id_kategori': id,
        'nama_kategori': jenis,
        'jenis_kategori': jenis,
      };
      if (isCreate) {
        await dio.post(_endpoint, data: data);
      } else {
        await dio.put('$_endpoint/$originalId', data: data);
      }
      _applyLocally(originalId: originalId, row: row);
      await MasterDataStore.ensure().fetchFromBackend();
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menyimpan kategori ke database.');
    } finally {
      isSaving.value = false;
    }
  }

  /// Hapus kategori. Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> deleteKategori(String idKategori) async {
    final id = idKategori.trim();
    if (id.isEmpty) return 'ID kategori tidak valid.';

    isSaving.value = true;
    try {
      // [MODIFIKASI] Hapus kategori dari backend database
      final dio = await ApiService.getClient();
      await dio.delete('$_endpoint/$id');
      listKategori.removeWhere(
        (kategori) => kategori['id_kategori']?.toString() == id,
      );
      listKategori.refresh();
      await MasterDataStore.ensure().fetchFromBackend();
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menghapus kategori dari database.');
    } finally {
      isSaving.value = false;
    }
  }

  void _applyLocally({String? originalId, required Map<String, dynamic> row}) {
    final index = originalId == null
        ? -1
        : listKategori.indexWhere(
            (kategori) => kategori['id_kategori']?.toString() == originalId,
          );
    if (index == -1) {
      listKategori.add(row);
    } else {
      listKategori[index] = row;
    }
    _sort();
  }

  void _useDemoData() {
    usingDemoData.value = true;
    // Data contoh sudah disemai oleh MasterDataStore. Jangan menimpa data
    // yang mungkin baru ditambahkan pengguna saat server tidak tersedia.
    _sort();
  }

  // [MODIFIKASI] Pengurutan tabel master kategori berdasarkan id_kategori secara natural
  void _sort() {
    listKategori.sort((first, second) {
      final firstId = (first['id_kategori'] ?? first['idKategori'] ?? '').toString().trim();
      final secondId = (second['id_kategori'] ?? second['idKategori'] ?? '').toString().trim();
      if (firstId.isEmpty && secondId.isEmpty) return 0;
      if (firstId.isEmpty) return 1;
      if (secondId.isEmpty) return -1;

      final numA = int.tryParse(firstId);
      final numB = int.tryParse(secondId);
      if (numA != null && numB != null) return numA.compareTo(numB);

      final reg = RegExp(r'^(\D*)(\d+)$');
      final matchA = reg.firstMatch(firstId);
      final matchB = reg.firstMatch(secondId);
      if (matchA != null && matchB != null && matchA.group(1)?.toLowerCase() == matchB.group(1)?.toLowerCase()) {
        final nA = int.tryParse(matchA.group(2)!) ?? 0;
        final nB = int.tryParse(matchB.group(2)!) ?? 0;
        final comp = nA.compareTo(nB);
        if (comp != 0) return comp;
      }

      return firstId.toLowerCase().compareTo(secondId.toLowerCase());
    });
    listKategori.refresh();
  }

  // [MODIFIKASI] Normalisasi kategori mendukung nama_kategori dari database PostgreSQL
  Map<String, dynamic> _normalize(Map<String, dynamic> row) {
    final name = (row['nama_kategori'] ?? row['jenis_kategori'] ?? row['jenisKategori'] ?? '').toString();
    return {
      'id_kategori': (row['id_kategori'] ?? row['idKategori'] ?? '').toString(),
      'nama_kategori': name,
      'jenis_kategori': name,
      'created_at': row['created_at'] ?? row['createdAt'],
      'updated_at': row['updated_at'] ?? row['updatedAt'],
    };
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    dynamic rows = payload;
    if (payload is Map) {
      rows =
          payload['data'] ??
          payload['rows'] ??
          payload['kategori'] ??
          payload['items'];
      if (rows is Map) {
        rows = rows['rows'] ?? rows['data'] ?? rows['items'];
      }
    }
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  String _errorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        final msgStr = message.toString();
        if (msgStr.contains('notNull Violation')) {
          final lower = msgStr.toLowerCase();
          if (lower.contains('kategori') || lower.contains('nama')) return 'Jenis kategori tidak boleh kosong.';
          return 'Data yang wajib diisi tidak boleh kosong.';
        }
        return msgStr;
      }
    }
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => 'Tidak dapat terhubung ke server.',
      _ => fallback,
    };
  }
}
