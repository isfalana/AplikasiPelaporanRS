import 'package:aplikasilaporan/app/routes/app_pages.dart';
import 'package:aplikasilaporan/app/global_widgets/report_style_card.dart';
import 'package:aplikasilaporan/app/modules/laporan/controllers/laporan_controller.dart';
import 'package:aplikasilaporan/app/modules/tindakan/controllers/tindakan_controller.dart';
import 'package:aplikasilaporan/app/core/theme/app_colors.dart';
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

  testWidgets('PIC can add and save a follow-up for an assigned report', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.TINDAKAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Kerusakan AC Ruang IGD'), findsNWidgets(2));
    expect(find.text('Permintaan Perbaikan Jaringan LAN'), findsNothing);
    expect(find.text('Daftar Tindakan'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    final cardTitleFinder = find.text('Kerusakan AC Ruang IGD').last;
    final cardTitle = tester.widget<Text>(cardTitleFinder);
    expect(cardTitle.style?.fontSize, 15);
    expect(cardTitle.style?.fontWeight, FontWeight.w700);
    expect(find.byType(ReportStyleCard), findsWidgets);
    final cardMaterial = tester.widget<Material>(
      find.ancestor(of: cardTitleFinder, matching: find.byType(Material)).first,
    );
    expect(cardMaterial.color, AppColors.white);
    expect(cardMaterial.surfaceTintColor, AppColors.white);
    expect(find.text('Keterangan laporan'), findsNothing);

    final tindakanController = Get.find<TindakanController>();
    expect(tindakanController.noteController.text, isEmpty);

    final actionField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Tuliskan langkah tindak lanjut...',
    );
    await tester.enterText(actionField, 'Memeriksa unit AC');
    await tester.tap(find.text('Tambah'));
    await tester.pump();
    expect(find.text('Memeriksa unit AC'), findsOneWidget);
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
    expect(checkbox.value, isFalse);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);

    final noteField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Tuliskan keterangan tindak lanjut...',
    );
    await tester.enterText(noteField, 'Pemeriksaan awal selesai.');
    tindakanController.selectedStatus.value = 'On Progress';
    await tester.ensureVisible(find.text('Kirim Tindakan'));
    await tester.tap(find.text('Kirim Tindakan'));
    await tester.pump();

    expect(find.text('Tindak lanjut berhasil disimpan.'), findsOneWidget);
    expect(find.text('Kerusakan AC Ruang IGD'), findsNWidgets(2));
    final savedReport = Get.find<LaporanController>().listLaporan.first;
    expect(
      savedReport['keterangan'],
      'AC tidak dingin dan mengeluarkan bunyi bising di ruangan IGD.',
    );
    expect(savedReport['keterangan_tindakan'], 'Pemeriksaan awal selesai.');
    expect(savedReport['status'], 'On Progress');
    final savedDetail =
        (savedReport['detail_tindakan'] as List<Map<String, dynamic>>).single;
    expect(savedReport['progres_tindakan'], [
      {'id_detail': savedDetail['id_detail'], 'selesai': true},
    ]);
    expect(savedDetail.keys.toSet(), {
      'id_detail',
      'id_laporan',
      'id_nik_pic',
      'deskripsi_tindakan',
      'file_lampiran',
    });
    Get.offNamed(Routes.LAPORAN);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kerusakan AC Ruang IGD').first);
    await tester.pumpAndSettle();
    expect(find.text('Memeriksa unit AC'), findsOneWidget);
    expect(find.text('Pemeriksaan awal selesai.'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('On Progress'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('sidebar opens the Tindakan page', (tester) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.DASHBOARD, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Tindakan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(Get.currentRoute, Routes.TINDAKAN);
    expect(find.text('Daftar Tindakan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tindakan layout fits a mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.TINDAKAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, AppColors.white);
    expect(appBar.surfaceTintColor, AppColors.white);
    expect(find.text('Informasi Laporan'), findsOneWidget);
    expect(find.text('Daftar Tindakan'), findsOneWidget);
    final reportId = tester.getRect(find.text('ID laporan').first);
    final reportDate = tester.getRect(find.text('Tanggal laporan').first);
    expect(reportId.top, closeTo(reportDate.top, 1));
    expect(reportId.left, lessThan(reportDate.left));
    expect(tester.takeException(), isNull);
  });
}
