// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// [MODIFIKASI] Pembuka kamera perangkat interaktif langsung di Flutter Web via WebRTC
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

Future<Map<String, dynamic>?> openDeviceCameraWeb() async {
  try {
    if (!js.context.hasProperty('openWebCameraCapture')) {
      return null;
    }

    final completer = Completer<Map<String, dynamic>?>();
    final promise = js.context.callMethod('openWebCameraCapture', []);
    if (promise == null) return null;

    promise.callMethod('then', [
      (dynamic result) {
        if (result == null) {
          completer.complete(null);
          return;
        }
        try {
          final jsObj = js.JsObject.fromBrowserObject(result);
          final name = jsObj['name']?.toString() ?? 'foto_kamera.jpg';
          final dataUrl = jsObj['dataUrl']?.toString() ?? '';
          completer.complete({
            'name': name,
            'dataUrl': dataUrl,
          });
        } catch (e) {
          debugPrint('[WebCamera] Gagal memparsing hasil kamera: $e');
          completer.complete(null);
        }
      }
    ]);

    promise.callMethod('catch', [
      (dynamic err) {
        debugPrint('[WebCamera] Error tangkapan kamera: $err');
        completer.complete(null);
      }
    ]);

    return await completer.future;
  } catch (e) {
    debugPrint('[WebCamera] Exception: $e');
    return null;
  }
}
