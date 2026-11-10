import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Deteksi platform untuk menentukan Base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:3000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // IP khusus untuk Emulator Android agar bisa mengakses localhost host komputer
        return 'http://10.0.2.2:3000/api';
      default:
        // Windows Desktop, macOS, Linux, dll.
        return 'http://127.0.0.1:3000/api';
    }
  }

  static Dio? _dioInstance;

  static Future<Dio> getClient() async {
    if (_dioInstance == null) {
      _dioInstance = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      _dioInstance!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // Ambil token JWT terbaru dari SharedPreferences untuk setiap request
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? token = prefs.getString('jwt_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (DioException e, handler) {
            debugPrint('API Error [${e.response?.statusCode}]: ${e.message}');
            return handler.next(e);
          },
        ),
      );
    }
    return _dioInstance!;
  }
}