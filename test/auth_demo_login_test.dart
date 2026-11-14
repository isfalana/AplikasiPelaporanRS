import 'package:aplikasilaporan/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('demo PIC logs in and opens assigned actions', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.LOGIN, getPages: AppPages.routes),
    );
    await tester.pump();

    expect(find.text('Kerusakan AC Ruang IGD'), findsNothing);
    expect(find.byType(Card), findsNothing);

    await tester.tap(find.textContaining('PIC Umum'));
    await tester.tap(find.text('Masuk'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, Routes.DASHBOARD);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('id_nik'), 'NIK-002');
    expect(preferences.getString('unit_name'), 'UNIT-UMUM');
    expect(preferences.getString('nama_karyawan'), 'PIC Umum');

    await tester.tap(find.text('Tindakan'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, Routes.TINDAKAN);
    expect(find.text('Kerusakan AC Ruang IGD'), findsNWidgets(2));
    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
