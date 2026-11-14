import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';

// Palet khusus halaman login agar terasa lebih tenang dan premium tanpa
// mengubah warna brand utama aplikasi.
const _ink = Color(0xFF191725);
const _paper = Color(0xFFF7F5FB);
const _fieldBorder = Color(0xFFE7E2F0);
const _accentSoft = Color(0xFFCBA8F7);

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Layar lebar memakai komposisi dua panel, layar kecil memakai
          // hero gelap di atas dan form yang lapang di bawahnya.
          if (constraints.maxWidth >= 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 11, child: _BrandPanel()),
                Expanded(flex: 10, child: _FormPanel(controller: controller)),
              ],
            );
          }
          return _CompactLayout(controller: controller);
        },
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MobileHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _LoginForm(controller: controller, compact: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _ink,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          const Positioned(top: -140, right: -110, child: _Glow(size: 430)),
          const Positioned(
            bottom: -170,
            left: -130,
            child: _Glow(size: 360, color: Color(0xFF4B2E7A), opacity: 0.45),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minHeight = constraints.maxHeight - 72;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(48, 40, 48, 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minHeight > 0 ? minHeight : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _BrandLockup(),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Eyebrow(),
                            SizedBox(height: 16),
                            _Headline(fontSize: 40),
                            SizedBox(height: 16),
                            Text(
                              'Satu ruang kerja untuk melaporkan kendala, '
                              'menyusun prioritas, dan menutup tindak lanjut '
                              'bersama tim.',
                              style: TextStyle(
                                color: Color(0xB3FFFFFF),
                                fontSize: 13.5,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                        const _PanelFooter(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: Container(
        color: _ink,
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
            const Positioned(top: -110, right: -80, child: _Glow(size: 280)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandLockup(),
                    const SizedBox(height: 34),
                    const _Eyebrow(),
                    const SizedBox(height: 12),
                    const _Headline(fontSize: 28),
                    const SizedBox(height: 12),
                    const Text(
                      'Satu ruang kerja untuk melaporkan kendala dan menutup '
                      'tindak lanjut bersama tim.',
                      style: TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 12.5,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.diamond_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: 'lapor'),
                  TextSpan(
                    text: 'permata',
                    style: TextStyle(color: _accentSoft),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1),
            Text(
              'RS PERMATA CIREBON',
              style: TextStyle(
                color: Color(0x66FFFFFF),
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 20, height: 2, color: AppColors.primary),
        const SizedBox(width: 8),
        const Text(
          'RUANG KERJA INTERNAL',
          style: TextStyle(
            color: Color(0x8CFFFFFF),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.14,
          letterSpacing: -1.1,
          color: Colors.white,
        ),
        children: const [
          TextSpan(text: 'Laporan rapi.\n'),
          TextSpan(text: 'Tindak lanjut\n'),
          TextSpan(text: 'terasa '),
          TextSpan(
            text: 'ringan.',
            style: TextStyle(color: _accentSoft),
          ),
        ],
      ),
    );
  }
}

class _PanelFooter extends StatelessWidget {
  const _PanelFooter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.lock_outline_rounded, color: Color(0x59FFFFFF), size: 13),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'Akses internal · Data simulasi',
            style: TextStyle(color: Color(0x59FFFFFF), fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _paper,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.maxHeight - 80;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: minHeight > 0 ? minHeight : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: _LoginForm(controller: controller, compact: false),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.controller, required this.compact});

  final AuthController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Masuk ke akun Anda',
          style: TextStyle(
            color: AppColors.textStrong,
            fontSize: compact ? 22 : 25,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gunakan akun RS Permata untuk melanjutkan ke ruang kerja.',
          style: TextStyle(
            color: AppColors.textWeak,
            fontSize: 12.5,
            height: 1.55,
          ),
        ),
        SizedBox(height: compact ? 26 : 32),
        const _FieldLabel('Username'),
        const SizedBox(height: 7),
        TextField(
          controller: controller.usernameController,
          style: const TextStyle(
            color: AppColors.textStrong,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.primary,
          decoration: _inputDecoration(
            hint: 'Masukkan username',
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Kata sandi'),
        const SizedBox(height: 7),
        Obx(
          () => TextField(
            controller: controller.passwordController,
            obscureText: controller.isPasswordHidden.value,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppColors.primary,
            decoration: _inputDecoration(
              hint: 'Masukkan kata sandi',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                onPressed: controller.togglePasswordView,
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 42,
                  height: 42,
                ),
                icon: Icon(
                  controller.isPasswordHidden.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textWeak,
                  size: 19,
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Lupa kata sandi?'),
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (!controller.isLoading.value)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.26),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.55,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 26 : 30),
        _DemoAccounts(controller: controller),
      ],
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final entries = AuthController.demoAccounts.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: _fieldBorder, height: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'atau akun demo',
                style: TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 10,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            Expanded(child: Divider(color: _fieldBorder, height: 1)),
          ],
        ),
        const SizedBox(height: 4),
        for (var index = 0; index < entries.length; index++) ...[
          _DemoAccountRow(
            nik: entries[index].key,
            name: entries[index].value['name'] ?? entries[index].key,
            password: entries[index].value['password'] ?? '',
            onTap: () => controller.selectDemoAccount(entries[index].key),
          ),
          if (index != entries.length - 1)
            const Divider(height: 1, color: _fieldBorder),
        ],
      ],
    );
  }
}

class _DemoAccountRow extends StatelessWidget {
  const _DemoAccountRow({
    required this.nik,
    required this.name,
    required this.password,
    required this.onTap,
  });

  final String nik;
  final String name;
  final String password;
  final VoidCallback onTap;

  String get _initials {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase());
    return parts.join();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                _initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$nik · sandi $password',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textWeak,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_outward_rounded,
              size: 14,
              color: AppColors.textWeak,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textStrong,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(13)),
    borderSide: BorderSide(color: _fieldBorder),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textWeak, fontSize: 13.5),
    prefixIcon: Icon(icon, color: AppColors.textWeak, size: 19),
    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    filled: true,
    fillColor: Colors.white,
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(13)),
      borderSide: BorderSide(color: AppColors.primary, width: 1.6),
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
    this.color = AppColors.primary,
    this.opacity = 0.32,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.045);
    const spacing = 26.0;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
