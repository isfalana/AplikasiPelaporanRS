// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// [MODIFIKASI] Kompresi gambar otomatis berbasis HTML5 Canvas di platform Web
import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

Future<Uint8List?> compressImageWeb(
  Uint8List bytes, {
  int maxDimension = 1600,
  double quality = 0.78,
}) async {
  try {
    if (!js.context.hasProperty('compressImageBytes')) {
      return null;
    }

    final completer = Completer<Uint8List?>();
    final base64Input = base64Encode(bytes);
    final promise = js.context.callMethod('compressImageBytes', [
      base64Input,
      maxDimension,
      quality,
    ]);

    if (promise == null) return null;

    promise.callMethod('then', [
      (dynamic result) {
        if (result == null) {
          completer.complete(null);
          return;
        }
        try {
          final dataUrl = result.toString();
          if (dataUrl.isEmpty) {
            completer.complete(null);
            return;
          }
          final base64Part = dataUrl.contains(',') ? dataUrl.split(',').last : dataUrl;
          final compressedBytes = base64Decode(base64Part);
          completer.complete(compressedBytes);
        } catch (e) {
          debugPrint('[FileCompress] Error decode hasil kompresi: $e');
          completer.complete(null);
        }
      }
    ]);

    promise.callMethod('catch', [
      (dynamic err) {
        debugPrint('[FileCompress] JS compress error: $err');
        completer.complete(null);
      }
    ]);

    return await completer.future;
  } catch (e) {
    debugPrint('[FileCompress] Exception: $e');
    return null;
  }
}
