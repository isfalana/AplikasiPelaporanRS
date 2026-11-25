import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';

import '../../../data/services/api_services.dart';
import '../../../data/services/master_data_store.dart';
import '../../../data/services/notification_service.dart';

class LaporanController extends GetxController {
  var isLoading = false.obs;
  // [MODIFIKASI] Target ID laporan yang dibuka melalui klik notifikasi
  final viewingReportId = RxnString();
  // [MODIFIKASI] Pemicu reset tampilan ke halaman awal (daftar laporan tanpa filter dan form bersih)
  final resetViewTrigger = 0.obs;

  void resetToInitialView() {
    viewingReportId.value = null;
    resetViewTrigger.value++;
    fetchLaporanData();
  }

  MasterDataStore get master => MasterDataStore.ensure();

  static const demoUserNames = <String, String>{
    'NIK-001': 'Admin IT',
    'NIK-002': 'Siti Aminah',
    'NIK-003': 'Budi Teknisi',
    'NIK-004': 'Andi IT',
  };

  static const demoUnitNames = <String, String>{
    'U-UMUM': 'Umum & Fasilitas',
    'U-PENDAFTARAN': 'Pendaftaran & Rekam Medis',
    'U-IT': 'Information Technology',
    'UNIT-UMUM': 'Umum & Fasilitas',
    'UNIT-IGD': 'Instalasi Gawat Darurat',
    'UNIT-IT': 'Teknologi Informasi',
    'UNIT-SDM': 'Sumber Daya Manusia',
  };

  List<Map<String, dynamic>> get listUnit => master.listUnit;
  // [MODIFIKASI] Mengembalikan nama unit kerja (bukan sekadar ID unit)
  String employeeUnitName(String nik) {
    final unitId = master.employeeUnit(nik);
    if (unitId.isEmpty) return '';
    return master.unitName(unitId);
  }
  List<Map<String, dynamic>> get kategoriOptions => master.listKategori;

  List<String> get employeeNiks => master.listKaryawan
      .map((karyawan) => karyawan['id_nik']?.toString().trim() ?? '')
      .where((nik) => nik.isNotEmpty)
      .toList();

  final listPrioritas = <Map<String, dynamic>>[
    {'id_prioritas': 'P-01', 'nama_prioritas': 'Kritis'},
    {'id_prioritas': 'P-02', 'nama_prioritas': 'Tinggi'},
    {'id_prioritas': 'P-03', 'nama_prioritas': 'Sedang'},
    {'id_prioritas': 'P-04', 'nama_prioritas': 'Rendah'},
  ].obs;

  String userName(String nik) {
    final key = nik.trim();
    if (key.isEmpty) return '';
    final name = master.employeeName(key);
    if (name.isNotEmpty && name != key) return name;
    return demoUserNames[key.toUpperCase()] ?? key;
  }

  String unitName(String unit) {
    final key = unit.trim();
    if (key.isEmpty) return '';
    final name = master.unitName(key);
    if (name.isNotEmpty && name != key) return name;
    return demoUnitNames[key.toUpperCase()] ?? key;
  }

  String kategoriName(String idKategori) {
    final key = idKategori.trim();
    if (key.isEmpty) return '';
    return master.kategoriName(key);
  }

  String employeeUnit(String nik) => master.employeeUnit(nik);

