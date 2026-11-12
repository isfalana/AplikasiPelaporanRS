import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../laporan/controllers/laporan_controller.dart';

class ReportController extends GetxController {
  ReportController({required this.laporanController});

  final LaporanController laporanController;

  final dateRange = Rxn<DateTimeRange>();
  final selectedType = 'Semua'.obs;
  final selectedStatus = 'Semua'.obs;
  final selectedUnit = 'Semua'.obs;
  final searchQuery = ''.obs;

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
      final unitMatches =
          selectedUnit.value == 'Semua' ||
          _unitValues(report).any(
            (unit) => unit.toLowerCase() == selectedUnit.value.toLowerCase(),
          );
      final typeMatches = switch (selectedType.value) {
        'Laporan' => actions(report).isEmpty,
        'Tindakan' => actions(report).isNotEmpty,
        _ => true,
      };
      final searchableValues = [
        _value(report, 'perihal'),
        _value(report, 'id_nik_pelapor', 'nik_pelapor'),
        _value(report, 'id_unit_pelapor', 'unit_pelapor'),
        _value(report, 'id_nik_pic', 'nik_pic'),
        _value(report, 'id_unit_pic', 'unit_pic', 'nama_unit_pic'),
        _value(report, 'id_kategori', 'kategori', 'nama_kategori'),
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

  List<String> get units {
    final values = <String>{};
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
    return '$day/$month/${date.year}';
  }

  String status(Map<String, dynamic> report) {
    final value = _value(report, 'status');
    return switch (value.trim().toLowerCase()) {
      'done' || 'selesai' => 'Done',
      'on progress' ||
      'on progres' ||
      'proses' ||
      'in progress' => 'On Progress',
      '' || '-' => 'Open',
      _ => value,
    };
  }

  String category(Map<String, dynamic> report) =>
      _value(report, 'id_kategori', 'kategori', 'nama_kategori');

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

  String pic(Map<String, dynamic> report) =>
      _personValue(report, 'id_nik_pic', 'id_unit_pic', 'unit_pic');

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

  List<String> _unitValues(Map<String, dynamic> report) {
    return [
      _value(report, 'id_unit_pic', 'unit_pic', 'nama_unit_pic'),
      _value(report, 'id_unit_pelapor', 'unit_pelapor'),
    ].where((value) => value.isNotEmpty && value != '-').toSet().toList();
  }

  String _personValue(
    Map<String, dynamic> report,
    String idKey,
    String unitKey, [
    String? alternateUnitKey,
  ]) {
    final id = _value(report, idKey);
    final unit = alternateUnitKey == null
        ? _value(report, unitKey)
        : _value(report, unitKey, alternateUnitKey);
    final values = [
      id,
      unit,
    ].where((value) => value.isNotEmpty && value != '-');
    return values.isEmpty ? '-' : values.join(' - ');
  }

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
    return DateTime.tryParse(value);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
