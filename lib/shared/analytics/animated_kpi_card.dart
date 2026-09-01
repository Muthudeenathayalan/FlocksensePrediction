import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/shared/analytics/chart_animation_config.dart';

/// Interactive, Animated KPI Card with Tween Count-Up & Live Transition
class AnimatedKpiCard extends StatefulWidget {
  final String title;
  final num numericValue;
  final String? prefix;
  final String? suffix;
  final int decimalDigits;
  final String? delta;
  final bool? isPositiveDelta;
  final bool isIncreaseNegative;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isCritical;
  final VoidCallback? onTap;

  const AnimatedKpiCard({
    super.key,
    required this.title,
    required this.numericValue,
    this.prefix,
    this.suffix,
    this.decimalDigits = 0,
    this.delta,
    this.isPositiveDelta,
    this.isIncreaseNegative = false,
    this.subtitle,
    required this.icon,
    this.accentColor = AppColors.primary,
    this.isCritical = false,
    this.onTap,
  });

  @override
  State<AnimatedKpiCard> createState() => _AnimatedKpiCardState();
}

class _AnimatedKpiCardState extends State<AnimatedKpiCard>
    with SingleTickerProviderStateMixin {
  late num _oldValue;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _oldValue = 0;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isCritical) {
      _pulseController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedKpiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.numericValue != widget.numericValue) {
      _oldValue = oldWidget.numericValue;
      if (widget.isCritical && !_pulseController.isAnimating) {
        _pulseController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = ChartAnimationConfig.isReducedMotion(context);
    final cardColor = widget.isCritical ? AppColors.criticalBg : AppColors.surface;
    final borderColor = widget.isCritical
        ? AppColors.critical.withOpacity(0.35)
        : AppColors.border;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
      child: AnimatedContainer(
        duration: ChartAnimationConfig.realtimeUpdate,
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: widget.isCritical
              ? [
                  BoxShadow(
                    color: AppColors.critical.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : AppDesign.subtleShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Title + Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isCritical ? AppColors.critical : AppColors.slate600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  ),
                  child: Icon(widget.icon, size: 16, color: widget.accentColor),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Middle: Animated Number Count-Up
            isReduced
                ? _buildFormattedValue(widget.numericValue.toDouble())
                : TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: _oldValue.toDouble(),
                      end: widget.numericValue.toDouble(),
                    ),
                    duration: ChartAnimationConfig.kpiCount,
                    curve: ChartAnimationConfig.defaultCurve,
                    builder: (context, val, child) {
                      return _buildFormattedValue(val);
                    },
                  ),
            const SizedBox(height: 6),

            // Bottom Row: Delta & Subtitle
            Row(
              children: [
                if (widget.delta != null) ...[
                  _buildDeltaBadge(),
                  const SizedBox(width: 6),
                ],
                if (widget.subtitle != null) ...[
                  Expanded(
                    child: Text(
                      widget.subtitle!,
                      style: AppTypography.metadata,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedValue(double val) {
    String formattedNumber;
    if (widget.decimalDigits > 0) {
      formattedNumber = val.toStringAsFixed(widget.decimalDigits);
    } else {
      formattedNumber = NumberFormat('#,###').format(val.round());
    }

    final fullText = '${widget.prefix ?? ''}$formattedNumber${widget.suffix != null ? ' ${widget.suffix}' : ''}';

    return Text(
      fullText,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: widget.isCritical ? AppColors.critical : AppColors.slate900,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildDeltaBadge() {
    final isPositive = widget.isPositiveDelta ?? widget.delta!.startsWith('+');
    Color deltaColor;
    if (widget.isIncreaseNegative) {
      deltaColor = isPositive ? AppColors.critical : AppColors.healthy;
    } else {
      deltaColor = isPositive ? AppColors.healthy : AppColors.critical;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: deltaColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.delta!,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: deltaColor,
        ),
      ),
    );
  }
}
