import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../data/services/api_services.dart';

/// Controller halaman Master Unit.
///
/// Data diambil dari endpoint `/unit` pada backend. Bila server belum
/// terhubung, halaman memakai data contoh supaya tetap bisa dipakai.
class MasterUnitController extends GetxController {
  static const _endpoint = '/unit';

  final listUnit = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final usingDemoData = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUnits();
  }

  /// Unit yang tampil setelah pencarian diterapkan.
  List<Map<String, dynamic>> get filteredUnits {
    final keyword = searchQuery.value.trim().toLowerCase();
    if (keyword.isEmpty) return listUnit;
    return listUnit.where((unit) {
      return [unit['id_unit'], unit['nama_unit']].any(
        (value) => value?.toString().toLowerCase().contains(keyword) ?? false,
      );
    }).toList();
  }

  /// Buat ID unit baru yang belum dipakai, misalnya `UNIT-001`.
  String generateUnitId() {
    final used = listUnit
        .map((unit) => unit['id_unit']?.toString().toUpperCase() ?? '')
        .toSet();
    var next = 1;
    for (final id in used) {
      final match = RegExp(r'^UNIT-(\d+)$').firstMatch(id);
      final number = int.tryParse(match?.group(1) ?? '');
      if (number != null && number >= next) next = number + 1;
    }

    var candidate = 'UNIT-${next.toString().padLeft(3, '0')}';
    while (used.contains(candidate)) {
      next++;
      candidate = 'UNIT-${next.toString().padLeft(3, '0')}';
    }
    return candidate;
  }

  Future<void> fetchUnits() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get(_endpoint);
      listUnit.assignAll(_extractRows(response.data).map(_normalize));
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

  /// Simpan unit baru (saat [originalId] null) atau perubahan unit.
  /// ID unit dibuat otomatis untuk unit baru.
  /// Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> saveUnit({
    String? originalId,
    required String namaUnit,
  }) async {
    final nama = namaUnit.trim();
    if (nama.isEmpty) return 'Nama unit wajib diisi.';
    if (nama.length > 100) return 'Nama unit maksimal 100 karakter.';

    final isCreate = originalId == null;
    final id = isCreate ? generateUnitId() : originalId.trim();
    if (id.isEmpty) return 'ID unit tidak valid.';

    final row = <String, dynamic>{'id_unit': id, 'nama_unit': nama};

    isSaving.value = true;
    try {
      if (!usingDemoData.value) {
        final dio = await ApiService.getClient();
        final data = <String, dynamic>{'id_unit': id, 'nama_unit': nama};
        if (isCreate) {
          await dio.post(_endpoint, data: data);
        } else {
          await dio.put('$_endpoint/$originalId', data: data);
        }
      }
      _applyLocally(originalId: originalId, row: row);
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menyimpan unit.');
    } finally {
      isSaving.value = false;
    }
  }

  /// Hapus unit. Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> deleteUnit(String idUnit) async {
    final id = idUnit.trim();
    if (id.isEmpty) return 'ID unit tidak valid.';

    isSaving.value = true;
    try {
      if (!usingDemoData.value) {
        final dio = await ApiService.getClient();
        await dio.delete('$_endpoint/$id');
      }
      listUnit.removeWhere((unit) => unit['id_unit']?.toString() == id);
      listUnit.refresh();
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menghapus unit.');
    } finally {
      isSaving.value = false;
    }
  }

  void _applyLocally({
    String? originalId,
    required Map<String, dynamic> row,
  }) {
    final index = originalId == null
        ? -1
        : listUnit.indexWhere(
            (unit) => unit['id_unit']?.toString() == originalId,
          );
    if (index == -1) {
      listUnit.add(row);
    } else {
      listUnit[index] = row;
    }
    _sort();
  }

  void _useDemoData() {
    usingDemoData.value = true;
    if (listUnit.isEmpty) {
      listUnit.assignAll(_demoUnits());
      _sort();
    }
  }

  void _sort() {
    listUnit.sort((first, second) {
      final firstName = first['nama_unit']?.toString().toLowerCase() ?? '';
      final secondName = second['nama_unit']?.toString().toLowerCase() ?? '';
      return firstName.compareTo(secondName);
    });
    listUnit.refresh();
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> row) {
    return {
      'id_unit': (row['id_unit'] ?? row['idUnit'] ?? '').toString(),
      'nama_unit': (row['nama_unit'] ?? row['namaUnit'] ?? '').toString(),
    };
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    dynamic rows = payload;
    if (payload is Map) {
      rows =
          payload['data'] ??
          payload['rows'] ??
          payload['units'] ??
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

  List<Map<String, dynamic>> _demoUnits() {
    return [
      {'id_unit': 'UNIT-UMUM', 'nama_unit': 'Unit Umum'},
      {'id_unit': 'UNIT-IGD', 'nama_unit': 'Instalasi Gawat Darurat'},
      {'id_unit': 'UNIT-IT', 'nama_unit': 'Teknologi Informasi'},
      {'id_unit': 'UNIT-SDM', 'nama_unit': 'Sumber Daya Manusia'},
    ];
  }
}
