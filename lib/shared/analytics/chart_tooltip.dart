import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';

/// Data payload for rich, interactive chart tooltips
class AnalyticsTooltipData {
  final String date;
  final String primaryLabel;
  final String primaryValue;
  final String? secondaryLabel;
  final String? secondaryValue;
  final String? baselineLabel;
  final String? baselineValue;
  final String? changePercent;
  final bool isIncreaseNegative;
  final String? riskStatus;
  final Color? riskColor;
  final String? note;
  final String? actionText;
  final VoidCallback? onAction;

  const AnalyticsTooltipData({
    required this.date,
    required this.primaryLabel,
    required this.primaryValue,
    this.secondaryLabel,
    this.secondaryValue,
    this.baselineLabel,
    this.baselineValue,
    this.changePercent,
    this.isIncreaseNegative = true,
    this.riskStatus,
    this.riskColor,
    this.note,
    this.actionText,
    this.onAction,
  });
}

/// Rich, interactive tooltip presentation widget for analytical charts
class ChartTooltipView extends StatelessWidget {
  final AnalyticsTooltipData data;

  const ChartTooltipView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.slate700, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Date & Risk Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.date,
                style: const TextStyle(
                  color: AppColors.slate400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (data.riskStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (data.riskColor ?? AppColors.critical).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: data.riskColor ?? AppColors.critical,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    data.riskStatus!,
                    style: TextStyle(
                      color: data.riskColor ?? AppColors.critical,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Primary Metric & Delta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.primaryLabel,
                    style: const TextStyle(
                      color: AppColors.slate300,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.primaryValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (data.changePercent != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getDeltaBgColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getDeltaIcon(),
                        size: 12,
                        color: _getDeltaColor(),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        data.changePercent!,
                        style: TextStyle(
                          color: _getDeltaColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // 3. Baseline / Reference comparison if provided
          if (data.baselineLabel != null && data.baselineValue != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.baselineLabel!,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                ),
                Text(
                  data.baselineValue!,
                  style: const TextStyle(
                    color: AppColors.slate200,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // 4. Secondary Metric if provided
          if (data.secondaryLabel != null && data.secondaryValue != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.secondaryLabel!,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                ),
                Text(
                  data.secondaryValue!,
                  style: const TextStyle(
                    color: AppColors.slate200,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // 5. Note / Context
          if (data.note != null) ...[
            const SizedBox(height: 6),
            Text(
              data.note!,
              style: const TextStyle(
                color: AppColors.slate400,
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // 6. Click action prompt
          if (data.actionText != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.slate800),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.touch_app_outlined, size: 12, color: AppColors.primaryLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data.actionText!,
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getDeltaColor() {
    final isPositive = data.changePercent?.startsWith('+') ?? true;
    if (data.isIncreaseNegative) {
      return isPositive ? AppColors.critical : AppColors.healthy;
    } else {
      return isPositive ? AppColors.healthy : AppColors.critical;
    }
  }

  Color _getDeltaBgColor() {
    return _getDeltaColor().withOpacity(0.18);
  }

  IconData _getDeltaIcon() {
    final isPositive = data.changePercent?.startsWith('+') ?? true;
    return isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
  }
}
