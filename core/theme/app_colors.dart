import 'package:flutter/material.dart';

/// Centralized FlockSense Design System Color Palette
/// Adapted from Agronex visual design principles (Electric Lime, Obsidian Slate, Pale Ice Backgrounds)
/// for modern poultry intelligence, farm management, and disease surveillance.
class AppColors {
  AppColors._();

  // ── Agronex Signature Brand Palette ──────────────────────────────────────
  static const Color primary = Color(0xFFD2F546); // Electric Lime / Chartreuse (Agronex Accent)
  static const Color primaryDark = Color(0xFF0C1311); // Deep Obsidian Slate
  static const Color primaryMedium = Color(0xFFBCE62E); // Vibrant Lime Medium
  static const Color primaryLight = Color(0xFFF1FCD1); // Soft Lime Tint
  static const Color primarySoft = Color(0xFFF8FEE8); // Ultra-light Lime Glow
  static const Color primaryHover = Color(0xFFC3E835); // Hover Accent

  // ── Obsidian & Slate Neutrals ───────────────────────────────────────────
  static const Color slate950 = Color(0xFF070B0A); // Deepest Obsidian
  static const Color slate900 = Color(0xFF0C1311); // Major Headers & Dark Containers
  static const Color slate800 = Color(0xFF151E1C); // Sidebar & Elevated Dark Cards
  static const Color slate700 = Color(0xFF263330); // Dark Border / Dark Surface Muted
  static const Color slate600 = Color(0xFF4B5B57); // Primary Body Text
  static const Color slate500 = Color(0xFF6E7E7A); // Secondary Text
  static const Color slate400 = Color(0xFF9BA9A5); // Muted / Metadata Text
  static const Color slate300 = Color(0xFFCBD5D2); // Moderate Hairline Borders
  static const Color slate200 = Color(0xFFE5EBE9); // Subtle Dividers & Card Borders
  static const Color slate100 = Color(0xFFEEF2F1); // Light Backgrounds / Table Headers
  static const Color slate50 = Color(0xFFF4F5F6); // Agronex Off-White / Pale Ice Background

  // ── Surfaces & Canvas ───────────────────────────────────────────────────
  static const Color background = slate50;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF8F9FA);
  static const Color surfaceSubtle = slate100;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color darkCanvas = Color(0xFF0C1311);
  static const Color darkSurface = Color(0xFF151E1C);

  // ── Text Tokens ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textMuted = Color(0xFF888888);
  static const Color textHint = Color(0xFFAAAAAA);
  static const Color textDisabled = Color(0xFFCCCCCC);
  static const Color onPrimary = Color(0xFF0C1311); // Dark text on Electric Lime buttons

  // ── Borders, Dividers & Shadows ─────────────────────────────────────────
  static const Color border = Color(0xFFE5E8EB);
  static const Color borderStrong = Color(0xFFD1D5DB);
  static const Color divider = Color(0xFFE5E8EB);
  static const Color shadow = Color(0x0A000000);
  static const Color shadowMd = Color(0x14000000);

  // ── Semantic Health & Status Tokens ─────────────────────────────────────
  // Healthy / Normal
  static const Color healthy = Color(0xFF10B981);
  static const Color healthyBg = Color(0xFFD1FAE5);
  static const Color healthyBorder = Color(0xFF6EE7B7);

  // Info / Operational
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFE0F2FE);
  static const Color infoBorder = Color(0xFF7DD3FC);

  // Warning / Attention Needed
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningBorder = Color(0xFFFCD34D);

  // High Risk / Severe
  static const Color highRisk = Color(0xFFF97316);
  static const Color highRiskBg = Color(0xFFFFEDD5);
  static const Color highRiskBorder = Color(0xFFFDBA74);

  // Critical / Outbreak / Hazard
  static const Color critical = Color(0xFFEF4444);
  static const Color criticalBg = Color(0xFFFEE2E2);
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
  static const Color accent = primary;
  static const Color accentLight = primaryLight;
  static const Color warningLight = warningBg;
  static const Color criticalLight = criticalBg;
  static const Color emerald = healthy;
  static const Color emeraldLight = healthyBg;
  static const Color gold = warning;
  static const Color goldLight = warningBg;
  static const Color ocean = info;
  static const Color oceanLight = infoBg;
  // ── Dark Theme & Bottom Sheet Backward Compatibility ────────────────────
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkBorder = Color(0xFF263330);
  static const Color darkTextSecondary = Color(0xFF9BA9A5);
  static const Color darkSurfaceSoft = Color(0xFF151E1C);

  // ── Extended Colors & Surfaces ───────────────────────────────────────────
  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoLight = Color(0xFFEEF2FF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);

  // ── Signature Gradients ──────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0C1311), Color(0xFF151E1C)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );
}
