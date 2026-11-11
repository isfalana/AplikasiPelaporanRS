import 'package:aplikasilaporan/app/core/theme/app_colors.dart';
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

  testWidgets('report page displays and filters data on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.REPORT, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Report'), findsWidgets);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Export Excel'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Kerusakan AC Ruang IGD'), findsOneWidget);
    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsOneWidget);

    // Tombol export ada di sisi kanan dan berwarna: PDF merah, Excel hijau.
    final pdfButtonFinder = find.widgetWithText(ElevatedButton, 'Export PDF');
    final excelButtonFinder = find.widgetWithText(
      ElevatedButton,
      'Export Excel',
    );
    final pdfStyle = tester.widget<ElevatedButton>(pdfButtonFinder).style;
    final excelStyle = tester.widget<ElevatedButton>(excelButtonFinder).style;
    expect(
      pdfStyle?.backgroundColor?.resolve(const <WidgetState>{}),
      AppColors.error,
    );
    expect(
      excelStyle?.backgroundColor?.resolve(const <WidgetState>{}),
      AppColors.success,
    );
    expect(tester.getRect(excelButtonFinder).right, greaterThan(1440 * 0.8));

    // Tabel panjang bisa digulir ke kanan dan ke kiri.
    final horizontalScrollFinder = find.ancestor(
      of: find.byType(DataTable),
      matching: find.byWidgetPredicate(
        (widget) => widget is Scrollable && widget.axis == Axis.horizontal,
      ),
    );
    expect(horizontalScrollFinder, findsOneWidget);
    final horizontalScroll = tester.state<ScrollableState>(
      horizontalScrollFinder,
    );
    expect(horizontalScroll.position.maxScrollExtent, greaterThan(0));
    await tester.drag(horizontalScrollFinder, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(horizontalScroll.position.pixels, greaterThan(0));

    await tester.enterText(find.byType(TextField), 'Kerusakan AC Ruang IGD');
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.text('Kerusakan AC Ruang IGD'),
      ),
      findsOneWidget,
    );
    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report page uses cards on a mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.REPORT, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Report'), findsWidgets);
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Kerusakan AC Ruang IGD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Report sidebar item opens the report page', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.DASHBOARD, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, Routes.REPORT);
    expect(find.text('Export PDF'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
