// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart'; // Wajib diimpor
import 'app/routes/app_pages.dart';
import 'firebase_options.dart'; // Buka komentar ini jika Anda sudah men-generate konfigurasi Firebase CLI

void main() async {
  // Wajib ditambahkan agar binding Flutter siap sebelum Firebase dipanggil
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase belum terkonfigurasi sepenuhnya: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Lapor Permata',
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}