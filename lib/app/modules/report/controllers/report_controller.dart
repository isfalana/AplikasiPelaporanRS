import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../laporan/controllers/laporan_controller.dart';

class ReportController extends GetxController {
  ReportController({required this.laporanController});

  final LaporanController laporanController;

  // [MODIFIKASI] Ambil data laporan terbaru saat halaman Report/Rekap diinisialisasi
  @override
  void onInit() {
    super.onInit();
    laporanController.fetchLaporanData();
  }

  /// [MODIFIKASI] Reset tampilan ke kondisi awal (bersihkan semua filter, rentang tanggal, dan pencarian)
  void resetToInitialView() {
    dateRange.value = null;
    selectedType.value = 'Semua';
    selectedStatus.value = 'Semua';
    selectedUnit.value = 'Semua';
    searchQuery.value = '';
    laporanController.fetchLaporanData();
  }

  final dateRange = Rxn<DateTimeRange>();
  final selectedType = 'Semua'.obs;
  final selectedStatus = 'Semua'.obs;
  final selectedUnit = 'Semua'.obs;
  final searchQuery = ''.obs;

  bool get hasActiveFilters =>
      dateRange.value != null ||
      selectedType.value != 'Semua' ||
      selectedStatus.value != 'Semua' ||
      selectedUnit.value != 'Semua' ||
      searchQuery.value.trim().isNotEmpty;

  static const exportHeaders = [
    'Tanggal Laporan',
    'Tanggal Kejadian',
    'Kategori',
    'Perihal',
    'Pelapor',
    'PIC',
    'Tindakan',
    'Status',
    'Tanggal Mulai Tindak Lanjut',
    'Tanggal Selesai',
  ];

  List<Map<String, dynamic>> get filteredReports {
    laporanController.listLaporan.length;
    final keyword = searchQuery.value.trim().toLowerCase();
    final range = dateRange.value;

    final reports = laporanController.listLaporan.where((report) {
      final date = reportDate(report);
      final inRange =
          range == null ||
          (date != null &&
              !_dateOnly(date).isBefore(_dateOnly(range.start)) &&
              !_dateOnly(date).isAfter(_dateOnly(range.end)));
      final statusMatches =
          selectedStatus.value == 'Semua' ||
          status(report) == selectedStatus.value;
      // [MODIFIKASI] Pencocokan filter unit berdasarkan nama unit dan ID unit
      final unitMatches =
          selectedUnit.value == 'Semua' ||
          _unitValues(report).any(
            (unit) =>
                unit.toLowerCase() == selectedUnit.value.toLowerCase() ||
                laporanController.unitName(unit).toLowerCase() ==
                    selectedUnit.value.toLowerCase(),
          );
      final typeMatches = switch (selectedType.value) {
        'Laporan' => actions(report).isEmpty,
        'Tindakan' => actions(report).isNotEmpty,
        _ => true,
      };
      final searchableValues = [
        _value(report, 'nomor_laporan'),
        _value(report, 'id_laporan'),
        _value(report, 'perihal'),
        _value(report, 'id_nik_pelapor', 'nik_pelapor'),
        _value(report, 'id_unit_pelapor', 'unit_pelapor'),
        _value(report, 'id_nik_pic', 'nik_pic'),
        _value(report, 'id_unit_pic', 'unit_pic', 'nama_unit_pic'),
        _value(report, 'id_kategori', 'kategori', 'nama_kategori'),
        // [MODIFIKASI] Sertakan nama PIC dan nama Pelapor ke pencarian
        pic(report),
        reporter(report),
      ];
      final matchesKeyword =
          keyword.isEmpty ||
          searchableValues.any(
            (value) => value.toLowerCase().contains(keyword),
          );

      return inRange &&
          statusMatches &&
          unitMatches &&
          typeMatches &&
          matchesKeyword;
    }).toList();

    reports.sort((a, b) {
      final firstDate = reportDate(a);
      final secondDate = reportDate(b);
      if (firstDate == null) return secondDate == null ? 0 : 1;
      if (secondDate == null) return -1;
      return secondDate.compareTo(firstDate);
    });
    return reports;
  }

  // [MODIFIKASI] Getter units menghasilkan daftar nama unit (bukan ID) dari master data dan riwayat laporan
  List<String> get units {
    final values = <String>{};
    for (final unit in laporanController.listUnit) {
      final name = unit['nama_unit']?.toString().trim();
      if (name != null && name.isNotEmpty && name != '-') {
        values.add(name);
      }
    }
    for (final report in laporanController.listLaporan) {
      values.addAll(_unitValues(report));
    }
    final sorted = values.toList()..sort();
    return ['Semua', ...sorted];
  }

