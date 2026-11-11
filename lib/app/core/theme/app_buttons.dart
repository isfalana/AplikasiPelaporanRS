// lib/app/core/theme/app_buttons.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Style button bersama untuk form di seluruh aplikasi.
///
/// Semua button memakai bentuk yang sama (radius sudut dan ukuran padding),
/// yang membedakan antar tombol hanyalah warna.
class AppButtons {
  AppButtons._();

  /// Radius sudut semua button form.
  static const double radius = 8;

  /// Padding bersama agar tinggi semua button seragam.
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 12,
  );

  /// Bentuk bersama semua button form.
  static final RoundedRectangleBorder shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
  );

  /// Button terisi warna utama (ungu) — aksi utama seperti Kirim/Perbarui.
  static final ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 0,
    padding: _padding,
    shape: shape,
  );

  /// Button terisi merah — khusus export PDF.
  static final ButtonStyle danger = ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.white,
    elevation: 0,
    padding: _padding,
    shape: shape,
  );

  /// Button terisi hijau — khusus export Excel.
  static final ButtonStyle success = ElevatedButton.styleFrom(
    backgroundColor: AppColors.success,
    foregroundColor: AppColors.white,
    elevation: 0,
    padding: _padding,
    shape: shape,
  );

  /// Button outline — pasangan button terisi (bentuk sama, beda warna).
  static final ButtonStyle outlined = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary),
    padding: _padding,
    shape: shape,
  );
}
