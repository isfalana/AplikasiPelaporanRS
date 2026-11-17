import 'package:aplikasilaporan/app/data/services/master_data_store.dart';
import 'package:aplikasilaporan/app/global_widgets/sidebar_widgets.dart';
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

  /// Ganti hak akses role tertentu pada store bersama.
  void setRolePermissions(String idRole, List<String> permissions) {
    final store = MasterDataStore.ensure();
    final index = store.listRole.indexWhere(
      (role) => role['id_role']?.toString() == idRole,
    );
    store.listRole[index] = {
      ...store.listRole[index],
      'permissions': permissions,
    };
  }

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

  test('hak akses karyawan mengikuti role-nya', () {
    final store = MasterDataStore();

    expect(store.hasPermission('NIK-001', 'laporan.lihat'), isTrue);
    expect(store.hasPermission('NIK-001', 'laporan.hapus'), isFalse);
    expect(store.hasPermission('NIK-002', 'report.export'), isTrue);
    expect(store.permissionsForRole('ROLE-02'), contains('master.role'));
  });

  testWidgets('sidebar hanya menampilkan menu sesuai hak akses role', (
    tester,
  ) async {
    setRolePermissions('ROLE-02', ['laporan.lihat']);

    await pumpApp(tester, Routes.DASHBOARD);

    final sidebar = find.byType(SidebarWidget);
    expect(
      find.descendant(of: sidebar, matching: find.text('Laporan')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sidebar, matching: find.text('Tindakan')),
      findsNothing,
    );
    expect(
      find.descendant(of: sidebar, matching: find.text('Report')),
      findsNothing,
    );
    expect(
      find.descendant(of: sidebar, matching: find.text('Master Data')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tombol simpan tindakan nonaktif tanpa hak tindakan.ubah', (
    tester,
  ) async {
    setRolePermissions('ROLE-02', ['tindakan.lihat']);

    await pumpApp(tester, Routes.TINDAKAN);

    expect(find.text('Kerusakan AC Ruang IGD'), findsWidgets);
    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Kirim Tindakan'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tombol export report nonaktif tanpa hak report.export', (
    tester,
  ) async {
    setRolePermissions('ROLE-02', ['report.lihat']);

    await pumpApp(tester, Routes.REPORT);

    final exportPdf = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Export PDF'),
        matching: find.byType(ElevatedButton),
      ),
    );
    final exportExcel = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Export Excel'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(exportPdf.onPressed, isNull);
    expect(exportExcel.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
