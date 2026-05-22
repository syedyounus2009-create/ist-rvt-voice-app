import 'package:flutter/material.dart';

/// IST-RVT Brand Color Palette
/// Dark, premium, glassmorphism-ready
class AppColors {
  AppColors._();

  // ── Primary Backgrounds ─────────────────────────────────────────────────
  static const Color background     = Color(0xFF080818);  // Deep space black
  static const Color surface        = Color(0xFF10102A);  // Dark navy surface
  static const Color surfaceCard    = Color(0xFF16163A);  // Card background
  static const Color surfaceGlass   = Color(0x1AFFFFFF);  // Glass overlay

  // ── Brand Gradient Colors ───────────────────────────────────────────────
  static const Color primary        = Color(0xFF6C63FF);  // Electric purple
  static const Color primaryLight   = Color(0xFF9D97FF);
  static const Color primaryDark    = Color(0xFF4A43CC);
  static const Color secondary      = Color(0xFF00D4FF);  // Cyan electric
  static const Color accent         = Color(0xFFFF6B9D);  // Hot pink accent
  static const Color accentGreen    = Color(0xFF00E5A0);  // Teal success

  // ── Text ───────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFFB0B0CC);
  static const Color textHint       = Color(0xFF6B6B8A);
  static const Color textDisabled   = Color(0xFF404060);

  // ── Status Colors ──────────────────────────────────────────────────────
  static const Color success        = Color(0xFF00E5A0);
  static const Color warning        = Color(0xFFFFB930);
  static const Color error          = Color(0xFFFF4D6D);
  static const Color online         = Color(0xFF00E5A0);
  static const Color offline        = Color(0xFF6B6B8A);

  // ── Border & Divider ───────────────────────────────────────────────────
  static const Color border         = Color(0xFF1E1E45);
  static const Color borderGlow     = Color(0xFF6C63FF);
  static const Color divider        = Color(0xFF1A1A38);

  // ── Call UI ────────────────────────────────────────────────────────────
  static const Color callGreen      = Color(0xFF00E676);
  static const Color callRed        = Color(0xFFFF1744);
  static const Color callMute       = Color(0xFF37374A);

  // ── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF080818), Color(0xFF100B28)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16163A), Color(0xFF0E0E28)],
  );

  static const LinearGradient callGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1035), Color(0xFF080818)],
  );
}
