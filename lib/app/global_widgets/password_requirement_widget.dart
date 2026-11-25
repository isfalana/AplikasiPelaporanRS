import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_buttons.dart';
import '../core/theme/app_colors.dart';
import '../data/services/api_services.dart';

// [MODIFIKASI] Kelas pembantu evaluasi kriteria keamanan kata sandi
class PasswordRequirementStatus {
  final String password;

  PasswordRequirementStatus(this.password);

  bool get hasMinLength => password.length >= 8;
  bool get hasLetter => RegExp(r'[a-zA-Z]').hasMatch(password);
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(password);
  bool get hasSymbol =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_~+\-=\[\]\\]').hasMatch(password);

  int get score {
    if (password.isEmpty) return 0;
    int count = 0;
    if (hasMinLength) count++;
    if (hasLetter) count++;
    if (hasNumber) count++;
    if (hasSymbol) count++;
    return count;
  }

  bool get isValid => hasMinLength && hasNumber && hasSymbol;

  String get label {
    if (password.isEmpty) return 'Belum diisi';
    switch (score) {
      case 1:
        return 'Sangat Lemah';
      case 2:
        return 'Lemah';
      case 3:
        return 'Sedang';
      case 4:
        return 'Kuat';
      default:
        return 'Sangat Lemah';
    }
  }

  Color get color {
    if (password.isEmpty) return AppColors.divider;
    switch (score) {
      case 1:
        return AppColors.error;
      case 2:
        return const Color(0xFFF97316); // Oranye
      case 3:
        return AppColors.warning; // Kuning
      case 4:
        return AppColors.success; // Hijau
      default:
        return AppColors.error;
    }
  }
}

// [MODIFIKASI] Widget visual indikator kekuatan password dan checklist syarat
class PasswordRequirementWidget extends StatelessWidget {
  const PasswordRequirementWidget({
    super.key,
    required this.password,
    this.compact = false,
  });

  final String password;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final status = PasswordRequirementStatus(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        // Bar Indikator Tingkat Keamanan
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: password.isEmpty ? 0.0 : status.score / 4.0,
                    backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(status.color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              status.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: password.isEmpty ? AppColors.textWeak : status.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Checklist Syarat Password
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckItem('Minimal 8 karakter', status.hasMinLength),
              const SizedBox(height: 4),
              _buildCheckItem('Mengandung angka (0-9)', status.hasNumber),
              const SizedBox(height: 4),
              _buildCheckItem(
                'Mengandung simbol khusus (!@#\$%^&*)',
                status.hasSymbol,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String label, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 14,
          color: isMet ? AppColors.success : AppColors.textWeak,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isMet ? AppColors.textStrong : AppColors.textWeak,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// [MODIFIKASI] Dialog Lupa Kata Sandi / Reset Password yang dapat diakses dari Login dan Profil Pengguna
Future<bool?> showResetPasswordDialog(
  BuildContext context, {
  String? initialNik,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _ResetPasswordDialog(initialNik: initialNik),
  );
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({this.initialNik});

  final String? initialNik;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nikController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nikController = TextEditingController(text: widget.initialNik ?? '');
  }

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final nik = _nikController.text.trim().toUpperCase();
    final newPassword = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    if (newPassword != confirmPassword) {
      Get.snackbar(
        'Perhatian',
        'Konfirmasi kata sandi tidak cocok.',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
      return;
    }

    final status = PasswordRequirementStatus(newPassword);
    if (!status.isValid) {
      Get.snackbar(
        'Perhatian',
        'Kata sandi belum memenuhi seluruh syarat keamanan.',
        backgroundColor: AppColors.warning,
        colorText: AppColors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = await ApiService.getClient();
      final response = await dio.post('/auth/reset-password', data: {
        'id_nik': nik,
        'new_password': newPassword,
      });

      if (response.statusCode == 200) {
        if (mounted) Navigator.of(context).pop(true);
        Get.snackbar(
          'Sukses',
          response.data?['message'] ??
              'Kata sandi berhasil diubah. Silakan masuk menggunakan kata sandi baru.',
          backgroundColor: AppColors.success,
          colorText: AppColors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan saat mereset kata sandi: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFixedNik = widget.initialNik != null && widget.initialNik!.isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Reset / Lupa Kata Sandi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Masukkan NIK Anda dan buat kata sandi baru yang memenuhi syarat keamanan.',
                  style: TextStyle(fontSize: 12, color: AppColors.textWeak),
                ),
                const SizedBox(height: 14),
                // NIK Field
                const Text(
                  'NIK Karyawan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textStrong),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nikController,
                  enabled: !isFixedNik && !_isLoading,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Contoh: NIK-001',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: isFixedNik,
                    fillColor: isFixedNik ? AppColors.surface : null,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'NIK karyawan wajib diisi.' : null,
                ),
                const SizedBox(height: 12),
                // Password Baru
                const Text(
                  'Kata Sandi Baru',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textStrong),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Minimal 8 karakter, angka & simbol',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return 'Kata sandi baru wajib diisi.';
                    final status = PasswordRequirementStatus(text);
                    if (!status.isValid) return 'Kata sandi belum memenuhi syarat keamanan.';
                    return null;
                  },
                ),
                // Realtime Password Strength & Requirement Widget
                PasswordRequirementWidget(password: _passwordController.text),
                const SizedBox(height: 12),
                // Konfirmasi Password Baru
                const Text(
                  'Konfirmasi Kata Sandi Baru',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textStrong),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Ulangi kata sandi baru',
                    prefixIcon: const Icon(Icons.lock_clock_outlined, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Konfirmasi kata sandi wajib diisi.';
                    if (v.trim() != _passwordController.text.trim()) {
                      return 'Konfirmasi kata sandi tidak cocok.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          style: AppButtons.outlined,
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: AppButtons.primary,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Ubah Kata Sandi'),
        ),
      ],
    );
  }
}
