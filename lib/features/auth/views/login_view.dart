import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../../../core/utils/google_fonts.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authCtrl = Get.find<AuthController>();
  bool _obscure = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Background aura glow circles for light clinical portal feel
          Positioned(
            top: -120,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentAlt.withOpacity(0.06),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeaderLogo(),
                      const SizedBox(height: 36),
                      _buildLoginCard(),
                      const SizedBox(height: 24),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderLogo() {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 18),
        Text(
          'SIMRS DOKTER',
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'RS Islam Aminah Blitar',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.divider, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Silakan masuk dengan kredensial dokter Anda.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          _buildLabel('Username'),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameCtrl,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
            decoration: const InputDecoration(
              hintText: 'Masukkan username',
              prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textMuted, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel('Password'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
            decoration: InputDecoration(
              hintText: 'Masukkan password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildLoginButton(),
          const SizedBox(height: 16),
          _buildErrorMsg(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildLoginButton() {
    return Obx(() {
      final isLoading = _authCtrl.isLoading.value;
      return GestureDetector(
        onTap: isLoading
            ? null
            : () => _authCtrl.login(_usernameCtrl.text.trim(), _passwordCtrl.text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: isLoading ? null : AppTheme.primaryGradient,
            color: isLoading ? AppTheme.bgSurface : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Masuk Ke Dashboard',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildErrorMsg() {
    return Obx(() {
      final msg = _authCtrl.errorMsg.value;
      if (msg.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFooter() {
    return Text(
      'v1.1.0 • RSI Aminah Blitar © 2026',
      style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
    );
  }
}
