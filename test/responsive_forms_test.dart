import 'dart:typed_data';

import 'package:aplikasilaporan/app/modules/laporan/controllers/laporan_controller.dart';
import 'package:aplikasilaporan/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const mobileSizes = [Size(320, 800), Size(360, 800), Size(390, 844)];

  // Dialog tambah pada setiap halaman Master beserta label tombolnya.
  const masterDialogs = [
    (
      route: Routes.MASTER_UNIT,
      compactLabel: 'Tambah Unit',
      wideLabel: 'Tambah Unit',
      title: 'Tambah unit',
    ),
    (
      route: Routes.MASTER_KATEGORI,
      compactLabel: 'Tambah',
      wideLabel: 'Tambah Kategori',
      title: 'Tambah kategori',
    ),
    (
      route: Routes.MASTER_KARYAWAN,
      compactLabel: 'Tambah',
      wideLabel: 'Tambah Karyawan',
      title: 'Tambah karyawan',
    ),
    (
      route: Routes.MASTER_TEMPLATE_TINDAKAN,
      compactLabel: 'Tambah',
      wideLabel: 'Tambah Template',
      title: 'Tambah template',
    ),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'id_nik': 'NIK-002',
      'unit_name': 'UNIT-UMUM',
    });
  });

  Future<void> pumpRoute(WidgetTester tester, String route, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);
    await tester.pumpWidget(
      GetMaterialApp(initialRoute: route, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  for (final size in mobileSizes) {
    testWidgets(
      'form Tindakan dengan bukti pelapor aman di ${size.width}x${size.height}',
      (tester) async {
        final laporanController = Get.put(LaporanController(), permanent: true);
        laporanController.listLaporan.first['bukti'] = 'bukti_kerusakan.pdf';
        laporanController.listLaporan.first['bukti_bytes'] = Uint8List.fromList(
          [1, 2, 3, 4],
        );
        laporanController.listLaporan.refresh();

        await pumpRoute(tester, Routes.TINDAKAN, size);

        expect(find.text('Bukti laporan pelapor'), findsOneWidget);
        expect(find.text('Bukti laporan'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('dialog hak akses role aman di ${size.width}x${size.height}', (
      tester,
    ) async {
      await pumpRoute(tester, Routes.MASTER_ROLE, size);

      final addLabel = size.width < 380 ? 'Tambah' : 'Tambah Role';
      await tester.tap(find.text(addLabel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(Scrollable).last, const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(find.text('Simpan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final dialog in masterDialogs) {
      testWidgets(
        'dialog ${dialog.title} aman di ${size.width}x${size.height}',
        (tester) async {
          await pumpRoute(tester, dialog.route, size);

          final addLabel = size.width < 380
              ? dialog.compactLabel
              : dialog.wideLabel;
          await tester.tap(find.text(addLabel));
          await tester.pumpAndSettle();
          expect(find.text(dialog.title), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.drag(
            find.byType(Scrollable).last,
            const Offset(0, -1500),
          );
          await tester.pumpAndSettle();
          expect(find.text('Simpan'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
