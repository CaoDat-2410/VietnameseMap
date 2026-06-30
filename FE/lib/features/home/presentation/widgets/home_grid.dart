import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// 12-column responsive bento grid for home pages.
/// Each child is wrapped in a HomeGridItem which declares its column span.
class HomeGrid extends StatelessWidget {
  const HomeGrid({
    super.key,
    required this.children,
    this.gap = AppSpacing.bentoGap,
    this.padding,
  });

  final List<Widget> children;
  final double gap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Responsive breakpoints matching AppSpacing
        // >= 1200px: 3 columns  (each col = 4 spans)
        // 900-1199px: 2 columns (each col = 6 spans)
        // < 900px: 1 column    (each col = 12 spans)
        final columns = width >= AppSpacing.breakpointDesktop
            ? 3
            : width >= AppSpacing.breakpointTablet
                ? 2
                : 1;

        final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.base);

        if (columns == 1) {
          return Padding(
            padding: effectivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildRows(children, 1, gap),
            ),
          );
        }

        return Padding(
          padding: effectivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildRows(children, columns, gap),
          ),
        );
      },
    );
  }

  List<Widget> _buildRows(List<Widget> children, int columns, double gap) {
    final rows = <Widget>[];
    int i = 0;

    while (i < children.length) {
      final rowChildren = <Widget>[];
      int spansUsed = 0;

      while (i < children.length && spansUsed < 12) {
        final item = children[i];
        int itemSpan = 12;

        // Extract the declared span from HomeGridItem if present
        if (item is HomeGridItem) {
          itemSpan = item.span;
        }

        // Don't overflow past 12 spans
        if (spansUsed + itemSpan > 12) break;

        rowChildren.add(item);
        spansUsed += itemSpan;
        i++;
      }

      // Add spacer for remaining space if not filled
      if (spansUsed < 12) {
        final remaining = 12 - spansUsed;
        rowChildren.add(SizedBox(width: gap));
        // Flex with spacer
      }

      if (columns == 1) {
        rows.add(SizedBox(height: gap));
        rows.add(Expanded(child: rowChildren.first));
      } else {
        rows.add(Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildRowChildren(rowChildren, columns, gap, spansUsed),
            ),
          ),
        ));
      }
    }

    return rows;
  }

  List<Widget> _buildRowChildren(
    List<Widget> rowChildren,
    int columns,
    double gap,
    int spansUsed,
  ) {
    final result = <Widget>[];

    for (int j = 0; j < rowChildren.length; j++) {
      final item = rowChildren[j];
      int itemSpan = 12;
      if (item is HomeGridItem) {
        itemSpan = item.span;
      }

      result.add(
        Expanded(
          flex: itemSpan,
          child: item is HomeGridItem ? item.child : item,
        ),
      );
      if (j < rowChildren.length - 1) {
        result.add(SizedBox(width: gap));
      }
    }

    return result;
  }
}

/// Wraps a widget with its column span for HomeGrid.
class HomeGridItem extends StatelessWidget {
  const HomeGridItem({
    super.key,
    required this.child,
    this.span = 6,
  });

  final Widget child;
  final int span;

  @override
  Widget build(BuildContext context) => child;
}

/// A row of HomeGridItems that can span multiple columns on the same row.
class HomeGridRow extends StatelessWidget {
  const HomeGridRow({
    super.key,
    required this.children,
    this.gap = AppSpacing.bentoGap,
  });

  final List<HomeGridItem> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= AppSpacing.breakpointDesktop
            ? 3
            : width >= AppSpacing.breakpointTablet
                ? 2
                : 1;

        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                flex: children[i].span,
                child: children[i].child,
              ),
            ],
          ],
        );
      },
    );
  }
}
