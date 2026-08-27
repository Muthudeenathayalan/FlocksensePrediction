import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/shared/analytics/chart_animation_config.dart';
import 'package:flock_sense/shared/analytics/chart_empty_state.dart';
import 'package:flock_sense/shared/analytics/chart_error_state.dart';
import 'package:flock_sense/shared/analytics/chart_loading_skeleton.dart';

class LegendItemData {
  final String label;
  final Color color;
  final bool isDashed;
  final bool isArea;

  const LegendItemData({
    required this.label,
    required this.color,
    this.isDashed = false,
    this.isArea = false,
  });
}

/// Standard Animated Analytics Chart Container with Title, Filter Chips, Legend & States
class AnimatedChartContainer extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<String> timeRanges;
  final String? selectedTimeRange;
  final ValueChanged<String>? onTimeRangeChanged;
  final List<LegendItemData> legendItems;
  final List<Widget>? headerActions;
  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final String emptyTitle;
  final String? emptySubtitle;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final VoidCallback? onRetry;
  final VoidCallback? onExport;
  final double height;

  const AnimatedChartContainer({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.timeRanges = const ['7D', '30D', '90D'],
    this.selectedTimeRange,
    this.onTimeRangeChanged,
    this.legendItems = const [],
    this.headerActions,
    this.isLoading = false,
    this.errorMessage,
    this.isEmpty = false,
    this.emptyTitle = 'No data available for this range',
    this.emptySubtitle,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.onRetry,
    this.onExport,
    this.height = 280,
  });

  @override
  State<AnimatedChartContainer> createState() => _AnimatedChartContainerState();
}

class _AnimatedChartContainerState extends State<AnimatedChartContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = ChartAnimationConfig.isReducedMotion(context);

    Widget content = Container(
      decoration: AppDesign.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with Title & Filter Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTypography.cardTitle),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(widget.subtitle!, style: AppTypography.metadata),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time Range Filter Chips
                  if (widget.onTimeRangeChanged != null && widget.timeRanges.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.timeRanges.map((range) {
                          final isSelected = (widget.selectedTimeRange ?? widget.timeRanges.first) == range;
                          return InkWell(
                            onTap: () => widget.onTimeRangeChanged!(range),
                            borderRadius: BorderRadius.circular(4),
                            child: AnimatedContainer(
                              duration: ChartAnimationConfig.filterTransition,
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                range,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.slate900 : AppColors.slate600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Additional Header Actions
                  if (widget.headerActions != null) ...widget.headerActions!,

                  // Export Action
                  if (widget.onExport != null) ...[
                    IconButton(
                      icon: const Icon(Icons.download_outlined, size: 18, color: AppColors.slate600),
                      tooltip: 'Export Chart Data',
                      onPressed: widget.onExport,
                    ),
                  ],
                ],
              ),
            ],
          ),

          // 2. Legend if provided
          if (widget.legendItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: widget.legendItems.map((item) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: item.isArea ? 8 : 3,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(item.isArea ? 2 : 1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.slate600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // 3. Body: Loading, Error, Empty, or Actual Chart
          SizedBox(
            height: widget.height,
            child: _buildBody(),
          ),
        ],
      ),
    );

    if (isReduced) {
      return content;
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: content,
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return ChartLoadingSkeleton(height: widget.height);
    }
    if (widget.errorMessage != null) {
      return ChartErrorState(
        message: widget.errorMessage,
        onRetry: widget.onRetry,
        height: widget.height,
      );
    }
    if (widget.isEmpty) {
      return ChartEmptyState(
        title: widget.emptyTitle,
        subtitle: widget.emptySubtitle,
        actionLabel: widget.emptyActionLabel,
        onAction: widget.onEmptyAction,
        height: widget.height,
      );
    }
    return widget.child;
  }
}
