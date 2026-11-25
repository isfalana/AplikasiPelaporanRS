import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/api_services.dart';
import '../../../data/services/master_data_store.dart';

/// Controller halaman Master Karyawan.
///
/// Data karyawan diambil dari endpoint `/users` beserta relasinya ke
/// `/unit` dan `/role`. Bila server belum terhubung, halaman memakai data
/// contoh dari [MasterDataStore] supaya tetap bisa dipakai dan tetap
/// terhubung dengan halaman master lainnya.
class MasterKaryawanController extends GetxController {
  // [MODIFIKASI] Endpoint diselaraskan dengan backend masterRoutes.js
  static const _usersEndpoint = '/master/users';
  static const _unitEndpoint = '/master/units';
  static const _roleEndpoint = '/master/roles';

  MasterDataStore get _store => MasterDataStore.ensure();

  /// Daftar karyawan milik store bersama.
  RxList<Map<String, dynamic>> get listKaryawan => _store.listKaryawan;

  /// Daftar unit dan role dari store bersama. Unit/role yang ditambahkan pada
  /// halaman master lain langsung muncul pada dropdown form ini.
  RxList<Map<String, dynamic>> get listUnit => _store.listUnit;
  RxList<Map<String, dynamic>> get listRole => _store.listRole;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final usingDemoData = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  /// Karyawan yang tampil setelah pencarian diterapkan.
  ///
  /// Pencarian mencakup NIK, nama, unit, dan role supaya relasi antar
  /// master tetap bisa ditelusuri dari satu kolom pencarian.
  List<Map<String, dynamic>> get filteredKaryawan {
    final keyword = searchQuery.value.trim().toLowerCase();
    if (keyword.isEmpty) return listKaryawan;
    return listKaryawan.where((karyawan) {
      return [
        karyawan['id_nik'],
        karyawan['nama_karyawan'],
        karyawan['nama_unit'],
        karyawan['nama_role'],
      ].any(
        (value) => value?.toString().toLowerCase().contains(keyword) ?? false,
      );
    }).toList();
  }

  Future<void> fetchAll() async {
    if (isLoading.value) return;
    isLoading.value = true;
    var usersDemo = false;
    try {
      final dio = await ApiService.getClient();

      try {
        final response = await dio.get(_usersEndpoint);
        final rows = _extractRows(response.data)
            .map(_normalizeKaryawan)
            .toList();
        if (rows.isNotEmpty) {
          listKaryawan.assignAll(rows);
        } else {
          usersDemo = true;
        }
      } catch (_) {
        usersDemo = true;
      }

      if (!usersDemo) {
        // Bila daftar referensi gagal dimuat, opsi tetap memakai data dari
        // store bersama agar tidak menghapus unit/role yang sudah ada.
        try {
          final response = await dio.get(_unitEndpoint);
          final rows = _extractRows(response.data).map(_normalizeUnit).toList();
          if (rows.isNotEmpty) listUnit.assignAll(rows);
        } catch (_) {
          // Pertahankan daftar unit dari store.
        }

        try {
          final response = await dio.get(_roleEndpoint);
          final rows = _extractRows(response.data).map(_normalizeRole).toList();
          if (rows.isNotEmpty) listRole.assignAll(rows);
        } catch (_) {
          // Pertahankan daftar role dari store.
        }
      }

      _hydrateRelations();
      _sort();
      usingDemoData.value = usersDemo;
    } catch (_) {
      usingDemoData.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Simpan karyawan baru (saat [originalNik] null) atau perubahan data.
  ///
  /// Password wajib diisi saat menambah karyawan. Saat mengubah data,
  /// password boleh dikosongkan yang berarti tidak diubah.
  /// Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> saveKaryawan({
    String? originalNik,
    required String idNik,
    required String namaKaryawan,
    required String idUnit,
    required String idRole,
    required String password,
  }) async {
    final nik = idNik.trim();
    final nama = namaKaryawan.trim();
    final unit = idUnit.trim();
    final role = idRole.trim();
    final pass = password.trim();
    final isCreate = originalNik == null;

    if (nik.isEmpty) return 'NIK karyawan wajib diisi.';
    if (nik.length > 50) return 'NIK karyawan maksimal 50 karakter.';
    if (nama.isEmpty) return 'Nama karyawan wajib diisi.';
    if (nama.length > 150) return 'Nama karyawan maksimal 150 karakter.';

    if (isCreate) {
      if (pass.isEmpty) return 'Password wajib diisi untuk karyawan baru.';
      if (pass.length < 6) return 'Password minimal 6 karakter.';
      if (listKaryawan.any(
        (karyawan) =>
            karyawan['id_nik']?.toString().toLowerCase() == nik.toLowerCase(),
      )) {
        return 'NIK "$nik" sudah digunakan karyawan lain.';
      }
    } else if (pass.isNotEmpty && pass.length < 6) {
      return 'Password minimal 6 karakter.';
    }

    final existing = isCreate
        ? null
        : listKaryawan.firstWhereOrNull(
            (karyawan) => karyawan['id_nik']?.toString() == originalNik,
          );

    final row = <String, dynamic>{
      'id_nik': isCreate ? nik : originalNik.trim(),
      'nama_karyawan': nama,
      'id_unit': unit,
      'id_role': role,
      'nama_unit': unitName(unit),
      'nama_role': roleName(role),
      // Simpan password agar karyawan baru bisa login pada sesi aplikasi ini.
      'password': isCreate
          ? pass
          : (pass.isNotEmpty ? pass : existing?['password']),
      'last_login': existing?['last_login'],
    };

    isSaving.value = true;
    try {
      // [MODIFIKASI] Selalu simpan karyawan ke backend API /master/users
      final dio = await ApiService.getClient();
      final data = <String, dynamic>{
        'id_nik': row['id_nik'],
        'nama_karyawan': nama,
        'id_unit': unit.isEmpty ? null : unit,
        'id_role': role.isEmpty ? null : role,
        if (isCreate || pass.isNotEmpty) 'password': pass,
      };
      if (isCreate) {
        await dio.post(_usersEndpoint, data: data);
      } else {
        await dio.put('$_usersEndpoint/${row['id_nik']}', data: data);
      }
      _applyLocally(originalNik: originalNik, row: row);
      await MasterDataStore.ensure().fetchFromBackend();
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menyimpan data karyawan.');
    } finally {
      isSaving.value = false;
    }
  }

