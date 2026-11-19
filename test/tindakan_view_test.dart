import 'dart:typed_data';

import 'package:aplikasilaporan/app/data/services/master_data_store.dart';
import 'package:aplikasilaporan/app/routes/app_pages.dart';
import 'package:aplikasilaporan/app/global_widgets/bukti_preview.dart';
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
    expect(find.text('permasalahan'), findsWidgets);
    expect(find.text('KAT-01'), findsNothing);
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
    await tester.ensureVisible(find.text('Tambah'));
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

  testWidgets('form Tindakan menampilkan bukti laporan dari pelapor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    final laporanController = Get.put(LaporanController(), permanent: true);
    final report = laporanController.listLaporan.first;
    report['bukti'] = 'bukti_kerusakan.pdf';
    report['bukti_bytes'] = Uint8List.fromList([1, 2, 3, 4]);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.TINDAKAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Bukti laporan pelapor'), findsOneWidget);
    expect(find.text('Bukti laporan'), findsNothing);
    expect(find.text('bukti_kerusakan.pdf'), findsWidgets);
    expect(find.byType(BuktiPreviewTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hanya PIC yang melihat pesan tindakan', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    final laporanController = Get.put(LaporanController(), permanent: true);
    laporanController.listLaporan.insert(0, {
      'id_laporan': 'LAP-PIC-IT',
      'tgl_laporan': '2026-11-16',
      'tgl_kejadian': '2026-11-16',
      'deadline': '2026-11-17',
      'id_nik_pelapor': 'NIK-002',
      'nama_pelapor': 'Rina Kartika',
      'id_unit_pelapor': 'UNIT-UMUM',
      'nama_unit_pelapor': 'Unit Umum',
      'id_kategori': 'KAT-01',
      'id_nik_pic': 'NIK-004',
      'id_unit_pic': 'UNIT-IT',
      'id_tindak_lanjut': 'TL-04',
      'perihal': 'Laporan hanya untuk unit IT',
      'prioritas': 'Tinggi',
      'status': 'Open',
    });
    laporanController.listLaporan.refresh();

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.TINDAKAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Laporan hanya untuk unit IT'), findsNothing);
    expect(find.text('Kerusakan AC Ruang IGD'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rekan satu unit bukan PIC tidak melihat laporan PIC lain', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    // Muhammad adalah PIC di Unit IT; user lain (NIK-004) juga di Unit IT.
    MasterDataStore.ensure().listKaryawan.add({
      'id_nik': 'NIK-005',
      'nama_karyawan': 'Muhammad',
      'id_unit': 'UNIT-IT',
      'id_role': 'ROLE-01',
      'last_login': null,
    });
    SharedPreferences.setMockInitialValues({
      'id_nik': 'NIK-004',
      'unit_name': 'UNIT-IT',
    });

    final laporanController = Get.put(LaporanController(), permanent: true);
    laporanController.listLaporan.insert(0, {
      'id_laporan': 'LAP-PIC-MUHAMMAD',
      'tgl_laporan': '2026-11-16',
      'tgl_kejadian': '2026-11-16',
      'deadline': '2026-11-17',
      'id_nik_pelapor': 'NIK-002',
      'nama_pelapor': 'Rina Kartika',
      'id_unit_pelapor': 'UNIT-UMUM',
      'nama_unit_pelapor': 'Unit Umum',
      'id_kategori': 'KAT-01',
      'id_nik_pic': 'NIK-005',
      'id_unit_pic': 'UNIT-IT',
      'id_tindak_lanjut': 'TL-05',
      'perihal': 'Laporan khusus untuk Muhammad IT',
      'prioritas': 'Tinggi',
      'status': 'Open',
    });
    laporanController.listLaporan.refresh();

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.TINDAKAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Laporan khusus untuk Muhammad IT'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PIC yang ditunjuk tetap melihat laporannya', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    MasterDataStore.ensure().listKaryawan.add({
      'id_nik': 'NIK-005',
      'nama_karyawan': 'Muhammad',
      'id_unit': 'UNIT-IT',
      'id_role': 'ROLE-01',
      'last_login': null,
    });
    SharedPreferences.setMockInitialValues({
      'id_nik': 'NIK-005',
      'unit_name': 'UNIT-IT',
    });

    final laporanController = Get.put(LaporanController(), permanent: true);
    laporanController.listLaporan.insert(0, {
      'id_laporan': 'LAP-PIC-MUHAMMAD',
      'tgl_laporan': '2026-11-16',
      'tgl_kejadian': '2026-11-16',
      'deadline': '2026-11-17',
      'id_nik_pelapor': 'NIK-002',
      'nama_pelapor': 'Rina Kartika',
      'id_unit_pelapor': 'UNIT-UMUM',
      'nama_unit_pelapor': 'Unit Umum',
      'id_kategori': 'KAT-01',
      'id_nik_pic': 'NIK-005',
      'id_unit_pic': 'UNIT-IT',
      'id_tindak_lanjut': 'TL-05',
      'perihal': 'Laporan khusus untuk Muhammad IT',
      'prioritas': 'Tinggi',
      'status': 'Open',
    });
    laporanController.listLaporan.refresh();

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.TINDAKAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Laporan khusus untuk Muhammad IT'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ID tindak lanjut terisi otomatis untuk laporan baru', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    final laporanController = Get.put(LaporanController(), permanent: true);
    laporanController.listLaporan.insert(0, {
      'id_laporan': 'LAP-BARU',
      'tgl_laporan': '2026-11-16',
      'tgl_kejadian': '2026-11-16',
      'deadline': '2026-11-17',
      'id_nik_pelapor': 'NIK-001',
      'nama_pelapor': 'dr. Enung Sp.PD',
      'id_unit_pelapor': 'UNIT-IGD',
      'nama_unit_pelapor': 'Instalasi Gawat Darurat',
      'id_kategori': 'KAT-01',
      'id_nik_pic': 'NIK-002',
      'id_tindak_lanjut': null,
      'perihal': 'Laporan baru tanpa ID tindak lanjut',
      'prioritas': 'Sedang',
      'status': 'Open',
    });
    laporanController.listLaporan.refresh();

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.TINDAKAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Laporan baru tanpa ID tindak lanjut'), findsWidgets);
    expect(find.text('TL-03'), findsWidgets);
    expect(laporanController.listLaporan.first['id_tindak_lanjut'], 'TL-03');
    expect(tester.takeException(), isNull);
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

  testWidgets('informasi laporan menampilkan tanggal dan deadline', (
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

    expect(find.text('Tanggal laporan'), findsWidgets);
    expect(find.text('Deadline'), findsWidgets);
    expect(find.text('09/11/2026'), findsWidgets);
    expect(find.text('11/11/2026'), findsWidgets);
    expect(find.text('2026-11-09'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('laporan baru dari halaman Laporan muncul di Tindakan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    final laporanController = Get.put(LaporanController(), permanent: true);

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.LAPORAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ringkasan perihal kendala...',
      ),
      'Laporan uji muncul di tindakan',
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
    await tester.tap(find.textContaining('Rina Kartika').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Kirim'));
    await tester.tap(find.text('Kirim'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    final created = laporanController.listLaporan.first;
    expect(created['perihal'], 'Laporan uji muncul di tindakan');
    expect(created['id_nik_pic'], 'NIK-002');

    Get.offNamed(Routes.TINDAKAN);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Laporan uji muncul di tindakan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card tindakan menandai laporan Done yang tervalidasi pelapor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    final laporanController = Get.put(LaporanController(), permanent: true);
    laporanController.listLaporan.insert(0, {
      'id_laporan': 'LAP-VALID',
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
      'perihal': 'Laporan selesai dan tervalidasi',
      'prioritas': 'Sedang',
      'status': 'Done',
      'validasi_pelapor': true,
      'tgl_validasi': '17/11/2026',
    });
    laporanController.listLaporan.refresh();

    await tester.pumpWidget(
      GetMaterialApp(initialRoute: Routes.TINDAKAN, getPages: AppPages.routes),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Laporan selesai dan tervalidasi'), findsWidgets);
    expect(find.text('Tervalidasi pelapor'), findsOneWidget);
    expect(find.text('Done'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menyimpan tindakan Done mengisi tanggal mulai dan selesai', (
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

    final actionField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Tuliskan langkah tindak lanjut...',
    );
    await tester.enterText(actionField, 'Menyelesaikan tindak lanjut');
    await tester.ensureVisible(find.text('Tambah'));
    await tester.tap(find.text('Tambah'));
    await tester.pump();

    // Status Done baru boleh dipilih setelah tindakan dicentang.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    final tindakanController = Get.find<TindakanController>();
    tindakanController.selectedStatus.value = 'Done';
    await tester.ensureVisible(find.text('Kirim Tindakan'));
    await tester.tap(find.text('Kirim Tindakan'));
    await tester.pumpAndSettle();

    final savedReport = Get.find<LaporanController>().listLaporan.first;
    expect(savedReport['status'], 'Done');
    expect(savedReport['tgl_mulai_tindakan'], isNotEmpty);
    expect(savedReport['tgl_selesai'], isNotEmpty);
    expect(savedReport['validasi_pelapor'], isFalse);

    Get.offNamed(Routes.REPORT);
    await tester.pumpAndSettle();
    expect(find.text(savedReport['tgl_mulai_tindakan']), findsWidgets);
    expect(find.text(savedReport['tgl_selesai']), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('centang dari template tidak menular ke tindakan lain', (
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

    final tindakanController = Get.find<TindakanController>();
    // Template berisi beberapa langkah yang ditambahkan beruntun.
    tindakanController.actionTemplates.assignAll([
      {
        'id_template': 'TPL-UJI',
        'nama_template': 'Template Uji',
        'list_tindakan': [
          {'deskripsi_tindakan': 'Langkah satu'},
          {'deskripsi_tindakan': 'Langkah dua'},
          {'deskripsi_tindakan': 'Langkah tiga'},
        ],
      },
    ]);
    tindakanController.selectedTemplateId.value = 'TPL-UJI';
    await tester.pump();

    await tester.ensureVisible(find.text('Terapkan'));
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();
    // Tutup notifikasi template agar tidak menutupi tombol kirim.
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNWidgets(3));
    // Setiap tindakan harus punya ID unik.
    final ids = tindakanController.actionItems
        .map((item) => item['id_detail'])
        .toSet();
    expect(ids.length, 3);

    // Centang hanya tindakan kedua.
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    tindakanController.selectedStatus.value = 'On Progress';
    await tester.ensureVisible(find.text('Kirim Tindakan'));
    await tester.tap(find.text('Kirim Tindakan'));
    await tester.pumpAndSettle();

    final savedReport = Get.find<LaporanController>().listLaporan.first;
    final progress = (savedReport['progres_tindakan'] as List)
        .cast<Map<String, dynamic>>();
    expect(progress.where((item) => item['selesai'] == true).length, 1);
    expect(progress[1]['selesai'], isTrue);
    expect(progress[0]['selesai'], isFalse);
    expect(progress[2]['selesai'], isFalse);

    // Saat laporan dibuka kembali, hanya satu tindakan yang tetap tercentang.
    tindakanController.selectReport(savedReport);
    await tester.pump();
    expect(
      tindakanController.actionItems
          .where((item) => item['selesai'] == true)
          .length,
      1,
    );
    expect(tindakanController.actionItems[1]['selesai'], isTrue);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('status Done ditolak bila tindakan belum semua dicentang', (
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

    final actionField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Tuliskan langkah tindak lanjut...',
    );
    await tester.enterText(actionField, 'Tindakan belum selesai');
    await tester.ensureVisible(find.text('Tambah'));
    await tester.tap(find.text('Tambah'));
    await tester.pump();

    final tindakanController = Get.find<TindakanController>();
    tindakanController.selectedStatus.value = 'Done';
    await tester.ensureVisible(find.text('Kirim Tindakan'));
    await tester.tap(find.text('Kirim Tindakan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Centang semua tindakan sebelum mengubah status menjadi Done.'),
      findsWidgets,
    );
    final report = Get.find<LaporanController>().listLaporan.first;
    expect(report['status'], isNot('Done'));

    // Setelah semua tindakan dicentang, status Done boleh disimpan.
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.ensureVisible(find.text('Kirim Tindakan'));
    await tester.tap(find.text('Kirim Tindakan'));
    await tester.pumpAndSettle();

    expect(report['status'], 'Done');
    expect(report['tgl_selesai'], isNotEmpty);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
