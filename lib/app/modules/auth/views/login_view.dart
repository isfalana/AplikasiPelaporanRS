import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang utama (abu-abu sangat terang / surface)
      backgroundColor: AppColors.surface, 
      body: ResponsiveLayout(
        mobile: _buildLoginForm(context, isMobile: true),
        desktop: Center(
          child: Container(
            // Container Box tidak mepet layar (lebar max 420px)
            width: 420,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: _buildLoginForm(context, isMobile: false),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, {required bool isMobile}) {
    return SafeArea(
      child: SingleChildScrollView(
        // Padding untuk versi mobile agar tidak mepet
        padding: EdgeInsets.all(isMobile ? 24.0 : 0), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Judul Utama (Primary Color)
            const Text(
              'Selamat datang di\nAplikasi Lapor Permata',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subjudul
            const Text(
              'Masukan akun anda untuk masuk ke dalam aplikasi',
              textAlign: TextAlign.left,
              style: TextStyle(color: AppColors.textStrong, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            // Label dan Input Username
            const Text('Username', style: TextStyle(color: AppColors.textStrong, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: controller.usernameController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // Label dan Input Kata Sandi
            const Text('Kata Sandi', style: TextStyle(color: AppColors.textStrong, fontSize: 14)),
            const SizedBox(height: 8),
            Obx(() => TextField(
              controller: controller.passwordController,
              obscureText: controller.isPasswordHidden.value,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordHidden.value ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textWeak,
                  ),
                  onPressed: controller.togglePasswordView,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
            )),
            
            // Teks Lupa Sandi
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Lupa kata sandi?', style: TextStyle(color: AppColors.textWeak)),
              ),
            ),
            const SizedBox(height: 24),
            
            // Tombol Masuk
            Center(
              child: Obx(() => SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                      : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}