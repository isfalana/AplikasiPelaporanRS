import 'package:aplikasilaporan/app/modules/auth/controllers/dashboard_controller.dart';
import 'package:aplikasilaporan/app/modules/auth/views/dashboard_view.dart';
import 'package:aplikasilaporan/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('dashboard adapts between desktop and mobile layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    Get.put(DashboardController());
    await tester.pumpWidget(const GetMaterialApp(home: DashboardView()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Prioritas tindak lanjut'), findsOneWidget);
    expect(find.text('Tanggal laporan'), findsWidgets);
    expect(find.text('Last update by'), findsWidgets);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Mid'), findsWidgets);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('On Progress'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Ciutkan sidebar'));
    for (var frame = 0; frame < 15; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byTooltip('Buka sidebar'));
    for (var frame = 0; frame < 15; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }

    tester.view.physicalSize = const Size(799, 800);
    await tester.pump();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(800, 800);
    await tester.pump();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(390, 800);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard sidebar opens the reports page', (tester) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.DASHBOARD, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Laporan RS'), findsOneWidget);
    expect(Get.currentRoute, Routes.LAPORAN);
    expect(find.text('Daftar Laporan'), findsOneWidget);
    expect(find.text('Kirim'), findsOneWidget);
    expect(find.text('Kerusakan AC Ruang IGD'), findsOneWidget);
    expect(find.text('Tanggal laporan'), findsWidgets);
    expect(find.text('Deadline'), findsWidgets);
    expect(find.text('Last update by'), findsWidgets);
    final subjectField = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ringkasan perihal kendala...',
      ),
    );
    final evidenceField = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText ==
                'Pilih atau masukkan nama file bukti',
      ),
    );
    expect(evidenceField.top, lessThan(subjectField.top));
    expect(subjectField.width, greaterThan(evidenceField.width));

    await tester.ensureVisible(find.text('Kerusakan AC Ruang IGD'));
    await tester.tap(find.text('Kerusakan AC Ruang IGD'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Laporan'), findsOneWidget);
    expect(find.text('UNIT-IGD'), findsOneWidget);

    await tester.ensureVisible(find.text('Kembali ke daftar'));
    await tester.tap(find.text('Kembali ke daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Kirim'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Edit laporan').first);
    await tester.tap(find.byTooltip('Edit laporan').first);
    await tester.pumpAndSettle();
    expect(find.text('Perbarui'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, Routes.DASHBOARD);
    expect(find.text('Prioritas tindak lanjut'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report form uses two columns on a mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.LAPORAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    final reportDate = tester.getRect(find.text('Tanggal laporan').first);
    final eventDate = tester.getRect(find.text('Tanggal kejadian'));
    expect(reportDate.top, closeTo(eventDate.top, 1));
    expect(reportDate.left, lessThan(eventDate.left));
    expect(tester.takeException(), isNull);
  });
}
