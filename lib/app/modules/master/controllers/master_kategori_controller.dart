import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../data/services/api_services.dart';

/// Controller halaman Master Kategori.
///
/// Data diambil dari endpoint `/kategori` pada backend. Bila server belum
/// terhubung, halaman memakai data contoh supaya tetap bisa dipakai.
class MasterKategoriController extends GetxController {
  static const _endpoint = '/kategori';

  final listKategori = <Map<String, dynamic>>[].obs;
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

  /// Buat ID kategori baru yang belum dipakai, misalnya `KAT-06`.
  String generateKategoriId() {
    final used = listKategori
        .map(
          (kategori) => kategori['id_kategori']?.toString().toUpperCase() ?? '',
        )
        .toSet();
    var next = 1;
    for (final id in used) {
      final match = RegExp(r'^KAT-(\d+)$').firstMatch(id);
      final number = int.tryParse(match?.group(1) ?? '');
      if (number != null && number >= next) next = number + 1;
    }

    var candidate = 'KAT-${next.toString().padLeft(2, '0')}';
    while (used.contains(candidate)) {
      next++;
      candidate = 'KAT-${next.toString().padLeft(2, '0')}';
    }
    return candidate;
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
    required String jenisKategori,
  }) async {
    final jenis = jenisKategori.trim();
    if (jenis.isEmpty) return 'Jenis kategori wajib diisi.';
    if (jenis.length > 100) return 'Jenis kategori maksimal 100 karakter.';

    final isCreate = originalId == null;
    final id = isCreate ? generateKategoriId() : originalId.trim();
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
      'jenis_kategori': jenis,
      'created_at': existing?['created_at'] ?? now,
      'updated_at': now,
    };

    isSaving.value = true;
    try {
      if (!usingDemoData.value) {
        final dio = await ApiService.getClient();
        final data = <String, dynamic>{
          'id_kategori': id,
          'jenis_kategori': jenis,
        };
        if (isCreate) {
          await dio.post(_endpoint, data: data);
        } else {
          await dio.put('$_endpoint/$originalId', data: data);
        }
      }
      _applyLocally(originalId: originalId, row: row);
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menyimpan kategori.');
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
      if (!usingDemoData.value) {
        final dio = await ApiService.getClient();
        await dio.delete('$_endpoint/$id');
      }
      listKategori.removeWhere(
        (kategori) => kategori['id_kategori']?.toString() == id,
      );
      listKategori.refresh();
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menghapus kategori.');
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
    if (listKategori.isEmpty) {
      listKategori.assignAll(_demoKategori());
      _sort();
    }
  }

  void _sort() {
    listKategori.sort((first, second) {
      final firstName = first['jenis_kategori']?.toString().toLowerCase() ?? '';
      final secondName =
          second['jenis_kategori']?.toString().toLowerCase() ?? '';
      return firstName.compareTo(secondName);
    });
    listKategori.refresh();
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> row) {
    return {
      'id_kategori': (row['id_kategori'] ?? row['idKategori'] ?? '').toString(),
      'jenis_kategori': (row['jenis_kategori'] ?? row['jenisKategori'] ?? '')
          .toString(),
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
        return message.toString();
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

  List<Map<String, dynamic>> _demoKategori() {
    return [
      {
        'id_kategori': 'KAT-01',
        'jenis_kategori': 'Kelistrikan',
        'created_at': '2026-10-02T08:15:00',
      },
      {
        'id_kategori': 'KAT-02',
        'jenis_kategori': 'Jaringan & Internet',
        'created_at': '2026-10-02T08:20:00',
      },
      {
        'id_kategori': 'KAT-03',
        'jenis_kategori': 'Pendingin Ruangan',
        'created_at': '2026-10-03T09:05:00',
      },
      {
        'id_kategori': 'KAT-04',
        'jenis_kategori': 'Fasilitas Umum',
        'created_at': '2026-10-04T10:40:00',
      },
      {
        'id_kategori': 'KAT-05',
        'jenis_kategori': 'Kebersihan',
        'created_at': '2026-10-05T13:25:00',
      },
    ];
  }
}
