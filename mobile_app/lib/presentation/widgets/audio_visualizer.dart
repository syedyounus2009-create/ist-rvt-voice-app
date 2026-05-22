import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Animated waveform visualizer for microphone input
/// amplitude: 0.0 to 1.0 (from AudioService.getAmplitude())
class AudioVisualizer extends StatefulWidget {
  final double amplitude;
  final int barCount;
  final Color? color;

  const AudioVisualizer({
    super.key,
    required this.amplitude,
    this.barCount = 32,
    this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _random = Random();
  late List<double> _heights;

  @override
  void initState() {
    super.initState();
    _heights = List.generate(widget.barCount, (_) => 0.05);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateHeights)..repeat();
  }

  void _updateHeights() {
    if (!mounted) return;
    setState(() {
      _heights = List.generate(widget.barCount, (i) {
        final center = widget.barCount / 2;
        final distFromCenter = (i - center).abs() / center;
        final envelope = 1.0 - (distFromCenter * 0.6);
        final base = widget.amplitude * envelope;
        final noise = _random.nextDouble() * 0.3 * widget.amplitude;
        return (base + noise).clamp(0.04, 1.0);
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            width: 3,
            height: max(4.0, _heights[i] * 52),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  widget.color ?? AppColors.primary,
                  (widget.color ?? AppColors.secondary).withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
