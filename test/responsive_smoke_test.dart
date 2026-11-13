import 'package:aplikasilaporan/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Ukuran layar umum: dari ponsel kecil sampai desktop lebar.
  const screenSizes = [
    Size(320, 800),
    Size(360, 800),
    Size(390, 844),
    Size(412, 800),
    Size(600, 800),
    Size(768, 1024),
    Size(800, 900),
    Size(900, 900),
    Size(1024, 800),
    Size(1280, 800),
    Size(1440, 900),
    Size(1920, 1080),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'id_nik': 'NIK-002',
      'unit_name': 'UNIT-UMUM',
    });
  });

  for (final size in screenSizes) {
    for (final route in [
      Routes.LOGIN,
      Routes.DASHBOARD,
      Routes.LAPORAN,
      Routes.TINDAKAN,
      Routes.REPORT,
      Routes.MASTER_UNIT,
      Routes.MASTER_KARYAWAN,
      Routes.MASTER_KATEGORI,
      Routes.MASTER_ROLE,
    ]) {
      testWidgets(
        '${route.replaceAll('/', '')} aman di ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(Get.reset);

          await tester.pumpWidget(
            GetMaterialApp(initialRoute: route, getPages: AppPages.routes),
          );
          await tester.pump(const Duration(seconds: 2));
          expect(tester.takeException(), isNull);

          // Gulir sampai bawah untuk memicu layout seluruh konten.
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -3000),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
