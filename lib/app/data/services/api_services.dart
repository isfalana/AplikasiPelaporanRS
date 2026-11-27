import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Deteksi platform untuk menentukan Base URL
  static String get baseUrl {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'https://collectors-basically-unified-itself.trycloudflare.com/api';
    } else {
      // IP khusus untuk Emulator Android agar bisa mengakses localhost komputer
      return 'https://collectors-basically-unified-itself.trycloudflare.com/api';
    }
  }

  // [MODIFIKASI] Root URL backend untuk mengakses file statis (misal /storage/evidence/...)
  static String get rootUrl {
    final url = baseUrl;
    if (url.endsWith('/api')) {
      return url.substring(0, url.length - 4);
    }
    return url;
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static Future<Dio> getClient() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
    return _dio;
  }
}
