import 'package:flutter/material.dart';

/// Centralized FlockSense Design System Color Palette
/// Designed for a modern desktop-first agricultural-health and disease surveillance SaaS.
class AppColors {
  AppColors._();

  // ── Core Brand Palette (Deep Agricultural Green & Slate) ──────────────────
  static const Color primary = Color(0xFF166534); // Forest/Agricultural Green (600)
  static const Color primaryDark = Color(0xFF052E16); // Deep Emerald Slate (950)
  static const Color primaryMedium = Color(0xFF15803D); // Vivid Green (700)
  static const Color primaryLight = Color(0xFFDCFCE7); // Soft Green Tint (100)
  static const Color primarySoft = Color(0xFFF0FDF4); // Ultra-light Green (50)
  static const Color primaryHover = Color(0xFF14532D); // Deep Hover (800)

  // ── Slate & Neutral Tones ───────────────────────────────────────────────
  static const Color slate950 = Color(0xFF020617); // Almost Black
  static const Color slate900 = Color(0xFF0F172A); // Header & Major Titles
  static const Color slate800 = Color(0xFF1E293B); // Sidebar & Dark Surfaces
  static const Color slate700 = Color(0xFF334155); // Primary Body Text
  static const Color slate600 = Color(0xFF475569); // Secondary Text
  static const Color slate500 = Color(0xFF64748B); // Muted / Metadata Text
  static const Color slate400 = Color(0xFF94A3B8); // Disabled / Icons
  static const Color slate300 = Color(0xFFCBD5E1); // Borders Moderate
  static const Color slate200 = Color(0xFFE2E8F0); // Subtle Dividers & Card Borders
  static const Color slate100 = Color(0xFFF1F5F9); // Light Backgrounds / Table Headers
  static const Color slate50 = Color(0xFFF8FAFC); // Main Web Background

  // ── Surfaces & Canvas ───────────────────────────────────────────────────
  static const Color background = slate50;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = slate100;
  static const Color surfaceSubtle = slate50;
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // ── Text Tokens ─────────────────────────────────────────────────────────
  static const Color textPrimary = slate900;
  static const Color textSecondary = slate600;
  static const Color textMuted = slate500;
  static const Color textHint = slate400;
  static const Color textDisabled = slate400;
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Borders, Dividers & Shadows ─────────────────────────────────────────
  static const Color border = slate200;
  static const Color borderStrong = slate300;
  static const Color divider = slate200;
  static const Color shadow = Color(0x0A0F172A);
  static const Color shadowMd = Color(0x140F172A);

  // ── Semantic Health & Status Tokens ─────────────────────────────────────
  // Healthy / Normal
  static const Color healthy = Color(0xFF16A34A);
  static const Color healthyBg = Color(0xFFDCFCE7);
  static const Color healthyBorder = Color(0xFF86EFAC);

  // Info / Operational
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFF93C5FD);

  // Warning / Attention Needed
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  // High Risk / Severe
  static const Color highRisk = Color(0xFFEA580C);
  static const Color highRiskBg = Color(0xFFFFF7ED);
  static const Color highRiskBorder = Color(0xFFFDBA74);

  // Critical / Outbreak / Hazard
  static const Color critical = Color(0xFFDC2626);
  static const Color criticalBg = Color(0xFFFEF2F2);
  static const Color criticalBorder = Color(0xFFFCA5A5);

  // Neutral / Draft / Resolved
  static const Color neutral = slate500;
  static const Color neutralBg = slate100;
  static const Color neutralBorder = slate300;

  // ── Backward Compatibility Aliases ──────────────────────────────────────
  static const Color success = healthy;
  static const Color danger = critical;
  static const Color dangerLight = criticalBg;
  static const Color error = critical;
  static const Color accent = warning;
  static const Color accentLight = warningBg;
  static const Color warningLight = warningBg;
  static const Color criticalLight = criticalBg;
  static const Color emerald = healthy;
  static const Color emeraldLight = healthyBg;
  static const Color gold = warning;
  static const Color goldLight = warningBg;
  static const Color ocean = info;
  static const Color oceanLight = infoBg;
  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoLight = Color(0xFFEEF2FF);
  static const Color surfaceVariant = surfaceSoft;
  static const Color cardBg = surface;

  // ── Dark Theme Tokens ───────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B1118);
  static const Color darkSurface = Color(0xFF131D28);
  static const Color darkSurfaceSoft = Color(0xFF1C2B3A);
  static const Color darkBorder = Color(0xFF27384A);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ── Restrained Functional Gradients (Minimal Usage) ─────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMedium, primary],
  );

  static const LinearGradient subtleCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
  );

  static const LinearGradient farmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF166534), Color(0xFF15803D)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFB45309)],
  );

  static const LinearGradient cardGradient = subtleCardGradient;
}
