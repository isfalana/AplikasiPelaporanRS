// [MODIFIKASI] Abstraksi pemanggil notifikasi sistem latar belakang (Background Native Notification)
import 'notification_platform_stub.dart'
    if (dart.library.html) 'notification_platform_web.dart';

abstract class NotificationPlatformHelper {
  /// Meminta izin notifikasi browser/OS
  static void requestPermission() {
    requestSystemNotificationPermission();
  }

  /// [MODIFIKASI] Meminta izin notifikasi browser/OS secara asynchronous (dipicu dari interaksi pengguna)
  static Future<bool> requestPermissionAsync() async {
    return requestSystemNotificationPermissionAsync();
  }

  /// [MODIFIKASI] Memeriksa apakah izin notifikasi browser/OS telah diberikan
  static bool isPermissionGranted() {
    return isSystemNotificationGranted();
  }

  /// Menampilkan popup notifikasi sistem/OS di latar belakang (desktop Windows/web browser)
  static void showBackgroundNotification({
    required String title,
    required String body,
    String? idLaporan,
    void Function()? onClick,
  }) {
    showNativeSystemNotification(
      title: title,
      body: body,
      idLaporan: idLaporan,
      onClick: onClick,
    );
  }

  /// [MODIFIKASI] Memutar nada/suara pemberitahuan (audio alert chime)
  static void playNotificationSound() {
    playSystemNotificationSound();
  }
}
