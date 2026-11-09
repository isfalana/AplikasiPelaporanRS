import 'package:get/get.dart';

class LaporanController extends GetxController {
  // Indikator loading untuk simulasi API
  var isLoading = false.obs;

  // List data laporan yang disamakan persis dengan kolom Sequelize backend
  var listLaporan = <Map<String, dynamic>>[
    {
      'id_laporan': 'LAP-001',
      'tgl_kejadian': '2026-11-09',
      'id_unit_pelapor': 'UNIT-IGD',
      'id_nik_pelapor': 'NIK-001',
      'id_unit_pic': 'UNIT-UMUM',
      'id_nik_pic': 'NIK-002',
      'id_kategori': 'KAT-01',
      'id_tindak_lanjut': 'TL-01',
      'perihal': 'Kerusakan AC Ruang IGD',
      'prioritas': 'Tinggi',
      'keterangan': 'AC tidak dingin dan mengeluarkan bunyi bising di ruangan IGD.',
      'status': 'Pending',
      'tgl_selesai': null,
    },
    {
      'id_laporan': 'LAP-002',
      'tgl_kejadian': '2026-11-08',
      'id_unit_pelapor': 'UNIT-SDM',
      'id_nik_pelapor': 'NIK-003',
      'id_unit_pic': 'UNIT-IT',
      'id_nik_pic': 'NIK-004',
      'id_kategori': 'KAT-02',
      'id_tindak_lanjut': 'TL-02',
      'perihal': 'Permintaan Perbaikan Jaringan LAN',
      'prioritas': 'Sedang',
      'keterangan': 'Koneksi internet di ruang administrasi sering terputus.',
      'status': 'Proses',
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