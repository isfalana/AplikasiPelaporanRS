import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../laporan/controllers/laporan_controller.dart';
import '../../../routes/app_pages.dart';

class DashboardController extends GetxController {
  DashboardController({LaporanController? laporanController})
    : laporanController = laporanController ?? _resolveLaporanController();

  /// Data laporan yang sama dengan halaman Laporan, Tindakan, dan Report.
  ///
  /// Semua halaman memakai satu controller permanen supaya simulasi tetap
  /// saling terhubung meskipun data hanya tersimpan di memori.
  final LaporanController laporanController;

  static LaporanController _resolveLaporanController() {
    if (Get.isRegistered<LaporanController>()) {
      return Get.find<LaporanController>();
    }
    return Get.put(LaporanController(), permanent: true);
  }

  var unitName = ''.obs;
  var employeeName = ''.obs;
  var isSidebarCollapsed = false.obs;
  var isMasterExpanded = true.obs;

  // List data laporan berasal dari controller bersama.
  List<Map<String, dynamic>> get listLaporan => laporanController.listLaporan;
  var isLoading = true.obs;

  // Filter aktif pada card "Prioritas tindak lanjut". Bisa lebih dari satu.
  final priorityFilters = <String>{}.obs;

  // Metrik dihitung langsung dari data laporan yang sama.
  int get jumlahLaporan => listLaporan.length;

  int get jumlahPesanTindakan =>
      listLaporan.where((laporan) => statusLabel(laporan) != 'Done').length;

  int get jumlahTindakanSelesai =>
      listLaporan.where((laporan) => statusLabel(laporan) == 'Done').length;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchDashboardData();
  }

  void loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    unitName.value = prefs.getString('unit_name') ?? 'Unit';
    employeeName.value = _readEmployeeName(prefs);
  }

  String _readEmployeeName(SharedPreferences prefs) {
    for (final key in [
      'nama_karyawan',
      'nama_pegawai',
      'nama_lengkap',
      'employee_name',
      'full_name',
    ]) {
      final name = prefs.getString(key)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return prefs.getString('id_nik') ?? 'Pengguna';
  }

  /// Menyegarkan tampilan dashboard tanpa membuat data tiruan terpisah.
  void fetchDashboardData() async {
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 350));
      laporanController.listLaporan.refresh();
    } finally {
      isLoading.value = false;
    }
  }

  /// Tanggal laporan yang siap ditampilkan pada kartu dashboard.
  String reportDate(Map<String, dynamic> laporan) {
    final raw =
        laporan['tgl_laporan'] ??
        laporan['tanggal_laporan'] ??
        laporan['tanggal'] ??
        laporan['created_at'] ??
        laporan['tgl_kejadian'];
    final date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) {
      return raw?.toString().trim().isNotEmpty == true ? raw.toString() : '-';
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Label pelapor: "Nama · Unit".
  String reporter(Map<String, dynamic> laporan) {
    final nik = laporan['id_nik_pelapor']?.toString().trim() ?? '';
    final storedName = laporan['nama_pelapor']?.toString().trim() ?? '';
    final name = storedName.isNotEmpty
        ? storedName
        : (nik.isEmpty ? '' : laporanController.userName(nik));
    final unit =
        laporan['nama_unit_pelapor']?.toString().trim() ??
        laporan['id_unit_pelapor']?.toString().trim() ??
        '';
    final unitName = unit.isEmpty ? '' : laporanController.unitName(unit);
    final values = [
      name,
      unitName,
    ].where((value) => value.isNotEmpty && value != '-').toList();
    return values.isEmpty ? '-' : values.join(' · ');
  }

  /// Label PIC: nama karyawan yang ditugaskan.
  String reportPic(Map<String, dynamic> laporan) {
    final ids = (laporan['id_nik_pic']?.toString() ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (ids.isEmpty) {
      final unit =
          laporan['nama_unit_pic']?.toString().trim() ??
          laporan['id_unit_pic']?.toString().trim() ??
          '';
      return unit.isEmpty ? '-' : laporanController.unitName(unit);
    }
    return ids.map(laporanController.userName).join(', ');
  }

  String priorityLabel(Map<String, dynamic> laporan) {
    return switch (laporan['prioritas']?.toString().trim().toLowerCase()) {
      'tinggi' || 'high' => 'Tinggi',
      'sedang' || 'mid' || 'medium' => 'Sedang',
      'rendah' || 'low' => 'Rendah',
      _ => '-',
    };
  }

  String statusLabel(Map<String, dynamic> laporan) {
    return switch (laporan['status']?.toString().trim().toLowerCase()) {
      'done' || 'selesai' => 'Done',
      'on progress' ||
      'on progres' ||
      'proses' ||
      'in progress' => 'On Progress',
      _ => 'Open',
    };
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus sesi login
    if (Get.isRegistered<LaporanController>()) {
      Get.delete<LaporanController>(force: true);
    }
    Get.offAllNamed(Routes.LOGIN); // Kembali ke halaman login
  }
}
