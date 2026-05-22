import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 30, spreadRadius: 4,
                              )],
                            ),
                            child: const Center(
                              child: Text('RVT',
                                  style: TextStyle(fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white, letterSpacing: 2)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Welcome Back',
                              style: TextStyle(fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          const Text('Sign in to IST-RVT',
                              style: TextStyle(fontSize: 14,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Username
                    _buildLabel('Username'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _userCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Enter your username',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Username required' : null,
                    ),
                    const SizedBox(height: 20),
                    // Password
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 4)
                          ? 'Password too short' : null,
                    ),
                    const SizedBox(height: 8),
                    // Error
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) => auth.error != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.error.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: AppColors.error, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(auth.error!,
                                          style: const TextStyle(
                                              color: AppColors.error,
                                              fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),
                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) => SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20, offset: const Offset(0, 8),
                            )],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: auth.isLoading ? null : _login,
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Text('Sign In',
                                    style: TextStyle(fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Register link
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(color: AppColors.textSecondary,
                                  fontSize: 14)),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: const Text('Sign Up',
                                style: TextStyle(color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Try without account
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Try without account →',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 13)),
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

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));
}
