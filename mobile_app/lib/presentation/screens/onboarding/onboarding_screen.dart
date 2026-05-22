import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/language_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  String _selectedSrc = 'en';
  String _selectedTgt = 'ar';

  final List<_OnboardPage> _pages = const [
    _OnboardPage(
      emoji: '🌍',
      title: 'Break Language Barriers',
      subtitle:
          'Real-time voice translation in under 300ms.\nSpeak your language, be heard in theirs.',
      gradient: [Color(0xFF6C63FF), Color(0xFF4A43CC)],
    ),
    _OnboardPage(
      emoji: '🎙️',
      title: 'Your Voice, Preserved',
      subtitle:
          'IST-RVT clones your voice so your translated speech\nsounds like YOU — not a robot.',
      gradient: [Color(0xFF00D4FF), Color(0xFF0090CC)],
    ),
    _OnboardPage(
      emoji: '📵',
      title: 'Works Offline Too',
      subtitle:
          'On-device AI translation — no internet required.\nPrivate, fast, always available.',
      gradient: [Color(0xFF00E5A0), Color(0xFF00A070)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length + 1, // +1 for language selection
                  itemBuilder: (_, i) {
                    if (i < _pages.length) return _buildInfoPage(_pages[i]);
                    return _buildLanguagePage();
                  },
                ),
              ),

              // Dots + button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length + 1, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    // Next / Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _next,
                          child: Text(
                            _currentPage < _pages.length ? 'Next →' : 'Get Started',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPage(_OnboardPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: page.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: page.gradient.first.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(page.emoji, style: const TextStyle(fontSize: 52)),
            ),
          ),
          const SizedBox(height: 40),
          Text(page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 16),
          Text(page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15, color: AppColors.textSecondary, height: 1.6,
              )),
        ],
      ),
    );
  }

  Widget _buildLanguagePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🗣️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 24),
          const Text('Choose Your Languages',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          const Text('You can change these anytime in settings.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 40),
          _langSelector('I speak:', _selectedSrc, (v) => setState(() => _selectedSrc = v)),
          const SizedBox(height: 16),
          _langSelector('Translate to:', _selectedTgt, (v) => setState(() => _selectedTgt = v)),
        ],
      ),
    );
  }

  Widget _langSelector(String label, String value, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ),
          DropdownButtonFormField<String>(
            value: value,
            dropdownColor: AppColors.surfaceCard,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: LanguageUtils.allLanguages
                .map((l) => DropdownMenuItem(
                      value: l['code'],
                      child: Text(
                          '${l['flag']} ${l['name']}',
                          style: const TextStyle(color: AppColors.textPrimary)),
                    ))
                .toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_currentPage < _pages.length) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    await prefs.setString('source_lang', _selectedSrc);
    await prefs.setString('target_lang', _selectedTgt);
    if (mounted) context.go('/login');
  }
}

class _OnboardPage {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
