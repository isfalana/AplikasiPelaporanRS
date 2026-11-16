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

  Future<void> pumpApp(WidgetTester tester, String initialRoute) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);
    await tester.pumpWidget(
      GetMaterialApp(initialRoute: initialRoute, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> openKaryawanForm(WidgetTester tester) async {
    await tester.tap(find.text('Master Karyawan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Tambah Karyawan'));
    await tester.pumpAndSettle();
  }

  testWidgets('unit baru di Master Unit muncul pada form Master Karyawan', (
    tester,
  ) async {
    await pumpApp(tester, Routes.MASTER_UNIT);

    await tester.tap(find.text('Tambah Unit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('unit_name_field')),
      'Instalasi Gizi',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Instalasi Gizi'), findsOneWidget);

    await openKaryawanForm(tester);
    await tester.tap(find.byKey(const ValueKey('karyawan_unit_dropdown')));
    await tester.pumpAndSettle();

    expect(find.text('Instalasi Gizi'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('role baru di Master Role muncul pada form Master Karyawan', (
    tester,
  ) async {
    await pumpApp(tester, Routes.MASTER_ROLE);

    await tester.tap(find.text('Tambah Role'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('role_nama_field')),
      'Perawat',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Perawat'), findsOneWidget);

    await openKaryawanForm(tester);
    await tester.tap(find.byKey(const ValueKey('karyawan_role_dropdown')));
    await tester.pumpAndSettle();

    expect(find.text('Perawat'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kategori baru di Master Kategori muncul pada form Laporan', (
    tester,
  ) async {
    await pumpApp(tester, Routes.MASTER_KATEGORI);

    await tester.tap(find.text('Tambah Kategori'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('kategori_jenis_field')),
      'Peralatan Medis',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Peralatan Medis'), findsOneWidget);

    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(
      find.ancestor(
        of: find.text('Pilih kategori'),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peralatan Medis'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
