// lib/app/core/utils/responsive_layout.dart
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  // Tambahkan dua baris static helper ini untuk mendeteksi ukuran layar
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 800;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 800;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Jika lebar layar 800px ke atas, tampilkan versi Desktop
        if (constraints.maxWidth >= 800) {
          return desktop;
        } 
        // Jika di bawah 800px (HP), tampilkan versi Mobile
        else {
          return mobile;
        }
      },
    );
  }
}