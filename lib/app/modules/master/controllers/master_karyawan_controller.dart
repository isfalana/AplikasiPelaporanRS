import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/api_services.dart';

/// Controller halaman Master Karyawan.
///
/// Data karyawan diambil dari endpoint `/users` beserta relasinya ke
/// `/unit` dan `/role`. Bila server belum terhubung, halaman memakai data
/// contoh supaya tetap bisa dipakai.
class MasterKaryawanController extends GetxController {
  static const _usersEndpoint = '/users';
  static const _unitEndpoint = '/unit';
  static const _roleEndpoint = '/role';

  final listKaryawan = <Map<String, dynamic>>[].obs;
  final listUnit = <Map<String, dynamic>>[].obs;
  final listRole = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final usingDemoData = false.obs;
  final searchQuery = ''.obs;

  /// Apakah daftar karyawan berasal dari server. Bila false, perubahan data
  /// hanya disimpan di memori (mode contoh).
  bool _usersFromServer = false;

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
    _usersFromServer = false;
    try {
      final dio = await ApiService.getClient();

      try {
        final response = await dio.get(_usersEndpoint);
        listKaryawan.assignAll(
          _extractRows(response.data).map(_normalizeKaryawan),
        );
        _usersFromServer = true;
      } catch (_) {
        usersDemo = true;
        listKaryawan.assignAll(_demoKaryawan());
      }

      if (usersDemo) {
        // Data contoh harus konsisten, jadi unit dan role ikut memakai
        // daftar contoh meskipun endpoint-nya sempat merespons.
        listUnit.assignAll(_demoUnit());
        listRole.assignAll(_demoRole());
      } else {
        // Bila daftar referensi gagal dimuat, opsi tetap dilengkapi dari
        // relasi unitData/roleData pada data karyawan.
        try {
          final response = await dio.get(_unitEndpoint);
          listUnit.assignAll(_extractRows(response.data).map(_normalizeUnit));
        } catch (_) {
          listUnit.clear();
        }

        try {
          final response = await dio.get(_roleEndpoint);
          listRole.assignAll(_extractRows(response.data).map(_normalizeRole));
        } catch (_) {
          listRole.clear();
        }
      }

      _hydrateRelations();
      _sort();
      usingDemoData.value = usersDemo;
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
      'last_login': existing?['last_login'],
    };

    isSaving.value = true;
    try {
      if (_usersFromServer) {
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
      }
      _applyLocally(originalNik: originalNik, row: row);
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
      if (_usersFromServer) {
        final dio = await ApiService.getClient();
        await dio.delete('$_usersEndpoint/$nik');
      }
      listKaryawan.removeWhere(
        (karyawan) => karyawan['id_nik']?.toString() == nik,
      );
      listKaryawan.refresh();
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menghapus karyawan.');
    } finally {
      isSaving.value = false;
    }
  }

  /// NIK otomatis berikutnya berdasarkan NIK berurutan yang sudah ada.
  ///
  /// Format `NIK-` + nomor 3 digit, misalnya `NIK-005`. Bila daftar masih
  /// kosong atau tidak ada NIK berformat angka, nomor dimulai dari 001.
  String generateNik() {
    var highest = 0;
    final pattern = RegExp(r'^NIK-(\d+)$', caseSensitive: false);
    for (final karyawan in listKaryawan) {
      final match = pattern.firstMatch(
        karyawan['id_nik']?.toString().trim() ?? '',
      );
      final number = int.tryParse(match?.group(1) ?? '');
      if (number != null && number > highest) highest = number;
    }
    return 'NIK-${(highest + 1).toString().padLeft(3, '0')}';
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

  /// Lengkapi nama unit/role dan pastikan pilihan dropdown memuat semua
  /// relasi yang sedang dipakai karyawan.
  void _hydrateRelations() {
    final unitIds = listUnit
        .map((unit) => unit['id_unit']?.toString() ?? '')
        .toSet();
    final roleIds = listRole
        .map((role) => role['id_role']?.toString() ?? '')
        .toSet();

    for (final karyawan in listKaryawan) {
      final unitId = karyawan['id_unit']?.toString().trim() ?? '';
      if (unitId.isNotEmpty && !unitIds.contains(unitId)) {
        listUnit.add({
          'id_unit': unitId,
          'nama_unit': _displayOrId(karyawan['nama_unit'], unitId),
        });
        unitIds.add(unitId);
      }

      final roleId = karyawan['id_role']?.toString().trim() ?? '';
      if (roleId.isNotEmpty && !roleIds.contains(roleId)) {
        listRole.add({
          'id_role': roleId,
          'nama_role': _displayOrId(karyawan['nama_role'], roleId),
        });
        roleIds.add(roleId);
      }
    }

    for (final karyawan in listKaryawan) {
      final unitId = karyawan['id_unit']?.toString() ?? '';
      final roleId = karyawan['id_role']?.toString() ?? '';
      karyawan['nama_unit'] = unitName(unitId);
      karyawan['nama_role'] = roleName(roleId);
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

  String _displayOrId(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
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
    return {
      'id_role': (row['id_role'] ?? row['idRole'] ?? '').toString(),
      'nama_role': (row['nama_role'] ?? row['namaRole'] ?? '').toString(),
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

  List<Map<String, dynamic>> _demoKaryawan() {
    return [
      {
        'id_nik': 'NIK-001',
        'nama_karyawan': 'dr. Enung Sp.PD',
        'id_unit': 'UNIT-IGD',
        'id_role': 'ROLE-DOKTER',
        'last_login': '2026-11-11T08:24:00',
      },
      {
        'id_nik': 'NIK-002',
        'nama_karyawan': 'Rina Kartika',
        'id_unit': 'UNIT-UMUM',
        'id_role': 'ROLE-ADMIN',
        'last_login': '2026-11-12T07:05:00',
      },
      {
        'id_nik': 'NIK-003',
        'nama_karyawan': 'Budi Santoso',
        'id_unit': 'UNIT-SDM',
        'id_role': 'ROLE-PETUGAS',
        'last_login': null,
      },
      {
        'id_nik': 'NIK-004',
        'nama_karyawan': 'Andi Pratama',
        'id_unit': 'UNIT-IT',
        'id_role': 'ROLE-TEKNISI',
        'last_login': '2026-11-10T16:40:00',
      },
    ];
  }

  List<Map<String, dynamic>> _demoUnit() {
    return [
      {'id_unit': 'UNIT-UMUM', 'nama_unit': 'Unit Umum'},
      {'id_unit': 'UNIT-IGD', 'nama_unit': 'Instalasi Gawat Darurat'},
      {'id_unit': 'UNIT-IT', 'nama_unit': 'Teknologi Informasi'},
      {'id_unit': 'UNIT-SDM', 'nama_unit': 'Sumber Daya Manusia'},
    ];
  }

  List<Map<String, dynamic>> _demoRole() {
    return [
      {'id_role': 'ROLE-ADMIN', 'nama_role': 'Administrator'},
      {'id_role': 'ROLE-DOKTER', 'nama_role': 'Dokter'},
      {'id_role': 'ROLE-PETUGAS', 'nama_role': 'Petugas'},
      {'id_role': 'ROLE-TEKNISI', 'nama_role': 'Teknisi'},
    ];
  }
}
