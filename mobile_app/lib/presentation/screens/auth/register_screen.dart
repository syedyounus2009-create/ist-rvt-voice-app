import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/language_utils.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _emailCtrl= TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure   = true;
  String _srcLang = 'en';
  String _tgtLang = 'ar';

  @override
  void dispose() {
    _nameCtrl.dispose(); _userCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      username: _userCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      displayName: _nameCtrl.text.trim(),
      preferredLanguage: _srcLang,
      targetLanguage: _tgtLang,
    );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  IconButton(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  const Text('Create Account',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Join IST-RVT and speak any language',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 32),

                  _label('Full Name'),
                  const SizedBox(height: 8),
                  _field(_nameCtrl, 'Your display name',
                      Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name required' : null),
                  const SizedBox(height: 16),

                  _label('Username'),
                  const SizedBox(height: 8),
                  _field(_userCtrl, 'Unique username',
                      Icons.alternate_email_rounded,
                      validator: (v) {
                        if (v == null || v.trim().length < 3)
                          return 'Min 3 characters';
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v))
                          return 'Letters, numbers, _ only';
                        return null;
                      }),
                  const SizedBox(height: 16),

                  _label('Email'),
                  const SizedBox(height: 8),
                  _field(_emailCtrl, 'your@email.com',
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Valid email required' : null),
                  const SizedBox(height: 16),

                  _label('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Min 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 24),

                  // Language row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌐  Language Preferences',
                            style: TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _langDrop('I speak', _srcLang,
                                (v) => setState(() => _srcLang = v))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.swap_horiz_rounded,
                                  color: AppColors.primary),
                            ),
                            Expanded(child: _langDrop('Translate to', _tgtLang,
                                (v) => setState(() => _tgtLang = v))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Error
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => auth.error != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: Text(auth.error!,
                                  style: const TextStyle(
                                      color: AppColors.error, fontSize: 13)),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 28),
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
                          onPressed: auth.isLoading ? null : _register,
                          child: auth.isLoading
                              ? const SizedBox(width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Create Account',
                                  style: TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Already have an account? ',
                            style: TextStyle(color: AppColors.textSecondary,
                                fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text('Sign In',
                              style: TextStyle(color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
        validator: validator,
      );

  Widget _langDrop(String label, String value, ValueChanged<String> onChange) =>
      DropdownButtonFormField<String>(
        value: value,
        dropdownColor: AppColors.surfaceCard,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, color: AppColors.textHint),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
        ),
        items: LanguageUtils.allLanguages
            .map((l) => DropdownMenuItem(
                value: l['code'],
                child: Text('${l['flag']} ${l['name']}',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (v) { if (v != null) onChange(v); },
      );
}
