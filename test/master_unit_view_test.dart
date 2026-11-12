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

  Future<void> openMasterUnit(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: Routes.MASTER_UNIT,
        getPages: AppPages.routes,
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('master unit page shows a table and supports search', (
    tester,
  ) async {
    await openMasterUnit(tester, const Size(1440, 1000));

    expect(find.text('Master Unit'), findsWidgets);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Unit Umum'), findsOneWidget);
    expect(find.text('Teknologi Informasi'), findsOneWidget);
    expect(find.text('Tambah Unit'), findsOneWidget);
    expect(find.text('Laporan terkait'), findsNothing);
    expect(find.text('PIC'), findsNothing);

    await tester.enterText(find.byType(TextField), 'teknologi');
    await tester.pump();

    expect(find.text('Teknologi Informasi'), findsOneWidget);
    expect(find.text('Unit Umum'), findsNothing);

    await tester.enterText(find.byType(TextField), 'NIK-002');
    await tester.pump();

    expect(find.text('Unit Umum'), findsNothing);
    expect(
      find.text('Tidak ada unit yang cocok dengan pencarian.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('can add a new unit with an automatic ID', (tester) async {
    await openMasterUnit(tester, const Size(1440, 1000));

    await tester.tap(find.text('Tambah Unit'));
    await tester.pumpAndSettle();

    expect(find.text('dibuat otomatis'), findsOneWidget);
    expect(find.byKey(const ValueKey('unit_id_field')), findsNothing);
    expect(find.byKey(const ValueKey('unit_nik_field')), findsNothing);
    expect(find.text('UNIT-001'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('unit_name_field')),
      'Instalasi Gizi',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Instalasi Gizi'), findsOneWidget);
    expect(find.text('UNIT-001'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can edit an existing unit', (tester) async {
    await openMasterUnit(tester, const Size(1440, 1000));

    await tester.tap(find.byTooltip('Edit unit').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('unit_name_field')),
      'Unit Umum Diperbarui',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Unit Umum Diperbarui'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can delete a unit after confirmation', (tester) async {
    await openMasterUnit(tester, const Size(1440, 1000));

    await tester.tap(find.byTooltip('Hapus unit').first);
    await tester.pumpAndSettle();
    expect(find.text('Hapus unit?'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Instalasi Gawat Darurat'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('master unit page uses cards on a mobile viewport', (
    tester,
  ) async {
    await openMasterUnit(tester, const Size(390, 844));

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Unit Umum'), findsOneWidget);
    expect(find.text('Tambah Unit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Master Unit sidebar item opens the master unit page', (
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

    await tester.tap(find.text('Master Unit'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(Get.currentRoute, Routes.MASTER_UNIT);
    expect(find.text('Tambah Unit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