  List<List<String>> get exportRows => filteredReports
      .map(
        (report) => [
          dateText(reportDate(report)),
          eventDate(report),
          category(report),
          reportTitle(report),
          reporter(report),
          pic(report),
          actions(report)
              .map(
                (action) =>
                    '${_isActionComplete(report, action) ? '[x]' : '[ ]'} ${action['deskripsi_tindakan'] ?? '-'}',
              )
              .join('; '),
          status(report),
          actionStartDate(report),
          completionDate(report),
        ],
      )
      .toList();

  void resetFilters() {
    dateRange.value = null;
    selectedType.value = 'Semua';
    selectedStatus.value = 'Semua';
    selectedUnit.value = 'Semua';
    searchQuery.value = '';
  }

  DateTime? reportDate(Map<String, dynamic> report) {
    return _parseDate(
          _value(
            report,
            'tgl_laporan',
            'tanggal_laporan',
            'tanggal',
            'created_at',
          ),
        ) ??
        _parseDate(_value(report, 'tgl_kejadian'));
  }

  String eventDate(Map<String, dynamic> report) =>
      dateText(_parseDate(_value(report, 'tgl_kejadian')));

  String dateText(DateTime? date) {
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    // [MODIFIKASI] Sesuaikan format tanggal ke DD-MM-YYYY
    return '$day-$month-${date.year}';
  }

  String status(Map<String, dynamic> report) {
    final value = _value(report, 'status');
    return switch (value.trim().toUpperCase()) {
      'COMPLETED' || 'DONE' || 'SELESAI' => 'Done',
      'PENDING_APPROVAL' || 'PENDING APPROVAL' => 'Menunggu Approval',
      'RETURNED' || 'DIKEMBALIKAN' => 'Dikembalikan',
      'IN_PROGRESS' || 'ON PROGRESS' || 'PROSES' => 'On Progress',
      '' || '-' => 'Open',
      _ => value,
    };
  }

  String category(Map<String, dynamic> report) {
    final value = _value(report, 'id_kategori', 'kategori', 'nama_kategori');
    if (value == '-' || value.isEmpty) return '-';
    return laporanController.kategoriName(value);
  }

  String reporter(Map<String, dynamic> report) {
    final nik = _value(report, 'id_nik_pelapor', 'nik_pelapor');
    final storedName = report['nama_pelapor']?.toString().trim() ?? '';
    final name = storedName.isNotEmpty
        ? storedName
        : (nik == '-' ? '-' : laporanController.userName(nik));
    final unit = _value(
      report,
      'nama_unit_pelapor',
      'id_unit_pelapor',
      'unit_pelapor',
    );
    final unitName = unit == '-' ? '-' : laporanController.unitName(unit);
    final values = [
      name,
      unitName,
    ].where((value) => value.isNotEmpty && value != '-').toList();
    return values.isEmpty ? '-' : values.join(' · ');
  }

