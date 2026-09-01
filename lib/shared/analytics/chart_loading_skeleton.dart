import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';

/// Shimmer loading skeleton for analytical charts
class ChartLoadingSkeleton extends StatefulWidget {
  final double height;

  const ChartLoadingSkeleton({super.key, this.height = 240});

  @override
  State<ChartLoadingSkeleton> createState() => _ChartLoadingSkeletonState();
}

class _ChartLoadingSkeletonState extends State<ChartLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return Container(
          height: widget.height,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar placeholders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 140,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.slate200.withOpacity(opacity),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.slate200.withOpacity(opacity),
                      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Chart axes and line shimmers
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Y-axis labels placeholder
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        4,
                        (index) => Container(
                          width: 24,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.slate200.withOpacity(opacity),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Grid & Bar simulation
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (i) {
                          final barHeights = [0.4, 0.65, 0.5, 0.8, 0.45, 0.7, 0.9];
                          return Container(
                            width: 16,
                            height: (widget.height - 90) * barHeights[i],
                            decoration: BoxDecoration(
                              color: AppColors.slate200.withOpacity(opacity),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Bottom X-axis labels placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  5,
                  (index) => Container(
                    width: 32,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.slate200.withOpacity(opacity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
