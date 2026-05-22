import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;

    if (!onboarded) {
      context.go('/onboarding');
    } else if (auth.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'RVT',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // App name
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        'IST-RVT',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Speak Any Language, Anywhere',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
