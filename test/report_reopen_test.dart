import 'package:aplikasilaporan/app/data/services/master_data_store.dart';
import 'package:aplikasilaporan/app/modules/laporan/controllers/laporan_controller.dart';
import 'package:aplikasilaporan/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _validatedDoneReport() => {
  'id_laporan': 'LAP-DONE',
  'tgl_laporan': '16/11/2026',
  'tgl_kejadian': '15/11/2026',
  'deadline': '31/12/2030',
  'id_unit_pelapor': 'UNIT-UMUM',
  'id_nik_pelapor': 'NIK-002',
  'nama_pelapor': 'Rina Kartika',
  'id_unit_pic': 'UNIT-UMUM',
  'id_nik_pic': 'NIK-002',
  'id_kategori': 'KAT-01',
  'id_tindak_lanjut': 'TL-08',
  'perihal': 'Laporan selesai dan tervalidasi',
  'prioritas': 'Sedang',
  'status': 'Done',
  'validasi_pelapor': true,
  'tgl_validasi': '17/11/2026',
  'validasi_by': 'NIK-002',
  'nama_validasi_by': 'Rina Kartika',
  'tgl_selesai': '17/11/2026',
  'detail_tindakan': [
    {'id_detail': 'DT-DONE-1', 'deskripsi_tindakan': 'Langkah satu'},
  ],
  'progres_tindakan': [
    {'id_detail': 'DT-DONE-1', 'selesai': true},
  ],
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> login(WidgetTester tester, String nik, String password) async {
    await tester.enterText(find.byType(TextField).first, nik);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.text('Masuk'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    // Tunggu snackbar login hilang agar tidak ada timer yang tertinggal.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  Future<void> openLaporan(WidgetTester tester) async {
    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('superadmin bisa membuka kembali laporan Done yang tervalidasi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    final laporanController = Get.put(LaporanController(), permanent: true);
    laporanController.listLaporan.assignAll([_validatedDoneReport()]);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.LOGIN, getPages: AppPages.routes),
    );
    await tester.pump();

    // NIK-002 adalah akun demo dengan role superadmin.
    await login(tester, 'NIK-002', '123456');
    await openLaporan(tester);

    // Laporan Done tetap tidak punya tombol edit biasa, tetapi superadmin
    // mendapat aksi "Buka kembali laporan".
    expect(find.byTooltip('Edit laporan'), findsNothing);
    expect(find.byTooltip('Buka kembali laporan'), findsWidgets);

    await tester.tap(find.byTooltip('Buka kembali laporan').first);
    await tester.pumpAndSettle();
    expect(find.text('Buka kembali laporan?'), findsOneWidget);

    await tester.tap(find.text('Buka kembali'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    final report = laporanController.listLaporan.first;
    expect(report['status'], 'On Progress');
    expect(report['validasi_pelapor'], isFalse);
    expect(report['tgl_validasi'], isNull);
    expect(report['tgl_selesai'], isNull);

    // Setelah dibuka kembali, laporan bisa diedit lagi.
    expect(find.byTooltip('Edit laporan'), findsWidgets);
    await tester.tap(find.byTooltip('Edit laporan').first);
    await tester.pumpAndSettle();
    expect(find.text('Perbarui'), findsOneWidget);

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ringkasan perihal kendala...',
      ),
      'Laporan diperbaiki setelah dibuka kembali',
    );
    await tester.ensureVisible(find.text('Perbarui'));
    await tester.tap(find.text('Perbarui'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(
      laporanController.listLaporan.first['perihal'],
      'Laporan diperbaiki setelah dibuka kembali',
    );
    expect(laporanController.listLaporan.first['status'], 'On Progress');
    expect(tester.takeException(), isNull);
  });

  testWidgets('role tanpa izin tidak bisa membuka kembali laporan Done', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    // Karyawan dengan role karu (ROLE-01) tidak memiliki izin buka kembali.
    MasterDataStore.ensure().listKaryawan.add({
      'id_nik': 'NIK-009',
      'nama_karyawan': 'Karu Uji',
      'id_unit': 'UNIT-UMUM',
      'id_role': 'ROLE-01',
      'password': 'karu123',
      'last_login': null,
    });

    final laporanController = Get.put(LaporanController(), permanent: true);
    laporanController.listLaporan.assignAll([_validatedDoneReport()]);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.LOGIN, getPages: AppPages.routes),
    );
    await tester.pump();

    await login(tester, 'NIK-009', 'karu123');
    await openLaporan(tester);

    expect(find.byTooltip('Buka kembali laporan'), findsNothing);
    expect(find.text('Buka kembali laporan'), findsNothing);
    expect(find.byTooltip('Edit laporan'), findsNothing);

    // Status laporan tidak berubah.
    expect(laporanController.listLaporan.first['status'], 'Done');
    expect(laporanController.listLaporan.first['validasi_pelapor'], isTrue);
    expect(tester.takeException(), isNull);
  });
}
