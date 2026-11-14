import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../data/services/api_services.dart';

/// Controller halaman Master Template Tindakan.
///
/// Template dipakai oleh halaman Tindakan sebagai pilihan cepat saat penindak
/// mengisi daftar tindak lanjut. Data diambil dari endpoint
/// `/template-tindakan` pada backend. Bila server belum terhubung, halaman
/// memakai data contoh supaya tetap bisa dipakai.
class MasterTemplateTindakanController extends GetxController {
  static const _endpoint = '/template-tindakan';

  final listTemplate = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final usingDemoData = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTemplate();
  }

  /// Template yang tampil setelah pencarian diterapkan.
  List<Map<String, dynamic>> get filteredTemplate {
    final keyword = searchQuery.value.trim().toLowerCase();
    if (keyword.isEmpty) return listTemplate;
    return listTemplate.where((template) {
      final names = [
        template['id_template'],
        template['nama_template'],
        ..._actionDescriptions(template['list_tindakan']),
      ];
      return names.any(
        (value) => value.toLowerCase().contains(keyword) ?? false,
      );
    }).toList();
  }

  /// Buat ID template baru yang belum dipakai, misalnya `TPL-01`.
  String generateTemplateId() {
    final used = listTemplate
        .map(
          (template) => template['id_template']?.toString().toUpperCase() ?? '',
        )
        .toSet();
    var next = 1;
    for (final id in used) {
      final match = RegExp(r'^TPL-(\d+)$').firstMatch(id);
      final number = int.tryParse(match?.group(1) ?? '');
      if (number != null && number >= next) next = number + 1;
    }

    var candidate = 'TPL-${next.toString().padLeft(2, '0')}';
    while (used.contains(candidate)) {
      next++;
      candidate = 'TPL-${next.toString().padLeft(2, '0')}';
    }
    return candidate;
  }

  Future<void> fetchTemplate() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get(_endpoint);
      listTemplate.assignAll(_extractRows(response.data).map(_normalize));
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

  /// Simpan template baru (saat [originalId] null) atau perubahan template.
  /// ID template dibuat otomatis untuk template baru.
  /// Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> saveTemplate({
    String? originalId,
    required String namaTemplate,
    required List<String> listTindakan,
  }) async {
    final nama = namaTemplate.trim();
    if (nama.isEmpty) return 'Nama template wajib diisi.';
    if (nama.length > 255) return 'Nama template maksimal 255 karakter.';
    final actions = listTindakan
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (actions.isEmpty) {
      return 'Tambahkan minimal satu tindakan pada template.';
    }

    final isCreate = originalId == null;
    final id = isCreate ? generateTemplateId() : originalId.trim();
    if (id.isEmpty) return 'ID template tidak valid.';

    final now = DateTime.now().toIso8601String();
    Map<String, dynamic>? existing;
    if (!isCreate) {
      final index = listTemplate.indexWhere(
        (template) => template['id_template']?.toString() == originalId,
      );
      if (index != -1) existing = listTemplate[index];
    }
    final detail = actions
        .map(
          (description) => <String, dynamic>{'deskripsi_tindakan': description},
        )
        .toList();
    final row = <String, dynamic>{
      'id_template': id,
      'nama_template': nama,
      'list_tindakan': detail,
      'created_at': existing?['created_at'] ?? now,
      'updated_at': now,
    };

    isSaving.value = true;
    try {
      if (!usingDemoData.value) {
        final dio = await ApiService.getClient();
        final data = <String, dynamic>{
          'id_template': id,
          'nama_template': nama,
          'list_tindakan': detail,
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
      return _errorMessage(error, 'Gagal menyimpan template.');
    } finally {
      isSaving.value = false;
    }
  }

  /// Hapus template. Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> deleteTemplate(String idTemplate) async {
    final id = idTemplate.trim();
    if (id.isEmpty) return 'ID template tidak valid.';

    isSaving.value = true;
    try {
      if (!usingDemoData.value) {
        final dio = await ApiService.getClient();
        await dio.delete('$_endpoint/$id');
      }
      listTemplate.removeWhere(
        (template) => template['id_template']?.toString() == id,
      );
      listTemplate.refresh();
      return null;
    } on DioException catch (error) {
      return _errorMessage(error, 'Gagal menghapus template.');
    } finally {
      isSaving.value = false;
    }
  }

  void _applyLocally({String? originalId, required Map<String, dynamic> row}) {
    final index = originalId == null
        ? -1
        : listTemplate.indexWhere(
            (template) => template['id_template']?.toString() == originalId,
          );
    if (index == -1) {
      listTemplate.add(row);
    } else {
      listTemplate[index] = row;
    }
    _sort();
  }

  void _useDemoData() {
    usingDemoData.value = true;
    if (listTemplate.isEmpty) {
      listTemplate.assignAll(_demoTemplate());
      _sort();
    }
  }

  void _sort() {
    listTemplate.sort((first, second) {
      final firstId = first['id_template']?.toString().toLowerCase() ?? '';
      final secondId = second['id_template']?.toString().toLowerCase() ?? '';
      return firstId.compareTo(secondId);
    });
    listTemplate.refresh();
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> row) {
    return {
      'id_template': (row['id_template'] ?? row['idTemplate'] ?? '').toString(),
      'nama_template': (row['nama_template'] ?? row['namaTemplate'] ?? '')
          .toString(),
      'list_tindakan': _normalizeActions(
        row['list_tindakan'] ?? row['listTindakan'],
      ),
      'created_at': row['created_at'] ?? row['createdAt'],
      'updated_at': row['updated_at'] ?? row['updatedAt'],
    };
  }

  /// Menyeragamkan isi `list_tindakan` menjadi list of map
  /// `{'deskripsi_tindakan': ...}`. Backend boleh menyimpan string biasa
  /// maupun object, keduanya diterima.
  List<dynamic> _normalizeActions(dynamic value) {
    if (value is! List) return [];
    return value.map((item) {
      if (item is Map) {
        return <String, dynamic>{
          'deskripsi_tindakan':
              (item['deskripsi_tindakan'] ??
                      item['deskripsiTindakan'] ??
                      item['nama_tindakan'] ??
                      item)
                  .toString(),
        };
      }
      return <String, dynamic>{'deskripsi_tindakan': item.toString()};
    }).toList();
  }

  List<String> _actionDescriptions(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) {
          return (item['deskripsi_tindakan'] ?? item['deskripsiTindakan'] ?? '')
              .toString();
        })
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    dynamic rows = payload;
    if (payload is Map) {
      rows =
          payload['data'] ??
          payload['rows'] ??
          payload['templateTindakan'] ??
          payload['templates'] ??
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

  List<Map<String, dynamic>> _demoTemplate() {
    return [
      {
        'id_template': 'TPL-01',
        'nama_template': 'Perbaikan AC',
        'list_tindakan': [
          {'deskripsi_tindakan': 'Cek suhu dan tekanan freon AC'},
          {'deskripsi_tindakan': 'Bersihkan filter dan evaporator'},
          {'deskripsi_tindakan': 'Uji ulang suhu ruangan'},
        ],
        'created_at': '2026-10-05T08:15:00',
      },
      {
        'id_template': 'TPL-02',
        'nama_template': 'Gangguan Jaringan LAN',
        'list_tindakan': [
          {'deskripsi_tindakan': 'Cek kabel dan switch jaringan'},
          {'deskripsi_tindakan': 'Restart perangkat jaringan'},
          {'deskripsi_tindakan': 'Konfirmasi koneksi ke pengguna'},
        ],
        'created_at': '2026-10-06T09:30:00',
      },
      {
        'id_template': 'TPL-03',
        'nama_template': 'Pembersihan Fasilitas',
        'list_tindakan': [
          {'deskripsi_tindakan': 'Lakukan pembersihan menyeluruh'},
          {'deskripsi_tindakan': 'Foto kondisi sebelum dan sesudah'},
        ],
        'created_at': '2026-10-07T13:05:00',
      },
    ];
  }
}
