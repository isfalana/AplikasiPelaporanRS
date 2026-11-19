import 'package:get/get.dart';

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

  /// Nama unit dari [idUnit]. Mengembalikan [idUnit] bila tidak ditemukan.
  String unitName(String idUnit) {
    final id = idUnit.trim();
    if (id.isEmpty) return '';
    final unit = _firstWhere(listUnit, 'id_unit', id);
    final name = unit?['nama_unit']?.toString().trim() ?? '';
    return name.isEmpty ? id : name;
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
    final name = kategori?['jenis_kategori']?.toString().trim() ?? '';
    return name.isEmpty ? id : name;
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
    return name.isEmpty ? key : name;
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

    if (values.contains(wildcardPermission)) return allPermissions.toSet();
    if (values.isEmpty &&
        role['nama_role']?.toString().trim().toLowerCase() == 'superadmin') {
      return allPermissions.toSet();
    }
    return allPermissions.where(values.contains).toSet();
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

  void _seedDemoData() {
    listUnit.assignAll([
      {'id_unit': 'UNIT-UMUM', 'nama_unit': 'Unit Umum'},
      {'id_unit': 'UNIT-IGD', 'nama_unit': 'Instalasi Gawat Darurat'},
      {'id_unit': 'UNIT-IT', 'nama_unit': 'Teknologi Informasi'},
      {'id_unit': 'UNIT-SDM', 'nama_unit': 'Sumber Daya Manusia'},
    ]);

    listRole.assignAll([
      {
        'id_role': 'ROLE-01',
        'nama_role': 'karu',
        'permissions': [
          'laporan.lihat',
          'laporan.buat',
          'laporan.ubah',
          'laporan.validasi',
          'tindakan.lihat',
          'tindakan.ubah',
          'report.lihat',
          'report.export',
        ],
        'created_at': '2026-10-02T08:10:00',
      },
      {
        'id_role': 'ROLE-02',
        'nama_role': 'superadmin',
        'permissions': [wildcardPermission],
        'created_at': '2026-10-02T08:12:00',
      },
    ]);

    listKategori.assignAll([
      {
        'id_kategori': 'KAT-01',
        'jenis_kategori': 'permasalahan',
        'created_at': '2026-10-02T08:15:00',
      },
      {
        'id_kategori': 'KAT-02',
        'jenis_kategori': 'Informasi',
        'created_at': '2026-10-02T08:20:00',
      },
      {
        'id_kategori': 'KAT-03',
        'jenis_kategori': 'Arahan Direktur',
        'created_at': '2026-10-03T09:05:00',
      },
    ]);

    listKaryawan.assignAll([
      {
        'id_nik': 'NIK-001',
        'nama_karyawan': 'dr. Enung Sp.PD',
        'id_unit': 'UNIT-IGD',
        'id_role': 'ROLE-01',
        'last_login': '2026-11-11T08:24:00',
      },
      {
        'id_nik': 'NIK-002',
        'nama_karyawan': 'Rina Kartika',
        'id_unit': 'UNIT-UMUM',
        'id_role': 'ROLE-02',
        'last_login': '2026-11-12T07:05:00',
      },
      {
        'id_nik': 'NIK-003',
        'nama_karyawan': 'Budi Santoso',
        'id_unit': 'UNIT-SDM',
        'id_role': 'ROLE-01',
        'last_login': null,
      },
      {
        'id_nik': 'NIK-004',
        'nama_karyawan': 'Andi Pratama',
        'id_unit': 'UNIT-IT',
        'id_role': 'ROLE-02',
        'last_login': '2026-11-10T16:40:00',
      },
    ]);
  }
}
