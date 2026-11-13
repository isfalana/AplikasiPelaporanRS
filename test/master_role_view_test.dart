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

  Future<void> openMasterRole(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: Routes.MASTER_ROLE,
        getPages: AppPages.routes,
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('master role page shows a table and supports search', (
    tester,
  ) async {
    await openMasterRole(tester, const Size(1440, 1000));

    expect(find.text('Master Role'), findsWidgets);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('Teknisi'), findsOneWidget);
    expect(find.text('Tambah Role'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'teknisi');
    await tester.pump();

    expect(find.text('Teknisi'), findsOneWidget);
    expect(find.text('Administrator'), findsNothing);

    await tester.enterText(find.byType(TextField), 'tidak-ada');
    await tester.pump();

    expect(
      find.text('Tidak ada role yang cocok dengan pencarian.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('can add a new role with an automatic ID', (tester) async {
    await openMasterRole(tester, const Size(1440, 1000));

    await tester.tap(find.text('Tambah Role'));
    await tester.pumpAndSettle();

    expect(find.text('dibuat otomatis'), findsOneWidget);
    expect(find.text('ROLE-05'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('role_nama_field')),
      'Perawat',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Perawat'), findsOneWidget);
    expect(find.text('ROLE-05'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can edit an existing role', (tester) async {
    await openMasterRole(tester, const Size(1440, 1000));

    await tester.tap(find.byTooltip('Edit role').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('role_nama_field')),
      'Super Admin',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Super Admin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can delete a role after confirmation', (tester) async {
    await openMasterRole(tester, const Size(1440, 1000));

    await tester.tap(find.byTooltip('Hapus role').first);
    await tester.pumpAndSettle();
    expect(find.text('Hapus role?'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Administrator'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('master role page uses cards on a mobile viewport', (
    tester,
  ) async {
    await openMasterRole(tester, const Size(390, 844));

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('Tambah Role'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Master Role sidebar item opens the role page', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.DASHBOARD, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Master Role'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(Get.currentRoute, Routes.MASTER_ROLE);
    expect(find.text('Tambah Role'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
