import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';

enum BadgeVariant {
  healthy,
  info,
  warning,
  highRisk,
  critical,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final IconData? icon;
  final BadgeVariant? variant;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.icon,
    this.variant,
  });

  factory StatusBadge.fromStatus(String status) {
    final s = status.toLowerCase().trim();
    if (s.contains('crit') || s.contains('outbreak') || s.contains('dead') || s.contains('danger')) {
      return StatusBadge(
        label: status,
        variant: BadgeVariant.critical,
        icon: Icons.error_outline_rounded,
      );
    } else if (s.contains('high') || s.contains('severe')) {
      return StatusBadge(
        label: status,
        variant: BadgeVariant.highRisk,
        icon: Icons.warning_amber_rounded,
      );
    } else if (s.contains('warn') || s.contains('mod') || s.contains('overdue') || s.contains('pending')) {
      return StatusBadge(
        label: status,
        variant: BadgeVariant.warning,
        icon: Icons.schedule_rounded,
      );
    } else if (s.contains('good') || s.contains('health') || s.contains('normal') || s.contains('active') || s.contains('completed')) {
      return StatusBadge(
        label: status,
        variant: BadgeVariant.healthy,
        icon: Icons.check_circle_outline_rounded,
      );
    } else if (s.contains('info') || s.contains('investigat') || s.contains('treat')) {
      return StatusBadge(
        label: status,
        variant: BadgeVariant.info,
        icon: Icons.info_outline_rounded,
      );
    }
    return StatusBadge(
      label: status,
      variant: BadgeVariant.neutral,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color fg = color ?? AppColors.slate700;
    Color bg = backgroundColor ?? AppColors.slate100;
    Color border = borderColor ?? AppColors.slate200;

    if (variant != null) {
      switch (variant!) {
        case BadgeVariant.healthy:
          fg = AppColors.healthy;
          bg = AppColors.healthyBg;
          border = AppColors.healthyBorder;
          break;
        case BadgeVariant.info:
          fg = AppColors.info;
          bg = AppColors.infoBg;
          border = AppColors.infoBorder;
          break;
        case BadgeVariant.warning:
          fg = AppColors.warning;
          bg = AppColors.warningBg;
          border = AppColors.warningBorder;
          break;
        case BadgeVariant.highRisk:
          fg = AppColors.highRisk;
          bg = AppColors.highRiskBg;
          border = AppColors.highRiskBorder;
          break;
        case BadgeVariant.critical:
          fg = AppColors.critical;
          bg = AppColors.criticalBg;
          border = AppColors.criticalBorder;
          break;
        case BadgeVariant.neutral:
          fg = AppColors.slate600;
          bg = AppColors.slate100;
          border = AppColors.slate200;
          break;
      }
    } else if (color != null) {
      fg = color!;
      bg = color!.withOpacity(0.1);
      border = color!.withOpacity(0.3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDesign.radiusFull),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
