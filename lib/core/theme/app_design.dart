import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

/// Centralized Design System Tokens & Helpers for FlockSense Web SaaS
class AppDesign {
  AppDesign._();

  // ── Standard 8px Spacing Grid ───────────────────────────────────────────
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // ── Corner Radii ────────────────────────────────────────────────────────
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 9999.0;

  // ── Layout Dimensions ───────────────────────────────────────────────────
  static const double sidebarWidth = 250.0;
  static const double sidebarCollapsedWidth = 72.0;
  static const double headerHeight = 64.0;
  static const double maxContentWidth = 1500.0;
  static const double maxFormWidth = 850.0;
  static const double maxModalWidth = 650.0;

  // ── Shadows ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> modalShadow = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // ── Card & Container Decorations ────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: cardShadow,
      );

  static BoxDecoration get cardDecorationFlat => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
      );

  static BoxDecoration get panelDecoration => BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: AppColors.border, width: 1),
      );

  // ── Semantic Status Chips ───────────────────────────────────────────────
  static Widget statusChip(
    String text,
    Color bg, {
    Color textColor = AppColors.slate900,
    Color? borderColor,
    IconData? icon,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radiusFull),
          border: Border.all(
            color: borderColor ?? bg.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      );

  static Widget riskBadge(String riskLevel) {
    Color bg;
    Color text;
    Color border;
    IconData icon;

    switch (riskLevel.toLowerCase()) {
      case 'critical':
      case 'severe':
        bg = AppColors.criticalBg;
        text = AppColors.critical;
        border = AppColors.criticalBorder;
        icon = Icons.error_outline_rounded;
        break;
      case 'high':
      case 'high risk':
        bg = AppColors.highRiskBg;
        text = AppColors.highRisk;
        border = AppColors.highRiskBorder;
        icon = Icons.warning_amber_rounded;
        break;
      case 'moderate':
      case 'warning':
        bg = AppColors.warningBg;
        text = AppColors.warning;
        border = AppColors.warningBorder;
        icon = Icons.info_outline_rounded;
        break;
      case 'low':
      case 'healthy':
      case 'normal':
        bg = AppColors.healthyBg;
        text = AppColors.healthy;
        border = AppColors.healthyBorder;
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        bg = AppColors.neutralBg;
        text = AppColors.neutral;
        border = AppColors.neutralBorder;
        icon = Icons.help_outline_rounded;
    }

    return statusChip(
      riskLevel.toUpperCase(),
      bg,
      textColor: text,
      borderColor: border,
      icon: icon,
    );
  }

  // ── Backward Compatible Gradients (Cleaned up) ──────────────────────────
  static const LinearGradient headerGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF052E16), Color(0xFF166534)],
  );

  static const LinearGradient headerGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF78350F), Color(0xFFD97706)],
  );

  static const LinearGradient headerTealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF042F2E), Color(0xFF0D9488)],
  );

  static const LinearGradient headerBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  );

  static const LinearGradient headerPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B0764), Color(0xFF7C3AED)],
  );

  static const LinearGradient headerRedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
  );

  static const LinearGradient actionGreen = AppColors.primaryGradient;
  static const LinearGradient actionTeal = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  );
  static const LinearGradient actionGold = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
  );
  static const LinearGradient actionRed = LinearGradient(
    colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
  );
  static const LinearGradient actionPurple = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
  );
  static const LinearGradient actionBlue = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
  );
  static const LinearGradient actionDarkTeal = LinearGradient(
    colors: [Color(0xFF115E59), Color(0xFF0F766E)],
  );
  static const LinearGradient actionDarkRed = LinearGradient(
    colors: [Color(0xFF991B1B), Color(0xFFB91C1C)],
  );

  static BoxDecoration gradientDecoration(LinearGradient gradient) =>
      BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: cardShadow,
      );

  // ── Stat Card Builders ──────────────────────────────────────────────────
  static Widget miniStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) =>
      Container(
        padding: const EdgeInsets.all(space16),
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(radiusMd),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
              ],
            ),
            const SizedBox(height: space12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );

  static Widget sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: space12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      );

  static Widget headerStat(String label, String value, IconData icon) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      );

  static Widget infoRow(String label, String value) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: space8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
        ],
      );
}
