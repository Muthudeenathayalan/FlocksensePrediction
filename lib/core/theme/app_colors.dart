import 'package:flutter/material.dart';

/// Centralized FlockSense Design System Color Palette
/// Adapted from Agronex visual design principles (Electric Lime, Obsidian Slate, Pale Ice Backgrounds)
/// for modern poultry intelligence, farm management, and disease surveillance.
class AppColors {
  AppColors._();

  // ── Green and White Signature Brand Palette ─────────────────────────────
  static const Color primary = Color(0xFF15803D); // Clinical Emerald Green
  static const Color primaryDark = Color(0xFF14532D); // Deep Forest Green
  static const Color primaryMedium = Color(0xFF16A34A); // Vibrant Emerald Green
  static const Color primaryLight = Color(0xFFDCFCE7); // Crisp Mint Tint
  static const Color primarySoft = Color(0xFFF0FDF4); // Ultra-light Fresh Mint Glow
  static const Color primaryHover = Color(0xFF166534); // Deep Forest Green Hover

  // ── Obsidian & Slate Neutrals ───────────────────────────────────────────
  static const Color slate950 = Color(0xFF070B0A); // Deepest Obsidian
  static const Color slate900 = Color(0xFF0F172A); // Major Headers & Dark Slate
  static const Color slate800 = Color(0xFF1E293B); // Elevated Slate Cards
  static const Color slate700 = Color(0xFF334155); // Slate Border / Dark Surface Muted
  static const Color slate600 = Color(0xFF475569); // Primary Body Text
  static const Color slate500 = Color(0xFF64748B); // Secondary Text
  static const Color slate400 = Color(0xFF94A3B8); // Muted / Metadata Text
  static const Color slate300 = Color(0xFFCBD5E1); // Moderate Hairline Borders
  static const Color slate200 = Color(0xFFE2E8F0); // Subtle Dividers & Card Borders
  static const Color slate100 = Color(0xFFF1F5F9); // Light Backgrounds / Table Headers
  static const Color slate50 = Color(0xFFF8FAFC); // Clean Pale White Canvas

  // ── Surfaces & Canvas ───────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF0FDF4);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color darkCanvas = Color(0xFF14532D);
  static const Color darkSurface = Color(0xFF0F3A22);

  // ── Text Tokens ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color onPrimary = Color(0xFFFFFFFF); // Pure White text on Green buttons

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
    colors: [Color(0xFF15803D), Color(0xFF166534)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );
}
