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

  Future<void> openPage(WidgetTester tester, String route, Size size) async {
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

  testWidgets('dashboard prioritas card can be filtered', (tester) async {
    await openPage(tester, Routes.DASHBOARD, const Size(1440, 1000));

    expect(find.text('Perbaikan IBS & Penambahan Mesin Cuci'), findsOneWidget);
    expect(
      find.text('Follow up MOU dengan dr Enung Sp PD EMD'),
      findsOneWidget,
    );
    expect(
      find.text('Buat link untuk progres tindaklanjut IT'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Filter daftar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prioritas: Tinggi'));
    await tester.pumpAndSettle();

    expect(find.text('Perbaikan IBS & Penambahan Mesin Cuci'), findsOneWidget);
    expect(find.text('Follow up MOU dengan dr Enung Sp PD EMD'), findsNothing);
    expect(find.text('Buat link untuk progres tindaklanjut IT'), findsNothing);

    // Kembali ke semua data.
    await tester.tap(find.byTooltip('Filter daftar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    expect(
      find.text('Follow up MOU dengan dr Enung Sp PD EMD'),
      findsOneWidget,
    );
  });

  testWidgets('laporan list can be filtered by status', (tester) async {
    await openPage(tester, Routes.LAPORAN, const Size(1440, 1000));

    expect(find.text('Kerusakan AC Ruang IGD'), findsOneWidget);
    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsOneWidget);

    await tester.tap(find.byTooltip('Filter daftar'));
    await tester.pumpAndSettle();

    // Filter tampil sebagai bottom sheet dengan pilihan berbentuk chip.
    expect(
      find.text('Pilih satu atau lebih prioritas dan status.'),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('On Progress'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Terapkan'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsOneWidget);
    expect(find.text('Kerusakan AC Ruang IGD'), findsNothing);
  });

  testWidgets('tindakan list can be filtered by priority', (tester) async {
    await openPage(tester, Routes.TINDAKAN, const Size(1440, 1000));

    // NIK-002 hanya menerima LAP-001 (prioritas Tinggi).
    // Perihal muncul di form informasi dan di daftar kartu.
    expect(find.text('Kerusakan AC Ruang IGD'), findsWidgets);

    await tester.tap(find.byTooltip('Filter daftar'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Sedang'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Terapkan'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Belum ada pesan tindakan untuk akun ini.'),
      findsOneWidget,
    );
  });

  testWidgets('filter bottom sheet can be reset', (tester) async {
    await openPage(tester, Routes.LAPORAN, const Size(1440, 1000));

    await tester.tap(find.byTooltip('Filter daftar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Open'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Terapkan'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kerusakan AC Ruang IGD'), findsOneWidget);
    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsNothing);

    await tester.tap(find.byTooltip('Filter daftar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Reset'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Terapkan'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsOneWidget);
  });

  testWidgets('laporan filter accepts multiple priorities and statuses', (
    tester,
  ) async {
    await openPage(tester, Routes.LAPORAN, const Size(1440, 1000));

    await tester.tap(find.byTooltip('Filter daftar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Tinggi'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Sedang'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Terapkan'),
      ),
    );
    await tester.pumpAndSettle();

    // Dua prioritas dipilih sekaligus: kedua laporan tampil.
    expect(find.text('Kerusakan AC Ruang IGD'), findsOneWidget);
    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsOneWidget);

    // Tambah filter status Open: hanya laporan Open yang tampil.
    await tester.tap(find.byTooltip('Filter daftar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Open'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Terapkan'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kerusakan AC Ruang IGD'), findsOneWidget);
    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsNothing);
  });

  testWidgets('dashboard mobile keeps refresh in the app bar', (tester) async {
    await openPage(tester, Routes.DASHBOARD, const Size(390, 844));

    final refresh = find.byTooltip('Muat ulang data');
    expect(refresh, findsOneWidget);
    // Tombol refresh berada di app bar (atas layar), sama seperti versi desktop.
    expect(tester.getRect(refresh).top, lessThan(80));
  });
}