  var listLaporan = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchLaporanData();
    fetchPrioritas();
  }

  Future<void> fetchPrioritas() async {
    try {
      final dio = await ApiService.getClient();
      final res = await dio.get('/master/prioritas');
      if (res.statusCode == 200 && res.data['data'] != null) {
        final list = List<Map<String, dynamic>>.from(res.data['data']);
        if (list.isNotEmpty) {
          listPrioritas.assignAll(list);
        }
      }
    } catch (_) {}
  }

  Future<void> fetchLaporanData() async {
    isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get('/laporan');
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data['data'];
        if (raw is List) {
          final items = raw.map((item) {
            final m = Map<String, dynamic>.from(item);
            _normalizeReportItem(m);
            return m;
          }).toList();
          listLaporan.assignAll(items);
        }
      }
    } on DioException catch (e) {
      debugPrint('Error fetchLaporanData Dio: ${e.response?.data ?? e.message}');
    } catch (e) {
      debugPrint('Error fetchLaporanData: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _normalizeReportItem(Map<String, dynamic> m) {
    if (m['pelapor'] is Map) {
      m['nama_pelapor'] = m['pelapor']['nama_karyawan'] ?? m['nama_pelapor'];
    }
    if (m['unit_pelapor'] is Map) {
      m['nama_unit_pelapor'] = m['unit_pelapor']['nama_unit'] ?? m['nama_unit_pelapor'];
    }
    if (m['kategori'] is Map) {
      m['nama_kategori'] = m['kategori']['nama_kategori'] ?? m['nama_kategori'];
    }
    if (m['prioritas'] is Map) {
      m['prioritas_nama'] = m['prioritas']['nama_prioritas'];
      m['prioritas'] = m['prioritas']['nama_prioritas'];
    }
    if (m['penugasan_pic'] is List) {
      final picNiks = (m['penugasan_pic'] as List)
          .map((p) {
            if (p is Map) {
              return p['id_nik_pic'] ?? p['pic']?['id_nik'];
            }
            return p?.toString();
          })
          .where((v) => v != null && v.toString().trim().isNotEmpty)
          .map((v) => v.toString().trim())
          .toList();
      m['id_nik_pic'] = picNiks.join(', ');

      final picNames = (m['penugasan_pic'] as List)
          .map((p) {
            if (p is Map && p['pic'] is Map) {
              return p['pic']['nama_karyawan']?.toString();
            }
            return null;
          })
          .whereType<String>()
          .toList();
      if (picNames.isNotEmpty) {
        m['nama_pic'] = picNames.join(', ');
      } else {
        // [MODIFIKASI] Jika nama_pic belum ada di penugasan_pic, cari nama karyawan dari MasterDataStore berdasarkan NIK
        final resolvedNames = picNiks.map((nik) => master.employeeName(nik)).toList();
        if (resolvedNames.isNotEmpty) {
          m['nama_pic'] = resolvedNames.join(', ');
        }
      }
    } else if (m['id_nik_pic'] != null) {
      // [MODIFIKASI] Jika penugasan_pic bukan list tapi id_nik_pic ada, pecah dan cari nama karyawan
      final niks = m['id_nik_pic'].toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final names = niks.map((nik) => master.employeeName(nik)).toList();
      if (names.isNotEmpty) {
        m['nama_pic'] = names.join(', ');
      }
    }
    // Tanggal selesai jika status COMPLETED
    if (m['status'] == 'COMPLETED' && m['approved_at'] != null) {
      final dt = DateTime.tryParse(m['approved_at'].toString());
      if (dt != null) {
        m['tgl_selesai'] =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    }

    // [MODIFIKASI] Normalisasi detail tindakan dan status is_completed agar detail laporan sinkron
    if (m['detail_tindakan'] is List) {
      m['detail_tindakan'] = (m['detail_tindakan'] as List).map((item) {
        if (item is! Map) return item;
        final d = Map<String, dynamic>.from(item);
        d['id_detail'] = d['id_detail_tindakan'] ?? d['id_detail'];
        d['deskripsi_tindakan'] = d['nama_tindakan'] ?? d['deskripsi_tindakan'] ?? '';
        d['selesai'] = d['is_completed'] == true || d['selesai'] == true;
        return d;
      }).toList();
    }

    // [MODIFIKASI] Ambil keterangan dan bukti tindak lanjut dari laporan atau tabel evidence
    m['keterangan_tindakan'] = m['keterangan_tindakan'] ?? m['catatan_tindakan'];
    if (m['evidence'] is List && (m['evidence'] as List).isNotEmpty) {
      final evList = (m['evidence'] as List).whereType<Map>().toList();
      if (evList.isNotEmpty) {
        final firstEv = evList.first;
        final reportFileName = firstEv['original_name']?.toString() ?? firstEv['file_path']?.toString() ?? '';
        if (m['bukti'] == null || m['bukti'].toString().isEmpty || m['bukti'] == '-') {
          m['bukti'] = reportFileName;
        }
        final evId = firstEv['id_evidence']?.toString() ?? m['id_evidence']?.toString();
        if (evId != null && evId.isNotEmpty) {
          m['id_evidence'] = evId;
          m['bukti_url'] = '${ApiService.baseUrl}/evidence/file/$evId';
        } else if (firstEv['file_path'] != null) {
          m['bukti_url'] = '${ApiService.rootUrl}/storage/evidence/${firstEv['file_path']}';
        }

        Map? actionEv;
        for (final e in evList.reversed) {
          if (e['id_detail_tindakan'] != null || evList.length > 1) {
            actionEv = e;
            break;
          }
        }
        if (actionEv != null && actionEv != firstEv) {
          final actFileName = actionEv['original_name']?.toString() ?? actionEv['file_path']?.toString() ?? '';
          if (m['bukti_tindakan'] == null || m['bukti_tindakan'].toString().isEmpty || m['bukti_tindakan'] == '-') {
            m['bukti_tindakan'] = actFileName;
          }
          final actEvId = actionEv['id_evidence']?.toString();
          if (actEvId != null && actEvId.isNotEmpty) {
            m['id_evidence_tindakan'] = actEvId;
            m['bukti_tindakan_url'] = '${ApiService.baseUrl}/evidence/file/$actEvId';
          } else if (actionEv['file_path'] != null) {
            m['bukti_tindakan_url'] = '${ApiService.rootUrl}/storage/evidence/${actionEv['file_path']}';
          }
        }
      }
    }

    // Pastikan jika backend mengirim bukti_url relatif, ubah menjadi full URL yang dapat diakses
    if (m['bukti_url'] != null && m['bukti_url'].toString().startsWith('/')) {
      m['bukti_url'] = '${ApiService.rootUrl}${m['bukti_url']}';
    }
    if (m['bukti_tindakan_url'] != null && m['bukti_tindakan_url'].toString().startsWith('/')) {
      m['bukti_tindakan_url'] = '${ApiService.rootUrl}${m['bukti_tindakan_url']}';
    }

    // [MODIFIKASI] Normalisasi riwayat laporan (history) agar nama PIC ditampilkan berdasarkan NIK
    if (m['history'] is List) {
      m['history'] = (m['history'] as List).map((h) {
        if (h is! Map) return h;
        final hist = Map<String, dynamic>.from(h);
        final newVal = hist['new_value'] is Map ? Map<String, dynamic>.from(hist['new_value'] as Map) : null;
        if (newVal != null && newVal['id_nik_pics'] is List) {
          final nList = newVal['id_nik_pics'] as List;
          final names = nList.map((nik) => master.employeeName(nik.toString())).toList();
          newVal['nama_pics'] = names;
          newVal['pics'] = nList.map((nik) => {
            'id_nik': nik.toString(),
            'nama_karyawan': master.employeeName(nik.toString()),
          }).toList();
          hist['new_value'] = newVal;

          // Format deskripsi riwayat agar memuat nama karyawan PIC, bukan hanya NIK
          var desc = hist['description']?.toString() ?? '';
          if (desc.contains('Laporan baru dibuat') && !desc.contains('PIC:')) {
            hist['description'] = 'Laporan baru dibuat. PIC: ${names.join(', ')}';
          } else if (desc == 'Penugasan PIC diperbarui') {
            hist['description'] = 'Penugasan PIC diperbarui: ${names.join(', ')}';
          }
        }
        return hist;
      }).toList();
    }

    // [MODIFIKASI] Normalisasi last_update_by agar selalu menampilkan nama karyawan dan unit kerja
    String? resolvedLastUpdate = m['last_update_by']?.toString() ??
        m['lastUpdateBy']?.toString() ??
        m['update_by']?.toString();
    if (resolvedLastUpdate == null ||
        resolvedLastUpdate.trim().isEmpty ||
        resolvedLastUpdate.trim() == '-') {
      // 1. Cek dari riwayat laporan (history) terbaru
      if (m['history'] is List && (m['history'] as List).isNotEmpty) {
        final histList = List<Map<String, dynamic>>.from(
          (m['history'] as List).whereType<Map>(),
        );
        histList.sort((a, b) {
          final tA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(1970);
          final tB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(1970);
          return tB.compareTo(tA);
        });
        if (histList.isNotEmpty) {
          final latest = histList.first;
          if (latest['actor'] is Map) {
            final act = latest['actor'] as Map;
            final aName = act['nama_karyawan']?.toString() ?? '';
            final aUnit = act['unit'] is Map
                ? act['unit']['nama_unit']?.toString() ?? ''
                : (act['nama_unit']?.toString() ?? '');
            if (aName.isNotEmpty) {
              resolvedLastUpdate = aUnit.isNotEmpty ? '$aName · $aUnit' : aName;
            }
          }
          if (resolvedLastUpdate == null || resolvedLastUpdate.isEmpty) {
            final actorId = latest['actor_id']?.toString() ?? '';
            if (actorId.isNotEmpty) {
              final aName = master.employeeName(actorId);
              final aUnit = employeeUnitName(actorId);
              final parts = [aName, aUnit].where((v) => v.isNotEmpty && v != '-').toList();
              if (parts.isNotEmpty) {
                resolvedLastUpdate = parts.join(' · ');
              } else {
                resolvedLastUpdate = actorId;
              }
            }
          }
        }
      }
      // 2. Jika riwayat belum ada, gunakan pelapor sebagai fallback
      if (resolvedLastUpdate == null || resolvedLastUpdate.trim().isEmpty || resolvedLastUpdate == '-') {
        final pNik = m['id_nik_pelapor']?.toString() ?? '';
        final pName = m['nama_pelapor']?.toString() ?? (pNik.isNotEmpty ? master.employeeName(pNik) : '');
        final pUnit = m['nama_unit_pelapor']?.toString() ?? (pNik.isNotEmpty ? employeeUnitName(pNik) : '');
        final parts = [pName, pUnit].where((v) => v.isNotEmpty && v != '-').toList();
        if (parts.isNotEmpty) {
          resolvedLastUpdate = parts.join(' · ');
        }
      }
    } else {
      // Jika last_update_by sudah ada tetapi hanya berupa NIK tanpa format nama · unit
      final raw = resolvedLastUpdate.trim();
      if (!raw.contains('·') && !raw.contains(' - ') && !raw.contains(' ')) {
        final aName = master.employeeName(raw);
        final aUnit = employeeUnitName(raw);
        final parts = [aName, aUnit].where((v) => v.isNotEmpty && v != '-').toList();
        if (parts.isNotEmpty) {
          resolvedLastUpdate = parts.join(' · ');
        }
      }
    }

    if (resolvedLastUpdate != null && resolvedLastUpdate.trim().isNotEmpty) {
      m['last_update_by'] = resolvedLastUpdate.trim();
      m['lastUpdateBy'] = resolvedLastUpdate.trim();
    }
  }

  // [MODIFIKASI] Helper untuk memastikan format tanggal selalu ISO YYYY-MM-DD
  String _toIsoDate(String dateStr) {
    final trimmed = dateStr.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) return trimmed;
    final dmyMatch = RegExp(r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$').firstMatch(trimmed);
    if (dmyMatch != null) {
      final day = dmyMatch.group(1)!.padLeft(2, '0');
      final month = dmyMatch.group(2)!.padLeft(2, '0');
      final year = dmyMatch.group(3)!;
      return '$year-$month-$day';
    }
    return trimmed;
  }

  // [MODIFIKASI] POST Laporan ke backend dengan tanggal ISO YYYY-MM-DD dan mapping prioritas akurat
  Future<bool> createReport({
    required String tglKejadian,
    required String idKategori,
    required String deadline,
    required String perihal,
    String? keterangan,
    String? idPrioritas,
    required List<String> idNikPics,
    Uint8List? buktiBytes,
    String? buktiFilename,
  }) async {
    try {
      isLoading.value = true;
      final dio = await ApiService.getClient();

      // [MODIFIKASI] Resolusi ID prioritas dari nama ('Tinggi' -> 'P-02') atau ID langsung
      String? prioritasId = idPrioritas;
      if (prioritasId != null && prioritasId.isNotEmpty) {
        final searchKey = prioritasId.toLowerCase();
        final match = listPrioritas.firstWhereOrNull(
          (p) =>
              p['id_prioritas']?.toString().toLowerCase() == searchKey ||
              p['nama_prioritas']?.toString().toLowerCase() == searchKey,
        );
        if (match != null) {
          prioritasId = match['id_prioritas']?.toString();
        }
      }

      // [MODIFIKASI] Format body dengan tanggal ISO YYYY-MM-DD yang diterima PostgreSQL
      final body = {
        'tgl_kejadian': _toIsoDate(tglKejadian),
        'id_kategori': idKategori,
        'deadline': _toIsoDate(deadline),
        'perihal': perihal,
        'keterangan': keterangan ?? '',
        if (prioritasId != null && prioritasId.isNotEmpty)
          'id_prioritas': prioritasId,
        'id_nik_pics': idNikPics,
      };

      final response = await dio.post('/laporan', data: body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final newReport = response.data['data'];
        final reportId = newReport?['id_laporan']?.toString();

        if (reportId != null && buktiBytes != null && buktiBytes.isNotEmpty) {
          try {
            final formData = FormData.fromMap({
              'id_laporan': reportId,
              'file': MultipartFile.fromBytes(
                buktiBytes,
                filename: buktiFilename ?? 'bukti_laporan.jpg',
              ),
            });
            await dio.post('/evidence', data: formData);
          } catch (e) {
            debugPrint('Gagal upload evidence: $e');
          }
        }

        // [MODIFIKASI] Refresh data laporan dari backend setelah sukses membuat laporan baru
        await fetchLaporanData();
        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.fetchNotifications(silent: true);
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal membuat laporan';
      Get.snackbar('Gagal', msg.toString(),
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // [MODIFIKASI] Update detail laporan ke backend PUT /laporan/:id (Hanya Pelapor / Admin, Dilarang untuk PIC)
  Future<bool> updateReport({
    required String idLaporan,
    required String perihal,
    required String tglKejadian,
    required String idKategori,
    required String deadline,
    required String idPrioritas,
    required List<String> idNikPics,
    String? keterangan,
    Uint8List? buktiBytes,
    String? buktiFilename,
  }) async {
    try {
      isLoading.value = true;
      final dio = await ApiService.getClient();

      // Resolusi ID prioritas jika nama prioritas yang diteruskan
      String prioritasId = idPrioritas;
      final searchKey = prioritasId.toLowerCase();
      final match = listPrioritas.firstWhereOrNull(
        (p) =>
            p['id_prioritas']?.toString().toLowerCase() == searchKey ||
            p['nama_prioritas']?.toString().toLowerCase() == searchKey,
      );
      if (match != null) {
        prioritasId = match['id_prioritas']?.toString() ?? prioritasId;
      }

      final body = {
        'perihal': perihal,
        'tgl_kejadian': _toIsoDate(tglKejadian),
        'id_kategori': idKategori,
        'deadline': _toIsoDate(deadline),
        'id_prioritas': prioritasId,
        'id_nik_pics': idNikPics,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
      };

      final response = await dio.put('/laporan/$idLaporan', data: body);
      if (response.statusCode == 200) {
        // Jika terdapat unggahan bukti baru saat edit laporan
        if (buktiBytes != null && buktiBytes.isNotEmpty) {
          try {
            final formData = FormData.fromMap({
              'id_laporan': idLaporan,
              'file': MultipartFile.fromBytes(
                buktiBytes,
                filename: buktiFilename ?? 'bukti_laporan.jpg',
              ),
            });
            await dio.post('/evidence', data: formData);
          } catch (e) {
            debugPrint('Gagal upload evidence saat edit: $e');
          }
        }

        await fetchLaporanData();
        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.fetchNotifications(silent: true);
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memperbarui laporan';
      Get.snackbar('Gagal', msg.toString(),
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // [MODIFIKASI] Update penugasan PIC laporan ke backend PUT /laporan/:id/pics
  Future<bool> updateReportPics({
    required String idLaporan,
    required List<String> idNikPics,
  }) async {
    try {
      isLoading.value = true;
      final dio = await ApiService.getClient();
      final res = await dio.put('/laporan/$idLaporan/pics', data: {
        'id_nik_pics': idNikPics,
      });
      if (res.statusCode == 200) {
        await fetchLaporanData();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memperbarui PIC';
      Get.snackbar('Gagal', msg.toString(),
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateApprovalStatus({
    required String idLaporan,
    required String status, // 'COMPLETED' atau 'RETURNED'
    String? approvalNote,
  }) async {
    try {
      isLoading.value = true;
      final dio = await ApiService.getClient();
      final body = {
        'status': status,
        if (approvalNote != null && approvalNote.trim().isNotEmpty)
          'approval_note': approvalNote.trim(),
      };

      final response = await dio.put('/laporan/$idLaporan/status', data: body);
      if (response.statusCode == 200) {
        await fetchLaporanData();
        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.fetchNotifications(silent: true);
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memproses status approval';
      Get.snackbar('Gagal', msg.toString(),
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // [MODIFIKASI] Simpan keterangan dan bukti tindak lanjut ke backend
  Future<bool> saveTindakLanjut({
    required String idLaporan,
    required String keteranganTindakan,
    String? buktiTindakan,
  }) async {
    try {
      isLoading.value = true;
      final dio = await ApiService.getClient();
      final body = {
        'keterangan_tindakan': keteranganTindakan,
        if (buktiTindakan != null && buktiTindakan.isNotEmpty)
          'bukti_tindakan': buktiTindakan,
      };

      final response = await dio.put('/laporan/$idLaporan/tindak-lanjut', data: body);
      if (response.statusCode == 200) {
        await fetchLaporanData();
        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.fetchNotifications(silent: true);
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menyimpan keterangan tindak lanjut';
      Get.snackbar('Gagal', msg.toString(),
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// [MODIFIKASI] Hapus laporan (soft-delete) via backend API (khusus Admin atau Pelapor)
  Future<bool> deleteReport(String idLaporan) async {
    try {
      final dio = await ApiService.getClient();
      final response = await dio.delete('/laporan/$idLaporan');
      if (response.statusCode == 200) {
        listLaporan.removeWhere((l) => l['id_laporan']?.toString() == idLaporan);
        listLaporan.refresh();
        await fetchLaporanData();
        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.fetchNotifications(silent: true);
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menghapus laporan';
      Get.snackbar('Gagal', msg.toString(),
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan saat menghapus laporan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }
}