  // [MODIFIKASI] Menampilkan nama karyawan PIC dan unitnya (contoh: "Budi Teknisi · Umum & Fasilitas")
  String pic(Map<String, dynamic> report) {
    // 1. Ambil jika sudah memiliki nama_pic_unit yang sudah dinormalisasi lengkap
    final storedPicUnit = report['nama_pic_unit']?.toString().trim();
    if (storedPicUnit != null && storedPicUnit.isNotEmpty && storedPicUnit != '-') {
      return storedPicUnit;
    }

    // 2. Ambil dari id_nik_pic, petakan setiap NIK ke nama dan unit karyawan
    final rawNiks = _value(report, 'id_nik_pic', 'nik_pic');
    if (rawNiks != '-' && rawNiks.isNotEmpty) {
      final niks = rawNiks
          .split(',')
          .map((n) => n.trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (niks.isNotEmpty) {
        final entries = niks.map((nik) {
          final name = laporanController.userName(nik);
          var uName = laporanController.employeeUnitName(nik);
          if (uName.isEmpty) {
            final repUnit = _value(report, 'nama_unit_pic', 'id_unit_pic', 'unit_pic');
            if (repUnit != '-' && repUnit.isNotEmpty) {
              uName = laporanController.unitName(repUnit);
            }
          }
          final values = [
            (name.isNotEmpty && name != nik) ? name : nik,
            uName,
          ].where((v) => v.isNotEmpty && v != '-').toList();
          return values.join(' · ');
        }).where((e) => e.isNotEmpty).toList();

        if (entries.isNotEmpty) {
          return entries.join(', ');
        }
      }
    }

    // 3. Fallback jika ada nama_pic tersimpan
    final storedName = report['nama_pic']?.toString().trim();
    if (storedName != null && storedName.isNotEmpty && storedName != '-') {
      final repUnit = _value(report, 'nama_unit_pic', 'id_unit_pic', 'unit_pic');
      final uName = (repUnit != '-' && repUnit.isNotEmpty)
          ? laporanController.unitName(repUnit)
          : '';
      final values = [storedName, uName].where((v) => v.isNotEmpty && v != '-').toList();
      return values.join(' · ');
    }

    // 4. Fallback unit bila PIC belum ditentukan
    final unit = _value(report, 'nama_unit_pic', 'id_unit_pic', 'unit_pic');
    if (unit != '-' && unit.isNotEmpty) {
      final uName = laporanController.unitName(unit);
      return uName.isNotEmpty ? uName : unit;
    }

    return '-';
  }

  String reportTitle(Map<String, dynamic> report) => _value(report, 'perihal');

  String value(Map<String, dynamic> report, String key) => _value(report, key);

  List<Map<String, dynamic>> actions(Map<String, dynamic> report) {
    final value = report['detail_tindakan'] ?? report['detailTindakan'];
    if (value is! List) return [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  bool isActionComplete(
    Map<String, dynamic> report,
    Map<String, dynamic> action,
  ) => _isActionComplete(report, action);

  String actionStartDate(Map<String, dynamic> report) {
    return dateText(
      _parseDate(
        _value(report, 'tgl_mulai_tindakan', 'tanggal_mulai_tindakan'),
      ),
    );
  }

  String completionDate(Map<String, dynamic> report) =>
      dateText(_parseDate(_value(report, 'tgl_selesai')));

  bool _isActionComplete(
    Map<String, dynamic> report,
    Map<String, dynamic> action,
  ) {
    final actionId = action['id_detail']?.toString();
    final progress = report['progres_tindakan'];
    if (actionId != null && progress is List) {
      for (final item in progress.whereType<Map>()) {
        if (item['id_detail']?.toString() == actionId) {
          return item['selesai'] == true;
        }
      }
    }
    return action['selesai'] == true;
  }

  // [MODIFIKASI] Petakan seluruh nilai unit di laporan ke nama unit resmi (bukan ID)
  List<String> _unitValues(Map<String, dynamic> report) {
    final values = <String>[];

    // 1. Unit Pelapor
    final rawPelapor = _value(report, 'nama_unit_pelapor', 'id_unit_pelapor', 'unit_pelapor');
    if (rawPelapor != '-' && rawPelapor.isNotEmpty) {
      final uName = laporanController.unitName(rawPelapor);
      if (uName.isNotEmpty && uName != '-') {
        values.add(uName);
      } else {
        values.add(rawPelapor);
      }
    }

    // 2. Unit dari NIK Pelapor
    final pelaporNik = _value(report, 'id_nik_pelapor', 'nik_pelapor');
    if (pelaporNik != '-' && pelaporNik.isNotEmpty) {
      final uName = laporanController.employeeUnitName(pelaporNik);
      if (uName.isNotEmpty && uName != '-') values.add(uName);
    }

    // 3. Unit PIC
    final rawPicUnit = _value(report, 'nama_unit_pic', 'id_unit_pic', 'unit_pic');
    if (rawPicUnit != '-' && rawPicUnit.isNotEmpty) {
      final uName = laporanController.unitName(rawPicUnit);
      if (uName.isNotEmpty && uName != '-') {
        values.add(uName);
      } else {
        values.add(rawPicUnit);
      }
    }

    // 4. Unit kerja dari masing-masing PIC
    final rawNiks = _value(report, 'id_nik_pic', 'nik_pic');
    if (rawNiks != '-' && rawNiks.isNotEmpty) {
      for (final nik in rawNiks.split(',').map((s) => s.trim())) {
        final uName = laporanController.employeeUnitName(nik);
        if (uName.isNotEmpty && uName != '-') values.add(uName);
      }
    }

    return values.where((value) => value.isNotEmpty && value != '-').toSet().toList();
  }

  // [MODIFIKASI] _personValue dihapus karena fungsi pic() dan reporter() sudah memetakan NIK ke nama karyawan secara spesifik.

  String _value(
    Map<String, dynamic> report,
    String key, [
    String? key2,
    String? key3,
    String? key4,
  ]) {
    for (final candidate in [key, key2, key3, key4]) {
      if (candidate == null) continue;
      final value = report[candidate]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '-';
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty || value == '-') return null;

    // Sebagian data disimpan sebagai ISO (yyyy-MM-dd), sebagian lagi sebagai
    // format yang dipakai form laporan (dd/MM/yyyy). Keduanya harus terbaca
    // agar kolom tanggal pada halaman Report tidak kosong.
    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) return isoDate;

    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
