import 'dart:convert';
import 'package:get/get.dart';
import 'api_services.dart';

/// Penyimpanan master data di memori untuk simulasi antar halaman.
///
/// Semua halaman master (unit, role, kategori, karyawan) memakai instance
/// yang sama. Data yang ditambahkan pada satu halaman langsung terlihat pada
/// pilihan di halaman lain, misalnya unit baru pada dropdown unit di form
/// karyawan. Data hanya hidup selama aplikasi berjalan dan belum disimpan ke
/// database.
class MasterDataStore extends GetxController {
  MasterDataStore({bool seedDemo = true}) {
    if (seedDemo) _seedDemoData();
  }

  /// Wildcard: role dengan izin ini boleh mengakses semua fitur.
  static const wildcardPermission = '*';

  /// Katalog hak akses yang bisa diberikan ke sebuah role.
  ///
  /// Dikelompokkan supaya dialog Master Role mudah dibaca. Setiap entri
  /// memiliki `key` yang dipakai di kode dan `label` yang tampil ke pengguna.
  static const permissionGroups = <String, List<Map<String, String>>>{
    'Laporan': [
      {'key': 'laporan.lihat', 'label': 'Lihat laporan'},
      {'key': 'laporan.buat', 'label': 'Buat laporan'},
      {'key': 'laporan.ubah', 'label': 'Ubah laporan'},
      {'key': 'laporan.hapus', 'label': 'Hapus laporan'},
      {'key': 'laporan.validasi', 'label': 'Validasi laporan selesai'},
      {'key': 'laporan.buka_kembali', 'label': 'Buka kembali laporan Done'},
    ],
    'Tindakan': [
      {'key': 'tindakan.lihat', 'label': 'Lihat pesan tindakan'},
      {'key': 'tindakan.ubah', 'label': 'Simpan tindak lanjut'},
    ],
    'Report': [
      {'key': 'report.lihat', 'label': 'Lihat rekap report'},
      {'key': 'report.export', 'label': 'Export PDF/Excel'},
    ],
    'Master Data': [
      {'key': 'master.unit', 'label': 'Master Unit'},
      {'key': 'master.karyawan', 'label': 'Master Karyawan'},
      {'key': 'master.kategori', 'label': 'Master Kategori'},
      {'key': 'master.template', 'label': 'Master Template Tindakan'},
      {'key': 'master.role', 'label': 'Master Role'},
    ],
  };

  /// Seluruh key hak akses yang tersedia.
  static final Set<String> allPermissions = permissionGroups.values
      .expand((group) => group)
      .map((item) => item['key']!)
      .toSet();

  /// Label yang ramah dibaca untuk sebuah key hak akses.
  static String permissionLabel(String key) {
    for (final group in permissionGroups.values) {
      for (final item in group) {
        if (item['key'] == key) return item['label']!;
      }
    }
    return key;
  }

