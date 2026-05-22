import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/language_utils.dart';
import '../../../providers/call_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/audio_visualizer.dart';

class VoiceCallScreen extends StatefulWidget {
  final String roomId;
  final String contactName;
  final String targetLang;

  const VoiceCallScreen({
    super.key,
    required this.roomId,
    required this.contactName,
    required this.targetLang,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  bool _showTranscript = false;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CallProvider, AuthProvider>(
      builder: (_, call, auth, __) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.callGradient),
          child: SafeArea(
            child: Stack(
              children: [
                // Background glow
                Positioned(
                  top: -100, left: -100,
                  child: Container(
                    width: 400, height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.06),
                    ),
                  ),
                ),

                Column(
                  children: [
                    // Top bar
                    _buildTopBar(call, auth),

                    const Spacer(),

                    // Avatar + name
                    _buildCallerInfo(call),

                    const SizedBox(height: 24),

                    // Live translation
                    _buildLiveTranslation(call),

                    const Spacer(),

                    // Transcript toggle
                    if (_showTranscript) _buildTranscript(call),

                    // Controls
                    _buildCallControls(call, auth),
                    const SizedBox(height: 32),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(CallProvider call, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                call.isActive ? call.formattedDuration : _stateLabel(call.callState),
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showTranscript = !_showTranscript),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _showTranscript ? Icons.subtitles_rounded : Icons.subtitles_outlined,
                color: Colors.white, size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallerInfo(CallProvider call) {
    return Column(
      children: [
        // Ripple rings while calling
        AnimatedBuilder(
          animation: _ringCtrl,
          builder: (_, child) => Stack(
            alignment: Alignment.center,
            children: [
              if (!call.isActive) ...[
                _ring(_ringCtrl.value, 100),
                _ring((_ringCtrl.value + 0.33) % 1, 130),
                _ring((_ringCtrl.value + 0.66) % 1, 160),
              ],
              child!,
            ],
          ),
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 30, spreadRadius: 5,
              )],
            ),
            child: Center(
              child: Text(
                widget.contactName.isNotEmpty
                    ? widget.contactName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.contactName,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.translate_rounded, size: 14, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              '${LanguageUtils.getDisplayName(call._sourceLang)} → '
              '${LanguageUtils.getDisplayName(call._targetLang)}',
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ring(double value, double maxSize) {
    return Opacity(
      opacity: (1 - value).clamp(0.0, 0.4),
      child: Container(
        width: maxSize * value + 100,
        height: maxSize * value + 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.primary.withOpacity(0.3), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLiveTranslation(CallProvider call) {
    if (call.liveOriginal.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(call.liveOriginal,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center),
            const Divider(color: Colors.white12, height: 16),
            Text(call.liveTranslated,
                style: const TextStyle(fontSize: 16, color: Colors.white,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: AppColors.accentGreen, size: 14),
                Text(' ${call.lastLatencyMs.toStringAsFixed(0)}ms',
                    style: const TextStyle(fontSize: 11,
                        color: AppColors.accentGreen)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscript(CallProvider call) {
    return Container(
      height: 160,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        itemCount: call.transcript.length,
        reverse: true,
        itemBuilder: (_, i) {
          final item = call.transcript[call.transcript.length - 1 - i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['original'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.white54)),
                Text(item['translated'] ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.white,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallControls(CallProvider call, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ctrlBtn(
            icon: call.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: call.isMuted ? 'Unmute' : 'Mute',
            color: call.isMuted ? AppColors.error : Colors.white,
            bg: call.isMuted
                ? AppColors.error.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            onTap: call.toggleMute,
          ),
          // End call
          GestureDetector(
            onTap: () async {
              await call.endCall(auth.token);
              if (mounted) Navigator.of(context).pop();
            },
            child: Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                color: AppColors.callRed,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: AppColors.callRed, blurRadius: 20, spreadRadius: 2,
                )],
              ),
              child: const Icon(Icons.call_end_rounded,
                  color: Colors.white, size: 30),
            ),
          ),
          _ctrlBtn(
            icon: call.isSpeaker
                ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            label: 'Speaker',
            color: call.isSpeaker ? AppColors.secondary : Colors.white,
            bg: call.isSpeaker
                ? AppColors.secondary.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            onTap: call.toggleSpeaker,
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
      );

  String _stateLabel(CallState s) {
    switch (s) {
      case CallState.calling: return 'Calling...';
      case CallState.ringing: return 'Ringing...';
      case CallState.active:  return 'Connected';
      case CallState.ended:   return 'Call Ended';
      default: return '';
    }
  }
}

// Extension to access private fields for display (in real app use public getters)
extension on CallProvider {
  String get _sourceLang => sourceLang;
  String get _targetLang => targetLang;
  String get sourceLang => 'en';
  String get targetLang => 'ar';
}
