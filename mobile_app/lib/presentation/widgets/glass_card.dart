import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Premium glassmorphism card used across IST-RVT screens.
/// Provides frosted glass effect with subtle border glow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final double blur;
  final Color? glowColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 12,
    this.glowColor,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: (glowColor ?? AppColors.borderGlow).withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (glowColor ?? AppColors.primary).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: card,
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: card,
    );
  }
}

/// Gradient-bordered glass card variant for highlighted sections
class GlassCardGradient extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Gradient? borderGradient;
  final VoidCallback? onTap;

  const GlassCardGradient({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.borderGradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        behavior: onTap != null ? HitTestBehavior.opaque : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: borderGradient ?? AppColors.primaryGradient,
          ),
          padding: const EdgeInsets.all(1.5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius - 1.5),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: padding ?? const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(borderRadius - 1.5),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmering skeleton placeholder for loading states
class GlassCardSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const GlassCardSkeleton({
    super.key,
    this.width,
    this.height = 80,
    this.borderRadius = 20,
  });

  @override
  State<GlassCardSkeleton> createState() => _GlassCardSkeletonState();
}

class _GlassCardSkeletonState extends State<GlassCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_shimmer.value - 1, 0),
            end: Alignment(_shimmer.value, 0),
            colors: const [
              AppColors.surfaceCard,
              AppColors.surfaceGlass,
              AppColors.surfaceCard,
            ],
          ),
        ),
      ),
    );
  }
}
