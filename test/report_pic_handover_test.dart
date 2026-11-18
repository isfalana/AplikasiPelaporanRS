import 'package:aplikasilaporan/app/data/services/master_data_store.dart';
import 'package:aplikasilaporan/app/modules/laporan/controllers/laporan_controller.dart';
import 'package:aplikasilaporan/app/modules/tindakan/controllers/tindakan_controller.dart';
import 'package:aplikasilaporan/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void addMuhammad({String role = 'ROLE-01'}) {
    MasterDataStore.ensure().listKaryawan.add({
      'id_nik': 'NIK-005',
      'nama_karyawan': 'Muhammad',
      'id_unit': 'UNIT-IT',
      'id_role': role,
      'password': 'rahasia123',
      'last_login': null,
    });
  }

  testWidgets('laporan dari unit lain bisa ditindak oleh PIC yang dituju', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    addMuhammad();

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.LOGIN, getPages: AppPages.routes),
    );
    await tester.pump();

    // Login sebagai PIC Unit Umum lalu kirim laporan untuk Muhammad (Unit IT).
    await tester.tap(find.textContaining('PIC Umum'));
    await login(tester, 'NIK-002', '123456');

    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ringkasan perihal kendala...',
      ),
      'Laporan untuk Muhammad dari Unit Umum',
    );

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('permasalahan').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Muhammad').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Kirim'));
    await tester.tap(find.text('Kirim'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    final laporanController = Get.find<LaporanController>();
    final created = laporanController.listLaporan.first;
    expect(created['perihal'], 'Laporan untuk Muhammad dari Unit Umum');
    expect(created['id_nik_pic'], 'NIK-005');

    // Logout lalu login sebagai Muhammad.
    await tester.tap(find.byTooltip('Menu akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar akun'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    await login(tester, 'NIK-005', 'rahasia123');

    // Laporan tetap ada dan masuk ke daftar tindakan Muhammad.
    await tester.tap(find.text('Tindakan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Laporan untuk Muhammad dari Unit Umum'), findsWidgets);

    // Muhammad bisa menyimpan tindak lanjut untuk laporan tersebut.
    final actionField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Tuliskan langkah tindak lanjut...',
    );
    await tester.enterText(actionField, 'Memeriksa jaringan di Unit Umum');
    await tester.ensureVisible(find.text('Tambah'));
    await tester.tap(find.text('Tambah'));
    await tester.pump();

    Get.find<TindakanController>().selectedStatus.value = 'On Progress';
    await tester.ensureVisible(find.text('Kirim Tindakan'));
    await tester.tap(find.text('Kirim Tindakan'));
    await tester.pump();

    expect(find.text('Tindak lanjut berhasil disimpan.'), findsOneWidget);
    expect(created['status'], 'On Progress');
    expect((created['detail_tindakan'] as List), isNotEmpty);

    // Tunggu snackbar hilang agar tidak ada timer yang tertinggal.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('login mengisi riwayat login karyawan di Master Karyawan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    addMuhammad(role: 'ROLE-02');

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.LOGIN, getPages: AppPages.routes),
    );
    await tester.pump();

    await login(tester, 'NIK-005', 'rahasia123');

    final store = MasterDataStore.ensure();
    final lastLogin = store.employee('NIK-005')?['last_login']?.toString();
    expect(lastLogin, isNotNull);
    expect(lastLogin, isNotEmpty);

    await tester.tap(find.text('Master Karyawan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    await tester.enterText(find.byType(TextField).first, 'NIK-005');
    await tester.pump();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final now = DateTime.now();
    final expectedDate = '${now.day} ${months[now.month - 1]} ${now.year}';

    expect(find.textContaining(expectedDate), findsWidgets);
    expect(find.text('Belum pernah'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
