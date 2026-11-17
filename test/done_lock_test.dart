import 'package:aplikasilaporan/app/modules/laporan/controllers/laporan_controller.dart';
import 'package:aplikasilaporan/app/modules/tindakan/controllers/tindakan_controller.dart';
import 'package:aplikasilaporan/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _doneReport() => {
  'id_laporan': 'LAP-DONE',
  'tgl_laporan': '16/11/2026',
  'tgl_kejadian': '15/11/2026',
  'deadline': '17/11/2026',
  'id_unit_pelapor': 'UNIT-UMUM',
  'id_nik_pelapor': 'NIK-002',
  'nama_pelapor': 'Rina Kartika',
  'id_unit_pic': 'UNIT-UMUM',
  'id_nik_pic': 'NIK-002',
  'id_kategori': 'KAT-01',
  'id_tindak_lanjut': 'TL-08',
  'perihal': 'Laporan selesai dan final',
  'prioritas': 'Sedang',
  'status': 'Done',
  'detail_tindakan': [
    {'id_detail': 'DT-DONE-1', 'deskripsi_tindakan': 'Langkah satu'},
    {'id_detail': 'DT-DONE-2', 'deskripsi_tindakan': 'Langkah dua'},
  ],
  'progres_tindakan': [
    {'id_detail': 'DT-DONE-1', 'selesai': true},
    {'id_detail': 'DT-DONE-2', 'selesai': true},
  ],
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'id_nik': 'NIK-002',
      'unit_name': 'UNIT-UMUM',
    });
  });

  testWidgets('laporan Done tidak menampilkan tombol edit', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    final laporanController = Get.put(LaporanController(), permanent: true);
    laporanController.listLaporan.assignAll([_doneReport()]);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.LAPORAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Laporan selesai dan final'), findsWidgets);
    expect(find.text('Done'), findsWidgets);
    // Tombol edit disembunyikan karena laporan sudah final.
    expect(find.byTooltip('Edit laporan'), findsNothing);
    expect(find.text('Perbarui'), findsNothing);

    // Detail laporan tetap bisa dibuka untuk melihat riwayat.
    await tester.tap(find.text('Laporan selesai dan final').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail Laporan'), findsOneWidget);
    expect(find.text('Perbarui'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tindakan laporan Done dikunci dari perubahan', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    final laporanController = Get.put(LaporanController(), permanent: true);
    laporanController.listLaporan.insert(0, _doneReport());
    laporanController.listLaporan.refresh();

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.TINDAKAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    final controller = Get.find<TindakanController>();
    expect(controller.selectedReport.value?['id_laporan'], 'LAP-DONE');

    // Pemberitahuan bahwa laporan sudah final.
    expect(
      find.text(
        'Laporan ini sudah Done. Data tindak lanjut tidak dapat diubah lagi.',
      ),
      findsOneWidget,
    );

    // Tombol kirim, centang, dan tambah tindakan dinonaktifkan.
    final submit = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Kirim Tindakan'),
    );
    expect(submit.onPressed, isNull);

    final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
    expect(checkboxes, isNotEmpty);
    expect(checkboxes.every((checkbox) => checkbox.onChanged == null), isTrue);

    final addButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Tambah'),
    );
    expect(addButton.onPressed, isNull);

    // Controller juga menolak seluruh perubahan pada laporan Done.
    final actionCount = controller.actionItems.length;
    expect(controller.addActionItem('Langkah baru'), isFalse);
    expect(controller.actionItems.length, actionCount);

    controller.toggleActionItem(0, false);
    expect(controller.actionItems[0]['selesai'], isTrue);

    controller.removeActionItem(0);
    expect(controller.actionItems.length, actionCount);

    expect(
      controller.applyTemplateById('TPL-UJI'),
      'Laporan yang sudah Done tidak dapat diubah lagi.',
    );
    expect(
      controller.saveAction(),
      'Laporan yang sudah Done tidak dapat diubah lagi.',
    );

    // Data laporan tidak berubah setelah semua percobaan di atas.
    final report = laporanController.listLaporan.first;
    expect(report['status'], 'Done');
    expect(
      (report['progres_tindakan'] as List).every(
        (item) => (item as Map)['selesai'] == true,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
