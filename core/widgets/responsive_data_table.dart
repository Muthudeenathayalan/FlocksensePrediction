import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';

class ResponsiveDataColumn {
  final String label;
  final int flex;
  final TextAlign align;
  final double? width;

  const ResponsiveDataColumn({
    required this.label,
    this.flex = 1,
    this.align = TextAlign.left,
    this.width,
  });
}

class ResponsiveDataRow {
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const ResponsiveDataRow({
    required this.cells,
    this.onTap,
    this.backgroundColor,
  });
}

class ResponsiveDataTable extends StatelessWidget {
  final List<ResponsiveDataColumn> columns;
  final List<ResponsiveDataRow> rows;
  final Widget? emptyWidget;
  final String? emptyMessage;
  final bool isHeaderVisible;

  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyWidget,
    this.emptyMessage,
    this.isHeaderVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return emptyWidget ??
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: AppDesign.cardDecoration,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inbox_rounded,
                    size: 24,
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  emptyMessage ?? 'No records found',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'There are no entries matching your filter criteria.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          );
    }

    return Container(
      decoration: AppDesign.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. Table Header
          if (isHeaderVisible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.slate100,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: columns.map((col) {
                  Widget headerText = Text(
                    col.label.toUpperCase(),
                    textAlign: col.align,
                    style: AppTypography.tableHeader,
                  );

                  if (col.width != null) {
                    return SizedBox(
                      width: col.width,
                      child: headerText,
                    );
                  }

                  return Expanded(
                    flex: col.flex,
                    child: headerText,
                  );
                }).toList(),
              ),
            ),

          // 2. Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) {
              final row = rows[index];
              return Material(
                color: row.backgroundColor ?? Colors.transparent,
                child: InkWell(
                  onTap: row.onTap,
                  hoverColor: AppColors.primaryLight.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: List.generate(
                        columns.length,
                        (colIdx) {
                          final col = columns[colIdx];
                          final cell = row.cells[colIdx];

                          Alignment alignment = Alignment.centerLeft;
                          if (col.align == TextAlign.right) {
                            alignment = Alignment.centerRight;
                          } else if (col.align == TextAlign.center) {
                            alignment = Alignment.center;
                          }

                          Widget cellWidget = Align(
                            alignment: alignment,
                            child: cell,
                          );

                          if (col.width != null) {
                            return SizedBox(
                              width: col.width,
                              child: cellWidget,
                            );
                          }

                          return Expanded(
                            flex: col.flex,
                            child: cellWidget,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
