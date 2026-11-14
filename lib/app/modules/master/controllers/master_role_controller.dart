import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../data/services/api_services.dart';

/// Controller halaman Master Role.
///
/// Data diambil dari endpoint `/role` pada backend. Bila server belum
/// terhubung, halaman memakai data contoh supaya tetap bisa dipakai.
class MasterRoleController extends GetxController {
  static const _endpoint = '/role';

  final listRole = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final usingDemoData = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRole();
  }

  /// Role yang tampil setelah pencarian diterapkan.
  List<Map<String, dynamic>> get filteredRole {
    final keyword = searchQuery.value.trim().toLowerCase();
    if (keyword.isEmpty) return listRole;
    return listRole.where((role) {
      return [role['id_role'], role['nama_role']].any(
        (value) => value?.toString().toLowerCase().contains(keyword) ?? false,
      );
    }).toList();
  }

  /// Buat ID role baru yang belum dipakai, misalnya `ROLE-05`.
  String generateRoleId() {
    final used = listRole
        .map((role) => role['id_role']?.toString().toUpperCase() ?? '')
        .toSet();
    var next = listRole.isEmpty ? 1 : listRole.length + 1;
    for (final id in used) {
      final match = RegExp(r'^ROLE-(\d+)$').firstMatch(id);
      final number = int.tryParse(match?.group(1) ?? '');
      if (number != null && number >= next) next = number + 1;
    }

    var candidate = 'ROLE-${next.toString().padLeft(2, '0')}';
    while (used.contains(candidate)) {
      next++;
      candidate = 'ROLE-${next.toString().padLeft(2, '0')}';
    }
    return candidate;
  }

  Future<void> fetchRole() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get(_endpoint);
      listRole.assignAll(_extractRows(response.data).map(_normalize));
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

  /// Simpan role baru (saat [originalId] null) atau perubahan role.
  /// ID role dibuat otomatis untuk role baru.
  /// Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> saveRole({
    String? originalId,
    required String namaRole,
  }) async {
    final nama = namaRole.trim();
    if (nama.isEmpty) return 'Nama role wajib diisi.';
    if (nama.length > 50) return 'Nama role maksimal 50 karakter.';

    final isCreate = originalId == null;
    final id = isCreate ? generateRoleId() : originalId.trim();
    if (id.isEmpty) return 'ID role tidak valid.';

    final now = DateTime.now().toIso8601String();
    Map<String, dynamic>? existing;
    if (!isCreate) {
      final index = listRole.indexWhere(
        (role) => role['id_role']?.toString() == originalId,
      );
      if (index != -1) existing = listRole[index];
    }
    final row = <String, dynamic>{
      'id_role': id,
      'nama_role': nama,
      'created_at': existing?['created_at'] ?? now,
      'updated_at': now,
    };

    isSaving.value = true;
    try {
      if (!usingDemoData.value) {
        final dio = await ApiService.getClient();
        final data = <String, dynamic>{'id_role': id, 'nama_role': nama};
        if (isCreate) {
          await dio.post(_endpoint, data: data);
        } else {
          await dio.put('$_endpoint/$originalId', data: data);
        }
      }
      _applyLocally(originalId: originalId, row: row);
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menyimpan role.');
    } finally {
      isSaving.value = false;
    }
  }

  /// Hapus role. Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> deleteRole(String idRole) async {
    final id = idRole.trim();
    if (id.isEmpty) return 'ID role tidak valid.';

    isSaving.value = true;
    try {
      if (!usingDemoData.value) {
        final dio = await ApiService.getClient();
        await dio.delete('$_endpoint/$id');
      }
      listRole.removeWhere((role) => role['id_role']?.toString() == id);
      listRole.refresh();
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menghapus role.');
    } finally {
      isSaving.value = false;
    }
  }

  void _applyLocally({String? originalId, required Map<String, dynamic> row}) {
    final index = originalId == null
        ? -1
        : listRole.indexWhere(
            (role) => role['id_role']?.toString() == originalId,
          );
    if (index == -1) {
      listRole.add(row);
    } else {
      listRole[index] = row;
    }
    _sort();
  }

  void _useDemoData() {
    usingDemoData.value = true;
    if (listRole.isEmpty) {
      listRole.assignAll(_demoRole());
      _sort();
    }
  }

  void _sort() {
    listRole.sort((first, second) {
      final firstName = first['nama_role']?.toString().toLowerCase() ?? '';
      final secondName = second['nama_role']?.toString().toLowerCase() ?? '';
      return firstName.compareTo(secondName);
    });
    listRole.refresh();
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> row) {
    return {
      'id_role': (row['id_role'] ?? row['idRole'] ?? '').toString(),
      'nama_role': (row['nama_role'] ?? row['namaRole'] ?? '').toString(),
      'created_at': row['created_at'] ?? row['createdAt'],
      'updated_at': row['updated_at'] ?? row['updatedAt'],
      'deleted_at': row['deleted_at'] ?? row['deletedAt'],
    };
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    dynamic rows = payload;
    if (payload is Map) {
      rows =
          payload['data'] ??
          payload['rows'] ??
          payload['role'] ??
          payload['roles'] ??
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

  List<Map<String, dynamic>> _demoRole() {
    return [
      {
        'id_role': 'ROLE-ADMIN',
        'nama_role': 'Administrator',
        'created_at': '2026-10-02T08:10:00',
      },
      {
        'id_role': 'ROLE-DOKTER',
        'nama_role': 'Dokter',
        'created_at': '2026-10-02T08:12:00',
      },
      {
        'id_role': 'ROLE-PETUGAS',
        'nama_role': 'Petugas Umum',
        'created_at': '2026-10-02T08:14:00',
      },
      {
        'id_role': 'ROLE-TEKNISI',
        'nama_role': 'Teknisi',
        'created_at': '2026-10-02T08:16:00',
      },
    ];
  }
}
