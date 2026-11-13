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

  Future<void> openMasterKategori(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: Routes.MASTER_KATEGORI,
        getPages: AppPages.routes,
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('master kategori page shows a table and supports search', (
    tester,
  ) async {
    await openMasterKategori(tester, const Size(1440, 1000));

    expect(find.text('Master Kategori'), findsWidgets);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Kelistrikan'), findsOneWidget);
    expect(find.text('Jaringan & Internet'), findsOneWidget);
    expect(find.text('Tambah Kategori'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'jaringan');
    await tester.pump();

    expect(find.text('Jaringan & Internet'), findsOneWidget);
    expect(find.text('Kelistrikan'), findsNothing);

    await tester.enterText(find.byType(TextField), 'tidak-ada');
    await tester.pump();

    expect(
      find.text('Tidak ada kategori yang cocok dengan pencarian.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('can add a new kategori with an automatic ID', (tester) async {
    await openMasterKategori(tester, const Size(1440, 1000));

    await tester.tap(find.text('Tambah Kategori'));
    await tester.pumpAndSettle();

    expect(find.text('dibuat otomatis'), findsOneWidget);
    expect(find.text('KAT-06'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('kategori_jenis_field')),
      'Peralatan Medis',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Peralatan Medis'), findsOneWidget);
    expect(find.text('KAT-06'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can edit an existing kategori', (tester) async {
    await openMasterKategori(tester, const Size(1440, 1000));

    await tester.tap(find.byTooltip('Edit kategori').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('kategori_jenis_field')),
      'Fasilitas Gedung',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Fasilitas Gedung'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can delete a kategori after confirmation', (tester) async {
    await openMasterKategori(tester, const Size(1440, 1000));

    await tester.tap(find.byTooltip('Hapus kategori').first);
    await tester.pumpAndSettle();
    expect(find.text('Hapus kategori?'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Fasilitas Umum'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('master kategori page uses cards on a mobile viewport', (
    tester,
  ) async {
    await openMasterKategori(tester, const Size(390, 844));

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Kelistrikan'), findsOneWidget);
    expect(find.text('Tambah Kategori'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Master Kategori sidebar item opens the kategori page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.DASHBOARD, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Master Kategori'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(Get.currentRoute, Routes.MASTER_KATEGORI);
    expect(find.text('Tambah Kategori'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
