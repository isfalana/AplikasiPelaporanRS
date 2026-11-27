import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../data/services/api_services.dart';
import '../../../data/services/master_data_store.dart';

/// Controller halaman Master Role.
///
/// Data diambil dari endpoint `/role` pada backend. Bila server belum
/// terhubung, halaman memakai data contoh dari [MasterDataStore] supaya tetap
/// bisa dipakai dan tetap terhubung dengan dropdown role karyawan.
class MasterRoleController extends GetxController {
  // [MODIFIKASI] Endpoint diselaraskan dengan backend masterRoutes.js (/master/roles)
  static const _endpoint = '/master/roles';

  MasterDataStore get _store => MasterDataStore.ensure();

  /// Daftar role milik store bersama, dipakai juga oleh form karyawan.
  RxList<Map<String, dynamic>> get listRole => _store.listRole;

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

  /// [MODIFIKASI] Ambil ID role berikutnya langsung dari database (termasuk soft-delete)
  Future<String> fetchNextId() async {
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get('/master/next-id/role');
      if (response.statusCode == 200 && response.data != null) {
        final nextId = response.data['data']?['next_id']?.toString();
        if (nextId != null && nextId.isNotEmpty) {
          return nextId;
        }
      }
    } catch (_) {}
    return generateRoleId();
  }

  /// [MODIFIKASI] Buat ID role baru 2 digit (ROLE-01) sebagai fallback
  String generateRoleId() {
    var maxNumber = 0;
    for (final role in listRole) {
      final id = role['id_role']?.toString().toUpperCase() ?? '';
      final match = RegExp(r'^(?:ROLE|R)-?(\d+)$').firstMatch(id);
      if (match != null) {
        final number = int.tryParse(match.group(1)!);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }
    return 'ROLE-${(maxNumber + 1).toString().padLeft(2, '0')}';
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
    String? customId,
    required String namaRole,
    List<String> permissions = const [],
  }) async {
    final nama = namaRole.trim();
    if (nama.isEmpty) return 'Nama role wajib diisi.';
    if (nama.length > 50) return 'Nama role maksimal 50 karakter.';

    final isCreate = originalId == null;
    final id = isCreate ? (customId ?? await fetchNextId()) : originalId.trim();
    if (id.isEmpty) return 'ID role tidak valid.';

    final selectedPermissions = _cleanPermissions(permissions);
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
      'permissions': selectedPermissions,
      'created_at': existing?['created_at'] ?? now,
      'updated_at': now,
    };

    isSaving.value = true;
    try {
      // [MODIFIKASI] Selalu simpan role beserta daftar hak akses (permissions) ke endpoint backend /master/roles
      final dio = await ApiService.getClient();
      final data = <String, dynamic>{
        'id_role': id,
        'nama_role': nama,
        'deskripsi': nama,
        'permissions': selectedPermissions,
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
      return _errorMessage(error, 'Gagal menyimpan role.');
    } finally {
      isSaving.value = false;
    }
  }

  /// Ringkas daftar permission: hanya key yang dikenal, tanpa duplikat.
  ///
  /// Bila seluruh permission dipilih, simpan wildcard `*` supaya role tetap
  /// mendapat fitur baru yang ditambahkan di kemudian hari.
  List<String> _cleanPermissions(List<String> permissions) {
    final values = permissions
        .map((permission) => permission.trim())
        .where(MasterDataStore.allPermissions.contains)
        .toSet();
    if (values.length == MasterDataStore.allPermissions.length) {
      return [MasterDataStore.wildcardPermission];
    }
    return values.toList()..sort();
  }

  /// Hak akses milik [role], dipakai untuk ringkasan pada tabel.
  Set<String> permissionsOf(Map<String, dynamic> role) {
    return _store.permissionsForRole(role['id_role']?.toString() ?? '');
  }

  /// Hapus role. Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> deleteRole(String idRole) async {
    final id = idRole.trim();
    if (id.isEmpty) return 'ID role tidak valid.';

    isSaving.value = true;
    try {
      // [MODIFIKASI] Hapus role dari database backend
      final dio = await ApiService.getClient();
      await dio.delete('$_endpoint/$id');
      listRole.removeWhere((role) => role['id_role']?.toString() == id);
      listRole.refresh();
      await MasterDataStore.ensure().fetchFromBackend();
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
    // Data contoh sudah disemai oleh MasterDataStore. Jangan menimpa data
    // yang mungkin baru ditambahkan pengguna saat server tidak tersedia.
    _sort();
  }

  // [MODIFIKASI] Pengurutan tabel master role berdasarkan id_role secara natural
  void _sort() {
    listRole.sort((first, second) {
      final firstId = (first['id_role'] ?? first['idRole'] ?? '').toString().trim();
      final secondId = (second['id_role'] ?? second['idRole'] ?? '').toString().trim();
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
    listRole.refresh();
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> row) {
    return {
      'id_role': (row['id_role'] ?? row['idRole'] ?? '').toString(),
      'nama_role': (row['nama_role'] ?? row['namaRole'] ?? '').toString(),
      'permissions': _normalizePermissions(
        row['permissions'] ??
            row['permission'] ??
            row['hak_akses'] ??
            row['hakAkses'],
      ),
      'created_at': row['created_at'] ?? row['createdAt'],
      'updated_at': row['updated_at'] ?? row['updatedAt'],
      'deleted_at': row['deleted_at'] ?? row['deletedAt'],
    };
  }

  /// Bentuk permission dari backend bisa berupa list string, list object,
  /// string dipisah koma, atau string JSON. Semuanya diseragamkan di sini.
  List<String> _normalizePermissions(dynamic raw) {
    final values = <String>{};
    void collect(dynamic value) {
      if (value is Iterable) {
        for (final item in value) {
          collect(item);
        }
        return;
      }
      if (value is Map) {
        final key =
            value['permission'] ??
            value['key'] ??
            value['name'] ??
            value['id_permission'];
        if (key != null) values.add(key.toString().trim());
        return;
      }
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return;
      if (text.startsWith('[') || text.startsWith('{')) {
        try {
          collect(jsonDecode(text));
          return;
        } catch (_) {
          // Bukan JSON valid; lanjut sebagai teks biasa.
        }
      }
      values.addAll(text.split(RegExp(r'[,\s]+')));
    }

    collect(raw);
    return values.where((value) => value.isNotEmpty).toList();
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
        final msgStr = message.toString();
        if (msgStr.contains('notNull Violation')) {
          final lower = msgStr.toLowerCase();
          if (lower.contains('nama')) return 'Nama role tidak boleh kosong.';
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
