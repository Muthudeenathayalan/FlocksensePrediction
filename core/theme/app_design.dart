import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

/// Centralized Design System Tokens & Helpers for FlockSense Web SaaS
/// Extracted from Agronex visual principles: Generous 20px/24px rounded cards,
/// 100px stadium pill buttons/badges, ultra-fine hairlines, and high-contrast typography.
class AppDesign {
  AppDesign._();

  // ── Standard Spacing Grid ───────────────────────────────────────────────
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // ── Corner Radii (Agronex-Inspired Smooth Geometry) ─────────────────────
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0; // Agronex signature card radius
  static const double radiusXl = 24.0; // Agronex hero container radius
  static const double radiusPill = 100.0; // Stadium pill buttons & tags
  static const double radiusFull = 9999.0;

  // ── Layout Dimensions ───────────────────────────────────────────────────
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 76.0;
  static const double headerHeight = 68.0;
  static const double maxContentWidth = 1520.0;
  static const double maxFormWidth = 860.0;
  static const double maxModalWidth = 680.0;

  // ── Shadows (Atmospheric & Ambient) ─────────────────────────────────────
  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> modalShadow = [
    BoxShadow(
      color: Color(0x20000000),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  // ── Card & Container Decorations (Agronex Style) ────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: cardShadow,
      );

  static BoxDecoration get cardDecorationFlat => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: AppColors.border, width: 1.0),
      );

  static BoxDecoration get cardDecorationDark => BoxDecoration(
        color: AppColors.darkCanvas,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: const Color(0xFF263330), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get panelDecoration => BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: AppColors.border, width: 1.0),
      );

  // ── Semantic Status Chips & Stadium Pills ───────────────────────────────
  static Widget statusChip(
    String text,
    Color bg, {
    Color textColor = AppColors.textPrimary,
    Color? borderColor,
    IconData? icon,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radiusPill),
          border: Border.all(
            color: borderColor ?? bg.withOpacity(0.4),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: textColor),
              const SizedBox(width: 5),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: textColor,
                decoration: TextDecoration.none,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );

  // ── Information Data Row ────────────────────────────────────────────────
  static Widget infoRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: isMono ? 'monospace' : null,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Title Helper ────────────────────────────────────────────────
  static Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ── Risk Badge Helper ───────────────────────────────────────────────────
  static Widget riskBadge(String riskLevel) {
    final lower = riskLevel.toLowerCase();
    Color bg;
    Color text;
    Color border;

    if (lower.contains('critical') || lower.contains('outbreak')) {
      bg = AppColors.criticalBg;
      text = AppColors.critical;
      border = AppColors.criticalBorder;
    } else if (lower.contains('high')) {
      bg = AppColors.highRiskBg;
      text = AppColors.highRisk;
      border = AppColors.highRiskBorder;
    } else if (lower.contains('moderate') || lower.contains('warning') || lower.contains('caution')) {
      bg = AppColors.warningBg;
      text = AppColors.warning;
      border = AppColors.warningBorder;
    } else {
      bg = AppColors.healthyBg;
      text = AppColors.healthy;
      border = AppColors.healthyBorder;
    }

    return statusChip(
      riskLevel.toUpperCase(),
      bg,
      textColor: text,
      borderColor: border,
    );
  }
}