  final listUnit = <Map<String, dynamic>>[].obs;
  final listRole = <Map<String, dynamic>>[].obs;
  final listKategori = <Map<String, dynamic>>[].obs;
  final listKaryawan = <Map<String, dynamic>>[].obs;
  final listPrioritas = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // [MODIFIKASI] Otomatis ambil data terbaru dari backend saat store diinisialisasi
    fetchFromBackend();
  }

  /// [MODIFIKASI] Mengambil data master lengkap dari backend database
  /// Mengambil data unit, kategori, role, karyawan/users, dan prioritas
  Future<void> fetchFromBackend() async {
    try {
      final dio = await ApiService.getClient();
      final responses = await Future.wait([
        dio.get('/master/units'),
        dio.get('/master/kategoris'),
        dio.get('/master/roles'),
        dio.get('/master/users'),
        dio.get('/master/prioritas'),
      ]);

      if (responses[0].statusCode == 200 && responses[0].data != null) {
        final data = responses[0].data['data'];
        if (data is List) {
          listUnit.assignAll(data.map((e) => Map<String, dynamic>.from(e)).toList());
        }
      }
      if (responses[1].statusCode == 200 && responses[1].data != null) {
        final data = responses[1].data['data'];
        if (data is List) {
          // [MODIFIKASI] Normalisasi agar nama_kategori dan jenis_kategori saling terisi
          final items = data.map((e) {
            final m = Map<String, dynamic>.from(e);
            final name = m['nama_kategori'] ?? m['jenis_kategori'] ?? '';
            m['nama_kategori'] = name;
            m['jenis_kategori'] = name;
            return m;
          }).toList();
          listKategori.assignAll(items);
        }
      }
      if (responses[2].statusCode == 200 && responses[2].data != null) {
        final data = responses[2].data['data'];
        if (data is List) {
          // [MODIFIKASI] Normalisasi field permissions agar selalu berupa List<String> di memori
          final roles = data.map((e) {
            final m = Map<String, dynamic>.from(e);
            m['permissions'] = parsePermissions(m['permissions']);
            return m;
          }).toList();
          listRole.assignAll(roles);
        }
      }
      if (responses[3].statusCode == 200 && responses[3].data != null) {
        final data = responses[3].data['data'];
        if (data is List) {
          // [MODIFIKASI] Filter karyawan aktif (tidak di-soft delete) untuk listKaryawan,
          // sekaligus daftarkan nama historis agar riwayat laporan lama tetap menampilkan nama aslinya
          final activeUsers = <Map<String, dynamic>>[];
          for (final item in data) {
            if (item is Map) {
              final m = Map<String, dynamic>.from(item);
              final nik = m['id_nik']?.toString().trim() ?? '';
              final name = m['nama_karyawan']?.toString().trim() ?? '';
              if (nik.isNotEmpty && name.isNotEmpty) {
                registerEmployeeName(nik, name);
              }
              if (m['deleted_at'] == null) {
                activeUsers.add(m);
              }
            }
          }
          listKaryawan.assignAll(activeUsers);
        }
      }
      // [MODIFIKASI] Parsing data master prioritas dari backend
      if (responses[4].statusCode == 200 && responses[4].data != null) {
        final data = responses[4].data['data'];
        if (data is List) {
          listPrioritas.assignAll(data.map((e) => Map<String, dynamic>.from(e)).toList());
        }
      }
    } catch (_) {
      // Biarkan data demo sebagai cadangan jika offline
    }
  }

  /// Ambil store yang sama untuk seluruh halaman.
  ///
  /// Store didaftarkan sebagai controller permanen supaya tetap hidup saat
  /// berpindah halaman, tetapi tetap dibersihkan oleh `Get.reset()` pada
  /// pengujian sehingga setiap test mendapat data awal yang bersih.
  static MasterDataStore ensure() {
    if (Get.isRegistered<MasterDataStore>()) {
      return Get.find<MasterDataStore>();
    }
    return Get.put(MasterDataStore(), permanent: true);
  }

  // [MODIFIKASI] Cache nama unit historis agar unit yang sudah di-soft-delete tetap menampilkan nama aslinya bukan ID
  final Map<String, String> _historicalUnitNames = {};

  /// Salinan read-only dari cache unit historis
  Map<String, String> get historicalUnitNames => Map.unmodifiable(_historicalUnitNames);

  /// Daftarkan pemetaan ID unit ke nama unit historis
  void registerUnitName(String idUnit, String unitName) {
    final id = idUnit.trim();
    final name = unitName.trim();
    if (id.isNotEmpty && name.isNotEmpty && id != name) {
      _historicalUnitNames[id] = name;
    }
  }

  /// Nama unit dari [idUnit]. Mengembalikan [idUnit] bila tidak ditemukan.
  String unitName(String idUnit) {
    final id = idUnit.trim();
    if (id.isEmpty) return '';
    final unit = _firstWhere(listUnit, 'id_unit', id);
    final name = unit?['nama_unit']?.toString().trim() ?? '';
    if (name.isNotEmpty && name != id) return name;

    // [MODIFIKASI] Periksa cache unit historis bila unit telah di-soft-delete
    if (_historicalUnitNames.containsKey(id)) {
      return _historicalUnitNames[id]!;
    }

    // [MODIFIKASI] Cari juga di data karyawan yang mungkin memiliki relasi nama_unit historis
    for (final k in listKaryawan) {
      if (k['id_unit']?.toString().trim() == id) {
        final kUnitName = k['nama_unit']?.toString().trim() ?? '';
        if (kUnitName.isNotEmpty && kUnitName != id) {
          _historicalUnitNames[id] = kUnitName;
          return kUnitName;
        }
      }
    }
    return id;
  }

  /// Nama role dari [idRole]. Mengembalikan [idRole] bila tidak ditemukan.
  String roleName(String idRole) {
    final id = idRole.trim();
    if (id.isEmpty) return '';
    final role = _firstWhere(listRole, 'id_role', id);
    final name = role?['nama_role']?.toString().trim() ?? '';
    return name.isEmpty ? id : name;
  }

  /// Nama kategori dari [idKategori]. Mengembalikan [idKategori] bila tidak
  /// ditemukan, supaya data lama yang masih memakai ID tetap tampil masuk akal.
  String kategoriName(String idKategori) {
    final id = idKategori.trim();
    if (id.isEmpty) return '';
    final kategori = _firstWhere(listKategori, 'id_kategori', id);
    final name = kategori?['nama_kategori']?.toString().trim() ??
        kategori?['jenis_kategori']?.toString().trim() ??
        '';
    return name.isEmpty ? id : name;
  }

  // [MODIFIKASI] Cache nama karyawan historis agar karyawan yang sudah di-soft-delete tetap menampilkan namanya
  final Map<String, String> _historicalEmployeeNames = {};

  /// Salinan read-only dari cache nama karyawan historis
  Map<String, String> get historicalEmployeeNames => Map.unmodifiable(_historicalEmployeeNames);

  /// Daftarkan pemetaan NIK ke nama karyawan historis
  void registerEmployeeName(String nik, String employeeName) {
    final k = nik.trim();
    final n = employeeName.trim();
    if (k.isNotEmpty && n.isNotEmpty && k != n) {
      _historicalEmployeeNames[k] = n;
    }
  }

  /// Data karyawan dari [nik], atau null bila tidak ditemukan.
  Map<String, dynamic>? employee(String nik) {
    final key = nik.trim();
    if (key.isEmpty) return null;
    return _firstWhere(listKaryawan, 'id_nik', key, ignoreCase: true);
  }

  /// Nama karyawan dari [nik]. Mengembalikan [nik] bila tidak ditemukan.
  String employeeName(String nik) {
    final key = nik.trim();
    if (key.isEmpty) return '';
    final name = employee(key)?['nama_karyawan']?.toString().trim() ?? '';
    if (name.isNotEmpty && name != key) return name;
    if (_historicalEmployeeNames.containsKey(key)) {
      return _historicalEmployeeNames[key]!;
    }
    return key;
  }

  /// ID unit milik karyawan [nik], atau string kosong bila tidak ditemukan.
  String employeeUnit(String nik) {
    return employee(nik)?['id_unit']?.toString().trim() ?? '';
  }

  /// ID role milik karyawan [nik], atau string kosong bila tidak ditemukan.
  String employeeRole(String nik) {
    return employee(nik)?['id_role']?.toString().trim() ?? '';
  }

  /// Daftar hak akses milik role [idRole].
  ///
  /// Role dengan wildcard `*` dianggap memiliki seluruh hak akses. Role lama
  /// bernama `superadmin` juga otomatis mendapat semua akses agar data yang
  /// sudah ada sebelum fitur permission tetap berjalan.
  Set<String> permissionsForRole(String idRole) {
    final role = _firstWhere(listRole, 'id_role', idRole.trim());
    if (role == null) return <String>{};

    final raw = role['permissions'];
    final values = <String>{};
    if (raw is Iterable) {
      for (final item in raw) {
        if (item is Map) {
          final key =
              item['permission'] ??
              item['key'] ??
              item['name'] ??
              item['id_permission'];
          if (key != null) values.add(key.toString().trim());
        } else {
          values.add(item.toString().trim());
        }
      }
    } else if (raw != null) {
      values.addAll(raw.toString().split(RegExp(r'[,\s]+')));
    }

    // [MODIFIKASI] Wildcard permission '*' memberikan seluruh hak akses
    if (values.contains(wildcardPermission)) return allPermissions.toSet();
    final roleNameLower = role['nama_role']?.toString().trim().toLowerCase() ?? '';
    final roleId = role['id_role']?.toString().trim() ?? '';

    // [MODIFIKASI] Hanya gunakan default permission jika role belum pernah diatur hak aksesnya sama sekali (raw == null)
    if (raw == null) {
      if (roleId == 'R-01' || roleNameLower == 'admin' || roleNameLower == 'superadmin') {
        return allPermissions.toSet();
      }
      return {
        'laporan.lihat',
        'laporan.buat',
        'laporan.ubah',
        'laporan.validasi',
        'laporan.buka_kembali',
        'tindakan.lihat',
        'tindakan.ubah',
        'report.lihat',
      };
    }

    // [MODIFIKASI] Bila role telah diatur hak aksesnya (raw != null), kembalikan HANYA permission yang aktif (ada di values).
    // Bila checkbox non-aktif (false), permission tersebut tidak ada di values sehingga tidak mendapatkan hak akses.
    return allPermissions.where(values.contains).toSet();
  }

  // [MODIFIKASI] Helper static untuk parsing permissions dari berbagai format database backend
  static List<String> parsePermissions(dynamic raw) {
    if (raw == null) return [];
    if (raw is Iterable) {
      return raw
          .map((e) {
            if (e is Map) {
              return (e['permission'] ?? e['key'] ?? e['name'] ?? e['id_permission'])?.toString();
            }
            return e?.toString();
          })
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final text = raw.toString().trim();
    if (text.startsWith('[') || text.startsWith('{')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Iterable) {
          return decoded.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        }
      } catch (_) {}
    }
    return text.split(RegExp(r'[,\s]+')).where((s) => s.isNotEmpty).toList();
  }

  /// Daftar hak akses milik karyawan [nik] berdasarkan role-nya.
  Set<String> permissionsForEmployee(String nik) {
    return permissionsForRole(employeeRole(nik));
  }

  /// Apakah karyawan [nik] memiliki hak akses [permission].
  bool hasPermission(String nik, String permission) {
    final permissions = permissionsForEmployee(nik);
    return permissions.contains(wildcardPermission) ||
        permissions.contains(permission);
  }

  Map<String, dynamic>? _firstWhere(
    List<Map<String, dynamic>> rows,
    String key,
    String value, {
    bool ignoreCase = false,
  }) {
    final needle = ignoreCase ? value.toLowerCase() : value;
    for (final row in rows) {
      final current = row[key]?.toString().trim() ?? '';
      final candidate = ignoreCase ? current.toLowerCase() : current;
      if (candidate == needle) return row;
    }
    return null;
  }

  // [MODIFIKASI] Sinkronisasi fallback data demo awal dengan data seeder PostgreSQL backend
  void _seedDemoData() {
    listUnit.assignAll([
      {'id_unit': 'U-IT', 'nama_unit': 'Information Technology'},
      {'id_unit': 'U-PENDAFTARAN', 'nama_unit': 'Pendaftaran & Rekam Medis'},
      {'id_unit': 'U-UMUM', 'nama_unit': 'Umum & Fasilitas'},
    ]);

    listRole.assignAll([
      {
        'id_role': 'R-01',
        'nama_role': 'Admin',
        'permissions': [wildcardPermission],
        'created_at': '2026-10-02T08:10:00',
      },
      {
        'id_role': 'R-02',
        'nama_role': 'User',
        'permissions': [
          'laporan.lihat',
          'laporan.buat',
          'laporan.ubah',
          'laporan.validasi',
          'laporan.buka_kembali',
          'tindakan.lihat',
          'tindakan.ubah',
          'report.lihat',
        ],
        'created_at': '2026-10-02T08:12:00',
      },
    ]);

    listKategori.assignAll([
      {
        'id_kategori': 'KAT-01',
        'nama_kategori': 'Perbaikan / Maintenance',
        'jenis_kategori': 'Perbaikan / Maintenance',
        'created_at': '2026-10-02T08:15:00',
      },
      {
        'id_kategori': 'KAT-02',
        'nama_kategori': 'Pengadaan Barang',
        'jenis_kategori': 'Pengadaan Barang',
        'created_at': '2026-10-02T08:20:00',
      },
      {
        'id_kategori': 'KAT-03',
        'nama_kategori': 'Komplain Layanan',
        'jenis_kategori': 'Komplain Layanan',
        'created_at': '2026-10-03T09:05:00',
      },
    ]);

    listPrioritas.assignAll([
      {'id_prioritas': 'P-01', 'nama_prioritas': 'Kritis', 'urutan': 1, 'batas_sisa_hari': 0},
      {'id_prioritas': 'P-02', 'nama_prioritas': 'Tinggi', 'urutan': 2, 'batas_sisa_hari': 1},
      {'id_prioritas': 'P-03', 'nama_prioritas': 'Sedang', 'urutan': 3, 'batas_sisa_hari': 3},
      {'id_prioritas': 'P-04', 'nama_prioritas': 'Rendah', 'urutan': 4, 'batas_sisa_hari': 7},
    ]);

    listKaryawan.assignAll([
      {
        'id_nik': 'NIK-001',
        'nama_karyawan': 'Admin IT',
        'id_unit': 'U-IT',
        'id_role': 'R-01',
        'last_login': '2026-11-19T08:00:00',
      },
      {
        'id_nik': 'NIK-002',
        'nama_karyawan': 'Siti Aminah',
        'id_unit': 'U-PENDAFTARAN',
        'id_role': 'R-02',
        'last_login': '2026-11-19T08:00:00',
      },
      {
        'id_nik': 'NIK-003',
        'nama_karyawan': 'Budi Teknisi',
        'id_unit': 'U-UMUM',
        'id_role': 'R-02',
        'last_login': null,
      },
      {
        'id_nik': 'NIK-004',
        'nama_karyawan': 'Andi IT',
        'id_unit': 'U-IT',
        'id_role': 'R-02',
        'last_login': '2026-11-19T08:00:00',
      },
    ]);
  }
}
