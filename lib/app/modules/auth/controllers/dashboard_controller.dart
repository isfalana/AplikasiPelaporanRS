import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/master_data_store.dart';
// [MODIFIKASI] Import NotificationService
import '../../../data/services/notification_service.dart';
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
  var activeNik = ''.obs;
  // [MODIFIKASI] Simpan role ID aktif dari session login agar otorisasi menu tetap konsisten
  var activeRoleId = ''.obs;
  var isSidebarCollapsed = false.obs;
  var isMasterExpanded = true.obs;

  /// Hak akses akun yang sedang login.
  ///
  /// Selama NIK belum termuat (misalnya sesaat setelah halaman dibuka), semua
  /// menu ditampilkan agar aplikasi tidak "berkedip". Setelah NIK terbaca,
  /// daftar ini mengikuti permission role pada Master Role.
  Set<String> get permissions {
    final nik = activeNik.value.trim();
    if (nik.isEmpty) return Set<String>.from(MasterDataStore.allPermissions);
    final store = MasterDataStore.ensure();
    var roleId = store.employeeRole(nik);
    if (roleId.isEmpty && activeRoleId.value.isNotEmpty) {
      roleId = activeRoleId.value.trim();
    }
    if (roleId.isNotEmpty) {
      return store.permissionsForRole(roleId);
    }
    return store.permissionsForEmployee(nik);
  }

  /// Apakah akun yang sedang login memiliki hak akses [permission].
  bool can(String permission) {
    final current = permissions;
    return current.contains(MasterDataStore.wildcardPermission) ||
        current.contains(permission);
  }

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
    activeNik.value = prefs.getString('id_nik') ?? '';
    activeRoleId.value = prefs.getString('id_role') ?? '';
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

  /// Menyegarkan tampilan dashboard dengan mengambil data backend terbaru.
  void fetchDashboardData() async {
    isLoading.value = true;
    try {
      await laporanController.fetchLaporanData();
      await MasterDataStore.ensure().fetchFromBackend();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// [MODIFIKASI] Reset tampilan ke kondisi awal (bersihkan filter dan segarkan metrik)
  void resetToInitialView() {
    priorityFilters.clear();
    fetchDashboardData();
  }

  /// Tanggal laporan yang siap ditampilkan pada kartu dashboard (format DD-MM-YYYY).
  String reportDate(Map<String, dynamic> laporan) {
    final raw =
        laporan['tgl_laporan'] ??
        laporan['tanggal_laporan'] ??
        laporan['tanggal'] ??
        laporan['created_at'] ??
        laporan['tgl_kejadian'];
    return formatDisplayDate(raw);
  }

  /// [MODIFIKASI] Helper untuk memformat tanggal ke format standar DD-MM-YYYY
  String formatDisplayDate(dynamic raw) {
    if (raw == null) return '-';
    final text = raw.toString().trim();
    if (text.isEmpty || text == '-') return '-';

    final date = DateTime.tryParse(text);
    if (date != null) {
      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-${date.year}';
    }

    final clean = text.replaceAll('/', '-');
    final parts = clean.split('-');
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}';
      }
      if (parts[2].length == 4) {
        return '${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}';
      }
    }
    return text;
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

  /// [MODIFIKASI] Label Last Update By: Nama karyawan dan unit kerja
  String lastUpdatedBy(Map<String, dynamic> laporan) {
    final raw = (laporan['last_update_by'] ?? laporan['lastUpdateBy'])?.toString().trim();
    if (raw != null && raw.isNotEmpty && raw != '-') {
      if (!raw.contains('·') && !raw.contains(' - ') && !raw.contains(' ')) {
        final name = laporanController.userName(raw);
        final unit = laporanController.employeeUnitName(raw);
        final parts = [name, unit].where((v) => v.isNotEmpty && v != '-').toList();
        if (parts.isNotEmpty) return parts.join(' · ');
      }
      return raw;
    }
    // Fallback ke pelapor bila riwayat belum ada
    return reporter(laporan);
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
      'kritis' => 'Kritis',
      'tinggi' || 'high' => 'Tinggi',
      'sedang' || 'mid' || 'medium' => 'Sedang',
      'rendah' || 'low' => 'Rendah',
      _ => laporan['prioritas']?.toString() ?? '-',
    };
  }

  String statusLabel(Map<String, dynamic> laporan) {
    return switch (laporan['status']?.toString().trim().toUpperCase()) {
      'COMPLETED' || 'DONE' || 'SELESAI' => 'Done',
      'PENDING_APPROVAL' || 'PENDING APPROVAL' => 'Menunggu Approval',
      'RETURNED' || 'DIKEMBALIKAN' => 'Dikembalikan',
      'IN_PROGRESS' || 'ON PROGRESS' || 'PROSES' => 'On Progress',
      _ => 'Open',
    };
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // [MODIFIKASI] Pertahankan preferensi perangkat (toggle notifikasi) agar tetap aktif setelah logout
    final deviceNotif = prefs.getBool('device_notification_enabled') ??
        (Get.isRegistered<NotificationService>()
            ? Get.find<NotificationService>().isDeviceNotificationEnabled.value
            : false);

    // Hapus hanya key sesi login pengguna, jangan hapus setting perangkat
    await prefs.remove('jwt_token');
    await prefs.remove('id_nik');
    await prefs.remove('nama_karyawan');
    await prefs.remove('id_unit');
    await prefs.remove('unit_name');
    await prefs.remove('id_role');
    await prefs.remove('nama_role');
    await prefs.setBool('device_notification_enabled', deviceNotif);

    // [MODIFIKASI] Bersihkan daftar notifikasi sesi pengguna saat ini
    if (Get.isRegistered<NotificationService>()) {
      final notif = Get.find<NotificationService>();
      notif.notifications.clear();
      notif.unreadCount.value = 0;
      notif.isDeviceNotificationEnabled.value = deviceNotif;
    }

    // Laporan sengaja tidak dihapus: data laporan tersimpan di memori agar PIC
    // yang login berikutnya tetap bisa menindaklanjuti laporan yang ditujukan
    // kepadanya.
    Get.offAllNamed(Routes.LOGIN); // Kembali ke halaman login
  }
}