  /// Hapus karyawan. Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> deleteKaryawan(String idNik) async {
    final nik = idNik.trim();
    if (nik.isEmpty) return 'NIK karyawan tidak valid.';

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('id_nik') == nik) {
      return 'Tidak dapat menghapus akun yang sedang digunakan.';
    }

    isSaving.value = true;
    try {
      // [MODIFIKASI] Hapus karyawan langsung dari database backend
      final dio = await ApiService.getClient();
      await dio.delete('$_usersEndpoint/$nik');
      listKaryawan.removeWhere(
        (karyawan) => karyawan['id_nik']?.toString() == nik,
      );
      listKaryawan.refresh();
      await MasterDataStore.ensure().fetchFromBackend();
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menghapus karyawan.');
    } finally {
      isSaving.value = false;
    }
  }

  /// Nama unit dari [idUnit], dipakai untuk kolom relasi.
  String unitName(String idUnit) {
    if (idUnit.trim().isEmpty) return '';
    final unit = listUnit.firstWhereOrNull(
      (item) => item['id_unit']?.toString() == idUnit,
    );
    final name = unit?['nama_unit']?.toString().trim() ?? '';
    return name.isEmpty ? idUnit : name;
  }

  /// Nama role dari [idRole], dipakai untuk kolom relasi.
  String roleName(String idRole) {
    if (idRole.trim().isEmpty) return '';
    final role = listRole.firstWhereOrNull(
      (item) => item['id_role']?.toString() == idRole,
    );
    final name = role?['nama_role']?.toString().trim() ?? '';
    return name.isEmpty ? idRole : name;
  }

  void _applyLocally({String? originalNik, required Map<String, dynamic> row}) {
    final index = originalNik == null
        ? -1
        : listKaryawan.indexWhere(
            (karyawan) => karyawan['id_nik']?.toString() == originalNik,
          );
    if (index == -1) {
      listKaryawan.add(row);
    } else {
      listKaryawan[index] = row;
    }
    _sort();
  }

  /// [MODIFIKASI] Lengkapi nama unit dan role pada baris karyawan tanpa memasukkan
  /// unit/role yang sudah non-aktif ke dalam listUnit/listRole.
  /// listUnit dan listRole murni hanya memuat master data aktif dari server agar form Tambah Karyawan
  /// hanya menampilkan unit yang aktif (misal hanya IT-Dev, bukan U-IT).
  void _hydrateRelations() {
    for (final karyawan in listKaryawan) {
      final unitId = karyawan['id_unit']?.toString().trim() ?? '';
      final roleId = karyawan['id_role']?.toString().trim() ?? '';
      final currentUnit = karyawan['nama_unit']?.toString().trim() ?? '';
      if (currentUnit.isEmpty || currentUnit == unitId) {
        karyawan['nama_unit'] = unitName(unitId);
      }
      final currentRole = karyawan['nama_role']?.toString().trim() ?? '';
      if (currentRole.isEmpty || currentRole == roleId) {
        karyawan['nama_role'] = roleName(roleId);
      }
    }

    listUnit.sort(
      (first, second) => (first['nama_unit']?.toString() ?? '').compareTo(
        second['nama_unit']?.toString() ?? '',
      ),
    );
    listRole.sort(
      (first, second) => (first['nama_role']?.toString() ?? '').compareTo(
        second['nama_role']?.toString() ?? '',
      ),
    );
    listUnit.refresh();
    listRole.refresh();
  }

  void _sort() {
    listKaryawan.sort((first, second) {
      final firstName = first['nama_karyawan']?.toString().toLowerCase() ?? '';
      final secondName =
          second['nama_karyawan']?.toString().toLowerCase() ?? '';
      return firstName.compareTo(secondName);
    });
    listKaryawan.refresh();
  }

  Map<String, dynamic> _normalizeKaryawan(Map<String, dynamic> row) {
    final unitData = _asMap(row['unitData'] ?? row['unit_data'] ?? row['unit']);
    final roleData = _asMap(row['roleData'] ?? row['role_data'] ?? row['role']);

    return {
      'id_nik': (row['id_nik'] ?? row['idNik'] ?? row['nik'] ?? '').toString(),
      'nama_karyawan':
          (row['nama_karyawan'] ?? row['namaKaryawan'] ?? row['nama'] ?? '')
              .toString(),
      'id_unit': (row['id_unit'] ?? unitData?['id_unit'] ?? '').toString(),
      'id_role': (row['id_role'] ?? roleData?['id_role'] ?? '').toString(),
      'nama_unit': (unitData?['nama_unit'] ?? row['nama_unit'] ?? '')
          .toString(),
      'nama_role': (roleData?['nama_role'] ?? row['nama_role'] ?? '')
          .toString(),
      'last_login': row['last_login'] ?? row['lastLogin'],
    };
  }

  Map<String, dynamic> _normalizeUnit(Map<String, dynamic> row) {
    return {
      'id_unit': (row['id_unit'] ?? row['idUnit'] ?? '').toString(),
      'nama_unit': (row['nama_unit'] ?? row['namaUnit'] ?? '').toString(),
    };
  }

  Map<String, dynamic> _normalizeRole(Map<String, dynamic> row) {
    final id = (row['id_role'] ?? row['idRole'] ?? '').toString();
    // [MODIFIKASI] Ambil permissions dari row backend atau pertahankan permissions yang sudah ada di store
    // agar data hak akses role tidak terhapus saat halaman Master Karyawan dimuat.
    final permsRaw =
        row['permissions'] ??
        row['permission'] ??
        row['hak_akses'] ??
        row['hakAkses'];
    List<String> permissions = [];
    if (permsRaw != null) {
      permissions = MasterDataStore.parsePermissions(permsRaw);
    } else {
      final existingRole = _store.listRole.firstWhereOrNull(
        (r) => r['id_role']?.toString() == id,
      );
      if (existingRole != null && existingRole['permissions'] is List) {
        permissions = List<String>.from(existingRole['permissions'] as List);
      }
    }

    return {
      'id_role': id,
      'nama_role': (row['nama_role'] ?? row['namaRole'] ?? '').toString(),
      'permissions': permissions,
      'created_at': row['created_at'] ?? row['createdAt'],
      'updated_at': row['updated_at'] ?? row['updatedAt'],
      'deleted_at': row['deleted_at'] ?? row['deletedAt'],
    };
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    dynamic rows = payload;
    if (payload is Map) {
      rows =
          payload['data'] ??
          payload['rows'] ??
          payload['users'] ??
          payload['units'] ??
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
}
