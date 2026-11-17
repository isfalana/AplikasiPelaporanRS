import 'package:aplikasilaporan/app/core/theme/app_colors.dart';
import 'package:aplikasilaporan/app/modules/laporan/controllers/laporan_controller.dart';
import 'package:aplikasilaporan/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'id_nik': 'NIK-002',
      'unit_name': 'UNIT-UMUM',
    });
  });

  testWidgets('report page displays and filters data on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.REPORT, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Report'), findsWidgets);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Export Excel'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Kerusakan AC Ruang IGD'), findsOneWidget);
    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsOneWidget);

    // Tombol export ada di sisi kanan dan berwarna: PDF merah, Excel hijau.
    final pdfButtonFinder = find.widgetWithText(ElevatedButton, 'Export PDF');
    final excelButtonFinder = find.widgetWithText(
      ElevatedButton,
      'Export Excel',
    );
    final pdfStyle = tester.widget<ElevatedButton>(pdfButtonFinder).style;
    final excelStyle = tester.widget<ElevatedButton>(excelButtonFinder).style;
    expect(
      pdfStyle?.backgroundColor?.resolve(const <WidgetState>{}),
      AppColors.error,
    );
    expect(
      excelStyle?.backgroundColor?.resolve(const <WidgetState>{}),
      AppColors.success,
    );
    expect(tester.getRect(excelButtonFinder).right, greaterThan(1440 * 0.8));

    // Tabel panjang bisa digulir ke kanan dan ke kiri.
    final horizontalScrollFinder = find.ancestor(
      of: find.byType(DataTable),
      matching: find.byWidgetPredicate(
        (widget) => widget is Scrollable && widget.axis == Axis.horizontal,
      ),
    );
    expect(horizontalScrollFinder, findsOneWidget);
    final horizontalScroll = tester.state<ScrollableState>(
      horizontalScrollFinder,
    );
    expect(horizontalScroll.position.maxScrollExtent, greaterThan(0));
    await tester.drag(horizontalScrollFinder, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(horizontalScroll.position.pixels, greaterThan(0));

    await tester.enterText(find.byType(TextField), 'Kerusakan AC Ruang IGD');
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.text('Kerusakan AC Ruang IGD'),
      ),
      findsOneWidget,
    );
    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report page uses cards on a mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.REPORT, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Report'), findsWidgets);
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Kerusakan AC Ruang IGD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Report sidebar item opens the report page', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.DASHBOARD, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, Routes.REPORT);
    expect(find.text('Export PDF'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('report menampilkan tanggal dan seluruh tindakan di desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    final laporanController = Get.put(LaporanController(), permanent: true);
    laporanController.listLaporan.insert(0, {
      'id_laporan': 'LAP-TANGGAL',
      'tgl_laporan': '16/11/2026',
      'tgl_kejadian': '15/11/2026',
      'deadline': '18/11/2026',
      'id_unit_pelapor': 'UNIT-UMUM',
      'id_nik_pelapor': 'NIK-002',
      'nama_pelapor': 'Rina Kartika',
      'id_unit_pic': 'UNIT-UMUM',
      'id_nik_pic': 'NIK-002',
      'id_kategori': 'KAT-01',
      'id_tindak_lanjut': 'TL-09',
      'perihal': 'Laporan dengan tanggal lengkap',
      'prioritas': 'Sedang',
      'status': 'Done',
      'tgl_mulai_tindakan': '16/11/2026',
      'tgl_selesai': '17/11/2026',
      'detail_tindakan': [
        {'id_detail': 'DT-1', 'deskripsi_tindakan': 'Cek suhu AC'},
        {'id_detail': 'DT-2', 'deskripsi_tindakan': 'Bersihkan filter'},
        {'id_detail': 'DT-3', 'deskripsi_tindakan': 'Uji ulang suhu'},
      ],
      'progres_tindakan': [
        {'id_detail': 'DT-1', 'selesai': true},
        {'id_detail': 'DT-2', 'selesai': true},
        {'id_detail': 'DT-3', 'selesai': false},
      ],
    });
    laporanController.listLaporan.refresh();

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.REPORT, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    // Tanggal tersimpan dalam format dd/MM/yyyy dan harus tampil.
    expect(find.text('16/11/2026'), findsWidgets);
    expect(find.text('15/11/2026'), findsWidgets);
    expect(find.text('17/11/2026'), findsWidgets);

    // Semua tindakan tampil, tidak dipotong dua baris.
    for (final action in [
      'Cek suhu AC',
      'Bersihkan filter',
      'Uji ulang suhu',
    ]) {
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(DataTable),
          matching: find.textContaining(action),
        ),
      );
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('kartu report mobile bisa dibuka untuk melihat detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    final laporanController = Get.put(LaporanController(), permanent: true);
    final report = laporanController.listLaporan.first;
    report['tgl_mulai_tindakan'] = '09/11/2026';
    report['tgl_selesai'] = '10/11/2026';
    report['detail_tindakan'] = [
      {'id_detail': 'DT-1', 'deskripsi_tindakan': 'Cek suhu AC'},
      {'id_detail': 'DT-2', 'deskripsi_tindakan': 'Bersihkan filter'},
    ];
    report['progres_tindakan'] = [
      {'id_detail': 'DT-1', 'selesai': true},
      {'id_detail': 'DT-2', 'selesai': false},
    ];
    laporanController.listLaporan.refresh();

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.REPORT, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    // Ringkasan tertutup: detail lengkap belum tampil.
    expect(find.text('Tanggal laporan'), findsNothing);
    expect(find.text('Pelapor'), findsNothing);
    expect(find.textContaining('Cek suhu AC'), findsNothing);
    expect(find.text('Detail'), findsWidgets);

    await tester.ensureVisible(find.text('Kerusakan AC Ruang IGD'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kerusakan AC Ruang IGD'));
    await tester.pumpAndSettle();

    // Setelah diketuk, informasi yang sama dengan desktop tampil.
    expect(find.text('Tanggal laporan'), findsOneWidget);
    expect(find.text('Tanggal kejadian'), findsOneWidget);
    expect(find.text('Mulai tindak lanjut'), findsOneWidget);
    expect(find.text('Tanggal selesai'), findsOneWidget);
    expect(find.text('Pelapor'), findsOneWidget);
    expect(find.text('PIC'), findsOneWidget);
    expect(find.text('09/11/2026'), findsWidgets);
    expect(find.text('10/11/2026'), findsWidgets);
    expect(find.textContaining('Cek suhu AC'), findsOneWidget);
    expect(find.textContaining('Bersihkan filter'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
