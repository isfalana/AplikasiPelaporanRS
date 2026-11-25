// [MODIFIKASI] Stub helper untuk platform native non-web (Windows Desktop, Android, iOS)
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void requestSystemNotificationPermission() {
  // Fallback platform non-web
}

Future<bool> requestSystemNotificationPermissionAsync() async {
  return true;
}

bool isSystemNotificationGranted() {
  return true;
}

void showNativeSystemNotification({
  required String title,
  required String body,
  String? idLaporan,
  void Function()? onClick,
}) {
  debugPrint('[NativeNotification Stub] $title: $body');
}

// [MODIFIKASI] Memutar nada/suara sistem alert pada platform native
void playSystemNotificationSound() {
  try {
    SystemSound.play(SystemSoundType.alert);
  } catch (e) {
    debugPrint('[NativeNotification Stub] Gagal memutar suara notifikasi: $e');
  }
}
