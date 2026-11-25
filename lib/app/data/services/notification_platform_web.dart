// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// [MODIFIKASI] Implementasi Web Notification API untuk background desktop popup di peramban Web
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

void requestSystemNotificationPermission() {
  try {
    if (js.context.hasProperty('requestWebNotificationPermission')) {
      js.context.callMethod('requestWebNotificationPermission', []);
      return;
    }
    if (html.Notification.supported) {
      if (html.Notification.permission != 'granted' &&
          html.Notification.permission != 'denied') {
        html.Notification.requestPermission();
      }
    }
  } catch (e) {
    debugPrint('[WebNotification] Gagal request permission: $e');
  }
}

Future<bool> requestSystemNotificationPermissionAsync() async {
  try {
    if (js.context.hasProperty('requestWebNotificationPermission')) {
      final completer = Completer<bool>();
      final promise = js.context.callMethod('requestWebNotificationPermission', []);
      if (promise != null) {
        promise.callMethod('then', [
          (dynamic result) {
            final resStr = result?.toString() ?? '';
            debugPrint('[WebNotification] Permission result: $resStr');
            completer.complete(resStr == 'granted');
          }
        ]);
        promise.callMethod('catch', [
          (dynamic err) {
            debugPrint('[WebNotification] Permission error: $err');
            completer.complete(false);
          }
        ]);
        return await completer.future;
      }
    }
    if (html.Notification.supported) {
      if (html.Notification.permission == 'granted') return true;
      final perm = await html.Notification.requestPermission();
      return perm == 'granted';
    }
    return false;
  } catch (e) {
    debugPrint('[WebNotification] Gagal request permission async: $e');
    return false;
  }
}

bool isSystemNotificationGranted() {
  try {
    if (html.Notification.supported) {
      return html.Notification.permission == 'granted';
    }
    return false;
  } catch (_) {
    return false;
  }
}

void showNativeSystemNotification({
  required String title,
  required String body,
  String? idLaporan,
  void Function()? onClick,
}) {
  try {
    if (js.context.hasProperty('showWebNotification')) {
      final tag = idLaporan ?? 'lapor_${DateTime.now().millisecondsSinceEpoch}';
      final url = idLaporan != null ? '#/pelaporan' : '#/dashboard';
      js.context.callMethod('showWebNotification', [title, body, tag, url]);
      return;
    }

    if (!html.Notification.supported) return;
    if (html.Notification.permission == 'granted') {
      final notif = html.Notification(
        title,
        body: body,
        icon: 'favicon.png',
        tag: idLaporan ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );
      if (onClick != null) {
        notif.onClick.listen((_) => onClick());
      }
    } else if (html.Notification.permission != 'denied') {
      html.Notification.requestPermission().then((perm) {
        if (perm == 'granted') {
          final notif = html.Notification(
            title,
            body: body,
            icon: 'favicon.png',
            tag: idLaporan ?? DateTime.now().millisecondsSinceEpoch.toString(),
          );
          if (onClick != null) {
            notif.onClick.listen((_) => onClick());
          }
        }
      });
    }
  } catch (e) {
    debugPrint('[WebNotification] Gagal menampilkan notifikasi browser: $e');
  }
}

// [MODIFIKASI] Memutar nada chime audio notifikasi pada platform Web
void playSystemNotificationSound() {
  try {
    if (js.context.hasProperty('playNotificationChime')) {
      js.context.callMethod('playNotificationChime', []);
    }
  } catch (e) {
    debugPrint('[WebNotification] Gagal memutar nada chime notifikasi: $e');
  }
}
