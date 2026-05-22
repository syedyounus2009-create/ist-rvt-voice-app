import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/call_provider.dart';
import '../../../providers/auth_provider.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  final String contactName;

  const VideoCallScreen({super.key, required this.roomId, required this.contactName});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _cameraOn = true;
  bool _micOn = true;
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return Consumer2<CallProvider, AuthProvider>(
      builder: (_, call, auth, __) => Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            children: [
              // Remote video (full screen placeholder)
              Container(
                color: const Color(0xFF0A0A1A),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.contactName.isNotEmpty
                                ? widget.contactName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 52,
                                fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.contactName,
                          style: const TextStyle(fontSize: 22,
                              fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(
                        call.isActive ? call.formattedDuration : 'Connecting...',
                        style: const TextStyle(fontSize: 14, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),

              // Local video (PiP — top right)
              Positioned(
                top: 60, right: 16,
                child: Container(
                  width: 90, height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _cameraOn
                        ? Container(color: AppColors.surfaceCard,
                            child: const Icon(Icons.videocam_rounded,
                                color: AppColors.textHint, size: 36))
                        : Container(color: const Color(0xFF1A1A2E),
                            child: const Icon(Icons.videocam_off_rounded,
                                color: AppColors.textHint, size: 36)),
                  ),
                ),
              ),

              // Live translation subtitles
              if (call.liveTranslated.isNotEmpty)
                Positioned(
                  bottom: 140, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(call.liveOriginal,
                            style: const TextStyle(fontSize: 12,
                                color: Colors.white54),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(call.liveTranslated,
                            style: const TextStyle(fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),

              // Controls bar (animated show/hide)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                bottom: _showControls ? 0 : -120,
                left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent,
                        Colors.black.withOpacity(0.9)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ctrlBtn(Icons.mic_off_rounded, _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                          _micOn, () => setState(() => _micOn = !_micOn)),
                      _ctrlBtn(Icons.videocam_off_rounded, _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                          _cameraOn, () => setState(() => _cameraOn = !_cameraOn)),
                      // End call
                      GestureDetector(
                        onTap: () async {
                          await call.endCall(auth.token);
                          if (mounted) Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 64, height: 64,
                          decoration: const BoxDecoration(
                              color: AppColors.callRed, shape: BoxShape.circle),
                          child: const Icon(Icons.call_end_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                      _ctrlBtn(Icons.flip_camera_ios_outlined,
                          Icons.flip_camera_ios_rounded, true, () {}),
                      _ctrlBtn(Icons.subtitles_outlined,
                          Icons.subtitles_rounded, true, () {}),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ctrlBtn(IconData offIcon, IconData onIcon, bool isOn, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: isOn ? Colors.white.withOpacity(0.15) : AppColors.error.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(isOn ? onIcon : offIcon, color: Colors.white, size: 22),
        ),
      );
}
