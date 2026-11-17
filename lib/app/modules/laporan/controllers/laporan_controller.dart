import 'package:get/get.dart';

import '../../../data/services/master_data_store.dart';

class LaporanController extends GetxController {
  // Indikator loading untuk simulasi API
  var isLoading = false.obs;

  /// Master data bersama untuk nama kategori, unit, dan karyawan.
  ///
  /// Dipakai supaya pilihan kategori/PIC dan label pada laporan selalu
  /// mengikuti data yang ada di halaman Master.
  MasterDataStore get master => MasterDataStore.ensure();

  /// Nama karyawan contoh untuk menampilkan pelapor berdasarkan NIK.
  static const demoUserNames = <String, String>{
    'NIK-001': 'dr. Enung Sp.PD',
    'NIK-002': 'Rina Kartika',
    'NIK-003': 'Budi Santoso',
    'NIK-004': 'Andi Pratama',
  };

  /// Nama unit contoh untuk menampilkan relasi unit pelapor.
  static const demoUnitNames = <String, String>{
    'UNIT-UMUM': 'Unit Umum',
    'UNIT-IGD': 'Instalasi Gawat Darurat',
    'UNIT-IT': 'Teknologi Informasi',
    'UNIT-SDM': 'Sumber Daya Manusia',
  };

  /// Pilihan kategori untuk form laporan, berasal dari Master Kategori.
  List<Map<String, dynamic>> get kategoriOptions => master.listKategori;

  /// Daftar NIK karyawan untuk pilihan PIC, berasal dari Master Karyawan.
  List<String> get employeeNiks => master.listKaryawan
      .map((karyawan) => karyawan['id_nik']?.toString().trim() ?? '')
      .where((nik) => nik.isNotEmpty)
      .toList();

  String userName(String nik) {
    final key = nik.trim();
    if (key.isEmpty) return '';
    final name = master.employeeName(key);
    if (name.isNotEmpty && name != key) return name;
    return demoUserNames[key.toUpperCase()] ?? key;
  }

  String unitName(String unit) {
    final key = unit.trim();
    if (key.isEmpty) return '';
    final name = master.unitName(key);
    if (name.isNotEmpty && name != key) return name;
    return demoUnitNames[key.toUpperCase()] ?? key;
  }

  /// Nama kategori dari [idKategori]. Bila tidak ditemukan, tampilkan nilai
  /// aslinya supaya data lama yang masih berupa ID tidak hilang.
  String kategoriName(String idKategori) {
    final key = idKategori.trim();
    if (key.isEmpty) return '';
    return master.kategoriName(key);
  }

  /// Unit karyawan [nik] dari Master Karyawan.
  String employeeUnit(String nik) => master.employeeUnit(nik);

  // List data laporan yang disamakan persis dengan kolom Sequelize backend
  var listLaporan = <Map<String, dynamic>>[
    {
      'id_laporan': 'LAP-001',
      'tgl_laporan': '2026-11-09',
      'tgl_kejadian': '2026-11-09',
      'deadline': '2026-11-11',
      'id_unit_pelapor': 'UNIT-IGD',
      'id_nik_pelapor': 'NIK-001',
      'nama_pelapor': 'dr. Enung Sp.PD',
      'nama_unit_pelapor': 'Instalasi Gawat Darurat',
      'id_unit_pic': 'UNIT-UMUM',
      'id_nik_pic': 'NIK-002',
      'id_kategori': 'KAT-01',
      'id_tindak_lanjut': 'TL-01',
      'perihal': 'Kerusakan AC Ruang IGD',
      'prioritas': 'Tinggi',
      'keterangan':
          'AC tidak dingin dan mengeluarkan bunyi bising di ruangan IGD.',
      'status': 'Open',
      'tgl_selesai': null,
    },
    {
      'id_laporan': 'LAP-002',
      'tgl_laporan': '2026-11-08',
      'tgl_kejadian': '2026-11-08',
      'deadline': '2026-11-10',
      'id_unit_pelapor': 'UNIT-SDM',
      'id_nik_pelapor': 'NIK-003',
      'nama_pelapor': 'Budi Santoso',
      'nama_unit_pelapor': 'Sumber Daya Manusia',
      'id_unit_pic': 'UNIT-IT',
      'id_nik_pic': 'NIK-004',
      'id_kategori': 'KAT-02',
      'id_tindak_lanjut': 'TL-02',
      'perihal': 'Permintaan Perbaikan Jaringan LAN',
      'prioritas': 'Sedang',
      'keterangan': 'Koneksi internet di ruang administrasi sering terputus.',
      'status': 'On Progress',
      'tgl_selesai': null,
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchLaporanData();
  }

  // Simulasi mengambil data dari endpoint /api/laporan backend
  void fetchLaporanData() async {
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      // Nanti di sini bisa diganti dengan pemanggilan Dio:
      // Dio dio = await ApiService.getClient();
      // final response = await dio.get('/laporan');
      // listLaporan.assignAll(response.data);
    } finally {
      isLoading.value = false;
    }
  }
}
