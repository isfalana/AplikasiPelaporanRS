import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../modules/laporan/controllers/laporan_controller.dart';
import '../../routes/app_pages.dart';
import 'api_services.dart';
import 'notification_platform_helper.dart';

// [MODIFIKASI] Service terpusat untuk notifikasi lintas platform (Web, Desktop, Mobile)
// Mengelola in-app notifications, status badge, FCM push tokens, polling real-time cepat (5s), 
// dan pop-up latar belakang (Web Background Native Notification)
class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final notifications = <Map<String, dynamic>>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;
  // [MODIFIKASI] State toggle notifikasi perangkat latar belakang
  final isDeviceNotificationEnabled = false.obs;

  Timer? _pollingTimer;
  int _lastKnownUnreadCount = 0;
  bool _isInitialized = false;
  bool _isInitialFetch = true;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  /// Inisialisasi service: setup FCM (Web/Mobile), polling (Desktop/Web/Mobile), dan ambil notifikasi awal
  Future<void> init() async {
    // Muat preferensi status notifikasi perangkat
    final prefs = await SharedPreferences.getInstance();
    final savedEnabled = prefs.getBool('device_notification_enabled');
    if (savedEnabled != null) {
      isDeviceNotificationEnabled.value = savedEnabled;
    } else {
      isDeviceNotificationEnabled.value = NotificationPlatformHelper.isPermissionGranted();
    }

    // Muat notifikasi awal
    await fetchNotifications(silent: true);

    // Minta izin notifikasi browser / OS di latar belakang
    requestPermission();

    if (!_isInitialized) {
      _isInitialized = true;
      // Setup Firebase Cloud Messaging untuk Web & Mobile
      _setupFcm();

      // Setup periodic polling real-time setiap 5 detik untuk sinkronisasi cepat
      _startPolling();
    }
  }

  /// [MODIFIKASI] Mengaktifkan atau menonaktifkan notifikasi perangkat latar belakang
  Future<void> toggleDeviceNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    isDeviceNotificationEnabled.value = enabled;
    await prefs.setBool('device_notification_enabled', enabled);

    if (enabled) {
      bool sysGranted = false;
      try {
        sysGranted = await NotificationPlatformHelper.requestPermissionAsync();
      } catch (e) {
        debugPrint('[NotificationService] Request permission error: $e');
      }

      // [MODIFIKASI] Putar nada suara notifikasi sebagai konfirmasi audio aktif
      NotificationPlatformHelper.playNotificationSound();

      // Pop-up notifikasi foreground dalam aplikasi konfirmasi aktif
      _showInAppToast(
        title: 'Notifikasi Perangkat Aktif',
        body: 'Pemberitahuan laporan dan tindak lanjut aktif di perangkat ini.',
      );

      // Pop-up sistem background jika didukung oleh peramban / OS
      if (sysGranted) {
        NotificationPlatformHelper.showBackgroundNotification(
          title: 'Notifikasi Perangkat Aktif',
          body: 'Notifikasi laporan dan tindak lanjut akan muncul di perangkat ini.',
        );
      }
    } else {
      _showInAppToast(
        title: 'Notifikasi Dinonaktifkan',
        body: 'Pemberitahuan perangkat telah dimatikan.',
      );
    }
  }

  /// Meminta izin notifikasi sistem / browser
  void requestPermission() {
    NotificationPlatformHelper.requestPermission();
  }

  /// Setup Firebase Cloud Messaging (hanya di Web dan Mobile)
  Future<void> _setupFcm() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('[NotificationService] Desktop Windows menggunakan In-App Polling notifications');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission untuk Web & Mobile
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[NotificationService] Status izin FCM: ${settings.authorizationStatus}');

      // Ambil FCM Token
      String? fcmToken;
      try {
        fcmToken = await messaging.getToken();
      } catch (tokenErr) {
        debugPrint('[NotificationService] Info FCM token: $tokenErr');
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('[NotificationService] FCM Token diperoleh: $fcmToken');
        await registerFcmToken(fcmToken);
      }

      // Dengarkan pembaharuan token
      messaging.onTokenRefresh.listen((newToken) {
        registerFcmToken(newToken);
      });

      // Dengarkan pesan yang masuk saat aplikasi sedang dibuka (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Pesan foreground diterima: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // Dengarkan jika notifikasi diklik saat aplikasi di background / terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Notifikasi diklik di background: ${message.data}');
        final idLaporan = message.data['id_laporan']?.toString();
        if (idLaporan != null && idLaporan.isNotEmpty) {
          openLaporanDetail(idLaporan);
        }
      });
    } catch (e) {
      debugPrint('[NotificationService] Info inisialisasi FCM: $e');
    }
  }

  /// Registrasi FCM Token ke backend API
  Future<void> registerFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token');
      if (jwt == null || jwt.isEmpty) return;

      final dio = await ApiService.getClient();
      String platformName = 'web';
      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          platformName = 'android';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          platformName = 'ios';
        } else if (defaultTargetPlatform == TargetPlatform.windows) {
          platformName = 'windows';
        }
      }

      await dio.put('/auth/fcm-token', data: {
        'fcm_token': token,
        'platform': platformName,
        'device_id': 'app_$platformName',
      });
      debugPrint('[NotificationService] FCM Token berhasil didaftarkan');
    } catch (e) {
      debugPrint('[NotificationService] Info mendaftarkan FCM Token: $e');
    }
  }

  /// Menjalankan interval polling berkala setiap 5 detik untuk sinkronisasi notifikasi real-time
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchNotifications(silent: true);
    });
  }

  /// Menangani pesan yang masuk saat aplikasi aktif di foreground
  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notifikasi Baru';
    final body = message.notification?.body ?? '';
    final idLaporan = message.data['id_laporan']?.toString();

    // Refresh daftar notifikasi dari backend
    fetchNotifications(silent: true);

    // [MODIFIKASI] Putar nada suara audio saat notifikasi baru masuk
    NotificationPlatformHelper.playNotificationSound();

    // Tampilkan snackbar interaktif di layar
    _showInAppToast(title: title, body: body, idLaporan: idLaporan);

    // Tampilkan juga notifikasi latar belakang jika pengguna mengaktifkannya
    if (isDeviceNotificationEnabled.value) {
      NotificationPlatformHelper.showBackgroundNotification(
        title: title,
        body: body,
        idLaporan: idLaporan,
        onClick: () {
          if (idLaporan != null && idLaporan.isNotEmpty) {
            openLaporanDetail(idLaporan);
          }
        },
      );
    }
  }

  /// Menampilkan banner/toast mengambang di aplikasi
  void _showInAppToast({
    required String title,
    required String body,
    String? idLaporan,
  }) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFF6366F1), size: 28),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      duration: const Duration(seconds: 5),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
      mainButton: (idLaporan != null && idLaporan.isNotEmpty)
          ? TextButton(
              onPressed: () {
                if (Get.isSnackbarOpen) {
                  Get.closeCurrentSnackbar();
                }
                openLaporanDetail(idLaporan);
              },
              child: const Text(
                'Lihat',
                style: TextStyle(
                  color: Color(0xFF818CF8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  /// Mengambil daftar notifikasi dari server
  Future<void> fetchNotifications({bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null || jwt.isEmpty) return;

    if (!silent) isLoading.value = true;
    try {
      final dio = await ApiService.getClient();
      final response = await dio.get('/notifications', queryParameters: {
        'limit': 30,
      });

      if (response.statusCode == 200 && response.data?['data'] != null) {
        final data = response.data['data'];
        final list = (data['notifications'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final count = (data['unread_count'] as num? ?? 0).toInt();

        // Jika polling mendeteksi notifikasi baru yang masuk setelah inisialisasi
        if (!_isInitialFetch && count > _lastKnownUnreadCount && list.isNotEmpty) {
          final newest = list.first;
          if (newest['is_read'] != true) {
            final title = newest['title']?.toString() ?? 'Notifikasi Baru';
            final body = newest['body']?.toString() ?? '';
            final idLaporan = newest['id_laporan']?.toString();

            // [MODIFIKASI] Putar nada suara audio saat laporan baru/perubahan diterima
            NotificationPlatformHelper.playNotificationSound();

            // 1. Pop-up di dalam aplikasi (Foreground Toast)
            _showInAppToast(
              title: title,
              body: body,
              idLaporan: idLaporan,
            );

            // 2. Pop-up sistem di latar belakang jika diaktifkan pada perangkat ini
            if (isDeviceNotificationEnabled.value) {
              NotificationPlatformHelper.showBackgroundNotification(
                title: title,
                body: body,
                idLaporan: idLaporan,
                onClick: () {
                  if (idLaporan != null && idLaporan.isNotEmpty) {
                    openLaporanDetail(idLaporan);
                  }
                },
              );
            }
          }
        }

        _isInitialFetch = false;
        _lastKnownUnreadCount = count;
        notifications.value = list;
        unreadCount.value = count;
      }
    } catch (e) {
      debugPrint('[NotificationService] Gagal fetch notifications: $e');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Menandai satu notifikasi sebagai telah dibaca
  Future<void> markAsRead(String idNotification) async {
    try {
      final dio = await ApiService.getClient();
      await dio.put('/notifications/$idNotification/read');

      // Update status lokal
      final index = notifications.indexWhere(
        (n) => n['id_notification']?.toString() == idNotification,
      );
      if (index != -1) {
        final updated = Map<String, dynamic>.from(notifications[index]);
        if (updated['is_read'] != true) {
          updated['is_read'] = true;
          notifications[index] = updated;
          if (unreadCount.value > 0) unreadCount.value--;
          _lastKnownUnreadCount = unreadCount.value;
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Gagal markAsRead: $e');
    }
  }

  /// Menandai semua notifikasi sebagai telah dibaca
  Future<void> markAllAsRead() async {
    try {
      final dio = await ApiService.getClient();
      await dio.put('/notifications/read-all');

      final updatedList = notifications.map((n) {
        final m = Map<String, dynamic>.from(n);
        m['is_read'] = true;
        return m;
      }).toList();

      notifications.value = updatedList;
      unreadCount.value = 0;
      _lastKnownUnreadCount = 0;
    } catch (e) {
      debugPrint('[NotificationService] Gagal markAllAsRead: $e');
    }
  }

  /// Membuka detail laporan terkait ketika notifikasi diklik
  Future<void> openLaporanDetail(String idLaporan, {String? type}) async {
    if (idLaporan.isEmpty) return;

    // Jika laporan berjenis penghapusan, jangan arahkan ke halaman detail karena sudah tidak ada di backend
    if (type == 'REPORT_DELETED' || type == 'DELETE_REPORT') {
      Get.snackbar(
        'Laporan Telah Dihapus',
        'Laporan ini telah dihapus dari sistem sehingga detail laporan tidak lagi tersedia.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    try {
      // Pastikan LaporanController aktif
      LaporanController laporanCtrl;
      if (Get.isRegistered<LaporanController>()) {
        laporanCtrl = Get.find<LaporanController>();
      } else {
        laporanCtrl = Get.put(LaporanController());
      }

      await laporanCtrl.fetchLaporanData();
      final exists = laporanCtrl.listLaporan.any(
        (r) => r['id_laporan']?.toString() == idLaporan,
      );

      if (!exists) {
        Get.snackbar(
          'Laporan Tidak Tersedia',
          'Laporan ini telah dihapus atau Anda tidak memiliki akses ke laporan tersebut.',
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      laporanCtrl.viewingReportId.value = idLaporan;

      if (Get.currentRoute != Routes.LAPORAN) {
        Get.toNamed(Routes.LAPORAN);
      }
    } catch (e) {
      debugPrint('[NotificationService] Gagal membuka detail laporan: $e');
    }
  }
}
