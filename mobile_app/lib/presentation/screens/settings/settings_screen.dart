import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/language_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/translation_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final trans = context.watch<TranslationProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Settings', style: TextStyle(fontSize: 24,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 24),

          // Profile card
          if (user != null) Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Container(width: 60, height: 60,
                decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                child: Center(child: Text(user.initials,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                        color: Colors.white)))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.displayTitle, style: const TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('@${user.username}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(children: [
                  _badge(LanguageUtils.getFlag(user.preferredLanguage),
                      LanguageUtils.getName(user.preferredLanguage), AppColors.primary),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_right_alt_rounded, color: AppColors.textHint, size: 16),
                  const SizedBox(width: 6),
                  _badge(LanguageUtils.getFlag(user.targetLanguage),
                      LanguageUtils.getName(user.targetLanguage), AppColors.secondary),
                ]),
              ])),
            ]),
          ),

          const SizedBox(height: 28),
          _section('🌐  Language Settings'),
          const SizedBox(height: 12),
          _langRow(context, trans, auth),

          const SizedBox(height: 24),
          _section('🔬  AI Engine'),
          const SizedBox(height: 12),
          _tile(Icons.mic_rounded, 'STT Model', 'faster-whisper (small)', AppColors.primary,
              subtitle: 'Speech-to-Text engine', onTap: null),
          const SizedBox(height: 8),
          _tile(Icons.translate_rounded, 'Translation', 'Argostranslate + Google', AppColors.secondary,
              subtitle: 'Offline-first', onTap: null),
          const SizedBox(height: 8),
          _tile(Icons.record_voice_over_rounded, 'TTS Engine', 'Microsoft Edge TTS', AppColors.accent,
              subtitle: '300+ voices, free', onTap: null),
          const SizedBox(height: 8),
          _tile(Icons.wifi_off_rounded, 'Offline Mode', trans.offlineMode ? 'ON' : 'OFF',
              trans.offlineMode ? AppColors.warning : AppColors.textHint,
              subtitle: 'On-device translation', onTap: trans.toggleOfflineMode,
              trailing: Switch(value: trans.offlineMode, onChanged: (_) => trans.toggleOfflineMode(),
                  activeColor: AppColors.primary)),

          const SizedBox(height: 24),
          _section('🔒  Privacy & Security'),
          const SizedBox(height: 12),
          _tile(Icons.security_rounded, 'E2E Encryption', 'Enabled', AppColors.accentGreen,
              subtitle: 'AES-256 for all calls', onTap: null),
          const SizedBox(height: 8),
          _tile(Icons.storage_rounded, 'Data Storage', 'Local only', AppColors.primary,
              subtitle: 'Messages not stored on server', onTap: null),

          const SizedBox(height: 24),
          _section('ℹ️  About'),
          const SizedBox(height: 12),
          _tile(Icons.info_outline_rounded, 'Version', AppConstants.appVersion,
              AppColors.textSecondary, onTap: null),
          const SizedBox(height: 8),
          _tile(Icons.code_rounded, 'IST-RVT', 'Real-Time Voice Translator',
              AppColors.primary, onTap: null),

          const SizedBox(height: 28),
          if (auth.isAuthenticated) SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error,
                  fontSize: 15, fontWeight: FontWeight.w600)),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ]),
      )),
    );
  }

  Widget _section(String title) => Text(title, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));

  Widget _badge(String emoji, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Text('$emoji $label', style: TextStyle(fontSize: 11,
        color: color, fontWeight: FontWeight.w600)),
  );

  Widget _langRow(BuildContext context, TranslationProvider trans, AuthProvider auth) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Translation Languages', style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _langDrop('From', trans.sourceLang,
                (v) => trans.setLanguages(v, trans.targetLang))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GestureDetector(
                onTap: () { trans.swapLanguages(); auth.updateLanguages(trans.sourceLang, trans.targetLang); },
                child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18)),
              ),
            ),
            Expanded(child: _langDrop('To', trans.targetLang,
                (v) => trans.setLanguages(trans.sourceLang, v))),
          ]),
        ]),
      );

  Widget _langDrop(String label, String value, ValueChanged<String> onChanged) =>
      DropdownButtonFormField<String>(
        value: value, dropdownColor: AppColors.surfaceCard,
        decoration: InputDecoration(labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: AppColors.textHint),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border))),
        items: LanguageUtils.allLanguages.map((l) => DropdownMenuItem(
            value: l['code'],
            child: Text('${l['flag']} ${l['name']}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      );

  Widget _tile(IconData icon, String title, String value, Color color,
      {String? subtitle, VoidCallback? onTap, Widget? trailing}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
              if (subtitle != null) Text(subtitle, style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint)),
            ])),
            trailing ?? Text(value, style: TextStyle(fontSize: 12,
                color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
