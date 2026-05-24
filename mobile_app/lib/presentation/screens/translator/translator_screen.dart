import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/language_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/translation_provider.dart';
import '../../widgets/audio_visualizer.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/translation_bubble.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});
  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Timer? _amplitudeTimer;
  double _amplitude = 0;
  bool _showTextInput = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Connect to backend on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final trans = context.read<TranslationProvider>();
      if (auth.isAuthenticated) {
        trans.connectRealtime(auth.user!.id);
      } else {
        // Connect anonymously so voice translation works without login
        trans.connectAnonymous();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _amplitudeTimer?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  void _startAmplitudePolling() {
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      final trans = context.read<TranslationProvider>();
      if (trans.isListening) {
        final amp = await trans.getAmplitude();
        if (mounted) setState(() => _amplitude = amp);
      }
    });
  }

  Future<void> _toggleRecording() async {
    final trans = context.read<TranslationProvider>();
    
    if (trans.isListening) {
      await trans.stopListening();
      _amplitudeTimer?.cancel();
      setState(() => _amplitude = 0);
    } else {
      await trans.startListening();
      _startAmplitudePolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLanguageBar(),
            Expanded(child: _buildTranslationArea()),
            _buildControls(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
            child: const Text('IST-RVT',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: 1.5)),
          ),
          const Spacer(),
          // Online/Offline toggle
          Consumer<TranslationProvider>(
            builder: (_, trans, __) => GestureDetector(
              onTap: trans.toggleOfflineMode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: trans.offlineMode
                      ? AppColors.warning.withOpacity(0.15)
                      : AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: trans.offlineMode
                        ? AppColors.warning.withOpacity(0.5)
                        : AppColors.success.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: trans.offlineMode
                            ? AppColors.warning : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      trans.offlineMode ? 'Offline' : 'Online',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: trans.offlineMode
                            ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageBar() {
    return Consumer<TranslationProvider>(
      builder: (_, trans, __) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: LanguagePicker(
                  value: trans.sourceLang,
                  label: 'From',
                  onChanged: (v) => trans.setLanguages(v, trans.targetLang),
                ),
              ),
              GestureDetector(
                onTap: trans.swapLanguages,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                    )],
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              Expanded(
                child: LanguagePicker(
                  value: trans.targetLang,
                  label: 'To',
                  onChanged: (v) => trans.setLanguages(trans.sourceLang, v),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranslationArea() {
    return Consumer<TranslationProvider>(
      builder: (_, trans, __) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            // Latency chip
            if (trans.latencyMs > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    '⚡ ${trans.latencyMs.toStringAsFixed(0)}ms · ${trans.ttsEngine}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            // Original bubble
            if (trans.originalText.isNotEmpty)
              TranslationBubble(
                text: trans.originalText,
                label: LanguageUtils.getDisplayName(trans.sourceLang),
                isOriginal: true,
              ),

            if (trans.originalText.isNotEmpty && trans.translatedText.isNotEmpty)
              const SizedBox(height: 12),

            // Translated bubble
            if (trans.translatedText.isNotEmpty)
              TranslationBubble(
                text: trans.translatedText,
                label: LanguageUtils.getDisplayName(trans.targetLang),
                isOriginal: false,
                isRTL: LanguageUtils.isRTL(trans.targetLang),
              ),

            // Empty state
            if (trans.originalText.isEmpty)
              _buildEmptyState(trans),

            // Text input
            if (_showTextInput) ...[
              const SizedBox(height: 20),
              _buildTextInput(trans),
            ],

            // History
            if (trans.history.isNotEmpty && trans.originalText.isEmpty) ...[
              const SizedBox(height: 24),
              _buildHistorySection(trans),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(TranslationProvider trans) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
          ),
          child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          trans.isListening ? 'Listening...' : 'Tap mic to translate',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          trans.isListening
              ? 'Speak now — translation starts automatically'
              : 'Or type text below',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextInput(TranslationProvider trans) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 3, minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Type to translate...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                trans.translateText(_textCtrl.text, auth.token);
                _textCtrl.clear();
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(TranslationProvider trans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Recent', style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const Spacer(),
            TextButton(
              onPressed: trans.clearHistory,
              child: const Text('Clear', style: TextStyle(
                  fontSize: 12, color: AppColors.textHint)),
            ),
          ],
        ),
        ...trans.history.take(5).map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.original, style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(r.translated, style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildControls() {
    return Consumer<TranslationProvider>(
      builder: (_, trans, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Waveform
            if (trans.isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AudioVisualizer(amplitude: _amplitude),
              ),

            // Control row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Text input toggle
                _controlBtn(
                  icon: _showTextInput
                      ? Icons.keyboard_hide_rounded
                      : Icons.keyboard_rounded,
                  color: AppColors.textHint,
                  onTap: () => setState(() => _showTextInput = !_showTextInput),
                  size: 48,
                ),
                const SizedBox(width: 24),

                // Main mic button
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: trans.isListening ? _pulseAnim.value : 1.0,
                    child: GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: trans.isListening
                              ? const LinearGradient(
                                  colors: [AppColors.error, Color(0xFFFF8A80)])
                              : AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (trans.isListening
                                      ? AppColors.error
                                      : AppColors.primary)
                                  .withOpacity(0.5),
                              blurRadius: 30, spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          trans.isListening
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          color: Colors.white, size: 36,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 24),
                // History clear / share
                _controlBtn(
                  icon: Icons.share_outlined,
                  color: AppColors.textHint,
                  onTap: () {},
                  size: 48,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 48,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      );
}
