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

  Future<void> openMasterKaryawan(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: Routes.MASTER_KARYAWAN,
        getPages: AppPages.routes,
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('master karyawan page shows relations and supports search', (
    tester,
  ) async {
    await openMasterKaryawan(tester, const Size(1440, 1000));

    expect(find.text('Master Karyawan'), findsWidgets);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Rina Kartika'), findsOneWidget);
    expect(find.text('Andi Pratama'), findsOneWidget);
    expect(find.text('Unit Umum'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('Tambah Karyawan'), findsOneWidget);

    // Password dan token perangkat tidak boleh tampil di halaman.
    expect(find.textContaining('123456'), findsNothing);
    expect(find.text('fcm_token'), findsNothing);

    // Pencarian berdasarkan nama unit.
    await tester.enterText(find.byType(TextField), 'teknologi');
    await tester.pump();

    expect(find.text('Andi Pratama'), findsOneWidget);
    expect(find.text('Rina Kartika'), findsNothing);

    // Pencarian berdasarkan nama role.
    await tester.enterText(find.byType(TextField), 'dokter');
    await tester.pump();

    expect(find.text('dr. Enung Sp.PD'), findsOneWidget);
    expect(find.text('Andi Pratama'), findsNothing);

    // Pencarian berdasarkan NIK.
    await tester.enterText(find.byType(TextField), 'NIK-004');
    await tester.pump();

    expect(find.text('Andi Pratama'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tidak-ada');
    await tester.pump();

    expect(
      find.text('Tidak ada karyawan yang cocok dengan pencarian.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('can add a new employee with unit and role', (tester) async {
    await openMasterKaryawan(tester, const Size(1440, 1000));

    await tester.tap(find.text('Tambah Karyawan'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah karyawan'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('karyawan_unit_dropdown')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('karyawan_role_dropdown')),
      findsOneWidget,
    );

    // NIK dibuat otomatis dan tidak bisa diubah manual.
    final nikField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('karyawan_nik_field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(nikField.readOnly, isTrue);
    expect(find.text('NIK-005'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('karyawan_name_field')),
      'Siti Aminah',
    );

    await tester.tap(find.byKey(const ValueKey('karyawan_unit_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teknologi Informasi').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('karyawan_role_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administrator').last);
    await tester.pumpAndSettle();

    // Password wajib untuk karyawan baru.
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Password wajib diisi.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('karyawan_password_field')),
      'rahasia123',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('NIK-005'), findsOneWidget);
    expect(find.text('Teknologi Informasi'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can edit an employee without changing the password', (
    tester,
  ) async {
    await openMasterKaryawan(tester, const Size(1440, 1000));

    await tester.tap(find.byTooltip('Edit karyawan').first);
    await tester.pumpAndSettle();

    expect(find.text('Ubah karyawan'), findsOneWidget);
    expect(find.text('ID login'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('karyawan_name_field')),
      'Andi Pratama Putra',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Andi Pratama Putra'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can delete an employee after confirmation', (tester) async {
    await openMasterKaryawan(tester, const Size(1440, 1000));

    await tester.tap(find.byTooltip('Hapus karyawan').first);
    await tester.pumpAndSettle();
    expect(find.text('Hapus karyawan?'), findsOneWidget);
    expect(find.textContaining('Riwayat laporan'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Andi Pratama'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('master karyawan page uses cards on a mobile viewport', (
    tester,
  ) async {
    await openMasterKaryawan(tester, const Size(390, 844));

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Rina Kartika'), findsOneWidget);
    expect(find.text('Tambah Karyawan'), findsOneWidget);
    expect(find.textContaining('Login terakhir:'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Master Karyawan sidebar item opens the page', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.DASHBOARD, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Master Karyawan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(Get.currentRoute, Routes.MASTER_KARYAWAN);
    expect(find.text('Tambah Karyawan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
